--!strict
-- Placement and return locations are server-owned; drill commands are presentation only.
local Players=game:GetService("Players")
local Placement=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ExamPlacementRules"))
local Formation={}

-- These editable parts are guides, hidden only in the running server copy.
local ground=workspace:FindFirstChild("ExamDrillGround")
if ground then
    local positions=ground:FindFirstChild("ExamPositions")
    if positions then
        for _,point in positions:GetDescendants() do
            if point:IsA("BasePart") then point.Transparency=1 end
            if point:IsA("BillboardGui") or point:IsA("SurfaceGui") then point.Enabled=false end
        end
    end
end

local function pointsFor(exam: any): (BasePart?,BasePart?)
    if type(exam.areaIndex)~="number" or exam.areaIndex%1~=0 or exam.areaIndex<1 or exam.areaIndex>6 then return nil,nil end
    local currentGround=workspace:FindFirstChild("ExamDrillGround")
    local positions=if currentGround then currentGround:FindFirstChild("ExamPositions") else nil
    local area=if positions then positions:FindFirstChild("Exam"..tostring(exam.areaIndex)) else nil
    local host=if area then area:FindFirstChild("ExaminerPoint") else nil
    local line=if area then area:FindFirstChild("ParticipantLine") else nil
    return if host and host:IsA("BasePart") then host else nil,
        if line and line:IsA("BasePart") then line else nil
end

local function destination(point: BasePart): CFrame
    -- Keep the avatar upright even if a marker is accidentally tilted.
    local look=Vector3.new(point.CFrame.LookVector.X,0,point.CFrame.LookVector.Z)
    if look.Magnitude<0.001 then look=Vector3.new(0,0,-1) end
    local position=point.Position+Vector3.new(0,Placement.height(point:GetAttribute("HeightOffset")),0)
    return CFrame.lookAt(position,position+look)
end
type ReturnPoint={character: Model, pivot: CFrame, examId: string}
local returns: {[number]: ReturnPoint}={}
local activeAreas: {[number]: string}={}

local function characterFor(userId: number): Model?
    local player=Players:GetPlayerByUserId(userId)
    local character=if player then player.Character else nil
    local humanoid=if character then character:FindFirstChildOfClass("Humanoid") else nil
    if character and humanoid and humanoid.Health>0 and character:FindFirstChild("HumanoidRootPart") then
        return character
    end
    return nil
end

function Formation.ready(exam: any): (boolean,string)
    local host,line=pointsFor(exam)
    if not host or not line then
        return false,"해당 시험 구역의 ExaminerPoint / ParticipantLine 위치를 확인하세요."
    end
    if activeAreas[exam.areaIndex] then return false,"해당 시험 구역을 사용 중입니다." end
    if not characterFor(exam.hostId) then return false,"개최자가 생존한 상태에서 시작하세요." end
    for userId in exam.participants do
        if not characterFor(userId) then return false,"모든 참가자가 부활한 후 다시 시작하세요." end
    end
    return true,""
end

local function move(userId: number,destination: CFrame,examId: string)
    local character=characterFor(userId)
    if not character then return end
    returns[userId]={character=character,pivot=character:GetPivot(),examId=examId}
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Sit=false end
    local root=character:FindFirstChild("HumanoidRootPart") :: BasePart
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    character:PivotTo(destination)
end

function Formation.start(exam: any)
    local host,line=pointsFor(exam)
    assert(host and line,"Exam placement points missing")
    activeAreas[exam.areaIndex]=exam.id
    move(exam.hostId,destination(host),exam.id)
    local ids: {number}={}
    for userId in exam.participants do table.insert(ids,userId) end
    table.sort(ids)
    local lineFrame=destination(line)
    local spacing=Placement.spacing(line:GetAttribute("ParticipantSpacing"))
    -- The line marker controls the center and facing of the whole rank.
    for index,userId in ids do
        move(userId,lineFrame*CFrame.new((index-(#ids+1)/2)*spacing,0,0),exam.id)
    end
end

local function restore(userId: number)
    local saved=returns[userId]
    returns[userId]=nil
    if not saved then return end
    local character=characterFor(userId)
    if character==saved.character then character:PivotTo(saved.pivot) end
end

function Formation.reconcile(sessions: {any})
    local active: {[string]: any}={}
    for _,exam in sessions do if exam.phase=="running" then active[exam.id]=exam end end
    local remove: {number}={}
    for userId,saved in returns do
        local current=active[saved.examId]
        if not current or (current.hostId~=userId and not current.participants[userId]) then
            table.insert(remove,userId)
        end
    end
    for _,userId in remove do restore(userId) end
    for areaIndex,examId in activeAreas do
        if not active[examId] then activeAreas[areaIndex]=nil end
    end
end

return Formation
