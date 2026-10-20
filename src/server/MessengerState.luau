--!strict
-- Pure, immutable configuration rules. No Roblox services or client trust.
local State = {}
State.OWNER = 1153125948
State.PERMISSIONS = {SEND_MESSAGES=true, CREATE_CHANNELS=true, DELETE_CHANNELS=true,
    MANAGE_ROLES=true, MANAGE_SETTINGS=true, POST_NOTICES=true, VIEW_COMMAND=true, WRITE_COMMAND=true}
local protected = {member=true, officer=true, operator=true, muted=true}
function State.copy(value: any): any
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in value do result[key] = State.copy(item) end
    return result
end
function State.default(): any
    local function role(name, grants) return {name=name, authorId=0, permissions=grants} end
    local function channel(id, name, transport, writer)
        return {id=id, name=name, authorId=0, channel=transport, builtin=true,
            persistent=id=="notice",
            acl={read={[if id=="command" then "officer" else "member"]=true}, write={[writer]=true}, manage={operator=true}}}
    end
    return {schema=1, revision=0, receipts={}, assignments={}, roles={
        member=role("일반 사용자",{SEND_MESSAGES=true}),
        officer=role("장교",{SEND_MESSAGES=true, POST_NOTICES=true, VIEW_COMMAND=true, WRITE_COMMAND=true}),
        operator=role("통신망 관리자",{SEND_MESSAGES=true, CREATE_CHANNELS=true, DELETE_CHANNELS=true, MANAGE_ROLES=true, MANAGE_SETTINGS=true}),
        muted=role("발언 제한",{}),
    }, channels={general=channel("general","전체 채팅","RP_General","member"),
        unit=channel("unit","부대 채팅","RP_Unit","member"),
        command=channel("command","지휘 채팅","RP_Command","officer"),
        notice=channel("notice","공지사항","RP_Notice","officer")}}
end
-- Backward compatible with existing schema=1 config records. Older notice channels
-- without a persistent field still behave as permanent announcements.
function State.isPersistent(data: any, id: string): boolean
    local channel=data.channels and data.channels[id]
    if not channel then return false end
    if channel.persistent~=nil then return channel.persistent==true end
    return id=="notice"
end
function State.rolesFor(data: any, actor: any): any
    local result = {member=true}
    if (actor.rankOrder or 0)>=11 then result.officer=true end -- existing main behavior
    for id, enabled in data.assignments[tostring(actor.userId)] or {} do
        if enabled and data.roles[id] then result[id]=true end
    end
    return result
end
function State.has(data: any, actor: any, permission: string): boolean
    if not State.PERMISSIONS[permission] then return false end
    if actor.userId==State.OWNER then return true end
    local roles=State.rolesFor(data,actor)
    if roles.muted and (permission=="SEND_MESSAGES" or permission=="POST_NOTICES" or permission=="WRITE_COMMAND") then return false end
    for id in roles do if data.roles[id].permissions[permission] then return true end end
    return false
end
function State.channel(data: any, actor: any, id: string, mode: string): boolean
    local entry=data.channels[id]
    if not entry or not entry.acl[mode] then return false end
    if actor.userId==State.OWNER then return true end
    if mode=="manage" and State.has(data,actor,"MANAGE_SETTINGS") then return true end
    if mode=="write" then
        if not State.has(data,actor,"SEND_MESSAGES") or not State.channel(data,actor,id,"read") then return false end
        if id=="notice" and not State.has(data,actor,"POST_NOTICES") then return false end
        if id=="command" and not State.has(data,actor,"WRITE_COMMAND") then return false end
    end
    if id=="command" and mode=="read" and not State.has(data,actor,"VIEW_COMMAND") then return false end
    for role in State.rolesFor(data,actor) do if entry.acl[mode][role] then return true end end
    return false
end
local function count(items): number local n=0;for _ in items do n+=1 end;return n end
local function validName(name): boolean
    if type(name)~="string" or #name>96 or name:find("[%c]") then return false end
    local length=utf8.len(name)
    return length~=nil and length>=2 and length<=24 and name:match("%S")~=nil
end
-- Names approved for public display by TextService are saved with the
-- channel/role. Old config entries (without displayName) remain compatible.
local function validDisplayName(name: any): boolean
    if type(name)~="string" or #name==0 or #name>384 or name:find("[%c]") then return false end
    local length=utf8.len(name)
    return length~=nil and length>0 and length<=96 and name:match("%S")~=nil
