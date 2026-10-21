--!strict
-- Pure, non-Roblox validation for server-session administrator audit events.
-- Validation and redaction remain independent of the in-memory history.
local Core={}
Core.PAGE_SIZE=15
Core.MAX_QUEUE=600
Core.MAX_TEXT_BYTES=1000
Core.TYPES={chat=true,command=true}

function Core.typeValid(kind: any): boolean
    return type(kind)=="string" and Core.TYPES[kind]==true
end

function Core.keyValid(key: any): boolean
    return type(key)=="string" and #key>=10 and #key<=48
        and key:match("^[%w_%-]+$")~=nil
end

function Core.valid(entry: any): boolean
    if type(entry)~="table" or not Core.typeValid(entry.kind)
        or not Core.keyValid(entry.id)
        or type(entry.time)~="number" or entry.time<1 or entry.time%1~=0
        or type(entry.userId)~="number" or entry.userId%1~=0
        or type(entry.name)~="string" or #entry.name>64
        or type(entry.text)~="string" or #entry.text>Core.MAX_TEXT_BYTES
        or type(entry.serverId)~="string" or #entry.serverId>80 then
        return false
    end
    if entry.kind=="chat" then
        return type(entry.channelId)=="string" and #entry.channelId<=48
            and (entry.unit==nil or (type(entry.unit)=="string" and #entry.unit<=90))
    end
    return type(entry.ok)=="boolean"
end

function Core.isRestricted(channelId: string): boolean
    return channelId=="unit"
end

function Core.canReadContent(entry: any,canReadChannel: boolean,currentUnit: any): boolean
    if entry.kind=="command" then return true end
    if not canReadChannel then return false end
    if Core.isRestricted(entry.channelId) then
        return type(entry.unit)=="string" and entry.unit~="" and entry.unit==currentUnit
    end
    return true
end

function Core.present(entry: any,allowedContent: boolean): any
    return {
        id=entry.id,kind=entry.kind,time=entry.time,
        name=entry.name,userId=entry.userId,
        channelId=entry.channelId,ok=entry.ok,source=entry.source,
        text=if allowedContent then entry.text else "[접근 권한이 없는 채널의 내용은 표시하지 않습니다.]",
        redacted=not allowedContent,
    }
end

return Core
