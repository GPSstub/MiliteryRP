--!strict
-- Appears automatically for ambiguous partial username / DisplayName matches
-- from BOTH Roblox chat commands and the admin panel.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TextChatService=game:GetService("TextChatService")
local UserInputService=game:GetService("UserInputService")
local localPlayer=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("AdminTargetSelection") :: RemoteEvent

local gui=Instance.new("ScreenGui")
gui.Name="AdminTargetPicker"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=100
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=localPlayer:WaitForChild("PlayerGui")

local overlay=Instance.new("Frame")
overlay.Name="DimOverlay"
overlay.BackgroundColor3=Color3.fromRGB(7,13,19)
overlay.BackgroundTransparency=0.25
overlay.BorderSizePixel=0
overlay.Size=UDim2.fromScale(1,1)
overlay.Visible=false
overlay.Parent=gui

local card=Instance.new("Frame")
card.Name="CandidatePicker"
card.AnchorPoint=Vector2.new(0.5,0.5)
card.Position=UDim2.fromScale(0.5,0.5)
card.Size=UDim2.new(0.9,0,0.74,0)
card.BackgroundColor3=Color3.fromRGB(28,37,44)
card.BorderSizePixel=0
card.Parent=overlay
local sizeLimit=Instance.new("UISizeConstraint")
sizeLimit.MaxSize=Vector2.new(490,570)
sizeLimit.MinSize=Vector2.new(260,240)
sizeLimit.Parent=card
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,14)
corner.Parent=card
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(87,105,117)
stroke.Transparency=0.32
stroke.Parent=card

local function addText(name: string,value: string,size: number,color: Color3,
        position: UDim2,dimensions: UDim2): TextLabel
    local label=Instance.new("TextLabel")
    label.Name=name
    label.BackgroundTransparency=1
    label.Text=value
    label.TextSize=size
    label.Font=Enum.Font.GothamMedium
    label.TextColor3=color
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextYAlignment=Enum.TextYAlignment.Center
    label.TextWrapped=true
    label.Position=position
    label.Size=dimensions
    label.Parent=card
    return label
end

local title=addText("Title","대상 선택",19,
    Color3.fromRGB(245,249,252),
    UDim2.fromOffset(18,12),UDim2.new(1,-85,0,30))
title.Font=Enum.Font.GothamBold
local description=addText("Description","표시 닉네임과 실제 사용자 이름을 확인하세요.",12,
    Color3.fromRGB(165,183,193),
    UDim2.fromOffset(18,46),UDim2.new(1,-36,0,40))
local status=addText("Status","",12,Color3.fromRGB(243,207,136),
    UDim2.new(0,18,1,-53),UDim2.new(1,-125,0,37))

local scroller=Instance.new("ScrollingFrame")
scroller.Name="Candidates"
scroller.Position=UDim2.fromOffset(16,91)
scroller.Size=UDim2.new(1,-32,1,-153)
scroller.BackgroundTransparency=1
scroller.BorderSizePixel=0
scroller.ScrollBarThickness=5
scroller.ScrollBarImageColor3=Color3.fromRGB(106,140,164)
scroller.ScrollingDirection=Enum.ScrollingDirection.Y
scroller.CanvasSize=UDim2.fromOffset(0,0)
scroller.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroller.Parent=card
local layout=Instance.new("UIListLayout")
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Padding=UDim.new(0,7)
layout.Parent=scroller
local padding=Instance.new("UIPadding")
padding.PaddingBottom=UDim.new(0,5)
padding.Parent=scroller

local cancel=Instance.new("TextButton")
cancel.Name="Cancel"
cancel.Text="취소"
cancel.Font=Enum.Font.GothamBold
cancel.TextSize=13
cancel.TextColor3=Color3.fromRGB(228,234,239)
cancel.BackgroundColor3=Color3.fromRGB(66,78,89)
cancel.BorderSizePixel=0
cancel.AnchorPoint=Vector2.new(1,1)
cancel.Position=UDim2.new(1,-16,1,-13)
cancel.Size=UDim2.fromOffset(84,34)
cancel.Parent=card
local cancelCorner=Instance.new("UICorner")
cancelCorner.CornerRadius=UDim.new(0,8)
cancelCorner.Parent=cancel

local ticket: number?=nil
local awaiting=false
local generation=0

local function hide()
    generation+=1
    ticket=nil
    awaiting=false
    overlay.Visible=false
end

