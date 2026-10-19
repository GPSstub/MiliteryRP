--!strict
local Parser=require("../src/server/RankCommandParser")
assert(assert(Parser.parse("/계급 대위")).rank=="대위")
assert(assert(Parser.parse("/rank general")).rank=="general")
assert(assert(Parser.parse("/계급 pikachu6361phw 병장")).target=="pikachu6361phw")
assert(assert(Parser.parse(" /계급   나   원사  ")).rank=="원사")
assert(assert(Parser.parse("/계급목록")).kind=="list")
assert(assert(Parser.parse("/ranks")).kind=="list")
for _,value in {"", "/계급", "/rank a b c", "/ranks bad", "/evil 대장", string.rep("x",257)} do
    assert(Parser.parse(value)==nil)
end
assert(Parser.parse({})==nil)
assert(Parser.parse(123)==nil)
assert(Parser.parse(nil)==nil)
print("PASS: self/target/Korean/English/list command parsing and malformed input rejection")
