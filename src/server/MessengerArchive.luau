--!strict
-- Permanent notice/rules bulletin channels only. Regular game chat remains ephemeral.
-- Only server-filtered broadcast-safe text is persisted; there is no raw chat archive.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TextService=game:GetService("TextService")
local TextChatService=game:GetService("TextChatService")
local DataStoreService=game:GetService("DataStoreService")
local MessagingService=game:GetService("MessagingService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")

local Store=require(script.Parent.MessengerStore)
local Rules=require(script.Parent.MessengerState)
local Permissions=require(script.Parent.MessengerPermissions)
local Core=require(script.Parent.MessengerArchiveCore)

local Archive={}
local name=if RunService:IsStudio() then "MilitaryMessenger_Boards_Dev_v1" else "MilitaryMessenger_Boards_v1"
local ds=DataStoreService:GetDataStore(name)
local TOPIC=name.."_changed"
local started=false
local changed: RemoteEvent?=nil
local requests: {[Player]: {[string]: number}}={}
local cache: {[string]: {at: number,data: any}}={}
local MAX_CHARACTERS=180
local MAX_BYTES=900
local EMOJI={["👍"]=true,["❤️"]=true,["😂"]=true,["🔥"]=true,["✅"]=true,["🎉"]=true}

local function enabled(id: any): boolean
    return type(id)=="string" and #id<=48 and Store.status().ready
        and Rules.isPersistent(Store.get(),id)
end

local function key(id: string): string
    -- Roblox DataStore key limit: 50 bytes; custom channel IDs are at most 39.
    return "c_"..id
end

local function read(id: string,useCache: boolean?): (any?,string?)
    local snapshot=cache[id]
    if useCache and snapshot and os.clock()-snapshot.at<2 then return snapshot.data,nil end
    local options=Instance.new("DataStoreGetOptions")
    options.UseCache=false
    local ok,value=pcall(function()
        return ds:GetAsync(key(id),options)
    end)
    if not ok then
        warn("[MessengerArchive] Unable to read channel",id)
        return nil,"영구 기록을 불러오지 못했습니다. 잠시 후 다시 시도하세요."
    end
    local data=if value==nil then Core.empty() else value
    if not Core.valid(data) then
        warn("[MessengerArchive] Invalid archive schema",id)
        return nil,"저장된 채널 기록 형식이 올바르지 않습니다."
    end
    cache[id]={at=os.clock(),data=data}
    return data,nil
end

local function allowed(player: Player,channelId: any,mode: string): boolean
    return player.Parent==Players and enabled(channelId) and Permissions.channel(player,channelId,mode)
end

local function moderator(player: Player,channelId: string): boolean
    return Permissions.has(player,"MANAGE_SETTINGS") and Permissions.channel(player,channelId,"manage")
end

local function mayPublish(player: Player): boolean
    if RunService:IsStudio() and player.UserId<=0 then return true end
    local ok,permission=pcall(function() return TextChatService:CanUserChatAsync(player.UserId) end)
    return ok and permission==true
end

local function rate(player: Player,nameOfAction: string,seconds: number): boolean
    local now=os.clock()
    local tableForPlayer=requests[player]
    if not tableForPlayer then tableForPlayer={};requests[player]=tableForPlayer end
    if now-(tableForPlayer[nameOfAction] or -math.huge)<seconds then return false end
    tableForPlayer[nameOfAction]=now
    return true
end

local function announce(channelId: string,revision: number,operation: any)
    cache[channelId]=nil
    if changed then
        for _,player in Players:GetPlayers() do
            if allowed(player,channelId,"read") then
                changed:FireClient(player,{channelId=channelId,revision=revision,
                    id=operation.id,action=operation.action})
            end
        end
    end
    task.spawn(function()
        pcall(function()
            MessagingService:PublishAsync(TOPIC,{channelId=channelId,revision=revision,
                id=operation.id,action=operation.action})
        end)
    end)
end

