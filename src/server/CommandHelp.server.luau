--!strict
-- TextChatCommand consumes ;? / ;help without broadcasting a chat message.
-- Viewing help is harmless and available to all; executing admin commands is
-- still restricted to server-verified Roblox group rank >= 200.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TeamService = require(script.Parent:WaitForChild("TeamService"))

local event = Instance.new("RemoteEvent")
event.Name = "MilitaryCommandHelp"
event.Parent = ReplicatedStorage

local lastOpen: {[Player]: number} = {}
local command = Instance.new("TextChatCommand")
command.Name = "MilitaryCommandHelpCommand"
command.PrimaryAlias = ";?"
command.SecondaryAlias = ";help"
command.Enabled = true
command.AutocompleteVisible = true
command.Triggered:Connect(function(source: TextSource, raw: string)
    if not source or (raw ~= ";?" and string.lower(raw) ~= ";help") then return end
    local player = Players:GetPlayerByUserId(source.UserId)
    if not player or player.Parent ~= Players then return end
    local now = os.clock()
    if now - (lastOpen[player] or -math.huge) < 0.35 then return end
    lastOpen[player] = now
    event:FireClient(player, TeamService.isAdmin(player))
end)
command.Parent = TextChatService

Players.PlayerRemoving:Connect(function(player: Player)
    lastOpen[player] = nil
end)
