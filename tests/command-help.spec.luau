--!strict
local Help = require("../src/shared/CommandHelpCatalog")
assert(type(Help.Sections)=="table")
local expected={
    ";계급", ";rank", ";계급목록", ";ranks",
    ";팀", ";team", ";무적", ";god", ";비행", ";fly",
    ";to", ";here", ";kill", ";폭발", ";explode", ";?", ";help",
}
local content=""
local groups=0
local count=0
for _,section in Help.Sections do
    groups+=1
    assert(type(section.title)=="string" and #section.title>0)
    assert(type(section.entries)=="table")
    for _,entry in section.entries do
        count+=1
        assert(type(entry.syntax)=="string" and #entry.syntax>0)
        assert(type(entry.description)=="string" and #entry.description>0)
        content..=entry.syntax.."\n"
    end
end
for _,alias in expected do
    assert(string.find(content,alias,1,true)~=nil,"Missing command in GUI: "..alias)
end
assert(groups==3 and count>=11,"Help sections or command list incomplete")
print("PASS: documented aliases and help list ("..count.." commands)")
