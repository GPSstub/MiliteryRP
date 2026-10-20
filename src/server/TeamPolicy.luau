--!strict
-- Pure team membership policy. HQ is a deliberate administration assignment,
-- never earned automatically through a military rank.
local Policy={}
Policy.HQ="HQ"
Policy.OWNER_USER_ID=1153125948

Policy.SPECS={
    {name="HQ",color=1003},
    {name="위관급",color=23},
    {name="영관급",color=24},
    {name="장관급",color=21},
}

function Policy.teamForCategory(category: any): string?
    if category=="위관" then return "위관급" end
    if category=="영관" then return "영관급" end
    if category=="장관" then return "장관급" end
    return nil
end

function Policy.isDefined(name: any): boolean
    if type(name)~="string" then return false end
    for _,spec in Policy.SPECS do
        if name==spec.name then return true end
    end
    return false
end

function Policy.isAdmin(teamName: any,neutral: any): boolean
    return teamName==Policy.HQ and neutral==false
end

return table.freeze(Policy)
