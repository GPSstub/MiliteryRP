--!strict
-- Default melee tool: server owns inventory, attack windows, targets and damage.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local AssetService=game:GetService("AssetService")
local Debris=game:GetService("Debris")
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KatanaRules"))
local MeshConfig=require(script.Parent:WaitForChild("KatanaMeshConfig"))
local remote=Instance.new("RemoteEvent")
remote.Name="KatanaAction"
remote.Parent=ReplicatedStorage
local templates=ServerStorage:FindFirstChild("KatanaAssets")
if not templates then
    local folder=Instance.new("Folder")
    folder.Name="KatanaAssets"
    local ok,err=pcall(function()
        for _,name in {"Katana","Scabbard"} do
            local data=MeshConfig[name]
            local part=AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://"..tostring(data.id)),
                {CollisionFidelity=Enum.CollisionFidelity.Box})
            part.Name=name
            part.Size=data.size
            part.TextureID=MeshConfig.TEXTURE
            part.Anchored=true
            part.CanCollide=false
            part.Parent=folder
        end
    end)
    if ok then folder:SetAttribute("SourceRevision",MeshConfig.REVISION);folder.Parent=ServerStorage;templates=folder
    else folder:Destroy();warn("[Katana] Asset load failed: "..tostring(err)) end
end
if not templates then return end
local assets=templates :: Instance
local weaponAsset=assets:FindFirstChild("Katana")
local sheathAsset=assets:FindFirstChild("Scabbard")
if not weaponAsset or not weaponAsset:IsA("MeshPart") or not sheathAsset or not sheathAsset:IsA("MeshPart") then
    warn("[Katana] KatanaAssets requires Katana + Scabbard MeshParts")
    return
end
type Session={owner: Player,state: Rules.State,sword: MeshPart,stowed: MeshPart,sheath: Model,trail: Trail}
local sessions: {[Tool]: Session}={}
local lastRemote: {[Player]: number}={}
local function finiteVector(v: Vector3): boolean
    return v.X==v.X and v.Y==v.Y and v.Z==v.Z
        and math.max(math.abs(v.X),math.abs(v.Y),math.abs(v.Z))<1000000
end
local function prepare(part: BasePart)
    part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
end
local function weld(part: BasePart,root: BasePart,offset: CFrame)
    part.CFrame=root.CFrame*offset
    local joint=Instance.new("Weld")
    joint.Part0=root;joint.Part1=part;joint.C0=offset;joint.C1=CFrame.identity;joint.Parent=part
end
local function sound(handle: BasePart,id: string)
    local s=Instance.new("Sound");s.SoundId=id;s.Volume=.5;s.RollOffMaxDistance=70;s.Parent=handle
    s:Play();Debris:AddItem(s,3)
end
local function alive(player: Player,tool: Tool): (Model?,Humanoid?,BasePart?)
    local c=player.Character
    if not c or tool.Parent~=c then return nil,nil,nil end
    local h=c:FindFirstChildOfClass("Humanoid")
    local r=c:FindFirstChild("HumanoidRootPart")
    if not h or h.Health<=0 or not r or not r:IsA("BasePart") or not finiteVector(r.Position) then return nil,nil,nil end
    return c,h,r
end
local function ancestorHumanoid(part: BasePart): (Model?,Humanoid?)
    local node: Instance?=part.Parent
    for _=1,6 do
        if not node or node==workspace then break end
        if node:IsA("Model") then
            local h=node:FindFirstChildOfClass("Humanoid")
            if h then return node,h end
        end
        node=node.Parent
    end
    return nil,nil
end
local function strike(player: Player,tool: Tool,session: Session,origin: Vector3,serial: number,hit: {[Humanoid]: boolean})
    local c,_,r=alive(player,tool)
    if not c or not r or sessions[tool]~=session or session.state.serial~=serial then return end
    if (r.Position-origin).Magnitude>3.5 then return end
    local params=OverlapParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={c};params.MaxParts=128
    local box=r.CFrame*CFrame.new(0,0,-Rules.RANGE/2)
    local parts=workspace:GetPartBoundsInBox(box,Vector3.new(7,7,Rules.RANGE),params)
    for _,part in parts do
        local model,h=ancestorHumanoid(part)
        if not model or not h or hit[h] or h.Health<=0 then continue end
        local target=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if not target or not target:IsA("BasePart") or not finiteVector(target.Position) then continue end
        local delta=target.Position-r.Position
        local flat=Vector3.new(delta.X,0,delta.Z)
        local facing=Vector3.new(r.CFrame.LookVector.X,0,r.CFrame.LookVector.Z)
        local dot=if flat.Magnitude<.1 then 1 else flat.Unit:Dot(facing.Unit)
        if not Rules.inReach(delta.Magnitude,dot,delta.Y) then continue end
        local victim=Players:GetPlayerFromCharacter(model)
        if not Rules.canDamage(victim==player,victim~=nil and player.Team~=nil and victim.Team==player.Team,
            player.Neutral,if victim then victim.Neutral else true) then continue end
        local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={c}
        local start=r.Position+Vector3.new(0,1,0)
        local ray=workspace:Raycast(start,target.Position+Vector3.new(0,1,0)-start,rp)
        if ray and not ray.Instance:IsDescendantOf(model) then continue end
        hit[h]=true
        h:TakeDamage(Rules.DAMAGE)
        remote:FireClient(player,"hit",tool)
    end
