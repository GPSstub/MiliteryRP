--!strict
-- Critically damped recoil spring, independent of frame rate and Roblox services.
-- v is kicked upward; x rises and naturally eases back to zero without snapping.
local Spring={}
Spring.OMEGA=19
Spring.KICK=22
function Spring.step(position: number,velocity: number,dt: number): (number,number)
    local omega=Spring.OMEGA
    local t=math.clamp(dt,0,0.08)
    local decay=math.exp(-omega*t)
    local factor=velocity+omega*position
    local x=(position+factor*t)*decay
    local v=(velocity-omega*factor*t)*decay
    if math.abs(x)<0.00005 and math.abs(v)<0.0005 then return 0,0 end
    return x,v
end
return table.freeze(Spring)
