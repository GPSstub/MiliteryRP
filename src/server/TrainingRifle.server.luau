--!strict
-- A single Roblox training rifle: server-granted Tool, server ammo and raycast.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TrainingRifleRules"))

local remote=Instance.new("RemoteEvent")
remote.Name="TrainingRifleAction"
remote.Parent=ReplicatedStorage

local sessions: {[Tool]: Rules.WeaponState}={}
local lastRemote: {[Player]: number}={}
local steel=Color3.fromRGB(44,48,49)
local charcoal=Color3.fromRGB(27,30,33)
local gripColor=Color3.fromRGB(69,73,66)
local accent=Color3.fromRGB(222,166,63)

local function part(parent: Tool,handle: BasePart,name: string,size: Vector3,
    offset: CFrame,color: Color3,material: Enum.Material?): Part
    local piece=Instance.new("Part")
    piece.Name=name
    piece.Size=size
    piece.Color=color
    piece.Material=material or Enum.Material.Metal
    piece.CanCollide=false
    piece.CanQuery=false
    piece.CanTouch=false
    piece.Anchored=false
    piece.Massless=true
    piece.CFrame=handle.CFrame*offset
    local weld=Instance.new("WeldConstraint")
    weld.Part0=handle
    weld.Part1=piece
    weld.Parent=piece
    piece.Parent=parent
    return piece
end

local function buildTool(): Tool
    local tool=Instance.new("Tool")
    tool.Name=Rules.DISPLAY_NAME
    tool.ToolTip="30발 · R 키 / 화면 버튼 재장전"
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool:SetAttribute("WeaponId",Rules.WEAPON_ID)
    tool:SetAttribute("MagazineSize",Rules.MAGAZINE)
    tool.Grip=CFrame.new(0,-0.3,-0.4)*CFrame.Angles(math.rad(-90),0,0)

    -- Blocky temporary carbine model, oriented towards local -Z.
    local handle=Instance.new("Part")
    handle.Name="Handle"
    handle.Size=Vector3.new(0.31,0.38,0.98)
    handle.Material=Enum.Material.Metal
    handle.Color=steel
    handle.CanCollide=false
    handle.CanTouch=false
    handle.CanQuery=false
    handle.Anchored=false
    handle.Massless=true
    handle.Parent=tool

    part(tool,handle,"Handguard",Vector3.new(0.33,0.35,0.85),
        CFrame.new(0,0,-0.84),gripColor,Enum.Material.SmoothPlastic)
    part(tool,handle,"Barrel",Vector3.new(0.12,0.12,0.95),
        CFrame.new(0,0,-1.56),charcoal)
    part(tool,handle,"TrainingTip",Vector3.new(0.17,0.17,0.19),
        CFrame.new(0,0,-2.08),accent)
    part(tool,handle,"TopRail",Vector3.new(0.22,0.08,1.7),
        CFrame.new(0,0.25,-0.38),charcoal)
    part(tool,handle,"RearSight",Vector3.new(0.12,0.18,0.12),
        CFrame.new(0,0.37,0.23),charcoal)
    part(tool,handle,"FrontSight",Vector3.new(0.1,0.25,0.1),
        CFrame.new(0,0.38,-1.46),charcoal)
    part(tool,handle,"Magazine",Vector3.new(0.24,0.62,0.28),
        CFrame.new(0,-0.44,-0.22)*CFrame.Angles(math.rad(10),0,0),charcoal)
    part(tool,handle,"PistolGrip",Vector3.new(0.23,0.56,0.24),
        CFrame.new(0,-0.45,0.37)*CFrame.Angles(math.rad(-20),0,0),gripColor,Enum.Material.SmoothPlastic)
    part(tool,handle,"Stock",Vector3.new(0.28,0.28,0.95),
        CFrame.new(0,-0.04,0.98),gripColor,Enum.Material.SmoothPlastic)
    part(tool,handle,"ButtPlate",Vector3.new(0.34,0.5,0.12),
        CFrame.new(0,-0.11,1.5),charcoal,Enum.Material.SmoothPlastic)
    part(tool,handle,"SideSelector",Vector3.new(0.04,0.1,0.16),
        CFrame.new(0.18,0,0.27),accent)

    local muzzle=Instance.new("Attachment")
    muzzle.Name="Muzzle"
    muzzle.Position=Vector3.new(0,0,-2.22)
    muzzle.Parent=handle

    local state=Rules.new()
    sessions[tool]=state
    tool:SetAttribute("Ammo",state.ammo)
    tool:SetAttribute("Reserve",state.reserve)
    tool:SetAttribute("Reloading",false)
    tool.Destroying:Connect(function() sessions[tool]=nil end)
    return tool
end

local function publish(tool: Tool,state: Rules.WeaponState)
    tool:SetAttribute("Ammo",state.ammo)
    tool:SetAttribute("Reserve",state.reserve)
    tool:SetAttribute("Reloading",state.reloadUntil>0)
