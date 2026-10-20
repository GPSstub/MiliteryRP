--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local Audit = require(script.Parent:WaitForChild("AdminAudit"))
local RankCommands = require(script.Parent:WaitForChild("RankCommands"))
local TeamService = require(script.Parent:WaitForChild("TeamService"))
local PlayerCommandParser = require(script.Parent:WaitForChild("AdminPlayerCommandParser"))
local PlayerActions = require(script.Parent:WaitForChild("AdminPlayerActions"))
local AdminLogService = require(script.Parent:WaitForChild("AdminLogService"))
local Service = {}
local started = false
local requests: {[Player]: number} = {}
local syncRequests: {[Player]: number} = {}
local inputs: {[Player]: number} = {}
local flying: {[Player]: any} = {}
local healthConnections: {[Player]: RBXScriptConnection} = {}
local teamConnections: {[Player]: {RBXScriptConnection}} = {}
local hadHQ: {[Player]: boolean} = {}
local function authorized(actor: Player): boolean
    return TeamService.isAdmin(actor)
end
local function targetFor(actor: Player, name: string): Player?
    if name == "나" or name == "me" then return actor end
    for _, p in Players:GetPlayers() do
        if string.lower(p.Name) == string.lower(name) then return p end
    end
    return nil
end
local function stopFlight(player: Player)
    local state = flying[player]
    flying[player] = nil
    player:SetAttribute("AdminFlying", false)
    if not state then return end
    for _, instance in {state.velocity, state.orientation, state.attachment} do instance:Destroy() end
    if state.humanoid.Parent then
        state.humanoid.PlatformStand = state.platformStand
        state.humanoid.AutoRotate = state.autoRotate
    end
    if state.root.Parent then
        state.root.AssemblyLinearVelocity = Vector3.zero
        pcall(function() state.root:SetNetworkOwnershipAuto() end)
    end
end
local function setFlight(player: Player, enabled: boolean): (boolean, string)
    stopFlight(player)
    if not enabled then return true, player.Name .. " 비행 끄기" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 or root.Anchored or humanoid.SeatPart then
        return false, "살아 있고 앉아 있지 않은 캐릭터가 필요합니다."
    end
    local attachment = Instance.new("Attachment"); attachment.Name = "AdminFlightAttachment"; attachment.Parent = root
    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "AdminFlightVelocity"; velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.MaxForce = math.max(100000, root.AssemblyMass * workspace.Gravity * 8)
    velocity.VectorVelocity = Vector3.zero; velocity.Parent = root
    local orientation = Instance.new("AlignOrientation")
    orientation.Name = "AdminFlightOrientation"; orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orientation.Attachment0 = attachment; orientation.MaxTorque = 100000; orientation.Responsiveness = 15
    orientation.CFrame = root.CFrame.Rotation; orientation.Parent = root
    flying[player] = {root=root, humanoid=humanoid, attachment=attachment, velocity=velocity, orientation=orientation,
        autoRotate=humanoid.AutoRotate, platformStand=humanoid.PlatformStand, direction=Vector3.zero, lastInput=os.clock()}
    humanoid.AutoRotate = false; humanoid.PlatformStand = true
    root:SetNetworkOwner(nil)
    player:SetAttribute("AdminFlying", true)
    return true, player.Name .. " 비행 켜기"
end
local function applyGod(player: Player)
    local previous = healthConnections[player]
    if previous then previous:Disconnect(); healthConnections[player] = nil end
    local character = player.Character
    if not character then return end
    local previousField = character:FindFirstChild("AdminGodForceField")
    if previousField then previousField:Destroy() end
    if not player:GetAttribute("AdminGod") then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local field = Instance.new("ForceField"); field.Name="AdminGodForceField"; field.Visible=false; field.Parent=character
    humanoid.Health = humanoid.MaxHealth
    healthConnections[player] = humanoid.HealthChanged:Connect(function(health)
        if health > 0 and health < humanoid.MaxHealth and player:GetAttribute("AdminGod") then humanoid.Health=humanoid.MaxHealth end
    end)
