--!strict
-- Edit-mode setup. Existing point X/Z and facing are preserved.
local ground=workspace:FindFirstChild("ExamDrillGround")
assert(ground,"Training ground missing")
local positions=ground:FindFirstChild("ExamPositions")
if not positions then positions=Instance.new("Folder");positions.Name="ExamPositions";positions.Parent=ground end
for areaIndex=1,6 do
local area=positions:FindFirstChild("Exam"..areaIndex)
if not area then area=Instance.new("Model");area.Name="Exam"..areaIndex;area.Parent=positions end
for _,config in {
    {name="ExaminerPoint",label="시험관 위치",color=Color3.fromRGB(255,195,65)},
    {name="ParticipantLine",label="참가자 줄의 중앙",color=Color3.fromRGB(70,185,255)},
} do
    local point=area:FindFirstChild(config.name) :: Part?
    if not point then
        point=Instance.new("Part");point.Name=config.name;point.Parent=area
        local z=-230+(areaIndex-1)*24
        point.CFrame=if config.name=="ExaminerPoint" then CFrame.new(350,7.56,z-10)*CFrame.Angles(0,math.pi,0)
            else CFrame.new(350,7.56,z)
        point:SetAttribute("HeightOffset",2.94)
    end
    if config.name=="ParticipantLine" and point:GetAttribute("ParticipantSpacing")==nil then
        point:SetAttribute("ParticipantSpacing",4)
    end
    point.Size=Vector3.new(6,0.16,6);point.Anchored=true
    point.CanCollide=false;point.CanTouch=false;point.CanQuery=true
    point.Color=config.color;point.Material=Enum.Material.Neon;point.Transparency=.25
    point:SetAttribute("Instructions","이 표식을 이동·회전하세요. 화살표 방향을 바라봅니다. HeightOffset=바닥 위 높이")
    local label=point:FindFirstChild("PlacementLabel") :: BillboardGui?
    if not label then label=Instance.new("BillboardGui");label.Name="PlacementLabel";label.Parent=point end
    label.Size=UDim2.fromOffset(280,65);label.StudsOffsetWorldSpace=Vector3.new(0,4,0)
    label.AlwaysOnTop=true;label.MaxDistance=350;label.Enabled=true
    local text=label:FindFirstChild("Text") :: TextLabel?
    if not text then text=Instance.new("TextLabel");text.Name="Text";text.Parent=label end
    text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=.2;text.BackgroundColor3=Color3.fromRGB(24,28,33)
    text.Text=tostring(areaIndex).."번 시험 · "..config.label.."\n이동 / 회전으로 배치 변경";text.TextColor3=config.color
    text.Font=Enum.Font.GothamBold;text.TextSize=17;text.TextWrapped=true
    local surface=point:FindFirstChild("DirectionGuide") :: SurfaceGui?
    if not surface then surface=Instance.new("SurfaceGui");surface.Name="DirectionGuide";surface.Parent=point end
    surface.Face=Enum.NormalId.Top;surface.CanvasSize=Vector2.new(256,256);surface.AlwaysOnTop=true;surface.Enabled=true
    local arrow=surface:FindFirstChild("Arrow") :: TextLabel?
    if not arrow then arrow=Instance.new("TextLabel");arrow.Name="Arrow";arrow.Parent=surface end
    arrow.Size=UDim2.fromScale(1,1);arrow.BackgroundTransparency=1
    arrow.Text="▲\n보는 방향";arrow.TextColor3=Color3.fromRGB(20,25,30);arrow.TextSize=58;arrow.Font=Enum.Font.GothamBold
end
end
-- Retire the old decorations so there is only one movable marker per role.
for _,name in {"ExaminerMark","FormationMark","ExaminerPoint","ParticipantLine"} do
    local old=ground:FindFirstChild(name)
    if old and old:IsA("BasePart") then
        old.Transparency=1;old.CanQuery=false
        for _,gui in old:GetDescendants() do if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then gui.Enabled=false end end
    end
end
game:GetService("Selection"):Set({positions})
return "Six editable exam areas ready under ExamPositions / Exam1 ... Exam6"
