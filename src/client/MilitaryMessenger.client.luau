-- MilitaryMessenger.client.luau
-- Discord 스타일 군용 메신저 UI

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ==========================================
-- 테마
-- ==========================================

local C = {
    bg = Color3.fromRGB(27, 30, 37),
    sidebar = Color3.fromRGB(20, 23, 29),
    surface = Color3.fromRGB(37, 42, 51),
    hover = Color3.fromRGB(49, 56, 66),

    accent = Color3.fromRGB(106, 149, 113),
    accentLight = Color3.fromRGB(166, 207, 166),

    white = Color3.fromRGB(241, 242, 245),
    muted = Color3.fromRGB(153, 162, 174),
    border = Color3.fromRGB(58, 66, 76),

    warning = Color3.fromRGB(235, 185, 105),
}

-- ==========================================
-- 채널
-- ==========================================

local CHANNELS = {
    {
        id = "general",
        name = "전체 채팅",
        channel = "RP_General",
        description = "현재 서버의 모든 병사가 참여하는 채팅입니다.",
    },

    {
        id = "unit",
        name = "부대 채팅",
        channel = "RP_Unit",
        description = "같은 소속 부대의 병사끼리 통신합니다.",
    },

    {
        id = "command",
        name = "지휘 채팅",
        channel = "RP_Command",
        description = "소위 이상 지휘관 전용 통신입니다.",
    },

    {
        id = "notice",
        name = "공지사항",
        channel = "RP_Notice",
        description = "군 주요 공지사항을 확인합니다.",
    },
}

local channelIds = {}

for _, info in CHANNELS do
    channelIds[info.channel] = info.id
end

local function getRankOrder(target)
    return tonumber(target:GetAttribute("RankOrder")) or 0
end

local function getUnit(target)
    local unit = target:GetAttribute("Unit")

    if type(unit) == "string" and unit ~= "" then
        return unit
    end

    if target.Team and not target.Neutral then
        return target.Team.Name
    end

    return nil
end

local function canView(id)
    if id == "command" then
        return getRankOrder(player) >= 11
    end

    if id == "unit" then
        return getUnit(player) ~= nil
    end

    return true
end

local function canWrite(id)
    if id == "command" or id == "notice" then
        return getRankOrder(player) >= 11
    end

    if id == "unit" then
        return getUnit(player) ~= nil
    end

    return true
end

-- ==========================================
-- UI 생성 도우미
-- ==========================================

local function create(className, parent, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local function corner(object, radius)
    create("UICorner", object, {
        CornerRadius = UDim.new(0, radius),
    })
end

local function outline(object)
    create("UIStroke", object, {
        Color = C.border,
        Thickness = 1,
        Transparency = 0.3,
    })
end

local function label(parent, content, size, color, bold)
    return create("TextLabel", parent, {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Text = content,
        TextSize = size,
        TextColor3 = color,

        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,

        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function button(parent, content, color)
    local object = create("TextButton", parent, {
        BackgroundColor3 = color or C.surface,
        BorderSizePixel = 0,

        Text = content,
        TextColor3 = C.white,
        TextSize = 14,
        Font = Enum.Font.GothamBold,

        AutoButtonColor = true,
    })

    corner(object, 10)

    return object
end

-- ==========================================
-- GUI 루트
-- ==========================================

local gui = create("ScreenGui", player:WaitForChild("PlayerGui"), {
    Name = "MilitaryMessenger",
    ResetOnSpawn = false,
    DisplayOrder = 30,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
})

-- 오른쪽 중앙 버튼
local launcher = button(gui, "●  통신", C.sidebar)

launcher.Name = "CommunicationButton"
launcher.AnchorPoint = Vector2.new(1, 0.5)
launcher.Position = UDim2.new(1, -16, 0.5, 0)
launcher.Size = UDim2.fromOffset(112, 50)
launcher.TextSize = 16

corner(launcher, 12)
outline(launcher)

-- ==========================================
-- 메신저 창
-- ==========================================

local window = create("Frame", gui, {
    Name = "MessengerWindow",

    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),

    Size = UDim2.fromOffset(820, 550),

    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,

    ClipsDescendants = true,
    Visible = false,
})

corner(window, 16)
outline(window)

local windowScale = create("UIScale", window, {
    Scale = 1,
})

-- ==========================================
-- 상단 헤더
-- ==========================================

local header = create("Frame", window, {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
})

local title = label(
    header,
    "●  MILITARY NETWORK",
    17,
    C.white,
    true
)

title.Position = UDim2.fromOffset(18, 7)
title.Size = UDim2.new(1, -90, 0, 30)

local subtitle = label(
    header,
    "SECURE COMMUNICATION  /  RP NETWORK",
    10,
    C.muted,
    false
)

subtitle.Position = UDim2.fromOffset(39, 35)
subtitle.Size = UDim2.new(1, -100, 0, 14)

local closeButton = button(header, "×", C.surface)

closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 9)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.TextSize = 26

-- ==========================================
-- 왼쪽 채널 사이드바
-- ==========================================

local sidebar = create("Frame", window, {
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
})

local sideTitle = label(
    sidebar,
    "TEXT CHANNELS",
    11,
    C.muted,
    true
)

sideTitle.Position = UDim2.fromOffset(14, 18)
sideTitle.Size = UDim2.new(1, -28, 0, 24)

local channelButtons = {}

for index, info in CHANNELS do
    local row = button(sidebar, "#  " .. info.name, C.sidebar)

    row.Name = info.id
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextSize = 13

    row.Position = UDim2.fromOffset(
        10,
        54 + (index - 1) * 46
    )

    row.Size = UDim2.new(1, -20, 0, 40)

    channelButtons[info.id] = row
end

-- 내 프로필
local profile = create("Frame", sidebar, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 10, 1, -12),
    Size = UDim2.new(1, -20, 0, 62),

    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
})

