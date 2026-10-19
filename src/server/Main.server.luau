--!strict
local Players=game:GetService("Players")
local RankService=require(script.Parent:WaitForChild("RankService"))
-- Rank metadata is independent of Roblox Teams; no units or team selection yet.
Players.PlayerAdded:Connect(RankService.add)
Players.PlayerRemoving:Connect(RankService.remove)
for _,player in Players:GetPlayers() do RankService.add(player) end

require(script.Parent:WaitForChild("RankCommands")).start()
