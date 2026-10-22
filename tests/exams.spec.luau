--!strict
local Rules=require("../src/shared/ExamRules")
local assertions=0
local function check(ok: any,message: string)
    assertions+=1
    assert(ok,message)
end
local board=Rules.new()
local host={userId=1,canHost=true}
local otherHost={userId=2,canHost=true}
local regular={userId=200,canHost=false,rankId="private"}
local rankCategories={"위관","영관","장관"}
for _,category in rankCategories do
    check(Rules.canHost({category=category}),"Officer category must host: "..category)
end
for _,category in {"훈련병","병","부사관","준사관"} do
    check(not Rules.canHost({category=category}),"Lower ranks must not host")
end
check(not Rules.canHost(nil),"Nil rank cannot host")
local studio=Rules.new()
local studioCreated=Rules.apply(studio,{userId=-1,canHost=true},"create","private",nil,1700000000)
check(studioCreated~=nil and Rules.valid(studioCreated),"Studio mock negative UserId can host")
local studioJoined=Rules.apply(studioCreated,{userId=-2,canHost=false,rankId="private"},"join",nil,"exam_1",1700000000)
check(studioJoined~=nil and studioJoined.sessions[1].participants[-2],
    "Studio mock negative UserId can join")
check(#Rules.TARGET_IDS==8,"There should be exactly eight exam target ranks")
check(Rules.MAX_PARTICIPANTS==10,"Each exam must allow exactly ten attendees")
for _,id in Rules.TARGET_IDS do check(Rules.isTarget(id),"Invalid target in published catalog") end
for _,id in {"trainee","warrant_officer","captain","major","general","fake"} do
    check(not Rules.isTarget(id),"Disallowed target: "..id)
end
local function apply(actor: any,action: string,targetId: any?,examId: any?)
    local updated,message=Rules.apply(board,actor,action,targetId,examId,1700000000)
    check(updated~=nil,message)
    board=updated
    check(Rules.valid(board),"Invalid board after "..action)
end
check(Rules.valid(board),"Empty board should be valid")
check(not Rules.apply(board,regular,"create","private"),"Non officer must not create")
check(not Rules.apply(board,host,"create","captain"),"Outside target range rejected")
apply(host,"create","private")
check(board.revision==1 and #board.sessions==1,"First session created")
check(board.sessions[1].targetId=="private","Wrong target rank")
local anotherHosted=Rules.apply(board,host,"create","private_first_class")
check(anotherHosted==nil,"A host may only organize one exam")
apply(regular,"join",nil,"exam_1")
check(board.sessions[1].participants[200],"Attendee should be listed")
check(not Rules.apply(board,regular,"join",nil,"exam_1"),"Duplicate join denied")
check(not Rules.apply(board,host,"join",nil,"exam_1"),"Host cannot attend own exam")
check(not Rules.apply(board,regular,"close",nil,"exam_1"),"Participant cannot close")
check(not Rules.apply(board,regular,"leave",nil,"exam_999"),"Unknown exam should fail")
apply(otherHost,"create","corporal")
check(not Rules.apply(board,regular,"join",nil,"exam_2"),"Only one joined exam at a time")
apply(regular,"leave",nil,"exam_1")
check(not board.sessions[1].participants[200],"Leave should remove attendee")
check(not Rules.apply(board,regular,"join",nil,"exam_2"),"Wrong rank cannot join")
regular.rankId="corporal"
apply(regular,"join",nil,"exam_2")
check(board.sessions[2].participants[200],"Can join another after leaving")
check(not Rules.apply(board,host,"join",nil,"exam_2"),"Hosting prevents joining another exam")
check(not Rules.apply(board,{userId=200,canHost=true,rankId="corporal"},"create","private"),"Attending prevents hosting")
local newcomer={userId=3,canHost=true}
apply(newcomer,"create","sergeant")
for id=4,6 do apply({userId=id,canHost=true},"create","sergeant_major") end
check(#board.sessions==6,"Exactly six live exams")
check(not Rules.apply(board,{userId=7,canHost=true},"create","staff_sergeant"),
    "Seventh simultaneous exam should fail")
check(not Rules.apply(board,regular,"create","private"),"Bypass capacity and permission denied")
check(not Rules.apply(board,regular,"delete",nil,"exam_2"),"Unknown action rejected")
local preRemove=board
local cleaned,did=Rules.removePlayer(board,2)
check(did and cleaned~=preRemove and #cleaned.sessions==5,"Host disconnect must close exam")
check(board.revision==preRemove.revision and #board.sessions==6,"State must remain immutable")
check(not cleaned.sessions[2].participants[200],"Joined exam closed on host disconnect")
board=cleaned
apply({userId=7,canHost=true},"create","sergeant_first_class")
check(#board.sessions==6,"Freed slot should be reusable")
local withJoins=board
local cleanedAttendee,removed=Rules.removePlayer(board,200)
check(not removed,"Already removed participant should have no effect")
check(cleanedAttendee.revision==withJoins.revision,"No-change disconnect should not bump revision")
regular.rankId="private"
apply(regular,"join",nil,"exam_1")
local afterLeave,changed=Rules.removePlayer(board,200)
check(changed and afterLeave.sessions[1].participants[200]==nil,
    "Disconnect removes attendee")
check(afterLeave.revision==board.revision+1,"Disconnect must publish revision")
board=afterLeave
apply(host,"close",nil,"exam_1")
check(#board.sessions==5,"Host can end exam")
check(not Rules.apply(board,regular,"join",nil,"exam_1"),"Closed exam cannot be joined")
check(not Rules.apply(board,{userId=0,canHost=true},"create","private"),"Invalid actor denied")
local reopened=Rules.apply(board,host,"create","private")
check(reopened~=nil,"Host can create after closing")
for _,id in Rules.TARGET_IDS do
    local single=Rules.apply(Rules.new(),host,"create",id)
    check(Rules.apply(single,{userId=20,rankId=id},"join",nil,"exam_1")~=nil,"Matching rank joins "..id)
    check(not Rules.apply(single,{userId=20,rankId="trainee"},"join",nil,"exam_1"),"Other rank denied "..id)
    check(not Rules.apply(single,{userId=20},"join",nil,"exam_1"),"Unloaded rank denied "..id)
end
-- Participant cap is per exam and does not count the host.
local capacityBoard=Rules.apply(Rules.new(),host,"create","private")
check(capacityBoard~=nil,"Capacity test exam created")
for userId=101,110 do
    local nextBoard,message=Rules.apply(capacityBoard,{userId=userId,rankId="private"},"join",nil,"exam_1")
    check(nextBoard~=nil,"First ten attendees can join: "..tostring(message))
    capacityBoard=nextBoard
end
check(Rules.valid(capacityBoard),"Exactly ten participants is valid")
check(not Rules.apply(capacityBoard,{userId=111,rankId="private"},"join",nil,"exam_1"),
    "Eleventh attendee must be rejected")
local vacancy,removedOne=Rules.removePlayer(capacityBoard,110)
check(removedOne and Rules.valid(vacancy),"Participant departure reopens a slot")
check(Rules.apply(vacancy,{userId=111,rankId="private"},"join",nil,"exam_1")~=nil,
    "Eleventh attendee can join after a spot becomes available")
capacityBoard.sessions[1].participants[111]=true
check(not Rules.valid(capacityBoard),"Over-capacity state must be rejected")

print("Exam board rules passed "..assertions.." assertions")
