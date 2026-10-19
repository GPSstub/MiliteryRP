--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("AdminFlightInput") :: RemoteEvent
local timer=0
local focused=true
local gui=Instance.new("ScreenGui");gui.Name="FlightControls";gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.Parent=player:WaitForChild("PlayerGui")
local upHeld,downHeld=false,false
for i,spec in {{"상승",true},{"하강",false}} do
    local b=Instance.new("TextButton");b.Name=if spec[2] then "Up" else "Down";b.Text=spec[1] :: string
    b.Size=UDim2.fromOffset(60,48);b.AnchorPoint=Vector2.new(1,1);b.Position=UDim2.new(1,-20,1,-80-i*56)
    b.BackgroundColor3=Color3.fromRGB(23,29,26);b.TextColor3=Color3.fromRGB(238,237,224);b.TextSize=15
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,10);corner.Parent=b;b.Parent=gui
    b.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            if spec[2] then upHeld=true else downHeld=true end
        end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            if spec[2] then upHeld=false else downHeld=false end
        end
    end)
end
local function updateVisibility()
    gui.Enabled=player:GetAttribute("AdminFlying")==true
    upHeld=false;downHeld=false
end
player:GetAttributeChangedSignal("AdminFlying"):Connect(updateVisibility);updateVisibility()
UserInputService.WindowFocusReleased:Connect(function() focused=false;upHeld=false;downHeld=false;remote:FireServer(Vector3.zero,Vector3.new(0,0,-1)) end)
UserInputService.WindowFocused:Connect(function() focused=true end)
RunService.Heartbeat:Connect(function(dt)
    if not player:GetAttribute("AdminFlying") then return end
    timer+=dt;if timer<1/12 then return end;timer=0
    local camera=workspace.CurrentCamera
    local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not camera or not humanoid then return end
    local direction=Vector3.zero
    if focused and not UserInputService:GetFocusedTextBox() then
        local function key(code: Enum.KeyCode): number return if UserInputService:IsKeyDown(code) then 1 else 0 end
        local forward=key(Enum.KeyCode.W)-key(Enum.KeyCode.S)
        local right=key(Enum.KeyCode.D)-key(Enum.KeyCode.A)
        direction=camera.CFrame.LookVector*forward+camera.CFrame.RightVector*right
        if forward==0 and right==0 then direction=humanoid.MoveDirection end
        local vertical=key(Enum.KeyCode.Space)+key(Enum.KeyCode.E)-key(Enum.KeyCode.Q)-key(Enum.KeyCode.LeftControl)
        vertical+=if upHeld then 1 else 0;vertical-=if downHeld then 1 else 0
        direction+=Vector3.yAxis*math.clamp(vertical,-1,1)
    end
    if direction.Magnitude>1 then direction=direction.Unit end
    remote:FireServer(direction,camera.CFrame.LookVector)
end)
