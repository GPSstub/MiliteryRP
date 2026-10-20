--!strict
local Core=require("../src/server/AdminLogCore")
local checks=0
local function check(condition: any,reason: string)
    checks+=1
    assert(condition,reason)
end
check(Core.PAGE_SIZE==15,"Logs must be fetched in small ordered pages")
check(Core.typeValid("chat"),"Chat log type is required")
check(Core.typeValid("command"),"Command log type is required")
check(not Core.typeValid("other"),"Unrecognized log type must fail")
check(Core.keyValid("log_aabbcc11"),"Stored log key must be accepted")
check(not Core.keyValid("xx"),"Too-short log key must fail")
check(not Core.keyValid("log_a;bad"),"Illegal key characters must fail")
check(not Core.keyValid(string.rep("x",49)),"Long log IDs must fail")
local sample={
    id="log_77aa3355",kind="chat",time=1792453801,userId=83,
    name="SomePlayer",channelId="general",text="Filtered sentence",
    serverId="server_abc",source="메신저",
}
check(Core.valid(sample),"Filtered chat event validation failed")
local unfiltered=table.clone(sample)
unfiltered.text=string.rep("x",Core.MAX_TEXT_BYTES+1)
check(not Core.valid(unfiltered),"Oversized chat must be rejected")
local noChannel=table.clone(sample)
noChannel.channelId=nil
check(not Core.valid(noChannel),"Chat event must contain channel id")
local wrongType=table.clone(sample)
wrongType.kind="private"
check(not Core.valid(wrongType),"Unknown log type must be rejected")
local command=table.clone(sample)
command.kind="command"
command.channelId=nil
command.ok=false
check(Core.valid(command),"Administrator command log must validate")
check(Core.isRestricted("unit"),"Unit chat must be private")
check(not Core.isRestricted("general"),"General chat is not unit-private")
check(Core.canReadContent(sample,true,nil),"Readable general messages should display")
check(not Core.canReadContent(sample,false,nil),"Inaccessible channel must be redacted")
local restricted=table.clone(sample)
restricted.channelId="unit";restricted.unit="1대대"
check(Core.valid(restricted),"Unit-log event must validate")
check(not Core.canReadContent(restricted,true,nil),"Unknown unit cannot see private logs")
check(not Core.canReadContent(restricted,true,"2대대"),"Other unit cannot see private logs")
check(Core.canReadContent(restricted,true,"1대대"),"Authorized unit can see its logs")
check(Core.canReadContent(command,true,nil),"HQ can review filtered command logs")
local redacted=Core.present(restricted,false)
check(redacted.redacted,"Hidden log must be marked redacted")
check(redacted.text~="Filtered sentence","Hidden log must never include private chat text")
check(redacted.userId==83,"Audit identity must remain visible")
local shown=Core.present(sample,true)
check(shown.text=="Filtered sentence","Readable filtered text should be passed through")
print("HQ persistent audit log tests passed: "..checks.." assertions")