end
remote.OnServerEvent:Connect(function(player: Player,action: unknown,extra: unknown)
    local now=os.clock()
    if now-(lastRemote[player] or -math.huge)<.06 then return end
    lastRemote[player]=now
    if action~="swing" or extra~=nil then return end
    local c=player.Character
    local tool=if c then c:FindFirstChild(Rules.DISPLAY_NAME) else nil
    if not tool or not tool:IsA("Tool") then return end
    local session=sessions[tool]
    if not session or session.owner~=player then return end
    local character,_,root=alive(player,tool)
    local handle=tool:FindFirstChild("Handle")
    if not character or not root or not handle or not handle:IsA("BasePart")
        or not finiteVector(handle.Position) or (handle.Position-root.Position).Magnitude>7 then return end
    if not Rules.trySwing(session.state,now) then return end
    local serial=session.state.serial
    local origin=root.Position
    tool:SetAttribute("Swinging",true)
    tool:SetAttribute("SwingSerial",serial)
    tool:SetAttribute("NextSwingAt",workspace:GetServerTimeNow()+Rules.COOLDOWN)
    remote:FireAllClients("swing",tool)
    sound(handle,"rbxasset://sounds/swordslash.wav")
    task.delay(Rules.WINDUP,function()
        if sessions[tool]~=session or session.state.serial~=serial then return end
        session.trail.Enabled=true
        local hit: {[Humanoid]: boolean}={}
        for _=1,5 do
            strike(player,tool,session,origin,serial,hit)
            task.wait(Rules.ACTIVE_SECONDS/4)
        end
        if sessions[tool]==session then session.trail.Enabled=false end
    end)
    task.delay(Rules.COOLDOWN,function()
        if sessions[tool]==session and session.state.serial==serial then tool:SetAttribute("Swinging",false) end
    end)
end)
local function grant(player: Player,character: Model)
    task.spawn(function()
        local backpack=player:WaitForChild("Backpack",10)
        local h=character:WaitForChild("Humanoid",10)
        local torso=character:WaitForChild("HumanoidRootPart",10)
        if not backpack or not h or not h:IsA("Humanoid") or not torso or not torso:IsA("BasePart")
            or player.Parent~=Players or player.Character~=character then return end
        if backpack:FindFirstChild(Rules.DISPLAY_NAME) or character:FindFirstChild(Rules.DISPLAY_NAME) then return end
        local hip=character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso") or torso
        if not hip:IsA("BasePart") then return end
        local tool=Instance.new("Tool");tool.Name=Rules.DISPLAY_NAME;tool.CanBeDropped=false
        tool.ToolTip="카타나 · 클릭 베기 · 30 데미지";tool.Grip=CFrame.new(0,-.1,0)
        tool:SetAttribute("WeaponId",Rules.WEAPON_ID);tool:SetAttribute("Swinging",false)
        tool:SetAttribute("Damage",Rules.DAMAGE);tool:SetAttribute("Cooldown",Rules.COOLDOWN)
        local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.16,.65,.16)
        handle.Transparency=1;prepare(handle);handle.Parent=tool
        local sword=(weaponAsset :: MeshPart):Clone();sword.Name="Blade";prepare(sword);sword.Parent=tool
        weld(sword,handle,MeshConfig.Katana.offset)
        local a=Instance.new("Attachment");a.Name="BladeBase";a.Position=MeshConfig.Katana.offset:PointToObjectSpace(Vector3.new(0,.70,0));a.Parent=sword
        local b=Instance.new("Attachment");b.Name="BladeTip";b.Position=MeshConfig.Katana.offset:PointToObjectSpace(Vector3.new(0,3.42,0));b.Parent=sword
        local trail=Instance.new("Trail");trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.12
        trail.Color=ColorSequence.new(Color3.fromRGB(150,205,255));trail.Transparency=NumberSequence.new(.45,1)
        trail.FaceCamera=true;trail.Enabled=false;trail.Parent=sword
        local sheath=Instance.new("Model");sheath.Name="KatanaSheath";sheath.Parent=character
        local anchor=Instance.new("Part");anchor.Name="Mouth";anchor.Size=Vector3.new(.1,.1,.1)
        anchor.Transparency=1;prepare(anchor);anchor.Parent=sheath;weld(anchor,hip,MeshConfig.HIP_OFFSET)
        local cover=(sheathAsset :: MeshPart):Clone();cover.Name="Scabbard";prepare(cover);cover.Parent=sheath
        weld(cover,anchor,MeshConfig.Scabbard.offset)
        local stowed=(weaponAsset :: MeshPart):Clone();stowed.Name="StowedKatana";prepare(stowed);stowed.Parent=sheath
        weld(stowed,anchor,MeshConfig.STOWED_OFFSET)
        local session: Session={owner=player,state=Rules.new(),sword=sword,stowed=stowed,sheath=sheath,trail=trail}
        sessions[tool]=session
        tool.Equipped:Connect(function()
            Rules.equip(session.state,os.clock());stowed.Transparency=1;trail.Enabled=false
            tool:SetAttribute("Swinging",false);tool:SetAttribute("Drawn",true)
            remote:FireAllClients("draw",tool)
            sound(handle,"rbxasset://sounds/unsheath.wav")
        end)
        tool.Unequipped:Connect(function()
            Rules.unequip(session.state);stowed.Transparency=0;trail.Enabled=false
            tool:SetAttribute("Swinging",false);tool:SetAttribute("Drawn",false)
        end)
        local function cleanup()
            Rules.unequip(session.state);sessions[tool]=nil
            if sheath.Parent then sheath:Destroy() end
        end
        tool.Destroying:Once(cleanup)
        h.Died:Once(function() if tool.Parent then tool:Destroy() end end)
        tool.Parent=backpack
    end)
end
local function add(player: Player)
    player.CharacterAdded:Connect(function(c: Model) grant(player,c) end)
    if player.Character then grant(player,player.Character) end
end
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(player: Player) lastRemote[player]=nil end)
for _,player in Players:GetPlayers() do add(player) end
