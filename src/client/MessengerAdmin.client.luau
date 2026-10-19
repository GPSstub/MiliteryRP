--!strict
-- Discord-like server settings. UI grants no authority; every mutation is a server transaction.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("MilitaryMessenger")
local window=gui:WaitForChild("MessengerWindow") :: Frame
local header=window:WaitForChild("Header") :: Frame
local sidebar=window:WaitForChild("ChannelSidebar") :: Frame
local remote=ReplicatedStorage:WaitForChild("MessengerManage") :: RemoteFunction
local changed=ReplicatedStorage:WaitForChild("MessengerChannelsChanged") :: RemoteEvent
local C={bg=Color3.fromRGB(27,30,37),side=Color3.fromRGB(20,23,29),surface=Color3.fromRGB(37,42,51),white=Color3.fromRGB(241,242,245),muted=Color3.fromRGB(153,162,174),accent=Color3.fromRGB(106,149,113),red=Color3.fromRGB(150,67,75)}
local function make(class: string,parent: Instance,props: any): any
    local obj=Instance.new(class)
    for k,v in props do (obj :: any)[k]=v end
    obj.Parent=parent;return obj
end
local function corner(o: Instance) make("UICorner",o,{CornerRadius=UDim.new(0,8)}) end
local function pad(o: Instance)
    make("UIPadding",o,{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)})
end
local function button(parent: Instance,name: string,value: string,color: Color3?): TextButton
    local b=make("TextButton",parent,{Name=name,Text=value,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=C.white,
        BackgroundColor3=color or C.surface,BorderSizePixel=0,Size=UDim2.new(1,-8,0,44),ZIndex=17,Selectable=true})
    pad(b);b.TextXAlignment=Enum.TextXAlignment.Left;corner(b);return b
end
local function text(parent: Instance,value: string,height: number): TextLabel
    return make("TextLabel",parent,{Text=value,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=C.white,
        BackgroundTransparency=1,Size=UDim2.new(1,-8,0,height),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17})
end
local function input(parent: Instance,placeholder: string): TextBox
    local box=make("TextBox",parent,{Text="",PlaceholderText=placeholder,ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=14,
        TextColor3=C.white,PlaceholderColor3=C.muted,BackgroundColor3=C.surface,BorderSizePixel=0,Size=UDim2.new(1,-8,0,44),ZIndex=17})
    pad(box);box.TextXAlignment=Enum.TextXAlignment.Left;corner(box);return box
end
local open=button(header,"MessengerSettingsButton","설정")
open.AnchorPoint=Vector2.new(1,0);open.Position=UDim2.new(1,-60,0,9);open.Size=UDim2.fromOffset(72,40);open.TextXAlignment=Enum.TextXAlignment.Center
local plus=button(sidebar,"CreateChannelButton","+")
plus.AnchorPoint=Vector2.new(1,0);plus.Position=UDim2.new(1,-8,0,6);plus.Size=UDim2.fromOffset(40,40);plus.TextSize=25;plus.TextXAlignment=Enum.TextXAlignment.Center
local overlay=make("Frame",window,{Name="SettingsOverlay",Position=UDim2.fromOffset(0,60),Size=UDim2.new(1,0,1,-60),BackgroundColor3=C.bg,BorderSizePixel=0,Active=true,Visible=false,ZIndex=15})
local nav=make("Frame",overlay,{Name="SettingsSidebar",BackgroundColor3=C.side,BorderSizePixel=0,ZIndex=16})
local body=make("ScrollingFrame",overlay,{Name="SettingsBody",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=16})
make("UIListLayout",body,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
make("UIPadding",body,{PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,16)})
local heading=text(overlay,"통신망 설정",36)
heading.Name="SettingsHeading";heading.TextSize=22;heading.Font=Enum.Font.GothamBold
local status=text(overlay,"설정을 불러오는 중…",40)
status.Position=UDim2.new(0,12,1,-44);status.Size=UDim2.new(1,-24,0,40);status.TextColor3=C.muted
local back=button(nav,"BackToChannels","← 통신망")
local state: any={channels={},permissions={roles={},people={}},storage={ready=false},revision=0}
local page="channels"
local selectedChannel="general"
local selectedRole="member"
local busy=false
local render: ()->()
local refresh: ()->()
local scrim=make("TextButton",window,{Name="ModalBackdrop",Text="",AutoButtonColor=false,
    Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.35,
    BorderSizePixel=0,Visible=false,ZIndex=24})
