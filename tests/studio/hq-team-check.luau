-- Server Command Bar or Studio test script (run only while Play is active).
-- Read-only test. It never grants teams, changes ranks or calls DataStores.
local ServerScriptService=game:GetService("ServerScriptService")
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local TeamService=require(ServerScriptService.TeamService)
local TeamPolicy=require(ServerScriptService.TeamPolicy)
local AdminService=require(ServerScriptService.AdminService)

TeamService.start()
local checks=0
local function check(ok: boolean,why: string)
    checks+=1
    assert(ok,why)
end
for _,spec in TeamPolicy.SPECS do
    local team=Teams:FindFirstChild(spec.name)
    check(team~=nil and team:IsA("Team"),"Missing Team: "..spec.name)
    check(team.AutoAssignable==false,"Team incorrectly auto-assignable: "..spec.name)
    check(team.TeamColor==BrickColor.new(spec.color),"Team color mismatch: "..spec.name)
end
for _,player in Players:GetPlayers() do
    local hq=TeamService.isAdmin(player)
    check(hq==(player.Team==Teams:FindFirstChild("HQ") and not player.Neutral),
        "Inconsistent HQ membership: "..player.Name)
    -- Safe rank listing only; no ranks, teams or admin modes are changed.
    local success,message=AdminService.execute(player,"/계급목록")
    if hq then
        check(success,"HQ player should list ranks: "..message)
    else
        check(not success,"Non-HQ player unexpectedly executed a rank command")
    end
end
print("[HQ TEST] "..checks.." assertions passed; "..#Players:GetPlayers().." players inspected.")
