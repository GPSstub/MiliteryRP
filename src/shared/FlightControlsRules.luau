--!strict
-- A cosmetic flight control is visible only while the SERVER considers this
-- player to be flying and the compact-screen UI is not covering game controls.
local Rules={}
function Rules.visible(adminFlying: any,hiddenByModal: any): boolean
    return adminFlying==true and hiddenByModal~=true
end
return table.freeze(Rules)
