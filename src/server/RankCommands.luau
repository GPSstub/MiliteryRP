--!strict
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankCatalog"))
local RankService=require(script.Parent:WaitForChild("RankService"))
local Parser=require(script.Parent:WaitForChild("RankCommandParser"))
local TeamService=require(script.Parent:WaitForChild("TeamService"))
local TargetPicker=require(script.Parent:WaitForChild("AdminTargetSelection"))
-- Administrator commands are authorized by server-verified Roblox group rank.
-- No team transfer or rank promotion can grant administrator authority.
local lastCommand: {[Player]: number}={}
local started=false
local Commands={}
local Audit=require(script.Parent:WaitForChild("AdminAudit"))
local function handle(actor: Player, text: any): (boolean, string, boolean?)
    if typeof(actor)~="Instance" or not actor:IsA("Player") or actor.Parent~=Players
        or not TeamService.isAdmin(actor) then
        return false,"계급 변경 명령어는 Roblox 그룹 운영진 전용입니다."
    end
    local now=os.clock()
    if now-(lastCommand[actor] or -math.huge)<0.5 then
        return false,"잠시 후 다시 입력하세요."
    end
    lastCommand[actor]=now
    TargetPicker.clear(actor)
    local command=Parser.parse(text)
    if not command then
        return false,"사용법: ;계급 대위 · ;계급 닉네임 대위 · ;계급목록"
    end
    if command.kind=="list" then
        TargetPicker.clear(actor)
        local names: {string}={}
        for _,rank in Catalog.All do table.insert(names,rank.name) end
        return true,table.concat(names," · ")
    end
    local rank=nil
    for _,candidate in Catalog.All do
        if candidate.name==command.rank or candidate.id==command.rank then rank=candidate;break end
    end
    if not rank then return false,"없는 계급입니다. ;계급목록으로 확인하세요." end
    local desiredId=rank.id
    local desiredName=rank.name
    local function applyTo(selected: Player): (boolean,string)
        -- Pending selections are validated again before the persistent write.
        if not TeamService.isAdmin(actor) or selected.Parent~=Players then
            return false,"그룹 운영진 권한 또는 대상 접속 상태를 다시 확인하세요."
        end
        local saved,saveError=RankService.set(selected,desiredId)
        local success=saved==true
        local message=if success then selected.Name.." → "..desiredName
            else saveError or "계급을 저장하지 못했습니다."
        Audit.record(actor,text,success,message)
        return success,message
    end
    if not command.target then
        TargetPicker.clear(actor)
        local saved,saveError=RankService.set(actor,desiredId)
        return saved,if saved then actor.Name.." → "..desiredName
            else saveError or "계급을 저장하지 못했습니다."
    end
    local found,reason,pending=TargetPicker.resolve(actor,command.target,applyTo)
    if not found then
        return false,reason or "대상 플레이어를 찾지 못했습니다.",pending
    end
    local saved,saveError=RankService.set(found,desiredId)
    return saved,if saved then found.Name.." → "..desiredName
        else saveError or "계급을 저장하지 못했습니다."
end
function Commands.handle(actor: Player, text: any): (boolean, string, boolean?)
    local ok,message,pending=handle(actor,text)
    if not pending and typeof(actor)=="Instance" and actor:IsA("Player")
        and TeamService.isAdmin(actor) and type(text)=="string" then
        Audit.record(actor,text,ok,message)
    end
    return ok,message,pending
end
function Commands.start()
    if started then return end
    started=true
    TeamService.start()
    TargetPicker.start()
    local feedback=Instance.new("RemoteEvent")
    feedback.Name="RankCommandFeedback";feedback.Parent=ReplicatedStorage
    -- TextChatCommand supports non-slash aliases (such as ';') in Roblox's
    -- current TextChatService. The command is consumed by the engine rather
    -- than being sent as a normal message to other players.
    for _,spec in {{"SetMilitaryRank",";계급",";rank"},{"ListMilitaryRanks",";계급목록",";ranks"}} do
        local command=Instance.new("TextChatCommand")
        command.Name=spec[1];command.PrimaryAlias=spec[2];command.SecondaryAlias=spec[3]
        command.Enabled=true
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
