--!strict
-- Polished single-tool training carbine: server grants it, authorizes every shot,
-- supplies positional SFX, and animates magazine/bolt for other players too.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TrainingRifleRules"))
local remote=Instance.new("RemoteEvent")
remote.Name="TrainingRifleAction"
remote.Parent=ReplicatedStorage

local sessions: {[Tool]: Rules.WeaponState}={}
local lastRemote: {[Player]: number}={}
local STEEL=Color3.fromRGB(46,50,53)
local DARK=Color3.fromRGB(24,28,31)
local OLIVE=Color3.fromRGB(79,85,72)
local ORANGE=Color3.fromRGB(223,158,63)
-- Previous -90-degree X Grip tilted the barrel down. This grip keeps local
-- -Z forward, with only a mild positional offset relative to the right hand.
local BASE_GRIP=CFrame.new(0,-0.29,-0.42)
-- Public Creator Store sounds. Availability still depends on experience permissions.
local FIRE_SOUND_ID="rbxassetid://9113189096"
local RELOAD_SOUND_ID="rbxassetid://8145744063"
local motorBases: {[Motor6D]: CFrame}={}

local function piece(tool: Tool,handle: Part,name: string,size: Vector3,
    offset: CFrame,color: Color3,material: Enum.Material?,shape: Enum.PartType?): Part
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.CFrame=handle.CFrame*offset
    p.Color=color
    p.Material=material or Enum.Material.Metal
    if shape then p.Shape=shape end
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Anchored=false
    p.Massless=true
    local w=Instance.new("WeldConstraint")
    w.Part0=handle
    w.Part1=p
    w.Parent=p
    p.Parent=tool
    return p
end
local function articulated(tool: Tool,handle: Part,name: string,size: Vector3,
    offset: CFrame): Motor6D
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.CFrame=handle.CFrame*offset
    p.Material=Enum.Material.Metal
    p.Color=DARK
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Anchored=false
    p.Massless=true
    p.Parent=tool
    local motor=Instance.new("Motor6D")
    motor.Name=name.."Joint"
    motor.Part0=handle
    motor.Part1=p
    motor.C0=offset
    motor.C1=CFrame.identity
    motor.Parent=handle
    motorBases[motor]=offset
    return motor
end
local function attachSound(handle: Part,name: string,id: string,volume: number)
    local s=Instance.new("Sound")
    s.Name=name
    s.SoundId=id
    s.Volume=volume
    s.RollOffMode=Enum.RollOffMode.InverseTapered
    s.RollOffMinDistance=15
    s.RollOffMaxDistance=220
    s.Parent=handle
end
local function playSound(handle: BasePart,name: string)
    local template=handle:FindFirstChild(name)
    if not template or not template:IsA("Sound") then return end
    local s=template:Clone()
    s.Name=name.."Playing"
    if name=="FireSound" then s.PlaybackSpeed=math.random(98,103)/100 end
    s.Parent=handle
    s:Play()
    Debris:AddItem(s,if name=="FireSound" then 4 else 3)
