--!strict
-- Pure protocol regressions; run with luau tests/messenger-actions.spec.luau.
local Protocol=require("../src/shared/MessengerActionProtocol")
local checks=0
local function check(condition: any, description: string)
    checks+=1;assert(condition,description)
end
local a="e1787684-1139-4a75-8813-ad9ee2f74fc0"
local b="05dc20b8-7a37-4d36-8206-0b86f2c8540d"
check(Protocol.validId(a),"UUID should be an accepted message identifier")
check(not Protocol.validId("x"),"Too-short IDs should fail")
check(not Protocol.validId(string.rep("x",91)),"Oversized IDs should fail")
check(not Protocol.validId("x;DROP TABLE"),"Invalid characters should fail")
check(not Protocol.validId(123),"IDs must be strings")
for _,kind in {"m","e","r","t"} do
    local encoded=Protocol.encode(kind,a,if kind=="m" then nil else b)
    check(encoded~=nil,"Encoding "..kind.." must succeed")
    local parsed=Protocol.decode(encoded)
    check(parsed~=nil and parsed.kind==kind and parsed.id==a,"Decoded kind or ID mismatch for "..kind)
    check(parsed.target==(if kind=="m" then nil else b),"Reference mismatch for "..kind)
end
check(Protocol.encode("x",a,b)==nil,"Unknown kind must not encode")
check(Protocol.encode("m",a,b)==nil,"New message cannot have a target")
check(Protocol.encode("r",a,"too short")==nil,"Bad target ID must not encode")
for _,invalid in {"","mrp1|m|x","mrp1|e|"..a,"mrp1|r|"..a.."|x",
    "mrp1|t|"..a.."|"..b.."|extra",
    "mrp1|m|"..a.."|",
    "mrp1|x|"..a,"mrp1|e|"..a.."|"..b..";bad",
    string.rep("a",201)} do
    check(Protocol.decode(invalid)==nil,"Invalid metadata must fail: "..invalid:sub(1,40))
end
check(Protocol.decode(123)==nil,"Non-string metadata must fail")
print("Messenger action protocol tests passed: "..checks.." assertions")
