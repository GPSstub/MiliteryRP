--!strict
-- Messenger settings overlay. Requests are always re-validated by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MilitaryMessenger")
local window = gui:WaitForChild("MessengerWindow") :: Frame
local header = window:WaitForChild("Header") :: Frame
local remote = ReplicatedStorage:WaitForChild("MessengerManage") :: RemoteFunction
local changed = ReplicatedStorage:WaitForChild("MessengerChannelsChanged") :: RemoteEvent

local BG = Color3.fromRGB(24, 27, 34)
local PANEL = Color3.fromRGB(39, 45, 55)
local MUTED = Color3.fromRGB(164, 172, 184)
local WHITE = Color3.fromRGB(237, 241, 243)
local GREEN = Color3.fromRGB(109, 159, 122)
local RED = Color3.fromRGB(167, 76, 82)

local function make(className: string, parent: Instance, props: {[string]: any}): any
    local obj = Instance.new(className)
    for key, value in props do (obj :: any)[key] = value end
    obj.Parent = parent
    return obj
end
local function round(obj: Instance)
    make("UICorner", obj, {CornerRadius = UDim.new(0, 9)})
end
local function button(parent: Instance, title: string, color: Color3?): TextButton
    local b = make("TextButton", parent, {
        Text = title, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = WHITE, BackgroundColor3 = color or PANEL,
        BorderSizePixel = 0, Size = UDim2.fromOffset(110, 34),
    }) :: TextButton
    round(b)
    return b
end
local function text(parent: Instance, value: string, height: number): TextLabel
    return make("TextLabel", parent, {
        Text = value, Font = Enum.Font.GothamMedium,
        TextSize = 13, TextColor3 = WHITE,
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, height), TextWrapped = true,
    }) :: TextLabel
end
local function input(parent: Instance, placeholder: string): TextBox
    local box = make("TextBox", parent, {
        Text = "", PlaceholderText = placeholder, ClearTextOnFocus = false,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = WHITE,
        PlaceholderColor3 = MUTED, BackgroundColor3 = PANEL,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 36),
    }) :: TextBox
    round(box)
    return box
end
local open = button(header, "⚙ 설정")
open.Name = "MessengerSettingsButton"
open.AnchorPoint = Vector2.new(1, 0)
open.Position = UDim2.new(1, -60, 0, 12)
open.Size = UDim2.fromOffset(84, 35)

local overlay = make("Frame", window, {
    Name = "SettingsOverlay",
    Position = UDim2.fromOffset(0, 60),
    Size = UDim2.new(1, 0, 1, -60),
    BackgroundColor3 = BG,
    BorderSizePixel = 0, Visible = false,
    ZIndex = 15,
}) :: Frame
local top = make("Frame", overlay, {
    BackgroundColor3 = PANEL, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 44), ZIndex = 15,
}) :: Frame
local heading = text(top, "  통신망 설정", 30)
heading.TextSize = 16
heading.Position = UDim2.fromOffset(14, 6)
heading.Size = UDim2.new(1, -90, 0, 30)
heading.ZIndex = 16
local dismiss = button(top, "돌아가기")
dismiss.Position = UDim2.new(1, -96, 0, 5)
dismiss.Size = UDim2.fromOffset(88, 34)
dismiss.ZIndex = 16
dismiss.Activated:Connect(function() overlay.Visible = false end)
open.Activated:Connect(function()
    overlay.Visible = not overlay.Visible
end)

local tabs = make("Frame", overlay, {
    Position = UDim2.fromOffset(12, 54),
    Size = UDim2.new(1, -24, 0, 37), BackgroundTransparency = 1,
    ZIndex = 16,
}) :: Frame
local body = make("ScrollingFrame", overlay, {
    Position = UDim2.fromOffset(16, 101),
    Size = UDim2.new(1, -32, 1, -138),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 4, ZIndex = 16,
}) :: ScrollingFrame
make("UIListLayout", body, {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder})
make("UIPadding", body, {
    PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 14),
})
local status = text(overlay, "역할과 채널은 현재 서버에서만 유지됩니다.", 25)
status.Position = UDim2.new(0, 16, 1, -31)
status.Size = UDim2.new(1, -32, 0, 26)
status.ZIndex = 16
status.TextColor3 = MUTED

local page = "channels"
local selectedRole = "member"
local state: any = { channels = {}, permissions = {roles = {}, people = {}} }
local render: () -> ()

local permissions = {
    {"SEND_MESSAGES", "메시지 쓰기"},
    {"CREATE_CHANNELS", "채널 개설"},
    {"DELETE_CHANNELS", "채널 삭제"},
    {"MANAGE_ROLES", "역할 관리"},
    {"MANAGE_SETTINGS", "서버 설정"},
    {"POST_NOTICES", "공지 작성"},
    {"VIEW_COMMAND", "지휘 채널 읽기"},
    {"WRITE_COMMAND", "지휘 채널 쓰기"},
}
local function call(action: string, payload: any?)
    local ok, result = pcall(function()
        return remote:InvokeServer(action, payload)
    end)
    if not ok or type(result) ~= "table" then
        status.Text = "서버 통신 오류: " .. tostring(result)
        return false
    end
    status.Text = tostring(result.message or (result.ok and "완료" or "요청 실패"))
    return result.ok == true, result
