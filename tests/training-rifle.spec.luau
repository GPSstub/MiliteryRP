--!strict
local Rules=require("../src/shared/TrainingRifleRules")
local s=Rules.new()
assert(s.ammo==30 and s.reserve==90)
local ok=Rules.tryFire(s,10)
assert(ok and s.ammo==29)
assert(not Rules.tryFire(s,10.05))
assert(s.ammo==29)
assert(Rules.tryFire(s,10.16))
assert(s.ammo==28)
assert(Rules.startReload(s,11))
assert(not Rules.startReload(s,11.1))
assert(not Rules.tryFire(s,12))
assert(not Rules.completeReload(s,12.7))
assert(Rules.completeReload(s,12.8))
assert(s.ammo==30 and s.reserve==88)
assert(not Rules.startReload(s,13))
local t=Rules.new()
for i=1,30 do
    local fired,message=Rules.tryFire(t,100+i*(Rules.SHOT_INTERVAL+0.01))
    assert(fired,message)
end
assert(t.ammo==0 and not Rules.tryFire(t,110))
assert(Rules.startReload(t,111))
assert(Rules.completeReload(t,113))
assert(t.ammo==30 and t.reserve==60)
for cycle=1,2 do
    for i=1,30 do
        assert(Rules.tryFire(t,120+cycle*10+i*(Rules.SHOT_INTERVAL+0.01)))
    end
    assert(Rules.startReload(t,120+cycle*10+8))
    assert(Rules.completeReload(t,120+cycle*10+10))
end
assert(t.ammo==30 and t.reserve==0)
for i=1,30 do assert(Rules.tryFire(t,200+i*(Rules.SHOT_INTERVAL+0.01))) end
assert(not Rules.startReload(t,210))
assert(t.ammo==0 and t.reserve==0)
print("PASS: training rifle ammo, cadence, reload, reserve exhaustion")

local unlimited=Rules.new(true)
unlimited.reserve=0
for cycle=1,10 do
    local now=300+cycle*10
    for i=1,30 do assert(Rules.tryFire(unlimited,now+i*0.17)) end
    assert(unlimited.ammo==0 and not Rules.tryFire(unlimited,now+6))
    assert(Rules.startReload(unlimited,now+6))
    assert(not Rules.tryFire(unlimited,now+7))
    assert(Rules.completeReload(unlimited,now+8))
    assert(unlimited.ammo==30 and unlimited.reserve==0)
end
print("PASS: unlimited reserve retains 30-round magazine, cadence and timed reload")
