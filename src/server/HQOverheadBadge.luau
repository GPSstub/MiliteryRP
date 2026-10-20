--!strict
-- Compact HQ-only overhead nameplate: transparent turtle-cat emblem + HQ.
-- Never draw the old gold ring or stack a second large badge behind the logo.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Branding=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HQLogoConfig"))
local Badge={}

local function make(className: string,parent: Instance,props: {[string]: any}): Instance
    local child=Instance.new(className)
    for property,value in props do (child :: any)[property]=value end
    child.Parent=parent
    return child
end

function Badge.render(tag: BillboardGui)
    local iconSize=math.clamp(Branding.IconSize,40,80)
    local width=iconSize+36
    local height=iconSize+34
    tag:SetAttribute("DisplayMode","HQ")
    tag.Size=UDim2.fromOffset(width,height)
    tag.StudsOffsetWorldSpace=Vector3.new(0,Branding.OffsetY,0)
    tag.MaxDistance=Branding.MaxDistance

    -- The artwork sits alone on a completely transparent panel.
    local panel=make("Frame",tag,{
        Name="HQEmblem",Size=UDim2.fromOffset(iconSize,iconSize),
        Position=UDim2.fromOffset((width-iconSize)/2,0),
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1,
    })

    -- Small blue fallback while the new PNG has not been imported/approved.
    -- The client hides it once the real PNG has loaded successfully.
    local fallback=make("Frame",panel,{
        Name="TurtleCatFallback",Size=UDim2.fromScale(1,1),
        BackgroundColor3=Branding.DeepBlue,BackgroundTransparency=0.08,
        BorderSizePixel=0,ZIndex=2,
    })
    make("UICorner",fallback,{CornerRadius=UDim.new(1,0)})
    make("UIStroke",fallback,{Color=Branding.LightBlue,Thickness=1.4})
    make("TextLabel",fallback,{
        Name="FallbackMark",Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,Text="✦",TextSize=32,
        Font=Enum.Font.GothamBold,TextColor3=Branding.White,
        TextStrokeTransparency=0.7,ZIndex=3,
    })

    local assetId=tonumber(Branding.LogoAssetId) or 0
    local uri: string?=nil
    if assetId>0 and assetId%1==0 then
        uri="rbxassetid://"..tostring(assetId)
    elseif type(Branding.LogoGameAssetName)=="string"
        and Branding.LogoGameAssetName:match("^[%w_]+$") then
        uri="rbxgameasset://Images/"..Branding.LogoGameAssetName
    end

    if uri then
        -- Do not layer a decorative circle under the transparent image.
        -- The client can show the fallback only while the image is loading.
        fallback.Visible=false
        make("ImageLabel",panel,{
            Name="HQLogo",Size=UDim2.fromScale(1,1),
            Position=UDim2.fromOffset(0,0),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScaleType=Enum.ScaleType.Fit,Image=uri,
            ImageTransparency=0,ZIndex=4,
        })
    end

    local text=make("TextLabel",tag,{
        Name="HQLabel",
        Position=UDim2.fromOffset(0,iconSize+3),
        Size=UDim2.fromOffset(width,23),
        BackgroundTransparency=1,BorderSizePixel=0,
        Text="HQ",TextSize=17,TextScaled=false,
        Font=Enum.Font.GothamBold,
        TextColor3=Branding.LightBlue,
        TextStrokeColor3=Branding.DeepBlue,
        TextStrokeTransparency=0.2,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=5,
    })
    text:SetAttribute("OfficialHQ",true)
end
return Badge
