--!strict
-- Equip-aware HUD and input for the server-authoritative training rifle.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local mouse=player:GetMouse()
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TrainingRifleRules"))
local Spring=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RifleRecoilSpring"))
local Viewmodel=require(script.Parent:WaitForChild("RifleViewmodel"))
local RunService=game:GetService("RunService")
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
-- Client-only body/weapon motion complements the server-replicated moving
-- magazine and bolt. No uploaded AnimationId assets are required.
local baseGrip: CFrame?=nil
local movementVersion=0
local recoilPosition=0
local recoilVelocity=0
local recoilActive=false
local previousCameraKick=0
local currentGripTween: Tween?=nil
local leftShoulder: Motor6D?=nil
local leftShoulderBase: CFrame?=nil
local armTween: Tween?=nil

local function animateGrip(tool: Tool,target: CFrame,duration: number,style: Enum.EasingStyle?)
    if currentGripTween then currentGripTween:Cancel() end
    if tool.Parent==nil then return end
    local tween=TweenService:Create(tool,TweenInfo.new(duration,style or Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out),{Grip=target})
    currentGripTween=tween
    tween:Play()
end
local function shoulderTarget(target: CFrame,duration: number)
    if armTween then armTween:Cancel() end
    if not leftShoulder or not leftShoulder.Parent then return end
    armTween=TweenService:Create(leftShoulder,TweenInfo.new(duration,Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out),{C0=target})
    armTween:Play()
end
local function findShoulder()
    leftShoulder=nil
    leftShoulderBase=nil
    local character=player.Character
    if not character then return end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    -- R15 off-hand is driven by a server IKControl linked to the weapon.
    -- Rotating LeftShoulder.C0 here would fight the whole-arm IK solver.
    if humanoid and humanoid.RigType==Enum.HumanoidRigType.R15 then return end
    local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end
    local shoulder=torso:FindFirstChild("LeftShoulder") or torso:FindFirstChild("Left Shoulder")
    if shoulder and shoulder:IsA("Motor6D") then
        leftShoulder=shoulder
        leftShoulderBase=shoulder.C0
    end
end
local function recoil(tool: Tool)
    if selected~=tool or not baseGrip then return end
    if tool:GetAttribute("Reloading")==true then return end
    -- Add velocity rather than teleporting to a rotation. Critical damping
    -- gives visible upward travel and a smooth, gradual downward recovery.
    if currentGripTween then currentGripTween:Cancel();currentGripTween=nil end
    movementVersion+=1
    recoilVelocity=math.min(recoilVelocity+Spring.KICK,Spring.KICK*1.5)
    recoilActive=true
end

RunService:BindToRenderStep("TrainingRifleSmoothRecoil",
    Enum.RenderPriority.Camera.Value+1,function(dt)
        if not selected then return end
        recoilPosition,recoilVelocity=Spring.step(recoilPosition,recoilVelocity,dt)
        local camera=workspace.CurrentCamera
        local nextCameraKick=recoilPosition*1.65
        if camera then
            local delta=nextCameraKick-previousCameraKick
            camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(delta),0,0)
        end
        previousCameraKick=nextCameraKick
        if recoilActive and baseGrip and selected:GetAttribute("Reloading")~=true then
            local rest=baseGrip
            selected.Grip=rest*CFrame.new(0,-recoilPosition*0.04,recoilPosition*0.12)
                *CFrame.Angles(math.rad(recoilPosition*6),0,0)
            if recoilPosition==0 and recoilVelocity==0 then
                selected.Grip=rest
                recoilActive=false
            end
        end
        -- RightGrip is disabled while the torso mount holds the rifle.
        -- Convert the same equip/reload/recoil Grip pose into mount space so
        -- the intentional animations survive without following arm swings.
        local handle=selected:FindFirstChild("Handle")
        local mount=if handle then handle:FindFirstChild("RifleHoldJoint") else nil
        if mount and mount:IsA("Motor6D") and baseGrip then
            local rest=mount:GetAttribute("RestC0")
            if typeof(rest)=="CFrame" then
                mount.C0=rest*baseGrip*selected.Grip:Inverse()
            end
        end
        Viewmodel.update(selected,camera,if baseGrip then baseGrip*selected.Grip:Inverse() else CFrame.identity)
    end)

