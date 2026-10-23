--!strict
local Placement=require("../src/shared/ExamPlacementRules")
assert(Placement.spacing(nil)==4 and Placement.spacing("6")==4)
assert(Placement.spacing(6)==6 and Placement.spacing(2)==3 and Placement.spacing(100)==10)
assert(Placement.spacing(0/0)==4 and Placement.spacing(math.huge)==4)
assert(Placement.height(nil)==0 and Placement.height("3")==0)
assert(Placement.height(2.94)==2.94 and Placement.height(-1)==0 and Placement.height(100)==20)
assert(Placement.height(0/0)==0 and Placement.height(-math.huge)==0)
print("PASS: editable exam spacing/height, legacy defaults, malformed and nonfinite attributes")
