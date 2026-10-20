--!strict
-- Pure parser for HQ player manipulation commands.
-- Target must be an exact Roblox username or the self aliases "나"/"me".
-- This module never authorizes actions: AdminService checks HQ on the server.
export type PlayerAction = {kind: string, target: string}
local Parser={}
local aliases: {[string]: string}={
    [";to"]="to",
    [";here"]="here",
    [";kill"]="kill",
    [";폭발"]="explode",
    [";explode"]="explode",
}

function Parser.isVerb(verb: any): boolean
    return type(verb)=="string" and aliases[string.lower(verb)]~=nil
end

function Parser.parse(text: any): PlayerAction?
    if type(text)~="string" or #text>256 or not utf8.len(text) then return nil end
    local verb,target=text:match("^%s*(%S+)%s+(%S+)%s*$")
    if not verb or not target then return nil end
    local kind=aliases[string.lower(verb)]
    if not kind then return nil end
    if target=="나" or string.lower(target)=="me" then
        return {kind=kind,target=target}
    end
    if #target<3 or #target>20 or not target:match("^[%w_]+$") then
        return nil
    end
    return {kind=kind,target=target}
end

return table.freeze(Parser)