end
function Service.execute(actor: Player, text: any): (boolean, string)
    if typeof(actor) ~= "Instance" or not actor:IsA("Player") or not authorized(actor) then return false, "HQ 팀만 관리자 명령어를 사용할 수 있습니다." end
    if type(text) ~= "string" or #text > 256 or not utf8.len(text) then return false, "명령어는 256바이트 이내로 입력하세요." end
    local words: {string} = {}
    for word in string.gmatch(text, "%S+") do table.insert(words, word) end
    local verb = words[1]
    if verb == ";계급" or verb == ";rank" or verb == ";계급목록" or verb == ";ranks" then
        return RankCommands.handle(actor, text) -- RankCommands records its own audit entry.
    end
    local ok, message = false, "사용법: ;to 대상 · ;here 대상 · ;kill 대상 · ;폭발 대상 · ;계급 대위"
    local target = if words[2] then targetFor(actor, words[2]) else actor
    if not target then
        message = "서버에 있는 정확한 Roblox 사용자 이름을 선택하세요."
    elseif verb == ";무적" or verb == ";god" or verb == ";비행" or verb == ";fly" then
        local mode = words[3]
        local enabled = mode == "켜기" or mode == "on"
        if #words == 3 and (enabled or mode == "끄기" or mode == "off") then
            if verb == ";무적" or verb == ";god" then
                target:SetAttribute("AdminGod", enabled); applyGod(target)
                ok=true; message=target.Name .. (if enabled then " 무적 켜기" else " 무적 끄기")
            else ok, message = setFlight(target, enabled) end
        end
    elseif verb == ";팀" or verb == ";team" then
        local name = table.concat(words, " ", 3)
        ok,message=TeamService.assign(actor,target,name)
    elseif PlayerCommandParser.isVerb(verb) then
        local action=PlayerCommandParser.parse(text)
        if not action then
            message="사용법: ;to 대상 · ;here 대상 · ;kill 대상 · ;폭발 대상 (정확한 사용자 이름)"
        else
            local recipient=targetFor(actor,action.target)
            if not recipient then
                message="현재 서버에 있는 정확한 Roblox 사용자 이름을 입력하세요."
            else
                ok,message=PlayerActions.run(actor,recipient,action.kind,stopFlight)
            end
        end
    end
    Audit.record(actor, text, ok, message)
    return ok, message
