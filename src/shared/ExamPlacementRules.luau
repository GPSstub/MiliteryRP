--!strict
-- Bounded editor settings. Missing attributes keep legacy point behavior.
local Placement={}
function Placement.spacing(value: any): number
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return 4 end
    return math.clamp(value,3,10)
end
function Placement.height(value: any): number
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return 0 end
    return math.clamp(value,0,20)
end
return table.freeze(Placement)
