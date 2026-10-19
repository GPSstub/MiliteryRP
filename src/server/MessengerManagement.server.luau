--!strict
-- Server-side role and channel administration for the in-game messenger.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Permissions = require(script.Parent:WaitForChild("MessengerPermissions"))

local remote = Instance.new("RemoteFunction")
remote.Name = "MessengerManage"
remote.Parent = ReplicatedStorage

local changed = Instance.new("RemoteEvent")
changed.Name = "MessengerChannelsChanged"
changed.Parent = ReplicatedStorage

local channels: {[string]: {id: string, name: string, channel: string}} = {}
local nextId = 0
local lastRequest: {[Player]: number} = {}

local function announce()
    changed:FireAllClients()
end

local function snapshot()
    local result = {}
    for _, entry in channels do
        table.insert(result, table.clone(entry))
    end
    table.sort(result, function(a,b) return a.id < b.id end)
    return {channels = result, permissions = Permissions.snapshot()}
end

local function getPlayer(source: TextSource?): Player?
    if not source then return nil end
    return Players:GetPlayerByUserId(source.UserId)
end

local function join(channel: TextChannel, player: Player)
    if player.Parent ~= Players then return end
    local existing: TextSource? = nil
    for _, item in channel:GetChildren() do
        if item:IsA("TextSource") and item.UserId == player.UserId then
            existing = item
            break
        end
    end
    if not existing then
        local ok, source = pcall(function()
            return channel:AddUserAsync(player.UserId)
        end)
        if ok then existing = source else warn("[MessengerManage]", source) end
    end
    if existing then
        existing.CanSend = Permissions.has(player, "SEND_MESSAGES")
    end
end

local function refresh()
    for _, entry in channels do
        local channel = TextChatService:FindFirstChild(entry.channel)
        if channel and channel:IsA("TextChannel") then
            for _, player in Players:GetPlayers() do
                task.spawn(join, channel, player)
            end
        end
    end
    announce()
end

Permissions.Changed:Connect(refresh)
Players.PlayerAdded:Connect(function(player)
    for _, entry in channels do
        local channel = TextChatService:FindFirstChild(entry.channel)
        if channel and channel:IsA("TextChannel") then
            task.spawn(join, channel, player)
        end
    end
end)
Players.PlayerRemoving:Connect(function(player)
    lastRequest[player] = nil
end)

local function createChannel(actor: Player, name: any): (boolean, string)
    if not Permissions.has(actor, "CREATE_CHANNELS") then
        return false, "채널 개설 권한이 없습니다."
    end
    if type(name) ~= "string" then return false, "이름을 입력하세요." end
    name = name:match("^%s*(.-)%s*$")
    local len = utf8.len(name)
    if not len or len < 2 or len > 24 or name:find("[%c]") then
        return false, "채널 이름은 2~24자로 지정하세요."
    end
    local count = 0
    for _, entry in channels do
        count += 1
        if entry.name == name then return false, "이미 같은 채널이 있습니다." end
    end
    if count >= 8 then return false, "추가 채널은 최대 8개입니다." end
    nextId += 1
    local id = "custom_" .. tostring(nextId)
    local channelName = "RP_Custom_" .. tostring(nextId)
    local channel = Instance.new("TextChannel")
    channel.Name = channelName
    channel.ShouldDeliverCallback = function(message, recipient)
        local sender = getPlayer(message.TextSource)
        local receiver = getPlayer(recipient)
        return sender ~= nil and receiver ~= nil
            and Permissions.has(sender, "SEND_MESSAGES")
    end
    channel.Parent = TextChatService
    channels[id] = {id = id, name = name, channel = channelName}
    for _, player in Players:GetPlayers() do task.spawn(join, channel, player) end
    announce()
    return true, "채널 개설 완료"
end

local function deleteChannel(actor: Player, id: any): (boolean, string)
    if not Permissions.has(actor, "DELETE_CHANNELS") then
        return false, "채널 삭제 권한이 없습니다."
    end
    if type(id) ~= "string" or not channels[id] then
        return false, "삭제할 수 없는 채널입니다."
    end
    local channel = TextChatService:FindFirstChild(channels[id].channel)
    if channel then channel:Destroy() end
    channels[id] = nil
    announce()
    return true, "채널 삭제 완료"
end

local validCommands = {
    snapshot = true, create_channel = true, delete_channel = true,
    create_role = true, delete_role = true, set_permission = true,
    assign_role = true, remove_role = true,
}
remote.OnServerInvoke = function(actor: Player, action: any, data: any)
    if actor.Parent ~= Players or type(action) ~= "string" or not validCommands[action] then
        return {ok = false, message = "잘못된 요청입니다."}
    end
    local now = os.clock()
    if now - (lastRequest[actor] or -math.huge) < 0.15 then
        return {ok = false, message = "잠시 후 다시 시도하세요."}
    end
    lastRequest[actor] = now
    if action == "snapshot" then return {ok = true, data = snapshot()} end
    if type(data) ~= "table" then return {ok = false, message = "잘못된 입력입니다."} end
    local ok = false
    local message = ""
    if action == "create_channel" then
        ok, message = createChannel(actor, data.name)
    elseif action == "delete_channel" then
        ok, message = deleteChannel(actor, data.id)
    elseif action == "create_role" then
        ok, message = Permissions.createRole(actor, data.roleId, data.permissions)
    elseif action == "delete_role" then
        ok, message = Permissions.deleteRole(actor, data.roleId)
    elseif action == "set_permission" then
        ok, message = Permissions.setRolePermission(actor, data.roleId, data.permission, data.enabled)
    elseif action == "assign_role" or action == "remove_role" then
        local userId = data.userId
        local target = if type(userId) == "number" then Players:GetPlayerByUserId(userId) else nil
        if action == "assign_role" then
            ok, message = Permissions.assignRole(actor, target, data.roleId)
        else
            ok, message = Permissions.removeRole(actor, target, data.roleId)
        end
    else
        ok, message = false, "알 수 없는 요청입니다."
    end
    return {ok = ok, message = message}
end

print("[MessengerManage] Server role and channel controls ready")
