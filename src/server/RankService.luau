--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Insignia=require(script.Parent:WaitForChild("RankInsignia"))
local hqModule=script.Parent:WaitForChild("HQOverheadBadge",5)
-- A missing/broken decorative badge should never prevent all ranks from loading.
local hqLoaded,hqBadgeValue=false,nil
if hqModule then
    hqLoaded,hqBadgeValue=pcall(require,hqModule)
end
if not hqLoaded then warn("[RankService] HQ badge module unavailable:",hqBadgeValue) end
local HQBadge: any=if hqLoaded then hqBadgeValue else nil
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
local renderVersion: {[Player]: number} = {}
local function renderCharacter(player: Player, character: Model, version: number)
    local head=character:WaitForChild("Head",10)
    -- WaitForChild can yield; stale spawn/appearance requests must not build
    -- competing BillboardGuis after a team change or respawn.
    if player.Parent~=Players or player.Character~=character or not states[player]
        or renderVersion[player]~=version or not head or not head:IsA("BasePart") then return end
    local previous=head:FindFirstChild("RankTag")
    if previous then previous:Destroy() end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
    local tag=Instance.new("BillboardGui")
    tag.Name="RankTag"; tag.Adornee=head;tag.Enabled=true
    tag.Size=UDim2.fromOffset(180,88)
    tag.StudsOffsetWorldSpace=Vector3.new(0,2.7,0);tag.MaxDistance=100
    tag.AlwaysOnTop=true;tag.LightInfluence=0
    if TeamService.isHQ(player) then
        -- HQ is a team presentation, never an override of the saved rank. Build
        -- before parenting so an incomplete nameplate is never replicated.
        local success,errorMessage=pcall(function()
            if not HQBadge then error("HQ badge renderer not available") end
            HQBadge.render(tag)
        end)
        if not success then
            warn("[RankService] HQ badge render failed:",player.UserId,errorMessage)
            tag:ClearAllChildren()
            tag:SetAttribute("DisplayMode","HQ")
            tag.Size=UDim2.fromOffset(160,74)
            local emergency=Instance.new("TextLabel")
            emergency.Name="HQLabel";emergency.Text="HQ"
            emergency.Font=Enum.Font.GothamBold;emergency.TextSize=28
            emergency.TextColor3=Color3.fromRGB(255,220,125)
            emergency.TextStrokeTransparency=0.1
            emergency.BackgroundTransparency=1
            emergency.Size=UDim2.fromScale(1,1)
            emergency.Parent=tag
        end
        -- Keep the HQ emblem, but still show the actual persisted rank:
        -- manually placing an ordinary soldier in HQ must not make them admin.
        local actual=Catalog.find(states[player])
        local badgeHeight=tag.Size.Y.Offset
        tag.Size=UDim2.fromOffset(tag.Size.X.Offset,badgeHeight+21)
        local actualLabel=Instance.new("TextLabel")
        actualLabel.Name="ActualRank"
        actualLabel.Text=if actual then actual.name else "계급 확인 중"
        actualLabel.TextColor3=if actual
            then Color3.fromRGB(actual.color[1],actual.color[2],actual.color[3])
            else Color3.fromRGB(220,220,220)
        actualLabel.TextStrokeTransparency=0.25
        actualLabel.TextSize=14
        actualLabel.Font=Enum.Font.GothamBold
        actualLabel.BackgroundTransparency=1
        actualLabel.Position=UDim2.fromOffset(0,badgeHeight-3)
        actualLabel.Size=UDim2.new(1,0,0,20)
        actualLabel.Parent=tag
        tag.Parent=head
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
    tag.Parent=head
end
local function requestRender(player: Player, character: Model)
    if player.Parent~=Players or not states[player] then return end
    local version=(renderVersion[player] or 0)+1
    renderVersion[player]=version
    task.spawn(renderCharacter,player,character,version)
end
local function updateVisibleRank(player: Player)
    local id=states[player]
    local stored=if id then Catalog.find(id) else nil
    if not stored then return end
    -- Rank, RankDisplayId and leaderstats always show the saved rank.
    -- Being transferred into HQ is *not* a rank promotion.
    local display=stored.name
    player:SetAttribute("Rank",display)
    player:SetAttribute("RankDisplayId",stored.id)
    local stats=player:FindFirstChild("leaderstats")
    local label=if stats then stats:FindFirstChild("계급") else nil
    if label and label:IsA("StringValue") then
        label.Value=display
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
            updateVisibleRank(player)
            local character=player.Character
            if character then requestRender(player,character) end
        end
    end)
end
local function publish(player: Player, rank: Rank)
    player:SetAttribute("RankId",rank.id)
    player:SetAttribute("RankCategory",rank.category)
    player:SetAttribute("RankOrder",rank.order)
    updateVisibleRank(player)
    -- Rebuild the nameplate after both saved-rank and team attributes settle.
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
            requestRender(player,character)
        end),
        player.CharacterAppearanceLoaded:Connect(function(character: Model)
            -- The avatar loader may replace its Head/attachments. It must
            -- redraw with a fresh render version (previously this omitted the
            -- required version argument and every appearance redraw aborted).
            requestRender(player,character)
        end),
        player:GetPropertyChangedSignal("Team"):Connect(function()
            queueRedraw(player)
        end),
        player:GetPropertyChangedSignal("Neutral"):Connect(function()
            queueRedraw(player)
        end),
    }
    if player.Character then requestRender(player,player.Character) end

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
    renderVersion[player]=nil
end
return RankService
