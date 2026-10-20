--!strict
local Players=game:GetService("Players")
local TeamService=require(script.Parent:WaitForChild("TeamService"))
local RankService=require(script.Parent:WaitForChild("RankService"))

-- Ensure the four teams are available before rank loading and command registration.
-- Non-HQ teams track RankCategory; HQ is an explicit admin appointment.
TeamService.start()
Players.PlayerAdded:Connect(RankService.add)
Players.PlayerRemoving:Connect(RankService.remove)
for _,player in Players:GetPlayers() do RankService.add(player) end

require(script.Parent:WaitForChild("RankCommands")).start()
