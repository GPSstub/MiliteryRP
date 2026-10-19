--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Store=require(script.Parent.MessengerStore)
local Rules=require(script.Parent.MessengerState)
local Permissions=require(script.Parent.MessengerPermissions)
local Runtime=require(script.Parent.MessengerRuntime)
Runtime.start()
local remote=Instance.new("RemoteFunction");remote.Name="MessengerManage";remote.Parent=ReplicatedStorage
local changed=Instance.new("RemoteEvent");changed.Name="MessengerChannelsChanged";changed.Parent=ReplicatedStorage
local last={}
local editing={}
local metadataLast={}
local function snapshot(actor: Player)
    local data=Store.get()
    local result={channels={},permissions={roles={},people={},ownerId=Rules.OWNER},storage=Store.status(),revision=data.revision,
        canCreate=Permissions.has(actor,"CREATE_CHANNELS"),canManageRoles=Permissions.has(actor,"MANAGE_ROLES")}
    if not result.storage.ready then return result end
    for id,entry in data.channels do
        local read=Permissions.channel(actor,id,"read")
        local manage=Permissions.channel(actor,id,"manage")
        if read or manage then
            table.insert(result.channels,{id=id,name=Runtime.name(entry),channel=entry.channel,builtin=entry.builtin,
                persistent=Rules.isPersistent(data,id),
                canRead=read,canWrite=Permissions.channel(actor,id,"write"),canManage=manage,acl=if manage then Rules.copy(entry.acl) else nil,
                description=if read then "서버 권한이 적용된 통신 채널입니다." else "채널 관리 전용"})
        end
    end
    table.sort(result.channels,function(a,b) return a.id<b.id end)
    -- Role names and grants are needed to edit channel ACLs; assignments remain manager-only.
    for id,role in data.roles do
        result.permissions.roles[id]={name=Runtime.name(role),permissions=Rules.copy(role.permissions),protected=table.find({"member","officer","operator","muted"},id)~=nil}
    end
    if result.canManageRoles then
        local online={}
        for _,p in Players:GetPlayers() do online[tostring(p.UserId)]={userId=p.UserId,name=p.Name,displayName=p.DisplayName,roles={}} end
        for key,roles in data.assignments do
            local person=online[key] or {userId=tonumber(key),name="User "..key,displayName="오프라인",roles={}}
            for id in roles do table.insert(person.roles,id) end
            online[key]=person
        end
        for _,person in online do table.insert(result.permissions.people,person) end
        table.sort(result.permissions.people,function(a,b) return a.userId<b.userId end)
    end
    return result
end
local actions={create_channel=true,rename_channel=true,delete_channel=true,set_channel_access=true,set_channel_persistence=true,create_role=true,rename_role=true,
    delete_role=true,set_permission=true,assign_role=true,remove_role=true}
Store.Changed:Connect(function() changed:FireAllClients() end)
local function incoming(actor: Player,action: any,payload: any)
    if actor.Parent~=Players or type(action)~="string" then return {ok=false,message="잘못된 요청입니다."} end
    local now=os.clock()
    if now-(last[actor] or -math.huge)<0.2 then return {ok=false,message="잠시 후 다시 시도하세요."} end
    last[actor]=now
    if action=="snapshot" then return {ok=true,data=snapshot(actor)} end
    if action=="refresh" then Store.refresh();return {ok=true,data=snapshot(actor)} end
    if not actions[action] or type(payload)~="table" then return {ok=false,message="잘못된 입력입니다."} end
    if editing[actor] then return {ok=false,message="이전 변경을 저장 중입니다."} end
    editing[actor]=true
    local ok,result=pcall(function()
        -- Copy only whitelisted scalar values. Never traverse arbitrary remote tables.
        local op={action=action}
        for _,key in {"id","name","roleId","permission","mode"} do
            local value=payload[key]
            if value~=nil and (type(value)~="string" or #value>96 or not utf8.len(value)) then return {ok=false,message="입력 형식 오류"} end
            op[key]=value
        end
        op.enabled=payload.enabled;op.userId=payload.userId;op.persistent=payload.persistent
        if op.persistent~=nil and type(op.persistent)~="boolean" then return {ok=false,message="영구 저장 설정 형식 오류"} end
        if op.enabled~=nil and type(op.enabled)~="boolean" then return {ok=false,message="입력 형식 오류"} end
        if op.userId~=nil and type(op.userId)~="number" then return {ok=false,message="입력 형식 오류"} end
        op.permissions={}
        if action=="create_role" and payload.permissions~=nil then
            if type(payload.permissions)~="table" then return {ok=false,message="권한 형식 오류"} end
            for permission in Rules.PERMISSIONS do
                local value=payload.permissions[permission]
                if value~=nil and type(value)~="boolean" then return {ok=false,message="권한 형식 오류"} end
                if value then op.permissions[permission]=true end
            end
        end
        if action=="create_channel" then op.id="custom_"..HttpService:GenerateGUID(false):gsub("-","") end
        -- Reject unauthorized edits before expensive filtering; transaction re-checks latest stored roles.
        local preview,message=Rules.apply(Store.get(),Store.context(actor),op)
        if not preview then return {ok=false,message=message} end
        if op.name then
            if now-(metadataLast[actor] or -math.huge)<60 then return {ok=false,message="이름 생성·변경은 1분에 한 번 가능합니다."} end
            metadataLast[actor]=now
            if not Runtime.filter(op.name,actor.UserId) then return {ok=false,message="이름 필터링 실패. 변경하지 않았습니다."} end
        end
        local success,notice=Store.commit(actor,op,payload.revision)
        return {ok=success,message=notice,data=snapshot(actor)}
    end)
    editing[actor]=nil
    if not ok then warn("[MessengerManage] request failed");return {ok=false,message="요청 처리 실패. 새로고침 후 저장 상태를 확인하세요."} end
    return result
end
remote.OnServerInvoke=incoming
Players.PlayerRemoving:Connect(function(p) last[p]=nil;editing[p]=nil;metadataLast[p]=nil end)
