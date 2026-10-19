--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Insignia=require(script.Parent:WaitForChild("RankInsignia"))
type Rank = Catalog.Rank
local RankService = {}
local states: {[Player]: string} = {}
local connections: {[Player]: {RBXScriptConnection}} = {}
local function renderCharacter(player: Player, character: Model)
    local head=character:WaitForChild("Head",10)
    if player.Character ~= character or not states[player] or not head or not head:IsA("BasePart") then return end
    local previous=head:FindFirstChild("RankTag")
    if previous then previous:Destroy() end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
    local tag=Instance.new("BillboardGui")
    tag.Name="RankTag"; tag.Adornee=head; tag.Size=UDim2.fromOffset(180,88)
    tag.StudsOffsetWorldSpace=Vector3.new(0,2.7,0); tag.MaxDistance=100; tag.AlwaysOnTop=true
    tag.Parent=head
    local identity=Instance.new("TextLabel")
    identity.Name="Identity"; identity.Size=UDim2.new(1,0,0,26); identity.Position=UDim2.fromOffset(0,0)
    identity.BackgroundTransparency=1; identity.TextColor3=Color3.fromRGB(244,245,240)
    identity.TextStrokeTransparency=0.35; identity.Font=Enum.Font.GothamMedium; identity.TextSize=16
    identity.Text=player.DisplayName; identity.Parent=tag
    local rankLabel=Instance.new("TextLabel")
    rankLabel.Name="Rank"; rankLabel.Size=UDim2.new(1,0,0,28); rankLabel.Position=UDim2.fromOffset(0,62)
    rankLabel.BackgroundTransparency=1; rankLabel.TextStrokeTransparency=0.3
    rankLabel.Font=Enum.Font.GothamBold; rankLabel.TextSize=17; rankLabel.Parent=tag
    local rank=Catalog.find(states[player])
    if rank then
        rankLabel.Text=rank.name
        rankLabel.TextColor3=Color3.fromRGB(rank.color[1],rank.color[2],rank.color[3])
        Insignia.render(tag,rank)
    end
end
local function publish(player: Player, rank: Rank)
    player:SetAttribute("RankId",rank.id)
    player:SetAttribute("Rank",rank.name)
    player:SetAttribute("RankCategory",rank.category)
    player:SetAttribute("RankOrder",rank.order)
    local stats=player:FindFirstChild("leaderstats")
    local value=if stats then stats:FindFirstChild("계급") else nil
    if value and value:IsA("StringValue") then value.Value=rank.name end
    local character=player.Character
    if character then
        local head=character:FindFirstChild("Head")
        local tag=if head then head:FindFirstChild("RankTag") else nil
        local label=if tag then tag:FindFirstChild("Rank") else nil
        if label and label:IsA("TextLabel") then
            label.Text=rank.name
            label.TextColor3=Color3.fromRGB(rank.color[1],rank.color[2],rank.color[3])
            Insignia.render(tag,rank)
        end
    end
end
-- Server-only assignment API for later gameplay systems; no permission or promotion policy yet.
-- Rank commands call this API on the server; clients cannot assign ranks directly.
function RankService.set(player: Player, rankId: any): boolean
    local rank=Catalog.find(rankId)
    if player.Parent ~= Players or not rank then return false end
    -- Recover if the player joined before the rank initializer completed.
    if not states[player] then RankService.add(player) end
    if not states[player] then return false end
    states[player]=rank.id
    publish(player,rank)
    if player.Character then task.spawn(renderCharacter,player,player.Character) end
    return true
end
function RankService.get(player: Player): Rank?
    local id=states[player]
    return if id then Catalog.find(id) else nil
end
function RankService.add(player: Player)
    if states[player] then return end
    states[player]=Catalog.DefaultId
    local stats=player:FindFirstChild("leaderstats")
    if not stats then stats=Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=player end
    local value=stats:FindFirstChild("계급")
    if not value then value=Instance.new("StringValue"); value.Name="계급"; value.Parent=stats end
    local rank=Catalog.find(Catalog.DefaultId)
    assert(rank,"Default rank must exist")
    publish(player,rank)
    connections[player]={
        player.CharacterAdded:Connect(function(character: Model)
            task.spawn(renderCharacter,player,character)
        end),
        player.CharacterAppearanceLoaded:Connect(function(character: Model)
            task.spawn(renderCharacter,player,character)
        end),
    }
    if player.Character then task.spawn(renderCharacter,player,player.Character) end
end
function RankService.remove(player: Player)
    local playerConnections=connections[player]
    if playerConnections then
        for _,connection in playerConnections do connection:Disconnect() end
        connections[player]=nil
    end
    states[player]=nil
end
return RankService
