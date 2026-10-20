--!strict
-- Supports ;계급 나 대위, ;계급 일부 대위, and DisplayNames with spaces.
export type Command={kind: string,target: string?,rank: string?}
local Parser={}

function Parser.parse(message: any): Command?
    if type(message)~="string" or #message>256 or not utf8.len(message) then return nil end
    local verb,arguments=message:match("^%s*(%S+)%s*(.-)%s*$")
    if not verb then return nil end
    local alias=string.lower(verb)
    if alias==";계급목록" or alias==";ranks" then
        return if arguments=="" then {kind="list"} else nil
    end
    if alias~=";계급" and alias~=";rank" then return nil end
    if arguments=="" or arguments:find("[%c]") then return nil end
    -- The last word is a rank name or ID. Everything before it can be an
    -- arbitrary Unicode DisplayName, optionally containing spaces.
    local target,rank=arguments:match("^(.-)%s+(%S+)$")
    if not rank then
        rank=arguments
        target=nil
    else
        target=target:match("^%s*(.-)%s*$") or ""
        if target=="" or #target>100 then return nil end
        if target:sub(1,1)=='"' and target:sub(-1)=='"' then
            target=target:sub(2,-2)
        end
        if target=="" then return nil end
    end
    if #rank>60 or rank:find("[;]") then return nil end
    return {kind="set",target=target,rank=rank}
end
return table.freeze(Parser)
