--!strict
-- Keep phone launchers and the weapon HUD clear of open full-screen panels.
local Players=game:GetService("Players")
local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
local watched: {[Instance]: boolean}={}
local windows={ContentPanel=true,MessengerWindow=true,ExamWindow=true,DimOverlay=true}
local launchers={MenuButton=true,CommunicationButton=true,ExamButton=true}
local function refresh()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local compact=camera.ViewportSize.X<900 or camera.ViewportSize.Y<580
    local modal=false
    if compact then
        for object in watched do
            if object.Parent and object:IsA("GuiObject") and windows[object.Name] and object.Visible then
                modal=true;break
            end
        end
    end
    for object in watched do
        if object.Parent and object:IsA("GuiObject") and launchers[object.Name] then
            local ownWindow=if object.Name=="CommunicationButton" and object.Parent then object.Parent:FindFirstChild("MessengerWindow") else nil
            object.Visible=not modal and not (ownWindow and ownWindow:IsA("GuiObject") and ownWindow.Visible)
        end
    end
    local context=playerGui:FindFirstChild("ContextActionGui")
    if context and context:IsA("ScreenGui") then context.Enabled=not modal end
    local flight=playerGui:FindFirstChild("FlightControls")
    if flight and flight:IsA("ScreenGui") then flight.Enabled=not modal end
    local hud=playerGui:FindFirstChild("TrainingRifleHUD")
    if hud and hud:IsA("ScreenGui") then hud.Enabled=not modal end
end
local function bind(object: Instance)
    if not object:IsA("GuiObject") or watched[object]
        or (not windows[object.Name] and not launchers[object.Name]) then return end
    -- Limit matches to this game's top-level screens, not similarly named chat rows.
    local screen=object:FindFirstAncestorOfClass("ScreenGui")
    if not screen or not ({MilitaryMenu=true,MilitaryMessenger=true,MilitaryExams=true,AdminTargetPicker=true})[screen.Name] then return end
    watched[object]=true
    local connection: RBXScriptConnection?=nil
    connection=object:GetPropertyChangedSignal("Visible"):Connect(refresh)
    object.Destroying:Once(function()
        watched[object]=nil
        if connection then connection:Disconnect() end
        task.defer(refresh)
    end)
    task.defer(refresh)
end
-- Some UI helpers parent buttons before assigning their final names.
playerGui.DescendantAdded:Connect(function(object) task.defer(bind,object) end)
for _,object in playerGui:GetDescendants() do bind(object) end
local viewportConnection: RBXScriptConnection?=nil
local function cameraChanged()
    if viewportConnection then viewportConnection:Disconnect() end
    local camera=workspace.CurrentCamera
    if camera then viewportConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh) end
    refresh()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged)
cameraChanged()
