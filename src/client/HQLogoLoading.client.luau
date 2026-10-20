--!strict
-- ImageLabel.IsLoaded is client-only. Hide the placeholder on THIS client
-- when the approved HQ image actually becomes visible. Do not do this on the
-- server: IsLoaded does not replicate to server-side BillboardGui instances.
local Workspace=game:GetService("Workspace")
local Players=game:GetService("Players")
local bound: {[ImageLabel]: boolean}={}

local function bindIfHQ(image: Instance)
    if not image:IsA("ImageLabel") or image.Name~="HQLogo" or bound[image] then return end
    local root=image.Parent
    if not root or root.Name~="HQEmblem" then return end
    bound[image]=true
    task.spawn(function()
        local fallback=root:FindFirstChild("TurtleCatFallback")
            or root:WaitForChild("TurtleCatFallback",4)
        if not fallback or not fallback:IsA("GuiObject") then
            bound[image]=nil
            return
        end
        local function apply()
            if fallback.Parent and image.Parent then
                fallback.Visible=not image.IsLoaded
            end
        end
        local conn=image:GetPropertyChangedSignal("IsLoaded"):Connect(apply)
        apply()
        image.Destroying:Once(function()
            conn:Disconnect()
            bound[image]=nil
        end)
    end)
end

Workspace.DescendantAdded:Connect(bindIfHQ)
-- The LocalScript might start after characters were replicated (Play Solo,
-- Studio hot reload); inspect already present avatars as well.
for _,player in Players:GetPlayers() do
    local character=player.Character
    if character then
        for _,descendant in character:GetDescendants() do
            bindIfHQ(descendant)
        end
    end
end
