--!strict
-- Pure, deterministic target matching. Input objects only need Name,
-- DisplayName and UserId, so this can be tested outside Roblox Studio.
-- Precedence: exact @username > exact display name > prefix > substring.
-- An ambiguous DisplayName is NEVER silently assigned to the first user.
local Matcher={}

local function normalize(value: any): string
    if type(value)~="string" then return "" end
    local clean=value:match("^%s*(.-)%s*$") or ""
    -- @username is supported as an explicit username hint.
    if clean:sub(1,1)=="@" then clean=clean:sub(2) end
    if clean:sub(1,1)=='"' and clean:sub(-1)=='"' then
        clean=clean:sub(2,-2)
    end
    return string.lower(clean)
end

function Matcher.validQuery(value: any): boolean
    if type(value)~="string" or #value>100 or not utf8.len(value) then return false end
    local clean=normalize(value)
    if clean=="" or clean:find("[%c]") then return false end
    if clean=="all" or clean=="everyone" or clean=="모두" or clean=="전체" then
        return false
    end
    return true
end

function Matcher.find(players: {any}, query: any): {any}
    if not Matcher.validQuery(query) then return {} end
    local q=normalize(query)
    local exactUsername,exactDisplay,prefix,substring={},{},{},{}
    for _,player in players do
        local username=normalize(player.Name)
        local display=normalize(player.DisplayName)
        if username~="" and username==q then
            table.insert(exactUsername,player)
        elseif display~="" and display==q then
            table.insert(exactDisplay,player)
        elseif username:sub(1,#q)==q or display:sub(1,#q)==q then
            table.insert(prefix,player)
        elseif (username~="" and username:find(q,1,true))
            or (display~="" and display:find(q,1,true)) then
            table.insert(substring,player)
        end
    end

    local best=if #exactUsername>0 then exactUsername
        elseif #exactDisplay>0 then exactDisplay
        elseif #prefix>0 then prefix else substring
    table.sort(best,function(a,b)
        return a.UserId<b.UserId
    end)
    return best
end

return table.freeze(Matcher)
