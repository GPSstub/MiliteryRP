--!strict
-- 메신저 역할 및 권한 관리 (서버 전용)

local Players = game:GetService("Players")

local Permissions = {}

-- 기존 MilitaryRP 제작자 UserId
local OWNER_ID = 1153125948

-- 사용 가능한 권한
local VALID_PERMISSIONS = {
    SEND_MESSAGES = true,
    CREATE_CHANNELS = true,
    DELETE_CHANNELS = true,
    MANAGE_ROLES = true,
    MANAGE_SETTINGS = true,
    POST_NOTICES = true,
    VIEW_COMMAND = true,
    WRITE_COMMAND = true,
}

-- 기본 역할
local roles = {
    member = {
        SEND_MESSAGES = true,
    },

    officer = {
        SEND_MESSAGES = true,
        POST_NOTICES = true,
        VIEW_COMMAND = true,
        WRITE_COMMAND = true,
    },

    operator = {
        SEND_MESSAGES = true,
        CREATE_CHANNELS = true,
        DELETE_CHANNELS = true,
        MANAGE_ROLES = true,
        MANAGE_SETTINGS = true,
    },

    muted = {},
}

local protectedRoles = {
    member = true,
    officer = true,
    operator = true,
    muted = true,
}

-- 사용자별 추가 역할
-- 예: assigned[12345] = { operator = true }
local assigned = {}

local changed = Instance.new("BindableEvent")
Permissions.Changed = changed.Event

local function getAssigned(userId)
    if not assigned[userId] then
        assigned[userId] = {}
    end

    return assigned[userId]
end

function Permissions.has(player, permission)
    if not player or player.Parent ~= Players then
        return false
    end

    if not VALID_PERMISSIONS[permission] then
        return false
    end

    -- 소유자는 모든 권한
    if player.UserId == OWNER_ID then
        return true
    end

    local userRoles = assigned[player.UserId] or {}

    -- 채팅 금지 역할은 다른 역할보다 우선
    if userRoles.muted and (
        permission == "SEND_MESSAGES"
        or permission == "POST_NOTICES"
        or permission == "WRITE_COMMAND"
    ) then
        return false
    end

    -- 일반 병사 권한
    if roles.member[permission] then
        return true
    end

    -- 소위 이상은 장교 역할 자동 부여
    local rankOrder = tonumber(
        player:GetAttribute("RankOrder")
    ) or 0

    if rankOrder >= 11 and roles.officer[permission] then
        return true
    end

    -- 추가로 부여된 역할 확인
    for roleId in userRoles do
        local role = roles[roleId]

        if role and role[permission] then
            return true
        end
    end

    return false
end

-- 역할에 포함된 권한을 부여자가 가지고 있는지 확인
local function canGrant(actor, roleId)
    local role = roles[roleId]

    if not role then
        return false
    end

    for permission, enabled in role do
        if enabled and not Permissions.has(actor, permission) then
            return false
        end
    end

    return true
end

-- 새로운 역할 만들기
function Permissions.createRole(actor, roleId, rolePermissions)
    if not Permissions.has(actor, "MANAGE_ROLES") then
        return false, "역할 관리 권한이 없습니다."
    end

    if type(roleId) ~= "string"
        or #roleId < 3
        or #roleId > 24
        or not roleId:match("^[a-z][a-z0-9_]*$")
        or roles[roleId] then
        return false, "사용할 수 없는 역할 ID입니다."
    end

    if type(rolePermissions) ~= "table" then
        return false, "권한 정보가 잘못되었습니다."
    end

    local count = 0
    for _ in roles do
        count += 1
    end

    if count >= 30 then
        return false, "역할은 최대 30개입니다."
    end

    local clean = {}

    for permission, enabled in rolePermissions do
        if not VALID_PERMISSIONS[permission]
            or type(enabled) ~= "boolean" then
            return false, "잘못된 권한입니다."
        end

        if enabled then
            if not Permissions.has(actor, permission) then
                return false, "보유하지 않은 권한은 부여할 수 없습니다."
            end

            clean[permission] = true
        end
    end

    roles[roleId] = clean
    changed:Fire(nil)

    return true, "역할 생성 완료"
end

