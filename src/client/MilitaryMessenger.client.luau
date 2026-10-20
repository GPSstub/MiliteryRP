--!strict
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

local channelAccess = {}
local memberRoleLabels: {[string]: {string}}={}
local function canView(id)
    if not channelAccess[id] or not channelAccess[id].canRead then return false end
    if id == "command" then
        return player:GetAttribute("MessengerCanViewCommand") == true
    end

    if id == "unit" then
        return getUnit(player) ~= nil
    end

    return true
end

local function canWrite(id)
    if not channelAccess[id] or not channelAccess[id].canWrite then return false end
    if player:GetAttribute("MessengerCanSend") ~= true then
        return false
    end

    if id == "command" then
        return player:GetAttribute("MessengerCanWriteCommand") == true
    end

    if id == "notice" then
        return player:GetAttribute("MessengerCanPostNotices") == true
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
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
})

local title = label(
    header,
    "국군 생활 RP",
    17,
    C.white,
    true
)

title.Position = UDim2.fromOffset(18, 7)
title.Size = UDim2.new(1, -190, 0, 30)

local subtitle = label(
    header,
    "통신망  ·  채널과 역할로 연결되는 부대",
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
    Name = "ChannelSidebar",
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
})

local sideTitle = label(
    sidebar,
    "텍스트 채널",
    11,
    C.muted,
    true
)

sideTitle.Position = UDim2.fromOffset(14, 18)
sideTitle.Size = UDim2.new(1, -62, 0, 24)

local channelButtons = {}
local channelsScroll = create("ScrollingFrame", sidebar, {
    Name = "ChannelList",
    Position = UDim2.fromOffset(0, 96),
    Size = UDim2.new(1, 0, 1, -178),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0, 0),
})
for index, info in CHANNELS do
    local row = button(channelsScroll, "#  " .. info.name, C.sidebar)

    row.Name = info.id
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextSize = 13

    row.Position = UDim2.fromOffset(
        10,
        10 + (index - 1) * 46
    )

    row.Size = UDim2.new(1, -20, 0, 40)

    channelButtons[info.id] = row
end

local channelSearch = create("TextBox", sidebar, {
    Name = "ChannelSearch", Position = UDim2.fromOffset(10, 48), Size = UDim2.new(1, -20, 0, 40),
    BackgroundColor3 = C.surface, BorderSizePixel = 0, Text = "", PlaceholderText = "채널 찾기",
    TextColor3 = C.white, PlaceholderColor3 = C.muted, TextSize = 14, Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
})
corner(channelSearch, 8)
local channelToggle = button(header, "채널", C.surface)
channelToggle.Name = "ChannelDrawerButton"
channelToggle.Position = UDim2.fromOffset(10, 9)
channelToggle.Size = UDim2.fromOffset(52, 42)
channelToggle.Visible = false
local drawerOpen = false
local compact = false

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
    Name = "Conversation",
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
channelTitle.Size = UDim2.new(1, -172, 0, 30)

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

local messageSearch = create("TextBox", center, {
    Name = "MessageSearch", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10),
    Size = UDim2.fromOffset(144, 32), BackgroundColor3 = C.sidebar, BorderSizePixel = 0,
    Text = "", PlaceholderText = "대화 검색", TextColor3 = C.white, PlaceholderColor3 = C.muted,
    TextSize = 13, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
})
corner(messageSearch, 6)

-- Discord-style channel actions: pins, notification mute and mark-as-read.
local pinsButton = button(center, "📌", C.surface)
pinsButton.Name="PinnedMessagesButton"
pinsButton.Position=UDim2.new(1,-88,0,40)
pinsButton.Size=UDim2.fromOffset(34,26)
pinsButton.TextSize=15
local muteButton = button(center, "🔔", C.surface)
muteButton.Name="ChannelMuteButton"
muteButton.Position=UDim2.new(1,-48,0,40)
muteButton.Size=UDim2.fromOffset(34,26)
muteButton.TextSize=15
local markReadButton = button(center, "✓", C.surface)
markReadButton.Name="MarkReadButton"
markReadButton.Position=UDim2.new(1,-128,0,40)
markReadButton.Size=UDim2.fromOffset(34,26)
markReadButton.TextSize=15

local threadBackButton = button(center, "←  스레드 나가기", C.surface)
threadBackButton.Name="ThreadBackButton"
threadBackButton.Position=UDim2.fromOffset(12,72)
threadBackButton.Size=UDim2.new(1,-24,0,30)
threadBackButton.Visible=false

local modeBar = create("Frame", center, {
    Name="MessageModeBar", BackgroundColor3=C.sidebar,BorderSizePixel=0,
    Position=UDim2.new(0,12,1,-124), Size=UDim2.new(1,-24,0,30),Visible=false,
})
corner(modeBar,6)
local modeCaption = label(modeBar,"",12,C.accentLight,false)
modeCaption.Position=UDim2.fromOffset(10,0)
modeCaption.Size=UDim2.new(1,-45,1,0)
local modeCancel = button(modeBar,"×",C.hover)
modeCancel.Position=UDim2.new(1,-32,0,2)
modeCancel.Size=UDim2.fromOffset(28,26)