local function update(channelId: string,op: any): (boolean,string,any?)
    -- UpdateAsync applies each operation to the latest data, preventing lost writes.
    -- Its transform must not yield; text filtering occurs outside.
    local lastReason="영구 저장에 실패했습니다."
    local ok,updated=pcall(function()
        return ds:UpdateAsync(key(channelId),function(current)
            local result,reason=Core.apply(current,op)
            lastReason=reason
            return result
        end)
    end)
    if not ok or updated==nil then
        if not ok then warn("[MessengerArchive] UpdateAsync failed",channelId) end
        return false,if ok then lastReason else "저장 응답을 확인하지 못했습니다. 잠시 후 기록을 새로고침해 주세요.",nil
    end
    cache[channelId]=nil
    announce(channelId,updated.revision,op)
    return true,lastReason,updated
end

local function sanitizeText(player: Player,value: any): (string?,string?)
    if type(value)~="string" or #value==0 or #value>MAX_BYTES then
        return nil,"글은 1~180자로 작성해야 합니다."
    end
    local len=utf8.len(value)
    if not len or len<1 or len>MAX_CHARACTERS or not value:match("%S") then
        return nil,"글은 1~180자로 작성해야 합니다."
    end
    local ok,filtered=pcall(function()
        return TextService:FilterStringAsync(value,player.UserId,Enum.TextFilterContext.PublicChat)
            :GetNonChatStringForBroadcastAsync()
    end)
    if not ok or type(filtered)~="string" or filtered=="" then
        return nil,"Roblox 텍스트 필터링에 실패해 글을 저장하지 않았습니다."
    end
    return filtered,nil
end

local function replyId(value: any): string?
    if type(value)=="string" and #value>=8 and #value<=90 and value:match("^[%w_%-]+$") then return value end
    return nil
end

local function output(player: Player,channelId: string,data: any,before: number?): any
    if not allowed(player,channelId,"read") then
        return {ok=false,message="채널 기록을 읽을 권한이 없습니다."}
    end
    local page=Core.page(data,player.UserId,before,Core.PAGE_SIZE)
    return {ok=true,channelId=channelId,entries=page.entries,cursor=page.cursor,
        revision=page.revision,maxEntries=Core.MAX_ENTRIES}
end