cancel.Activated:Connect(function()
    if ticket then remote:FireServer("cancel",ticket) end
    hide()
end)
UserInputService.InputBegan:Connect(function(input: InputObject,processed: boolean)
    if processed then return end
    if overlay.Visible and input.KeyCode==Enum.KeyCode.Escape then
        if ticket then remote:FireServer("cancel",ticket) end
        hide()
    end
end)
localPlayer:GetAttributeChangedSignal("CanUseAdminCommands"):Connect(function()
    if localPlayer:GetAttribute("CanUseAdminCommands")~=true then hide() end
end)

local function makeCandidate(data: any,order: number)
    if type(data)~="table" or type(data.userId)~="number"
        or type(data.username)~="string" or type(data.displayName)~="string" then return end
    local btn=Instance.new("TextButton")
    btn.Name="Candidate_"..tostring(data.userId)
    btn.Text=""
    btn.LayoutOrder=order
    btn.Size=UDim2.new(1,-8,0,61)
    btn.BackgroundColor3=Color3.fromRGB(45,60,72)
    btn.BorderSizePixel=0
    btn.AutoButtonColor=true
    btn.Parent=scroller
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,9)
    c.Parent=btn

    local d=Instance.new("TextLabel")
    d.Name="DisplayName"
    d.BackgroundTransparency=1
    d.Position=UDim2.fromOffset(14,6)
    d.Size=UDim2.new(1,-28,0,27)
    d.Text=data.displayName
    d.TextColor3=Color3.fromRGB(241,246,250)
    d.Font=Enum.Font.GothamBold
    d.TextSize=16
    d.TextXAlignment=Enum.TextXAlignment.Left
    d.TextTruncate=Enum.TextTruncate.AtEnd
    d.Parent=btn

    local user=Instance.new("TextLabel")
    user.Name="Username"
    user.BackgroundTransparency=1
    user.Position=UDim2.fromOffset(14,33)
    user.Size=UDim2.new(1,-28,0,21)
    user.Text="@"..data.username.."  ·  ID "..tostring(data.userId)
    user.TextColor3=Color3.fromRGB(166,195,213)
    user.Font=Enum.Font.Gotham
    user.TextSize=12
    user.TextXAlignment=Enum.TextXAlignment.Left
    user.TextTruncate=Enum.TextTruncate.AtEnd
    user.Parent=btn

    btn.Activated:Connect(function()
        if not ticket or awaiting or not overlay.Visible then return end
        awaiting=true
        status.Text="선택한 대상에게 명령을 실행하는 중…"
        remote:FireServer("choose",ticket,data.userId)
    end)
end

local function show(data: any)
    if type(data)~="table" or type(data.ticket)~="number"
        or type(data.candidates)~="table" then return end
    generation+=1
    ticket=data.ticket
    awaiting=false
    overlay.Visible=true
    title.Text="대상 플레이어 선택"
    description.Text="'"..tostring(data.query or "").."' 검색 결과 · 같은 이름의 다른 사람을 잘 확인하세요."
    status.Text=tostring(#data.candidates).."명 검색됨 · 30초 안에 선택하세요."
    cancel.Text="취소"
    scroller.Visible=true
    for _,child in scroller:GetChildren() do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    scroller.CanvasPosition=Vector2.zero
    for i,player in data.candidates do
        makeCandidate(player,i)
    end
    local opening=generation
    local openedTicket=ticket
    task.delay(30,function()
        if generation==opening and ticket==openedTicket and overlay.Visible then
            remote:FireServer("cancel",openedTicket)
            hide()
        end
    end)
end

local function chatResult(message: string,ok: boolean)
    task.spawn(function()
        local channels=TextChatService:WaitForChild("TextChannels",5)
        local general=if channels then channels:FindFirstChild("RBXGeneral") else nil
        if general and general:IsA("TextChannel") then
            general:DisplaySystemMessage(
                (if ok then "[관리자] " else "[관리자 오류] ")..message
            )
        end
    end)
end

remote.OnClientEvent:Connect(function(kind: any,data: any)
    if kind=="open" then
        show(data)
    elseif kind=="dismiss" then
        hide()
    elseif kind=="result" and type(data)=="table" then
        local message=tostring(data.message or "응답이 없습니다.")
        chatResult(message,data.ok==true)
        if overlay.Visible then
            awaiting=false
            ticket=nil
            scroller.Visible=false
            title.Text=if data.ok==true then "명령 실행 완료" else "명령을 실행하지 못했습니다"
            status.Text=message
            cancel.Text="닫기"
            generation+=1
            local last=generation
            task.delay(3,function()
                if generation==last then hide() end
            end)
        end
    end
end)
