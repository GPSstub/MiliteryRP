--!strict
-- Server-controlled target picker for ambiguous partial usernames / DisplayNames.
-- The client receives a candidate list but can only select a UserId that this
-- server explicitly offered for this actor and this short-lived request.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TeamService=require(script.Parent:WaitForChild("TeamService"))
local Matcher=require(script.Parent:WaitForChild("AdminTargetMatch"))

type Pending={
    ticket: number,
    expires: number,
    allowed: {[number]: Player},
    completion: (Player)->(boolean,string),
}
local pending: {[Player]: Pending}={}
local ticketCounter=0
local remote: RemoteEvent?=nil
local Picker={}

local function reply(actor: Player,kind: string,data: any)
    if remote and actor.Parent==Players then
        remote:FireClient(actor,kind,data)
    end
end

function Picker.start()
    if remote then return end
    local event=Instance.new("RemoteEvent")
    event.Name="AdminTargetSelection"
    remote=event
    event.OnServerEvent:Connect(function(actor: Player,action: any,ticket: any,id: any)
        if type(ticket)~="number" or ticket%1~=0 then return end
        local item=pending[actor]
        if not item or item.ticket~=ticket then return end
        if action=="cancel" then
            pending[actor]=nil
            reply(actor,"dismiss",{})
            return
        end
        if action~="choose" or type(id)~="number" or id%1~=0 then return end
        -- Consume BEFORE executing: a forged replay cannot run the same
        -- dangerous command twice, even if execution yields or errors.
        pending[actor]=nil
        if os.clock()>item.expires then
            reply(actor,"result",{ok=false,message="선택 시간이 지났습니다. 명령어를 다시 입력하세요."})
            return
        end
        if not TeamService.isAdmin(actor) then
            reply(actor,"result",{ok=false,message="그룹 운영진 권한이 확인되지 않아 취소했습니다."})
            return
        end
        local selected=item.allowed[id]
        if not selected or selected.Parent~=Players then
            reply(actor,"result",{ok=false,message="선택한 플레이어가 서버에 없습니다. 다시 시도하세요."})
            return
        end
        local success,ok,message=pcall(item.completion,selected)
        if not success then
            warn("[AdminTargetSelection] Completion failed:",ok)
            reply(actor,"result",{ok=false,message="명령어 실행에 실패했습니다. Output을 확인하세요."})
            return
        end
        reply(actor,"result",{ok=ok==true,message=tostring(message)})
    end)
    event.Parent=ReplicatedStorage
    Players.PlayerRemoving:Connect(function(player)
        pending[player]=nil
    end)
end

function Picker.resolve(actor: Player,query: string,
        completion: (Player)->(boolean,string)): (Player?,string?)
    if not Matcher.validQuery(query) then
        return nil,"대상 이름이나 표시 닉네임을 입력하세요. 'all' 같은 전체 지정은 지원하지 않습니다."
    end
    if query=="나" or string.lower(query)=="me" then
        return actor,nil
    end
    local options=Matcher.find(Players:GetPlayers(),query)
    if #options==0 then
        return nil,"일치하는 사람이 없습니다. 사용자 이름 또는 표시 닉네임을 확인하세요."
    end
    if #options==1 then return options[1],nil end
    if not TeamService.isAdmin(actor) then
        return nil,"운영진 권한이 없어 플레이어 목록을 열 수 없습니다."
    end
    Picker.start()
    ticketCounter+=1
    local allowed: {[number]: Player}={}
    local list={}
    for _,player in options do
        allowed[player.UserId]=player
        table.insert(list,{
            userId=player.UserId,
            username=player.Name,
            displayName=player.DisplayName,
        })
    end
    pending[actor]={
        ticket=ticketCounter,
        expires=os.clock()+30,
        allowed=allowed,
        completion=completion,
    }
    reply(actor,"open",{ticket=ticketCounter,query=query,candidates=list})
    return nil,tostring(#options).."명이 검색됐습니다. 화면에서 대상을 선택하세요."
end

return Picker
