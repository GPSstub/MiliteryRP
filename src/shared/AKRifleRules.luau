--!strict
-- Pure magazine/cooldown/reload rules. Roblox services are not needed for testing.
local Rules = {
    WEAPON_ID = "AKRifle",
    DISPLAY_NAME = "AK 소총",
    MAGAZINE = 30,
    RESERVE = 90,
    DAMAGE = 12,
    RANGE = 300,
    SHOT_INTERVAL = 0.16,
    RELOAD_SECONDS = 1.8,
}
export type WeaponState = {
    ammo: number, reserve: number, lastShot: number, reloadUntil: number, unlimitedReserve: boolean,
}
function Rules.new(unlimitedReserve: boolean?): WeaponState
    return {ammo=Rules.MAGAZINE,reserve=Rules.RESERVE,lastShot=-math.huge,reloadUntil=0,unlimitedReserve=unlimitedReserve==true}
end
function Rules.tryFire(state: WeaponState,now: number): (boolean,string)
    if type(now)~="number" or now~=now then return false,"잘못된 시간" end
    if state.reloadUntil>0 then return false,"재장전 중" end
    if state.ammo<=0 then return false,"탄약 없음" end
    if now-state.lastShot<Rules.SHOT_INTERVAL then return false,"발사 간격 제한" end
    state.ammo-=1
    state.lastShot=now
    return true,"발사"
end
function Rules.startReload(state: WeaponState,now: number): (boolean,string)
    if type(now)~="number" or now~=now then return false,"잘못된 시간" end
    if state.reloadUntil>0 then return false,"이미 재장전 중" end
    if state.ammo>=Rules.MAGAZINE then return false,"탄창이 가득 참" end
    if not state.unlimitedReserve and state.reserve<=0 then return false,"예비 탄약 없음" end
    state.reloadUntil=now+Rules.RELOAD_SECONDS
    return true,"재장전 시작"
end
function Rules.completeReload(state: WeaponState,now: number): boolean
    if state.reloadUntil<=0 or type(now)~="number" or now<state.reloadUntil then return false end
    local loaded=if state.unlimitedReserve then Rules.MAGAZINE-state.ammo else math.min(Rules.MAGAZINE-state.ammo,state.reserve)
    state.ammo+=loaded
    if not state.unlimitedReserve then state.reserve-=loaded end
    state.reloadUntil=0
    return true
end
return table.freeze(Rules)