corner(profile, 10)

local myName = label(
    profile,
    player.DisplayName,
    13,
    C.white,
    true
)

myName.Position = UDim2.fromOffset(12, 7)
myName.Size = UDim2.new(1, -24, 0, 24)

local myRank = label(
    profile,
    "훈련병",
    11,
    C.accentLight,
    false
)

myRank.Position = UDim2.fromOffset(12, 31)
myRank.Size = UDim2.new(1, -24, 0, 20)

-- ==========================================
-- 중앙 채팅 영역
-- ==========================================

local center = create("Frame", window, {
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
})

local channelTitle = label(
    center,
    "#  전체 채팅",
    18,
    C.white,
    true
)

channelTitle.Position = UDim2.fromOffset(16, 10)
channelTitle.Size = UDim2.new(1, -32, 0, 30)

local description = label(
    center,
    "현재 서버의 모든 병사가 참여하는 채팅입니다.",
    11,
    C.muted,
    false
)

description.Position = UDim2.fromOffset(17, 40)
description.Size = UDim2.new(1, -34, 0, 20)

create("Frame", center, {
    Position = UDim2.fromOffset(0, 68),
    Size = UDim2.new(1, 0, 0, 1),

    BackgroundColor3 = C.border,
    BorderSizePixel = 0,
})

-- 메시지 스크롤
local feed = create("ScrollingFrame", center, {
    Name = "Messages",

    Position = UDim2.fromOffset(12, 78),
    Size = UDim2.new(1, -24, 1, -159),

    BackgroundTransparency = 1,
    BorderSizePixel = 0,

    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.muted,

    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0, 0),
    ScrollingDirection = Enum.ScrollingDirection.Y,
})

create("UIListLayout", feed, {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 12),
})

create("UIPadding", feed, {
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
})

-- ==========================================
-- 메시지 입력창
-- ==========================================

local composer = create("Frame", center, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 12, 1, -12),
    Size = UDim2.new(1, -24, 0, 54),

    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
})

corner(composer, 10)

local input = create("TextBox", composer, {
    Name = "MessageInput",

    Position = UDim2.fromOffset(14, 5),
    Size = UDim2.new(1, -108, 1, -10),

    BackgroundTransparency = 1,
    BorderSizePixel = 0,

    Font = Enum.Font.Gotham,
    TextSize = 14,
    TextColor3 = C.white,
    PlaceholderColor3 = C.muted,

    PlaceholderText = "메시지 보내기...",
    Text = "",

    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    MultiLine = false,
})

local sendButton = button(composer, "전송", C.accent)

sendButton.AnchorPoint = Vector2.new(1, 0.5)
sendButton.Position = UDim2.new(1, -6, 0.5, 0)
sendButton.Size = UDim2.fromOffset(78, 42)

-- ==========================================
-- 오른쪽 접속자 목록
-- ==========================================

local members = create("Frame", window, {
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
})

local membersTitle = label(
    members,
    "ONLINE",
    12,
    C.muted,
    true
)

membersTitle.Position = UDim2.fromOffset(14, 18)
membersTitle.Size = UDim2.new(1, -28, 0, 24)

