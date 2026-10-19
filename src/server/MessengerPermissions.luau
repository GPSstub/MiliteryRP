--!strict
local Players=game:GetService("Players")
local Rules=require(script.Parent.MessengerState)
local Store=require(script.Parent.MessengerStore)
local Permissions={Changed=Store.Changed}
function Permissions.has(player: Player,permission: string): boolean
    return player.Parent==Players and Rules.has(Store.get(),Store.context(player),permission)
end
function Permissions.channel(player: Player,id: string,mode: string): boolean
    return player.Parent==Players and Rules.channel(Store.get(),Store.context(player),id,mode)
end
function Permissions.publish(player: Player)
    for attribute,permission in {MessengerCanSend="SEND_MESSAGES",MessengerCanCreate="CREATE_CHANNELS",MessengerCanDelete="DELETE_CHANNELS",
        MessengerCanManageRoles="MANAGE_ROLES",MessengerCanManageSettings="MANAGE_SETTINGS",MessengerCanPostNotices="POST_NOTICES",
        MessengerCanViewCommand="VIEW_COMMAND",MessengerCanWriteCommand="WRITE_COMMAND"} do
        player:SetAttribute(attribute,Permissions.has(player,permission))
    end
end
return Permissions
