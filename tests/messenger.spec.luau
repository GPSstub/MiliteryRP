--!strict
local Rules=require("../src/server/MessengerState")
local Core=require("../src/server/MessengerStoreCore")
local owner={userId=Rules.OWNER,rankOrder=1}
local member={userId=42,rankOrder=1}
local data=Rules.default()
local assertions=0
local function check(value, message) assertions+=1;assert(value,message or ("check "..assertions)) end
local function apply(actor,op)
    local updated,message=Rules.apply(data,actor,op)
    check(updated~=nil,message);data=updated;check(Rules.valid(data));return updated
end
check(Rules.valid(data));check(Rules.has(data,member,"SEND_MESSAGES"));check(not Rules.has(data,member,"MANAGE_ROLES"))
check(not Rules.apply(data,member,{action="create_channel",id="custom_x",name="Private"}))
apply(owner,{action="create_channel",id="custom_x",name="Private"})
apply(owner,{action="create_role",roleId="medic",name="의무병",permissions={SEND_MESSAGES=true}})
apply(owner,{action="set_channel_access",id="custom_x",roleId="member",mode="read",enabled=false})
apply(owner,{action="set_channel_access",id="custom_x",roleId="medic",mode="read",enabled=true})
check(not Rules.channel(data,member,"custom_x","read"));check(not Rules.channel(data,member,"custom_x","write"))
apply(owner,{action="assign_role",userId=42,roleId="medic"})
check(Rules.channel(data,member,"custom_x","read"));check(Rules.channel(data,member,"custom_x","write"))
apply(owner,{action="assign_role",userId=42,roleId="muted"});check(not Rules.channel(data,member,"custom_x","write"))
apply(owner,{action="remove_role",userId=42,roleId="muted"})
local persisted=Rules.copy(data);check(Rules.rolesFor(persisted,member).medic)
apply(owner,{action="rename_role",roleId="medic",name="의무지원"})
apply(owner,{action="rename_channel",id="custom_x",name="의무통신"})
apply(owner,{action="create_role",roleId="limited",name="역할 담당",permissions={MANAGE_ROLES=true}})
apply(owner,{action="assign_role",userId=43,roleId="limited"})
local limited={userId=43,rankOrder=1}
check(not Rules.apply(data,limited,{action="set_permission",roleId="medic",permission="MANAGE_SETTINGS",enabled=true}))
check(not Rules.apply(data,limited,{action="assign_role",userId=43,roleId="operator"}))
check(not Rules.apply(data,limited,{action="set_permission",roleId="operator",permission="SEND_MESSAGES",enabled=false}))
check(not Rules.apply(data,owner,{action="delete_channel",id="general"}))
check(not Rules.apply(data,owner,{action="delete_role",roleId="member"}))
check(not Rules.apply(data,owner,{action="assign_role",userId=0/0,roleId="medic"}))
apply(owner,{action="delete_role",roleId="medic"});check(not data.assignments["42"]);check(not data.channels.custom_x.acl.read.medic)
apply(owner,{action="delete_channel",id="custom_x"});check(not data.channels.custom_x)
local backing=nil
local serial=0
local writes=0
local failBefore=false
local failAfter=false
local function adapter()
    return {get=function() if failBefore then error("offline") end;return Rules.copy(backing) end,
        id=function() serial+=1;return "op_"..serial end,wait=function() end,
        update=function(transform)
            writes+=1
            if failBefore then error("offline") end
            local result=transform(Rules.copy(backing))
            if result then backing=Rules.copy(result) end
            if failAfter then failAfter=false;error("response lost after commit") end
            return result
        end}
end
local a=Core.new(Rules,adapter());local b=Core.new(Rules,adapter())
check(a:load());check(b:load())
local op={action="create_channel",id="custom_atomic",name="Atomic"}
check(a:commit(owner,op,0));check(backing.revision==1)
check(not b:commit(owner,{action="create_channel",id="custom_stale",name="Stale"},0));check(not backing.channels.custom_stale);check(b.data.revision==1)
local restart=Core.new(Rules,adapter());check(restart:load());check(restart.data.channels.custom_atomic~=nil)
failAfter=true
check(a:commit(owner,{action="rename_channel",id="custom_atomic",name="Confirmed"},1));check(backing.revision==2);check(a.data.revision==2)
local before=Rules.copy(backing)
failBefore=true
check(not a:commit(owner,{action="delete_channel",id="custom_atomic"},2));check(backing.channels.custom_atomic~=nil);check(a.data.revision==2);check(not a.ready)
check(not a:commit(owner,op,2));failBefore=false;check(a:load())
check(not a:commit(member,{action="delete_channel",id="custom_atomic"},2));check(backing.revision==2)
local malformed=Rules.copy(backing);malformed.schema=999;backing=malformed
check(not restart:load());check(not restart.ready)
check(not restart:commit(owner,op,2));check(backing.schema==999)
check(not Rules.valid({schema=1,revision=0}))
backing=Rules.default()
local config=Core.new(Rules,adapter());check(config:load())
local function commit(op) check(config:commit(owner,op,config.data.revision)) end
commit({action="create_role",roleId="persisted",name="영구 역할",permissions={SEND_MESSAGES=true}})
commit({action="assign_role",roleId="persisted",userId=42})
commit({action="create_channel",id="custom_saved",name="영구 채널"})
commit({action="set_channel_access",id="custom_saved",roleId="member",mode="read",enabled=false})
commit({action="set_channel_access",id="custom_saved",roleId="persisted",mode="read",enabled=true})
local recovered=Core.new(Rules,adapter());check(recovered:load())
check(recovered.data.roles.persisted.name=="영구 역할")
check(recovered.data.assignments["42"].persisted)
check(Rules.channel(recovered.data,member,"custom_saved","read"))
check(not Rules.channel(recovered.data,{userId=99,rankOrder=1},"custom_saved","read"))
check(not Rules.apply(recovered.data,owner,{action="assign_role",roleId="persisted",userId=math.huge}))
local corrupt=Rules.copy(recovered.data);corrupt.channels.general.channel="RBXGeneral";check(not Rules.valid(corrupt))
check(not Rules.apply(recovered.data,owner,{action="create_channel",id="custom_bad",name="\255\255"}))
print("Messenger tests passed: "..assertions.." assertions; "..writes.." adapter write attempts")
