--!strict
-- Run manually in Roblox Studio command bar while the server is playing.
-- Confirms that Rojo synced the rifle system and the server granted one Tool.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
assert(ReplicatedStorage:FindFirstChild("TrainingRifleAction"),"Missing TrainingRifleAction remote")
local shared=ReplicatedStorage:FindFirstChild("Shared")
assert(shared and shared:FindFirstChild("TrainingRifleRules"),"Missing TrainingRifleRules")
for _,player in Players:GetPlayers() do
    local backpack=player:FindFirstChildOfClass("Backpack")
    local character=player.Character
    local tool=if backpack then backpack:FindFirstChild("훈련용 소총") else nil
    if not tool and character then tool=character:FindFirstChild("훈련용 소총") end
    if not tool then
        warn("Player missing TrainingRifle Tool",player.Name)
        continue
    end
    assert(tool:IsA("Tool"))
    assert(tool:GetAttribute("WeaponId")=="TrainingRifle")
    local handle=tool:FindFirstChild("Handle")
    assert(handle and handle:IsA("BasePart"))
    for _,name in {"Muzzle","FireSound","ReloadSound","MagazineJoint","BoltJoint"} do
        local found=handle:FindFirstChild(name)
        assert(found,"Missing rifle component: "..name)
    end
    assert(tool:GetAttribute("Ammo")~=nil and tool:GetAttribute("Reserve")~=nil)
    print("Rifle ready:",player.Name,tool:GetAttribute("Ammo"),"/",tool:GetAttribute("Reserve"))
end
