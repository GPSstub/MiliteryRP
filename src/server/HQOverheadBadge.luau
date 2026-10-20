--!strict
-- HQ-only overhead insignia; called by RankService instead of the normal
-- nickname/rank/insignia UI when the player currently belongs to HQ.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Branding = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HQLogoConfig"))

local Badge = {}

local function make(className: string, parent: Instance, props: {[string]: any}): Instance
    local item = Instance.new(className)
    for key,value in props do
        (item :: any)[key] = value
    end
    item.Parent = parent
    return item
end

function Badge.render(tag: BillboardGui)
    tag:SetAttribute("DisplayMode","HQ")
    tag.Size=UDim2.fromOffset(174,142)
    tag.StudsOffsetWorldSpace=Vector3.new(0,3.3,0)
    tag.MaxDistance=Branding.MaxDistance

    local icon: Instance
    local imageId=tonumber(Branding.LogoAssetId) or 0
    if imageId>0 and imageId%1==0 then
        icon=make("ImageLabel",tag,{
            Name="HQLogo",AnchorPoint=Vector2.new(0.5,0),
            Position=UDim2.new(0.5,0,0,0),
            Size=UDim2.fromOffset(104,104),
            BackgroundTransparency=1,BorderSizePixel=0,
            Image="rbxassetid://"..tostring(imageId),
            ScaleType=Enum.ScaleType.Fit,
        })
    else
        -- Safe placeholder while the illustrated PNG is being approved/uploaded
        -- as a Roblox Image asset; never pretend a nonexistent ID will render.
        icon=make("Frame",tag,{
            Name="HQLogoPlaceholder",AnchorPoint=Vector2.new(0.5,0),
            Position=UDim2.new(0.5,0,0,3),
            Size=UDim2.fromOffset(94,94),
            BackgroundColor3=Branding.DarkGreen,
            BorderSizePixel=0,
        })
        make("UICorner",icon,{CornerRadius=UDim.new(0,18)})
        make("UIStroke",icon,{
            Color=Branding.Gold,Thickness=3,Transparency=0,
        })
        make("TextLabel",icon,{
            Name="PlaceholderSymbol",
            BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,60),
            Position=UDim2.fromOffset(0,7),
            Text="★",Font=Enum.Font.GothamBlack,TextSize=42,
            TextColor3=Branding.Gold,
            TextStrokeColor3=Color3.fromRGB(12,24,20),
            TextStrokeTransparency=0.5,
        })
        make("TextLabel",icon,{
            Name="PlaceholderCaption",
            BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,24),
            Position=UDim2.fromOffset(0,62),
            Text="HQ",Font=Enum.Font.GothamBold,TextSize=18,
            TextColor3=Branding.Gold,
            TextStrokeTransparency=0.65,
        })
    end

    local label=make("TextLabel",tag,{
        Name="HQLabel",
        Position=UDim2.new(0,0,0,106),Size=UDim2.new(1,0,0,32),
        BackgroundTransparency=1,
        Text="HQ",TextSize=24,Font=Enum.Font.GothamBlack,
        TextColor3=Branding.Gold,TextStrokeColor3=Color3.fromRGB(8,15,13),
        TextStrokeTransparency=0.15,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center,
    })
    label:SetAttribute("OfficialHQ",true)
end

return Badge
