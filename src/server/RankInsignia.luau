--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
type Rank = Catalog.Rank
local Insignia = {}
local ATLAS = "rbxassetid://97383962049559"
local COLUMNS, ROWS = 4, 5
function Insignia.render(tag: Instance, rank: Rank)
    local previous = tag:FindFirstChild("Insignia")
    if previous then previous:Destroy() end
    local plate = Instance.new("Frame")
    plate.Name = "Insignia"
    plate.AnchorPoint = Vector2.new(0.5, 0)
    plate.Position = UDim2.new(0.5, 0, 0, 24)
    plate.Size = UDim2.fromOffset(38, 38)
    plate.BackgroundTransparency = 1
    plate.BorderSizePixel = 0
    plate.ClipsDescendants = true
    plate:SetAttribute("RankId", rank.id)
    plate:SetAttribute("Symbol", rank.symbol)
    plate:SetAttribute("Marks", rank.marks)
    plate.Parent = tag
    if rank.symbol == "training" then return end
    local index = rank.order - 1
    local column, row = index % COLUMNS, math.floor(index / COLUMNS)
    -- Normalized clipping remains correct if Roblox resizes the uploaded texture.
    local image = Instance.new("ImageLabel")
    image.Name = "Atlas"
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.Image = ATLAS
    image.ScaleType = Enum.ScaleType.Stretch
    image.Size = UDim2.fromScale(COLUMNS, ROWS)
    image.Position = UDim2.fromScale(-column, -row)
    image.Parent = plate
end
return Insignia
