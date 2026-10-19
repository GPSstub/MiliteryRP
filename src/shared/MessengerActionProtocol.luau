--!strict
-- Tiny, pure protocol for TextChannel:SendAsync metadata.
-- Text never enters this protocol; Roblox filters message bodies separately.
local Protocol={}
local MAX_ID=90
function Protocol.validId(id: any): boolean
    return type(id)=="string" and #id>=8 and #id<=MAX_ID
        and id:match("^[%w_%-]+$")~=nil
end
function Protocol.encode(kind: string, id: string, reference: string?): string?
    if not Protocol.validId(id) then return nil end
    if kind=="m" and reference==nil then
        return "mrp1|m|"..id
    end
    if (kind=="e" or kind=="r" or kind=="t") and Protocol.validId(reference) then
        return "mrp1|"..kind.."|"..reference.."|"..id
    end
    return nil
end
function Protocol.decode(metadata: any): any?
    if type(metadata)~="string" or #metadata>200 then return nil end
    local id=metadata:match("^mrp1|m|([^|]+)$")
    if Protocol.validId(id) then return {kind="m",id=id} end
    local kind,reference,nextId=metadata:match("^mrp1|([ert])|([^|]+)|([^|]+)$")
    if kind and Protocol.validId(reference) and Protocol.validId(nextId) then
        return {kind=kind,id=nextId,target=reference}
    end
    return nil
end
return Protocol
