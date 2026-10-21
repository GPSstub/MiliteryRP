--!strict
-- The Team roster and exact order are authoritative here.
-- Team membership never grants Roblox group-based administrative commands.
local Policy={}
Policy.HQ="HQ"
Policy.HEADQUARTERS="본부"
-- The ordering matches the requested hierarchy, top to bottom.
-- Each TeamColor is unique so Roblox's built-in Teams system can distinguish them.
Policy.SPECS={
    {name="HQ",color=1003},
    {name="본부",color=106},
    {name="장관급",color=21},
    {name="영관급",color=24},
    {name="위관급",color=23},
    {name="부사관급",color=105},
    {name="병사",color=28},
}

function Policy.teamForCategory(category: any): string?
    if category=="관리자" then return Policy.HQ end
    if category=="장관" then return "장관급" end
    if category=="영관" then return "영관급" end
    if category=="위관" or category=="준사관" then return "위관급" end
    if category=="부사관" then return "부사관급" end
    if category=="병" or category=="훈련병" then return "병사" end
    return nil
end

-- The "본부" team has no automatic rank assignment yet.
-- Administrators can place players there manually for the current session.
function Policy.isDefined(name: any): boolean
    if type(name)~="string" then return false end
    for _,spec in Policy.SPECS do
        if name==spec.name then return true end
    end
    return false
end
function Policy.isHQ(teamName: any,neutral: any): boolean
    return teamName==Policy.HQ and neutral==false
end
return table.freeze(Policy)
