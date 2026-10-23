--!strict
-- Pure, server-authoritative rules for a single live game server.
-- Exams are session-only; joining is not a pass and never promotes a player.
local Rules = {}
Rules.MAX_ACTIVE = 6
Rules.MAX_PARTICIPANTS = 10 -- per exam, excluding the host
Rules.COMMANDS = table.freeze({"우향우", "좌향우", "좌향좌", "우향좌", "앞으로서", "뒤로돌아", "시험관 주시"})

function Rules.isCommand(command: any): boolean
    return type(command)=="string" and table.find(Rules.COMMANDS,command)~=nil
end
Rules.TARGET_IDS = table.freeze({
    "private", "private_first_class", "corporal", "sergeant",
    "staff_sergeant", "sergeant_first_class", "master_sergeant", "sergeant_major",
})
local targetSet: {[string]: boolean} = {}
for _,id in Rules.TARGET_IDS do targetSet[id] = true end

function Rules.canHost(rank: any): boolean
    if type(rank)~="table" then return false end
    return rank.category=="위관" or rank.category=="영관" or rank.category=="장관"
end

function Rules.isTarget(rankId: any): boolean
    return type(rankId)=="string" and targetSet[rankId]==true
end

function Rules.new(): any
    return {revision=0,nextId=0,sessions={}}
end

local function copy(state: any): any
    local result={revision=state.revision,nextId=state.nextId,sessions={}}
    for _,exam in state.sessions do
        local attendees={}
        for userId,joined in exam.participants do attendees[userId]=joined end
        table.insert(result.sessions,{
            id=exam.id,hostId=exam.hostId,targetId=exam.targetId,
            startedAt=exam.startedAt,participants=attendees,phase=exam.phase,areaIndex=exam.areaIndex,
        })
    end
    return result
end

local function validUserId(id: any): boolean
    -- Studio multi-client test players may use negative UserIds.
    return type(id)=="number" and id~=0 and id%1==0 and math.abs(id)<math.huge
end

function Rules.valid(state: any): boolean
    if type(state)~="table" or type(state.revision)~="number" or state.revision<0
        or type(state.nextId)~="number" or state.nextId<0
        or type(state.sessions)~="table" or #state.sessions>Rules.MAX_ACTIVE then return false end
    local joined={}
    local ids={}
    local areas={}
    for _,exam in state.sessions do
        if type(exam)~="table" or type(exam.id)~="string"
            or not exam.id:match("^exam_%d+$") or ids[exam.id]
            or type(exam.areaIndex)~="number" or exam.areaIndex%1~=0
            or exam.areaIndex<1 or exam.areaIndex>Rules.MAX_ACTIVE or areas[exam.areaIndex]
            or not validUserId(exam.hostId)
            or not Rules.isTarget(exam.targetId)
            or (exam.phase~=nil and exam.phase~="recruiting" and exam.phase~="running")
            or type(exam.startedAt)~="number" or type(exam.participants)~="table" then return false end
        if joined[exam.hostId] then return false end
        joined[exam.hostId]=true
        ids[exam.id]=true
        areas[exam.areaIndex]=true
        local participantCount=0
        for userId,active in exam.participants do
            participantCount+=1
            if participantCount>Rules.MAX_PARTICIPANTS then return false end
            if not validUserId(userId) or active~=true or joined[userId]
                or userId==exam.hostId then return false end
            joined[userId]=true
        end
    end
    return true
end

local function locate(state: any,examId: any): (number?,any?)
    if type(examId)~="string" or #examId>24 then return nil,nil end
    for index,exam in state.sessions do
        if exam.id==examId then return index,exam end
    end
    return nil,nil
end

function Rules.busy(state: any,userId: number): boolean
    for _,exam in state.sessions do
        if exam.hostId==userId or exam.participants[userId] then return true end
    end
    return false
end