local membersFeed = create("ScrollingFrame", members, {
    Position = UDim2.fromOffset(8, 52),
    Size = UDim2.new(1, -16, 1, -64),

    BackgroundTransparency = 1,
    BorderSizePixel = 0,

    ScrollBarThickness = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0, 0),
})

create("UIListLayout", membersFeed, {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
})

-- ==========================================
-- 반응형 레이아웃
-- ==========================================

local function updateLayout()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local width = math.min(820, math.max(290, viewport.X - 24))
    local height = math.min(580, math.max(280, viewport.Y - 24))

    local sidebarWidth

    if width < 520 then
        sidebarWidth = 112
    elseif width < 720 then
        sidebarWidth = 155
    else
        sidebarWidth = 185
    end

    local memberWidth = width >= 740 and 160 or 0
    local centerWidth = width - sidebarWidth - memberWidth

    window.Size = UDim2.fromOffset(width, height)

    sidebar.Position = UDim2.fromOffset(0, 60)
    sidebar.Size = UDim2.fromOffset(sidebarWidth, height - 60)

    center.Position = UDim2.fromOffset(sidebarWidth, 60)
    center.Size = UDim2.fromOffset(centerWidth, height - 60)

    members.Position = UDim2.fromOffset(
        width - memberWidth,
        60
    )

    members.Size = UDim2.fromOffset(memberWidth, height - 60)
    members.Visible = memberWidth > 0
end

updateLayout()

local function connectCamera(camera)
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(
            updateLayout
        )

        updateLayout()
    end
end

connectCamera(workspace.CurrentCamera)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    connectCamera(workspace.CurrentCamera)
end)

-- ==========================================
-- 채팅 상태
-- ==========================================

local selectedChannel = "general"
local opened = false
local sending = false

local history = {
    general = {},
    unit = {},
    command = {},
    notice = {},
}

local unread = {
    general = 0,
    unit = 0,
    command = 0,
    notice = 0,
}

local seenMessages = {}
local seenQueue = {}

local previousUnit = getUnit(player)

local function getChannelInfo(id)
    for _, info in CHANNELS do
        if info.id == id then
            return info
        end
    end

    return CHANNELS[1]
end

local function updateChannelButtons()
    local totalUnread = 0

    for _, info in CHANNELS do
        local id = info.id
        local row = channelButtons[id]

        local allowed = canView(id)

        row.BackgroundColor3 = (
            selectedChannel == id and C.hover or C.sidebar
        )

        row.TextColor3 = allowed and C.white or C.muted

        local content = "#  " .. info.name

        if not allowed then
            content ..= "  ·"
        elseif unread[id] > 0 then
            content ..= "  •" .. tostring(unread[id])
        end

        row.Text = content

        if allowed then
            totalUnread += unread[id]
        end
    end

    launcher.Text = totalUnread > 0
        and ("●  통신  " .. tostring(totalUnread))
        or "●  통신"

    myRank.Text = tostring(
        player:GetAttribute("Rank") or "훈련병"
    )
end

-- ==========================================
-- 메시지 표시
-- ==========================================

local function scrollToBottom()
    task.delay(0.05, function()
        if not feed.Parent then
            return
        end

        feed.CanvasPosition = Vector2.new(
            0,
            math.max(
                0,
                feed.AbsoluteCanvasSize.Y - feed.AbsoluteWindowSize.Y
            )
        )
    end)
end

