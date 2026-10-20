--!strict
-- Common right-side exam launcher. The server decides who can create or join.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ExamRules"))
local remote=ReplicatedStorage:WaitForChild("ExamBoardRequest") :: RemoteFunction
local changed=ReplicatedStorage:WaitForChild("ExamBoardChanged") :: RemoteEvent

local C={
    bg=Color3.fromRGB(27,30,37),sidebar=Color3.fromRGB(20,23,29),
    surface=Color3.fromRGB(37,42,51),hover=Color3.fromRGB(49,56,66),
    accent=Color3.fromRGB(106,149,113),light=Color3.fromRGB(166,207,166),
    white=Color3.fromRGB(241,242,245),muted=Color3.fromRGB(153,162,174),
    border=Color3.fromRGB(58,66,76),warning=Color3.fromRGB(235,185,105),
}
local function make(className: string,parent: Instance,props: any): any
    local object: any=Instance.new(className)
    for key,value in props do object[key]=value end
    object.Parent=parent
    return object
end
local function rounded(object: Instance,radius: number)
    make("UICorner",object,{CornerRadius=UDim.new(0,radius)})
end
local function stroke(object: Instance)
    make("UIStroke",object,{Color=C.border,Thickness=1,Transparency=0.25})
end
local function text(parent: Instance,name: string,value: string,size: number,color: Color3,bold: boolean): TextLabel
    return make("TextLabel",parent,{Name=name,Text=value,TextSize=size,
        TextColor3=color,Font=if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
        BackgroundTransparency=1,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function button(parent: Instance,name: string,value: string,color: Color3): TextButton
    local item=make("TextButton",parent,{Name=name,Text=value,TextSize=15,
        TextColor3=C.white,Font=Enum.Font.GothamBold,BackgroundColor3=color,
        BorderSizePixel=0,AutoButtonColor=true,Selectable=true})
    rounded(item,11)
    return item
end
local function scrolling(parent: Instance,name: string): ScrollingFrame
    local item=make("ScrollingFrame",parent,{
        Name=name,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,
        ScrollBarImageColor3=C.muted,AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,
    })
    make("UIListLayout",item,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
    return item
end

local gui=make("ScreenGui",player:WaitForChild("PlayerGui"),{
    Name="MilitaryExams",ResetOnSpawn=false,DisplayOrder=32,
    ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})
local launcher=button(gui,"ExamButton","◆  시험",C.sidebar)
launcher.AnchorPoint=Vector2.new(1,0.5)
-- Existing communication button: right inset 16, center Y. Exactly above it.
launcher.Position=UDim2.new(1,-16,0.5,-62)
launcher.Size=UDim2.fromOffset(112,50)
launcher.TextSize=16
stroke(launcher)

local window=make("Frame",gui,{Name="ExamWindow",AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(900,610),
    BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true,Visible=false})
rounded(window,16)
stroke(window)
local scale=make("UIScale",window,{Scale=1})
local function resize()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local viewport=camera.ViewportSize
    scale.Scale=math.min(1,math.max(0.32,(viewport.X-32)/920),math.max(0.32,(viewport.Y-100)/660))
end
resize()
local viewportChanged: RBXScriptConnection?=nil
local function watchViewport()
    if viewportChanged then viewportChanged:Disconnect();viewportChanged=nil end
    local camera=workspace.CurrentCamera
    if camera then viewportChanged=camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchViewport)
watchViewport()

local header=make("Frame",window,{Name="Header",Size=UDim2.new(1,0,0,88),
    BackgroundColor3=C.sidebar,BorderSizePixel=0})
text(header,"Eyebrow","MILITARY RP  /  EXAM OPERATIONS",11,C.light,true).Size=UDim2.fromOffset(600,22)
local eyebrow=header:FindFirstChild("Eyebrow") :: TextLabel
eyebrow.Position=UDim2.fromOffset(26,10)
local title=text(header,"Title","계급 시험",26,C.white,true)
title.Position=UDim2.fromOffset(26,32);title.Size=UDim2.fromOffset(300,42)
local capacity=text(header,"Capacity","진행 중 0 / 6",14,C.muted,false)
capacity.Position=UDim2.fromOffset(485,37);capacity.Size=UDim2.fromOffset(215,27)
local refreshButton=button(header,"Refresh","새로고침",C.surface)
refreshButton.Position=UDim2.fromOffset(712,23);refreshButton.Size=UDim2.fromOffset(98,42)
local closeButton=button(header,"Close","×",C.surface)
closeButton.Position=UDim2.fromOffset(822,23);closeButton.Size=UDim2.fromOffset(52,42)
closeButton.TextSize=26

local creator=make("Frame",window,{Name="CreateSection",
    Position=UDim2.fromOffset(18,100),Size=UDim2.new(1,-36,0,121),
    BackgroundColor3=C.surface,BorderSizePixel=0,Visible=false})
rounded(creator,12)
local createTitle=text(creator,"Title","시험 창설  ·  개최할 시험 계급을 선택하세요",15,C.white,true)
createTitle.Position=UDim2.fromOffset(15,8);createTitle.Size=UDim2.fromOffset(700,29)
local createInfo=text(creator,"Hint","위관급 이상 개최 가능  /  서버 전체 동시 최대 6개",11,C.muted,false)
createInfo.Position=UDim2.fromOffset(15,91);createInfo.Size=UDim2.fromOffset(685,20)
local createButton=button(creator,"CreateButton","시험 창설",C.accent)
createButton.Position=UDim2.fromOffset(720,46);createButton.Size=UDim2.fromOffset(127,49)

local chosenRankId=Rules.TARGET_IDS[1]
local rankButtons: {[string]: TextButton}={}
for index,rankId in Rules.TARGET_IDS do
    local rank=Catalog.find(rankId)
    local chip=button(creator,"Rank_"..rankId,if rank then rank.name else rankId,C.bg)
    chip.TextSize=14
    chip.Position=UDim2.fromOffset(14+(index-1)*86,48)
    chip.Size=UDim2.fromOffset(80,36)
    rankButtons[rankId]=chip
    chip.Activated:Connect(function()
        chosenRankId=rankId
        for id,other in rankButtons do
            other.BackgroundColor3=if id==chosenRankId then C.accent else C.bg
        end
    end)
end
rankButtons[chosenRankId].BackgroundColor3=C.accent

local left=make("Frame",window,{Name="ListPanel",BackgroundColor3=C.surface,BorderSizePixel=0})
local right=make("Frame",window,{Name="DetailsPanel",BackgroundColor3=C.surface,BorderSizePixel=0})
rounded(left,12);rounded(right,12)
local listHeading=text(left,"Heading","진행 중인 시험",17,C.white,true)
listHeading.Position=UDim2.fromOffset(16,8);listHeading.Size=UDim2.new(1,-32,0,40)
local examList=scrolling(left,"ExamList")
examList.Position=UDim2.fromOffset(12,48)
examList.Size=UDim2.new(1,-24,1,-61)

local detailTitle=text(right,"DetailTitle","시험을 선택하세요",22,C.white,true)
detailTitle.Position=UDim2.fromOffset(16,12);detailTitle.Size=UDim2.new(1,-32,0,36)
local detailHost=text(right,"Host","목록에서 진행 중인 시험을 선택하세요.",14,C.muted,false)
detailHost.Position=UDim2.fromOffset(16,56);detailHost.Size=UDim2.new(1,-32,0,25)
local detailExtra=text(right,"Details","",12,C.muted,false)
detailExtra.Position=UDim2.fromOffset(16,86);detailExtra.Size=UDim2.new(1,-32,0,24)
local rosterHeading=text(right,"RosterTitle","참가자",15,C.white,true)
rosterHeading.Position=UDim2.fromOffset(16,117);rosterHeading.Size=UDim2.new(1,-32,0,32)
local roster=scrolling(right,"Roster")
roster.Position=UDim2.fromOffset(16,153)
roster.Size=UDim2.new(1,-32,1,-224)
local examAction=button(right,"ExamAction","시험 참가하기",C.accent)
examAction.Position=UDim2.new(0,16,1,-59)
examAction.Size=UDim2.new(1,-32,0,43)
examAction.Visible=false
local status=text(window,"Status","시험 정보는 현재 서버 기준입니다.",12,C.muted,false)
status.Position=UDim2.new(0,22,1,-25);status.Size=UDim2.new(1,-44,0,20)
local function arrange(canCreate: boolean)
    creator.Visible=canCreate
    local top=if canCreate then 232 else 100
    local bottom=if canCreate then 264 else 132
    left.Position=UDim2.fromOffset(18,top)
    left.Size=UDim2.new(0,418,1,-bottom)
    right.Position=UDim2.fromOffset(448,top)
    right.Size=UDim2.new(1,-466,1,-bottom)
end
arrange(false)

local board: any=nil
local selectedId: string?=nil
local pending=false
local fetching=false
local fetchAgain=false
local scheduled=false
local fetchSnapshot: ()->()
local scheduleRefresh: ()->()
local mutate: (string,any)->()
local function clearRows(scroll: ScrollingFrame)
    for _,child in scroll:GetChildren() do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end
local function personName(person: any): string
    return tostring(person.displayName or person.username or "알 수 없음")
        .." (@"..tostring(person.username or "?")..")"
end
local function findSelected(): any
    if not board then return nil end
    for _,exam in board.sessions do
        if exam.id==selectedId then return exam end
    end
    return nil
end
local function render()
    local sessions=if board and type(board.sessions)=="table" then board.sessions else {}
    local canCreate=board and board.canCreate==true
    arrange(canCreate==true)
    capacity.Text="진행 중 "..tostring(#sessions).." / "..tostring(Rules.MAX_ACTIVE)
    clearRows(examList)
    if selectedId~=nil then
        local stillThere=false
        for _,exam in sessions do if exam.id==selectedId then stillThere=true;break end end
        if not stillThere then selectedId=nil end
    end
    if not selectedId and #sessions>0 then selectedId=sessions[1].id end
    if #sessions==0 then
        local empty=text(examList,"Empty","현재 진행 중인 시험이 없습니다.",15,C.muted,false)
        empty.Size=UDim2.new(1,-12,0,88);empty.TextXAlignment=Enum.TextXAlignment.Center
    end
    for index,exam in sessions do
        local selected=selectedId==exam.id
        local host=exam.host or {}
        local entry=button(examList,"Exam_"..tostring(exam.id),"",
            if selected then C.accent else C.bg)
        entry.LayoutOrder=index
        entry.Size=UDim2.new(1,-5,0,106)
        entry.Text="  "..tostring(exam.targetName).." 시험  ·  "..tostring(#(exam.participants or {})).."명 참가\n"
            .."  개최: "..tostring(host.rank or "계급 확인 중").."  "..personName(host)
            .."\n  "..(if selected then "▶ 선택된 시험" else "클릭하여 참가자 확인")
        entry.TextXAlignment=Enum.TextXAlignment.Left
        entry.TextYAlignment=Enum.TextYAlignment.Center
        entry.TextWrapped=true
        entry.TextSize=14
        entry.Activated:Connect(function() selectedId=exam.id;render() end)
    end
    local selected=findSelected()
    clearRows(roster)
    if not selected then
        detailTitle.Text="시험을 선택하세요"
        detailHost.Text="목록에서 진행 중인 시험을 선택하세요."
        detailExtra.Text=""
        rosterHeading.Text="참가자"
        examAction.Visible=false
        return
    end
    detailTitle.Text=tostring(selected.targetName).." 시험"
    detailHost.Text="개최: "..tostring(selected.host.rank or "계급 확인 중")
        .."  "..personName(selected.host)
    detailExtra.Text="개최자 계정: @"..tostring(selected.host.username or "?")
    local people=selected.participants or {}
    rosterHeading.Text="참가자  ·  "..tostring(#people).."명"
    if #people==0 then
        local empty=text(roster,"Nobody","아직 참가자가 없습니다.",14,C.muted,false)
        empty.Size=UDim2.new(1,-8,0,45)
    else
        for index,member in people do
            local entry=make("Frame",roster,{Name="Participant_"..tostring(member.userId),
                Size=UDim2.new(1,-6,0,45),BackgroundColor3=C.bg,BorderSizePixel=0})
            entry.LayoutOrder=index
            rounded(entry,8)
            local item=text(entry,"Name",
                tostring(index)..".  ["..tostring(member.rank or "?").."]  "..personName(member),
                13,C.white,false)
            item.Position=UDim2.fromOffset(10,4)
            item.Size=UDim2.new(1,-20,1,-8)
        end
    end
    local isHost=selected.host and selected.host.userId==player.UserId
    local joined=false
    for _,member in people do
        if member.userId==player.UserId then joined=true;break end
    end
    examAction.Visible=true
    examAction.Text=if isHost then "시험 종료" elseif joined then "참가 취소" else "시험 참가하기"
    examAction.BackgroundColor3=if isHost or joined then C.hover else C.accent
    examAction.Active=not pending
end

local function applyData(data: any)
    if type(data)~="table" or type(data.sessions)~="table" or type(data.revision)~="number" then return end
    if board and type(board.revision)=="number" and data.revision<board.revision then return end
    board=data
    render()
end

fetchSnapshot=function()
    if fetching then fetchAgain=true;return end
    fetching=true
    task.spawn(function()
        local ok,response=pcall(function()
            return remote:InvokeServer("snapshot")
        end)
        fetching=false
        if ok and type(response)=="table" and response.ok then
            applyData(response.data)
        elseif window.Visible then
            status.Text=if ok and type(response)=="table" then tostring(response.message)
                else "시험 목록 조회에 실패했습니다."
        end
        if fetchAgain then fetchAgain=false;scheduleRefresh() end
    end)
end
scheduleRefresh=function()
    if scheduled then return end
    scheduled=true
    task.delay(0.35,function()
        scheduled=false
        fetchSnapshot()
    end)
end
mutate=function(action: string,payload: any)
    if pending then return end
    pending=true
    examAction.Active=false
    createButton.Active=false
    status.Text="서버에 요청하고 있습니다..."
    task.spawn(function()
        local ok,response=pcall(function()
            return remote:InvokeServer(action,payload)
        end)
        pending=false
        createButton.Active=true
        examAction.Active=true
        if ok and type(response)=="table" then
            status.Text=if type(response.message)=="string" then response.message
                elseif response.ok then "완료되었습니다." else "처리 실패"
            if response.ok then applyData(response.data) end
        else
            status.Text="서버에 연결할 수 없습니다. 다시 시도하세요."
        end
        scheduleRefresh()
        render()
    end)
end
createButton.Activated:Connect(function()
    if board and board.canCreate then
        mutate("create",{targetId=chosenRankId})
    end
end)
examAction.Activated:Connect(function()
    local exam=findSelected()
    if not exam then return end
    local isHost=exam.host and exam.host.userId==player.UserId
    if isHost then mutate("close",{examId=exam.id});return end
    for _,member in exam.participants or {} do
        if member.userId==player.UserId then mutate("leave",{examId=exam.id});return end
    end
    mutate("join",{examId=exam.id})
end)
local function toggle()
    window.Visible=not window.Visible
    launcher.Text=if window.Visible then "×  시험 닫기" else "◆  시험"
    if window.Visible then scheduleRefresh() end
end
launcher.Activated:Connect(toggle)
closeButton.Activated:Connect(toggle)
refreshButton.Activated:Connect(scheduleRefresh)
changed.OnClientEvent:Connect(function(_revision: number)
    scheduleRefresh()
end)
player:GetAttributeChangedSignal("RankId"):Connect(scheduleRefresh)
player:GetAttributeChangedSignal("RankStorageStatus"):Connect(scheduleRefresh)
UserInputService.InputBegan:Connect(function(input,processed)
    if not processed and window.Visible and input.KeyCode==Enum.KeyCode.Escape then toggle() end
end)
scheduleRefresh()
