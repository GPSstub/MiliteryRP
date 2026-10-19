--!strict
local R=require("../src/server/MessengerState")
local Core=require("../src/server/MessengerStoreCore")
local owner={userId=R.OWNER,rankOrder=1}
local member={userId=42,rankOrder=1}
local data=R.default()
local count=0
local function check(value,message) count+=1;assert(value,message or tostring(count)) end
local function apply(op)
    local nextData,message=R.apply(data,owner,op);check(nextData~=nil,message);check(R.valid(nextData));data=nextData
end
local legacy=R.copy(data);legacy.categories=nil;check(R.valid(legacy))
check(not R.apply(data,member,{action="create_category",id="cat_no",name="분류"}))
apply({action="create_category",id="cat_ops",name="작전 통신"})
check(data.schema==2,"Advanced ACL writes must invalidate old server readers")
apply({action="create_channel",id="custom_ops",name="작전 채널"})
apply({action="create_role",roleId="medic",name="의무병",permissions={SEND_MESSAGES=true}})
apply({action="assign_role",userId=42,roleId="medic"})
apply({action="place_channel",id="custom_ops",categoryId="cat_ops",synced=true,order=2})
check(R.channel(data,member,"custom_ops","read"))
apply({action="set_overwrite",scope="category",id="cat_ops",roleId="member",mode="read",value="deny"})
check(not R.channel(data,member,"custom_ops","read"));check(not R.channel(data,member,"custom_ops","write"))
check(not R.apply(data,owner,{action="set_overwrite",scope="channel",id="custom_ops",roleId="medic",mode="read",value="allow"}))
apply({action="set_overwrite",scope="category",id="cat_ops",roleId="medic",mode="read",value="allow"})
check(R.channel(data,member,"custom_ops","read"))
apply({action="set_overwrite",scope="category",id="cat_ops",roleId="medic",mode="read",value="deny"})
check(not R.channel(data,member,"custom_ops","read"))
apply({action="set_overwrite",scope="category",id="cat_ops",roleId="medic",mode="read",value="inherit"})
check(not R.channel(data,member,"custom_ops","read"))
apply({action="place_channel",id="custom_ops",categoryId="cat_ops",synced=false,order=2})
apply({action="set_overwrite",scope="category",id="cat_ops",roleId="member",mode="read",value="allow"})
check(not R.channel(data,member,"custom_ops","read"),"Detached channel changed with category")
local revision=data.revision
apply({action="batch_settings",operations={
 {action="set_overwrite",scope="channel",id="custom_ops",roleId="member",mode="read",value="allow"},
 {action="set_overwrite",scope="channel",id="custom_ops",roleId="member",mode="write",value="deny"}}})
check(data.revision==revision+1);check(R.channel(data,member,"custom_ops","read"));check(not R.channel(data,member,"custom_ops","write"))
local before=R.copy(data)
check(not R.apply(data,member,{action="batch_settings",operations={{action="set_overwrite",scope="channel",id="custom_ops",roleId="member",mode="read",value="allow"}}}))
check(not R.apply(data,owner,{action="batch_settings",operations={
 {action="set_overwrite",scope="channel",id="custom_ops",roleId="member",mode="read",value="deny"},
 {action="set_permission",roleId="member",permission="SEND_MESSAGES",enabled=false}}}))
check(data.revision==before.revision and R.channel(data,member,"custom_ops","read"),"Partial batch leaked")
check(not R.apply(data,owner,{action="batch_settings",operations={{action="batch_settings",operations={}}}}))
check(not R.apply(data,owner,{action="place_channel",id="custom_ops",categoryId="missing",synced=true,order=0}))
check(not R.apply(data,owner,{action="move_category",id="cat_ops",order=0/0}))
apply({action="place_channel",id="custom_ops",categoryId="cat_ops",synced=true,order=2})
apply({action="delete_category",id="cat_ops"})
check(data.channels.custom_ops~=nil and not data.channels.custom_ops.synced)
check(R.channel(data,member,"custom_ops","read"),"Delete category changed effective ACL")
apply({action="create_category",id="cat_saved",name="저장 분류"})
apply({action="place_channel",id="custom_ops",categoryId="cat_saved",synced=true,order=2})
apply({action="delete_role",roleId="medic"});check(R.valid(data))
local backing=R.copy(data)
local function adapter() return {get=function() return R.copy(backing) end,id=function() return "new-batch" end,wait=function() end,
 update=function(fn) local value=fn(R.copy(backing));if value then backing=R.copy(value) end;return value end} end
local core=Core.new(R,adapter());check(core:load())
check(core:commit(owner,{action="batch_settings",operations={{action="set_overwrite",scope="category",id="cat_saved",roleId="member",mode="read",value="deny"}}},data.revision))
local recovered=Core.new(R,adapter());check(recovered:load());check(not R.channel(recovered.data,member,"custom_ops","read"))
local bad=R.copy(data);bad.channels.custom_ops.categoryId="missing";check(not R.valid(bad))
bad=R.copy(data);bad.categories.cat_saved.overwrites={read={fake=true},write={},manage={}};check(not R.valid(bad))
print("Settings v2 tests passed: "..count.." assertions")
