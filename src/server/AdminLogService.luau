--!strict
-- Server-local filtered audit history. No storage or cross-server messaging.
-- A new server starts empty; current-server reconnects can read this session.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TextService=game:GetService("TextService")
local HttpService=game:GetService("HttpService")

local Core=require(script.Parent.AdminLogCore)
local TeamService=require(script.Parent.TeamService)
local Permissions=require(script.Parent.MessengerPermissions)
local Audit=require(script.Parent.AdminAudit)

local Service={}
local started=false
local history=require(script.Parent.ServerLogHistory).new()
local seen: {[string]: boolean}={}
local seenOrder: {string}={}
local sessions: {[Player]: {[string]: number}}={}
local lastRequest: {[Player]: number}={}
local lastError=""
local failures=0
local dropped=0
local PAGE_SIZE=Core.PAGE_SIZE

local function remember(messageId: string): boolean
    if seen[messageId] then return false end
    seen[messageId]=true
    table.insert(seenOrder,messageId)
    if #seenOrder>2200 then
        local oldest=table.remove(seenOrder,1)
        seen[oldest]=nil
    end
    return true
end

local function filteredText(text: string,userId: number): string?
    if text=="" or #text>Core.MAX_TEXT_BYTES then return nil end
    if not utf8.len(text) then return nil end
    local ok,result=pcall(function()
        return TextService:FilterStringAsync(text,userId,Enum.TextFilterContext.PublicChat)
            :GetNonChatStringForBroadcastAsync()
    end)
    if not ok or type(result)~="string" or result=="" then
        warn("[AdminLogs] Roblox filter failed, audit text not stored:",userId)
        failures+=1
        return nil
    end
    return result
end

local function createEntry(kind: string,fields: any): any
    return {
        id="log_"..HttpService:GenerateGUID(false):gsub("-",""),
        kind=kind,time=os.time(),sort=DateTime.now().UnixTimestampMillis,
        serverId=game.JobId,
        name=fields.name,userId=fields.userId,
        channelId=fields.channelId,unit=fields.unit,
        source=fields.source,ok=fields.ok,text=fields.text,
    }
end

local function enqueue(entry: any)
    if not Core.valid(entry) then failures+=1; return end
    history.append(entry)
end

-- This is invoked only *after* the messenger server has authorized delivery.
-- Never yield from TextChannel.ShouldDeliverCallback: filter on a spawned task.
function Service.captureChat(channelId: string,message: TextChatMessage,author: Player)
    if not started or author.Parent~=Players or not message.TextSource
        or message.TextSource.UserId~=author.UserId then return end
    local raw=message.Text
    if type(raw)~="string" or raw=="" then return end
    local engineId=message.MessageId
    local identity=if type(engineId)=="string" and engineId~="" then engineId else tostring(message)
    if not remember("chat:"..channelId..":"..identity) then return end
    local unit=nil
    if channelId=="unit" then
        local name=author:GetAttribute("Unit")
        unit=if type(name)=="string" and name~="" then name else (
            if author.Team and not author.Neutral then author.Team.Name else nil
        )
    end
    local userId=author.UserId
    local username=author.Name
    local source=if (message.Metadata or ""):match("^mrp1|e|") then "메신저 수정" else "메신저"
    task.spawn(function()
        local safe=filteredText(raw,userId)
        if not safe then return end
        enqueue(createEntry("chat",{
            name=username,userId=userId,text=safe,channelId=channelId,
            unit=unit,source=source,
        }))
    end)
end

-- Bulletin posts are already filtered by MessengerArchive before
-- persisting; log just the successfully committed public-safe text.
function Service.captureBulletin(channelId: string,author: Player,filtered: string,mode: string)
    if not started or not Core.typeValid("chat") or type(filtered)~="string"
        or #filtered>Core.MAX_TEXT_BYTES then return end
    enqueue(createEntry("chat",{
        name=author.Name,userId=author.UserId,channelId=channelId,
        text=filtered,source=if mode=="edit" then "게시글 수정" else "영구 게시판",
    }))
end

-- These events contain only server-generated action labels and validated IDs,
-- never player-submitted chat text or an unfiltered message body.
function Service.captureModeration(channelId: string,actor: Player,messageId: string,action: string)
    if not started or actor.Parent~=Players or type(channelId)~="string"
        or #channelId>48 or not Core.keyValid(messageId)
        or (action~="delete" and action~="pin") then return end
    local word=if action=="delete" then "삭제" else "고정 상태 변경"
    enqueue(createEntry("chat",{
        name=actor.Name,userId=actor.UserId,channelId=channelId,
        text="[관리 이벤트] 메시지 "..word.." · ID "..messageId,
        source="관리 이벤트",
    }))
end

local function captureCommand(item: any)
    if not started or type(item)~="table" or type(item.userId)~="number"
        or type(item.command)~="string" then return end
    local original=item.command
    local authorId=item.userId
    local username=item.name
    local success=item.ok==true
    task.spawn(function()
        local safe=filteredText(original,authorId)
        if not safe then return end
        enqueue(createEntry("command",{
            name=username,userId=authorId,text=safe,ok=success,source="관리 명령",
        }))
    end)
end

local function unitOf(player: Player): string?
    local unit=player:GetAttribute("Unit")
    if type(unit)=="string" and unit~="" then return unit end
    return if player.Team and not player.Neutral then player.Team.Name else nil
end

local function viewRecord(player: Player,record: any): any?
    if not Core.valid(record) then return nil end
    local allowedContent=true
    if record.kind=="chat" then
        local readAllowed=Permissions.channel(player,record.channelId,"read")
        -- Chat logs from deleted/unknown channels remain present but redacted.
        -- Unit chat logs are never exposed to HQ members in another unit.
        allowedContent=Core.canReadContent(record,readAllowed,unitOf(player))
    end
    return Core.present(record,allowedContent)
end

local function request(player: Player,kind: any,action: any): any
    if not TeamService.isAdmin(player) then
        return {ok=false,message="설정된 Roblox 그룹 운영진 등급이어야 서버 로그에 접근할 수 있습니다."}
    end
    if not Core.typeValid(kind) or (action~="latest" and action~="more") then
        return {ok=false,message="잘못된 로그 요청입니다."}
    end
    local now=os.clock()
    if now-(lastRequest[player] or -math.huge)<0.5 then
        return {ok=false,message="잠시 후 다시 조회하세요."}
    end
    lastRequest[player]=now
    local all=sessions[player]
    if not all then all={};sessions[player]=all end
    local before=if action=="more" then all[kind] else nil
    local entries,cursor,hasMore=history.page(kind,before,PAGE_SIZE)
    local items={}
    for _,entry in entries do
        local item=viewRecord(player,entry)
        if item then table.insert(items,item) end
    end
    all[kind]=cursor
    local result={ok=true,kind=kind,entries=items,hasMore=hasMore,incomplete=false,
        status={queued=0,failed=failures,dropped=dropped,lastError=lastError}}

    return result
end

function Service.start()
    if started then return end
    started=true
    local remote=Instance.new("RemoteFunction")
    remote.Name="AdminLogRequest"
    remote.Parent=ReplicatedStorage
    remote.OnServerInvoke=request
    Audit.Changed.Event:Connect(captureCommand)
    Players.PlayerRemoving:Connect(function(player)
        sessions[player]=nil
        lastRequest[player]=nil
    end)

end

return Service