local function request(player: Player,action: any,payload: any): any
    if type(action)~="string" or type(payload)~="table" then
        return {ok=false,message="잘못된 요청입니다."}
    end
    local channelId=payload.channelId
    if not enabled(channelId) then
        return {ok=false,message="영구 보관 채널이 아닙니다."}
    end

    if action=="load" then
        if not allowed(player,channelId,"read") then return {ok=false,message="채널 열람 권한이 없습니다."} end
        if not rate(player,"load:"..channelId,0.55) then return {ok=false,message="잠시 후 다시 불러오세요."} end
        local before=payload.before
        if before~=nil and (type(before)~="number" or before<1 or before%1~=0) then
            return {ok=false,message="잘못된 페이지입니다."}
        end
        local data,errorMessage=read(channelId,false)
        if not data then return {ok=false,message=errorMessage} end
        return output(player,channelId,data,before)
    end

    if action=="lookup" then
        if not allowed(player,channelId,"read") then return {ok=false,message="열람 권한이 없습니다."} end
        if not rate(player,"lookup",0.2) then return {ok=false,message="잠시 후 다시 조회하세요."} end
        local id=replyId(payload.id)
        if not id then return {ok=false,message="잘못된 메시지 ID입니다."} end
        local data,errorMessage=read(channelId,false)
        if not data then return {ok=false,message=errorMessage} end
        local item=Core.find(data,id)
        if not item then return {ok=true,entry=nil,missing=true} end
        local page=Core.page(data,player.UserId,item.seq+1,1)
        return {ok=true,entry=page.entries[1]}
    end

    if action=="post" or action=="edit" then
        if not allowed(player,channelId,"write") or not mayPublish(player) then
            return {ok=false,message="이 채널에 글을 작성할 권한이 없습니다."}
        end
        if not rate(player,"write",1.5) then return {ok=false,message="글은 잠시 간격을 두고 작성해 주세요."} end
        local body,errorMessage=sanitizeText(player,payload.text)
        if not body then return {ok=false,message=errorMessage} end
        local now=os.time()
        local op: any
        if action=="post" then
            if payload.replyTo~=nil and not replyId(payload.replyTo) then
                return {ok=false,message="답장할 글 ID가 올바르지 않습니다."}
            end
            if payload.threadRoot~=nil and not replyId(payload.threadRoot) then
                return {ok=false,message="스레드 ID가 올바르지 않습니다."}
            end
            local entry={
                id="p_"..HttpService:GenerateGUID(false):gsub("-",""),
                authorId=player.UserId,name=player.DisplayName,
                rank=tostring(player:GetAttribute("Rank") or "훈련병"),
                text=body,time=now,timeLabel=os.date("%H:%M"),date=os.date("%Y-%m-%d"),
                replyTo=payload.replyTo,threadRoot=payload.threadRoot,
            }
            op={action="append",id=entry.id,entry=entry}
        else
            local id=replyId(payload.id)
            if not id then return {ok=false,message="수정할 글 ID가 올바르지 않습니다."} end
            op={action="edit",id=id,text=body,authorId=player.UserId,time=now}
        end
        if not allowed(player,channelId,"write") then return {ok=false,message="작성 권한이 변경되었습니다."} end
        local ok,message,updated=update(channelId,op)
        if not ok then return {ok=false,message=message} end
        local id=if action=="post" then op.id else op.id
        local entry=Core.find(updated,id)
        return {ok=true,message=message,entry=entry and Core.page(updated,player.UserId,(entry.seq or 0)+1,1).entries[1]}
    end

    if action=="mutate" then
        if not allowed(player,channelId,"read") then return {ok=false,message="채널 열람 권한이 없습니다."} end
        if not rate(player,"mutate",0.4) then return {ok=false,message="잠시 후 다시 시도하세요."} end
        local id=replyId(payload.id)
        if not id then return {ok=false,message="글 ID가 올바르지 않습니다."} end
        local mode=payload.mode
        if mode~="delete" and mode~="pin" and mode~="react" then
            return {ok=false,message="지원하지 않는 글 관리 기능입니다."}
        end
        if mode=="react" then
            if not allowed(player,channelId,"write") or not mayPublish(player)
                or not EMOJI[payload.emoji] then
                return {ok=false,message="반응할 권한이 없거나 이모지가 지원되지 않습니다."}
            end
        elseif mode=="pin" and not moderator(player,channelId) then
            return {ok=false,message="메시지 고정 관리 권한이 없습니다."}
        end
        local op={action=mode,id=id,authorId=player.UserId,
            moderator=moderator(player,channelId),emoji=payload.emoji}
        local ok,message=update(channelId,op)
        return {ok=ok,message=message}
    end
    return {ok=false,message="지원하지 않는 요청입니다."}
end

function Archive.isEnabled(channelId: string): boolean
    return enabled(channelId)
end

function Archive.start()
    if started then return end
    started=true
    local remote=Instance.new("RemoteFunction")
    remote.Name="MessengerArchive"
    remote.Parent=ReplicatedStorage
    local event=Instance.new("RemoteEvent")
    event.Name="MessengerArchiveChanged"
    event.Parent=ReplicatedStorage
    changed=event
    remote.OnServerInvoke=request
    Players.PlayerRemoving:Connect(function(player) requests[player]=nil end)
    task.spawn(function()
        while true do
            local ok=pcall(function()
                MessagingService:SubscribeAsync(TOPIC,function(message)
                    local data=message.Data
                    if type(data)~="table" or type(data.channelId)~="string" then return end
                    local id=data.channelId
                    cache[id]=nil
                    if changed then
                        for _,player in Players:GetPlayers() do
                            if allowed(player,id,"read") then
                                changed:FireClient(player,{channelId=id,revision=data.revision,
                                    id=data.id,action=data.action})
                            end
                        end
                    end
                end)
            end)
            if ok then break end
            task.wait(30)
        end
    end)
end

return Archive
