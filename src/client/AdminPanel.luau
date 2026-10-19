--!strict
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Panel={}
local INK=Color3.fromRGB(36,44,38)
local PAPER=Color3.fromRGB(238,237,224)
local MUTED=Color3.fromRGB(163,174,157)
local ACCENT=Color3.fromRGB(192,210,150)
function Panel.mount(parent: Frame)
    local root=Instance.new("Frame");root.Name="AdminTools";root.BackgroundTransparency=1
    root.Position=UDim2.fromOffset(20,104);root.Size=UDim2.new(1,-40,1,-148);root.Visible=false;root.Parent=parent
    local request=ReplicatedStorage:WaitForChild("AdminRequest") :: RemoteEvent
    local response=ReplicatedStorage:WaitForChild("AdminResponse") :: RemoteEvent
    local active="command"
    local function round(object: GuiObject)
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=object
    end
    local function text(parentObject: Instance,name: string,value: string,height: number): TextLabel
        local t=Instance.new("TextLabel");t.Name=name;t.Text=value;t.Font=Enum.Font.GothamMedium;t.TextSize=14
        t.BackgroundTransparency=1;t.TextColor3=PAPER;t.TextXAlignment=Enum.TextXAlignment.Left
        t.Size=UDim2.new(1,0,0,height);t.TextWrapped=true;t.Parent=parentObject
        return t
    end
    local function button(parentObject: Instance,name: string,value: string): TextButton
        local b=Instance.new("TextButton");b.Name=name;b.Text=value;b.Font=Enum.Font.GothamBold;b.TextSize=14
        b.Size=UDim2.new(1,0,0,44);b.TextColor3=PAPER;b.BackgroundColor3=INK;b.BorderSizePixel=0
        b.Selectable=true;round(b);b.Parent=parentObject
        return b
    end
    local function box(parentObject: Instance,name: string,placeholder: string): TextBox
        local b=Instance.new("TextBox");b.Name=name;b.PlaceholderText=placeholder;b.Text="";b.ClearTextOnFocus=false
        b.Font=Enum.Font.GothamMedium;b.TextSize=14;b.TextColor3=PAPER;b.PlaceholderColor3=MUTED
        b.BackgroundColor3=INK;b.BorderSizePixel=0;b.Size=UDim2.new(1,0,0,44);b.TextXAlignment=Enum.TextXAlignment.Left
        round(b);local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12);pad.Parent=b
        b.Parent=parentObject
        return b
    end
    local tabs=Instance.new("Frame");tabs.Name="Tabs";tabs.Size=UDim2.new(1,0,0,44);tabs.BackgroundTransparency=1;tabs.Parent=root
    local content=Instance.new("ScrollingFrame");content.Name="Body";content.Position=UDim2.fromOffset(0,54)
    content.Size=UDim2.new(1,0,1,-54);content.BackgroundTransparency=1;content.BorderSizePixel=0
    content.ScrollBarThickness=4;content.ScrollBarImageColor3=ACCENT;content.AutomaticCanvasSize=Enum.AutomaticSize.Y
    content.CanvasSize=UDim2.new();content.Parent=root
    local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,8);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=content
    local padding=Instance.new("UIPadding");padding.PaddingRight=UDim.new(0,8);padding.PaddingBottom=UDim.new(0,8);padding.Parent=content
    local target=box(content,"TargetName","대상 사용자 이름 (나 / 정확한 Roblox 이름)");target.Text="나";target.LayoutOrder=1
    local choosePlayer=button(content,"ChoosePlayer","닉네임 목록에서 선택  ▾");choosePlayer.LayoutOrder=2
    local playerOptions=Instance.new("ScrollingFrame");playerOptions.Name="PlayerOptions";playerOptions.Visible=false
    playerOptions.Size=UDim2.new(1,0,0,120);playerOptions.BackgroundTransparency=1;playerOptions.BorderSizePixel=0
    playerOptions.AutomaticCanvasSize=Enum.AutomaticSize.Y;playerOptions.CanvasSize=UDim2.new();playerOptions.ScrollBarThickness=4;playerOptions.LayoutOrder=3;playerOptions.Parent=content
    local pl=Instance.new("UIListLayout");pl.Padding=UDim.new(0,4);pl.Parent=playerOptions
    choosePlayer.Activated:Connect(function()
        playerOptions.Visible=not playerOptions.Visible
        if not playerOptions.Visible then return end
        for _,child in playerOptions:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
        for _,player in Players:GetPlayers() do
            local b=button(playerOptions,"Player_"..player.UserId,player.DisplayName.."  @"..player.Name)
            b.Activated:Connect(function() target.Text=player.Name;playerOptions.Visible=false end)
        end
    end)
    local pages: {[string]: Frame}={}
    for _,name in {"command","god","fly","team","rank"} do
        local frame=Instance.new("Frame");frame.Name=name;frame.BackgroundTransparency=1
        frame.Size=UDim2.new(1,0,0,if name=="team" or name=="rank" then 226 elseif name=="command" then 132 else 118)
        frame.LayoutOrder=4;frame.Visible=name=="command";frame.Parent=content;pages[name]=frame
    end
    local command=box(pages.command,"CommandInput","/계급 대위 · /무적 나 켜기 · /비행 나 끄기")
    local send=button(pages.command,"RunCommand","명령어 실행");send.Position=UDim2.fromOffset(0,52)
    local hint=text(pages.command,"Hint","허용된 관리 명령만 실행됩니다. Luau 코드 실행 기능은 없습니다.",28);hint.Position=UDim2.fromOffset(0,102);hint.TextColor3=MUTED;hint.TextSize=12
    local status=text(content,"Status","명령을 실행하면 여기에 결과가 표시됩니다.",40);status.LayoutOrder=5;status.TextColor3=MUTED
    local function run(value: string)
        if #value>256 then status.Text="명령어가 너무 깁니다.";return end
        status.Text="실행 중…";request:FireServer("command",value)
    end
    local function submit()
        if command.Text:match("%S") then run(command.Text);command:ReleaseFocus(false) end
    end
    send.Activated:Connect(submit)
    command.FocusLost:Connect(function(enterPressed) if enterPressed then submit() end end)
    local function name(): string
        return if target.Text:match("%S") then target.Text else "나"
    end
    for _,spec in {{"god","무적", "/무적"},{"fly","비행","/비행"}} do
        local page=pages[spec[1]]
        local description=text(page,"Description",if spec[1]=="god" then "선택한 플레이어의 무적 모드를 변경합니다." else "WASD 이동 · Space/E 상승 · Q/Ctrl 하강",26)
        description.TextColor3=MUTED
        local on=button(page,"Enable","켜기");on.Position=UDim2.fromOffset(0,36);on.Size=UDim2.new(0.5,-4,0,44)
        local off=button(page,"Disable","끄기");off.Position=UDim2.new(0.5,4,0,36);off.Size=UDim2.new(0.5,-4,0,44)
        on.Activated:Connect(function() run(spec[3].." "..name().." 켜기") end)
        off.Activated:Connect(function() run(spec[3].." "..name().." 끄기") end)
    end
    local selectedTeam: Team?=nil
    local teamChoice=button(pages.team,"ChooseTeam","팀 선택  ▾")
    local teamOptions=Instance.new("ScrollingFrame");teamOptions.Name="TeamOptions";teamOptions.Position=UDim2.fromOffset(0,50)
    teamOptions.Size=UDim2.new(1,0,0,114);teamOptions.BackgroundTransparency=1;teamOptions.BorderSizePixel=0
    teamOptions.ScrollBarThickness=4;teamOptions.CanvasSize=UDim2.new();teamOptions.AutomaticCanvasSize=Enum.AutomaticSize.Y
    teamOptions.Parent=pages.team
    local tl=Instance.new("UIListLayout");tl.Padding=UDim.new(0,4);tl.Parent=teamOptions
    local function refreshTeams()
        for _,child in teamOptions:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
        local teams=Teams:GetTeams()
        if selectedTeam and selectedTeam.Parent~=Teams then selectedTeam=nil end
        teamChoice.Text=if selectedTeam then "선택: "..selectedTeam.Name else "팀 선택  ▾"
        if #teams==0 then local note=text(teamOptions,"NoTeams","등록된 팀이 없습니다.",44);note.TextColor3=MUTED end
        for _,team in teams do
            local b=button(teamOptions,"Team_"..team.Name,team.Name)
            b.Activated:Connect(function() selectedTeam=team;teamChoice.Text="선택: "..team.Name end)
        end
    end
    teamChoice.Activated:Connect(refreshTeams)
    Teams.ChildAdded:Connect(refreshTeams);Teams.ChildRemoved:Connect(refreshTeams);refreshTeams()
    local apply=button(pages.team,"ApplyTeam","선택한 플레이어의 팀 변경");apply.Position=UDim2.fromOffset(0,174)
    apply.Activated:Connect(function()
        if selectedTeam then run("/팀 "..name().." "..selectedTeam.Name)
        else status.Text="먼저 등록된 팀을 선택하세요." end
    end)
    local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
    local selectedRank: string?=nil
    local rankChoice=button(pages.rank,"ChooseRank","계급 선택  ▾")
    local rankOptions=Instance.new("ScrollingFrame");rankOptions.Name="RankOptions"
    rankOptions.Position=UDim2.fromOffset(0,50);rankOptions.Size=UDim2.new(1,0,0,114)
    rankOptions.BackgroundTransparency=1;rankOptions.BorderSizePixel=0;rankOptions.ScrollBarThickness=4
    rankOptions.AutomaticCanvasSize=Enum.AutomaticSize.Y;rankOptions.CanvasSize=UDim2.new();rankOptions.Parent=pages.rank
    local rl=Instance.new("UIListLayout");rl.Padding=UDim.new(0,4);rl.Parent=rankOptions
    for _,rank in Catalog.All do
        local b=button(rankOptions,"Rank_"..rank.id,rank.name)
        b.Activated:Connect(function() selectedRank=rank.name;rankChoice.Text="선택: "..rank.name end)
    end
    rankChoice.Activated:Connect(function() rankOptions.CanvasPosition=Vector2.zero end)
    local applyRank=button(pages.rank,"ApplyRank","선택한 플레이어의 계급 변경");applyRank.Position=UDim2.fromOffset(0,174)
    applyRank.Activated:Connect(function()
        if selectedRank then run("/계급 "..name().." "..selectedRank)
        else status.Text="먼저 계급을 선택하세요." end
    end)
    local logTitle=text(content,"LogHeading","명령어 사용 기록  ·  현재 서버 / 최근 60개",14);logTitle.LayoutOrder=6;logTitle.TextColor3=ACCENT;logTitle.TextSize=12
    local logs=Instance.new("ScrollingFrame");logs.Name="CommandHistory";logs.Size=UDim2.new(1,0,0,180)
    logs.BackgroundColor3=Color3.fromRGB(17,23,19);logs.BorderSizePixel=0;logs.ScrollBarThickness=4
    logs.AutomaticCanvasSize=Enum.AutomaticSize.Y;logs.CanvasSize=UDim2.new();logs.LayoutOrder=7;round(logs);logs.Parent=content
    local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,6);ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Parent=logs
    local lp=Instance.new("UIPadding");lp.PaddingLeft=UDim.new(0,10);lp.PaddingRight=UDim.new(0,10);lp.PaddingTop=UDim.new(0,8);lp.PaddingBottom=UDim.new(0,8);lp.Parent=logs
    local placeholder=text(logs,"NoHistory","아직 사용 기록이 없습니다.",38);placeholder.TextColor3=MUTED
    local rows: {TextLabel}={}
    local order=0
    local function append(entry: any)
        if type(entry)~="table" then return end
        placeholder.Visible=false;order+=1
        local row=text(logs,"Entry",os.date("%H:%M:%S",entry.time).."  @"..entry.name.."\n"..entry.command.."\n"..(if entry.ok then "완료 · " else "실패 · ")..entry.message,70)
        row.TextSize=12;row.TextYAlignment=Enum.TextYAlignment.Top;row.LayoutOrder=order
        row.TextColor3=if entry.ok then PAPER else Color3.fromRGB(237,177,153)
        table.insert(rows,row)
        if #rows>60 then table.remove(rows,1):Destroy() end
        task.defer(function() logs.CanvasPosition=Vector2.new(0,math.max(0,logs.AbsoluteCanvasSize.Y-logs.AbsoluteWindowSize.Y)) end)
    end
    response.OnClientEvent:Connect(function(kind: string,data: any)
        if kind=="result" then status.Text=data.message;status.TextColor3=if data.ok then ACCENT else Color3.fromRGB(237,177,153)
        elseif kind=="log" then append(data)
        elseif kind=="snapshot" then
            for _,row in rows do row:Destroy() end;table.clear(rows);placeholder.Visible=true
            for _,entry in data do append(entry) end
        end
    end)
    local tabButtons: {[string]: TextButton}={}
    for i,spec in {{"command","명령어"},{"god","무적"},{"fly","비행"},{"team","팀 변경"},{"rank","계급"}} do
        local b=button(tabs,"Tab_"..spec[1],spec[2]);b.Position=UDim2.fromScale((i-1)/5,0);b.Size=UDim2.new(0.2,-4,1,0);tabButtons[spec[1]]=b
        b.Activated:Connect(function()
            active=spec[1];root:SetAttribute("Tab",active)
            for key,page in pages do page.Visible=key==active end
            for key,tab in tabButtons do tab.TextColor3=if key==active then ACCENT else MUTED end
            content.CanvasPosition=Vector2.zero
        end)
    end
    tabButtons.command.TextColor3=ACCENT
    local function show(visible: boolean)
        root.Visible=visible
        if visible then request:FireServer("sync") end
    end
    return show
end
return Panel
