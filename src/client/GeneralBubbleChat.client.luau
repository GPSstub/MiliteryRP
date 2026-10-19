--!strict
-- GeneralBubbleChat.client.luau
-- 일반 채팅에만 말풍선 표시

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- 자동 말풍선 비활성화
local bubbleConfig = TextChatService:WaitForChild("BubbleChatConfiguration")
bubbleConfig.Enabled = false

-- 수신한 메시지 확인
TextChatService.MessageReceived:Connect(function(message)

    -- 정상적으로 전달된 메시지만 처리
    if message.Status ~= Enum.TextChatMessageStatus.Success then
        return
    end

    if not message.TextChannel or not message.TextSource then
        return
    end

    -- 일반 Roblox 채팅 메시지만 말풍선 표시
    if message.TextChannel.Name ~= "RBXGeneral" then
        return
    end

    local sender = Players:GetPlayerByUserId(
        message.TextSource.UserId
    )

    if not sender or not sender.Character then
        return
    end

    -- 이미 필터링된 메시지로 말풍선 생성
    TextChatService:DisplayBubble(
        sender.Character,
        message.Text
    )

end)