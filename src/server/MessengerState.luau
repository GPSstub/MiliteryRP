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
-- Existing ACL grants remain the base. Explicit overwrites apply everyone first,
-- then assigned roles (combined deny, then combined allow), like Discord's role overwrites.
function State.effectiveAccess(data: any, actor: any, entry: any, mode: string): boolean
    local source=entry
    if entry.synced and entry.categoryId and data.categories and data.categories[entry.categoryId] then source=data.categories[entry.categoryId] end
    local roles=State.rolesFor(data,actor)
    local allowed=false
    for id in roles do if source.acl[mode][id] then allowed=true end end
    local overrides=(source.overwrites or {})[mode] or {}
    if overrides.member~=nil then allowed=overrides.member end
    local deny,allow=false,false
    for id in roles do
        if id~="member" then
            if overrides[id]==false then deny=true elseif overrides[id]==true then allow=true end
        end
    end
    if deny then allowed=false end
    if allow then allowed=true end
    return allowed
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
    return State.effectiveAccess(data,actor,entry,mode)
end
local function count(items): number local n=0;for _ in items do n+=1 end;return n end
local function validName(name): boolean
    if type(name)~="string" or #name>96 or name:find("[%c]") then return false end
    local length=utf8.len(name)
    return length~=nil and length>=2 and length<=24 and name:match("%S")~=nil
end
local function grantsValid(grants): boolean
    if type(grants)~="table" or count(grants)>8 then return false end
    for key,value in grants do if not State.PERMISSIONS[key] or type(value)~="boolean" then return false end end
    return true
end
local function validAcl(acl: any,roles: any): boolean
    if type(acl)~="table" then return false end
    for _,mode in {"read","write","manage"} do
        if type(acl[mode])~="table" or count(acl[mode])>30 then return false end
        for id,value in acl[mode] do if not roles[id] or type(value)~="boolean" then return false end end
    end
    return true
end
local function validOrder(value: any): boolean
    return value==nil or (type(value)=="number" and value==value and value>=0 and value<=10000 and value%1==0)