local modal=make("Frame",window,{Name="ChannelModal",BackgroundColor3=C.bg,BorderSizePixel=0,Size=UDim2.fromScale(0.9,0.75),
    AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Visible=false,ZIndex=25})
corner(modal)
make("UISizeConstraint",modal,{MaxSize=Vector2.new(420,330)})
local modalTitle=text(modal,"채널 만들기",36);modalTitle.Position=UDim2.fromOffset(20,16);modalTitle.Size=UDim2.new(1,-40,0,36);modalTitle.TextSize=19;modalTitle.ZIndex=26
local modalInput=input(modal,"이름 (2~24자)");modalInput.Name="NameInput";modalInput.Position=UDim2.fromOffset(20,66);modalInput.Size=UDim2.new(1,-40,0,44);modalInput.ZIndex=26
local modalInfo=text(modal,"",90);modalInfo.Position=UDim2.fromOffset(20,118);modalInfo.Size=UDim2.new(1,-40,1,-184);modalInfo.ZIndex=26
local persistentSelected=false
local persistentChoice=button(modal,"PersistentChoice","○  일반 채널 · 기록 저장 안 함",C.surface)
persistentChoice.Position=UDim2.fromOffset(20,116)
persistentChoice.Size=UDim2.new(1,-40,0,38)
persistentChoice.ZIndex=26
persistentChoice.Visible=false
persistentChoice.Activated:Connect(function()
    persistentSelected=not persistentSelected
    persistentChoice.Text=if persistentSelected then "✓  영구 보관 · 기록 저장" else "○  일반 채널 · 기록 저장 안 함"
    persistentChoice.BackgroundColor3=if persistentSelected then C.accent else C.surface
end)
local confirm=button(modal,"Confirm","저장",C.accent);confirm.Position=UDim2.new(0,20,1,-56);confirm.Size=UDim2.new(0.5,-26,0,44);confirm.ZIndex=26
local cancel=button(modal,"Cancel","취소");cancel.Position=UDim2.new(0.5,6,1,-56);cancel.Size=UDim2.new(0.5,-26,0,44);cancel.ZIndex=26
local modalAction: ((string)->())?=nil
modal:GetPropertyChangedSignal("Visible"):Connect(function() scrim.Visible=modal.Visible end)
scrim.Activated:Connect(function() if not busy then modal.Visible=false;modalInput:ReleaseFocus(false) end end)
cancel.Activated:Connect(function() if not busy then modal.Visible=false;modalInput:ReleaseFocus() end end)
confirm.Activated:Connect(function() if modalAction and not busy then modalAction(modalInput.Text) end end)
local function prompt(title: string,initial: string?,fn: (string)->())
    modalTitle.Text=title;modalInput.Text=initial or "";modalInput.Visible=initial~=nil
    persistentSelected=false
    persistentChoice.Visible=title=="채널 만들기"
    persistentChoice.Text="○  일반 채널 · 기록 저장 안 함"
    persistentChoice.BackgroundColor3=C.surface
    modalInfo.Position=UDim2.fromOffset(20,if persistentChoice.Visible then 165 else 118)
    modalInfo.Size=UDim2.new(1,-40,1,if persistentChoice.Visible then -230 else -184)
    modalInfo.Text=if persistentChoice.Visible then "영구 보관 채널은 공지·규칙처럼 재접속 후에도 글이 남습니다. 저장된 글은 최대 300개이며, 한도 도달 시 새 글을 저장할 수 없습니다."
        elseif initial==nil then "이 작업을 실행할까요? 삭제 후에는 해당 채널·역할이 즉시 제거됩니다." else "이름은 Roblox 필터를 거쳐 표시됩니다. 이름 생성·변경은 1분에 한 번 가능합니다."
    modalAction=fn;modal.Visible=true
    confirm.Text=if initial==nil then "확인" else "저장"
    confirm.BackgroundColor3=if initial==nil then C.red else C.accent
    if initial~=nil then modalInput:CaptureFocus() end
