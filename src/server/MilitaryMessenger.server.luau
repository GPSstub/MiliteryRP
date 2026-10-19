-- MilitaryMessenger.server.luau
-- 군대 RP 실시간 채팅 서버

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- RankCatalog 기준 소위 = 11
local OFFICER_RANK = 11

local function getRank(player)
    return tonumber(player:GetAttribute("RankOrder")) or 0
end

local function getUnit(player)
    local unit = player:GetAttribute("Unit")

    if type(unit) == "string" and unit ~= "" then
        return unit
    end

    if player.Team and not player.Neutral then
        return player.Team.Name
    end

    return nil
end

local function getPlayer(textSource)
    if not textSource then
        return nil
    end

    return Players:GetPlayerByUserId(textSource.UserId)
end

-- Roblox 공식 채팅 채널 생성
-- 커스텀 TextChannel은 TextChatService 바로 아래에 둔다.
local function createChannel(name)
    local existing = TextChatService:FindFirstChild(name)

    if existing then
        assert(existing:IsA("TextChannel"), name .. " 이름 충돌")
        return existing
    end

    local channel = Instance.new("TextChannel")
    channel.Name = name
    channel.Parent = TextChatService

    return channel
end

local generalChannel = createChannel("RP_General")
local unitChannel = createChannel("RP_Unit")
local commandChannel = createChannel("RP_Command")
local noticeChannel = createChannel("RP_Notice")

-- 부대 채팅:
-- 같은 소속 부대의 플레이어에게만 메시지 전달
unitChannel.ShouldDeliverCallback = function(message, recipientSource)
    local sender = getPlayer(message.TextSource)
    local recipient = getPlayer(recipientSource)

    if not sender or not recipient then
        return false
    end

    local senderUnit = getUnit(sender)
    local recipientUnit = getUnit(recipient)

    return senderUnit ~= nil and senderUnit == recipientUnit
end

-- 지휘 채팅:
-- 소위 이상만 메시지 발신 및 수신
commandChannel.ShouldDeliverCallback = function(message, recipientSource)
    local sender = getPlayer(message.TextSource)
    local recipient = getPlayer(recipientSource)

    if not sender or not recipient then
        return false
    end

    return getRank(sender) >= OFFICER_RANK
        and getRank(recipient) >= OFFICER_RANK
end

-- 공지사항:
-- 소위 이상 작성, 모든 플레이어 수신
noticeChannel.ShouldDeliverCallback = function(message, recipientSource)
    local sender = getPlayer(message.TextSource)
    local recipient = getPlayer(recipientSource)

    if not sender or not recipient then
        return false
    end

    return getRank(sender) >= OFFICER_RANK
end

local function findSource(channel, player)
    for _, child in channel:GetChildren() do
        if child:IsA("TextSource")
            and child.UserId == player.UserId then
            return child
        end
    end

    return nil
end

local function ensureSource(channel, player)
    local existing = findSource(channel, player)

    if existing then
        return existing
    end

    local success, source = pcall(function()
        return channel:AddUserAsync(player.UserId)
    end)

    if not success then
        warn("[Messenger] 채널 참가 실패:", channel.Name, source)
        return nil
    end

    -- 채팅이 제한된 이용자는 nil이 반환될 수 있다.
    return source
end

-- 계급 또는 소속 변경 시 채널 권한 업데이트
local function refreshPlayer(player)
    if player.Parent ~= Players then
        return
    end

    local unitSource = ensureSource(unitChannel, player)
    local noticeSource = ensureSource(noticeChannel, player)

    if player.Parent ~= Players then
        return
    end

    if unitSource then
        unitSource.CanSend = getUnit(player) ~= nil
    end

    if noticeSource then
        noticeSource.CanSend = getRank(player) >= OFFICER_RANK
    end

    -- 지휘관만 지휘 채널에 가입
    local commandSource = findSource(commandChannel, player)

    if getRank(player) >= OFFICER_RANK then
        commandSource = commandSource or ensureSource(commandChannel, player)

        if commandSource then
            commandSource.CanSend = true
        end
    elseif commandSource then
        commandSource:Destroy()
    end
end

local function onPlayerAdded(player)
    player:GetAttributeChangedSignal("RankOrder"):Connect(function()
        task.spawn(refreshPlayer, player)
    end)

    player:GetAttributeChangedSignal("Unit"):Connect(function()
        task.spawn(refreshPlayer, player)
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        task.spawn(refreshPlayer, player)
    end)

    player:GetPropertyChangedSignal("Neutral"):Connect(function()
        task.spawn(refreshPlayer, player)
    end)

    task.spawn(refreshPlayer, player) 
    
    ensureSource(generalChannel, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

print("[MilitaryMessenger] 서버 시작 완료")