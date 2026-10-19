--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TextChatService=game:GetService("TextChatService")
local feedback=ReplicatedStorage:WaitForChild("RankCommandFeedback") :: RemoteEvent
feedback.OnClientEvent:Connect(function(message: any)
    if type(message)~="string" or #message>2048 then return end
    local channels=TextChatService:WaitForChild("TextChannels",5)
    local channel=if channels then channels:FindFirstChild("RBXGeneral") else nil
    if channel and channel:IsA("TextChannel") then
        channel:DisplaySystemMessage("[계급] "..message)
    end
end)

-- Subtle local shimmer; each animation ends when its rank image is replaced.
local TweenService = game:GetService("TweenService")
local function shimmer(instance: Instance)
    if not instance:IsA("ImageLabel") or instance.Name ~= "Atlas" then return end
    local plate = instance.Parent
    if not plate or plate.Name ~= "Insignia" or not plate.Parent or plate.Parent.Name ~= "RankTag" then return end
    instance.ImageColor3 = Color3.fromRGB(205, 209, 216)
    local tween = TweenService:Create(instance, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0.6), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
    instance.Destroying:Once(function() tween:Cancel() end)
    tween:Play()
end
workspace.DescendantAdded:Connect(shimmer)
for _, instance in workspace:GetDescendants() do shimmer(instance) end