end
local function grantsValid(grants): boolean
    if type(grants)~="table" or count(grants)>8 then return false end
    for key,value in grants do if not State.PERMISSIONS[key] or type(value)~="boolean" then return false end end
    return true
end
-- Stored configuration is bounded and validated before use; unknown schemas fail closed.
function State.valid(data: any): boolean
    if type(data)~="table" or data.schema~=1 or type(data.revision)~="number" or data.revision<0 or data.revision%1~=0 then return false end
    for _,key in {"roles","channels","assignments","receipts"} do if type(data[key])~="table" then return false end end
    if count(data.roles)>30 or count(data.channels)>28 or count(data.assignments)>1000 or #data.receipts>64 then return false end
    for id in protected do if type(data.roles[id])~="table" then return false end end
    for id,role in data.roles do
        if type(id)~="string" or not id:match("^[a-z][a-z0-9_]*$") or #id>48 or type(role)~="table" or not validName(role.name) or not grantsValid(role.permissions) or type(role.authorId)~="number" or role.authorId<0 or role.authorId%1~=0
            or (role.displayName~=nil and not validDisplayName(role.displayName)) then return false end
    end
    for id,entry in data.channels do
        if type(id)~="string" or type(entry)~="table" or entry.id~=id or not validName(entry.name) or type(entry.authorId)~="number" or type(entry.channel)~="string" or type(entry.acl)~="table" or (entry.persistent~=nil and type(entry.persistent)~="boolean")
            or (entry.displayName~=nil and not validDisplayName(entry.displayName)) then return false end
        if entry.authorId<0 or entry.authorId%1~=0 then return false end
        local builtins={general="RP_General",unit="RP_Unit",command="RP_Command",notice="RP_Notice"}
        if builtins[id] then
            if entry.builtin~=true or entry.channel~=builtins[id] then return false end
        elseif entry.builtin~=false or not id:match("^custom_%w+$") or #id>48 or entry.channel~="RP_"..id then return false end
        for _,mode in {"read","write","manage"} do
            if type(entry.acl[mode])~="table" or count(entry.acl[mode])>30 then return false end
            for role,value in entry.acl[mode] do if not data.roles[role] or type(value)~="boolean" then return false end end
        end
    end
    for _,id in {"general","unit","command","notice"} do if not data.channels[id] or not data.channels[id].builtin then return false end end
    if count(data.receipts)>64 or count(data.receipts)~=#data.receipts then return false end
    for _,receipt in data.receipts do
        if type(receipt)~="table" or type(receipt.id)~="string" or #receipt.id>64 then return false end
    end
    for userId,roles in data.assignments do
        if type(userId)~="string" or not userId:match("^%d+$") or type(roles)~="table" or count(roles)>30 then return false end
        for role,value in roles do if not data.roles[role] or value~=true then return false end end
    end
    return true
end
local function canGrant(data,actor,role): boolean
    for permission,enabled in role.permissions do if enabled and not State.has(data,actor,permission) then return false end end
    return true
