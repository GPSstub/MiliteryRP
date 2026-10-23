--!strict
-- Session-local exam board. All authority and participants are on the server.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ExamRules"))
local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local Formation=require(script.Parent:WaitForChild("ExamFormation"))
local RankService=require(script.Parent:WaitForChild("RankService"))

local request=Instance.new("RemoteFunction")
request.Name="ExamBoardRequest"
request.Parent=ReplicatedStorage
local changed=Instance.new("RemoteEvent")
changed.Name="ExamBoardChanged"
changed.Parent=ReplicatedStorage

local command=Instance.new("RemoteEvent")
command.Name="ExamDrillCommand"
command.Parent=ReplicatedStorage

local board=Rules.new()
local lastMutate: {[Player]: number}={}
local lastRead: {[Player]: number}={}
local rankConnections: {[Player]: RBXScriptConnection}={}
local characterConnections: {[Player]: RBXScriptConnection}={}

local function hostRank(player: Player): any
    if player.Parent~=Players or player:GetAttribute("RankStorageStatus")~="Ready" then return nil end
    return RankService.get(player)
end

local function canHost(player: Player): boolean
    return Rules.canHost(hostRank(player))
end

local function announce()
    Formation.reconcile(board.sessions)
    changed:FireAllClients(board.revision)
end

local function remove(player: Player)
    local updated,didChange=Rules.removePlayer(board,player.UserId)
    if didChange then
        board=updated
        announce()
    end
end

local function track(player: Player)
    if rankConnections[player] then return end
    characterConnections[player]=player.CharacterRemoving:Connect(function()
        for _,exam in board.sessions do
            if exam.phase=="running" and (exam.hostId==player.UserId or exam.participants[player.UserId]) then
                remove(player)
                break
            end
        end
    end)
    rankConnections[player]=player:GetAttributeChangedSignal("RankId"):Connect(function()
        local rank=RankService.get(player)
        local incompatible=false
        for _,exam in board.sessions do
            if (exam.hostId==player.UserId and not Rules.canHost(rank))
                or (exam.participants[player.UserId] and (not rank or rank.id~=exam.targetId)) then
                incompatible=true;break
            end
        end
        if incompatible then remove(player) else announce() end
    end)
end

local function identity(player: Player): any
    local rank=RankService.get(player)
    return {
        userId=player.UserId,
        username=player.Name,
        displayName=player.DisplayName,
        rank=if rank then rank.name else "계급 확인 중",
    }
end

local function snapshot(player: Player): any
    local result={revision=board.revision,maxActive=Rules.MAX_ACTIVE,maxParticipants=Rules.MAX_PARTICIPANTS,
        canCreate=canHost(player) and not Rules.busy(board,player.UserId),
        rankId=(hostRank(player) or {}).id,sessions={}}
    for _,exam in board.sessions do
        local host=Players:GetPlayerByUserId(exam.hostId)
        if host then
            local participants={}
            for userId in exam.participants do
                local participant=Players:GetPlayerByUserId(userId)
                if participant then table.insert(participants,identity(participant)) end
            end
            table.sort(participants,function(a,b) return a.userId<b.userId end)
            local target=Catalog.find(exam.targetId)
            table.insert(result.sessions,{
                id=exam.id,targetId=exam.targetId,
                targetName=if target then target.name else "알 수 없음",
                host=identity(host),participants=participants,
                startedAt=exam.startedAt,phase=exam.phase or "recruiting",areaIndex=exam.areaIndex,
            })
        end
    end
    return result
end

request.OnServerInvoke=function(player: Player,action: any,payload: any): any
    if player.Parent~=Players or type(action)~="string" or #action>16 then
        return {ok=false,message="잘못된 시험 요청입니다."}
    end
    local now=os.clock()
    if action=="snapshot" then
        if now-(lastRead[player] or -math.huge)<0.2 then
            return {ok=false,message="조회 요청이 너무 빠릅니다."}
        end
        lastRead[player]=now
        return {ok=true,data=snapshot(player)}
    end
    if now-(lastMutate[player] or -math.huge)<0.4 then
        return {ok=false,message="잠시 후 다시 시도하세요."}
    end
    lastMutate[player]=now
    if type(payload)~="table" then return {ok=false,message="요청 형식이 잘못되었습니다."} end
    local targetId=payload.targetId
    local examId=payload.examId
    if targetId~=nil and (type(targetId)~="string" or #targetId>40) then
        return {ok=false,message="계급 형식이 잘못되었습니다."}
    end
    if examId~=nil and (type(examId)~="string" or #examId>24) then
        return {ok=false,message="시험 번호 형식이 잘못되었습니다."}
    end
    local rank=hostRank(player)
    local actor={userId=player.UserId,canHost=Rules.canHost(rank),rankId=if rank then rank.id else nil}
    local selected: any=nil
    for _,exam in board.sessions do if exam.id==examId then selected=exam;break end end
    if action=="command" then
        if not selected or selected.hostId~=player.UserId or not actor.canHost
            or selected.phase~="running" or not Rules.isCommand(payload.command) then
            return {ok=false,message="진행 중인 시험의 개최자만 구령을 전달할 수 있습니다."}
        end
        for userId in selected.participants do
            local participant=Players:GetPlayerByUserId(userId)
            if participant then command:FireClient(participant,payload.command,player.DisplayName) end
        end
        return {ok=true,message="구령 전달: "..payload.command,data=snapshot(player)}
    end
    local updated,message=Rules.apply(board,actor,action,targetId,examId,os.time())
    if updated and action=="start" then
        local ready,reason=Formation.ready(selected)
        if not ready then return {ok=false,message=reason} end
        Formation.start(selected)
    end
    if not updated then return {ok=false,message=message} end
    board=updated
    announce()
    return {ok=true,message=message,data=snapshot(player)}
end

Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
    local connection=rankConnections[player]
    if connection then connection:Disconnect();rankConnections[player]=nil end
    local characterConnection=characterConnections[player]
    if characterConnection then characterConnection:Disconnect();characterConnections[player]=nil end
    lastMutate[player]=nil
    lastRead[player]=nil
    remove(player)
end)
for _,player in Players:GetPlayers() do track(player) end
