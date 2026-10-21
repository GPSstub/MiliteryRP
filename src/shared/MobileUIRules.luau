--!strict
-- Shared UI density rules for mobile + small emulated viewports.
-- Pair UIScale with a larger logical frame so every input, label and spacing
-- shrinks proportionally while scrollable content retains its full extent.
local Rules={}
function Rules.forViewport(width: number,height: number,touch: boolean): any
    local compact=width<900 or height<580
    local cramped=width<480 or height<440
    local scale: number
    if compact and cramped then
        scale=if touch then 0.82 else 0.86
    elseif compact then
        scale=0.90
    elseif touch then
        scale=0.92
    else
        scale=1
    end
    return {
        compact=compact,
        scale=scale,
        widthCoverage=if compact then 0.92 else 0.94,
        heightCoverage=if compact then 0.88 else 0.94,
    }
end
return table.freeze(Rules)