end
function State.apply(data: any, actor: any, op: any): (any?, string)
    local updated=State.copy(data)
    local action=op.action
    local entry=updated.channels[op.id]
    local role=updated.roles[op.roleId]
    if action=="create_channel" then
        if not State.has(data,actor,"CREATE_CHANNELS") then return nil,"채널 개설 권한이 없습니다." end
        if not validName(op.name) or type(op.id)~="string" or not op.id:match("^custom_%w+$") or updated.channels[op.id] or count(updated.channels)>=28 then return nil,"채널 이름 또는 개수 제한을 확인하세요." end
        for _,other in updated.channels do if other.name==op.name then return nil,"같은 이름의 채널이 있습니다." end end
        if op.persistent~=nil and type(op.persistent)~="boolean" then return nil,"영구 저장 설정이 올바르지 않습니다." end
        if op.displayName~=nil and not validDisplayName(op.displayName) then return nil,"채널 표시 이름이 유효하지 않습니다." end
        updated.channels[op.id]={id=op.id,name=op.name,displayName=op.displayName,authorId=actor.userId,channel="RP_"..op.id,builtin=false,persistent=op.persistent==true,acl={read={member=true},write={member=true},manage={operator=true}}}
    elseif action=="rename_channel" or action=="delete_channel" or action=="set_channel_access" or action=="set_channel_persistence" then
        if not entry or not State.channel(data,actor,op.id,"manage") then return nil,"채널 관리 권한이 없습니다." end
        if action=="delete_channel" then
            if entry.builtin or not State.has(data,actor,"DELETE_CHANNELS") then return nil,"삭제할 수 없는 채널입니다." end
            updated.channels[op.id]=nil
        elseif action=="set_channel_persistence" then
            if type(op.persistent)~="boolean" then return nil,"영구 저장 설정이 올바르지 않습니다." end
            -- Read-only managers should not turn a private channel into an archive.
            if not State.has(data,actor,"MANAGE_SETTINGS") then return nil,"채널 설정 관리 권한이 없습니다." end
            entry.persistent=op.persistent
        elseif action=="rename_channel" then
            if not validName(op.name) then return nil,"이름은 2~24자로 지정하세요." end
            for id,other in updated.channels do if id~=op.id and other.name==op.name then return nil,"같은 이름의 채널이 있습니다." end end
            if op.displayName~=nil and not validDisplayName(op.displayName) then return nil,"채널 표시 이름이 유효하지 않습니다." end
            entry.name=op.name;entry.displayName=op.displayName;entry.authorId=actor.userId
        else
            if not updated.roles[op.roleId] or not entry.acl[op.mode] or type(op.enabled)~="boolean" then return nil,"잘못된 채널 권한입니다." end
            entry.acl[op.mode][op.roleId]=op.enabled or nil
        end
    elseif action=="create_role" or action=="rename_role" or action=="delete_role" or action=="set_permission" or action=="assign_role" or action=="remove_role" then
        if not State.has(data,actor,"MANAGE_ROLES") then return nil,"역할 관리 권한이 없습니다." end
        if action=="create_role" then
            if type(op.roleId)~="string" or not op.roleId:match("^[a-z][a-z0-9_]*$") or #op.roleId<3 or #op.roleId>24 or role or count(updated.roles)>=30 or not validName(op.name) or not grantsValid(op.permissions) then return nil,"역할 ID·이름·권한을 확인하세요." end
            if op.displayName~=nil and not validDisplayName(op.displayName) then return nil,"역할 표시 이름이 유효하지 않습니다." end
            local created={name=op.name,displayName=op.displayName,authorId=actor.userId,permissions=State.copy(op.permissions)}
            if not canGrant(data,actor,created) then return nil,"보유하지 않은 권한은 부여할 수 없습니다." end
            updated.roles[op.roleId]=created
        else
            if not role or not canGrant(data,actor,role) then return nil,"이 역할을 관리할 권한이 부족합니다." end
            if action=="assign_role" or action=="remove_role" then
                if op.roleId=="member" or op.roleId=="officer" or type(op.userId)~="number" or op.userId<1 or op.userId%1~=0 or op.userId>2^53 then return nil,"유효한 사용자 ID와 수동 역할을 선택하세요." end
                local key=tostring(op.userId)
                if not updated.assignments[key] and count(updated.assignments)>=1000 then return nil,"사용자 배정 한도입니다." end
                updated.assignments[key]=updated.assignments[key] or {}
                updated.assignments[key][op.roleId]=if action=="assign_role" then true else nil
                if next(updated.assignments[key])==nil then updated.assignments[key]=nil end
            else
                if protected[op.roleId] then return nil,"기본 역할은 보호됩니다." end
                if action=="rename_role" then
                    if not validName(op.name) then return nil,"역할 이름은 2~24자입니다." end
                    if op.displayName~=nil and not validDisplayName(op.displayName) then return nil,"역할 표시 이름이 유효하지 않습니다." end
                    role.name=op.name;role.displayName=op.displayName;role.authorId=actor.userId
                elseif action=="set_permission" then
                    if not State.PERMISSIONS[op.permission] or type(op.enabled)~="boolean" or (op.enabled and not State.has(data,actor,op.permission)) then return nil,"권한을 부여할 수 없습니다." end
                    role.permissions[op.permission]=op.enabled or nil
                else
                    updated.roles[op.roleId]=nil
                    for key,assigned in updated.assignments do assigned[op.roleId]=nil;if next(assigned)==nil then updated.assignments[key]=nil end end
                    for _,channel in updated.channels do for _,acl in channel.acl do acl[op.roleId]=nil end end
                end
            end
        end
    else return nil,"알 수 없는 요청입니다." end
    updated.revision+=1
    return updated,"저장 완료"
end
return State
