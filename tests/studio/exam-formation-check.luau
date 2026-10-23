--!strict
-- Playtest server: isolated six-area roster, no rank/DataStore writes.
local storage=game:GetService("ServerStorage")
assert(not storage:FindFirstChild("ExamFormationTest"),"Test already running")
local folder=Instance.new("Folder");folder.Name="ExamFormationTest";folder.Parent=storage
local characters=Instance.new("Folder");characters.Name="ExamFormationTestCharacters";characters.Parent=workspace
local ground=Instance.new("Model");ground.Name="ExamFormationTestGround";ground.Parent=workspace
workspace.ExamDrillGround.ExamPositions:Clone().Parent=ground
local first=ground.ExamPositions.Exam1
first.ParticipantLine:SetAttribute("ParticipantSpacing",6)
first.ParticipantLine:SetAttribute("HeightOffset",4)
first.ParticipantLine.CFrame=CFrame.new(first.ParticipantLine.Position+Vector3.new(10,0,5))*CFrame.Angles(0,math.pi/2,0)
local success,result=pcall(function()
    local originals: {[number]: CFrame}={}
    local function character(userId: number)
        local model=Instance.new("Model");model.Name=tostring(userId)
        local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.Parent=model
        model.PrimaryPart=root
        local humanoid=Instance.new("Humanoid");humanoid.Parent=model
        model.Parent=characters;model:PivotTo(CFrame.new(userId,15,50));originals[userId]=model:GetPivot()
    end
    local sessions={}
    for area=1,6 do
        character(area)
        local participants={}
        for member=1,3 do local id=100+area*10+member;character(id);participants[id]=true end
        table.insert(sessions,{id="test_"..area,areaIndex=area,phase="running",hostId=area,participants=participants})
    end
    local mock=Instance.new("ModuleScript");mock.Name="MockPlayers"
    mock.Source=[[local roster={} for _,model in workspace.ExamFormationTestCharacters:GetChildren() do roster[tonumber(model.Name)]={Character=model} end return {GetPlayerByUserId=function(_,id) return roster[id] end}]]
    mock.Parent=folder
    local module=game.ServerScriptService.ExamFormation:Clone()
    module.Source=module.Source:gsub('local Players=game:GetService%("Players"%)','local Players=require(script.Parent.MockPlayers)')
    module.Source=module.Source:gsub('"ExamDrillGround"','"ExamFormationTestGround"')
    module.Parent=folder
    local formation=require(module)
    for _,exam in sessions do
        assert(formation.ready(exam))
        formation.start(exam)
        assert(not formation.ready(exam),"Duplicate area use rejected")
        local points=ground.ExamPositions["Exam"..exam.areaIndex]
        local hostPosition=points.ExaminerPoint.Position+Vector3.new(0,points.ExaminerPoint:GetAttribute("HeightOffset"),0)
        assert((characters[tostring(exam.hostId)]:GetPivot().Position-hostPosition).Magnitude<.01)
        local line=points.ParticipantLine
        local spacing=line:GetAttribute("ParticipantSpacing")
        local height=line:GetAttribute("HeightOffset")
        for member=1,3 do
            local id=100+exam.areaIndex*10+member
            local expected=line.CFrame*CFrame.new((member-2)*spacing,height,0)
            local pivot=characters[tostring(id)]:GetPivot()
            assert((pivot.Position-expected.Position).Magnitude<.01,"Edited center/spacing/height applied")
            assert(pivot.LookVector:Dot(line.CFrame.LookVector)>.999,"Edited facing applied")
        end
    end
    assert(not first.ExaminerPoint.PlacementLabel.Enabled and first.ExaminerPoint.Transparency==1,"Editor guides hidden")
    sessions[1].participants[111]=nil;formation.reconcile(sessions)
    assert((characters["111"]:GetPivot().Position-originals[111].Position).Magnitude<.01,"Leave restores location")
    local closed=table.remove(sessions,1)
    local otherPosition=characters["121"]:GetPivot().Position
    formation.reconcile(sessions)
    assert((characters["1"]:GetPivot().Position-originals[1].Position).Magnitude<.01,"Host returns on close")
    assert((characters["121"]:GetPivot().Position-otherPosition).Magnitude<.01,"Closing one exam preserves others")
    assert(formation.ready(closed),"Released area reusable")
    formation.reconcile({})
    for id,pivot in originals do assert((characters[tostring(id)]:GetPivot().Position-pivot.Position).Magnitude<.01,"All locations restored") end
    characters["112"]:Destroy()
    assert(not formation.ready(closed),"Missing character prevents partial teleport")
    return "PASS: six simultaneous areas, 24 mock characters, edited center/facing/spacing/height, hidden guides, independent leave/close returns and released-area reuse"
end)
folder:Destroy();characters:Destroy();ground:Destroy()
assert(success,result)
return result
