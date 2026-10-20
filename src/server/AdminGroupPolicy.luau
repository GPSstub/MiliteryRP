--!strict
-- One place to configure Roblox group-based administrator permissions.
-- HQ team assignment is a visual/organizational choice, NOT an admin grant.
local Policy={}
Policy.GROUP_ID=1101574390
Policy.MIN_ADMIN_RANK=200

function Policy.validRank(rank: any): boolean
    return type(rank)=="number" and rank>=0 and rank<=255
        and rank%1==0
end

function Policy.isAdminRank(rank: any): boolean
    return Policy.validRank(rank) and rank>=Policy.MIN_ADMIN_RANK
end

-- Roblox's group API can return multiple roles. Rank is used only as a
-- configurable threshold, never to infer that a user is in the HQ Team.
function Policy.rankFromRoles(result: any): number?
    if type(result)~="table" or type(result.IsMember)~="boolean"
        or type(result.Roles)~="table" then return nil end
    if not result.IsMember then return 0 end
    local maxRank=0
    for _,role in result.Roles do
        if type(role)=="table" and Policy.validRank(role.Rank) then
            maxRank=math.max(maxRank,role.Rank)
        end
    end
    return maxRank
end

return table.freeze(Policy)
