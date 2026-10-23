--!strict
-- Replace only the visual surface; keep all exam markers and collision parts.
local ground=workspace:FindFirstChild("ExamDrillGround") :: Model
local imported=workspace:FindFirstChild("ExamDrillGroundHQ") :: Model
assert(ground and imported,"Existing ground and imported HQ model required")
assert(not ground:FindFirstChild("VisualDetail"),"HQ model already installed")
local count=0
for _,item in imported:GetDescendants() do if item:IsA("MeshPart") then count+=1 end end
assert(count==16,"Expected 16 surface chunks")
local _,size=imported:GetBoundingBox()
imported:ScaleTo(imported:GetScale()*200/size.Z)
imported:PivotTo(CFrame.new(350,0,-180))
for _,item in imported:GetDescendants() do
    if item:IsA("BasePart") then
        item.Anchored=true;item.CanCollide=false;item.CanTouch=false
        if item:IsA("MeshPart") then item.RenderFidelity=Enum.RenderFidelity.Precise end
    end
end
local old=ground:FindFirstChild("ExamDrillGroundVisual")
if old then
    local storage=game:GetService("ServerStorage")
    local backup=Instance.new("Folder");backup.Name="ExamDrillGroundLowDetailBackup";backup.Parent=storage
    old.Parent=backup
end
imported.Name="VisualDetail";imported.Parent=ground
assert(ground:FindFirstChild("ExaminerPoint") and ground:FindFirstChild("ParticipantLine"))
return {surfaceParts=count,examPointsPreserved=true}
