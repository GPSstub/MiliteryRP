--!strict
-- Pure bounded per-channel permanent bulletin history.
-- A full archive rejects writes instead of silently discarding historical notices.
local Core = {}
Core.MAX_ENTRIES = 300
Core.PAGE_SIZE = 40

function Core.empty(): any
    return {version=1,nextSeq=1,revision=0,entries={}}
end

local function copy(value: any): any
    if type(value)~="table" then return value end
    local out={}
    for key,item in value do out[key]=copy(item) end
    return out
end

function Core.valid(value: any): boolean
    if type(value)~="table" or value.version~=1 or type(value.nextSeq)~="number"
        or value.nextSeq<1 or value.nextSeq%1~=0 or type(value.entries)~="table"
        or #value.entries>Core.MAX_ENTRIES or type(value.revision)~="number"
        or value.revision<0 or value.revision%1~=0 then return false end
    local lastSeq=0
    for _,item in value.entries do
        if type(item)~="table" or type(item.id)~="string" or type(item.text)~="string"
            or type(item.authorId)~="number" or type(item.seq)~="number"
            or item.seq<=lastSeq or item.seq%1~=0 or item.seq>=value.nextSeq
            or type(item.reactions)~="table" or type(item.pinned)~="boolean"
            or type(item.time)~="number" or #item.id>90 or #item.text>1200 then return false end
        lastSeq=item.seq
    end
    return true
end

function Core.find(data: any,id: string): (any?,number?)
    for index,item in data.entries do if item.id==id then return item,index end end
    return nil,nil
end

function Core.apply(source: any,operation: any): (any?,string)
    local data=if source==nil then Core.empty() else source
    if not Core.valid(data) then return nil,"손상되었거나 지원하지 않는 기록입니다." end
    local change=operation.action
    local updated=copy(data)
    local target,index=Core.find(updated,operation.id)
    if change=="append" then
        if target then
            if target.authorId==operation.entry.authorId then return updated,"이미 저장된 글입니다." end
            return nil,"메시지 ID가 중복되었습니다."
        end
        if #updated.entries>=Core.MAX_ENTRIES then
            return nil,"이 채널의 저장 한도(300개)에 도달했습니다. 관리자가 오래된 글을 삭제해야 합니다."
        end
        local entry=copy(operation.entry)
        if entry.replyTo or entry.threadRoot then
            local reference=Core.find(updated,entry.replyTo or entry.threadRoot)
            if not reference then return nil,"답장할 원본 글을 찾을 수 없습니다." end
        end
        entry.seq=updated.nextSeq
        updated.nextSeq+=1
        entry.reactions={};entry.pinned=false;entry.edited=false
        table.insert(updated.entries,entry)
    elseif change=="edit" then
        if not target then return nil,"수정할 글을 찾을 수 없습니다." end
        if target.authorId~=operation.authorId then return nil,"자신의 글만 수정할 수 있습니다." end
        target.text=operation.text
        target.edited=true
        target.editedAt=operation.time
    elseif change=="delete" then
        if not target then return nil,"삭제할 글이 없습니다." end
        if target.authorId~=operation.authorId and not operation.moderator then
            return nil,"자신의 글만 삭제할 수 있습니다."
        end
        table.remove(updated.entries,index)
    elseif change=="pin" then
        if not target or not operation.moderator then return nil,"고정 관리 권한이 없습니다." end
        target.pinned=not target.pinned
    elseif change=="react" then
        if not target then return nil,"반응할 글이 없습니다." end
        local emoji=operation.emoji
        if type(emoji)~="string" then return nil,"잘못된 반응입니다." end
        local users=target.reactions[emoji] or {}
        local user=tostring(operation.authorId)
        if users[user] then
            users[user]=nil
        else
            local n=0
            for _ in users do n+=1 end
            if n>=100 then return nil,"반응 인원 제한입니다." end
            users[user]=true
        end
        target.reactions[emoji]=users
    else
        return nil,"알 수 없는 기록 작업입니다."
    end
    updated.revision+=1
    return updated,"영구 저장 완료"
end

function Core.page(data: any,viewerId: number,before: number?,limit: number?): any
    if not Core.valid(data) then return {entries={},cursor=nil} end
    local maximum=math.clamp(tonumber(limit) or Core.PAGE_SIZE,1,Core.PAGE_SIZE)
    local untilSeq=if type(before)=="number" and before>0 then before else math.huge
    local chosen={}
    local oldest=math.huge
    local hasMore=false
    for index=#data.entries,1,-1 do
        local item=data.entries[index]
        if item.seq<untilSeq then
            if #chosen>=maximum then hasMore=true;break end
            oldest=item.seq
            local reactions={}
            for emoji,users in item.reactions do
                local count=0
                for _ in users do count+=1 end
                if count>0 then reactions[emoji]={count=count,mine=users[tostring(viewerId)]==true} end
            end
            table.insert(chosen,1,{
                id=item.id,seq=item.seq,userId=item.authorId,name=item.name,rank=item.rank,
                message=item.text,timeLabel=item.timeLabel,date=item.date,
                time=item.time,edited=item.edited,pinned=item.pinned,
                replyTo=item.replyTo,threadRoot=item.threadRoot,reactions=reactions,
            })
        end
    end
    return {entries=chosen,cursor=if hasMore then oldest else nil,revision=data.revision}
end

return Core