-- 역할 권한 변경
function Permissions.setRolePermission(actor, roleId, permission, enabled)
    if not Permissions.has(actor, "MANAGE_ROLES") then
        return false, "역할 관리 권한이 없습니다."
    end

    if protectedRoles[roleId] or not roles[roleId] then
        return false, "수정할 수 없는 역할입니다."
    end

    if not VALID_PERMISSIONS[permission] or type(enabled) ~= "boolean" then
        return false, "잘못된 권한입니다."
    end

    if enabled and not Permissions.has(actor, permission) then
        return false, "보유하지 않은 권한은 부여할 수 없습니다."
    end

    roles[roleId][permission] = enabled or nil
    changed:Fire(nil)

    return true, "권한 변경 완료"
end

-- 플레이어에게 추가 역할 부여
function Permissions.assignRole(actor, target, roleId)
    if not Permissions.has(actor, "MANAGE_ROLES") then
        return false, "역할 관리 권한이 없습니다."
    end

    if not target or target.Parent ~= Players then
        return false, "대상 플레이어가 없습니다."
    end

    if roleId == "member"
        or roleId == "officer"
        or not roles[roleId] then
        return false, "수동 부여할 수 없는 역할입니다."
    end

    if not canGrant(actor, roleId) then
        return false, "부여할 권한이 부족합니다."
    end

    local userRoles = getAssigned(target.UserId)
    userRoles[roleId] = true

    changed:Fire(target)

    return true, "역할 부여 완료"
end

-- 플레이어의 추가 역할 제거
function Permissions.removeRole(actor, target, roleId)
    if not Permissions.has(actor, "MANAGE_ROLES") then
        return false, "역할 관리 권한이 없습니다."
    end

    if not target or target.Parent ~= Players then
        return false, "대상 플레이어가 없습니다."
    end

    if not roles[roleId] or not canGrant(actor, roleId) then
        return false, "해당 역할을 제거할 권한이 없습니다."
    end

    local userRoles = getAssigned(target.UserId)
    userRoles[roleId] = nil

    changed:Fire(target)

    return true, "역할 제거 완료"
end

-- 클라이언트 화면에 필요한 권한 정보 동기화
-- 실제 권한 검사는 반드시 Permissions.has()로 서버에서 수행
function Permissions.publish(player)
    local attributes = {
        MessengerCanSend = "SEND_MESSAGES",
        MessengerCanCreate = "CREATE_CHANNELS",
        MessengerCanDelete = "DELETE_CHANNELS",
        MessengerCanManageRoles = "MANAGE_ROLES",
        MessengerCanManageSettings = "MANAGE_SETTINGS",
        MessengerCanPostNotices = "POST_NOTICES",
        MessengerCanViewCommand = "VIEW_COMMAND",
        MessengerCanWriteCommand = "WRITE_COMMAND",
    }

    for attribute, permission in attributes do
        player:SetAttribute(attribute, Permissions.has(player, permission))
    end
end

Players.PlayerRemoving:Connect(function(player)
    assigned[player.UserId] = nil
end)


-- Read-only snapshot for the management UI.
function Permissions.snapshot()
    local roleCopy = {}
    for roleId, grants in roles do
        roleCopy[roleId] = table.clone(grants)
    end
    local people = {}
    for _, player in Players:GetPlayers() do
        local active = {}
        for roleId in (assigned[player.UserId] or {}) do
            if roles[roleId] then table.insert(active, roleId) end
        end
        table.sort(active)
        people[#people + 1] = {
            userId = player.UserId, name = player.Name,
            displayName = player.DisplayName, roles = active,
        }
    end
    return { roles = roleCopy, people = people, ownerId = OWNER_ID }
end

function Permissions.deleteRole(actor, roleId)
    if not Permissions.has(actor, "MANAGE_ROLES") then
        return false, "역할 관리 권한이 없습니다."
    end
    if type(roleId) ~= "string" or protectedRoles[roleId] or not roles[roleId] then
        return false, "삭제할 수 없는 역할입니다."
    end
    if not canGrant(actor, roleId) then
        return false, "이 역할을 관리할 권한이 부족합니다."
    end
    roles[roleId] = nil
    for _, grants in assigned do
        grants[roleId] = nil
    end
    changed:Fire(nil)
    return true, "역할 삭제 완료"
end

return Permissions
