--!strict
local Policy=require("../src/server/AdminGroupPolicy")
local count=0
local function check(ok: any,message: string)
    count+=1
    assert(ok,message)
end

check(Policy.GROUP_ID==1101574390,"Configured Roblox group ID")
check(Policy.MIN_ADMIN_RANK==200,"Group admin minimum rank")
for _,rank in {0,1,50,100,199} do
    check(not Policy.isAdminRank(rank),"Unprivileged role may not administer: "..rank)
end
for _,rank in {200,201,250,254,255} do
    check(Policy.isAdminRank(rank),"Admin role must work: "..rank)
end
for _,rank in {-1,255.1,256,"255",true,nil,math.huge,0/0} do
    check(not Policy.isAdminRank(rank),"Invalid rank must never grant admin access")
end
check(Policy.rankFromRoles({IsMember=false,Roles={}})==0,"Nonmembers must rank zero")
check(Policy.rankFromRoles({IsMember=true,Roles={{Rank=150},{Rank=220}}})==220,
    "Account with multiple group roles gets highest allowed rank")
check(Policy.rankFromRoles({IsMember=true,Roles={{Rank=199},{Rank=199}}})==199,
    "Ordinary multiple-role member must not get admin access")
check(Policy.rankFromRoles({IsMember=true,Roles={{Rank="255"},{Rank=200}}})==200,
    "Malformed role must not grant more privilege")
check(Policy.rankFromRoles({IsMember=true,Roles={{Rank=255}}})==255,
    "Group owner rank is recognized")
check(Policy.rankFromRoles({IsMember=false,Roles={{Rank=255}}})==0,
    "Membership check must prevail over role data")
check(Policy.rankFromRoles({})==nil,"Missing group data should fail closed")
check(Policy.rankFromRoles({IsMember=true})==nil,"Missing roles should fail closed")
check(Policy.rankFromRoles({IsMember="true",Roles={}})==nil,
    "Malformed membership field should fail closed")
check(Policy.rankFromRoles(nil)==nil,"Unavailable API response should fail closed")
print("Roblox group administration policy passed "..count.." assertions")