-- Context is built on the server from RankService, never from remote payloads.
function Rules.apply(state: any,actor: any,action: any,targetId: any,examId: any,now: any): (any?,string)
    if not Rules.valid(state) or type(actor)~="table" or not validUserId(actor.userId)
        or type(action)~="string" then return nil,"잘못된 시험 요청입니다." end
    local nextState=copy(state)
    if action=="create" then
        if actor.canHost~=true then return nil,"위관급 이상의 계급만 시험을 개최할 수 있습니다." end
        if Rules.busy(state,actor.userId) then return nil,"이미 시험을 개최하거나 참가 중입니다. 먼저 종료 또는 참가 취소해 주세요." end
        if not Rules.isTarget(targetId) then return nil,"선택할 수 없는 시험 계급입니다." end
        if #nextState.sessions>=Rules.MAX_ACTIVE then return nil,"동시에 개최 가능한 시험은 6개입니다." end
        local used={}
        for _,exam in nextState.sessions do used[exam.areaIndex]=true end
        local areaIndex=1
        while used[areaIndex] do areaIndex+=1 end
        nextState.nextId+=1
        table.insert(nextState.sessions,{
            id="exam_"..tostring(nextState.nextId),
            hostId=actor.userId,targetId=targetId,
            startedAt=if type(now)=="number" and now>=0 then now else 0,
            participants={},phase="recruiting",areaIndex=areaIndex,
        })
    elseif action=="join" then
        local _,exam=locate(nextState,examId)
        if not exam then return nil,"종료되었거나 존재하지 않는 시험입니다." end
        if exam.phase=="running" then return nil,"이미 시작한 시험입니다." end
        if exam.hostId==actor.userId then return nil,"자신이 개최한 시험에는 참가할 수 없습니다." end
        if exam.participants[actor.userId] then return nil,"이미 참가한 시험입니다." end
        for _,other in nextState.sessions do
            if other.participants[actor.userId] then return nil,"다른 시험에 참가 중입니다." end
        end
        if Rules.busy(state,actor.userId) then return nil,"이미 다른 시험을 개최하거나 참가 중입니다." end
        if actor.rankId~=exam.targetId then return nil,"시험 계급과 현재 계급이 같아야 참가할 수 있습니다." end
        local participantCount=0
        for _ in exam.participants do participantCount+=1 end
        if participantCount>=Rules.MAX_PARTICIPANTS then
            return nil,"시험 정원("..tostring(Rules.MAX_PARTICIPANTS).."명)이 가득 찼습니다."
        end
        exam.participants[actor.userId]=true
    elseif action=="leave" then
        local _,exam=locate(nextState,examId)
        if not exam or not exam.participants[actor.userId] then return nil,"참가 중인 시험이 아닙니다." end
        exam.participants[actor.userId]=nil
    elseif action=="start" then
        local _,exam=locate(nextState,examId)
        if not exam or exam.hostId~=actor.userId or actor.canHost~=true then
            return nil,"개최자만 시험을 시작할 수 있습니다."
        end
        if exam.phase=="running" then return nil,"이미 시작한 시험입니다." end
        if next(exam.participants)==nil then return nil,"참가자가 필요합니다." end
        exam.phase="running"
    elseif action=="close" then
        local index,exam=locate(nextState,examId)
        if not exam then return nil,"종료되었거나 존재하지 않는 시험입니다." end
        if exam.hostId~=actor.userId then return nil,"개최자만 시험을 종료할 수 있습니다." end
        table.remove(nextState.sessions,index)
    else
        return nil,"지원하지 않는 시험 요청입니다."
    end
    nextState.revision+=1
    assert(Rules.valid(nextState),"Exam state corrupted")
    return nextState,"완료되었습니다."
end

-- Players who disconnect are removed from attendee rosters. Their hosted exam
-- is closed, returning the slot immediately. This has no DataStore side effects.
function Rules.removePlayer(state: any,userId: number): (any,boolean)
    if not validUserId(userId) then return state,false end
    local nextState=copy(state)
    local changed=false
    for i=#nextState.sessions,1,-1 do
        local exam=nextState.sessions[i]
        if exam.hostId==userId then
            table.remove(nextState.sessions,i)
            changed=true
        elseif exam.participants[userId] then
            exam.participants[userId]=nil
            changed=true
        end
    end
    if changed then nextState.revision+=1 end
    return nextState,changed
end

return table.freeze(Rules)