local function createMessage(entry, order)
    local row = create("Frame", feed, {
        Name = "Message",

        LayoutOrder = order,

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    local avatar = create("ImageLabel", row, {
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.fromOffset(36, 36),

        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,

        Image = (
            "rbxthumb://type=AvatarHeadShot&id="
            .. tostring(entry.userId)
            .. "&w=100&h=100"
        ),
    })

    corner(avatar, 18)

    local author = label(
        row,
        "[" .. entry.rank .. "] " .. entry.name .. "   " .. entry.time,
        13,
        C.accentLight,
        true
    )

    author.Position = UDim2.fromOffset(46, 0)
    author.Size = UDim2.new(1, -50, 0, 22)

    local messageText = label(
        row,
        entry.message,
        14,
        C.white,
        false
    )

    messageText.Position = UDim2.fromOffset(46, 24)
    messageText.Size = UDim2.new(1, -52, 0, 0)

    messageText.AutomaticSize = Enum.AutomaticSize.Y
    messageText.TextWrapped = true
    messageText.TextTruncate = Enum.TextTruncate.None
    messageText.TextYAlignment = Enum.TextYAlignment.Top
    messageText.RichText = false

    return row
end

local function renderMessages()
    for _, child in feed:GetChildren() do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local messages = history[selectedChannel]

    if #messages == 0 then
        local empty = label(
            feed,
            "아직 메시지가 없습니다.\n첫 번째 메시지를 보내 보세요.",
            14,
            C.muted,
            false
        )

        empty.Size = UDim2.new(1, -12, 0, 100)
        empty.TextWrapped = true
        empty.TextXAlignment = Enum.TextXAlignment.Center
    else
        for index, entry in messages do
            createMessage(entry, index)
        end
    end

    scrollToBottom()
end

-- ==========================================
-- 접속자 목록
-- ==========================================

local function renderMembers()
    for _, child in membersFeed:GetChildren() do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local count = 0

    for _, target in Players:GetPlayers() do
        local allowed = true

        if selectedChannel == "unit" then
            allowed = getUnit(player) ~= nil
                and getUnit(player) == getUnit(target)

        elseif selectedChannel == "command" then
            allowed = getRankOrder(target) >= 11
        end

        if allowed then
            count += 1

            local row = create("Frame", membersFeed, {
                LayoutOrder = count,

                Size = UDim2.new(1, 0, 0, 46),
                BackgroundTransparency = 1,
            })

            local avatar = create("ImageLabel", row, {
                Position = UDim2.fromOffset(2, 6),
                Size = UDim2.fromOffset(34, 34),

                BackgroundColor3 = C.surface,
                BorderSizePixel = 0,

                Image = (
                    "rbxthumb://type=AvatarHeadShot&id="
                    .. tostring(target.UserId)
                    .. "&w=100&h=100"
                ),
            })

            corner(avatar, 17)

            local name = label(
                row,
                target.DisplayName,
                12,
                C.white,
                true
            )

            name.Position = UDim2.fromOffset(44, 4)
            name.Size = UDim2.new(1, -47, 0, 20)

            local rank = label(
                row,
                tostring(target:GetAttribute("Rank") or "훈련병"),
                10,
                C.muted,
                false
            )

            rank.Position = UDim2.fromOffset(44, 24)
            rank.Size = UDim2.new(1, -47, 0, 17)
        end
    end

    membersTitle.Text = "ONLINE  ·  " .. tostring(count)
end

-- ==========================================
-- 채널 선택
-- ==========================================

local function selectChannel(id)
    if not canView(id) then
        description.Text = "이 채널에 접근할 권한이 없습니다."
        return
    end

    selectedChannel = id
    unread[id] = 0

    local info = getChannelInfo(id)

    channelTitle.Text = "#  " .. info.name
    description.Text = info.description

    if id == "unit" then
        description.Text = "소속 부대: " .. tostring(getUnit(player))
    end

    local writable = canWrite(id)

    input.TextEditable = writable

    input.PlaceholderText = writable
        and "메시지 보내기..."
        or "읽기 전용 채널입니다."

    sendButton.Text = writable and "전송" or "읽기 전용"

    sendButton.BackgroundColor3 = writable
        and C.accent
        or C.hover

    updateChannelButtons()
    renderMessages()
    renderMembers()
end

for _, info in CHANNELS do
    local id = info.id

    channelButtons[id].Activated:Connect(function()
        selectChannel(id)
    end)
end

-- ==========================================
-- 플레이어 정보 변화 감지
-- ==========================================

local function updateAccess()
    local currentUnit = getUnit(player)

    -- 소속 부대 변경 시 이전 부대의 채팅 기록 제거
    if currentUnit ~= previousUnit then
        previousUnit = currentUnit
        history.unit = {}
        unread.unit = 0
    end

    -- 지휘관 권한 상실 시 이전 지휘 채팅 기록 제거
    if getRankOrder(player) < 11 then
        history.command = {}
        unread.command = 0
    end

    if not canView(selectedChannel) then
        selectedChannel = "general"
    end

    selectChannel(selectedChannel)
end

local playerConnections = {}

local function watchPlayer(target)
    if playerConnections[target] then
        return
    end

    playerConnections[target] = {
        target:GetAttributeChangedSignal("Rank"):Connect(
            updateAccess
        ),

        target:GetAttributeChangedSignal("RankOrder"):Connect(
            updateAccess
        ),

        target:GetAttributeChangedSignal("Unit"):Connect(
            updateAccess
        ),

        target:GetPropertyChangedSignal("Team"):Connect(
            updateAccess
        ),

        target:GetPropertyChangedSignal("Neutral"):Connect(
            updateAccess
        ),
    }
end

for _, target in Players:GetPlayers() do
    watchPlayer(target)
end

Players.PlayerAdded:Connect(function(target)
    watchPlayer(target)
    renderMembers()
end)

Players.PlayerRemoving:Connect(function(target)
    local connections = playerConnections[target]

    if connections then
        for _, connection in connections do
            connection:Disconnect()
        end
    end

    playerConnections[target] = nil

    task.defer(renderMembers)
end)

-- ==========================================
-- 메시지 수신
-- ==========================================

TextChatService.MessageReceived:Connect(function(message)
    if not message.TextChannel then
        return
    end

    if not message.TextSource then
        return
    end

    -- 처리 중인 로컬 메시지는 표시하지 않음
    if message.Status ~= Enum.TextChatMessageStatus.Success then
        return
    end

    local channelName = message.TextChannel.Name
    local id = channelIds[channelName]

    if not id then
        return
    end

    if not canView(id) then
        return
    end

    -- 중복 메시지 방지
    local messageId = message.MessageId

    if messageId and messageId ~= "" then
        if seenMessages[messageId] then
            return
        end

        seenMessages[messageId] = true
        table.insert(seenQueue, messageId)

        if #seenQueue > 250 then
            local oldest = table.remove(seenQueue, 1)
            seenMessages[oldest] = nil
        end
    end

    local userId = message.TextSource.UserId
    local sender = Players:GetPlayerByUserId(userId)

    local entry = {
        userId = userId,

        name = sender
            and sender.DisplayName
            or "Unknown",

        rank = sender
            and tostring(sender:GetAttribute("Rank") or "훈련병")
            or "알 수 없음",

        message = message.Text,
        time = os.date("%H:%M"),
    }

    table.insert(history[id], entry)

    -- 채널당 최근 80개 메시지만 메모리에 보관
    if #history[id] > 80 then
        table.remove(history[id], 1)
    end

    if opened and selectedChannel == id then
        renderMessages()
    else
        unread[id] += 1
    end

    updateChannelButtons()
end)

-- ==========================================
-- 메시지 전송
-- ==========================================

local function sendMessage()
    if sending then
        return
    end

    if not canWrite(selectedChannel) then
        description.Text = "메시지 작성 권한이 없습니다."
        return
    end

    local content = input.Text:match("^%s*(.-)%s*$")

    if not content or content == "" then
        return
    end

    local characterCount = utf8.len(content)

    if not characterCount or characterCount > 180 then
        description.Text = "메시지는 180자 이내로 작성해 주세요."
        return
    end

    local id = selectedChannel
    local info = getChannelInfo(id)

    sending = true
    sendButton.Text = "..."

    input.Text = ""

    task.spawn(function()
        local success, result = pcall(function()
        local channel = TextChatService:WaitForChild(info.channel, 10)

        if not channel or not channel:IsA("TextChannel") then
        error("채팅 채널을 찾을 수 없습니다.")
        end

        return channel:SendAsync(content)
    end)

        sending = false

        if selectedChannel == id then
            sendButton.Text = canWrite(id)
                and "전송"
                or "읽기 전용"
        end

        if not success then
            warn("[Messenger] 메시지 전송 실패:", result)

            description.Text = "전송 실패. Output 창을 확인해 주세요."

            if input.Text == "" then
                input.Text = content
            end

        elseif result.Status ~= Enum.TextChatMessageStatus.Success then
            description.Text = "메시지 전송 제한: "
                .. result.Status.Name
        end
    end)
end

sendButton.Activated:Connect(sendMessage)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendMessage()
    end
end)

-- ==========================================
-- 메신저 열기 / 닫기
-- ==========================================

local function setOpen(state)
    opened = state

    launcher.Visible = not state
    window.Visible = state

    if state then
        windowScale.Scale = 0.94

        TweenService:Create(
            windowScale,
            TweenInfo.new(
                0.18,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ),
            {
                Scale = 1,
            }
        ):Play()

        selectChannel(selectedChannel)
    else
        input:ReleaseFocus()
    end
end

launcher.Activated:Connect(function()
    setOpen(true)
end)

closeButton.Activated:Connect(function()
    setOpen(false)
end)

-- M키로 열기 / 닫기
UserInputService.InputBegan:Connect(function(key, processed)
    if processed then
        return
    end

    if key.KeyCode == Enum.KeyCode.M then
        setOpen(not opened)
    end
end)

-- ==========================================
-- 초기화
-- ==========================================

selectChannel("general")
updateChannelButtons()

print("[MilitaryMessenger] 클라이언트 UI 시작 완료")