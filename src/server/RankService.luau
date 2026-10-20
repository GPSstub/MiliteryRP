--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Insignia=require(script.Parent:WaitForChild("RankInsignia"))
local HQBadge=require(script.Parent:WaitForChild("HQOverheadBadge"))
local TeamService=require(script.Parent:WaitForChild("TeamService"))
local RankStore=require(script.Parent:WaitForChild("RankStore"))
type Rank = Catalog.Rank
local RankService = {}
local states: {[Player]: string} = {}
local connections: {[Player]: {RBXScriptConnection}} = {}
local saving: {[Player]: boolean} = {}
-- A successful write takes precedence over a GetAsync started before that write.
local localChanges: {[Player]: number} = {}
local redrawQueued: {[Player]: boolean} = {}
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
    if TeamService.isAdmin(player) then
        -- HQ is a team appointment, not a rank. Show only the unit emblem and
        -- "HQ" rather than nickname, military rank name, and rank insignia.
        HQBadge.render(tag)
        return
    end
    tag:SetAttribute("DisplayMode","Rank")
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
local function queueRedraw(player: Player)
    if redrawQueued[player] then return end
    redrawQueued[player]=true
    -- Team and Neutral often change during the same assignment. Coalesce
    -- those signals so the tag reflects the final effective membership.
    task.defer(function()
        redrawQueued[player]=nil
        if player.Parent==Players and states[player] then
            local character=player.Character
            if character then task.spawn(renderCharacter,player,character) end
        end
    end)
end
local function publish(player: Player, rank: Rank)
    player:SetAttribute("RankId",rank.id)
    player:SetAttribute("Rank",rank.name)
    player:SetAttribute("RankCategory",rank.category)
    player:SetAttribute("RankOrder",rank.order)
    local stats=player:FindFirstChild("leaderstats")
    local value=if stats then stats:FindFirstChild("계급") else nil
    if value and value:IsA("StringValue") then value.Value=rank.name end
    -- Never update rank widgets inside an HQ tag. Rebuild the overhead with
    -- the correct HQ/rank branch after the server's rank attributes settle.
    if connections[player] then queueRedraw(player) end
end
-- Server-only assignment API. A command succeeds only after UpdateAsync confirms
-- the new rank is persisted. We never save a default rank during player departure.
function RankService.set(player: Player, rankId: any): (boolean, string?)
    local rank=Catalog.find(rankId)
    if player.Parent ~= Players or not rank then
        return false, "플레이어가 나갔거나 계급이 올바르지 않습니다."
    end
    if not states[player] then RankService.add(player) end
    if not states[player] then return false, "계급 초기화에 실패했습니다." end
    if saving[player] then return false, "이 플레이어의 계급 저장이 진행 중입니다." end

    saving[player]=true
    player:SetAttribute("RankStorageStatus","Saving")
    local success,reason=RankStore.save(player.UserId,rank.id)
    saving[player]=nil
    if not success then
        if player.Parent==Players then player:SetAttribute("RankStorageStatus","Error") end
        return false,reason or "계급 영구 저장에 실패했습니다."
    end

    if player.Parent==Players and states[player] then
        localChanges[player]=(localChanges[player] or 0)+1
        states[player]=rank.id
        publish(player,rank)
        player:SetAttribute("RankStorageStatus","Ready")
    end
    return true,nil
end
function RankService.get(player: Player): Rank?
    local id=states[player]
    return if id then Catalog.find(id) else nil
end
function RankService.add(player: Player)
    if player.Parent~=Players or states[player] then return end
    states[player]=Catalog.DefaultId
    localChanges[player]=0
    player:SetAttribute("RankStorageStatus","Loading")
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
        player:GetPropertyChangedSignal("Team"):Connect(function()
            queueRedraw(player)
        end),
        player:GetPropertyChangedSignal("Neutral"):Connect(function()
            queueRedraw(player)
        end),
    }
    if player.Character then task.spawn(renderCharacter,player,player.Character) end

    -- Load asynchronously so a temporary DataStore outage never blocks character
    -- creation, rank commands registration, or the rest of the server.
    task.spawn(function()
        local startVersion=localChanges[player] or 0
        local loaded,rankId,reason=RankStore.load(player.UserId)
        if player.Parent~=Players or not states[player] or localChanges[player]~=startVersion then return end
        if not loaded then
            warn("[RankService] Rank loading failed:",player.UserId,reason)
            player:SetAttribute("RankStorageStatus","Error")
            return
        end
        local restored=Catalog.find(rankId)
        if not restored then
            player:SetAttribute("RankStorageStatus","Error")
            return
        end
        states[player]=restored.id
        publish(player,restored)
        player:SetAttribute("RankStorageStatus","Ready")
    end)
end
function RankService.remove(player: Player)
    local playerConnections=connections[player]
    if playerConnections then
        for _,connection in playerConnections do connection:Disconnect() end
        connections[player]=nil
    end
    states[player]=nil
    localChanges[player]=nil
    saving[player]=nil
    redrawQueued[player]=nil
end
return RankService
