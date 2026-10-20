--!strict
-- HQ command desk: responsive dark tactical dashboard.
-- Visual controls never confer authority; AdminService rechecks Team on every request.
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Panel={}

local C={
    background=Color3.fromRGB(20,26,29),
    card=Color3.fromRGB(31,39,43),
    raised=Color3.fromRGB(41,51,55),
    hover=Color3.fromRGB(52,65,69),
    text=Color3.fromRGB(244,247,243),
    muted=Color3.fromRGB(158,174,173),
    border=Color3.fromRGB(73,89,89),
    accent=Color3.fromRGB(153,207,155),
    red=Color3.fromRGB(235,148,145),
    yellow=Color3.fromRGB(236,205,128),
}
local TEAM_NAMES={"HQ","위관급","영관급","장관급"}
local NAV={
    {"overview","개요"},
    {"god","무적"},
    {"fly","비행"},
    {"team","팀 관리"},
    {"rank","계급"},
    {"command","명령어"},
    {"logs","기록"},
}
local function make(className: string,parent: Instance,properties: any): any
    local object=Instance.new(className)
    for key,value in properties do (object :: any)[key]=value end
    object.Parent=parent
    return object
end
local function rounded(object: Instance,radius: number?)
    make("UICorner",object,{CornerRadius=UDim.new(0,radius or 10)})
end
local function text(parent: Instance,value: string,size: number,color: Color3?,bold: boolean?): TextLabel
    return make("TextLabel",parent,{
        BackgroundTransparency=1,BorderSizePixel=0,Text=value,TextColor3=color or C.text,
        Font=if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium,TextSize=size,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,
        Size=UDim2.new(1,0,0,32),
    })
end
local function button(parent: Instance,value: string,width: UDim2?,color: Color3?): TextButton
    local result: TextButton=make("TextButton",parent,{
        Text=value,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=C.text,
        BackgroundColor3=color or C.raised,BorderSizePixel=0,
        Size=width or UDim2.new(1,0,0,42),AutoButtonColor=true,Selectable=true,
    })
    rounded(result,8)
    return result
end
local function input(parent: Instance,value: string,placeholder: string): TextBox
    local result: TextBox=make("TextBox",parent,{
        Text=value,PlaceholderText=placeholder,ClearTextOnFocus=false,
        TextColor3=C.text,PlaceholderColor3=C.muted,
        Font=Enum.Font.GothamMedium,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundColor3=C.raised,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,42),
    })
    rounded(result,8)
    make("UIPadding",result,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
    return result
end
local function vStack(parent: Instance,gap: number)
    make("UIListLayout",parent,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,gap)})
end
local function isHQ(player: Player): boolean
    return player.Team~=nil and player.Team.Name=="HQ" and not player.Neutral
end