-- Pins are only available for messages delivered during this game session.
local pinsPanel = create("Frame",center,{
    Name="PinnedMessagesPanel",Position=UDim2.new(0,12,0,78),Size=UDim2.new(1,-24,1,-174),
    BackgroundColor3=C.sidebar,BorderSizePixel=0,Visible=false,ZIndex=10,
})
corner(pinsPanel,10)
local pinsHeading=label(pinsPanel,"📌  고정 메시지 · 현재 접속 기록",15,C.white,true)
pinsHeading.Position=UDim2.fromOffset(12,8)
pinsHeading.Size=UDim2.new(1,-60,0,30)
pinsHeading.ZIndex=11
local pinsClose=button(pinsPanel,"×",C.hover)
pinsClose.Position=UDim2.new(1,-43,0,8)
pinsClose.Size=UDim2.fromOffset(30,30)
pinsClose.ZIndex=11
local pinsList=create("ScrollingFrame",pinsPanel,{
    Name="PinnedList",Position=UDim2.fromOffset(8,46),Size=UDim2.new(1,-16,1,-54),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
    AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),
    ZIndex=11,
})
create("UIListLayout",pinsList,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)})
-- 메시지 스크롤
local feed = create("ScrollingFrame", center, {
    Name = "Messages",

    Position = UDim2.fromOffset(12, 78),
    Size = UDim2.new(1, -24, 1, -212),

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
    Position = UDim2.new(0, 12, 1, -30),
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

local composerHint = label(center, "Enter로 전송  ·  0 / 180", 11, C.muted, false)
composerHint.Name = "ComposerHint"
composerHint.Position = UDim2.new(0, 18, 1, -26)
composerHint.Size = UDim2.new(1, -36, 0, 22)
local newMessages = button(center, "새 메시지 ↓", C.accent)
newMessages.Name = "NewMessageNotice"
newMessages.AnchorPoint = Vector2.new(0.5, 1)
newMessages.Position = UDim2.new(0.5, 0, 1, -90)
newMessages.Size = UDim2.new(1, -40, 0, 40)
newMessages.ZIndex = 5
newMessages.Visible = false

-- ==========================================
-- 오른쪽 접속자 목록
-- ==========================================

local members = create("Frame", window, {
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
})

local membersTitle = label(
    members,
    "접속 중",
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

local function updateLayout(viewportOverride: Vector2?)
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = viewportOverride or camera.ViewportSize

    local width = math.min(1080, math.max(260, viewport.X - 24))
    local height = math.min(720, math.max(240, viewport.Y - 84))
    compact = width < 640
    local sidebarWidth = if compact then (if drawerOpen then width else 0) else (if width < 840 then 190 else 220)
    local memberWidth = if width >= 960 then 190 else 0
    local centerWidth = width - (if compact then 0 else sidebarWidth) - memberWidth
    window.Size = UDim2.fromOffset(width, height)
    sidebar.Position = UDim2.fromOffset(0, 60)
    sidebar.Size = UDim2.fromOffset(sidebarWidth, height - 60)
    sidebar.Visible = not compact or drawerOpen
    center.Position = UDim2.fromOffset(if compact then 0 else sidebarWidth, 60)
    center.Size = UDim2.fromOffset(centerWidth, height - 60)
    center.Visible = not compact or not drawerOpen
    members.Position = UDim2.fromOffset(width - memberWidth, 60)
    members.Size = UDim2.fromOffset(memberWidth, height - 60)
    members.Visible = memberWidth > 0
    channelToggle.Visible = compact
    title.Position = UDim2.fromOffset(if compact then 72 else 18, 7)
    title.Size = UDim2.new(1, if compact then -215 else -170, 0, 30)
    subtitle.Visible = not compact
    channelTitle.TextSize = if centerWidth < 390 then 15 else 18
    messageSearch.Size = UDim2.fromOffset(if centerWidth < 390 then 108 else 144, 32)
    channelTitle.Size = UDim2.new(1, if centerWidth < 390 then -132 else -172, 0, 30)
    markReadButton.Visible = centerWidth >= 420
    pinsButton.Position=UDim2.new(1,-88,0,40)
    muteButton.Position=UDim2.new(1,-48,0,40)
    threadBackButton.Size=UDim2.new(1,-24,0,30)
    description.Size=UDim2.new(1,if centerWidth<390 then -114 else -154,0,20)

end

channelToggle.Activated:Connect(function() drawerOpen = not drawerOpen; updateLayout() end)
updateLayout()

local cameraConnection: RBXScriptConnection? = nil
local function connectCamera(camera)
    if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(
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
local drafts = {}
local scrollPositions = {}
local pendingMessages = {}
local restoringDraft = false
local renderGeneration = 0

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

local messageOrder = 1000
local seenMessages = {}
local seenQueue = {}

local previousUnit = getUnit(player)

-- Message bodies remain in TextChatService/local client memory. Only session metadata
-- (IDs, emoji reactions, pin/delete state) goes through the authorized server API.
local HttpService=game:GetService("HttpService")
local Protocol=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MessengerActionProtocol"))
local actionRemote=game:GetService("ReplicatedStorage"):WaitForChild("MessengerActions") :: RemoteFunction
local actionChanged=game:GetService("ReplicatedStorage"):WaitForChild("MessengerActionsChanged") :: RemoteEvent
local archiveRemote=game:GetService("ReplicatedStorage"):WaitForChild("MessengerArchive") :: RemoteFunction
local archiveChanged=game:GetService("ReplicatedStorage"):WaitForChild("MessengerArchiveChanged") :: RemoteEvent
local archiveLoaded: {[string]: boolean}={}
local archiveLoading: {[string]: boolean}={}
local archiveCursor: {[string]: number?}={}
local archiveLastFetch: {[string]: number}={}
local archiveDirty: {[string]: boolean}={}
local archiveWantedRevision: {[string]: number}={}
local loadArchive: (string,number?)->() = function() end
local mutedChannels: {[string]: boolean} = {}
local replyTarget: any? = nil
local editTarget: any? = nil
local threadRoot: string? = nil
local expandedMenu: string? = nil
local expandedEmoji: string? = nil
local renderMessages: () -> () = function() end
local reactionChoices={"👍","❤️","😂","🔥","✅","🎉"}

local function findEntry(messageId: any): any?
    if type(messageId)~="string" or messageId=="" then return nil end
    for _, messages in history do
        for _, item in messages do
            if item.id==messageId then return item end
        end
    end
    return nil
end

local function updateMode()
    modeBar.Visible = editTarget~=nil or replyTarget~=nil or threadRoot~=nil
    if editTarget then
        modeCaption.Text="수정 중 · "..editTarget.name.."의 메시지"
    elseif replyTarget then
        modeCaption.Text="↩ "..replyTarget.name.."에게 답장"
    elseif threadRoot then
        modeCaption.Text="⌗ 스레드에서 대화 중"
    end
    threadBackButton.Visible=threadRoot~=nil
    feed.Position=UDim2.fromOffset(12,if threadRoot then 112 else 78)
    feed.Size=UDim2.new(1,-24,1,if threadRoot then -246 else -212)
end

local function requestAction(action: string, entry: any, emoji: string?)
    if not entry.id or entry.id=="" then
        description.Text="이 메시지는 반응 기능을 사용할 수 없습니다."
        return
    end
    task.spawn(function()
        local ok,result=pcall(function()
            if channelAccess[entry.channelId or selectedChannel]
            and channelAccess[entry.channelId or selectedChannel].persistent then
            return archiveRemote:InvokeServer("mutate",{
                channelId=entry.channelId or selectedChannel,
                id=entry.id,mode=action,emoji=emoji,
            })
        end
        return actionRemote:InvokeServer(action,{id=entry.id,emoji=emoji})
        end)
        if not ok or type(result)~="table" or result.ok~=true then
            description.Text=(if ok and type(result)=="table" then result.message else nil)
                or "요청을 처리할 수 없습니다."
        end
    end)
end

local function beginReply(entry: any, inThread: boolean)
    if not canWrite(selectedChannel) then
        description.Text="답장 권한이 없습니다."
        return
    end
    editTarget=nil
    if inThread then
        threadRoot=entry.threadRoot or entry.id
        replyTarget=nil
        renderMessages()
    else
        replyTarget=entry
    end
    updateMode()
    input:CaptureFocus()
end

local function beginEdit(entry: any)
    if entry.userId~=player.UserId or not canWrite(selectedChannel) then return end
    replyTarget=nil
    editTarget=entry
    input.Text=entry.message
    updateMode()
    input:CaptureFocus()
end

local function jumpToMessage(messageId: string)
    renderMessages()
    task.delay(0.08,function()
        for _, child in feed:GetChildren() do
            if child:IsA("Frame") and child:GetAttribute("MessageId")==messageId then
                local y=child.AbsolutePosition.Y-feed.AbsolutePosition.Y+feed.CanvasPosition.Y
                feed.CanvasPosition=Vector2.new(0,math.max(0,y-12))
                return
            end
        end
        description.Text="이 메시지는 현재 화면에 없습니다."
    end)
end

local function refreshPins()
    for _, obj in pinsList:GetChildren() do
        if obj:IsA("GuiObject") then obj:Destroy() end
    end
    local count=0
    for index=#(history[selectedChannel] or {}),1,-1 do
        local item=history[selectedChannel][index]
        if item.pinned and not item.deleted then
            count+=1
            local b=button(pinsList,item.name.."  ·  "..item.message,C.surface)
            b.Size=UDim2.new(1,-8,0,50)
            b.LayoutOrder=count
            b.TextSize=12
            b.TextWrapped=true
            b.TextXAlignment=Enum.TextXAlignment.Left
            b.ZIndex=11
            b.Activated:Connect(function()
                pinsPanel.Visible=false
                threadRoot=nil
                updateMode()
                jumpToMessage(item.id)
            end)
        end
    end
    if count==0 then
        local empty=label(pinsList,"현재 접속 중 확인한 고정 메시지가 없습니다.",13,C.muted,false)
        empty.Size=UDim2.new(1,-8,0,45)
        empty.ZIndex=11
    end
end

local function searchMatches(entry: any, query: string): boolean
    local terms={}
    local filters={}
    for token in query:gmatch("%S+") do
        local key,value=token:match("^(%w+):(.+)$")
        if key and table.find({"from","in","before","after","has","is"},key) then
            filters[key]=string.lower(value)
        else
            table.insert(terms,string.lower(token))
        end
    end
    if filters["in"] then
        local info=channelAccess[selectedChannel]
        local channelName=if info then string.lower(info.name) else selectedChannel
        if filters["in"]~=string.lower(selectedChannel) and
            not string.find(channelName,filters["in"],1,true) then return false end
    end
    if filters["from"] then
        local sender=string.lower(entry.name)
        if not string.find(sender,filters["from"],1,true) and
            tostring(entry.userId)~=filters["from"] then return false end
    end
    if filters["has"]=="pin" and not entry.pinned then return false end
    if filters["is"]=="thread" and not entry.threadRoot then return false end
    if filters["before"] and (not entry.date or entry.date>=filters["before"]) then return false end
    if filters["after"] and (not entry.date or entry.date<=filters["after"]) then return false end
    local haystack=string.lower(entry.name.." "..entry.message)
    for _,term in terms do
        if not string.find(haystack,term,1,true) then return false end
    end
    return true
end

modeCancel.Activated:Connect(function()
    editTarget=nil
    replyTarget=nil
    if threadRoot then
        threadRoot=nil
        renderMessages()
    end
    updateMode()
end)
threadBackButton.Activated:Connect(function()
    threadRoot=nil
    replyTarget=nil
    editTarget=nil
    updateMode()
    renderMessages()
end)
pinsClose.Activated:Connect(function() pinsPanel.Visible=false end)
pinsButton.Activated:Connect(function()
    pinsPanel.Visible=not pinsPanel.Visible
    if pinsPanel.Visible then refreshPins() end
end)

local lastStateSync: {[string]: number} = {}
local function syncMessageActions(channelId: string)
    local now=os.clock()
    if now-(lastStateSync[channelId] or -100)<3 then return end
    lastStateSync[channelId]=now
    task.spawn(function()
        local ok,result=pcall(function()
            return actionRemote:InvokeServer("snapshot",{channelId=channelId})
        end)
        if not ok or type(result)~="table" or not result.ok then return end
        local updated=false
        for _,info in result.data or {} do
            local entry=findEntry(info.id)
            if entry and entry.channelId==channelId then
                entry.pinned=info.pinned==true
                entry.reactions=info.reactions or {}
                updated=true
            end
        end
        if updated and selectedChannel==channelId then
            renderMessages()
            if pinsPanel.Visible then refreshPins() end
        end
    end)
end

local function getChannelInfo(id)
    for _, info in CHANNELS do
        if info.id == id then
            return info
        end
    end

    return CHANNELS[1]
end

-- Read only published, server-filtered bulletin posts, never raw user text.
-- Cursor is a monotonically increasing sequence rather than an array index,
-- so removing older posts cannot shift the paging boundary.
loadArchive = function(channelId: string,before: number?)
    if archiveLoading[channelId] or not canView(channelId)
        or not (channelAccess[channelId] and channelAccess[channelId].persistent) then return end
    local now=os.clock()
    if now-(archiveLastFetch[channelId] or -math.huge)<0.65 then
        archiveDirty[channelId]=true
        task.delay(0.85,function()
            if archiveDirty[channelId] and channelId==selectedChannel then
                archiveDirty[channelId]=false
                loadArchive(channelId,before)
            end
        end)
        return
    end
    archiveLastFetch[channelId]=now
    archiveLoading[channelId]=true
    task.spawn(function()
        local ok,result=pcall(function()
            return archiveRemote:InvokeServer("load",{channelId=channelId,before=before})
        end)
        archiveLoading[channelId]=false
        if not ok or type(result)~="table" or result.ok~=true then
            if selectedChannel==channelId then
                description.Text=(if ok and type(result)=="table" then result.message else nil)
                    or "영구 기록을 불러오지 못했습니다. 다시 시도해 주세요."
            end
            return
        end
        if not canView(channelId) or not (channelAccess[channelId] and channelAccess[channelId].persistent) then
            return
        end
        local previous=history[channelId] or {}
        local byId={}
        for _,item in previous do
            if item.seq then byId[item.id]=item end
        end
        -- Newest-page refresh deletes locally cached posts which disappeared
        -- from that page (e.g. administrator delete or a revoked message).
        if before==nil then
            local smallest=math.huge
            local currentIds={}
            for _,entry in result.entries or {} do
                if type(entry.seq)=="number" then
                    smallest=math.min(smallest,entry.seq)
                    currentIds[entry.id]=true
                end
            end
            if smallest==math.huge then
                byId={}
            else
                for id,entry in byId do
                    if entry.seq>=smallest and not currentIds[id] then byId[id]=nil end
                end
            end
        end
        for _,item in result.entries or {} do
            if type(item.id)=="string" and type(item.message)=="string" and type(item.seq)=="number" then
                item.channelId=channelId
                item.time=item.timeLabel or "이전 기록"
                item.reactions=item.reactions or {}
                item.deleted=false
                byId[item.id]=item
            end
        end
        local merged={}
        for _,item in byId do table.insert(merged,item) end
        table.sort(merged,function(a,b) return a.seq<b.seq end)
        -- Bound client memory to the server's 300-post maximum.
        while #merged>300 do table.remove(merged,1) end
        for _,item in merged do item.threadCount=0 end
        local roots={}
        for _,item in merged do roots[item.id]=item end
        for _,item in merged do
            if item.threadRoot and roots[item.threadRoot] then
                roots[item.threadRoot].threadCount+=1
            end
        end
        history[channelId]=merged
        archiveCursor[channelId]=result.cursor
        archiveLoaded[channelId]=true
        local wanted=archiveWantedRevision[channelId] or 0
        local received=if type(result.revision)=="number" then result.revision else 0
        archiveDirty[channelId]=received<wanted
        if archiveDirty[channelId] and channelId==selectedChannel then
            task.delay(0.8,function()
                if archiveDirty[channelId] and not archiveLoading[channelId]
                    and channelId==selectedChannel then
                    loadArchive(channelId)
                end
            end)
        end
        if channelId==selectedChannel then
            renderMessages()
            if pinsPanel.Visible then refreshPins() end
        end
    end)
end

local lastArchiveLookup: {[string]: number}={}
archiveChanged.OnClientEvent:Connect(function(data: any)
    if type(data)~="table" or type(data.channelId)~="string" then return end
    local id=data.channelId
    archiveDirty[id]=true
    if type(data.revision)=="number" then
        archiveWantedRevision[id]=math.max(archiveWantedRevision[id] or 0,data.revision)
    end
    local messageId=data.id
    if type(messageId)=="string" and canView(id) then
        if data.action=="delete" then
            local list=history[id] or {}
            for index=#list,1,-1 do
                if list[index].id==messageId then table.remove(list,index) end
            end
            if editTarget and editTarget.id==messageId then editTarget=nil end
            if replyTarget and replyTarget.id==messageId then replyTarget=nil end
            updateMode()
            if id==selectedChannel then
                renderMessages()
                if pinsPanel.Visible then refreshPins() end
            end
        elseif data.action=="edit" or data.action=="pin" or data.action=="react" then
            local existing=findEntry(messageId)
            if existing and os.clock()-(lastArchiveLookup[messageId] or -math.huge)>0.4 then
                lastArchiveLookup[messageId]=os.clock()
                task.spawn(function()
                    local ok,result=pcall(function()
                        return archiveRemote:InvokeServer("lookup",{channelId=id,id=messageId})
                    end)
                    if not ok or type(result)~="table" or not result.ok then return end
                    if not canView(id) then return end
                    if result.entry then
                        result.entry.channelId=id
                        result.entry.time=result.entry.timeLabel or "이전 기록"
                        local list=history[id] or {}
                        for index,item in list do
                            if item.id==messageId then
                                list[index]=result.entry
                                break
                            end
                        end
                        if id==selectedChannel then
                            renderMessages()
                            if pinsPanel.Visible then refreshPins() end
                        end
                    end
                end)
            end
        end
    end
    if id==selectedChannel and canView(id) then
        task.delay(0.8,function()
            if archiveDirty[id] and id==selectedChannel and not archiveLoading[id] then
                archiveDirty[id]=false
                loadArchive(id)
            end
        end)
    end
end)

local function updateChannelButtons()
    local totalUnread = 0

    local visibleIndex = 0
    local query = string.lower(channelSearch.Text)
    for _, info in CHANNELS do
        local id = info.id
        local row = channelButtons[id]

        local allowed = canView(id)

        row.Visible = allowed and (query == "" or string.find(string.lower(info.name), query, 1, true) ~= nil)
        if row.Visible then
            row.Position = UDim2.fromOffset(10, 8 + visibleIndex * 46)
            visibleIndex += 1
        end
        row.BackgroundColor3 = (
            selectedChannel == id and C.hover or C.sidebar
        )

        row.TextColor3 = allowed and C.white or C.muted

        local content = "#  " .. info.name
        if mutedChannels[id] then content ..= "  🔕" end

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

    channelsScroll.CanvasSize = UDim2.fromOffset(0, 16 + visibleIndex * 46)
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

local function updateNotice()
    local count = pendingMessages[selectedChannel] or 0
    newMessages.Visible = count > 0 and messageSearch.Text == ""
    newMessages.Text = "새 메시지 " .. tostring(count) .. "개  ·  확인하기 ↓"
end

local function acknowledgeMessages()
    pendingMessages[selectedChannel] = 0
    unread[selectedChannel] = 0
    updateNotice()
    updateChannelButtons()
end

-- New messages never write CanvasPosition. Only this explicit user action jumps.
muteButton.Activated:Connect(function()
    mutedChannels[selectedChannel]=not mutedChannels[selectedChannel]
    muteButton.Text=if mutedChannels[selectedChannel] then "🔕" else "🔔"
    if mutedChannels[selectedChannel] then
        unread[selectedChannel]=0;pendingMessages[selectedChannel]=0
    end
    description.Text=if mutedChannels[selectedChannel] then "이 채널의 일반 알림이 음소거되었습니다." else "알림을 다시 활성화했습니다."
    updateNotice();updateChannelButtons()
end)
markReadButton.Activated:Connect(function() acknowledgeMessages() end)

newMessages.Activated:Connect(function()
    local id = selectedChannel
    task.defer(function()
        if id ~= selectedChannel then return end
        feed.CanvasPosition = Vector2.new(0, math.max(0, feed.AbsoluteCanvasSize.Y - feed.AbsoluteWindowSize.Y))
        scrollPositions[id] = feed.CanvasPosition
        acknowledgeMessages()
    end)
end)
channelSearch:GetPropertyChangedSignal("Text"):Connect(updateChannelButtons)
input:GetPropertyChangedSignal("Text"):Connect(function()
    if not restoringDraft then drafts[selectedChannel] = input.Text end
    local count = utf8.len(input.Text)
    composerHint.Text = (if count and count <= 180 then "Enter로 전송  ·  " else "180자 이내로 입력하세요  ·  ") .. tostring(count or 0) .. " / 180"
    composerHint.TextColor3 = if not count or count > 180 then C.warning else C.muted
end)


-- Only format text after Roblox has already filtered it for this recipient.
-- Escape RichText tags before applying the limited Discord markdown subset.
local function formatMarkdown(message: string): string
    local safe=message:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
    safe=safe:gsub("%*%*(.-)%*%*","<b>%1</b>")
    safe=safe:gsub("__(.-)__","<u>%1</u>")
    safe=safe:gsub("~~(.-)~~","<s>%1</s>")
    safe=safe:gsub("%*([^*]-)%*","<i>%1</i>")
    safe=safe:gsub("`([^`]-)`","<font color=\"#C7D8C9\">%1</font>")
    return safe
end

-- Render the text already filtered by Roblox for this player.
local function createMessage(entry: any, order: number)
    local row=create("Frame",feed,{
        Name="Message",LayoutOrder=order,BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    })
    row:SetAttribute("MessageId",entry.id or "")
    create("UISizeConstraint",row,{MinSize=Vector2.new(0,58)})
    local avatar=create("ImageLabel",row,{
        Position=UDim2.fromOffset(0,2),Size=UDim2.fromOffset(36,36),
        BackgroundColor3=C.surface,BorderSizePixel=0,
        Image="rbxthumb://type=AvatarHeadShot&id="..tostring(entry.userId).."&w=100&h=100",
    })
    corner(avatar,18)
    local prefix=(if entry.pinned then "📌  " else "")..
        entry.name.."  ·  "..entry.rank.."  ·  "..entry.time..
        (if entry.edited then "  (수정됨)" else "")..
        (if (entry.threadCount or 0)>0 then "  ⌗ "..tostring(entry.threadCount) else "")
    local author=label(row,prefix,13,C.accentLight,true)
    author.Position=UDim2.fromOffset(46,0)
    author.Size=UDim2.new(1,-52,0,22)

    local body=create("Frame",row,{
        Name="Content",Position=UDim2.fromOffset(46,24),
        Size=UDim2.new(1,-52,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,BorderSizePixel=0,
    })
    create("UIListLayout",body,{
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),
    })
    if entry.replyTo then
        local target=findEntry(entry.replyTo)
        local preview=button(body,"↩ "..(if target then target.name.." · "..target.message else "이전 답장"),C.sidebar)
        preview.LayoutOrder=1
        preview.Size=UDim2.new(1,0,0,25)
        preview.TextSize=11
        preview.TextColor3=C.muted
        preview.TextXAlignment=Enum.TextXAlignment.Left
        preview.Activated:Connect(function() jumpToMessage(entry.replyTo) end)
    elseif entry.threadRoot then
        local line=label(body,"⌗  스레드 답장",11,C.accentLight,false)
        line.LayoutOrder=1
        line.Size=UDim2.new(1,0,0,19)
    end

    local content=label(body,formatMarkdown(entry.message),15,C.white,false)
    content.LayoutOrder=2
    content.Size=UDim2.new(1,0,0,0)
    content.AutomaticSize=Enum.AutomaticSize.Y
    content.TextWrapped=true
    content.TextTruncate=Enum.TextTruncate.None
    content.TextYAlignment=Enum.TextYAlignment.Top
    content.RichText=true

    local reactionCount=0
    for _,emoji in reactionChoices do
        local value=entry.reactions and entry.reactions[emoji]
        if value and value.count and value.count>0 then reactionCount+=1 end
    end
    if reactionCount>0 then
        local bar=create("ScrollingFrame",body,{
            BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=3,
            Size=UDim2.new(1,0,0,27),ScrollBarThickness=0,
            ScrollingDirection=Enum.ScrollingDirection.X,
            CanvasSize=UDim2.fromOffset(reactionCount*69,0),
        })
        create("UIListLayout",bar,{
            FillDirection=Enum.FillDirection.Horizontal,
            Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,
        })
        for _,emoji in reactionChoices do
            local value=entry.reactions and entry.reactions[emoji]
            if value and value.count and value.count>0 then
                local b=button(bar,emoji.." "..tostring(value.count),if value.mine then C.accent else C.surface)
                b.Size=UDim2.fromOffset(65,26)
                b.TextSize=12
                b.Activated:Connect(function() requestAction("react",entry,emoji) end)
            end
        end
    end

    local actions=create("ScrollingFrame",body,{
        Name="MessageActions",BackgroundTransparency=1,BorderSizePixel=0,
        LayoutOrder=4,Size=UDim2.new(1,0,0,28),
        ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=0,
        CanvasSize=UDim2.fromOffset(236,0),
    })
    create("UIListLayout",actions,{
        FillDirection=Enum.FillDirection.Horizontal,
        Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,
    })
    local actionIndex=0
    local function actionButton(titleText: string,width: number,callback: ()->())
        actionIndex+=1
        local b=button(actions,titleText,C.surface)
        b.LayoutOrder=actionIndex
        b.Size=UDim2.fromOffset(width,26)
        b.TextSize=11
        b.Activated:Connect(callback)
    end
    actionButton("↩ 답장",54,function() beginReply(entry,false) end)
    actionButton("⌗ 스레드",68,function() beginReply(entry,true) end)
    actionButton("☺ 반응",60,function()
        expandedEmoji=if expandedEmoji==entry.id then nil else entry.id
        expandedMenu=nil
        renderMessages()
    end)
    actionButton("···",34,function()
        expandedMenu=if expandedMenu==entry.id then nil else entry.id
        expandedEmoji=nil
        renderMessages()
    end)

    if expandedEmoji==entry.id then
        local palette=create("ScrollingFrame",body,{
            LayoutOrder=5,Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,
            BorderSizePixel=0,ScrollingDirection=Enum.ScrollingDirection.X,
            ScrollBarThickness=0,CanvasSize=UDim2.fromOffset(6*36,0),
        })
        create("UIListLayout",palette,{
            FillDirection=Enum.FillDirection.Horizontal,
            Padding=UDim.new(0,4),
        })
        for index,emoji in reactionChoices do
            local buttonEmoji=button(palette,emoji,C.surface)
            buttonEmoji.LayoutOrder=index
            buttonEmoji.Size=UDim2.fromOffset(32,28)
            buttonEmoji.TextSize=17
            buttonEmoji.Activated:Connect(function()
                expandedEmoji=nil
                requestAction("react",entry,emoji)
                renderMessages()
            end)
        end
    end

    if expandedMenu==entry.id then
        local menu=create("ScrollingFrame",body,{
            LayoutOrder=6,Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,
            BorderSizePixel=0,ScrollingDirection=Enum.ScrollingDirection.X,
            ScrollBarThickness=0,CanvasSize=UDim2.fromOffset(260,0),
        })
        create("UIListLayout",menu,{
            FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),
        })
        local menuIndex=0
        local function menuButton(textValue: string,fn: ()->())
            menuIndex+=1
            local b=button(menu,textValue,C.hover)
            b.LayoutOrder=menuIndex
            b.Size=UDim2.fromOffset(79,30)
            b.TextSize=12
            b.Activated:Connect(fn)
        end
        if entry.userId==player.UserId and canWrite(selectedChannel) then
            menuButton("✎ 수정",function()
                expandedMenu=nil
                beginEdit(entry)
                renderMessages()
            end)
        end
        local access=channelAccess[selectedChannel]
        local moderator=player:GetAttribute("MessengerCanManageSettings")==true
            and access~=nil and access.canManage==true
        if entry.userId==player.UserId or moderator then
            menuButton("🗑 삭제",function()
                expandedMenu=nil
                requestAction("delete",entry)
                renderMessages()
            end)
        end
        if moderator then
            menuButton(if entry.pinned then "고정 해제" else "📌 고정",function()
                expandedMenu=nil
                requestAction("pin",entry)
                renderMessages()
            end)
        end
    end
    return row
end

renderMessages = function()
    local position = scrollPositions[selectedChannel] or Vector2.zero
    renderGeneration += 1
    local generation = renderGeneration
    for _, child in feed:GetChildren() do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    local query = string.lower(messageSearch.Text)
    local count = 0
    if channelAccess[selectedChannel] and channelAccess[selectedChannel].persistent then
        if archiveCursor[selectedChannel] and query=="" then
            local older=button(feed,if archiveLoading[selectedChannel] then "불러오는 중…" else "↑ 이전 영구 기록 불러오기",C.surface)
            older.Name="LoadOlderArchive"
            older.LayoutOrder=-100
            older.Size=UDim2.new(1,-12,0,36)
            older.Activated:Connect(function()
                local cursor=archiveCursor[selectedChannel]
                if cursor then loadArchive(selectedChannel,cursor) end
            end)
        end
    end
    for _, entry in history[selectedChannel] or {} do
        local threadVisible=if threadRoot then (entry.id==threadRoot or entry.threadRoot==threadRoot)
            else (entry.threadRoot==nil or query~="")
        if not entry.deleted and threadVisible and searchMatches(entry,query) then
            count+=1
            createMessage(entry,count)
        end
    end
    if count == 0 then
        local empty=label(feed,if query~="" then "검색 결과가 없습니다."
            elseif threadRoot then "이 스레드에는 아직 답장이 없습니다."
            elseif channelAccess[selectedChannel] and channelAccess[selectedChannel].persistent then
                (if archiveLoading[selectedChannel] then "영구 기록을 불러오는 중입니다…" else "이 채널에는 보관된 글이 없습니다.")
            else "# "..getChannelInfo(selectedChannel).name.."에 오신 것을 환영합니다.\n이 채널에서 대화를 시작해 보세요.",
            15,C.muted,false)
        empty.Name = "EmptyState"
        empty.Size = UDim2.new(1, -12, 0, 100)
        empty.TextWrapped = true
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end
    task.defer(function()
        if renderGeneration == generation then feed.CanvasPosition = position end
    end)
    updateNotice()
end
messageSearch:GetPropertyChangedSignal("Text"):Connect(function()
    renderMessages()
end)
feed:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    scrollPositions[selectedChannel] = feed.CanvasPosition
end)

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
            allowed = target:GetAttribute("MessengerCanViewCommand") == true
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

            local publicLabels=memberRoleLabels[tostring(target.UserId)] or {}
            local roleSuffix=if #publicLabels>0 then " · "..table.concat(publicLabels,", ") else ""
            local rank = label(
                row,
                tostring(target:GetAttribute("Rank") or "훈련병")..roleSuffix,
                10,
                if #publicLabels>0 then C.accentLight else C.muted,
                false
            )

            rank.Position = UDim2.fromOffset(44, 24)
            rank.Size = UDim2.new(1, -47, 0, 17)

            if player:GetAttribute("MessengerCanManageRoles")==true then
                name.Size=UDim2.new(1,-91,0,20)
                rank.Size=UDim2.new(1,-91,0,17)
                local give=button(row,"역할",C.surface)
                give.Name="AssignRole"
                give.AnchorPoint=Vector2.new(1,0.5)
                give.Position=UDim2.new(1,-4,0.5,0)
                give.Size=UDim2.fromOffset(42,30)
                give.TextSize=11
                give.Activated:Connect(function()
                    local picker=window:FindFirstChild("MessengerRolePicker")
                        or window:WaitForChild("MessengerRolePicker",4)
                    if picker and picker:IsA("BindableEvent") then
                        picker:Fire(target.UserId)
                    else
                        description.Text="역할 설정을 준비하지 못했습니다. 잠시 후 다시 시도하세요."
                    end
                end)
            end
        end
    end

    membersTitle.Text = "접속 중  ·  " .. tostring(count)
end

-- ==========================================
-- 채널 선택
-- ==========================================

local function selectChannel(id)
    if not canView(id) then
        description.Text = "이 채널에 접근할 권한이 없습니다."
        return
    end

    local switched = selectedChannel ~= id
    if switched then
        threadRoot=nil;replyTarget=nil;editTarget=nil
        expandedMenu=nil;expandedEmoji=nil
        pinsPanel.Visible=false
        updateMode()
        drafts[selectedChannel] = input.Text
        scrollPositions[selectedChannel] = feed.CanvasPosition
        selectedChannel = id
        restoringDraft = true
        input.Text = drafts[id] or ""
        restoringDraft = false
        messageSearch.Text = ""
    end
    drawerOpen = false
    updateLayout()
    window:SetAttribute("SelectedChannel", id)

    local info = getChannelInfo(id)

    local persistent=channelAccess[id] and channelAccess[id].persistent
    channelTitle.Text=(if persistent then "▣  " else "#  ")..info.name
    description.Text=if persistent then "영구 보관 채널 · 최대 300개까지 기록됩니다." else info.description
    muteButton.Text=if mutedChannels[id] then "🔕" else "🔔"

    if id == "unit" then
        description.Text = "소속 부대: " .. tostring(getUnit(player))
    end

    local writable = canWrite(id)

    input.TextEditable = writable

    input.PlaceholderText = writable
        and ("# " .. info.name .. "에 메시지 보내기")
        or "읽기 전용 채널입니다."

    sendButton.Text = writable and "전송" or "읽기 전용"

    sendButton.BackgroundColor3 = writable
        and C.accent
        or C.hover

    updateChannelButtons()
    if switched or #feed:GetChildren() <= 2 then renderMessages() end
    if persistent then
        if not archiveLoaded[id] or archiveDirty[id] or os.clock()-(archiveLastFetch[id] or -math.huge)>10 then
            loadArchive(id)
        end
    else
        syncMessageActions(id)
    end
    updateNotice()
    renderMembers()
end

for _, info in CHANNELS do
    local id = info.id

    channelButtons[id].Activated:Connect(function()
        selectChannel(id)
    end)
end

-- Keep channel listings in sync with the server. Only the server creates/deletes channels.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local manageRemote = ReplicatedStorage:WaitForChild("MessengerManage") :: RemoteFunction
local channelsChanged = ReplicatedStorage:WaitForChild("MessengerChannelsChanged") :: RemoteEvent
local function syncCustomChannels()
    local ok, result = pcall(function()
        return manageRemote:InvokeServer("snapshot")
    end)
    if not ok or not result or not result.ok or not result.data then return end
    local previousSelection = selectedChannel
    memberRoleLabels=if type(result.data.memberRoles)=="table" then result.data.memberRoles else {}
    local previousModes={}
    for id,item in channelAccess do previousModes[id]=item.persistent==true end
    local incoming = {}
    channelAccess = {}
    for _, item in result.data.channels or {} do
        if type(item) == "table" and type(item.id) == "string"
            and type(item.channel) == "string" and type(item.name) == "string" then
            incoming[item.id] = item
            channelAccess[item.id] = item
        end
    end
    for index = #CHANNELS, 1, -1 do
        local info = CHANNELS[index]
        if info.id:sub(1, 7) == "custom_" and not incoming[info.id] then
            local row = channelButtons[info.id]
            if row then row:Destroy() end
            channelButtons[info.id] = nil
            channelIds[info.channel] = nil
            history[info.id] = nil
            unread[info.id] = nil
            drafts[info.id] = nil; scrollPositions[info.id] = nil; pendingMessages[info.id] = nil
            archiveLoaded[info.id]=nil;archiveCursor[info.id]=nil;archiveDirty[info.id]=nil
            table.remove(CHANNELS, index)
            if selectedChannel == info.id then selectedChannel = "general"; input.Text = drafts.general or "" end
        end
    end
    for _, info in incoming do
        if previousModes[info.id]~=nil and previousModes[info.id]~=(info.persistent==true) then
            history[info.id]={}
            unread[info.id]=0;pendingMessages[info.id]=0
            archiveLoaded[info.id]=nil;archiveCursor[info.id]=nil
            archiveDirty[info.id]=true
        end
        for _, existing in CHANNELS do
            if existing.id == info.id then
                existing.name = info.name;existing.description=info.description;existing.persistent=info.persistent==true
            end
        end
        if not channelButtons[info.id] then
            table.insert(CHANNELS, info)
            channelIds[info.channel] = info.id
            history[info.id] = {}
            unread[info.id] = 0
            local row = button(channelsScroll, "#  " .. info.name, C.sidebar)
            row.Name = info.id
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.TextSize = 13
            channelButtons[info.id] = row
            local id = info.id
            row.Activated:Connect(function() selectChannel(id) end)
        end
    end
    for index, info in CHANNELS do
        local row = channelButtons[info.id]
        if row then
            row.Position = UDim2.fromOffset(10, 10 + (index - 1) * 46)
            row.Size = UDim2.new(1, -20, 0, 40)
            if info.id:sub(1, 7) == "custom_" then row.Text = "#  " .. info.name end
        end
    end
    channelsScroll.CanvasSize = UDim2.fromOffset(0, 20 + #CHANNELS * 46)
    for id in history do
        if not canView(id) then
            history[id]={};unread[id]=0;drafts[id]=nil;pendingMessages[id]=nil;scrollPositions[id]=nil
            archiveLoaded[id]=nil;archiveCursor[id]=nil;archiveDirty[id]=nil
        end
    end
    if not canView(selectedChannel) then
        selectedChannel = "general"
        input.Text = drafts.general or ""
        channelTitle.Text = "통신망"
        description.Text = result.data.storage and result.data.storage.error or "읽을 수 있는 채널이 없습니다."
        input.TextEditable = false
        renderMessages()
    else selectChannel(selectedChannel) end
    if previousSelection ~= selectedChannel then renderMessages() end
    updateChannelButtons()
end
channelsChanged.OnClientEvent:Connect(function()
    task.delay(0.25, syncCustomChannels)
end)
task.defer(syncCustomChannels)

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
        drafts.unit = nil; pendingMessages.unit = nil; scrollPositions.unit = nil
        if selectedChannel == "unit" then input.Text = ""; renderMessages() end
    end

    -- 지휘관 권한 상실 시 이전 지휘 채팅 기록 제거
    if not canView("command") then
        history.command = {}
        unread.command = 0
        drafts.command = nil; pendingMessages.command = nil; scrollPositions.command = nil
        if selectedChannel == "command" then input.Text = ""; renderMessages() end
    end

    if not canView(selectedChannel) then
        selectedChannel = "general"
        input.Text = drafts.general or ""
        renderMessages()
    end

    if canView(selectedChannel) then selectChannel(selectedChannel) else renderMessages(); updateChannelButtons() end
    renderMembers()
end

-- Register these signals once, not every time updateAccess runs.
local permissionAttributes = {
    "MessengerCanSend",
    "MessengerCanCreate",
    "MessengerCanDelete",
    "MessengerCanManageRoles",
    "MessengerCanManageSettings",
    "MessengerCanPostNotices",
    "MessengerCanViewCommand",
    "MessengerCanWriteCommand",
}
for _, attributeName in permissionAttributes do
    player:GetAttributeChangedSignal(attributeName):Connect(updateAccess)
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

local function receiveMessage(message)
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
    -- Permanent notice/rules channels are server-filtered boards, not
    -- TextChatService conversations. Never mix unarchived chat with posts.
    if channelAccess[id] and channelAccess[id].persistent then return end

    -- 중복 메시지 방지
    local messageId = message.MessageId

    if messageId and messageId ~= "" then
        if seenMessages[messageId] then
            return
        end

        seenMessages[messageId] = true
        table.insert(seenQueue, messageId)

        if #seenQueue > 800 then
            local oldest = table.remove(seenQueue, 1)
            seenMessages[oldest] = nil
        end
    end

    local userId = message.TextSource.UserId
    local sender = Players:GetPlayerByUserId(userId)
    local parsed=Protocol.decode(message.Metadata or "")
    local mode=if parsed then parsed.kind else nil
    local reference=if parsed then parsed.target else nil
    local token=if parsed then parsed.id else nil
    local plainToken=if mode=="m" then token else nil
    if mode=="e" then
        -- Edits are normal, Roblox-filtered TextChatService messages.
        local target=findEntry(reference)
        if target and target.userId==userId and not target.deleted then
            target.message=message.Text
            target.edited=true
            if selectedChannel==id then
                renderMessages()
                if pinsPanel.Visible then refreshPins() end
            end
        end
        return
    end

    local entry = {
        channelId=id,
        id=plainToken or token or message.MessageId,
        replyTo=if mode=="r" then reference else nil,
        threadRoot=if mode=="t" then reference else nil,
        date=os.date("%Y-%m-%d"),
        reactions={},pinned=false,deleted=false,edited=false,
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

    local dropped = nil
    if #history[id] > 300 then dropped = table.remove(history[id], 1) end
    if entry.threadRoot then
        local root=findEntry(entry.threadRoot)
        if root then root.threadCount=(root.threadCount or 0)+1 end
        if opened and selectedChannel==id and threadRoot==nil then
            renderMessages()
        end
    end
    local mentionsMe=string.find(string.lower(entry.message),"@"..string.lower(player.Name),1,true)~=nil
        or string.find(string.lower(entry.message),"@"..string.lower(player.DisplayName),1,true)~=nil
    if userId~=player.UserId and (not mutedChannels[id] or mentionsMe) then
        pendingMessages[id]=(pendingMessages[id] or 0)+1
        unread[id]=(unread[id] or 0)+1
    end
    local threadVisible=if threadRoot then (entry.threadRoot==threadRoot or entry.id==threadRoot)
        else entry.threadRoot==nil
    if opened and selectedChannel == id and messageSearch.Text == "" and threadVisible then
        local empty = feed:FindFirstChild("EmptyState")
        if empty then empty:Destroy() end
        -- Incremental append leaves the reader's viewport untouched.
        messageOrder += 1
        createMessage(entry, messageOrder)
        if dropped and not dropped.threadRoot then
            local oldest = nil
            for _, child in feed:GetChildren() do
                if child:IsA("Frame") and child.Name == "Message" and (not oldest or child.LayoutOrder < oldest.LayoutOrder) then oldest = child end
            end
            if oldest then
                local removedHeight = oldest.AbsoluteSize.Y + 12
                local position = feed.CanvasPosition
                oldest:Destroy()
                feed.CanvasPosition = Vector2.new(0, math.max(0, position.Y - removedHeight))
            end
        end
    end
    updateNotice()

    updateChannelButtons()
end
TextChatService.MessageReceived:Connect(receiveMessage)

-- Only channel-scoped metadata is broadcast here, never unfiltered message text.
actionChanged.OnClientEvent:Connect(function(update: any)
    if type(update)~="table" or type(update.id)~="string" or type(update.channelId)~="string"
        or not canView(update.channelId) then return end
    local entry=findEntry(update.id)
    if not entry then return end
    if update.action=="pin" and type(update.extra)=="table" then
        entry.pinned=update.extra.pinned==true
    elseif update.action=="delete" then
        entry.deleted=true
        if editTarget==entry then editTarget=nil end
        if replyTarget==entry then replyTarget=nil end
        updateMode()
    elseif update.action=="reaction" and type(update.extra)=="table" then
        local extra=update.extra
        if type(extra.emoji)~="string" or type(extra.userId)~="number" then return end
        entry.reactions=entry.reactions or {}
        local reaction=entry.reactions[extra.emoji] or {count=0,mine=false}
        reaction.count=math.max(0,(reaction.count or 0)+(if extra.active then 1 else -1))
        if extra.userId==player.UserId then reaction.mine=extra.active==true end
        entry.reactions[extra.emoji]=reaction
    else
        return
    end
    if update.channelId==selectedChannel then
        renderMessages()
        if pinsPanel.Visible then refreshPins() end
    end
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
    local token=HttpService:GenerateGUID(false)
    local metadata=assert(Protocol.encode("m",token))
    if editTarget then
        if editTarget.userId~=player.UserId then return end
        metadata=assert(Protocol.encode("e",token,editTarget.id))
    elseif threadRoot then
        metadata=assert(Protocol.encode("t",token,threadRoot))
    elseif replyTarget then
        metadata=assert(Protocol.encode("r",token,replyTarget.id))
    end

    sending = true
    sendButton.Text = "..."

    input.Text = ""
    drafts[id] = ""

    -- Permanent channels are filtered bulletin boards, not regular TextChat
    -- conversations. The server validates rights, filters the post, commits it
    -- to DataStore and then asks every authorized client to refresh history.
    if channelAccess[id] and channelAccess[id].persistent then
        local operation=if editTarget then "edit" else "post"
        local args: any={channelId=id,text=content}
        if editTarget then
            args.id=editTarget.id
        elseif threadRoot then
            args.threadRoot=threadRoot
        elseif replyTarget then
            args.replyTo=replyTarget.id
        end
        task.spawn(function()
            local ok,result=pcall(function()
                return archiveRemote:InvokeServer(operation,args)
            end)
            sending=false
            if selectedChannel==id then sendButton.Text=if canWrite(id) then "전송" else "읽기 전용" end
            if not ok or type(result)~="table" or not result.ok then
                local failure=if ok and type(result)=="table" then result.message else "영구 보관 서버의 응답을 받지 못했습니다."
                if selectedChannel==id then
                    description.Text=failure or "영구 기록 저장에 실패했습니다."
                    if input.Text=="" then input.Text=content end
                end
                return
            end
            if selectedChannel==id then
                editTarget=nil;replyTarget=nil;updateMode()
                loadArchive(id)
            else
                archiveDirty[id]=true
            end
        end)
        return
    end

    task.spawn(function()
        local success, result = pcall(function()
        local channel = TextChatService:WaitForChild(info.channel, 10)

        if not channel or not channel:IsA("TextChannel") then
        error("채팅 채널을 찾을 수 없습니다.")
        end

        return channel:SendAsync(content,metadata)
    end)

        sending = false

        if selectedChannel == id then
            sendButton.Text = canWrite(id)
                and "전송"
                or "읽기 전용"
        end

        if not success then
            warn("[Messenger] 메시지 전송 실패:", result)

            description.Text = "메시지를 보내지 못했습니다. 잠시 후 다시 시도해 주세요."

            if canView(id) and (drafts[id] or "") == "" then
                drafts[id] = content
                if selectedChannel == id then input.Text = content end
            end

        elseif result.Status ~= Enum.TextChatMessageStatus.Success then
            if canView(id) and (drafts[id] or "") == "" then
                drafts[id] = content
                if selectedChannel == id then input.Text = content end
            end
            description.Text = "통신 설정 또는 채널 권한으로 전송이 제한됐습니다."
        elseif selectedChannel==id then
            editTarget=nil
            replyTarget=nil
            updateMode()
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
        renderMessages()
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

-- Discord-inspired keyboard navigation (Mac Cmd and Windows Ctrl supported).
UserInputService.InputBegan:Connect(function(key, processed)
    local isModifier=UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftMeta)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightMeta)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightSuper)
    if opened and not processed and isModifier and key.KeyCode==Enum.KeyCode.F then
        messageSearch:CaptureFocus()
        return
    elseif opened and not processed and isModifier and key.KeyCode==Enum.KeyCode.P then
        pinsPanel.Visible=not pinsPanel.Visible
        if pinsPanel.Visible then refreshPins() end
        return
    end
    if key.KeyCode==Enum.KeyCode.Escape or key.KeyCode==Enum.KeyCode.ButtonB then
        if not opened or processed then return end
        if pinsPanel.Visible then
            pinsPanel.Visible=false
        elseif editTarget or replyTarget or threadRoot then
            editTarget=nil;replyTarget=nil;threadRoot=nil
            updateMode();renderMessages()
        else
            setOpen(false)
        end
    elseif key.KeyCode==Enum.KeyCode.M and not processed then
        setOpen(not opened)
    end
end)

input.InputBegan:Connect(function(key)
    if key.KeyCode~=Enum.KeyCode.Up or input.Text~="" or not opened then return end
    for index=#(history[selectedChannel] or {}),1,-1 do
        local entry=history[selectedChannel][index]
        if entry.userId==player.UserId and not entry.deleted and
            ((threadRoot==nil and entry.threadRoot==nil) or entry.threadRoot==threadRoot) then
            beginEdit(entry)
            return
        end
    end
end)

-- ==========================================
-- 초기화
-- ==========================================

selectChannel("general")
updateChannelButtons()

print("[MilitaryMessenger] 클라이언트 UI 시작 완료")