local function reloadPose(tool: Tool)
    if selected~=tool or not baseGrip then return end
    movementVersion+=1
    recoilActive=false
    local version=movementVersion
    local rest=baseGrip
    animateGrip(tool,rest*CFrame.new(0,-0.12,0.16)
        *CFrame.Angles(math.rad(21),math.rad(-12),math.rad(-9)),0.24)
    if leftShoulder and leftShoulderBase then
        shoulderTarget(leftShoulderBase*CFrame.Angles(math.rad(-46),0,math.rad(32)),0.25)
    end
    task.delay(0.38,function()
        if movementVersion~=version or selected~=tool then return end
        animateGrip(tool,rest*CFrame.new(0,-0.18,0.22)
            *CFrame.Angles(math.rad(31),math.rad(-18),math.rad(-12)),0.33)
    end)
    task.delay(1.17,function()
        if movementVersion~=version or selected~=tool then return end
        animateGrip(tool,rest,0.48,Enum.EasingStyle.Back)
        if leftShoulder and leftShoulderBase then
            shoulderTarget(leftShoulderBase*CFrame.Angles(math.rad(-22),0,math.rad(14)),0.42)
        end
    end)
end
-- A rejected shot (wall obstruction, cooldown, empty magazine) must not kick.
remote.OnClientEvent:Connect(function(action: unknown,tool: unknown,hitPoint: unknown)
    if action=="shot" and typeof(tool)=="Instance" and tool:IsA("Tool") and selected==tool then
        recoil(tool)
        if typeof(hitPoint)=="Vector3" then Viewmodel.shot(tool,hitPoint) end
    end
end)
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
    movementVersion+=1
    recoilActive=false
    recoilPosition=0
    recoilVelocity=0
    previousCameraKick=0
    if currentGripTween then currentGripTween:Cancel();currentGripTween=nil end
    if baseGrip then tool.Grip=baseGrip end
    if armTween then armTween:Cancel();armTween=nil end
    if leftShoulder and leftShoulderBase and leftShoulder.Parent then
        leftShoulder.C0=leftShoulderBase
    end
    leftShoulder=nil
    leftShoulderBase=nil
    baseGrip=nil
    selected=nil
    Viewmodel.clear()
    panel.Visible=false
    crosshair.Visible=false
    ContextActionService:UnbindAction("TrainingRifleReload")
end
local function equip(tool: Tool)
    if selected==tool then return end
    if selected then unequip(selected) end
    selected=tool
    baseGrip=tool.Grip
    movementVersion+=1
    local version=movementVersion
    recoilActive=false
    recoilPosition=0
    recoilVelocity=0
    previousCameraKick=0
    findShoulder()
    panel.Visible=true
    -- PC now aims by mouse cursor, not the center reticle. Avoid drawing
    -- a misleading fixed '+' at screen center. Touch retains center aiming.
    crosshair.Visible=not UserInputService.MouseEnabled
    updateAmmo()
    local rest=baseGrip
    tool.Grip=rest*CFrame.new(0,-0.15,0.14)*CFrame.Angles(math.rad(20),0,0)
    task.defer(function()
        if selected==tool and movementVersion==version then animateGrip(tool,rest,0.23) end
    end)
    if leftShoulder and leftShoulderBase then
        shoulderTarget(leftShoulderBase*CFrame.Angles(math.rad(-22),0,math.rad(14)),0.22)
    end
    ContextActionService:BindAction("TrainingRifleReload",reloadAction,true,Enum.KeyCode.R)
    ContextActionService:SetTitle("TrainingRifleReload","재장전")
    ContextActionService:SetPosition("TrainingRifleReload",UDim2.new(1,-168,1,-192))
    if tool:GetAttribute("Reloading")==true then reloadPose(tool) end
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
        if not camera then return end
        -- PC mouse.UnitRay points at the actual pointer position, including
        -- when the camera is in third person. Shift-lock naturally aims
        -- through the locked cursor. Mobile still uses a center-screen ray.
        local ray: Ray
        if UserInputService.MouseEnabled then
            ray=mouse.UnitRay
        else
            local size=camera.ViewportSize
            ray=camera:ViewportPointToRay(size.X*0.5,size.Y*0.5)
        end
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=if player.Character then {player.Character} else {}
        params.IgnoreWater=true
        local hit=workspace:Raycast(ray.Origin,ray.Direction*Rules.RANGE,params)
        local aimPoint=if hit then hit.Position else ray.Origin+ray.Direction*Rules.RANGE
        remote:FireServer("fire",aimPoint)
    end)
    for _,attribute in {"Ammo","Reserve","Reloading"} do
        tool:GetAttributeChangedSignal(attribute):Connect(function()
            if selected==tool then
                updateAmmo()
                if attribute=="Reloading" and tool:GetAttribute("Reloading")==true then
                    reloadPose(tool)
                end
            end
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
