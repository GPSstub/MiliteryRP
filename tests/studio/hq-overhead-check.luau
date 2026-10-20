-- Run in Roblox Studio SERVER Command Bar while Play is active.
-- Read-only regression check for HQ overhead and normal rank nameplates.
-- To exercise transitions: use the HQ admin panel to move a player into
-- HQ and back to 위관급/영관급/장관급, then run this check again.
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local ServerScriptService=game:GetService("ServerScriptService")
local TeamService=require(ServerScriptService:WaitForChild("TeamService"))
local Catalog=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Branding=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("HQLogoConfig"))

local checks=0
local function check(ok: boolean,message: string)
    checks+=1
    assert(ok,message)
end

local hq=Teams:FindFirstChild("HQ")
check(hq and hq:IsA("Team"),"HQ team not registered")
for _,player in Players:GetPlayers() do
    local character=player.Character
    local head=if character then character:FindFirstChild("Head") else nil
    if not head then
        warn("[HQ OVERHEAD] Skip player without a spawned character:",player.Name)
        continue
    end
    local tag=head:FindFirstChild("RankTag")
    if not tag then tag=head:WaitForChild("RankTag",5) end
    check(tag and tag:IsA("BillboardGui"),player.Name.." is missing overhead GUI")
    local isHQ=TeamService.isAdmin(player)
    check(isHQ==(player.Team==hq and not player.Neutral),
        player.Name.." HQ membership is inconsistent")
    local rankId=player:GetAttribute("RankId")
    local storedRank=Catalog.find(rankId)
    check(storedRank~=nil,player.Name.." saved rank ID is invalid")
    local shown=if isHQ then "admin" else storedRank.name
    check(player:GetAttribute("Rank")==shown,
        player.Name.." Rank attribute should be "..shown)
    local displayId=if isHQ then "admin" else rankId
    check(player:GetAttribute("RankDisplayId")==displayId,
        player.Name.." RankDisplayId not synchronized")
    local leaderstats=player:FindFirstChild("leaderstats")
    local rankValue=if leaderstats then leaderstats:FindFirstChild("계급") else nil
    check(rankValue and rankValue:IsA("StringValue") and rankValue.Value==shown,
        player.Name.." leaderboard should display "..shown)
    check(player:GetAttribute("RankCategory")==storedRank.category
        and player:GetAttribute("RankOrder")==storedRank.order,
        player.Name.." HQ must not overwrite the persisted military rank")
    local expectedMode=if isHQ then "HQ" else "Rank"
    check(tag:GetAttribute("DisplayMode")==expectedMode,
        player.Name.." overhead mode is wrong")
    if isHQ then
        local label=tag:FindFirstChild("HQLabel")
        local image=tag:FindFirstChild("HQEmblem")
        check(label and label:IsA("TextLabel") and label.Text=="HQ",
            player.Name.." has no HQ label")
        check(image and image:IsA("Frame"),
            player.Name.." has no HQ emblem")
        check(image:FindFirstChild("TurtleCatFallback")~=nil,
            player.Name.." has no fallback emblem")
        if Branding.LogoAssetId>0 or Branding.LogoGameAssetName then
            check(image:FindFirstChild("HQLogo")~=nil,
                player.Name.." has no configured HQ image")
        end
        check(tag:FindFirstChild("Identity")==nil
            and tag:FindFirstChild("Rank")==nil
            and tag:FindFirstChild("Insignia")==nil,
            player.Name.." displays a military rank while in HQ")
    else
        check(tag:FindFirstChild("HQLabel")==nil,
            player.Name.." displays HQ after leaving HQ")
        check(tag:FindFirstChild("Identity")~=nil and tag:FindFirstChild("Rank")~=nil,
            player.Name.." has not restored regular rank overhead")
    end
    local count=0
    for _,child in head:GetChildren() do
        if child.Name=="RankTag" then count+=1 end
    end
    check(count==1,player.Name.." has duplicate overhead GUIs")
end
print("[HQ OVERHEAD] Passed "..checks.." assertions across "..#Players:GetPlayers().." players.")
