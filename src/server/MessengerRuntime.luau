--!strict
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
local TextService=game:GetService("TextService")
local Store=require(script.Parent.MessengerStore)
local Permissions=require(script.Parent.MessengerPermissions)
local Runtime={}
local started=false
local channels: {[string]: TextChannel}={}
local pending={}
local filtered={}
function Runtime.name(entry: any): string
    if entry.authorId==0 then return entry.name end
    local key=tostring(entry.authorId)..":"..entry.name
    return filtered[key] or "이름 확인 중"
end
function Runtime.filter(name: any,userId: number): string?
    if type(name)~="string" or #name>96 or not utf8.len(name) then return nil end
    local ok,value=pcall(function()
        return TextService:FilterStringAsync(name,userId,Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()
    end)
    if ok then
        filtered[tostring(userId)..":"..name]=value
        return value
    end
    return nil
end
local function unit(p: Player): string?
    local value=p:GetAttribute("Unit")
    if type(value)=="string" and value~="" then return value end
    return if p.Team and not p.Neutral then p.Team.Name else nil
end
local function delivery(id: string,message: TextChatMessage,recipient: TextSource): boolean
    if not Store.status().ready then return false end
    local sender=message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
    local receiver=Players:GetPlayerByUserId(recipient.UserId)
    if not sender or not receiver or not Permissions.channel(sender,id,"write") or not Permissions.channel(receiver,id,"read") then return false end
    return id~="unit" or (unit(sender)~=nil and unit(sender)==unit(receiver))
end
local function refreshPlayer(player: Player)
    if player.Parent~=Players then return end
    if pending[player]~=nil then pending[player]=true;return end
    pending[player]=false
    repeat
        pending[player]=false
        Permissions.publish(player)
        for id,channel in channels do
            local function allowed() return player.Parent==Players and channel.Parent~=nil and Store.status().ready and Permissions.channel(player,id,"read") end
            local source: TextSource?=nil
            for _,child in channel:GetChildren() do if child:IsA("TextSource") and child.UserId==player.UserId then source=child;break end end
            if allowed() and not source then
                -- AddUserAsync enforces Roblox communication eligibility; never create TextSources ourselves.
                local ok,result=pcall(function() return channel:AddUserAsync(player.UserId) end)
                if ok then source=result end
            end
            if source then
                if not allowed() then source:Destroy()
                else source.CanSend=Permissions.channel(player,id,"write") and (id~="unit" or unit(player)~=nil) end
            end
        end
    until not pending[player] or player.Parent~=Players
    pending[player]=nil
end
local function refreshOnce()
    local data=Store.get()
    -- Metadata filtering is separate from permissions, never inside ShouldDeliverCallback.
    local activeNames={}
    for _,group in {data.channels,data.roles} do
        for _,entry in group do
            if entry.authorId~=0 then
                local key=tostring(entry.authorId)..":"..entry.name;activeNames[key]=true
                if not filtered[key] then Runtime.filter(entry.name,entry.authorId) end
            end
        end
    end
    for key in filtered do if not activeNames[key] then filtered[key]=nil end end
    if Store.get()~=data then return false end
    for id,channel in channels do if not data.channels[id] then channel:Destroy();channels[id]=nil end end
    for id,entry in data.channels do
        if not channels[id] then
            local existing=TextChatService:FindFirstChild(entry.channel)
            if existing and not existing:IsA("TextChannel") then warn("[Messenger] TextChannel name collision");continue end
            local channel=existing or Instance.new("TextChannel")
            channel.Name=entry.channel
            channel.ShouldDeliverCallback=function(message,recipient) return delivery(id,message,recipient) end
            channel.Parent=TextChatService;channels[id]=channel
        end
    end
    for _,p in Players:GetPlayers() do task.spawn(refreshPlayer,p) end
    return true
end
local refreshing=false
local refreshAgain=false
function Runtime.refresh()
    if refreshing then refreshAgain=true;return end
    refreshing=true
    repeat
        refreshAgain=false
        local ok,complete=pcall(refreshOnce)
        if not ok then warn("[Messenger] refresh failed");break end
        if not complete then refreshAgain=true end
    until not refreshAgain
    refreshing=false
end
function Runtime.start()
    if started then return end;started=true
    local function added(p: Player)
        for _,attribute in {"RankOrder","Unit"} do p:GetAttributeChangedSignal(attribute):Connect(function() task.spawn(refreshPlayer,p) end) end
        for _,property in {"Team","Neutral"} do p:GetPropertyChangedSignal(property):Connect(function() task.spawn(refreshPlayer,p) end) end
        task.spawn(refreshPlayer,p)
    end
    Players.PlayerAdded:Connect(added)
    Players.PlayerRemoving:Connect(function(p) pending[p]=nil end)
    Store.Changed:Connect(function() task.spawn(Runtime.refresh) end)
    for _,p in Players:GetPlayers() do added(p) end
    task.spawn(Runtime.refresh)
    task.spawn(function() while true do task.wait(20);for _,p in Players:GetPlayers() do task.spawn(refreshPlayer,p) end end end)
end
return Runtime
