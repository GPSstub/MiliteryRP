--!strict
-- Player action command parser. Accepts partial usernames AND DisplayNames,
-- including Unicode and spaces. The resolver validates real online players.
export type PlayerAction={kind: string,target: string}
local Parser={}
local aliases: {[string]: string}={
    [";to"]="to",[";here"]="here",[";kill"]="kill",
    [";폭발"]="explode",[";explode"]="explode",
}

function Parser.isVerb(verb: any): boolean
    return type(verb)=="string" and aliases[string.lower(verb)]~=nil
end

function Parser.parse(text: any): PlayerAction?
    if type(text)~="string" or #text>256 or not utf8.len(text) then return nil end
    local verb,target=text:match("^%s*(%S+)%s+(.-)%s*$")
    if not verb or not target then return nil end
    local kind=aliases[string.lower(verb)]
    if not kind then return nil end
    -- No arbitrary commands appended after the name. Spaces are allowed for
    -- real Roblox DisplayNames, including ones written in Hangul.
    target=target:match("^%s*(.-)%s*$") or ""
    if target:sub(1,1)=='"' and target:sub(-1)=='"' then
        target=target:sub(2,-2)
    end
    if #target==0 or #target>100 or not utf8.len(target)
        or target:find("[%c]") or target:find("[;]") then return nil end
    local lower=string.lower(target)
    if lower=="all" or lower=="everyone"
        or target=="모두" or target=="전체" then return nil end
    return {kind=kind,target=target}
end

return table.freeze(Parser)
