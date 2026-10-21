--!strict
local Rules=require("../src/shared/FlightControlsRules")
for _,state in {nil,false,0,"true"} do
    assert(not Rules.visible(state,false),"Flying is never inferred from a truthy value")
    assert(not Rules.visible(state,true),"Opening a modal cannot enable idle flight controls")
end
assert(Rules.visible(true,false),"Flying with no modal shows flight controls")
assert(Rules.visible(true,nil),"Absent modal flag means no modal is blocking")
assert(not Rules.visible(true,true),"Flying behind a modal hides controls")
assert(not Rules.visible(false,false),"Closing modal while not flying cannot show controls")
assert(not Rules.visible(nil,false),"Initial state must not show controls")
print("PASS: flight controls remain hidden unless actively flying and modal-free")
