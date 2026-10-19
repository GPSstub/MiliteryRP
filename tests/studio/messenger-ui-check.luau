-- Studio-only regression harness. Append to MilitaryMessenger source in a temporary
-- runtime LocalScript; never deploy this harness or bypass TextChatService in production.
local assertions = 0
local function check(value, message)
    assert(value, message)
    assertions += 1
end
local function fakeMessage(index)
    return {TextChannel={Name="RP_General"},TextSource={UserId=player.UserId+1},
        Status=Enum.TextChatMessageStatus.Success,MessageId="ui-regression-"..index,
        Text="통신 상태 확인 "..index}
end
task.wait(2)
channelAccess.general={canRead=true,canWrite=true}
channelAccess.notice={canRead=true,canWrite=true}
setOpen(true)
for i=1,45 do receiveMessage(fakeMessage(i)) end
task.wait(.3)
feed.CanvasPosition=Vector2.new(0,180)
task.wait(.1)
local before=feed.CanvasPosition.Y
receiveMessage(fakeMessage(46))
task.wait(.3)
check(math.abs(feed.CanvasPosition.Y-before)<2,"Incoming message moved reading position")
check(newMessages.Visible and newMessages.Text:find("46"),"New-message notice missing")
check(unread.general==46,"Unread count mismatch")
receiveMessage(fakeMessage(46))
check(#history.general==46,"Duplicate message was rendered")
input.Text="임시 작성"
selectChannel("notice")
input.Text="공지 작성"
selectChannel("general")
check(input.Text=="임시 작성","Draft lost on channel switch")
task.wait(.2)
check(math.abs(feed.CanvasPosition.Y-before)<2,"Channel switch lost scroll position")
messageSearch.Text="존재하지않는검색어"
task.wait(.2)
check(feed:FindFirstChild("EmptyState")~=nil,"Search empty state missing")
messageSearch.Text="통신 상태 확인 46"
task.wait(.2)
local count=0
for _,child in feed:GetChildren() do if child:IsA("Frame") and child.Name=="Message" then count+=1 end end
check(count==1,"Local message search incorrect")
messageSearch.Text=""
task.wait(.2)
setOpen(false)
receiveMessage(fakeMessage(47))
setOpen(true)
task.wait(.3)
check(#history.general==47 and newMessages.Visible,"Closed-window delivery lost")
for i=48,310 do receiveMessage(fakeMessage(i)) end
task.wait(.3)
check(#history.general==300,"History memory cap exceeded")
count=0
for _,child in feed:GetChildren() do if child:IsA("Frame") and child.Name=="Message" then count+=1 end end
check(count==300,"Visible message memory cap exceeded")
-- Exercise filtered-message UI protocol; this fake input is only for Studio harness use.
local root=history.general[#history.general]
local edited=fakeMessage(311)
edited.Metadata=assert(Protocol.encode("e","ui-regression-311",root.id))
edited.Text="새로 수정한 필터된 텍스트"
receiveMessage(edited)
check(root.message=="새로 수정한 필터된 텍스트" and root.edited,"Edit UI did not replace filtered text")
local reply=fakeMessage(312)
reply.Metadata=assert(Protocol.encode("r","ui-regression-312",root.id))
receiveMessage(reply)
check(history.general[#history.general].replyTo==root.id,"Reply metadata not applied")
local threadMessage=fakeMessage(313)
threadMessage.Metadata=assert(Protocol.encode("t","ui-regression-313",root.id))
receiveMessage(threadMessage)
check(root.threadCount==1,"Thread reply not grouped")
threadRoot=root.id
updateMode();renderMessages()
count=0
for _,child in feed:GetChildren() do
    if child:IsA("Frame") and child.Name=="Message" then count+=1 end
end
check(count==2,"Thread view must show root and thread reply only")
threadRoot=nil;updateMode();renderMessages()
root.pinned=true
messageSearch.Text="has:pin"
task.wait(.1)
count=0
for _,child in feed:GetChildren() do
    if child:IsA("Frame") and child.Name=="Message" then count+=1 end
end
check(count==1,"Pinned-message search failed")
messageSearch.Text=""
channelSearch.Text="전체"
task.wait(.1)
check(channelButtons.general.Visible and not channelButtons.notice.Visible,"Channel search incorrect")
channelSearch.Text=""
updateLayout(Vector2.new(390,844))
task.wait(.2)
check(channelToggle.Visible and not sidebar.Visible and center.Visible,"Mobile conversation layout incorrect")
drawerOpen=true
updateLayout(Vector2.new(390,844))
task.wait(.2)
check(sidebar.Visible and not center.Visible,"Mobile channel drawer incorrect")
drawerOpen=false
updateLayout()
gui:SetAttribute("RegressionAssertions",assertions)
gui:SetAttribute("RegressionPassed",true)
print("Messenger UI regression passed: "..assertions.." assertions")
