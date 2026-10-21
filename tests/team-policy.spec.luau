--!strict
local Policy=require("../src/server/TeamPolicy")
local Catalog=require("../src/shared/RankCatalog")
local count=0
local function check(value: any,why: string)
    count+=1
    assert(value,why)
end

local expected={"HQ","본부","장관급","영관급","위관급","부사관급","병사"}
check(#Policy.SPECS==#expected,"Exactly seven teams must exist")
local seen={}
local colors={}
for index,spec in Policy.SPECS do
    check(spec.name==expected[index],"Team ordering mismatch at position "..index)
    check(not seen[spec.name],"Team names must be unique")
    check(not colors[spec.color],"Team colors must be unique")
    seen[spec.name]=true
    colors[spec.color]=true
    check(Policy.isDefined(spec.name),"Declared team should be recognized")
end
check(Policy.isDefined("본부"),"Headquarters team missing")
check(not Policy.isDefined("사관급"),"Legacy incorrect team name")
check(not Policy.isDefined("전투병"),"No unrequested extra team")
check(not Policy.isDefined({}),"Invalid team name should fail")
check(Policy.teamForCategory("관리자")=="HQ","admin rank -> HQ")
check(Policy.teamForCategory("장관")=="장관급","General -> flag officers")
check(Policy.teamForCategory("영관")=="영관급","Major -> field officers")
check(Policy.teamForCategory("위관")=="위관급","Lieutenant -> officers")
check(Policy.teamForCategory("준사관")=="위관급","Warrant officer -> officers")
check(Policy.teamForCategory("부사관")=="부사관급","NCO -> NCO team")
check(Policy.teamForCategory("병")=="병사","Private -> soldiers")
check(Policy.teamForCategory("훈련병")=="병사","Trainee -> soldiers")
for _,category in {"본부","HQ","",nil} do
    check(Policy.teamForCategory(category)==nil,"Headquarters has no auto rank and unknown category has no fallback")
end
check(Policy.teamForCategory({})==nil,"Invalid rank category")
-- Verify the actual rank catalog is mapped, not just category string samples.
for _,rank in Catalog.All do
    check(Policy.isDefined(Policy.teamForCategory(rank.category)),rank.name.." must have an automatic team")
    if rank.id=="admin" then check(Policy.teamForCategory(rank.category)=="HQ","Saved admin rank joins HQ") end
    if rank.id=="warrant_officer" then check(Policy.teamForCategory(rank.category)=="위관급","Warrant officer joins 위관급") end
end
check(Policy.isHQ("HQ",false),"HQ membership should render the HQ badge")
check(not Policy.isHQ("HQ",true),"Neutral player should not render HQ badge")
for _,other in {"본부","장관급","영관급","위관급","부사관급","병사"} do
    check(not Policy.isHQ(other,false),other.." should not render HQ badge")
end
check(not Policy.isHQ(nil,false),"Unassigned player should not render HQ badge")
print("PASS: seven ordered teams, actual rank mappings, HQ display: "..count.." assertions")
