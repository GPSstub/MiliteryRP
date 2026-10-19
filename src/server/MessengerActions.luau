--!strict
-- Ephemeral Discord-like message actions. No DataStore and no raw chat text is stored.
-- Message bodies only travel through Roblox TextChannel:SendAsync, including edits.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Permissions = require(script.Parent.MessengerPermissions)
local Protocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MessengerActionProtocol"))

local Actions = {}
local messages: {[string]: any} = {}
local order: {string} = {}
local MAX_MESSAGES = 2000
local EMOJI = {["👍"]=true, ["❤️"]=true, ["😂"]=true, ["🔥"]=true, ["✅"]=true, ["🎉"]=true}
local started = false
local request: RemoteFunction? = nil
local changed: RemoteEvent? = nil
local lastAction: {[Player]: number} = {}
local lastSnapshot: {[Player]: number} = {}
local chatEligibility: {[Player]: {allowed: boolean, expires: number}} = {}
local function mayChat(player: Player): boolean
    local now=os.clock()
    local cached=chatEligibility[player]
    if cached and cached.expires>now then return cached.allowed end
    local ok,allowed=pcall(function()
        return TextChatService:CanUserChatAsync(player.UserId)
    end)
    local can=ok and allowed==true
    chatEligibility[player]={allowed=can,expires=now+60}
    return can
end

local validId=Protocol.validId

local function find(id: any): any?
    if not validId(id) then return nil end
    return messages[id]
end

local function canModerate(player: Player, channelId: string): boolean
    return Permissions.has(player, "MANAGE_SETTINGS") and Permissions.channel(player, channelId, "manage")
end

local function publish(entry: any, action: string, extra: any?)
    local event = changed
    if not event then return end
    for _, viewer in Players:GetPlayers() do
        if Permissions.channel(viewer, entry.channelId, "read") then
            local unit = viewer:GetAttribute("Unit")
            if type(unit)~="string" or unit=="" then
                unit=if viewer.Team and not viewer.Neutral then viewer.Team.Name else nil
            end
            if entry.channelId ~= "unit" or (entry.unit~=nil and entry.unit==unit) then
                event:FireClient(viewer, {action=action, id=entry.id, channelId=entry.channelId, extra=extra})
            end
        end
    end
end

local function entryFor(player: Player, id: any): any?
    local entry = find(id)
    if not entry or entry.deleted or not Permissions.channel(player, entry.channelId, "read") then return nil end
    if entry.channelId == "unit" then
        local unit = player:GetAttribute("Unit")
        if type(unit) ~= "string" or unit == "" then
            unit = if player.Team and not player.Neutral then player.Team.Name else nil
        end
        if unit == nil or unit ~= entry.unit then return nil end
    end
    return entry
end

-- Read-only metadata snapshot. No text content may be returned via this remote.
local function snapshot(player: Player, channelId: any): any
    if type(channelId) ~= "string" or not Permissions.channel(player, channelId, "read") then
        return {ok=false, message="채널 접근 권한이 없습니다."}
    end
    local result={}
    for index=#order,1,-1 do
        local entry=messages[order[index]]
        if entry and entry.channelId==channelId and entryFor(player, entry.id) then
            local counts={}
            for emoji, users in entry.reactions do
                local total=0
                for _ in users do total+=1 end
                if total>0 then counts[emoji]={count=total, mine=users[player.UserId]==true} end
            end
            table.insert(result,{id=entry.id,pinned=entry.pinned,reactions=counts})
            if #result>=120 then break end
        end
    end
    return {ok=true,data=result}
end

