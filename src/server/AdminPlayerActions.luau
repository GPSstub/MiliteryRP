--!strict
-- HQ-only character actions. Shared by the Roblox chat and admin panel command
-- paths. Targets must exist in the same server; movement/effects run on server.
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local TeamService=require(script.Parent:WaitForChild("TeamService"))

local Actions={}
local lastAction: {[Player]: number}={}
local lastBlast: {[Player]: number}={}

local function alive(player: Player): (Model?, Humanoid?, BasePart?)
    if player.Parent~=Players then return nil,nil,nil end
    local character=player.Character
    if not character then return nil,nil,nil end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local root=character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health<=0 or not root or not root:IsA("BasePart") then
        return nil,nil,nil
    end
    return character,humanoid,root
end

local function makeExplosionEffect(position: Vector3)
    -- Visual-only explosion. No map damage, no blast damage, no physics impulse
    -- to nearby characters; the intended target is killed separately below.
    local flash=Instance.new("Part")
    flash.Name="HQExplosionFlash"
    flash.Shape=Enum.PartType.Ball
    flash.Material=Enum.Material.Neon
    flash.Color=Color3.fromRGB(255,183,61)
    flash.Transparency=0.12
    flash.Size=Vector3.new(1,1,1)
    flash.CFrame=CFrame.new(position)
    flash.Anchored=true
    flash.CanCollide=false
    flash.CanTouch=false
    flash.CanQuery=false
    flash.CastShadow=false
    flash.Parent=Workspace
    Debris:AddItem(flash,2)

    local light=Instance.new("PointLight")
    light.Color=Color3.fromRGB(255,168,66)
    light.Brightness=6
    light.Range=17
    light.Parent=flash

    local sparks=Instance.new("ParticleEmitter")
    sparks.Name="Sparks"
    sparks.Enabled=false
    sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
    sparks.Rate=0
    sparks.Speed=NumberRange.new(13,26)
    sparks.Lifetime=NumberRange.new(0.35,0.75)
    sparks.Drag=3
    sparks.SpreadAngle=Vector2.new(180,180)
    sparks.EmissionDirection=Enum.NormalId.Top
    sparks.Color=ColorSequence.new(
        Color3.fromRGB(255,232,137),
        Color3.fromRGB(255,88,22)
    )
    sparks.LightEmission=0.9
    sparks.Size=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.65),
        NumberSequenceKeypoint.new(1,0),
    })
    sparks.Parent=flash
    sparks:Emit(55)

    -- A short-lived expanding sphere is visible even when the particle
    -- texture is not available on a particular Roblox client.
    TweenService:Create(flash,TweenInfo.new(0.46,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
        Size=Vector3.new(11,11,11),
        Transparency=1,
        Color=Color3.fromRGB(255,90,30),
    }):Play()
    TweenService:Create(light,TweenInfo.new(0.25),{Brightness=0}):Play()

    -- Use Roblox's own explosion VFX, but zero damage/pressure/crater radius.
    local burst=Instance.new("Explosion")
    burst.Name="HQExplosionVisual"
    burst.Position=position
    burst.BlastRadius=0
    burst.BlastPressure=0
    burst.DestroyJointRadiusPercent=0
    burst.ExplosionType=Enum.ExplosionType.NoCraters
    burst.Parent=Workspace
end

function Actions.run(actor: Player,target: Player,kind: string,
        stopFlight: (Player)->()): (boolean,string)
    if not TeamService.isAdmin(actor) or target.Parent~=Players then
        return false,"Roblox 그룹 운영진만 플레이어 제어 명령을 사용할 수 있습니다."
    end
    if kind~="to" and kind~="here" and kind~="kill" and kind~="explode" then
        return false,"알 수 없는 플레이어 명령어입니다."
    end

    local now=os.clock()
    if now-(lastAction[actor] or -math.huge)<0.35 then
        return false,"너무 빠른 명령입니다. 잠시 후 다시 시도하세요."
    end

    if kind=="to" or kind=="here" then
        if actor==target then return false,"자기 자신에게 순간이동할 수 없습니다." end
        local mover=if kind=="to" then actor else target
        local destination=if kind=="to" then target else actor
        local character,humanoid,root=alive(mover)
        local _,_,destinationRoot=alive(destination)
        if not character or not humanoid or not root or not destinationRoot then
            return false,"양쪽 모두 살아 있는 캐릭터로 접속해 있어야 합니다."
        end
        if humanoid.SeatPart or humanoid.Sit or root.Anchored then
            return false,"이동할 캐릭터는 앉아 있거나 고정된 상태일 수 없습니다."
        end
        lastAction[actor]=now
        stopFlight(mover)
        -- Place the arriving character to the right of the destination,
        -- facing the same direction, without overlapping the other player.
        local moved,moveError=pcall(function()
            character:PivotTo(destinationRoot.CFrame*CFrame.new(4,0,0))
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        end)
        if not moved then
            warn("[HQPlayerActions] Teleport failed:",moveError)
            return false,"순간이동하지 못했습니다. 캐릭터 상태와 Output을 확인하세요."
        end
        if kind=="to" then
            return true,actor.Name.." → "..target.Name.." 위치로 순간이동했습니다."
        end
        return true,target.Name.." → "..actor.Name.." 위치로 소환했습니다."
    end

    local _,humanoid,root=alive(target)
    if not humanoid or not root then
        return false,"대상이 살아 있는 캐릭터로 접속해 있어야 합니다."
    end

    if kind=="explode" and now-(lastBlast[actor] or -math.huge)<2 then
        return false,"폭발 명령은 2초 간격으로 사용할 수 있습니다."
    end
    lastAction[actor]=now
    if kind=="explode" then
        lastBlast[actor]=now
        local visualOk,visualError=pcall(makeExplosionEffect,root.Position)
        if not visualOk then
            warn("[HQPlayerActions] Explosion VFX failed:",visualError)
        end
        -- Kill only the named target. Nearby characters and the map are safe.
        humanoid.Health=0
        if visualOk then
            return true,target.Name.." 폭발 처리 완료 (이펙트 표시, 주변 피해 없음)."
        end
        return true,target.Name.." 사망 처리 완료 (폭발 이펙트 오류 · 서버 Output 확인)."

    end
    humanoid.Health=0
    return true,target.Name.." 사망 처리 완료."
end

Players.PlayerRemoving:Connect(function(player)
    lastAction[player]=nil
    lastBlast[player]=nil
end)

return Actions
