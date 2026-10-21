--!strict
-- Local camera-space presentation only. Hits, ammo and wall checks stay server-side.
local Players=game:GetService("Players")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local Viewmodel={}
local CAMERA_GRIP=CFrame.new(0.60,-0.70,-0.75)
local owner: Tool?=nil
local model: Model?=nil
local sourceHandle: BasePart?=nil
local copies: {[BasePart]: BasePart}={}
local hidden: {[BasePart]: number}={}
local hiddenParticles: {[ParticleEmitter]: number}={}
local lastFrame=CFrame.identity

function Viewmodel.clear()
    for part,value in hidden do
        if part.Parent then part.LocalTransparencyModifier=value end
    end
    for emitter,value in hiddenParticles do
        if emitter.Parent then emitter.LocalTransparencyModifier=value end
    end
    table.clear(copies)
    table.clear(hidden)
    table.clear(hiddenParticles)
    if model then model:Destroy() end
    owner=nil
    model=nil
    sourceHandle=nil
end

local function addPart(part: BasePart,parent: Model)
    local copy=part:Clone()
    for _,child in copy:GetDescendants() do
        if child:IsA("JointInstance") or child:IsA("WeldConstraint")
            or child:IsA("Sound") or child:IsA("LuaSourceContainer") then
            child:Destroy()
        end
    end
    copy.Anchored=true
    copy.CanCollide=false
    copy.CanTouch=false
    copy.CanQuery=false
    copy.CastShadow=false
    copy.LocalTransparencyModifier=0
    copy.Parent=parent
    copies[part]=copy
    hidden[part]=part.LocalTransparencyModifier
    for _,child in part:GetDescendants() do
        if child:IsA("ParticleEmitter") then
            hiddenParticles[child]=child.LocalTransparencyModifier
        end
    end
end

local function build(tool: Tool,camera: Camera): boolean
    local handle=tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end
    local view=Instance.new("Model")
    view.Name="TrainingRifleViewmodel"
    for _,child in tool:GetChildren() do
        if child:IsA("BasePart") then addPart(child,view) end
    end
    local character=player.Character
    if character then
        for _,name in {"RightUpperArm","RightLowerArm","RightHand",
            "LeftUpperArm","LeftLowerArm","LeftHand","Right Arm","Left Arm"} do
            local arm=character:FindFirstChild(name)
            if arm and arm:IsA("BasePart") then addPart(arm,view) end
        end
    end
    sourceHandle=handle
    owner=tool
    model=view
    view.Parent=camera
    return true
end

function Viewmodel.update(tool: Tool?,camera: Camera?,pose: CFrame)
    local firstPerson=camera~=nil and (player.CameraMode==Enum.CameraMode.LockFirstPerson
        or (camera.CFrame.Position-camera.Focus.Position).Magnitude<1)
    if not firstPerson or not tool or not camera then
        if model then Viewmodel.clear() end
        return
    end
    if owner~=tool then
        Viewmodel.clear()
        if not build(tool,camera) then return end
    end
    local view=model
    local handle=sourceHandle
    if not view or not handle or not handle.Parent then Viewmodel.clear();return end
    view.Parent=camera
    lastFrame=camera.CFrame*CAMERA_GRIP*pose
    for source,copy in copies do
        if source.Parent and copy.Parent then
            source.LocalTransparencyModifier=1
            copy.CFrame=lastFrame*handle.CFrame:ToObjectSpace(source.CFrame)
        end
    end
    for emitter in hiddenParticles do
        if emitter.Parent then emitter.LocalTransparencyModifier=1 end
    end
end

function Viewmodel.shot(tool: Tool,hitPoint: Vector3)
    if owner~=tool or not model then return end
    local muzzle=model:FindFirstChild("Muzzle",true)
    if not muzzle or not muzzle:IsA("Attachment") then return end
    local spark=muzzle:FindFirstChild("MuzzleFlash")
    if spark and spark:IsA("ParticleEmitter") then spark:Emit(7) end
    local light=muzzle:FindFirstChild("FlashLight")
    if light and light:IsA("PointLight") then
        light.Enabled=true
        task.delay(0.07,function() if light.Parent then light.Enabled=false end end)
    end
    local origin=muzzle.WorldPosition
    local distance=(hitPoint-origin).Magnitude
    if distance<0.1 then return end
    local tracer=Instance.new("Part")
    tracer.Name="TrainingRifleViewTracer"
    tracer.Anchored=true
    tracer.CanCollide=false
    tracer.CanTouch=false
    tracer.CanQuery=false
    tracer.Material=Enum.Material.Neon
    tracer.Color=Color3.fromRGB(251,202,130)
    tracer.Transparency=0.35
    tracer.Size=Vector3.new(0.035,0.035,distance)
    tracer.CFrame=CFrame.lookAt(origin,hitPoint)*CFrame.new(0,0,-distance/2)
    tracer.Parent=workspace
    Debris:AddItem(tracer,0.075)
end

-- Hide only our own world-space tracer while showing the camera-space one.
-- Other players keep seeing the authoritative muzzle and tracer as usual.
workspace.ChildAdded:Connect(function(child: Instance)
    if child.Name~="TrainingRifleTracer" or not child:IsA("BasePart") then return end
    local function hideOwnTracer()
        if model and child:GetAttribute("ShooterUserId")==player.UserId then
            child.LocalTransparencyModifier=1
        end
    end
    hideOwnTracer()
    local connection=child:GetAttributeChangedSignal("ShooterUserId"):Connect(hideOwnTracer)
    child.Destroying:Once(function() connection:Disconnect() end)
end)
return Viewmodel
