--!strict
local Rules=require("../src/server/MessengerState")
local Core=require("../src/server/MessengerArchiveCore")
local assertions=0
local function check(value: any,why: string)
    assertions+=1;assert(value,why)
end
local owner={userId=Rules.OWNER,rankOrder=1}
local config=Rules.default()
check(Rules.isPersistent(config,"notice"),"Notices must persist by default")
check(not Rules.isPersistent(config,"general"),"Normal chat should be temporary")
check(Rules.valid(config),"Updated config must validate")
local old=Rules.copy(config)
old.channels.notice.persistent=nil
check(Rules.valid(old),"Legacy config must continue validating")
check(Rules.isPersistent(old,"notice"),"Legacy announcements must be permanent")
local newer,message=Rules.apply(config,owner,{
    action="create_channel",id="custom_rules",name="규칙",persistent=true,
})
check(newer~=nil,message)
config=newer
check(Rules.isPersistent(config,"custom_rules"),"New rules channel did not persist")
local temporary
temporary,message=Rules.apply(config,owner,{
    action="create_channel",id="custom_chat",name="자유 대화",persistent=false,
})
check(temporary~=nil,message)
config=temporary
check(not Rules.isPersistent(config,"custom_chat"),"Temporary choice ignored")
local changed
changed,message=Rules.apply(config,owner,{
    action="set_channel_persistence",id="custom_chat",persistent=true,
})
check(changed~=nil,message)
config=changed
check(Rules.isPersistent(config,"custom_chat"),"Mode setting not saved")
check(Rules.valid(config),"Boolean persistence broke config schema")
local invalid=Rules.copy(config)
invalid.channels.custom_chat.persistent="yes"
check(not Rules.valid(invalid),"Malformed persistence value accepted")
local nonOwner={userId=99,rankOrder=1}
local refused=Rules.apply(config,nonOwner,{
    action="set_channel_persistence",id="custom_chat",persistent=false,
})
check(not refused,"Member must not edit persistence settings")
local record=Core.empty()
check(Core.valid(record),"Empty archive must validate")
local function post(n: number,replyTo: string?): boolean
    local entry={id="persistent_"..n,authorId=123,name="작성자",rank="소위",
        text="공지 "..n,time=1700000000+n,timeLabel="12:00",date="2026-10-20",
        replyTo=replyTo}
    local result,why=Core.apply(record,{action="append",id=entry.id,entry=entry})
    if not result then return false end
    record=result
    return true
end
for i=1,75 do check(post(i),"Unable to save post "..i) end
check(Core.valid(record),"Stored archive invalid")
local page=Core.page(record,123,nil,40)
check(#page.entries==40,"Initial page size should be 40")
check(page.entries[1].id=="persistent_36" and page.entries[40].id=="persistent_75","Newest page out of order")
check(page.cursor==36,"Stable page cursor is wrong")
local older=Core.page(record,123,page.cursor,40)
check(#older.entries==35 and older.cursor==nil,"Older page should have 35 entries")
check(older.entries[1].id=="persistent_1","Archive earliest entry missing")
local bad=Core.apply(record,{action="append",id="persistent_bad",entry={
    id="persistent_bad",authorId=123,text="bad",time=1,replyTo="missing",name="Test",rank="Test",
}})
check(not bad,"Reply to a missing post must fail")
local edited=Core.apply(record,{action="edit",id="persistent_4",text="수정된 규칙",authorId=123,time=1800})
check(edited~=nil,"Author should be allowed to edit")
check(Core.find(record,"persistent_4").text=="공지 4","Edit mutated original snapshot")
record=edited
check(Core.find(record,"persistent_4").text=="수정된 규칙","Edit was not retained")
check(not Core.apply(record,{action="edit",id="persistent_4",text="악성",authorId=456,time=2}),
    "Nonauthor must not edit")
local reaction=Core.apply(record,{action="react",id="persistent_4",authorId=789,emoji="👍"})
check(reaction~=nil,"Reaction failed")
record=reaction
page=Core.page(record,789,5,40)
check(page.entries[4].reactions["👍"].mine==true,"Viewer own reaction should be marked")
local unreact=Core.apply(record,{action="react",id="persistent_4",authorId=789,emoji="👍"})
check(unreact~=nil,"Reaction toggle off failed")
record=unreact
check(not Core.page(record,789,5,40).entries[4].reactions["👍"],"Reaction toggle off did not persist")
check(not Core.apply(record,{action="pin",id="persistent_4",moderator=false}),"Member cannot pin")
local pinned=Core.apply(record,{action="pin",id="persistent_4",moderator=true})
check(pinned~=nil,"Moderator pin failed")
record=pinned
check(Core.find(record,"persistent_4").pinned,"Pin flag should persist")
check(not Core.apply(record,{action="delete",id="persistent_4",authorId=456,moderator=false}),
    "Cannot delete another person's notice")
local removed=Core.apply(record,{action="delete",id="persistent_4",authorId=456,moderator=true})
check(removed~=nil,"Moderator delete failed")
record=removed
check(Core.find(record,"persistent_4")==nil,"Deleted post is still retrievable")
check(Core.valid(record),"Archive invalid after mutation")
for i=76,301 do
    local result=post(i)
    if i<=301 then check(result,"Archive capacity not reached as expected") end
end
check(#record.entries==300,"Wrong maximum archive capacity")
check(not post(302),"Archive must reject overflow without eviction")
check(Core.find(record,"persistent_1")~=nil,"Overflow silently evicted oldest post")
local lastPage=Core.page(record,123,nil,40)
check(#lastPage.entries==40,"Pagination should remain usable after capacity reached")
-- Unit archives remain available, but entries are never readable or writable
-- from another unit; legacy entries with no unit have no verified scope.
local scoped=Core.empty()
local function scopedPost(id: string, unit: string)
    local entry={id=id,authorId=123,name="작성자",rank="병장",
        text="부대 기록",unit=unit,time=1700001000,timeLabel="12:00",date="2026-10-20"}
    scoped=assert(Core.apply(scoped,{action="append",id=id,entry=entry,scope=unit}))
end
scopedPost("unit_a_01","A")
scopedPost("unit_b_01","B")
check(#Core.page(scoped,123,nil,40,"A").entries==1,"A should see only A entries")
check(#Core.page(scoped,123,nil,40,"B").entries==1,"B should see only B entries")
check(Core.find(scoped,"unit_b_01","A")==nil,"Foreign unit lookup must be hidden")
check(not Core.apply(scoped,{action="edit",id="unit_b_01",text="wrong",authorId=123,scope="A"}),
    "Foreign unit edit must fail even if the author is the same")
check(not Core.apply(scoped,{action="delete",id="unit_b_01",authorId=123,moderator=true,scope="A"}),
    "Foreign unit delete must fail even for moderators")
check(not Core.apply(scoped,{action="append",id="unit_bad",scope="B",entry={
    id="unit_bad",authorId=123,name="작성자",rank="병장",unit="A",
    text="위장 기록",time=1700001000,timeLabel="12:00",date="2026-10-20",
}}),"Forged unit scope must fail")
local legacy=assert(Core.apply(scoped,{action="append",id="legacy_nil",entry={
    id="legacy_nil",authorId=123,name="작성자",rank="병장",
    text="구버전 기록",time=1700001000,timeLabel="12:00",date="2026-10-20",
}}))
check(Core.find(legacy,"legacy_nil","A")==nil,"Unscoped legacy unit records must remain private")
check(Core.valid(scoped),"Scoped unit archives must validate")
print("Permanent messenger archive tests passed: "..assertions.." assertions")
