--!strict
-- Run once in Edit mode after importing assets/drill-ground/ExamDrillGroundHQ.fbx.
-- Only the named new training ground is modified. Existing map objects are preserved.
local ground=(workspace:FindFirstChild("ExamDrillGround") or workspace:FindFirstChild("ExamDrillGroundHQ")) :: Model
assert(ground and ground:IsA("Model"),"Import ExamDrillGround.fbx first")
ground.Name="ExamDrillGround"
local _,size=ground:GetBoundingBox()
ground:ScaleTo(ground:GetScale()*200/size.Z)
ground:PivotTo(CFrame.new(350,0,-180))
for _,part in ground:GetDescendants() do
    if part:IsA("MeshPart") then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end
end
local function part(name: string,dimensions: Vector3,cf: CFrame,transparent: boolean): BasePart
    local existing=ground:FindFirstChild(name)
    assert(not existing or existing:IsA("Part"),"Conflicting ground child")
    local item=existing or Instance.new("Part")
    item.Name=name;item.Size=dimensions;item.CFrame=cf;item.Anchored=true
    item.Transparency=if transparent then 1 else 0
    item.CanCollide=name=="WalkableFloor";item.CanTouch=false;item.CanQuery=false
    item.Parent=ground
    return item :: BasePart
end
part("WalkableFloor",Vector3.new(154,1,160),CFrame.new(350,7,-166),true)
part("ExaminerPoint",Vector3.new(2,1,2),CFrame.new(350,10.5,-230)*CFrame.Angles(0,math.pi,0),true)
part("ParticipantLine",Vector3.new(2,1,2),CFrame.new(350,10.5,-196),true)
local marker=part("ExaminerMark",Vector3.new(7,.08,7),CFrame.new(350,7.56,-230),false)
marker.Color=Color3.fromRGB(235,193,87);marker.Material=Enum.Material.SmoothPlastic
local line=part("FormationMark",Vector3.new(124,.08,.3),CFrame.new(350,7.56,-196),false)
line.Color=Color3.fromRGB(240,240,230);line.Material=Enum.Material.SmoothPlastic
local gui=marker:FindFirstChild("Label") or Instance.new("BillboardGui")
gui.Name="Label";gui.Size=UDim2.fromOffset(180,38);gui.StudsOffset=Vector3.new(0,3,0)
gui.AlwaysOnTop=false;gui.MaxDistance=100;gui.Parent=marker
local label=gui:FindFirstChild("Title") or Instance.new("TextLabel")
label.Name="Title";label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
label.Text="제식 시험 · 시험관 위치";label.TextColor3=Color3.new(1,1,1)
label.TextStrokeTransparency=.35;label.TextSize=16;label.Font=Enum.Font.GothamBold;label.Parent=gui
print("Run tools/setup_exam_markers.studio.luau next to create six editable placement areas")
