--!strict
-- Pure matching tests; no Roblox Studio services or live accounts required.
local Match=require("../src/server/AdminTargetMatch")
local pass=0
local function check(value: any,message: string)
    pass+=1
    assert(value,message)
end
local players={
    {UserId=201,Name="RisaGaming",DisplayName="철수"},
    {UserId=205,Name="RisaStudy",DisplayName="철수"},
    {UserId=207,Name="Cheolsoo123",DisplayName="민호"},
    {UserId=202,Name="SoraAlice",DisplayName="Sora"},
    {UserId=209,Name="SongBird",DisplayName="Sora The Cat"},
    {UserId=299,Name="BlueTurtle9",DisplayName="파란 거북이"},
}
local function ids(query: string): string
    local parts={}
    for _,player in Match.find(players,query) do
        table.insert(parts,tostring(player.UserId))
    end
    return table.concat(parts,",")
end

check(ids("risagaming")=="201","Exact case-insensitive username")
check(ids("@RisaGaming")=="201","@username exact match")
check(ids("철수")=="201,205","Duplicate DisplayNames must remain ambiguous")
check(ids("risa")=="201,205","Two username prefixes must remain ambiguous")
check(ids("SORA")=="202","Exact display name wins over prefixes")
check(ids("sora ")=="202","Whitespace is trimmed")
check(ids("거북")=="299","Substring Unicode DisplayName")
check(ids("파란 거")=="299","Prefix Unicode DisplayName with spaces")
check(ids('"파란 거북이"')=="299","Quoted multiword DisplayName")
check(ids("turtle")=="299","Username substring")
check(ids("nonexistent")=="","Unknown nickname matches nobody")
check(ids("@soraalice")=="202","Exact username is unambiguous")
check(ids("Sora")=="202","Exact DisplayName prioritized")
check(ids("blue")=="299","Case-insensitive username prefix")
check(ids("@Sora")=="202","Explicit @ syntax only matches account usernames")
check(ids("@철수")=="","DisplayNames must not match explicit @username syntax")
local collision={
    {UserId=11,Name="Hello",DisplayName="Different"},
    {UserId=12,Name="SomethingElse",DisplayName="Hello"},
}
check(#Match.find(collision,"Hello")==2,
    "Exact real usernames and display names with the same text must be disambiguated")
local explicit=Match.find(collision,"@Hello")
check(#explicit==1 and explicit[1].UserId==11,
    "@username must bypass ambiguous display-name collisions")

for _,invalid in {""," ","  ","all","ALL","everyone","모두","전체","\n","\t"} do
    check(not Match.validQuery(invalid),"Mass, empty and control queries must be rejected")
    check(#Match.find(players,invalid)==0,"Invalid queries must return no results")
end
check(not Match.validQuery(string.rep("x",101)),"Oversized display name rejected")
check(not Match.validQuery({}),"Table query rejected")
check(not Match.validQuery(nil),"Nil query rejected")
local original=Match.find(players,"철수")
check(#original==2 and original[1].UserId==201 and original[2].UserId==205,
    "Duplicate candidates have deterministic UserId order")
print("[Admin Target Match] PASS "..pass.." assertions")
