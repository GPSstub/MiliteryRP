--!strict
local Players=game:GetService("Players")
local TeamService=require(script.Parent:WaitForChild("TeamService"))
local RankService=require(script.Parent:WaitForChild("RankService"))
local SprintService=require(script.Parent:WaitForChild("SprintService"))

-- Ensure the four teams are available before rank loading and command registration.
-- Non-HQ teams track RankCategory; HQ is an explicit admin appointment.
TeamService.start()
-- Rank overhead and leaderboard setup are gameplay-critical. Register them
-- BEFORE optional persistent audit services so a DataStore/logging outage
-- cannot suppress every player's overhead nameplate.
Players.PlayerAdded:Connect(RankService.add)
Players.PlayerRemoving:Connect(RankService.remove)
for _,player in Players:GetPlayers() do RankService.add(player) end

-- Sprint controls are independent of persistent logs and HQ administration.
-- Start the server movement authority before optional services.
SprintService.start()

local logsReady,logError=pcall(function()
    require(script.Parent:WaitForChild("AdminLogService")).start()
end)
if not logsReady then
    warn("[Main] Admin logging unavailable; ranks and overhead remain active:",logError)
end
require(script.Parent:WaitForChild("RankCommands")).start()
