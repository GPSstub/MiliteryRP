--!strict
-- Standalone, responsive command-list modal. It does not execute commands.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local helpEvent = ReplicatedStorage:WaitForChild("MilitaryCommandHelp") :: RemoteEvent
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CommandHelpCatalog"))
local gui = Instance.new("ScreenGui")
gui.Name = "MilitaryCommandHelpGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 95
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function make(className: string, parent: Instance, props: {[string]: any}): any
    local object = Instance.new(className)
    for name, value in props do
        (object :: any)[name] = value
    end
    object.Parent = parent
    return object
end
local backdrop = make("TextButton", gui, {
    Name = "Backdrop", Text = "", AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(6,10,15),
    BackgroundTransparency = 0.27,
    BorderSizePixel = 0, Size = UDim2.fromScale(1,1),
})
local panel = make("Frame", backdrop, {
    Name = "CommandHelpPanel",
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.fromScale(0.5,0.5),
    BackgroundColor3 = Color3.fromRGB(24,32,37),
    BorderSizePixel = 0, Active = true,
})
make("UICorner", panel, {CornerRadius = UDim.new(0,14)})
make("UIStroke", panel, {
    Color = Color3.fromRGB(80,101,101), Thickness = 1.2, Transparency = 0.25,
})
local heading = make("TextLabel", panel, {
    Name = "Heading", Text = "군사 RP  /  명령어 목록",
    Size = UDim2.new(1,-94,0,33), Position = UDim2.fromOffset(20,13),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 21,
    TextColor3 = Color3.fromRGB(236,244,239),
    TextXAlignment = Enum.TextXAlignment.Left,
})
local close = make("TextButton", panel, {
    Name = "Close", Text = "✕", AutoButtonColor = true,
    Size = UDim2.fromOffset(40,36),
    Position = UDim2.new(1,-51,0,12),
    BackgroundColor3 = Color3.fromRGB(56,69,71),
    TextColor3 = Color3.fromRGB(247,249,246),
    Font = Enum.Font.GothamBold, TextSize = 19,
})
make("UICorner",close,{CornerRadius=UDim.new(0,8)})
local subtitle = make("TextLabel",panel,{
    Name = "Subtitle",
    Text = "채팅창에서 ;? 또는 ;help 로 다시 열 수 있습니다.",
    Size = UDim2.new(1,-40,0,30),
    Position = UDim2.fromOffset(20,49), BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(153,181,171), Font = Enum.Font.Gotham,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true,
})
local scroller = make("ScrollingFrame",panel,{
    Name = "CommandList",
    Position = UDim2.fromOffset(14,87),
    Size = UDim2.new(1,-28,1,-157),
    BackgroundColor3 = Color3.fromRGB(19,26,30),
    BorderSizePixel = 0, ScrollBarThickness = 5,
    ScrollBarImageColor3 = Color3.fromRGB(119,157,142),
    CanvasSize = UDim2.fromOffset(0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
})
make("UICorner",scroller,{CornerRadius=UDim.new(0,10)})
make("UIPadding",scroller,{
    PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,13),
    PaddingTop=UDim.new(0,9),PaddingBottom=UDim.new(0,12),
})
make("UIListLayout",scroller,{
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,8),
})
local sortIndex = 0
for _,section in Catalog.Sections do
    sortIndex += 1
    make("TextLabel",scroller,{
        Name="Section", LayoutOrder=sortIndex,
        Size=UDim2.new(1,0,0,29),
        BackgroundTransparency=1,
        Text=section.title,
        Font=Enum.Font.GothamBold,TextSize=15,
        TextColor3=Color3.fromRGB(145,202,158),
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    for _,entry in section.entries do
        sortIndex += 1
        local card=make("Frame",scroller,{
            Name="CommandRow",LayoutOrder=sortIndex,
            Size=UDim2.new(1,0,0,99),
            BackgroundColor3=Color3.fromRGB(37,48,52),
            BorderSizePixel=0,
        })
        make("UICorner",card,{CornerRadius=UDim.new(0,9)})
        make("TextLabel",card,{
            Name="Syntax",Position=UDim2.fromOffset(12,7),
            Size=UDim2.new(1,-24,0,37),
            Text=entry.syntax,BackgroundTransparency=1,
            Font=Enum.Font.Code,TextSize=14,TextWrapped=true,
            TextColor3=Color3.fromRGB(244,214,142),
            TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        })
        make("TextLabel",card,{
            Name="Description",Position=UDim2.fromOffset(12,46),
            Size=UDim2.new(1,-24,0,45),
            Text=entry.description,BackgroundTransparency=1,
            Font=Enum.Font.Gotham,TextSize=13,TextWrapped=true,
            TextColor3=Color3.fromRGB(209,223,219),
            TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        })
    end
end
local footer=make("TextLabel",panel,{
    Name="Permissions", Position=UDim2.new(0,18,1,-62),
    Size=UDim2.new(1,-36,0,50), BackgroundTransparency=1,
    Text="대상: 나 / 실제 사용자 이름 / 표시 닉네임 (중복 시 선택)",
    Font=Enum.Font.GothamMedium,TextSize=12,TextWrapped=true,
    TextColor3=Color3.fromRGB(187,199,198),
    TextXAlignment=Enum.TextXAlignment.Left,
})
local function resize()
    local size=backdrop.AbsoluteSize
    local width=math.min(706,math.max(228,size.X-24))
    local height=math.min(704,math.max(235,size.Y-26))
    panel.Size=UDim2.fromOffset(width,height)
    heading.TextSize=if size.X<450 then 17 else 21
    subtitle.TextSize=if size.X<450 then 11 else 13
end
backdrop:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local function dismiss()
    gui.Enabled=false
    if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad then
        GuiService.SelectedObject=nil
    end
end
close.Activated:Connect(dismiss)
backdrop.Activated:Connect(dismiss)
UserInputService.InputBegan:Connect(function(input: InputObject)
    if gui.Enabled and (input.KeyCode==Enum.KeyCode.Escape
        or input.KeyCode==Enum.KeyCode.ButtonB) then
        dismiss()
    end
end)
helpEvent.OnClientEvent:Connect(function(canUseAdmin: any)
    footer.Text=if canUseAdmin==true
        then "그룹 관리자 권한 확인됨 · 대상은 나 / 이름 일부 / 표시 닉네임 (중복 시 선택)"
        else "명령어 열람은 가능하지만 실행은 Roblox 그룹 랭크 200 이상만 허용됩니다."
    scroller.CanvasPosition=Vector2.zero
    gui.Enabled=true
    if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad then
        GuiService.SelectedObject=close
    end
end)
