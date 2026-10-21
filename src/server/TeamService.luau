--!strict
-- Server-owned team assignment. Actual rank -> team mapping; "본부" is
-- manually assigned for a session until a later rank change.
-- Administrator command authority is independent of ranks and teams.
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local Policy=require(script.Parent.TeamPolicy)
local AdminGroupService=require(script.Parent.AdminGroupService)

local Service={}
local started=false
local watched: {[Player]: {RBXScriptConnection}}={}
local queued: {[Player]: boolean}={}

function Service.ensure()
    local ordered: {Team}={}
    for index,spec in Policy.SPECS do
        local existing=Teams:FindFirstChild(spec.name)
        local team: Team
        if existing and existing:IsA("Team") then
            team=existing
        else
            if existing then error("Team name is occupied: "..spec.name) end
            team=Instance.new("Team")
            team.Name=spec.name
        end
        team.TeamColor=BrickColor.new(spec.color)
        team.AutoAssignable=false
        team:SetAttribute("TeamOrder",index)
        table.insert(ordered,team)
    end
    -- Native team lists commonly use parenting/insertion order. Reparent in
    -- the requested hierarchy even when the four old teams already exist.
    -- No existing team objects are destroyed.
    for _,team in ordered do team.Parent=nil end
    for _,team in ordered do team.Parent=Teams end
end

function Service.isAdmin(player: Player): boolean
    return AdminGroupService.isAdmin(player)
end
function Service.isHQ(player: Player): boolean
    if player.Parent~=Players then return false end
    local hq=Teams:FindFirstChild(Policy.HQ)
    return hq~=nil and hq:IsA("Team") and player.Team==hq and not player.Neutral
end
local function applyRankTeam(player: Player)
    if player.Parent~=Players then return end
    local name=Policy.teamForCategory(player:GetAttribute("RankCategory"))
    -- New players are trainees: join the soldier team before DataStore returns.
    if name==nil and player:GetAttribute("RankId")==nil then name="병사" end
    local team=if name then Teams:FindFirstChild(name) else nil
    if team and team:IsA("Team") then
        if player.Team~=team or player.Neutral then
            player.Team=team
            player.Neutral=false
        end
    elseif player.Team or not player.Neutral then
        player.Neutral=true
        player.Team=nil
    end
end
local function queueRankTeam(player: Player)
    if queued[player] then return end
    queued[player]=true
    -- RankService publishes RankId before RankCategory, so defer once to
    -- observe the *final* category. A new rank assignment overrides a prior
    -- manual HQ/본부/team transfer; ordinary team switches do not.
    task.defer(function()
        queued[player]=nil
        if watched[player] then applyRankTeam(player) end
    end)
end
local function add(player: Player)
    if watched[player] then return end
    watched[player]={
        player:GetAttributeChangedSignal("RankCategory"):Connect(function()
            queueRankTeam(player)
        end),
        player:GetAttributeChangedSignal("RankId"):Connect(function()
            queueRankTeam(player)
        end),
    }
    applyRankTeam(player)
end
function Service.assign(actor: Player,target: Player,name: string): (boolean,string)
    if not Service.isAdmin(actor) then return false,"Roblox 그룹 관리자만 팀을 배정할 수 있습니다." end
    if target.Parent~=Players or not Policy.isDefined(name) then
        return false,"HQ · 본부 · 장관급 · 영관급 · 위관급 · 부사관급 · 병사 팀 중에서 선택하세요."
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
    AdminGroupService.start()
    started=true
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player)
        local list=watched[player]
        watched[player]=nil
        queued[player]=nil
        if list then for _,connection in list do connection:Disconnect() end end
    end)
    for _,player in Players:GetPlayers() do add(player) end
end
return Service
