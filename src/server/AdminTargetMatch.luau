--!strict
-- Deterministic server-side target matcher for Roblox username & DisplayName.
-- 1) Unique exact name wins; 2) prefix; 3) substring.
-- Any tie in the best match tier MUST be resolved with the selection UI.
-- @username searches only real account usernames, not DisplayNames.
local Matcher={}

local function normalize(value: any): string
    if type(value)~="string" then return "" end
    local clean=value:match("^%s*(.-)%s*$") or ""
    if clean:sub(1,1)=='"' and clean:sub(-1)=='"' then
        clean=clean:sub(2,-2)
    end
    return string.lower(clean)
end

function Matcher.validQuery(value: any): boolean
    if type(value)~="string" or #value>100 or not utf8.len(value) then return false end
    local clean=normalize(value)
    if clean:sub(1,1)=="@" then clean=clean:sub(2) end
    if clean=="" or clean:find("[%c]") or clean:find("[;]") then return false end
    if clean=="all" or clean=="everyone" or clean=="모두" or clean=="전체" then
        return false
    end
    return true
end

function Matcher.find(players: {any}, query: any): {any}
    if not Matcher.validQuery(query) then return {} end
    local raw=normalize(query)
    local usernameOnly=raw:sub(1,1)=="@"
    local q=if usernameOnly then raw:sub(2) else raw
    local exact,prefix,substring={},{},{}
    for _,player in players do
        local username=normalize(player.Name)
        local display=if usernameOnly then "" else normalize(player.DisplayName)
        if username==q or (display~="" and display==q) then
            table.insert(exact,player)
        elseif username:sub(1,#q)==q or (display~="" and display:sub(1,#q)==q) then
            table.insert(prefix,player)
        elseif (username~="" and username:find(q,1,true))
            or (display~="" and display:find(q,1,true)) then
            table.insert(substring,player)
        end
    end
    local best=if #exact>0 then exact elseif #prefix>0 then prefix else substring
    table.sort(best,function(a,b)
        return a.UserId<b.UserId
    end)
    return best
end

return table.freeze(Matcher)