function Actions.observe(channelId: string, message: TextChatMessage): boolean
    local source=message.TextSource
    if not source then return false end
    local metadata=message.Metadata or ""
    local senderId=source.UserId
    local kind, target, newId = nil, nil, nil

    if metadata ~= "" then
        local parsed=Protocol.decode(metadata)
        if not parsed then return false end
        kind=parsed.kind;target=parsed.target;newId=parsed.id
    else
        -- Messages sent through the default Roblox UI can participate where IDs exist.
        newId=message.MessageId
        if not validId(newId) then return true end
        kind="m"
    end

    if not newId then return false end
    local existing=messages[newId]
    if existing then
        -- Delivery runs for each recipient. The same message is safe to observe repeatedly.
        return existing.authorId==senderId and existing.channelId==channelId
            and existing.kind==kind and existing.target==target and not existing.deleted
    end

    if kind=="e" or kind=="r" or kind=="t" then
        local reference=find(target)
        if not reference or reference.deleted or reference.channelId~=channelId then return false end
        if channelId=="unit" then
            local sender=Players:GetPlayerByUserId(senderId)
            if not sender then return false end
            local senderUnit=sender:GetAttribute("Unit")
            if type(senderUnit)~="string" or senderUnit=="" then
                senderUnit=if sender.Team and not sender.Neutral then sender.Team.Name else nil
            end
            if senderUnit==nil or reference.unit~=senderUnit then return false end
        end
        if kind=="e" and reference.authorId~=senderId then return false end
        if kind=="e" then
            -- The edit body goes through TextChatService filtering like a normal chat message.
            return true
        end
    end

    local unit=nil
    if channelId=="unit" then
        local sender=Players:GetPlayerByUserId(senderId)
        if sender then
            local attr=sender:GetAttribute("Unit")
            unit=if type(attr)=="string" and attr~="" then attr else (
                if sender.Team and not sender.Neutral then sender.Team.Name else nil
            )
        end
    end
    messages[newId]={id=newId,authorId=senderId,channelId=channelId,unit=unit,
        kind=kind,target=target,deleted=false,pinned=false,reactions={}}
    table.insert(order,newId)
    if #order>MAX_MESSAGES then
        local oldest=table.remove(order,1)
        messages[oldest]=nil
    end
    return true
end

local function invoke(player: Player, action: any, payload: any): any
    if type(action)~="string" or type(payload)~="table" then return {ok=false,message="잘못된 요청"} end
    if action=="snapshot" then
        local now=os.clock()
        if now-(lastSnapshot[player] or -100)<0.5 then
            return {ok=false,message="잠시 후 다시 불러오세요."}
        end
        lastSnapshot[player]=now
        return snapshot(player,payload.channelId)
    end
    local now=os.clock()
    if now-(lastAction[player] or -100)<0.15 then return {ok=false,message="너무 빠른 요청입니다."} end
    lastAction[player]=now
    local entry=entryFor(player,payload.id)
    if not entry then return {ok=false,message="메시지를 찾지 못했거나 접근 권한이 없습니다."} end

    if action=="react" then
        if not mayChat(player) or not Permissions.channel(player,entry.channelId,"write") then
            return {ok=false,message="이 채널에서 반응할 권한이 없습니다."}
        end
        local emoji=payload.emoji
        if not EMOJI[emoji] then return {ok=false,message="지원하지 않는 이모지입니다."} end
        local users=entry.reactions[emoji] or {}
        if users[player.UserId] then users[player.UserId]=nil else users[player.UserId]=true end
        entry.reactions[emoji]=users
        publish(entry,"reaction",{emoji=emoji, userId=player.UserId, active=users[player.UserId]==true})
        return {ok=true}
    elseif action=="pin" then
        if not canModerate(player,entry.channelId) then return {ok=false,message="고정 관리 권한이 없습니다."} end
        entry.pinned=not entry.pinned
        publish(entry,"pin",{pinned=entry.pinned})
        return {ok=true}
    elseif action=="delete" then
        if entry.authorId~=player.UserId and not canModerate(player,entry.channelId) then
            return {ok=false,message="자신의 메시지만 삭제할 수 있습니다."}
        end
        entry.deleted=true
        publish(entry,"delete",{})
        return {ok=true}
    end
    return {ok=false,message="지원하지 않는 작업입니다."}
end

function Actions.start()
    if started then return end
    started=true
    local remote=Instance.new("RemoteFunction")
    remote.Name="MessengerActions"
    remote.Parent=ReplicatedStorage
    local event=Instance.new("RemoteEvent")
    event.Name="MessengerActionsChanged"
    event.Parent=ReplicatedStorage
    request=remote
    changed=event
    remote.OnServerInvoke=invoke
    Players.PlayerRemoving:Connect(function(player)
        lastAction[player]=nil;lastSnapshot[player]=nil;chatEligibility[player]=nil
    end)
end

return Actions