end
function Service.start()
    if started then return end
    started=true
    TeamService.start()
    -- Audit storage should not take down admin commands or panel commands.
    local auditOk,auditError=pcall(AdminLogService.start)
    if not auditOk then warn("[AdminService] Admin logs unavailable:",auditError) end
    local request=Instance.new("RemoteEvent"); request.Name="AdminRequest"; request.Parent=ReplicatedStorage
    local response=Instance.new("RemoteEvent"); response.Name="AdminResponse"; response.Parent=ReplicatedStorage
    local flightInput=Instance.new("RemoteEvent"); flightInput.Name="AdminFlightInput"; flightInput.Parent=ReplicatedStorage
    request.OnServerEvent:Connect(function(actor: Player, action: any, text: any)
        if not authorized(actor) then return end
        local now=os.clock()
        if action=="sync" then
            if now-(syncRequests[actor] or -math.huge)<0.5 then return end
            syncRequests[actor]=now
            -- Legacy snapshot intentionally contains no raw/unfiltered commands.
            -- The HQ panel fetches filtered, durable history through AdminLogRequest.
            response:FireClient(actor,"snapshot",{})
        elseif action=="command" then
            if now-(requests[actor] or -math.huge)<0.25 then
                response:FireClient(actor,"result",{ok=false,message="너무 빠른 명령입니다. 잠시 후 다시 시도하세요."})
                return
            end
            requests[actor]=now
            local ok,message=Service.execute(actor,text)
            response:FireClient(actor,"result",{ok=ok,message=message})
        end
    end)
    -- Chat bar commands: the engine intercepts ';...' before broadcasting
    -- regular chat. Every call still enters Service.execute(), which validates
    -- the player's current HQ membership on the server.
    for _,spec in {
        {"HQGodCommand",";무적",";god"},
        {"HQFlightCommand",";비행",";fly"},
        {"HQTeamCommand",";팀",";team"},
        {"HQTeleportToCommand",";to"},
        {"HQTeleportHereCommand",";here"},
        {"HQKillCommand",";kill"},
        {"HQExplosionCommand",";폭발",";explode"},
    } do
        local command=Instance.new("TextChatCommand")
        command.Name=spec[1]
        command.PrimaryAlias=spec[2]
        if spec[3] then command.SecondaryAlias=spec[3] end
        command.Enabled=true
        command.Triggered:Connect(function(source: TextSource,text: string)
            if not source then return end
            local actor=Players:GetPlayerByUserId(source.UserId)
            if not actor then return end
            local ok,message=Service.execute(actor,text)
            response:FireClient(actor,"chat_result",{ok=ok,message=message})
        end)
        command.Parent=TextChatService
    end

    local function finiteVector(value: any): boolean
        return typeof(value)=="Vector3" and value.X==value.X and value.Y==value.Y and value.Z==value.Z
            and math.abs(value.X)<=1.01 and math.abs(value.Y)<=1.01 and math.abs(value.Z)<=1.01 and value.Magnitude<=1.01
    end
    flightInput.OnServerEvent:Connect(function(player: Player, direction: any, facing: any)
        local state=flying[player]
        if not state then return end
        local now=os.clock()
        if now-(inputs[player] or -math.huge)<0.04 then return end
        inputs[player]=now
        if not finiteVector(direction) or not finiteVector(facing) then return end
        state.direction=direction; state.lastInput=now
        local flat=Vector3.new(facing.X,0,facing.Z)
        if flat.Magnitude>0.01 then state.orientation.CFrame=CFrame.lookAt(Vector3.zero,flat) end
    end)
    RunService.Heartbeat:Connect(function()
        for player,state in flying do
            if not state.root.Parent or state.humanoid.Health<=0 then stopFlight(player)
            else state.velocity.VectorVelocity=if os.clock()-state.lastInput<0.4 then state.direction*32 else Vector3.zero end
        end
    end)
    local function added(player: Player)
        player:SetAttribute("AdminGod",false); player:SetAttribute("AdminFlying",false)
        hadHQ[player]=authorized(player)
        local function checkTeam()
            local stillHQ=authorized(player)
            if hadHQ[player] and not stillHQ then
                -- HQ powers are revoked immediately on transfer out of HQ.
                stopFlight(player)
                player:SetAttribute("AdminGod",false)
                applyGod(player)
            end
            hadHQ[player]=stillHQ
        end
        teamConnections[player]={
            player:GetPropertyChangedSignal("Team"):Connect(checkTeam),
            player:GetPropertyChangedSignal("Neutral"):Connect(checkTeam),
            player.CharacterAdded:Connect(function(character)
                stopFlight(player)
                local humanoid=character:WaitForChild("Humanoid",10)
                if humanoid and player.Character==character then applyGod(player) end
            end),
        }
    end
    Players.PlayerAdded:Connect(added)
    for _,p in Players:GetPlayers() do added(p) end
    Players.PlayerRemoving:Connect(function(p)
        stopFlight(p); requests[p]=nil;syncRequests[p]=nil;inputs[p]=nil;hadHQ[p]=nil
        if healthConnections[p] then healthConnections[p]:Disconnect();healthConnections[p]=nil end
        local connections=teamConnections[p]
        if connections then
            for _,connection in connections do connection:Disconnect() end
            teamConnections[p]=nil
        end
    end)
end
return Service
