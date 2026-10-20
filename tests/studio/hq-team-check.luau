-- Server Command Bar or Studio test script (run only while Play is active).
-- Safe test: does not grant teams, change ranks or touch DataStores.
-- Executing ;계급목록 may append a harmless entry to the in-server audit log.
local ServerScriptService=game:GetService("ServerScriptService")
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local TeamService=require(ServerScriptService.TeamService)
local TeamPolicy=require(ServerScriptService.TeamPolicy)
local GroupPolicy=require(ServerScriptService.AdminGroupPolicy)
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
    local isHQ=TeamService.isHQ(player)
    check(isHQ==(player.Team==Teams:FindFirstChild("HQ") and not player.Neutral),
        "HQ visual team membership is inconsistent: "..player.Name)
    local groupAdmin=TeamService.isAdmin(player)
    local status=player:GetAttribute("AdminGroupStatus")
    local rank=player:GetAttribute("AdminGroupRank")
    -- Group lookup may still be running immediately after joining.
    if status=="Ready" then
        check(groupAdmin==GroupPolicy.isAdminRank(rank),
            "Group rank and server authorization differ for "..player.Name)
        check(groupAdmin==(player:GetAttribute("CanUseAdminCommands")==true),
            "Group admin UI marker differs from server permissions")
    else
        check(not groupAdmin,"Unverified group roles must never grant access")
    end
    -- Safe rank listing only; no ranks, teams or admin modes are changed.
    local success,message=AdminService.execute(player,";계급목록")
    if groupAdmin then
        check(success or message=="잠시 후 다시 입력하세요.",
            "HQ player should be able to list ranks: "..message)
    else
        check(not success,"Non-admin group member executed a rank command")
        -- This is harmless for non-HQ users: authorization must reject BEFORE
        -- the kill, explosion or teleport action is considered.
        for _,command in {";to me",";here me",";kill me",";폭발 me"} do
            local actionOK=AdminService.execute(player,command)
            check(not actionOK,"Non-admin group member was allowed to run "..command)
        end
    end
end
print("[HQ TEST] "..checks.." assertions passed; "..#Players:GetPlayers().." players inspected.")