end
local function useData(data)
    if type(data)~="table" then return end
    state=data;plus.Visible=data.canCreate==true and data.storage.ready
    if not game:GetService("UserInputService"):GetFocusedTextBox() then render() end
end
local function call(action: string,payload: any?): boolean
    if busy then return false end
    busy=true;confirm.Active=false;status.Text="변경 사항을 확인하고 있습니다…";confirm.Text="처리 중…"
    if payload then payload.revision=state.revision end
    local ok,result=pcall(function() return remote:InvokeServer(action,payload) end)
    busy=false;confirm.Active=true;confirm.Text="저장"
    if not ok or type(result)~="table" then
        status.Text="서버 응답을 확인하지 못했습니다. 새로고침 후 확인하세요.";modalInfo.Text=status.Text;return false
    end
    if result.data then useData(result.data) end
    status.Text=result.message or (state.storage.ready and "변경 사항이 안전하게 저장됩니다." or state.storage.error)
    status.TextColor3=if result.ok then C.muted else Color3.fromRGB(244,167,167)
    if result.ok and action~="snapshot" and action~="refresh" then modal.Visible=false;modalInput:ReleaseFocus(false)
    else modalInfo.Text=status.Text end
    return result.ok==true
end
refresh=function() call("snapshot") end
local function row(value: string,fn: ()->(),color: Color3?): TextButton
    local b=button(body,value,value,color);b.Activated:Connect(fn);return b
end
local function note(value: string,height: number?)
    local label=text(body,value,height or 36)
    label.TextColor3=C.muted
end
local function permissionRow(value: string,enabled: boolean,fn: ()->())
    local line=make("Frame",body,{Name="PermissionRow",Size=UDim2.new(1,-8,0,50),BackgroundColor3=C.surface,BorderSizePixel=0,ZIndex=17})
    corner(line)
    local caption=text(line,value,50);caption.Position=UDim2.fromOffset(14,0);caption.Size=UDim2.new(1,-124,1,0)
    local toggle=button(line,"Toggle",if enabled then "✓ 허용" else "미허용",if enabled then C.accent else C.side)
    toggle.AnchorPoint=Vector2.new(1,0.5);toggle.Position=UDim2.new(1,-8,0.5,0);toggle.Size=UDim2.fromOffset(92,36)
    toggle.TextXAlignment=Enum.TextXAlignment.Center;toggle.ZIndex=18;toggle.Activated:Connect(fn)
end
local tabs={}
local function layout()
    local narrow=window.AbsoluteSize.X<600
    nav.Position=UDim2.fromOffset(0,0);nav.Size=if narrow then UDim2.new(1,0,0,80) else UDim2.new(0,144,1,-48)
    back.Position=UDim2.fromOffset(8,8);back.Size=UDim2.new(if narrow then 0 else 1,if narrow then 110 else -16,0,if narrow then 32 else 40)
    for i,b in tabs do
        b.Position=if narrow then UDim2.new((i-1)/4,4,0,40) else UDim2.fromOffset(8,64+(i-1)*50)
        b.Size=if narrow then UDim2.new(0.25,-8,0,36) else UDim2.new(1,-16,0,44)
    end
    heading.Position=if narrow then UDim2.fromOffset(16,84) else UDim2.fromOffset(176,12)
    heading.Size=if narrow then UDim2.new(1,-32,0,36) else UDim2.new(1,-192,0,36)
    body.Position=if narrow then UDim2.fromOffset(16,120) else UDim2.fromOffset(176,60)
    body.Size=if narrow then UDim2.new(1,-32,1,-170) else UDim2.new(1,-192,1,-110)
