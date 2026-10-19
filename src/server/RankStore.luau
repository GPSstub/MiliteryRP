--!strict
-- Persistent military ranks. One key per Roblox UserId.
-- Studio uses a separate DataStore namespace from published live servers.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))

local RankStore = {}
local STORE_NAME = if RunService:IsStudio() then "MilitaryRP_Ranks_Dev_v1" else "MilitaryRP_Ranks_v1"
local store: GlobalDataStore? = nil
local initialized, initError = pcall(function()
    store = DataStoreService:GetDataStore(STORE_NAME)
end)
if not initialized then
    warn("[RankStore] Could not initialize DataStore:", initError)
end

local function keyFor(userId: number): string
    return "user_" .. tostring(userId)
end

local function valid(record: any): boolean
    return type(record) == "table"
        and record.schema == 1
        and Catalog.find(record.rankId) ~= nil
end

function RankStore.load(userId: number): (boolean, string?, string?)
    if not store then
        return false, nil, "계급 저장소에 연결할 수 없습니다."
    end

    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return store:GetAsync(keyFor(userId))
        end)
        if ok then
            if result == nil then
                return true, Catalog.DefaultId, nil
            end
            if valid(result) then
                return true, result.rankId, nil
            end
            warn("[RankStore] Invalid stored record for UserId", userId)
            return false, nil, "저장된 계급 데이터 형식이 올바르지 않습니다."
        end
        warn("[RankStore] Load failed for UserId", userId, "attempt", attempt, result)
        if attempt < 3 then
            task.wait(0.5 * 2 ^ (attempt - 1))
        end
    end
    return false, nil, "계급을 불러오지 못했습니다. Studio API 설정을 확인하세요."
end

function RankStore.save(userId: number, rankId: string): (boolean, string?)
    if not store then
        return false, "계급 저장소에 연결할 수 없습니다."
    end
    if not Catalog.find(rankId) then
        return false, "존재하지 않는 계급입니다."
    end

    -- UpdateAsync is atomic for the player's key. A command only succeeds after a
    -- confirmed write; no unsaved default is written on PlayerRemoving / BindToClose.
    local nextRecord = {
        schema = 1,
        rankId = rankId,
        updatedAt = os.time(),
    }
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return store:UpdateAsync(keyFor(userId), function(current)
                if current ~= nil and not valid(current) then
                    error("Invalid existing rank record")
                end
                return nextRecord
            end)
        end)
        if ok and valid(result) and result.rankId == rankId then
            return true, nil
        end
        warn("[RankStore] Save failed for UserId", userId, "attempt", attempt, result)
        if attempt < 3 then
            task.wait(0.5 * 2 ^ (attempt - 1))
        end
    end
    return false, "계급 영구 저장에 실패했습니다. 잠시 후 다시 시도하세요."
end

return RankStore
