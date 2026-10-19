--!strict
local DataStoreService=game:GetService("DataStoreService")
local MessagingService=game:GetService("MessagingService")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local Rules=require(script.Parent.MessengerState)
local Core=require(script.Parent.MessengerStoreCore)
local Store={}
local changed=Instance.new("BindableEvent")
Store.Changed=changed.Event
local name=if RunService:IsStudio() then "MilitaryMessenger_Config_Dev_v1" else "MilitaryMessenger_Config_v1"
local key="configuration"
local topic=name.."_revision"
local dataStore
local ok=pcall(function() dataStore=DataStoreService:GetDataStore(name) end)
local core=Core.new(Rules,{
    get=function() assert(ok and dataStore,"DataStore unavailable");return dataStore:GetAsync(key) end,
    update=function(transform)
        return dataStore:UpdateAsync(key,function(current)
            local updated=transform(current)
            if updated and #HttpService:JSONEncode(updated)>1000000 then error("Configuration exceeds 1MB") end
            return updated
        end)
    end,
    wait=task.wait,
    id=function() return HttpService:GenerateGUID(false) end,
})
function Store.get() return core.data end
function Store.status() return {ready=core.ready,revision=core.data.revision,error=core.error,store=name} end
function Store.context(player: Player) return {userId=player.UserId,rankOrder=tonumber(player:GetAttribute("RankOrder")) or 0} end
function Store.refresh()
    local before=core.data.revision
    local wasReady=core.ready
    core:load()
    if core.data.revision~=before or core.ready~=wasReady then changed:Fire() end
end
function Store.commit(player: Player,op: any,revision: any): (boolean,string)
    local before=core.data.revision
    local success,message=core:commit(Store.context(player),op,revision)
    if core.data.revision~=before then changed:Fire() end
    if success then
        task.spawn(function() pcall(function() MessagingService:PublishAsync(topic,{revision=core.data.revision}) end) end)
    end
    return success,message
end
-- Notifications are hints; periodic reads recover dropped/out-of-order messages.
task.spawn(function()
    Store.refresh()
    while true do
        local subscribed=pcall(function()
            MessagingService:SubscribeAsync(topic,function(message)
                local data=message.Data
                if type(data)=="table" and type(data.revision)=="number" and data.revision>core.data.revision then task.spawn(Store.refresh) end
            end)
        end)
        if subscribed then break end
        task.wait(30)
    end
end)
task.spawn(function() while true do task.wait(30+math.random()*10);Store.refresh() end end)
-- No dirty write-behind cache: acknowledged changes have already committed in UpdateAsync.
return Store