end
for i,spec in {{"channels","채널"},{"roles","역할"},{"people","사용자"},{"settings","저장 상태"}} do
    local b=button(nav,"Tab_"..spec[1],spec[2]);tabs[i]=b
    b.Activated:Connect(function() page=spec[1];render() end)
end
back.Activated:Connect(function() overlay.Visible=false;modal.Visible=false end)
window:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout);layout()
local perms={{"SEND_MESSAGES","메시지 쓰기"},{"CREATE_CHANNELS","채널 생성"},{"DELETE_CHANNELS","채널 삭제"},{"MANAGE_ROLES","역할 관리"},
    {"MANAGE_SETTINGS","통신망 관리"},{"POST_NOTICES","공지 작성"},{"VIEW_COMMAND","지휘 읽기"},{"WRITE_COMMAND","지휘 쓰기"}}
local function roleIds()
    local ids={};for id in state.permissions.roles do table.insert(ids,id) end;table.sort(ids);return ids
end
render=function()
    heading.Text=({channels="채널 설정",roles="역할과 권한",people="사용자 역할",settings="저장 및 동기화"})[page]
    body.CanvasPosition=Vector2.zero
    for _,child in body:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
    for i,spec in {{"channels","채널"},{"roles","역할"},{"people","사용자"},{"settings","저장 상태"}} do tabs[i].BackgroundColor3=if page==spec[1] then C.accent else C.surface end
    if not state.storage.ready then
        note(state.storage.error or "저장소 연결 중입니다.",90)
        row("저장소 다시 연결",function() call("refresh") end)
        return
    end
    if page=="channels" then
        note("채널 설정  /  이름 · 접근 권한",40)
        if state.canCreate then row("+ 채널 만들기",function() prompt("채널 만들기","",function(name)
            call("create_channel",{name=name,persistent=persistentSelected})
        end) end,C.accent) end
        local entry=nil
        for _,channel in state.channels do
            if channel.canManage then
                row((if selectedChannel==channel.id then "●  " else "#  ")..channel.name,function() selectedChannel=channel.id;render() end)
                if channel.id==selectedChannel then entry=channel end
            end
        end
        if not entry then note("관리할 채널을 선택하세요.");return end
        note("# "..entry.name.." 설정",40)
        note("채팅 기록: "..(if entry.persistent then "영구 저장 (최대 300개)" else "일시적 · 재접속 시 소멸"),32)
        if state.canManageSettings then
            row(if entry.persistent then "영구 저장 끄기" else "영구 저장 켜기",function()
                call("set_channel_persistence",{id=entry.id,persistent=not entry.persistent})
            end)
        end
        row("채널 이름 변경",function() prompt("채널 이름 변경",entry.name,function(name) call("rename_channel",{id=entry.id,name=name}) end) end)
        if not entry.builtin then row("채널 삭제",function() prompt("채널 삭제",nil,function() call("delete_channel",{id=entry.id}) end) end,C.red) end
        note("역할 허용은 합산됩니다. 비공개 채널은 member 읽기를 먼저 해제하세요.",46)
        for _,id in roleIds() do
            local role=state.permissions.roles[id]
            note(role.name,32)
            for _,spec in {{"read","읽기"},{"write","쓰기"},{"manage","관리"}} do
                local value=entry.acl[spec[1]][id]==true
                permissionRow(spec[2],value,function() call("set_channel_access",{id=entry.id,roleId=id,mode=spec[1],enabled=not value}) end)
            end
        end
    elseif page=="roles" then
        if not state.canManageRoles then note("역할 관리 권한이 없습니다.");return end
        note("역할 관리",40)
        for _,id in roleIds() do row((if selectedRole==id then "●  " else "○  ")..state.permissions.roles[id].name,function() selectedRole=id;render() end) end
        local role=state.permissions.roles[selectedRole]
        if role then
            note("선택: "..role.name.."  / "..selectedRole,40)
            if role.protected then note("기본 역할은 수정·삭제할 수 없습니다.",40)
            else
                row("역할 이름 변경",function() prompt("역할 이름 변경",role.name,function(name) call("rename_role",{roleId=selectedRole,name=name}) end) end)
                for _,spec in perms do permissionRow(spec[2],role.permissions[spec[1]]==true,function() call("set_permission",{roleId=selectedRole,permission=spec[1],enabled=not role.permissions[spec[1]]}) end) end
                row("역할 삭제",function() prompt("역할 삭제",nil,function() if call("delete_role",{roleId=selectedRole}) then selectedRole="member";render() end end) end,C.red)
            end
        end
        note("새 역할 · ID는 영문 소문자/숫자/밑줄 3~24자",44)
        local roleId=input(body,"예: medic")
        local roleName=input(body,"역할 표시 이름")
        row("+ 역할 생성",function() call("create_role",{roleId=roleId.Text,name=roleName.Text,permissions={}}) end,C.accent)
    elseif page=="people" then
        if not state.canManageRoles then note("역할 배정 권한이 없습니다.");return end
        note("부여할 역할을 먼저 선택하세요.",32)
        for _,id in roleIds() do
            if id~="member" and id~="officer" then
                row((if selectedRole==id then "●  " else "○  ")..state.permissions.roles[id].name,function() selectedRole=id;render() end,if selectedRole==id then C.accent else nil)
            end
        end
        if selectedRole=="member" or selectedRole=="officer" or not state.permissions.roles[selectedRole] then
            note("일반 사용자·장교 역할은 자동으로 적용됩니다. 위에서 수동 역할을 선택하세요.",64);return
        end
        note("선택한 역할: "..state.permissions.roles[selectedRole].name,40)
        for _,person in state.permissions.people do
            local assigned=table.find(person.roles,selectedRole)~=nil
            row("@"..person.name.."  · "..(if assigned then "역할 제거" else "역할 부여"),function() call(if assigned then "remove_role" else "assign_role",{userId=person.userId,roleId=selectedRole}) end)
        end
        note("오프라인 사용자도 Roblox 숫자 UserId로 배정할 수 있습니다.",46)
        local userId=input(body,"숫자 UserId")
        row("선택 역할 부여",function() call("assign_role",{userId=tonumber(userId.Text),roleId=selectedRole}) end,C.accent)
        row("선택 역할 제거",function() call("remove_role",{userId=tonumber(userId.Text),roleId=selectedRole}) end)
    else
        note("저장소 연결 완료 · 리비전 "..state.revision,40)
        note("저장소: "..state.storage.store,46)
        note("채널·권한 설정은 영구 저장됩니다. 영구 보관을 켠 채널의 글만 별도 DataStore에 저장되며, 일반 채팅 기록은 저장하지 않습니다.",76)
        note("서버 간 변경은 알림과 주기적 새로고침으로 반영됩니다. 동시 수정은 충돌 시 거부됩니다.",80)
        row("최신 저장 데이터 새로고침",function() call("refresh") end)
    end
end
plus.Activated:Connect(function()
    if state.canCreate and state.storage.ready then prompt("채널 만들기","",function(name)
        call("create_channel",{name=name,persistent=persistentSelected})
    end) end
end)
open.Activated:Connect(function()
    overlay.Visible=not overlay.Visible
    if overlay.Visible then selectedChannel=window:GetAttribute("SelectedChannel") or selectedChannel;refresh() end
end)
changed.OnClientEvent:Connect(function() task.delay(0.65,refresh) end)
window:GetPropertyChangedSignal("Visible"):Connect(function() if not window.Visible then modal.Visible=false;overlay.Visible=false;modalInput:ReleaseFocus(false) end end)
render();plus.Visible=false
task.delay(0.6,refresh)
