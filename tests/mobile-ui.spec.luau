--!strict
local Rules=require("../src/shared/MobileUIRules")
local function verify(w,h,touch)
    local config=Rules.forViewport(w,h,touch)
    assert(config.scale>0.7 and config.scale<=1)
    assert(config.widthCoverage>0 and config.widthCoverage<1)
    assert(config.heightCoverage>0 and config.heightCoverage<1)
    local logicalWidth=w*config.widthCoverage/config.scale
    local logicalHeight=h*config.heightCoverage/config.scale
    assert(math.abs(logicalWidth*config.scale-w*config.widthCoverage)<0.01)
    assert(math.abs(logicalHeight*config.scale-h*config.heightCoverage)<0.01)
    return config
end
local phone=verify(390,844,true)
assert(phone.compact and phone.scale<=0.82)
local smallPhone=verify(320,568,true)
assert(smallPhone.compact and smallPhone.scale<=phone.scale)
local landscape=verify(844,390,true)
assert(landscape.compact and landscape.scale<=0.82)
local tablet=verify(820,1180,true)
assert(tablet.compact and tablet.scale<=0.9)
local desktop=verify(1920,1080,false)
assert(not desktop.compact and desktop.scale==1)
local narrowDesktop=verify(600,420,false)
assert(narrowDesktop.compact)
print("PASS: adaptive mobile UI density and viewport fit math")
