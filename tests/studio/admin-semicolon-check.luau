-- Run inside Roblox Studio SERVER Command Bar while Play is active.
-- Read-only: does not execute admin actions or change any player state.
local TextChatService=game:GetService("TextChatService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")

local Parser=require(ServerScriptService:WaitForChild("RankCommandParser"))
local Branding=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HQLogoConfig"))
local cases={
    {"SetMilitaryRank",";계급",";rank"},
    {"ListMilitaryRanks",";계급목록",";ranks"},
    {"HQGodCommand",";무적",";god"},
    {"HQFlightCommand",";비행",";fly"},
    {"HQTeamCommand",";팀",";team"},
    {"HQTeleportToCommand",";to"},
    {"HQTeleportHereCommand",";here"},
    {"HQKillCommand",";kill"},
    {"HQExplosionCommand",";폭발",";explode"},
}

local total=0
local function check(ok: boolean,message: string)
    total+=1
    assert(ok,message)
end

check(Branding.LogoAssetId==70816694077389,"HQ logo ID is not updated")
check(assert(Parser.parse(";계급 나 대위")).kind=="set",";계급 parser failed")
check(assert(Parser.parse(";계급목록")).kind=="list",";계급목록 parser failed")
check(Parser.parse("/계급 나 대위")==nil,"Old slash commands must be disabled")

for _,spec in cases do
    local registered=TextChatService:WaitForChild(spec[1],10)
    check(registered and registered:IsA("TextChatCommand"),spec[1].." is missing")
    check(registered.PrimaryAlias==spec[2],spec[1].." primary alias is wrong")
    if spec[3] then
        check(registered.SecondaryAlias==spec[3],spec[1].." secondary alias is wrong")
    else
        check(registered.SecondaryAlias=="",spec[1].." should not register an extra alias")
    end
    check(registered.Enabled, spec[1].." command is not enabled")
end

local response=ReplicatedStorage:WaitForChild("AdminResponse",10)
check(response and response:IsA("RemoteEvent"),"HQ chat command feedback remote is missing")
print("[HQ SEMICOLON] PASS: "..total.." checks; try ;계급목록, ;to 대상, ;here 대상, ;kill 대상, ;폭발 대상 in Roblox chat.")
