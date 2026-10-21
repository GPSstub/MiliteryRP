--!strict
local Access=require("../src/server/RiflePassAccess")
local now=0
local calls=0
local result=false
local failed=false
local service=Access.new({passId=987654,clock=function() return now end,
    cacheSeconds=60,retrySeconds=5,lookup=function(userId: number,passId: number): boolean
        assert(userId==42 and passId==987654)
        calls+=1
        if failed then error("Marketplace unavailable") end
        return result
    end})
assert(not service.allowed(42),"Unknown players must not use a rifle")
local allowed,status=service.check(42)
assert(not allowed and status=="notOwned" and calls==1)
result=true
assert(not service.check(42),"Cached non-ownership must not be replaced by client intent")
assert(calls==1)
allowed,status=service.check(42,true)
assert(allowed and status=="owned" and calls==2,"Server purchase confirmation must refresh ownership")
assert(service.allowed(42))
assert(not service.allowed(43),"Another player must not inherit the buyer's entitlement")
now=61
assert(not service.allowed(42),"Expired verification must deny firing")
assert(service.check(42))
assert(calls==3)
failed=true
allowed,status=service.check(42,true)
assert(not allowed and status=="error" and not service.allowed(42),"API failure must fail closed")
assert(not service.check(42) and calls==4,"Errors must be throttled")
failed=false
now=67
assert(service.check(42) and calls==5,"Failed lookups must recover")
service.forget(42)
assert(not service.allowed(42),"Leave must revoke cached access")
result=false
assert(not service.check(42) and calls==6)
for _,invalid in {0,-1,0/0,math.huge,1.25} do
    local blocked=Access.new({passId=invalid,clock=function() return now end,
        cacheSeconds=60,retrySeconds=5,lookup=function(): boolean error("Must not call Marketplace for an invalid ID") end})
    local owns,why=blocked.check(42)
    assert(not owns and why=="unconfigured" and not blocked.allowed(42))
end
-- Simulate a yielding Marketplace request completing after PlayerRemoving.
local late=Access.new({passId=987654,clock=function() return now end,
    cacheSeconds=60,retrySeconds=5,lookup=function(): boolean coroutine.yield();return true end})
local thread=coroutine.create(function() assert(not late.check(42),"Late response must not restore access") end)
assert(coroutine.resume(thread))
late.forget(42)
assert(coroutine.resume(thread))
assert(not late.allowed(42))
print("PASS: rifle pass owners, non-owners, expiry, purchase refresh, API failure, invalid IDs and stale responses")
