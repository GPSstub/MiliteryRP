--!strict
-- Pure state and combat geometry policy; no Roblox services required.
local Rules={WEAPON_ID="Katana",DISPLAY_NAME="카타나",DAMAGE=30,COOLDOWN=.65,
    DRAW_SECONDS=.35,WINDUP=.14,ACTIVE_SECONDS=.18,RANGE=5.5,MIN_DOT=.30,MAX_VERTICAL=3.5}
export type State={lastSwing: number,readyAt: number,serial: number}
local function finite(n: number): boolean return n==n and math.abs(n)<math.huge end
function Rules.new(): State return {lastSwing=-math.huge,readyAt=math.huge,serial=0} end
function Rules.equip(state: State,now: number)
    state.serial+=1
    state.readyAt=now+Rules.DRAW_SECONDS
end
function Rules.unequip(state: State)
    state.serial+=1
    state.readyAt=math.huge
end
function Rules.trySwing(state: State,now: number): boolean
    if not finite(now) or now<state.readyAt or now-state.lastSwing<Rules.COOLDOWN then return false end
    state.lastSwing=now
    state.serial+=1
    return true
end
function Rules.inReach(distance: number,dot: number,vertical: number): boolean
    return finite(distance) and finite(dot) and finite(vertical) and distance>=0
        and distance<=Rules.RANGE and dot>=Rules.MIN_DOT and math.abs(vertical)<=Rules.MAX_VERTICAL
end
function Rules.canDamage(isSelf: boolean,sameTeam: boolean,attackerNeutral: boolean,targetNeutral: boolean): boolean
    return not isSelf and not (sameTeam and not attackerNeutral and not targetNeutral)
end
return table.freeze(Rules)