end

local function finiteVector(value: any): boolean
    if typeof(value)~="Vector3" then return false end
    local mag=value.Magnitude
    return mag==mag and mag>0.98 and mag<1.02 and mag<math.huge
end

local function makeTracer(origin: Vector3,finish: Vector3)
    local length=(finish-origin).Magnitude
    if length<=0.02 then return end
    local tracer=Instance.new("Part")
    tracer.Name="TrainingRifleTracer"
    tracer.Size=Vector3.new(0.055,0.055,length)
    tracer.Anchored=true
    tracer.CanCollide=false
    tracer.CanTouch=false
    tracer.CanQuery=false
    tracer.Material=Enum.Material.Neon
    tracer.Color=Color3.fromRGB(242,206,132)
    tracer.Transparency=0.16
    tracer.CFrame=CFrame.lookAt(origin,finish)*CFrame.new(0,0,-length/2)
    tracer.Parent=workspace
    Debris:AddItem(tracer,0.09)
end

local function shoot(player: Player,tool: Tool,state: Rules.WeaponState,aim: any)
    if not finiteVector(aim) then return end
    local character=player.Character
    if not character or tool.Parent~=character then return end
    local head=character:FindFirstChild("Head")
    local root=character:FindFirstChild("HumanoidRootPart")
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not head or not head:IsA("BasePart") or not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health<=0 then return end
    local handle=tool:FindFirstChild("Handle")
    local muzzle=if handle then handle:FindFirstChild("Muzzle") else nil
    if not muzzle or not muzzle:IsA("Attachment") then return end
    local origin=muzzle.WorldPosition
    if (origin-head.Position).Magnitude>8 then return end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.IgnoreWater=true
    -- Do not fire through a wall between the user's head and the muzzle.
    local bridge=origin-head.Position
    if bridge.Magnitude>0.1 and workspace:Raycast(head.Position,bridge,params) then return end
    local fired=Rules.tryFire(state,os.clock())
    if not fired then return end
    publish(tool,state)

    local direction=(aim :: Vector3).Unit
    local hit=workspace:Raycast(origin,direction*Rules.RANGE,params)
    local finish=if hit then hit.Position else origin+direction*Rules.RANGE
    makeTracer(origin,finish)
    if not hit then return end
    local model=hit.Instance:FindFirstAncestorOfClass("Model")
    local targetHumanoid=if model then model:FindFirstChildOfClass("Humanoid") else nil
    if not targetHumanoid or targetHumanoid.Health<=0 or targetHumanoid==humanoid then return end
    local targetPlayer=Players:GetPlayerFromCharacter(model :: Model)
    if targetPlayer and player.Team and not player.Neutral
        and targetPlayer.Team==player.Team and not targetPlayer.Neutral then return end
    targetHumanoid:TakeDamage(Rules.DAMAGE)
end

local function reload(tool: Tool,state: Rules.WeaponState)
    local begin=Rules.startReload(state,os.clock())
    if not begin then return end
    publish(tool,state)
    task.delay(Rules.RELOAD_SECONDS+0.03,function()
        if sessions[tool]~=state or not tool.Parent then return end
        if Rules.completeReload(state,os.clock()) then publish(tool,state) end
    end)
end

remote.OnServerEvent:Connect(function(player: Player,action: any,aim: any)
    if type(action)~="string" or #action>12 then return end
    -- Bound the processing of malformed remote requests as well as valid ones.
    local now=os.clock()
    if now-(lastRemote[player] or -math.huge)<0.045 then return end
    lastRemote[player]=now
    local character=player.Character
    local tool=if character then character:FindFirstChild(Rules.DISPLAY_NAME) else nil
    if not tool or not tool:IsA("Tool") then return end
    local state=sessions[tool]
    if not state or tool:GetAttribute("WeaponId")~=Rules.WEAPON_ID then return end
    if action=="fire" then
        shoot(player,tool,state,aim)
    elseif action=="reload" then
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health>0 then reload(tool,state) end
    end
end)

local function grant(player: Player,character: Model)
    task.spawn(function()
        local backpack=player:WaitForChild("Backpack",10)
        if player.Parent~=Players or player.Character~=character or not backpack then return end
        if backpack:FindFirstChild(Rules.DISPLAY_NAME)
            or character:FindFirstChild(Rules.DISPLAY_NAME) then return end
        local tool=buildTool()
        if player.Parent==Players and player.Character==character then
            tool.Parent=backpack
        else
            tool:Destroy()
        end
    end)
end
local function add(player: Player)
    player.CharacterAdded:Connect(function(character: Model) grant(player,character) end)
    if player.Character then grant(player,player.Character) end
end
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(player) lastRemote[player]=nil end)
for _,player in Players:GetPlayers() do add(player) end
