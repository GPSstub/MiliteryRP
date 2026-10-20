--!strict
-- Creates official Roblox Team instances and assigns rank-category teams.
-- HQ is privileged and can only be granted through a server-authorized admin
-- operation; promotion to general NEVER grants HQ.
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local Policy=require(script.Parent.TeamPolicy)

local Service={}
local started=false
local watched: {[Player]: RBXScriptConnection}={}

function Service.ensure()
    for _,spec in Policy.SPECS do
        local existing=Teams:FindFirstChild(spec.name)
        local team: Team
        if existing and existing:IsA("Team") then
            team=existing
        else
            if existing then error("Team name is occupied: "..spec.name) end
            team=Instance.new("Team")
            team.Name=spec.name
            team.Parent=Teams
        end
        team.TeamColor=BrickColor.new(spec.color)
        team.AutoAssignable=false
    end
end

function Service.isAdmin(player: Player): boolean
    if player.Parent~=Players then return false end
    local hq=Teams:FindFirstChild(Policy.HQ)
    return hq~=nil and hq:IsA("Team") and player.Team==hq and not player.Neutral
end

local function applyRankTeam(player: Player)
    if player.Parent~=Players then return end
    if Service.isAdmin(player) then return end
    local teamName=Policy.teamForCategory(player:GetAttribute("RankCategory"))
    local team=if teamName then Teams:FindFirstChild(teamName) else nil
    if team and team:IsA("Team") then
        player.Team=team
        player.Neutral=false
    else
        player.Neutral=true
        player.Team=nil
    end
end

local function add(player: Player)
    if watched[player] then return end
    if player.UserId==Policy.OWNER_USER_ID then
        local hq=Teams:FindFirstChild(Policy.HQ)
        if hq and hq:IsA("Team") then player.Team=hq;player.Neutral=false end
    else
        applyRankTeam(player)
    end
    watched[player]=player:GetAttributeChangedSignal("RankCategory"):Connect(function()
        applyRankTeam(player)
    end)
end

function Service.assign(actor: Player,target: Player,name: string): (boolean,string)
    if not Service.isAdmin(actor) then return false,"HQ 팀만 팀을 배정할 수 있습니다." end
    if target.Parent~=Players or not Policy.isDefined(name) then
        return false,"HQ · 위관급 · 영관급 · 장관급 팀 중에서 선택하세요."
    end
    local team=Teams:FindFirstChild(name)
    if not team or not team:IsA("Team") then return false,"등록된 팀을 찾을 수 없습니다." end
    target.Team=team
    target.Neutral=false
    return true,target.Name.." → "..name
end

function Service.start()
    if started then return end
    Service.ensure()
    started=true
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player)
        local connection=watched[player]
        if connection then connection:Disconnect();watched[player]=nil end
    end)
    for _,player in Players:GetPlayers() do add(player) end
end

return Service
