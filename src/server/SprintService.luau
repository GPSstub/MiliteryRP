--!strict
-- Server-authoritative, per-character sprint. The client sends only a boolean,
-- never a requested WalkSpeed. Resets on respawn, death, seat, or admin flight.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SprintConfig"))
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SprintRules"))

local Sprint={}
local started=false
local requestRemote: RemoteEvent?=nil
local playerConnections: {[Player]: {RBXScriptConnection}}={}
local humanoidConnections: {[Player]: {RBXScriptConnection}}={}

local function cleanupHumanoid(player: Player)
    local previous=humanoidConnections[player]
    if previous then
        for _,connection in previous do connection:Disconnect() end
        humanoidConnections[player]=nil
    end
end

local function currentHumanoid(player: Player): Humanoid?
    local character=player.Character
    if not character then return nil end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    return humanoid
end

local function apply(player: Player,requested: boolean): boolean
    if player.Parent~=Players then return false end
    local humanoid=currentHumanoid(player)
    local allowed=false
    if humanoid then
        allowed=Rules.allowed(
            requested,
            humanoid.Health>0,
            humanoid.SeatPart~=nil or humanoid.Sit,
            player:GetAttribute("AdminFlying")==true,
            humanoid.PlatformStand
        )
        local speed=if allowed then Config.SprintSpeed else Config.WalkSpeed
        if humanoid.WalkSpeed~=speed then humanoid.WalkSpeed=speed end
    end
    if player:GetAttribute("IsSprinting")~=allowed then
        player:SetAttribute("IsSprinting",allowed)
    end
    return allowed
end

local function onCharacter(player: Player,character: Model)
    cleanupHumanoid(player)
    player:SetAttribute("IsSprinting",false)
    task.spawn(function()
        local humanoid=character:WaitForChild("Humanoid",10)
        if player.Parent~=Players or player.Character~=character
            or not humanoid or not humanoid:IsA("Humanoid") then return end
        humanoid.WalkSpeed=Config.WalkSpeed
        humanoidConnections[player]={
            humanoid.Seated:Connect(function(active: boolean)
                if active then apply(player,false) end
            end),
            humanoid.Died:Connect(function()
                apply(player,false)
            end),
        }
        apply(player,false)
    end)
end

local function add(player: Player)
    if playerConnections[player] then return end
    player:SetAttribute("IsSprinting",false)
    playerConnections[player]={
        player.CharacterAdded:Connect(function(character: Model)
            onCharacter(player,character)
        end),
        player:GetAttributeChangedSignal("AdminFlying"):Connect(function()
            if player:GetAttribute("AdminFlying")==true then
                apply(player,false)
            end
        end),
    }
    if player.Character then onCharacter(player,player.Character) end
end

function Sprint.start()
    if started then return end
    started=true
    local remote=Instance.new("RemoteEvent")
    remote.Name="SprintRequest"
    remote.Parent=ReplicatedStorage
    requestRemote=remote

    remote.OnServerEvent:Connect(function(player: Player,requested: any)
        if player.Parent~=Players or type(requested)~="boolean" then return end
        -- Accept immediate reversals, especially rapid mobile toggles and
        -- keyboard Begin/End pairs. Do not leave clients desynchronized by
        -- silently dropping a new sprint request behind a cooldown.
        -- Repeated matching requests need no work.
        if player:GetAttribute("IsSprinting")==requested then return end
        apply(player,requested)
    end)

    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player: Player)
        cleanupHumanoid(player)
        local list=playerConnections[player]
        if list then
            for _,connection in list do connection:Disconnect() end
        end
        playerConnections[player]=nil
    end)
    for _,player in Players:GetPlayers() do add(player) end
end

return Sprint
