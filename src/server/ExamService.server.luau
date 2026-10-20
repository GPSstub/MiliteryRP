--!strict
-- Session-local exam board. All authority and participants are on the server.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ExamRules"))
local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local RankService=require(script.Parent:WaitForChild("RankService"))

local request=Instance.new("RemoteFunction")
request.Name="ExamBoardRequest"
request.Parent=ReplicatedStorage
local changed=Instance.new("RemoteEvent")
changed.Name="ExamBoardChanged"
changed.Parent=ReplicatedStorage

local board=Rules.new()
local lastMutate: {[Player]: number}={}
local lastRead: {[Player]: number}={}
local rankConnections: {[Player]: RBXScriptConnection}={}

local function hostRank(player: Player): any
    if player.Parent~=Players or player:GetAttribute("RankStorageStatus")~="Ready" then return nil end
    return RankService.get(player)
end

local function canHost(player: Player): boolean
    return Rules.canHost(hostRank(player))
end

local function announce()
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
    rankConnections[player]=player:GetAttributeChangedSignal("RankId"):Connect(function()
        -- A demoted or departed host must not keep a privileged exam open.
        local hosts=false
        for _,exam in board.sessions do
            if exam.hostId==player.UserId then hosts=true;break end
        end
        if hosts and not canHost(player) then
            remove(player)
        elseif hosts then
            announce() -- Publish their new rank label to all viewers.
        end
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
    local result={revision=board.revision,maxActive=Rules.MAX_ACTIVE,
        canCreate=canHost(player),sessions={}}
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
                startedAt=exam.startedAt,
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
    local actor={userId=player.UserId,canHost=canHost(player)}
    local updated,message=Rules.apply(board,actor,action,targetId,examId,os.time())
    if not updated then return {ok=false,message=message} end
    board=updated
    announce()
    return {ok=true,message=message,data=snapshot(player)}
end

Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
    local connection=rankConnections[player]
    if connection then connection:Disconnect();rankConnections[player]=nil end
    lastMutate[player]=nil
    lastRead[player]=nil
    remove(player)
end)
for _,player in Players:GetPlayers() do track(player) end
