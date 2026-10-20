--!strict
export type Command = {kind: string, target: string?, rank: string?}
local Parser={}
function Parser.parse(message: any): Command?
    if type(message) ~= "string" or #message > 256 then return nil end
    local words: {string}={}
    for word in string.gmatch(message,"%S+") do
        table.insert(words,word)
        if #words > 3 then return nil end
    end
    local alias=string.lower(words[1] or "")
    if alias==";계급목록" or alias==";ranks" then
        return if #words==1 then {kind="list"} else nil
    end
    if alias~=";계급" and alias~=";rank" then return nil end
    if #words==2 then return {kind="set",rank=words[2]} end
    if #words==3 then return {kind="set",target=words[2],rank=words[3]} end
    return nil
end
return table.freeze(Parser)
