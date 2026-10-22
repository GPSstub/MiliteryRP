--!strict
-- Input, HUD and replicated procedural presentation. Never reports targets/damage.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local ContextActionService=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KatanaRules"))
local remote=ReplicatedStorage:WaitForChild("KatanaAction") :: RemoteEvent
local selected: Tool?=nil
local localReady=0
local observed: {[Tool]: boolean}=setmetatable({},{__mode="k"})
local activeTweens: {[Tool]: Tween}=setmetatable({},{__mode="k"})
local versions: {[Tool]: number}=setmetatable({},{__mode="k"})
local REST=CFrame.new(0,-.1,0)
local gui=Instance.new("ScreenGui");gui.Name="KatanaHUD";gui.ResetOnSpawn=false
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Name="Status";label.AnchorPoint=Vector2.new(1,1)
label.Position=UDim2.new(1,-18,1,-20);label.Size=UDim2.fromOffset(235,66)
label.BackgroundColor3=Color3.fromRGB(10,25,46);label.BackgroundTransparency=.15
label.TextColor3=Color3.fromRGB(215,235,255);label.TextSize=17;label.Font=Enum.Font.GothamMedium
label.Text="카타나  ·  클릭 / 터치로 베기";label.Visible=false;label.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=label
local hit=Instance.new("TextLabel");hit.Name="HitMarker";hit.Size=UDim2.fromOffset(50,50)
hit.Position=UDim2.new(.5,-25,.5,-25);hit.BackgroundTransparency=1;hit.Text="×"
hit.Font=Enum.Font.GothamBold;hit.TextColor3=Color3.fromRGB(170,225,255);hit.TextSize=36;hit.Visible=false;hit.Parent=gui
local function pose(tool: Tool,cf: CFrame,duration: number)
    if activeTweens[tool] then activeTweens[tool]:Cancel() end
    local tween=TweenService:Create(tool,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Grip=cf})
    activeTweens[tool]=tween;tween:Play()
end
local function present(tool: Tool,action: string)
    versions[tool]=(versions[tool] or 0)+1
    local version=versions[tool]
    if action=="draw" then
        tool.Grip=REST*CFrame.Angles(math.rad(-55),0,math.rad(-15))
        pose(tool,REST,Rules.DRAW_SECONDS)
        return
    end
    pose(tool,REST*CFrame.Angles(math.rad(-25),0,math.rad(-55)),.10)
    task.delay(.10,function()
        if versions[tool]~=version or not tool.Parent or not tool.Parent:IsA("Model") then return end
        pose(tool,REST*CFrame.Angles(math.rad(45),math.rad(25),math.rad(65)),.18)
    end)
    task.delay(.33,function()
        if versions[tool]~=version or not tool.Parent or not tool.Parent:IsA("Model") then return end
        pose(tool,REST,.22)
    end)
end
remote.OnClientEvent:Connect(function(action: unknown,item: unknown)
    if typeof(item)~="Instance" or not item:IsA("Tool") or item:GetAttribute("WeaponId")~=Rules.WEAPON_ID then return end
    local tool=item :: Tool
    if action=="swing" or action=="draw" then present(tool,action)
    elseif action=="hit" and selected==tool then
        hit.Visible=true;task.delay(.14,function() hit.Visible=false end)
    end
end)
local function attack()
    local tool=selected
    if not tool or tool.Parent~=player.Character or os.clock()<localReady then return end
    localReady=os.clock()+Rules.COOLDOWN
    remote:FireServer("swing")
    label.Text="카타나  ·  베기"
    task.delay(Rules.COOLDOWN,function()
        if selected==tool then label.Text="카타나  ·  클릭 / 터치로 베기" end
    end)
end
local function unequip(tool: Tool)
    versions[tool]=(versions[tool] or 0)+1
    if activeTweens[tool] then activeTweens[tool]:Cancel();activeTweens[tool]=nil end
    tool.Grip=REST
    if selected~=tool then return end
    selected=nil;label.Visible=false;hit.Visible=false
    ContextActionService:UnbindAction("KatanaSwing")
end
local function observe(item: Instance)
    if not item:IsA("Tool") then return end
    local tool=item :: Tool
    if observed[tool] then return end
    if tool:GetAttribute("WeaponId")~=Rules.WEAPON_ID then
        local connection: RBXScriptConnection?=nil
        connection=tool:GetAttributeChangedSignal("WeaponId"):Connect(function()
            if tool:GetAttribute("WeaponId")==Rules.WEAPON_ID then
                if connection then connection:Disconnect() end
                observe(tool)
            end
        end)
        tool.Destroying:Once(function() if connection then connection:Disconnect() end end)
        return
    end
    observed[tool]=true
    tool.Equipped:Connect(function()
        if selected and selected~=tool then unequip(selected) end
        selected=tool;localReady=os.clock()+Rules.DRAW_SECONDS;label.Visible=true
        ContextActionService:BindAction("KatanaSwing",function(_,state)
            if state==Enum.UserInputState.Begin then attack() end
            return Enum.ContextActionResult.Sink
        end,true,Enum.KeyCode.ButtonR2)
        ContextActionService:SetTitle("KatanaSwing","베기")
        ContextActionService:SetPosition("KatanaSwing",UDim2.new(1,-130,1,-220))
    end)
    tool.Unequipped:Connect(function() unequip(tool) end)
    tool.Destroying:Once(function() unequip(tool) end)
    tool.Activated:Connect(attack)
end
local backpack=player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(observe)
for _,tool in backpack:GetChildren() do observe(tool) end
local function watch(character: Model)
    character.ChildAdded:Connect(observe)
    for _,tool in character:GetChildren() do observe(tool) end
end
player.CharacterAdded:Connect(watch)
if player.Character then watch(player.Character) end