function Panel.mount(parent: Frame): (boolean)->()
    local player=Players.LocalPlayer
    local request=ReplicatedStorage:WaitForChild("AdminRequest") :: RemoteEvent
    local response=ReplicatedStorage:WaitForChild("AdminResponse") :: RemoteEvent

    local root=make("Frame",parent,{
        Name="AdminTools",BackgroundColor3=C.background,BorderSizePixel=0,
        Position=UDim2.fromOffset(18,102),Size=UDim2.new(1,-36,1,-138),
        Visible=false,
    })
    rounded(root,12)

    local title=text(root,"HQ  /  COMMAND DESK",18,C.text,true)
    title.Name="DashboardTitle"
    title.Position=UDim2.fromOffset(16,8)
    title.Size=UDim2.new(1,-172,0,30)
    local subtitle=text(root,"명령 실행 · 인원 통제 · 활동 기록",12,C.muted)
    subtitle.Position=UDim2.fromOffset(16,38)
    subtitle.Size=UDim2.new(1,-32,0,21)
    local badge=text(root,"● HQ 인증",12,C.accent,true)
    badge.Name="AuthorizationStatus"
    badge.TextXAlignment=Enum.TextXAlignment.Right
    badge.Position=UDim2.new(1,-152,0,8)
    badge.Size=UDim2.fromOffset(134,30)

    local nav=make("ScrollingFrame",root,{
        Name="OperationsNavigation",Position=UDim2.fromOffset(12,74),
        Size=UDim2.new(0,140,1,-118),BackgroundColor3=C.card,BorderSizePixel=0,
        ScrollBarThickness=2,ScrollBarImageColor3=C.border,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.XY,
    })
    rounded(nav,10)
    make("UIPadding",nav,{
        PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),
        PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),
    })
    local navLayout=make("UIListLayout",nav,{
        FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),
    })

    local body=make("ScrollingFrame",root,{
        Name="OperationsContent",Position=UDim2.fromOffset(164,74),
        Size=UDim2.new(1,-176,1,-118),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.border,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    })
    vStack(body,10)
    make("UIPadding",body,{
        PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,12),
    })

    local banner=make("Frame",root,{
        Name="ActionFeedback",Position=UDim2.new(0,12,1,-38),
        Size=UDim2.new(1,-24,0,29),BackgroundColor3=C.card,BorderSizePixel=0,
    })
    rounded(banner,7)
    local feedback=text(banner,"준비됨 · 서버에서 모든 관리 요청을 재검증합니다.",11,C.muted)
    feedback.Name="FeedbackMessage"
    feedback.Position=UDim2.fromOffset(10,0)
    feedback.Size=UDim2.new(1,-20,1,0)

    local currentTab="overview"
    local selectedTarget="나"
    local selectedTeam="위관급"
    local selectedRank="second_lieutenant"
    local pickerVisible=false
    local activity: {any}={}
    local navButtons: {[string]: TextButton}={}
    local lastSent=0
    local pendingHQTarget: string?=nil
    local active=false
    local render: ()->()=function() end

    local dialog=make("Frame",root,{
        Name="HQConfirmation",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(0.92,0,0,188),
        BackgroundColor3=C.card,BorderSizePixel=0,ZIndex=30,
    })
    rounded(dialog,12)
    make("UISizeConstraint",dialog,{MaxSize=Vector2.new(410,188)})
    local confirmTitle=text(dialog,"HQ 권한을 부여하시겠습니까?",17,C.yellow,true)
    confirmTitle.Position=UDim2.fromOffset(18,14)
    confirmTitle.Size=UDim2.new(1,-36,0,32)
    confirmTitle.ZIndex=31
    local confirmDetail=text(dialog,"HQ 소속자는 모든 관리자 명령어와 패널을 사용할 수 있습니다.",12,C.muted)
    confirmDetail.Position=UDim2.fromOffset(18,52)
    confirmDetail.Size=UDim2.new(1,-36,0,58)
    confirmDetail.ZIndex=31
    local confirmYes=button(dialog,"HQ 팀으로 이동",UDim2.new(0.5,-24,0,42),C.yellow)
    confirmYes.Position=UDim2.new(0,16,1,-56)
    confirmYes.TextColor3=C.background
    confirmYes.ZIndex=31
    local confirmNo=button(dialog,"취소",UDim2.new(0.5,-24,0,42))
    confirmNo.Position=UDim2.new(0.5,8,1,-56)
    confirmNo.ZIndex=31

    local function status(message: string,success: boolean?)
        feedback.Text=message
        feedback.TextColor3=if success==true then C.accent elseif success==false then C.red else C.muted
    end
    local function run(command: string)
        if not isHQ(player) then
            status("HQ 팀이 아니므로 관리자 명령을 실행할 수 없습니다.",false)
            return
        end
        if type(command)~="string" or #command>256 or not command:match("%S") then
            status("명령어는 공백이 아닌 256바이트 이내 문자열이어야 합니다.",false)
            return
        end
        if os.clock()-lastSent<0.32 then
            status("명령을 너무 빠르게 실행했습니다. 잠시 후 다시 시도하세요.",false)
            return
        end
        lastSent=os.clock()
        status("서버 처리 중…")
        request:FireServer("command",command)
    end
    local function clearBody()
        for _,child in body:GetChildren() do
            if child:IsA("GuiObject") then child:Destroy() end
        end
    end
    local function card(name: string,height: number): Frame
        local frame=make("Frame",body,{
            Name=name,Size=UDim2.new(1,-3,0,height),
            BackgroundColor3=C.card,BorderSizePixel=0,
        })
        rounded(frame,10)
        return frame
    end
    local function description(parentFrame: Instance,heading: string,detail: string)
        local h=text(parentFrame,heading,16,C.text,true)
        h.Position=UDim2.fromOffset(14,12);h.Size=UDim2.new(1,-28,0,27)
        local d=text(parentFrame,detail,12,C.muted)
        d.Position=UDim2.fromOffset(14,41);d.Size=UDim2.new(1,-28,0,40)
        return h,d
    end
    local function actionPair(parentFrame: Instance,first: string,second: string,callback1: ()->(),callback2: ()->(),y: number)
        local a=button(parentFrame,first,UDim2.new(0.5,-21,0,44),C.raised)
        a.Position=UDim2.fromOffset(14,y)
        local b=button(parentFrame,second,UDim2.new(0.5,-21,0,44),C.raised)
        b.Position=UDim2.new(0.5,7,0,y)
        a.Activated:Connect(callback1)
        b.Activated:Connect(callback2)
    end
    local function currentTarget(): string
        return if selectedTarget:match("%S") then selectedTarget else "나"
    end
    local function targetCard()
        local online=Players:GetPlayers()
        local visibleCount=if pickerVisible then math.min(#online,12) else 0
        local narrowTarget=root.AbsoluteSize.X<440
        local baseline=if narrowTarget then 204 else 150
        local height=if pickerVisible then baseline+visibleCount*38 else baseline
        local frame=card("TargetSelector",height)
        description(frame,"대상 플레이어","본인 또는 현재 서버의 Roblox 사용자 이름을 선택하세요.")
        local selector=input(frame,currentTarget(),"나 / Roblox 사용자 이름")
        selector.Name="TargetName"
        selector.Position=UDim2.fromOffset(14,86)
        selector.Size=if narrowTarget then UDim2.new(1,-28,0,44) else UDim2.new(1,-150,0,44)
        selector:GetPropertyChangedSignal("Text"):Connect(function()
            selectedTarget=selector.Text:match("^%s*(.-)%s*$") or ""
        end)
        local choose=button(frame,if pickerVisible then "목록 닫기" else "인원 선택  ▾",
            UDim2.fromOffset(116,44))
        choose.Position=if narrowTarget then UDim2.fromOffset(14,138) else UDim2.new(1,-130,0,86)
        choose.Size=if narrowTarget then UDim2.new(1,-28,0,44) else UDim2.fromOffset(116,44)
        choose.Activated:Connect(function()
            selectedTarget=selector.Text
            pickerVisible=not pickerVisible
            render()
        end)
        if pickerVisible then
            local list=make("ScrollingFrame",frame,{
                Name="OnlinePlayers",Position=UDim2.fromOffset(14,if narrowTarget then 192 else 140),
                Size=UDim2.new(1,-28,0,visibleCount*38),
                BackgroundTransparency=1,BorderSizePixel=0,
                ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,
                CanvasSize=UDim2.new(),
            })
            vStack(list,3)
            for _,other in online do
                local teamName=if other.Team and not other.Neutral then other.Team.Name else "미배정"
                local pick=button(list,other.DisplayName.."  @"..other.Name.."  ·  "..teamName,
                    UDim2.new(1,-4,0,34),C.raised)
                pick.TextXAlignment=Enum.TextXAlignment.Left
                make("UIPadding",pick,{PaddingLeft=UDim.new(0,10)})
                pick.Activated:Connect(function()
                    selectedTarget=other.Name
                    pickerVisible=false
                    render()
                end)
            end
        end
    end
    local function teamCounts(): {[string]: number}
        local counts={}
        for _,name in TEAM_NAMES do counts[name]=0 end
        for _,other in Players:GetPlayers() do
            local team=other.Team
            if team and not other.Neutral and counts[team.Name] then
                counts[team.Name]+=1
            end
        end
        return counts
    end
    local function jump(tab: string)
        currentTab=tab
        pickerVisible=false
        render()
    end

    local function drawOverview()
        local members=Players:GetPlayers()
        local totals=teamCounts()
        local intro=card("HQSummary",113)
        description(intro,"HQ 통제실","현재 서버 기준 · 대상별 실시간 팀 및 계급 관리")
        local summary=text(intro,"접속 "..#members.."명    |    HQ "..totals.HQ.."명    |    일반 관리 대상 "..(#members-totals.HQ).."명",13,C.accent,true)
        summary.Position=UDim2.fromOffset(14,82)
        summary.Size=UDim2.new(1,-28,0,22)
        local teamCard=card("TeamOverview",176)
        description(teamCard,"편제 현황","계급이 위관·영관·장관으로 변경되면 소속 팀이 자동 조정됩니다.")
        for index,name in TEAM_NAMES do
            local column=(index-1)%2
            local r=math.floor((index-1)/2)
            local b=button(teamCard,name.."  ·  "..tostring(totals[name] or 0).."명",
                UDim2.new(0.5,-21,0,36),if name=="HQ" then C.hover else C.raised)
            b.Position=UDim2.new(column*0.5,14+column*7,0,87+r*41)
            b.Activated:Connect(function() jump("team") end)
        end
        local quick=card("QuickOperations",158)
        description(quick,"바로 실행","아래 관리 기능은 HQ 소속 사용자에게만 열립니다.")
        actionPair(quick,"계급 조정","팀 배정",function() jump("rank") end,function() jump("team") end,88)
        local second=card("QuickActions",105)
        description(second,"기타 작업","무적·비행 제어와 기록 확인")
        actionPair(second,"무적/비행", "명령 기록",
            function() jump("god") end,function() jump("logs") end,56)
    end
    local function drawGodOrFlight(kind: string)
        targetCard()
        local flight=kind=="fly"
        local frame=card(if flight then "FlightControls" else "GodControls",160)
        description(frame,if flight then "비행 제어" else "무적 제어",
            if flight then "캐릭터의 자유 비행을 켜거나 끕니다. W/A/S/D 및 상승·하강 입력을 지원합니다."
            else "선택한 캐릭터의 피해 방지 상태를 변경합니다.")
        local verb=if flight then "/비행" else "/무적"
        actionPair(frame,"●  활성화","○  비활성화",
            function() run(verb.." "..currentTarget().." 켜기") end,
            function() run(verb.." "..currentTarget().." 끄기") end,92)
        local info=card("ControlHelp",92)
        description(info,"실행 전에 확인","대상은 현재 접속 중이어야 합니다. 변경 내용은 서버 권한 검사를 통과해야 적용됩니다.")
    end
    local function drawTeam()
        targetCard()
        local frame=card("TeamAssignment",264)
        description(frame,"팀 배정","HQ 지정 시 관리자 명령어와 패널 권한이 함께 부여됩니다.")
        for index,teamName in TEAM_NAMES do
            local column=(index-1)%2
            local rowIndex=math.floor((index-1)/2)
            local chosen=selectedTeam==teamName
            local b=button(frame,(if chosen then "✓  " else "")..teamName,
                UDim2.new(0.5,-21,0,44),if chosen then C.hover else C.raised)
            b.Position=UDim2.new(column*0.5,14+column*7,0,91+rowIndex*51)
            b.TextColor3=if chosen then C.accent else C.text
            b.Activated:Connect(function() selectedTeam=teamName;render() end)
        end
        local submit=button(frame,"선택한 팀으로 이동시키기",UDim2.new(1,-28,0,44),C.raised)
        submit.Position=UDim2.fromOffset(14,202)
        submit.Activated:Connect(function()
            if selectedTeam=="HQ" then
                pendingHQTarget=currentTarget()
                confirmDetail.Text="@"..pendingHQTarget.."에게 모든 관리자 명령어 및 관리 패널 사용 권한을 부여합니다."
                dialog.Visible=true
            else
                run("/팀 "..currentTarget().." "..selectedTeam)
            end
        end)
        local note=card("TeamNote",92)
        description(note,"자동 편제 규칙","위관·영관·장관 계급은 자동 배정됩니다. HQ는 계급으로 얻을 수 없고 직접 지정해야 합니다.")
    end
    local function drawRank()
        targetCard()
        local choice=card("RankSelection",746)
        description(choice,"계급 변경","계급 선택 후 저장합니다. 계급 DataStore에서 저장 성공이 확인되어야 적용됩니다.")
        local y=88
        local category=""
        for _,rank in Catalog.All do
            if rank.category~=category then
                category=rank.category
                local section=text(choice,category.." 계급",12,C.accent,true)
                section.Position=UDim2.fromOffset(14,y)
                section.Size=UDim2.new(1,-28,0,24)
                y+=25
            end
            local picked=selectedRank==rank.id
            local b=button(choice,(if picked then "●  " else "○  ")..rank.name,
                UDim2.new(1,-28,0,31),if picked then C.hover else C.raised)
            b.Position=UDim2.fromOffset(14,y)
            b.TextXAlignment=Enum.TextXAlignment.Left
            b.TextColor3=if picked then C.accent else C.text
            make("UIPadding",b,{PaddingLeft=UDim.new(0,12)})
            b.Activated:Connect(function()
                selectedRank=rank.id
                render()
            end)
            y+=35
        end
        choice.Size=UDim2.new(1,-3,0,y+12)
        local apply=card("RankApply",108)
        local selected=Catalog.find(selectedRank)
        description(apply,"선택한 계급",if selected then selected.name.." · "..selected.category else "계급을 선택하세요.")
        local commit=button(apply,"계급 저장 및 적용",UDim2.new(1,-28,0,40),C.raised)
        commit.Position=UDim2.fromOffset(14,65)
        commit.Activated:Connect(function()
            local rank=Catalog.find(selectedRank)
            if rank then run("/계급 "..currentTarget().." "..rank.name) end
        end)
    end
    local function drawCommand()
        local frame=card("DirectCommand",219)
        description(frame,"직접 명령어","서버의 승인된 관리 명령만 실행됩니다. Lua 코드 실행은 지원하지 않습니다.")
        local value=input(frame,"","예: /계급 사용자이름 대위")
        value.Name="CommandInput"
        value.Position=UDim2.fromOffset(14,93)
        value.Size=UDim2.new(1,-28,0,44)
        local execute=button(frame,"명령어 실행  →",UDim2.new(1,-28,0,42),C.raised)
        execute.Position=UDim2.fromOffset(14,148)
        execute.Activated:Connect(function()
            run(value.Text)
            value:ReleaseFocus(false)
        end)
        value.FocusLost:Connect(function(enterPressed)
            if enterPressed then run(value.Text) end
        end)
        local help=card("CommandExamples",230)
        description(help,"사용 가능한 명령","명령어를 눌러 입력창에 복사하세요.")
        local examples={
            "/계급 나 대위",
            "/계급목록",
            "/무적 나 켜기",
            "/비행 나 끄기",
            "/팀 나 HQ",
        }
        for i,command in examples do
            local b=button(help,command,UDim2.new(1,-28,0,29),C.raised)
            b.Position=UDim2.fromOffset(14,76+(i-1)*31)
            b.TextXAlignment=Enum.TextXAlignment.Left
            make("UIPadding",b,{PaddingLeft=UDim.new(0,10)})
            b.Activated:Connect(function()
                value.Text=command
                value:CaptureFocus()
            end)
        end
        help.Size=UDim2.new(1,-3,0,240)
    end
    local function drawLogs()
        local header=card("AuditHeader",108)
        description(header,"관리 기록","현재 서버의 최근 60개 관리 명령 기록. 서버 재시작 시 초기화됩니다.")
        local reload=button(header,"↻  최신 기록",UDim2.new(1,-28,0,34))
        reload.Position=UDim2.fromOffset(14,70)
        reload.Activated:Connect(function() request:FireServer("sync") end)
        if #activity==0 then
            local empty=card("NoHistory",78)
            local note=text(empty,"아직 기록이 없습니다.",13,C.muted)
            note.Position=UDim2.fromOffset(14,20)
        else
            local start=math.max(1,#activity-49)
            for index=#activity,start,-1 do
                local item=activity[index]
                local entry=card("Audit_"..index,100)
                local dateText=os.date("%H:%M:%S",tonumber(item.time) or os.time())
                local heading=text(entry,(if item.ok then "✓  완료" else "×  실패").."   ·   "..dateText.."  @"..tostring(item.name),12,
                    if item.ok then C.accent else C.red,true)
                heading.Position=UDim2.fromOffset(12,10)
                heading.Size=UDim2.new(1,-24,0,24)
                local commandText=text(entry,tostring(item.command),13,C.text,true)
                commandText.Position=UDim2.fromOffset(12,35)
                commandText.Size=UDim2.new(1,-24,0,25)
                local detail=text(entry,tostring(item.message),12,C.muted)
                detail.Position=UDim2.fromOffset(12,63)
                detail.Size=UDim2.new(1,-24,0,28)
            end
        end
    end
    render=function()
        if not root.Parent then return end
        clearBody()
        body.CanvasPosition=Vector2.zero
        for key,b in navButtons do
            local activeTab=key==currentTab
            b.BackgroundColor3=if activeTab then C.hover else C.card
            b.TextColor3=if activeTab then C.accent else C.muted
        end
        if currentTab=="overview" then drawOverview()
        elseif currentTab=="god" or currentTab=="fly" then drawGodOrFlight(currentTab)
        elseif currentTab=="team" then drawTeam()
        elseif currentTab=="rank" then drawRank()
        elseif currentTab=="command" then drawCommand()
        else drawLogs() end
        root:SetAttribute("Tab",currentTab)
    end

    for index,spec in NAV do
        local b=button(nav,spec[2],UDim2.new(1,-4,0,39),C.card)
        b.Name="Tab_"..spec[1]
        b.LayoutOrder=index
        b.Activated:Connect(function() jump(spec[1]) end)
        navButtons[spec[1]]=b
    end
    local function updateLayout()
        local narrow=root.AbsoluteSize.X<590
        navLayout.FillDirection=if narrow then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
        for _,b in navButtons do
            b.Size=if narrow then UDim2.fromOffset(82,38) else UDim2.new(1,-4,0,39)
            b.TextSize=if narrow then 12 else 13
        end
        if narrow then
            title.TextSize=15
            title.Size=UDim2.new(1,-141,0,30)
            badge.Size=UDim2.fromOffset(118,30)
            badge.Position=UDim2.new(1,-132,0,8)
            nav.Position=UDim2.fromOffset(10,67)
            nav.Size=UDim2.new(1,-20,0,50)
            body.Position=UDim2.fromOffset(10,123)
            body.Size=UDim2.new(1,-20,1,-166)
        else
            title.TextSize=18
            title.Size=UDim2.new(1,-172,0,30)
            badge.Size=UDim2.fromOffset(134,30)
            badge.Position=UDim2.new(1,-152,0,8)
            nav.Position=UDim2.fromOffset(10,70)
            nav.Size=UDim2.new(0,144,1,-112)
            body.Position=UDim2.fromOffset(164,70)
            body.Size=UDim2.new(1,-174,1,-112)
        end
    end
    root:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
    updateLayout()

    confirmNo.Activated:Connect(function() pendingHQTarget=nil;dialog.Visible=false end)
    confirmYes.Activated:Connect(function()
        if not pendingHQTarget then return end
        local username=pendingHQTarget
        pendingHQTarget=nil
        dialog.Visible=false
        run("/팀 "..username.." HQ")
    end)
    response.OnClientEvent:Connect(function(kind: string,data: any)
        if not isHQ(player) then return end
        if kind=="result" and type(data)=="table" then
            status(tostring(data.message or "응답 없음"),data.ok==true)
        elseif kind=="log" and type(data)=="table" then
            table.insert(activity,data)
            if #activity>60 then table.remove(activity,1) end
            if active and currentTab=="logs" then render() end
        elseif kind=="snapshot" and type(data)=="table" then
            table.clear(activity)
            for _,entry in data do
                if type(entry)=="table" then table.insert(activity,entry) end
            end
            if active and currentTab=="logs" then render() end
        end
    end)
    Players.PlayerAdded:Connect(function() if active and currentTab=="overview" then render() end end)
    Players.PlayerRemoving:Connect(function() if active and currentTab=="overview" then render() end end)
    local function show(visible: boolean)
        active=visible and isHQ(player)
        root.Visible=active
        dialog.Visible=false
        pendingHQTarget=nil
        if active then
            currentTab="overview"
            pickerVisible=false
            status("HQ 권한 확인 완료 · 명령 대기 중",true)
            render()
            request:FireServer("sync")
        end
    end
    return show
end
return Panel
