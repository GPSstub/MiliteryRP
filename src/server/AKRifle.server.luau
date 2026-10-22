--!strict
-- Polished single-tool training carbine: server grants it, authorizes every shot,
-- supplies positional SFX, and animates magazine/bolt for other players too.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AKRifleRules"))
local remote=Instance.new("RemoteEvent")
remote.Name="AKRifleAction"
remote.Parent=ReplicatedStorage

-- Persisted Studio templates are preferred; uploaded IDs make a fresh clone usable.
local MeshConfig=require(script.Parent:WaitForChild("AKMeshConfig"))
if not ServerStorage:FindFirstChild("AKAssets") then
    local folder=Instance.new("Folder")
    folder.Name="AKAssets"
    folder:SetAttribute("SourceRevision",MeshConfig.REVISION)
    local ok,err=pcall(function()
        for _,name in {"Body","Magazine"} do
            local config=MeshConfig[name]
            local part=game:GetService("AssetService"):CreateMeshPartAsync(
                Content.fromUri("rbxassetid://"..tostring(config.id)),
                {CollisionFidelity=Enum.CollisionFidelity.Box})
            part.Name=name
            part.Size=config.size
            part.TextureID=MeshConfig.TEXTURE
            part.CFrame=config.offset
            part:SetAttribute("HandleOffset",config.offset)
            part.Anchored=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.Massless=true
            part.Parent=folder
        end
    end)
    if ok then folder.Parent=ServerStorage
    else folder:Destroy();warn("[AKRifle] Mesh loading failed: "..tostring(err)) end
end

local sessions: {[Tool]: Rules.WeaponState}={}
local lastRemote: {[Player]: number}={}
local STEEL=Color3.fromRGB(46,50,53)
local DARK=Color3.fromRGB(24,28,31)
local OLIVE=Color3.fromRGB(79,85,72)
local ORANGE=Color3.fromRGB(223,158,63)
-- Measured in Studio: the former 180-degree yaw made muzzle/root dot -0.96.
-- New FBX geometry is authored with its pistol-grip pivot at the origin and
-- its muzzle along local -Z; keep the equipped assembly facing forward.
local R15_GRIP_YAW_DEGREES=0
local R15_GRIP_PITCH_DEGREES=16
local BASE_GRIP=CFrame.new(0,0.1,-0.3)
    *CFrame.Angles(math.rad(R15_GRIP_PITCH_DEGREES),0,0)
local AK_MESH_SCALE=1
local AK_SOURCE_REVISION="AK-Rounded-Hex-20261022"
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
    tool.ToolTip="AK · 기본 지급 · 30발 · R 재장전"
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool.Grip=BASE_GRIP
    tool:SetAttribute("WeaponId",Rules.WEAPON_ID)
    tool:SetAttribute("MagazineSize",Rules.MAGAZINE)
    tool:SetAttribute("UsingAKMesh",false)
    tool:SetAttribute("UsingR15SupportIK",false)
    tool:SetAttribute("UsingStableRifleMount",false)
    tool:SetAttribute("AKModelScale",AK_MESH_SCALE)
    tool:SetAttribute("GripYawDegrees",R15_GRIP_YAW_DEGREES)
    tool:SetAttribute("GripPitchDegrees",R15_GRIP_PITCH_DEGREES)
    tool:SetAttribute("MeshSourceRevision",AK_SOURCE_REVISION)
    tool:SetAttribute("MagazineFlipDegrees",0)
    tool:SetAttribute("MagazineTiltDegrees",15)
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

    -- Imported rounded hexagonal AK. Keep HK assets and entitlement separate.
    local assetFolder=ServerStorage:FindFirstChild("AKAssets")
    local bodyAsset=if assetFolder then assetFolder:FindFirstChild("Body") else nil
    local magAsset=if assetFolder then assetFolder:FindFirstChild("Magazine") else nil
    assert(bodyAsset and bodyAsset:IsA("MeshPart"),"AKAssets/Body mesh is missing")
    assert(magAsset and magAsset:IsA("MeshPart"),"AKAssets/Magazine mesh is missing")
    handle.Transparency=1
    tool:SetAttribute("UsingAKMesh",true)
    tool:SetAttribute("MagazineTiltDegrees",0)
    local function cloneMesh(source: MeshPart,name: string,offset: CFrame): MeshPart
        local part=source:Clone()
        part.Name=name
        part.CFrame=handle.CFrame*offset
        part.Anchored=false
        part.CanCollide=false
        part.CanTouch=false
        part.CanQuery=false
        part.Massless=true
        part.Parent=tool
        return part
    end
    local bodyOffset=bodyAsset:GetAttribute("HandleOffset")
    local magazineOffset=magAsset:GetAttribute("HandleOffset")
    assert(typeof(bodyOffset)=="CFrame" and typeof(magazineOffset)=="CFrame","AK mesh offsets are missing")
    local body=cloneMesh(bodyAsset,"AKBody",bodyOffset)
    local weld=Instance.new("WeldConstraint")
    weld.Part0=handle
    weld.Part1=body
    weld.Parent=body
    local magazine=cloneMesh(magAsset,"Magazine",magazineOffset)
    local mag=Instance.new("Motor6D")
    mag.Name="MagazineJoint"
    mag.Part0=handle
    mag.Part1=magazine
    -- Pivot at the feed lips; the mesh center remains in C1.
    local feed=CFrame.new(0,0.192,-0.672)
    mag.C0=feed
    mag.C1=magazineOffset:Inverse()*feed
    mag.Parent=handle
    motorBases[mag]=feed
    local bolt=articulated(tool,handle,"Bolt",Vector3.new(0.06,0.06,0.14),CFrame.new(0.16,0.468,-0.564))
    local support=Instance.new("Attachment")
    support.Name="SupportHandTarget"
    support.Position=Vector3.new(-0.18,0.32,-1.128)
    support.Parent=handle
    local reloadHand=Instance.new("Attachment")
    reloadHand.Name="MagazineHandTarget"
    reloadHand.Position=Vector3.new(-0.14,0.18,0)
    reloadHand.Parent=magazine
    local muzzle=Instance.new("Attachment")
    muzzle.Name="Muzzle"
    muzzle.Position=Vector3.new(0,0.384,-2.3556)
    muzzle.Parent=handle
    local spark=Instance.new("ParticleEmitter")
    spark.Name="MuzzleFlash"
    spark.Enabled=false
    spark.EmissionDirection=Enum.NormalId.Front
    spark.LockedToPart=true
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

    local state=Rules.new(true)
    tool:SetAttribute("UnlimitedReserve",true)
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
    local weapon=handle.Parent
    local scale=if weapon and weapon:IsA("Tool") and weapon:GetAttribute("UsingAKMesh")==true
        then AK_MESH_SCALE else 1
    joint.C0=base*CFrame.new(0,0,0.17*scale)
    TweenService:Create(joint,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=base}):Play()
