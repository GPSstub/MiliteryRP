--!strict
local Parser=require("../src/server/AdminPlayerCommandParser")
local passed=0
local function check(value: any,reason: string)
    passed+=1
    assert(value,reason)
end

local cases={
    {";to TargetPlayer","to","TargetPlayer"},
    {";TO TargetPlayer","to","TargetPlayer"},
    {";here player_2","here","player_2"},
    {";kill 나","kill","나"},
    {" ;kill   me ","kill","me"},
    {";폭발 Soldier_123","explode","Soldier_123"},
    {";explode TargetPlayer","explode","TargetPlayer"},
    {";EXPLODE TargetPlayer","explode","TargetPlayer"},
    {";to Risa","to","Risa"},
    {";here 철수","here","철수"},
    {";kill 파란 거북이","kill","파란 거북이"},
    {";폭발 \"Sora The Cat\"","explode","Sora The Cat"},
    {";to A","to","A"},
    {";here Ab","here","Ab"},
}
for _,case in cases do
    local result=Parser.parse(case[1])
    check(result~=nil,"Expected command to parse: "..case[1])
    check(result.kind==case[2],"Wrong action for "..case[1])
    check(result.target==case[3],"Wrong target for "..case[1])
end
for _,verb in {";to",";here",";kill",";폭발",";explode"} do
    check(Parser.isVerb(verb),"Verb must be recognized: "..verb)
end
for _,input in {
    "",";",";to",";here",";kill",";폭발",
    ";kill all",";kill everyone",";to 모두",";here 전체",
    "normal text", "to TargetPlayer",
    "/to TargetPlayer","/kill TargetPlayer",
    ";unknown TargetPlayer",string.rep("a",257),
    ";to "..string.rep("a",101),
} do
    check(Parser.parse(input)==nil,"Invalid input accepted: "..input)
end
check(not Parser.isVerb(";teams"),"Other admin commands aren't player actions")
check(not Parser.isVerb({}),"Verb cannot be a table")
check(Parser.parse({})==nil,"Structured input rejected")
check(Parser.parse(24)==nil,"Numbers rejected")
check(Parser.parse(nil)==nil,"Nil rejected")
print("HQ player command parser passed: "..passed.." assertions")
