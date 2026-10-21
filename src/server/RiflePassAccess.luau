--!strict
-- Pure server entitlement cache; the Marketplace lookup is injected for tests.
local Access={}
export type Status="owned"|"notOwned"|"unconfigured"|"error"|"checking"
export type Entry={owns: boolean,untilTime: number,status: Status}
export type Options={
    passId: number,
    lookup: (number,number)->boolean,
    clock: ()->number,
    cacheSeconds: number,
    retrySeconds: number,
}
function Access.validPassId(value: number): boolean
    return value==value and value>0 and value<math.huge and value%1==0
end
function Access.new(options: Options)
    local cache: {[number]: Entry}={}
    local pending: {[number]: boolean}={}
    local versions: {[number]: number}={}
    local service={}
    function service.allowed(userId: number): boolean
        if not Access.validPassId(options.passId) then return false end
        local entry=cache[userId]
        return entry~=nil and entry.owns and options.clock()<entry.untilTime
    end
    function service.check(userId: number,force: boolean?): (boolean,Status)
        if not Access.validPassId(options.passId) then return false,"unconfigured" end
        local entry=cache[userId]
        if not force and entry and options.clock()<entry.untilTime then
            return entry.owns,entry.status
        end
        if pending[userId] then return false,"checking" end
        pending[userId]=true
        local version=versions[userId] or 0
        local success,result=pcall(options.lookup,userId,options.passId)
        -- Leaving a server invalidates any lookup that was already in flight.
        if (versions[userId] or 0)~=version then return false,"checking" end
        pending[userId]=nil
        local owns=success and result==true
        local status: Status=if not success or type(result)~="boolean" then "error"
            elseif owns then "owned" else "notOwned"
        cache[userId]={owns=owns,status=status,untilTime=options.clock()
            +(if status=="error" then options.retrySeconds else options.cacheSeconds)}
        return owns,status
    end
    function service.forget(userId: number)
        versions[userId]=(versions[userId] or 0)+1
        cache[userId]=nil
        pending[userId]=nil
    end
    return service
end
return Access