end
local function buildTool(): Tool
    local tool=Instance.new("Tool")
    tool.Name=Rules.DISPLAY_NAME
    tool.ToolTip="훈련 카빈 · 30발 · R 재장전"
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool.Grip=BASE_GRIP
    tool:SetAttribute("WeaponId",Rules.WEAPON_ID)
    tool:SetAttribute("MagazineSize",Rules.MAGAZINE)
    local handle=Instance.new("Part")
    handle.Name="Handle"
    handle.Size=Vector3.new(0.29,0.32,0.89)
    handle.Color=STEEL
    handle.Material=Enum.Material.Metal
    handle.CanCollide=false
    handle.CanTouch=false
    handle.CanQuery=false
    handle.Massless=true
    handle.Parent=tool

    local plastic=Enum.Material.SmoothPlastic
    local metal=Enum.Material.Metal
    local cylinder=Enum.PartType.Cylinder
    -- Higher-detail, symmetrical low-poly carbine model with optical sight.
    piece(tool,handle,"UpperReceiver",Vector3.new(0.40,0.33,0.93),CFrame.new(0,0.18,-0.08),STEEL,metal)
    piece(tool,handle,"LowerReceiver",Vector3.new(0.35,0.21,0.52),CFrame.new(0,-0.15,0.07),DARK,metal)
    piece(tool,handle,"Handguard",Vector3.new(0.44,0.38,0.95),CFrame.new(0,0.04,-0.95),OLIVE,plastic)
    for _,side in {-1,1} do
        for _,z in {-1.30,-1.05,-0.80} do
            piece(tool,handle,"Vent",Vector3.new(0.03,0.10,0.11),
                CFrame.new(side*0.24,0.03,z),DARK,metal)
        end
    end
    -- Cylinders' local Y axis is aligned with rifle local -Z.
    piece(tool,handle,"Barrel",Vector3.new(0.15,0.89,0.15),
        CFrame.new(0,0,-1.76)*CFrame.Angles(math.rad(-90),0,0),DARK,metal,cylinder)
    piece(tool,handle,"MuzzleBrake",Vector3.new(0.22,0.25,0.22),
        CFrame.new(0,0,-2.22)*CFrame.Angles(math.rad(-90),0,0),STEEL,metal,cylinder)
    piece(tool,handle,"SafetyTip",Vector3.new(0.23,0.085,0.23),
        CFrame.new(0,0,-2.38)*CFrame.Angles(math.rad(-90),0,0),ORANGE,metal,cylinder)
    piece(tool,handle,"TopRail",Vector3.new(0.23,0.09,1.78),CFrame.new(0,0.37,-0.49),DARK,metal)
    piece(tool,handle,"FrontSight",Vector3.new(0.12,0.25,0.13),CFrame.new(0,0.54,-1.56),DARK,metal)
    piece(tool,handle,"RearSight",Vector3.new(0.19,0.20,0.12),CFrame.new(0,0.52,0.18),DARK,metal)
    piece(tool,handle,"OpticMount",Vector3.new(0.26,0.13,0.36),CFrame.new(0,0.48,-0.37),STEEL,metal)
    piece(tool,handle,"ReflexSight",Vector3.new(0.36,0.24,0.30),CFrame.new(0,0.67,-0.37),DARK,metal)
    piece(tool,handle,"SightGlass",Vector3.new(0.20,0.15,0.035),
        CFrame.new(0,0.68,-0.53),Color3.fromRGB(65,123,144),Enum.Material.Glass)
    piece(tool,handle,"ChargingHandle",Vector3.new(0.39,0.12,0.15),CFrame.new(0,0.39,0.25),DARK,metal)
    piece(tool,handle,"TriggerGuard",Vector3.new(0.24,0.09,0.38),CFrame.new(0,-0.37,0.13),DARK,metal)
    piece(tool,handle,"PistolGrip",Vector3.new(0.28,0.62,0.27),
        CFrame.new(0,-0.54,0.35)*CFrame.Angles(math.rad(-16),0,0),OLIVE,plastic)
    piece(tool,handle,"StockTube",Vector3.new(0.18,0.18,0.91),CFrame.new(0,-0.03,0.98),STEEL,metal)
    piece(tool,handle,"Stock",Vector3.new(0.34,0.37,0.74),CFrame.new(0,-0.11,1.28),OLIVE,plastic)
    piece(tool,handle,"ShoulderPad",Vector3.new(0.41,0.55,0.14),CFrame.new(0,-0.16,1.72),DARK,plastic)
    piece(tool,handle,"SafetySelector",Vector3.new(0.06,0.10,0.17),CFrame.new(0.20,0,0.20),ORANGE,metal)
    piece(tool,handle,"MagCollar",Vector3.new(0.34,0.10,0.36),CFrame.new(0,-0.34,-0.24),STEEL,metal)
    local mag=articulated(tool,handle,"Magazine",Vector3.new(0.32,0.73,0.33),
        CFrame.new(0,-0.68,-0.21)*CFrame.Angles(math.rad(12),0,0))
    local bolt=articulated(tool,handle,"Bolt",Vector3.new(0.08,0.11,0.37),CFrame.new(0.24,0.18,-0.18))
    local port=piece(tool,handle,"EjectionPort",Vector3.new(0.012,0.14,0.42),
        CFrame.new(0.216,0.16,-0.13),DARK,metal)
    port.Transparency=0.1

    local muzzle=Instance.new("Attachment")
    muzzle.Name="Muzzle"
    muzzle.Position=Vector3.new(0,0,-2.47)
    muzzle.Parent=handle
    local spark=Instance.new("ParticleEmitter")
    spark.Name="MuzzleFlash"
    spark.Enabled=false
    spark.Rate=0
    spark.Texture="rbxasset://textures/particles/sparkles_main.dds"
    spark.Lifetime=NumberRange.new(0.04,0.10)
    spark.Speed=NumberRange.new(2,6)
    spark.Size=NumberSequence.new(0.23,0)
    spark.Color=ColorSequence.new(Color3.fromRGB(255,219,147),Color3.fromRGB(255,121,44))
    spark.SpreadAngle=Vector2.new(35,35)
    spark.LightEmission=1
    spark.Parent=muzzle
    local light=Instance.new("PointLight")
    light.Name="FlashLight"
    light.Color=Color3.fromRGB(255,200,110)
    light.Range=10
    light.Brightness=2.8
    light.Enabled=false
    light.Parent=muzzle
    attachSound(handle,"FireSound",FIRE_SOUND_ID,0.8)
    attachSound(handle,"ReloadSound",RELOAD_SOUND_ID,0.72)

    local state=Rules.new()
    sessions[tool]=state
    tool:SetAttribute("Ammo",state.ammo)
    tool:SetAttribute("Reserve",state.reserve)
    tool:SetAttribute("Reloading",false)
    tool.Destroying:Connect(function()
        sessions[tool]=nil
        motorBases[mag]=nil
        motorBases[bolt]=nil
    end)
    return tool
