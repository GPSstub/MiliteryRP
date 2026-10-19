-- Append to MessengerAdmin in a temporary play-mode LocalScript only.
-- Uses a local fake RemoteFunction adapter; no persistent changes are sent.
task.wait(1.5)
local checks=0
local function check(value,message) checks+=1;assert(value,message) end
check(state.storage.ready,"Real snapshot did not load")
check(#tabs==6,"Missing settings navigation")
page="user";render()
check(heading.Text=="내 메신저 설정","User settings not rendered")
gui:SetAttribute("MessageFontSize",18)
check(gui:GetAttribute("MessageFontSize")==18,"Font preference failed")
local beforeRevision=state.revision
local succeeded=false
remote={InvokeServer=function(_,action,payload)
    if action=="batch_settings" then
        if not succeeded then return {ok=false,message="저장 실패 테스트",data=copy(latestSnapshot)} end
        local result=copy(state);result.revision+=1;return {ok=true,message="저장 완료",data=result}
    end
    return {ok=true,data=copy(latestSnapshot)}
end}
page="channels";selectedChannel="general";render()
queue({action="set_overwrite",scope="channel",id="general",roleId="member",mode="read",value="deny"})
check(#pendingOperations==1 and saveDraft.Visible and resetDraft.Visible,"Dirty footer missing")
check(state.revision==beforeRevision,"Local editing changed server revision")
queue({action="set_overwrite",scope="channel",id="general",roleId="member",mode="read",value="allow"})
check(#pendingOperations==1,"Same field edit was not coalesced")
local operations={};for _,entry in pendingOperations do table.insert(operations,entry.op) end
check(not call("batch_settings",{operations=operations}),"Fake failure should fail")
check(#pendingOperations==1 and saveDraft.Visible,"Failed save discarded edits")
succeeded=true
check(call("batch_settings",{operations=operations}),"Fake success should succeed")
check(#pendingOperations==0 and not saveDraft.Visible,"Successful save did not clear dirty state")
check(state.revision==beforeRevision+1,"Successful batch revision incorrect")
state.categories={{id="cat_ui",name="훈련 통신",order=1,acl={read={member=true},write={member=true},manage={operator=true}},overwrites={read={},write={},manage={}}}}
state.canManageSettings=true
selectedCategory="cat_ui";page="categories";render()
local choices=0
for _,o in body:GetDescendants() do if o:IsA("TextButton") and (o.Name=="allow" or o.Name=="deny" or o.Name=="inherit") then choices+=1 end end
check(choices==#roleIds()*9,"Tri-state category permission rows missing")
overlay.Size=UDim2.fromOffset(390,600)
layout()
page="user";render()
gui:SetAttribute("SettingsRegressionAssertions",checks)
gui:SetAttribute("SettingsRegressionPassed",true)
print("Settings UI regression passed: "..checks.." assertions")