end
local function animateMag(handle: BasePart)
    local joint=handle:FindFirstChild("MagazineJoint")
    if not joint or not joint:IsA("Motor6D") then return end
    local base=motorBases[joint]
    if not base then return end
    local weapon=handle.Parent
    local scale=if weapon and weapon:IsA("Tool") and weapon:GetAttribute("UsingAKMesh")==true
        then AK_MESH_SCALE else 1
    -- Translate in receiver space so reload always extracts downward.
    local translated=CFrame.new(0,-0.64*scale,-0.12*scale)*base
    TweenService:Create(joint,TweenInfo.new(0.29,Enum.EasingStyle.Quad),{
        C0=translated*CFrame.Angles(math.rad(11),0,0)}):Play()
    task.delay(0.96,function()
        if joint.Parent then
            TweenService:Create(joint,TweenInfo.new(0.41,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{C0=base}):Play()
        end
    end)
end
local function makeTracer(from: Vector3,to: Vector3,shooterId: number)
    local length=(to-from).Magnitude
    if length<0.1 then return end
    local p=Instance.new("Part")
    p.Name="AKRifleTracer"
    p:SetAttribute("ShooterUserId",shooterId)
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
    local muzzle=tool:FindFirstChild("Muzzle",true)
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
    local hitPoint=if result then result.Position else origin+direction*Rules.RANGE
    makeTracer(origin,hitPoint,player.UserId)
    remote:FireClient(player,"shot",tool,hitPoint)
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
    -- Only server-created sessions can fire this free default rifle.
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
-- Fix the weapon to the torso; IK makes both hands follow the weapon instead
-- of allowing the walk/tool arm animations to drag its muzzle around.
-- R6 retains Roblox's normal grip and the existing client shoulder fallback.
local function configureR15IK(tool: Tool,character: Model)
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType~=Enum.HumanoidRigType.R15 then return end
    local handle=tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return end
    local rest=handle:FindFirstChild("SupportHandTarget")
    local magazine=tool:FindFirstChild("Magazine")
    local loading=if magazine then magazine:FindFirstChild("MagazineHandTarget") else nil
    if not rest or not rest:IsA("Attachment") then return end

    local active: IKControl?=nil
    local rightControl: IKControl?=nil
    local rightTarget: Attachment?=nil
    local mount: Motor6D?=nil
    local defaultGrip: JointInstance?=nil
    local gripWasEnabled=true
    local equipVersion=0
    local function release()
        equipVersion+=1
        if active then active:Destroy();active=nil end
        if rightControl then rightControl:Destroy();rightControl=nil end
        if mount then mount:Destroy();mount=nil end
        if rightTarget then rightTarget:Destroy();rightTarget=nil end
        if defaultGrip and defaultGrip.Parent then defaultGrip.Enabled=gripWasEnabled end
        defaultGrip=nil
        tool:SetAttribute("UsingR15SupportIK",false)
        tool:SetAttribute("UsingStableRifleMount",false)
    end
    tool.Equipped:Connect(function()
        release()
        local version=equipVersion
        -- Client-owned R15 animation can reach the server after Equipped.
        -- Wait for the actual forward hold pose, never freeze the spawn pose
        -- with the arm dangling down. The bounded wait cancels on unequip.
        task.spawn(function()
            local ready=false
            for attempt=1,80 do
                if version~=equipVersion or tool.Parent~=character or humanoid.Health<=0 then return end
                local root=character:FindFirstChild("HumanoidRootPart")
                local hand=character:FindFirstChild("RightHand")
                local grip=if hand then hand:FindFirstChild("RightGrip") else nil
                if attempt>=4 and grip and grip:IsA("JointInstance") and grip.Part1==handle
                    and root and root:IsA("BasePart")
                    and handle.CFrame.LookVector:Dot(root.CFrame.LookVector)>0.85
                    and handle.CFrame.UpVector.Y>0.75 then
                    ready=true
                    break
                end
                task.wait(0.05)
            end
            if not ready then return end
            local torso=character:FindFirstChild("UpperTorso")
            local leftUpper=character:FindFirstChild("LeftUpperArm")
            local leftHand=character:FindFirstChild("LeftHand")
            local rightUpper=character:FindFirstChild("RightUpperArm")
            local rightHand=character:FindFirstChild("RightHand")
            if not torso or not torso:IsA("BasePart")
                or not leftUpper or not leftUpper:IsA("BasePart")
                or not leftHand or not leftHand:IsA("BasePart")
                or not rightUpper or not rightUpper:IsA("BasePart")
                or not rightHand or not rightHand:IsA("BasePart") then return end
            local grip=rightHand:FindFirstChild("RightGrip")
            if not grip or not grip:IsA("JointInstance") or grip.Part1~=handle then return end

            local target=Instance.new("Attachment")
            target.Name="TriggerHandTarget"
            target.CFrame=handle.CFrame:ToObjectSpace(rightHand.CFrame)
            target.Parent=handle
            rightTarget=target
            local joint=Instance.new("Motor6D")
            joint.Name="RifleHoldJoint"
            joint.Part0=torso
            joint.Part1=handle
            -- Server animation replication can lag the owning client's arm.
            -- Keep the fitted grip position, with a level forward rifle frame.
            local root=character:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsA("BasePart") then target:Destroy();rightTarget=nil;return end
            local held=CFrame.lookAt(handle.Position,
                handle.Position+root.CFrame.LookVector,root.CFrame.UpVector)
            joint.C0=torso.CFrame:ToObjectSpace(held)
            joint.C1=CFrame.identity
            joint:SetAttribute("RestC0",joint.C0)
            defaultGrip=grip
            gripWasEnabled=grip.Enabled
            grip.Enabled=false
            joint.Parent=handle
            mount=joint

            local right=Instance.new("IKControl")
            right.Name="AKRifleRightHandIK"
            right.Type=Enum.IKControlType.Transform
            right.ChainRoot=rightUpper
            right.EndEffector=rightHand
            right.Target=target
            right.SmoothTime=0
            right.Priority=20
            right.Weight=1
            right.Parent=humanoid
            rightControl=right

            local left=Instance.new("IKControl")
            left.Name="AKRifleLeftHandIK"
            left.Type=Enum.IKControlType.Position
            left.ChainRoot=leftUpper
            left.EndEffector=leftHand
            left.Target=if tool:GetAttribute("Reloading")==true and loading then loading else rest
            left.SmoothTime=0
            left.Priority=10
            left.Weight=1
            left.Parent=humanoid
            active=left
            tool:SetAttribute("UsingR15SupportIK",true)
            tool:SetAttribute("UsingStableRifleMount",true)
        end)
    end)
    tool.Unequipped:Connect(release)
    tool.Destroying:Connect(release)
    humanoid.Died:Connect(release)
    tool:GetAttributeChangedSignal("Reloading"):Connect(function()
        if active and active.Parent then
            active.Target=if tool:GetAttribute("Reloading")==true and loading then loading else rest
        end
    end)
end

local function grant(player: Player,character: Model)
    task.spawn(function()
        local backpack=player:WaitForChild("Backpack",10)
        if player.Parent~=Players or player.Character~=character or not backpack then return end
        if backpack:FindFirstChild(Rules.DISPLAY_NAME) or character:FindFirstChild(Rules.DISPLAY_NAME) then return end
        local assets=ServerStorage:FindFirstChild("AKAssets")
        if not assets or not assets:FindFirstChild("Body") or not assets:FindFirstChild("Magazine") then
            warn("[AKRifle] AKAssets missing: import assets/ak/AK_Roblox.glb and run installer")
            return
        end
        local tool=buildTool()
        configureR15IK(tool,character)
        if player.Parent==Players and player.Character==character then tool.Parent=backpack
        else tool:Destroy() end
    end)
end
local function add(player: Player)
    player.CharacterAdded:Connect(function(character: Model) grant(player,character) end)
    if player.Character then grant(player,player.Character) end
end
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(player: Player) lastRemote[player]=nil end)
for _,player in Players:GetPlayers() do add(player) end
