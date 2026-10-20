--!strict
local Policy=require("../src/server/TeamPolicy")
local count=0
local function check(value: any,why: string)
    count+=1
    assert(value,why)
end

check(#Policy.SPECS==4,"Exactly four teams must exist")
local seen={}
local colors={}
for _,spec in Policy.SPECS do
    check(not seen[spec.name],"Team names must be unique")
    check(not colors[spec.color],"Team colors must be unique")
    seen[spec.name]=true
    colors[spec.color]=true
    check(Policy.isDefined(spec.name),"Declared team should be recognized")
end
check(Policy.isDefined("HQ"),"HQ team missing")
check(not Policy.isDefined("전투병"),"No unrequested extra team")
check(not Policy.isDefined({}),"Invalid team name should fail")
check(Policy.teamForCategory("위관")=="위관급","Lieutenant must join junior officers")
check(Policy.teamForCategory("영관")=="영관급","Major must join field officers")
check(Policy.teamForCategory("장관")=="장관급","General must join flag officers")
for _,category in {"훈련병","병","부사관","준사관","HQ",""} do
    check(Policy.teamForCategory(category)==nil,"Low ranks must not get an administrative team")
end
check(Policy.teamForCategory({})==nil,"Invalid rank category should fail")
check(Policy.isAdmin("HQ",false),"HQ active membership must authorize")
check(not Policy.isAdmin("HQ",true),"Neutral HQ team should not authorize")
check(not Policy.isAdmin("위관급",false),"Officer rank team must not authorize")
check(not Policy.isAdmin("영관급",false),"Field rank team must not authorize")
check(not Policy.isAdmin("장관급",false),"General rank team must not authorize")
check(not Policy.isAdmin(nil,false),"Unassigned player must not authorize")
print("HQ team policy tests passed: "..count.." assertions")
