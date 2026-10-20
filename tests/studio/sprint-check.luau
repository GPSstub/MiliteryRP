-- Run in Roblox Studio SERVER Command Bar while the game is running.
-- Does not modify speed or grant privileges. Inspect while walking,
-- while holding Shift, while seated, and while using HQ flight.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.SprintConfig)
local Rules=require(ReplicatedStorage.Shared.SprintRules)
local remote=ReplicatedStorage:FindFirstChild("SprintRequest")
assert(remote and remote:IsA("RemoteEvent"),"SprintRequest was not registered by Main.server.luau")

local checks=1
for _,player in Players:GetPlayers() do
    local character=player.Character
    local humanoid=if character then character:FindFirstChildOfClass("Humanoid") else nil
    if humanoid and humanoid.Health>0 then
        local running=player:GetAttribute("IsSprinting")==true
        local correct=Rules.allowed(
            running,
            humanoid.Health>0,
            humanoid.SeatPart~=nil or humanoid.Sit,
            player:GetAttribute("AdminFlying")==true,
            humanoid.PlatformStand
        )
        assert(running==correct,player.Name.." has forbidden IsSprinting=true")
        local expected=if running then Config.SprintSpeed else Config.WalkSpeed
        assert(humanoid.WalkSpeed==expected,
            player.Name.." WalkSpeed expected "..expected..
                ", got "..humanoid.WalkSpeed)
        print("[Sprint] "..player.Name.." / "..(if running then "RUN" else "WALK")..
            " / speed "..humanoid.WalkSpeed)
        checks+=2
    end
end
print("[Sprint] PASS: "..checks.." assertions")
