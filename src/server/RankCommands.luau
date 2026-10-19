--!strict
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local RankService=require(script.Parent:WaitForChild("RankService"))
local Parser=require(script.Parent:WaitForChild("RankCommandParser"))
-- Current user's Roblox account, confirmed from their local Studio playtest.
-- This restricts only these edit commands; military ranks confer no permissions.
local COMMAND_OWNER_USER_ID=1153125948
local lastCommand: {[Player]: number}={}
local started=false
local Commands={}
local Audit=require(script.Parent:WaitForChild("AdminAudit"))
local function handle(actor: Player, text: any): (boolean, string)
    if typeof(actor)~="Instance" or not actor:IsA("Player") or actor.Parent~=Players
        or actor.UserId~=COMMAND_OWNER_USER_ID then
        return false,"계급 변경 명령어는 제작자 전용입니다."
    end
    local now=os.clock()
    if now-(lastCommand[actor] or -math.huge)<0.5 then return false,"잠시 후 다시 입력하세요." end
    lastCommand[actor]=now
    local command=Parser.parse(text)
    if not command then return false,"사용법: /계급 대위 또는 /계급 플레이어명 병장 · /계급목록" end
    if command.kind=="list" then
        local names: {string}={}
        for _,rank in Catalog.All do table.insert(names,rank.name) end
        return true,table.concat(names," · ")
    end
    local rank=nil
    for _,candidate in Catalog.All do
        if candidate.name==command.rank or candidate.id==command.rank then rank=candidate;break end
    end
    if not rank then return false,"없는 계급입니다. /계급목록으로 확인하세요." end
    local target=actor
    if command.target and command.target~="me" and command.target~="나" then
        local match=nil
        for _,player in Players:GetPlayers() do
            if string.lower(player.Name)==string.lower(command.target) then match=player;break end
        end
        if not match then return false,"현재 서버의 정확한 Roblox 사용자 이름을 입력하세요." end
        target=match
    end
    if not RankService.set(target,rank.id) then return false,"플레이어가 나갔거나 계급 정보가 준비되지 않았습니다." end
    return true,target.Name.." → "..rank.name
end
function Commands.handle(actor: Player, text: any): (boolean, string)
    local ok,message=handle(actor,text)
    if typeof(actor)=="Instance" and actor:IsA("Player") and actor.Parent==Players and actor.UserId==COMMAND_OWNER_USER_ID and type(text)=="string" then
        Audit.record(actor,text,ok,message)
    end
    return ok,message
end
function Commands.start()
    if started then return end
    started=true
    local feedback=Instance.new("RemoteEvent")
    feedback.Name="RankCommandFeedback";feedback.Parent=ReplicatedStorage
    for _,spec in {{"SetMilitaryRank","/계급","/rank"},{"ListMilitaryRanks","/계급목록","/ranks"}} do
        local command=Instance.new("TextChatCommand")
        command.Name=spec[1];command.PrimaryAlias=spec[2];command.SecondaryAlias=spec[3]
        command.Triggered:Connect(function(source: TextSource, text: string)
            if not source then return end
            local actor=Players:GetPlayerByUserId(source.UserId)
            if not actor then return end
            local _,message=Commands.handle(actor,text)
            feedback:FireClient(actor,message)
        end)
        command.Parent=TextChatService
    end
    Players.PlayerRemoving:Connect(function(player: Player) lastCommand[player]=nil end)
end
return Commands
