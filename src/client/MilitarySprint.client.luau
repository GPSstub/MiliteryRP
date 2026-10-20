--!strict
-- Hold Shift to sprint (PC). Tap the mobile button / L3 to toggle sprint.
-- Every speed change is authorized and applied by SprintService on the server.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SprintConfig"))
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("SprintRequest") :: RemoteEvent

local ACTION="MilitarySprint"
local held: {[Enum.KeyCode]: boolean}={}
local toggled=false
local requested=false
local seatedConnection: RBXScriptConnection?=nil
local diedConnection: RBXScriptConnection?=nil

local function flying(): boolean
    return player:GetAttribute("AdminFlying")==true
end

local function refreshButton()
    ContextActionService:SetTitle(ACTION,if toggled then "걷기" else Config.MobileButtonTitle)
    local touch=ContextActionService:GetButton(ACTION)
    if touch then
        touch.Visible=not flying()
        touch.ImageColor3=if requested then Color3.fromRGB(111,193,133)
            else Color3.fromRGB(235,239,230)
    end
end

local function updateIntent()
    local shouldRun=(toggled or next(held)~=nil) and not flying()
    if requested~=shouldRun then
        requested=shouldRun
        remote:FireServer(shouldRun)
    end
    refreshButton()
end

local function reset()
    table.clear(held)
    toggled=false
    -- Send a stop even when the local state already says walking; doing so
    -- reconciles a lost focus/respawn and is always accepted by the server.
    requested=false
    remote:FireServer(false)
    refreshButton()
end

local function sprintAction(_name: string,state: Enum.UserInputState,input: InputObject): Enum.ContextActionResult
    local key=input.KeyCode
    local toggleDevice=input.UserInputType==Enum.UserInputType.Touch
        or key==Enum.KeyCode.ButtonL3

    if state==Enum.UserInputState.Begin then
        if flying() or UserInputService:GetFocusedTextBox() then
            return Enum.ContextActionResult.Pass
        end
        if toggleDevice then
            toggled=not toggled
        else
            held[key]=true
        end
        updateIntent()
    elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then
        if not toggleDevice then
            held[key]=nil
            updateIntent()
        end
    end
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(
    ACTION,sprintAction,true,
    Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,Enum.KeyCode.ButtonL3
)
ContextActionService:SetPosition(ACTION,UDim2.new(0.77,0,0.55,0))
refreshButton()

local function watchCharacter(character: Model)
    reset()
    if seatedConnection then seatedConnection:Disconnect();seatedConnection=nil end
    if diedConnection then diedConnection:Disconnect();diedConnection=nil end
    task.spawn(function()
        local humanoid=character:WaitForChild("Humanoid",10)
        if player.Character~=character or not humanoid or not humanoid:IsA("Humanoid") then return end
        seatedConnection=humanoid.Seated:Connect(function(active: boolean)
            if active then reset() end
        end)
        diedConnection=humanoid.Died:Connect(reset)
    end)
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end
player:GetAttributeChangedSignal("AdminFlying"):Connect(function()
    if flying() then reset() else refreshButton() end
end)
UserInputService.TextBoxFocused:Connect(reset)
UserInputService.WindowFocusReleased:Connect(reset)
