--!strict
-- Pure validation of sprint intent. The remote never accepts a speed number.
local Rules={}

function Rules.allowed(requested: any,alive: any,seated: any,flying: any,platformStand: any): boolean
    return requested==true and alive==true and seated~=true
        and flying~=true and platformStand~=true
end

function Rules.speed(requested: any,alive: any,seated: any,flying: any,
        platformStand: any,walkSpeed: number,sprintSpeed: number): number
    if Rules.allowed(requested,alive,seated,flying,platformStand) then
        return sprintSpeed
    end
    return walkSpeed
end
return table.freeze(Rules)