end
local function publish(tool: Tool,state: Rules.WeaponState)
    tool:SetAttribute("Ammo",state.ammo)
    tool:SetAttribute("Reserve",state.reserve)
    tool:SetAttribute("Reloading",state.reloadUntil>0)
end
local function animateBolt(handle: BasePart)
    local joint=handle:FindFirstChild("BoltJoint")
    if not joint or not joint:IsA("Motor6D") then return end
    local base=motorBases[joint]
    if not base then return end
    joint.C0=base*CFrame.new(0,0,0.17)
    TweenService:Create(joint,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=base}):Play()
end
local function animateMag(handle: BasePart)
    local joint=handle:FindFirstChild("MagazineJoint")
    if not joint or not joint:IsA("Motor6D") then return end
    local base=motorBases[joint]
    if not base then return end
    TweenService:Create(joint,TweenInfo.new(0.29,Enum.EasingStyle.Quad),{
        C0=base*CFrame.new(0,-0.64,-0.12)*CFrame.Angles(math.rad(11),0,0)}):Play()
    task.delay(0.96,function()
        if joint.Parent then
            TweenService:Create(joint,TweenInfo.new(0.41,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{C0=base}):Play()
        end
    end)
end
local function makeTracer(from: Vector3,to: Vector3)
    local length=(to-from).Magnitude
    if length<0.1 then return end
    local p=Instance.new("Part")
    p.Name="TrainingRifleTracer"
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Material=Enum.Material.Neon
    p.Transparency=0.35
    p.Color=Color3.fromRGB(251,202,130)
    p.Size=Vector3.new(0.045,0.045,length)
    p.CFrame=CFrame.lookAt(from,to)*CFrame.new(0,0,-length/2)
    p.Parent=workspace
    Debris:AddItem(p,0.075)
end
local function fire(player: Player,tool: Tool,state: Rules.WeaponState,aimPoint: any)
    if typeof(aimPoint)~="Vector3" then return end
    if aimPoint.X~=aimPoint.X or aimPoint.Y~=aimPoint.Y or aimPoint.Z~=aimPoint.Z
        or math.max(math.abs(aimPoint.X),math.abs(aimPoint.Y),math.abs(aimPoint.Z))>100000 then return end
    local character=player.Character
    if not character or tool.Parent~=character then return end
    local head=character:FindFirstChild("Head")
    local root=character:FindFirstChild("HumanoidRootPart")
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not head or not head:IsA("BasePart") or not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health<=0 then return end
    local handle=tool:FindFirstChild("Handle")
    local muzzle=if handle then handle:FindFirstChild("Muzzle") else nil
    if not handle or not handle:IsA("BasePart") or not muzzle or not muzzle:IsA("Attachment") then return end
    local origin=muzzle.WorldPosition
    if (origin-head.Position).Magnitude>8 then return end
    local toAim=(aimPoint :: Vector3)-origin
    if toAim.Magnitude<0.5 then return end
    local direction=toAim.Unit
    -- Forward hemisphere check prevents backwards/behind-the-head exploit shots.
    local facing=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
    local heading=Vector3.new(direction.X,0,direction.Z)
    if facing.Magnitude>0.1 and heading.Magnitude>0.1
        and facing.Unit:Dot(heading.Unit)<-0.45 then return end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.IgnoreWater=true
    local bridge=origin-head.Position
    if bridge.Magnitude>0.1 and workspace:Raycast(head.Position,bridge,params) then return end
    if not Rules.tryFire(state,os.clock()) then return end
    publish(tool,state)
    playSound(handle,"FireSound")
    animateBolt(handle)
    local spark=muzzle:FindFirstChild("MuzzleFlash")
    if spark and spark:IsA("ParticleEmitter") then spark:Emit(7) end
    local light=muzzle:FindFirstChild("FlashLight")
    if light and light:IsA("PointLight") then
        light.Enabled=true
        task.delay(0.07,function() if light.Parent then light.Enabled=false end end)
    end
    local result=workspace:Raycast(origin,direction*Rules.RANGE,params)
    makeTracer(origin,if result then result.Position else origin+direction*Rules.RANGE)
    if not result then return end
    local model=result.Instance:FindFirstAncestorOfClass("Model")
    local victim=if model then model:FindFirstChildOfClass("Humanoid") else nil
    if not victim or victim.Health<=0 or victim==humanoid then return end
    local target=Players:GetPlayerFromCharacter(model :: Model)
    if target and player.Team and not player.Neutral and target.Team==player.Team and not target.Neutral then return end
    victim:TakeDamage(Rules.DAMAGE)
end
local function reload(tool: Tool,state: Rules.WeaponState)
    if not Rules.startReload(state,os.clock()) then return end
    publish(tool,state)
    local handle=tool:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        playSound(handle,"ReloadSound")
        animateMag(handle)
    end
    task.delay(Rules.RELOAD_SECONDS+0.04,function()
        if sessions[tool]~=state or not tool.Parent then return end
        if Rules.completeReload(state,os.clock()) then publish(tool,state) end
    end)
end
remote.OnServerEvent:Connect(function(player: Player,action: any,aimPoint: any)
    if type(action)~="string" or #action>12 then return end
    local now=os.clock()
    if now-(lastRemote[player] or -math.huge)<0.045 then return end
    lastRemote[player]=now
    local character=player.Character
    local tool=if character then character:FindFirstChild(Rules.DISPLAY_NAME) else nil
    if not tool or not tool:IsA("Tool") or tool:GetAttribute("WeaponId")~=Rules.WEAPON_ID then return end
    local state=sessions[tool]
    if not state then return end
    if action=="fire" then
        fire(player,tool,state,aimPoint)
    elseif action=="reload" then
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health>0 then reload(tool,state) end
    end
end)
local function grant(player: Player,character: Model)
    task.spawn(function()
        local backpack=player:WaitForChild("Backpack",10)
        if player.Parent~=Players or player.Character~=character or not backpack then return end
        if backpack:FindFirstChild(Rules.DISPLAY_NAME) or character:FindFirstChild(Rules.DISPLAY_NAME) then return end
        local tool=buildTool()
        if player.Parent==Players and player.Character==character then tool.Parent=backpack
        else tool:Destroy() end
    end)
end
local function add(player: Player)
    player.CharacterAdded:Connect(function(character: Model) grant(player,character) end)
    if player.Character then grant(player,player.Character) end
end
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(player) lastRemote[player]=nil end)
for _,player in Players:GetPlayers() do add(player) end
