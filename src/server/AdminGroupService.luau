--!strict
-- Server-only source of administrator authority from Roblox group membership.
-- No DataStore and no trust in client-set attributes, teams, or leaderstats.
local Players=game:GetService("Players")
local GroupService=game:GetService("GroupService")
local Policy=require(script.Parent:WaitForChild("AdminGroupPolicy"))

local Service={}
local started=false
local ranks: {[Player]: number}={}
local generations: {[Player]: number}={}

function Service.isAdmin(player: Player): boolean
    return player.Parent==Players and Policy.isAdminRank(ranks[player])
end

function Service.rank(player: Player): number?
    if player.Parent~=Players then return nil end
    return ranks[player]
end

local function getRank(player: Player): number?
    -- Preferred API: accounts can hold multiple roles. Highest public rank
    -- is compared against the configured minimum.
    local ok,result=pcall(function()
        return GroupService:GetRolesInGroupAsync(player.UserId,Policy.GROUP_ID)
    end)
    if ok then
        local rank=Policy.rankFromRoles(result)
        if rank~=nil then return rank end
    end

    -- Supported older Roblox method, used only when GroupService fails.
    -- It yields and may be cached by Roblox for the current play session.
    local legacyOK,legacyRank=pcall(function()
        return player:GetRankInGroupAsync(Policy.GROUP_ID)
    end)
    if legacyOK and Policy.validRank(legacyRank) then
        return legacyRank
    end
    return nil
end

local function resolve(player: Player,version: number)
    for attempt=1,3 do
        if player.Parent~=Players or generations[player]~=version then return end
        local rank=getRank(player)
        if rank~=nil then
            if player.Parent~=Players or generations[player]~=version then return end
            ranks[player]=rank
            player:SetAttribute("AdminGroupRank",rank)
            player:SetAttribute("CanUseAdminCommands",Policy.isAdminRank(rank))
            player:SetAttribute("AdminGroupStatus","Ready")
            return
        end
        warn("[AdminGroupService] Group rank lookup failed for",player.UserId,
            "attempt",attempt,"group",Policy.GROUP_ID)
        if attempt<3 then task.wait(2*attempt) end
    end
    if player.Parent~=Players or generations[player]~=version then return end
    -- Fail closed: a transient service failure must not grant privileges.
    ranks[player]=nil
    player:SetAttribute("AdminGroupRank",0)
    player:SetAttribute("CanUseAdminCommands",false)
    player:SetAttribute("AdminGroupStatus","Error")
end

local function add(player: Player)
    if generations[player] then return end
    generations[player]=1
    player:SetAttribute("AdminGroupRank",0)
    player:SetAttribute("CanUseAdminCommands",false)
    player:SetAttribute("AdminGroupStatus","Checking")
    task.spawn(resolve,player,1)
end

function Service.start()
    if started then return end
    started=true
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player)
        ranks[player]=nil
        generations[player]=nil
    end)
    for _,player in Players:GetPlayers() do add(player) end
end

return Service