end
-- Stored configuration is bounded and validated before use; unknown schemas fail closed.
function State.valid(data: any): boolean
    if type(data)~="table" or (data.schema~=1 and data.schema~=2) or type(data.revision)~="number" or data.revision<0 or data.revision%1~=0 then return false end
    for _,key in {"roles","channels","assignments","receipts"} do if type(data[key])~="table" then return false end end
    if count(data.roles)>30 or count(data.channels)>28 or count(data.assignments)>1000 or #data.receipts>64 then return false end
    for id in protected do if type(data.roles[id])~="table" then return false end end
    for id,role in data.roles do
        if type(id)~="string" or not id:match("^[a-z][a-z0-9_]*$") or #id>48 or type(role)~="table" or not validName(role.name) or not grantsValid(role.permissions) or type(role.authorId)~="number" or role.authorId<0 or role.authorId%1~=0 then return false end
    end
    if data.categories~=nil then
        if type(data.categories)~="table" or count(data.categories)>12 then return false end
        for id,entry in data.categories do
            if type(id)~="string" or not id:match("^cat_%w+$") or #id>48 or type(entry)~="table"
                or not validName(entry.name) or type(entry.authorId)~="number" or entry.authorId<0 or entry.authorId%1~=0
                or not validOrder(entry.order) or not validAcl(entry.acl,data.roles)
                or (entry.overwrites~=nil and not validAcl(entry.overwrites,data.roles)) then return false end
        end
    end
    for id,entry in data.channels do
        if type(id)~="string" or type(entry)~="table" or entry.id~=id or not validName(entry.name) or type(entry.authorId)~="number" or type(entry.channel)~="string" or type(entry.acl)~="table" then return false end
        if entry.authorId<0 or entry.authorId%1~=0 then return false end
        local builtins={general="RP_General",unit="RP_Unit",command="RP_Command",notice="RP_Notice"}
        if builtins[id] then
            if entry.builtin~=true or entry.channel~=builtins[id] then return false end
        elseif entry.builtin~=false or not id:match("^custom_%w+$") or #id>48 or entry.channel~="RP_"..id then return false end
        if not validOrder(entry.order) or (entry.synced~=nil and type(entry.synced)~="boolean")
            or (entry.categoryId~=nil and (type(entry.categoryId)~="string" or not (data.categories or {})[entry.categoryId]))
            or (entry.synced and not entry.categoryId)
            or (entry.overwrites~=nil and not validAcl(entry.overwrites,data.roles)) then return false end
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
    if op.action=="batch_settings" then
        if type(op.operations)~="table" or #op.operations<1 or #op.operations>40 then return nil,"한 번에 최대 40개까지 저장할 수 있습니다." end
        local current=data
        for _,operation in op.operations do
            if type(operation)~="table" or not table.find({"set_overwrite","place_channel","move_category","set_permission"},operation.action) then return nil,"일괄 저장 대상 오류" end
            local nextData,message=State.apply(current,actor,operation)
            if not nextData then return nil,message end
            current=nextData
        end
        current.revision=data.revision+1
        return current,"설정 저장 완료"
    end
    local updated=State.copy(data)
    -- Old servers understand schema 1 only and must fail closed after advanced ACL writes.
    updated.schema=2
    updated.categories=updated.categories or {}
    local action=op.action
    local entry=updated.channels[op.id]
    local role=updated.roles[op.roleId]
    if action=="create_category" or action=="rename_category" or action=="delete_category" or action=="move_category" then
        if not State.has(data,actor,"MANAGE_SETTINGS") then return nil,"통신망 관리 권한이 없습니다." end
        local category=updated.categories[op.id]
        if action=="create_category" then
            if type(op.id)~="string" or not op.id:match("^cat_%w+$") or #op.id>48 or category or count(updated.categories)>=12 or not validName(op.name) then return nil,"카테고리 이름 또는 개수 제한을 확인하세요." end
            updated.categories[op.id]={name=op.name,authorId=actor.userId,order=count(updated.categories)+1,
                acl={read={member=true},write={member=true},manage={operator=true}}}
        elseif not category then return nil,"카테고리를 찾을 수 없습니다."
        elseif action=="rename_category" then
            if not validName(op.name) then return nil,"이름은 2~24자입니다." end
            category.name=op.name;category.authorId=actor.userId
        elseif action=="move_category" then
            if op.order==nil or not validOrder(op.order) then return nil,"잘못된 순서입니다." end
            local ordered={}
            for id,value in updated.categories do if id~=op.id then table.insert(ordered,{id=id,order=value.order or 0}) end end
            table.sort(ordered,function(a,b) return if a.order==b.order then a.id<b.id else a.order<b.order end)
            table.insert(ordered,math.clamp(op.order,1,#ordered+1),{id=op.id})
            for index,value in ordered do updated.categories[value.id].order=index end
        else
            -- Deleting a category preserves channels and their effective permissions.
            for _,channel in updated.channels do
                if channel.categoryId==op.id then
                    if channel.synced then channel.acl=State.copy(category.acl);channel.overwrites=State.copy(category.overwrites) end
                    channel.categoryId=nil;channel.synced=nil
                end
            end
            updated.categories[op.id]=nil
        end
    elseif action=="place_channel" then
        if not entry or not State.channel(data,actor,op.id,"manage") or not State.has(data,actor,"MANAGE_SETTINGS") then return nil,"통신망 관리 권한이 없습니다." end
        if op.categoryId~="" and not updated.categories[op.categoryId] then return nil,"카테고리를 찾을 수 없습니다." end
        if type(op.synced)~="boolean" or not validOrder(op.order) or (op.synced and op.categoryId=="") then return nil,"배치 설정 오류" end
        if entry.synced and entry.categoryId and not op.synced then
            local category=updated.categories[entry.categoryId]
            entry.acl=State.copy(category.acl);entry.overwrites=State.copy(category.overwrites)
        end
        entry.categoryId=if op.categoryId=="" then nil else op.categoryId
        entry.synced=op.synced
        local ordered={}
        for id,value in updated.channels do if id~=op.id and value.categoryId==entry.categoryId then table.insert(ordered,{id=id,order=value.order or 0}) end end
        table.sort(ordered,function(a,b) return if a.order==b.order then a.id<b.id else a.order<b.order end)
        table.insert(ordered,math.clamp(op.order or #ordered+1,1,#ordered+1),{id=op.id})
        for index,value in ordered do updated.channels[value.id].order=index end
    elseif action=="set_overwrite" then
        local target=if op.scope=="category" then updated.categories[op.id] else entry
        if (op.scope~="channel" and op.scope~="category") or not target then return nil,"대상을 찾을 수 없습니다." end
        if (op.scope=="category" and not State.has(data,actor,"MANAGE_SETTINGS"))
            or (op.scope=="channel" and not State.channel(data,actor,op.id,"manage")) then return nil,"권한 편집 권한이 없습니다." end
        if target.synced then return nil,"카테고리와 동기화 중입니다. 먼저 동기화를 해제하세요." end
        if not data.roles[op.roleId] or not target.acl[op.mode] or not table.find({"allow","deny","inherit"},op.value) then return nil,"잘못된 권한 설정입니다." end
        target.overwrites=target.overwrites or {read={},write={},manage={}}
        target.overwrites[op.mode][op.roleId]=if op.value=="inherit" then nil else op.value=="allow"
    elseif action=="create_channel" then
        if not State.has(data,actor,"CREATE_CHANNELS") then return nil,"채널 개설 권한이 없습니다." end
        if not validName(op.name) or type(op.id)~="string" or not op.id:match("^custom_%w+$") or updated.channels[op.id] or count(updated.channels)>=28 then return nil,"채널 이름 또는 개수 제한을 확인하세요." end
        for _,other in updated.channels do if other.name==op.name then return nil,"같은 이름의 채널이 있습니다." end end
        updated.channels[op.id]={id=op.id,name=op.name,authorId=actor.userId,channel="RP_"..op.id,builtin=false,acl={read={member=true},write={member=true},manage={operator=true}}}
    elseif action=="rename_channel" or action=="delete_channel" or action=="set_channel_access" then
        if not entry or not State.channel(data,actor,op.id,"manage") then return nil,"채널 관리 권한이 없습니다." end
        if action=="delete_channel" then
            if entry.builtin or not State.has(data,actor,"DELETE_CHANNELS") then return nil,"삭제할 수 없는 채널입니다." end
            updated.channels[op.id]=nil
        elseif action=="rename_channel" then
            if not validName(op.name) then return nil,"이름은 2~24자로 지정하세요." end
            for id,other in updated.channels do if id~=op.id and other.name==op.name then return nil,"같은 이름의 채널이 있습니다." end end
            entry.name=op.name;entry.authorId=actor.userId
        else
            if not updated.roles[op.roleId] or not entry.acl[op.mode] or type(op.enabled)~="boolean" then return nil,"잘못된 채널 권한입니다." end
            entry.acl[op.mode][op.roleId]=op.enabled or nil
        end
    elseif action=="create_role" or action=="rename_role" or action=="delete_role" or action=="set_permission" or action=="assign_role" or action=="remove_role" then
        if not State.has(data,actor,"MANAGE_ROLES") then return nil,"역할 관리 권한이 없습니다." end
        if action=="create_role" then
            if type(op.roleId)~="string" or not op.roleId:match("^[a-z][a-z0-9_]*$") or #op.roleId<3 or #op.roleId>24 or role or count(updated.roles)>=30 or not validName(op.name) or not grantsValid(op.permissions) then return nil,"역할 ID·이름·권한을 확인하세요." end
            local created={name=op.name,authorId=actor.userId,permissions=State.copy(op.permissions)}
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
                    role.name=op.name;role.authorId=actor.userId
                elseif action=="set_permission" then
                    if not State.PERMISSIONS[op.permission] or type(op.enabled)~="boolean" or (op.enabled and not State.has(data,actor,op.permission)) then return nil,"권한을 부여할 수 없습니다." end
                    role.permissions[op.permission]=op.enabled or nil
                else
                    updated.roles[op.roleId]=nil
                    for key,assigned in updated.assignments do assigned[op.roleId]=nil;if next(assigned)==nil then updated.assignments[key]=nil end end
                    for _,group in {updated.channels,updated.categories} do
                        for _,channel in group do
                            for _,acl in channel.acl do acl[op.roleId]=nil end
                            for _,acl in channel.overwrites or {} do acl[op.roleId]=nil end
                        end
                    end
                end
            end
        end
    else return nil,"알 수 없는 요청입니다." end
    updated.revision+=1
    return updated,"저장 완료"
end
return State
