--!strict
-- Equip-aware HUD and input for the server-authoritative training rifle.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TrainingRifleRules"))
local remote=ReplicatedStorage:WaitForChild("TrainingRifleAction") :: RemoteEvent

local gui=Instance.new("ScreenGui")
gui.Name="TrainingRifleHUD"
gui.ResetOnSpawn=false
gui.DisplayOrder=35
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.Name="AmmoPanel"
panel.AnchorPoint=Vector2.new(1,1)
panel.Position=UDim2.new(1,-18,1,-18)
panel.Size=UDim2.fromOffset(208,91)
panel.BackgroundColor3=Color3.fromRGB(20,23,29)
panel.BackgroundTransparency=0.06
panel.BorderSizePixel=0
panel.Visible=false
panel.Parent=gui
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,12)
corner.Parent=panel
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(75,83,84)
stroke.Transparency=0.25
stroke.Parent=panel
local title=Instance.new("TextLabel")
title.Name="WeaponName"
title.Text=Rules.DISPLAY_NAME
title.Size=UDim2.new(1,-20,0,22)
title.Position=UDim2.fromOffset(10,4)
title.BackgroundTransparency=1
title.TextColor3=Color3.fromRGB(204,208,201)
title.Font=Enum.Font.GothamMedium
title.TextSize=12
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=panel
local ammo=Instance.new("TextLabel")
ammo.Name="Ammo"
ammo.Text="30 / 90"
ammo.Size=UDim2.new(1,-20,0,43)
ammo.Position=UDim2.fromOffset(10,24)
ammo.BackgroundTransparency=1
ammo.TextColor3=Color3.fromRGB(244,245,237)
ammo.Font=Enum.Font.GothamBold
ammo.TextSize=29
ammo.TextXAlignment=Enum.TextXAlignment.Right
ammo.Parent=panel
local hint=Instance.new("TextLabel")
hint.Name="Hint"
hint.Text="R  ·  재장전"
hint.Size=UDim2.new(1,-20,0,19)
hint.Position=UDim2.fromOffset(10,69)
hint.BackgroundTransparency=1
hint.TextColor3=Color3.fromRGB(170,185,171)
hint.Font=Enum.Font.Gotham
hint.TextSize=12
hint.TextXAlignment=Enum.TextXAlignment.Right
hint.Parent=panel
local crosshair=Instance.new("TextLabel")
crosshair.Name="RifleReticle"
crosshair.AnchorPoint=Vector2.new(0.5,0.5)
crosshair.Position=UDim2.fromScale(0.5,0.5)
crosshair.Size=UDim2.fromOffset(30,30)
crosshair.BackgroundTransparency=1
crosshair.Text="+"
crosshair.TextColor3=Color3.fromRGB(240,242,237)
crosshair.TextStrokeTransparency=0.6
crosshair.TextSize=28
crosshair.Font=Enum.Font.Gotham
crosshair.Visible=false
crosshair.Parent=gui

local selected: Tool?=nil
local observed: {[Tool]: boolean}=setmetatable({}, {__mode="k"})
local function updateAmmo()
    local tool=selected
    if not tool then return end
    local mag=tool:GetAttribute("Ammo")
    local reserve=tool:GetAttribute("Reserve")
    local isReloading=tool:GetAttribute("Reloading")==true
    ammo.Text=tostring(if type(mag)=="number" then mag else "?")
        .." / "..tostring(if type(reserve)=="number" then reserve else "?")
    hint.Text=if isReloading then "재장전 중..."
        elseif mag==0 and reserve==0 then "예비 탄약 없음"
        else (if UserInputService.TouchEnabled then "재장전 버튼" else "R  ·  재장전")
end
local function reloadAction(_name: string,inputState: Enum.UserInputState,_input: InputObject): Enum.ContextActionResult
    if inputState==Enum.UserInputState.Begin and selected then
        remote:FireServer("reload")
    end
    return Enum.ContextActionResult.Sink
end
local function unequip(tool: Tool)
    if selected~=tool then return end
    selected=nil
    panel.Visible=false
    crosshair.Visible=false
    ContextActionService:UnbindAction("TrainingRifleReload")
end
local function equip(tool: Tool)
    if selected==tool then return end
    if selected then unequip(selected) end
    selected=tool
    panel.Visible=true
    crosshair.Visible=true
    updateAmmo()
    ContextActionService:BindAction("TrainingRifleReload",reloadAction,true,Enum.KeyCode.R)
    ContextActionService:SetTitle("TrainingRifleReload","재장전")
    ContextActionService:SetPosition("TrainingRifleReload",UDim2.new(1,-168,1,-192))
end
local function observe(child: Instance)
    if not child:IsA("Tool") then return end
    local tool=child :: Tool
    if observed[tool] then return end
    if tool:GetAttribute("WeaponId")~=Rules.WEAPON_ID then
        -- Attributes can replicate immediately after a new Backpack child.
        local connection: RBXScriptConnection?=nil
        connection=tool:GetAttributeChangedSignal("WeaponId"):Connect(function()
            if tool:GetAttribute("WeaponId")==Rules.WEAPON_ID then
                if connection then connection:Disconnect() end
                observe(tool)
            end
        end)
        return
    end
    observed[tool]=true
    tool.Equipped:Connect(function() equip(tool) end)
    tool.Unequipped:Connect(function() unequip(tool) end)
    tool.Destroying:Connect(function() unequip(tool) end)
    tool.Activated:Connect(function()
        if selected~=tool then return end
        local camera=workspace.CurrentCamera
        if camera then remote:FireServer("fire",camera.CFrame.LookVector) end
    end)
    for _,attribute in {"Ammo","Reserve","Reloading"} do
        tool:GetAttributeChangedSignal(attribute):Connect(function()
            if selected==tool then updateAmmo() end
        end)
    end
    if tool.Parent==player.Character then equip(tool) end
end
local backpack=player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(observe)
for _,item in backpack:GetChildren() do observe(item) end
local function watchCharacter(character: Model)
    character.ChildAdded:Connect(observe)
    for _,item in character:GetChildren() do observe(item) end
    if selected and selected.Parent~=character then unequip(selected) end
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end
