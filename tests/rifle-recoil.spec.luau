--!strict
local Spring=require("../src/shared/RifleRecoilSpring")
local x,v=0,Spring.KICK
local max=0
local peakStep=0
local samples={}
for frame=1,240 do
    x,v=Spring.step(x,v,1/60)
    assert(x==x and v==v,"NaN in recoil spring")
    if x>max then max=x;peakStep=frame end
    samples[frame]=x
end
assert(max>0.25 and max<0.7,"Kick amplitude unexpected")
assert(peakStep>1 and peakStep<12,"Recoil must rise smoothly over multiple frames")
assert(samples[1]<samples[peakStep] and samples[peakStep+4]<samples[peakStep],
    "Must rise before returning")
for i=peakStep+1,240 do
    assert(samples[i]>=-0.0001,"Critically damped recoil should not overshoot")
end
assert(x==0 and v==0,"Recoil should settle at neutral grip")
local x2,v2=0,Spring.KICK
for i=1,120 do x2,v2=Spring.step(x2,v2,1/30) end
assert(x2==0 and v2==0,"Must settle at 30 FPS too")
print("PASS: smooth rise, gradual fall, zero overshoot, stable 30/60 FPS spring recoil")