end
local function refresh()
    local ok, result = call("snapshot")
    if ok and type(result.data) == "table" then
        state = result.data
        render()
    end
end
local function action(kind: string, payload: any)
    local ok = call(kind, payload)
    if ok then
        task.delay(0.25, refresh)
    end
end
local function clearRows()
    for _, child in body:GetChildren() do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end
local function addButton(name: string, fn: () -> (), color: Color3?): TextButton
    local b = button(body, name, color)
    b.Size = UDim2.new(1, -4, 0, 36)
    b.ZIndex = 17
    b.Activated:Connect(fn)
    return b
end
local function addLabel(name: string, height: number?)
    local l = text(body, name, height or 30)
    l.ZIndex = 17
    return l
end
local function addInput(placeholder: string)
    local field = input(body, placeholder)
    field.ZIndex = 17
    return field
end

render = function()
    clearRows()
    for _, child in tabs:GetChildren() do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for index, spec in {{"channels","채널"},{"roles","역할"},{"people","사용자"},{"settings","안내"}} do
        local b = button(tabs, spec[2], spec[1] == page and GREEN or PANEL)
        b.Position = UDim2.new((index-1)/4, 0, 0, 0)
        b.Size = UDim2.new(0.25, -5, 0, 34)
        b.ZIndex = 17
        b.Activated:Connect(function() page = spec[1]; render() end)
    end
    if page == "channels" then
        addLabel("채널 관리  ·  최대 8개 추가 채널")
        local nameBox = addInput("새 채널 이름 (2~24자)")
        addButton("+ 채널 개설", function()
            action("create_channel", {name = nameBox.Text})
        end, GREEN)
        for _, channel in state.channels or {} do
            addButton("# " .. channel.name .. "    ✕ 삭제", function()
                action("delete_channel", {id = channel.id})
            end, RED)
        end
        addLabel("기본 채널(전체·부대·지휘·공지)은 삭제할 수 없습니다.", 36)
    elseif page == "roles" then
        addLabel("역할 목록  ·  역할을 선택해 권한을 수정하세요.")
        local ids = {}
        for id in state.permissions.roles or {} do table.insert(ids, id) end
        table.sort(ids)
        for _, id in ids do
            addButton((selectedRole == id and "● " or "○ ") .. id, function()
                selectedRole = id
                render()
            end)
        end
        addLabel("선택한 역할: " .. selectedRole)
        local grants = state.permissions.roles[selectedRole]
        if grants then
            for _, entry in permissions do
                local key, title = entry[1], entry[2]
                addButton((grants[key] and "[✓] " or "[ ] ") .. title, function()
                    action("set_permission", {
                        roleId = selectedRole, permission = key,
                        enabled = not grants[key],
                    })
                end)
            end
            addButton("선택한 역할 삭제", function()
                action("delete_role", {roleId = selectedRole})
                selectedRole = "member"
            end, RED)
        end
        addLabel("새 역할 만들기 (영문 소문자·숫자·밑줄)")
        local roleInput = addInput("역할 ID 예: medic")
        addButton("+ 역할 생성", function()
            action("create_role", {roleId = roleInput.Text, permissions = {}})
        end, GREEN)
    elseif page == "people" then
        addLabel("사용자 역할 배정  ·  역할 탭에서 먼저 역할을 선택하세요.", 45)
        addLabel("현재 선택한 역할: " .. selectedRole)
        for _, member in state.permissions.people or {} do
            local hasRole = table.find(member.roles, selectedRole) ~= nil
            addButton("@" .. member.name .. (hasRole and "   [제거]" or "   [+ 부여]"), function()
                action(hasRole and "remove_role" or "assign_role", {
                    userId = member.userId, roleId = selectedRole,
                })
            end)
        end
    else
        addLabel("MILITARY NETWORK  /  SETTINGS", 40)
        addLabel("채널 생성·삭제와 역할 수정은 서버가 권한을 검사합니다.", 48)
        addLabel("기본 역할(member·officer·operator·muted)은 보호됩니다.", 50)
        addLabel("역할 및 사용자 배정은 서버 재시작 후 초기화됩니다.", 50)
        addLabel("정식 출시 전 DataStore 영구 저장을 추가해야 합니다.", 50)
    end
    body.CanvasPosition = Vector2.zero
end
changed.OnClientEvent:Connect(function()
    task.delay(0.35, function()
        if overlay.Visible then refresh() end
    end)
end)
open.Activated:Connect(function()
    if overlay.Visible then task.spawn(refresh) end
end)
render()
task.delay(0.4, refresh)
