--!strict
local Parser=require("../src/server/RankCommandParser")

assert(assert(Parser.parse(";계급 대위")).rank=="대위")
assert(assert(Parser.parse(";계급 admin")).rank=="admin")
assert(assert(Parser.parse(";계급 나 admin")).rank=="admin")
assert(assert(Parser.parse(";rank admin")).rank=="admin")
assert(assert(Parser.parse(";rank general")).rank=="general")
assert(assert(Parser.parse(";계급 pikachu6361phw 병장")).target=="pikachu6361phw")
assert(assert(Parser.parse(" ;계급   나   원사  ")).rank=="원사")
assert(assert(Parser.parse(";계급목록")).kind=="list")
assert(assert(Parser.parse(";ranks")).kind=="list")
assert(assert(Parser.parse(";RANK captain")).rank=="captain")
assert(assert(Parser.parse(";RANKS")).kind=="list")
assert(assert(Parser.parse(";계급 철수 대위")).target=="철수")
assert(assert(Parser.parse(";계급 리사 병장")).target=="리사")
assert(assert(Parser.parse(";계급 파란 거북이 대위")).target=="파란 거북이")
assert(assert(Parser.parse(";rank Sora The Cat captain")).target=="Sora The Cat")
assert(assert(Parser.parse(';계급 "파란 거북이" 대위')).target=="파란 거북이")
assert(assert(Parser.parse(";계급 Risa captain")).rank=="captain")

for _,value in {
    "",";", ";계급",";ranks bad",
    ";evil 대장",";계급목록 더보기",";계급목록x",
    "/계급 대위","/계급목록","/rank captain",
    "반갑습니다",";계급대위",string.rep("x",257),
} do
    assert(Parser.parse(value)==nil,"Rejected input parsed unexpectedly: "..value)
end
assert(Parser.parse({})==nil)
assert(Parser.parse(123)==nil)
assert(Parser.parse(nil)==nil)
print("PASS: semicolon HQ rank commands, aliases, targets, and slash command rejection")
