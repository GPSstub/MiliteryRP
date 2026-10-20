--!strict
-- HQ team overhead identity: emblem + HQ only; no character name or rank.
-- Shows a Roblox-approved turtle-cat PNG when configured. Until then, a
-- blue vector-style turtle-cat badge renders using Roblox GUI primitives.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Branding=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HQLogoConfig"))
local Badge={}

local function make(className: string,parent: Instance,props: {[string]: any}): Instance
    local item=Instance.new(className)
    for key,value in props do (item :: any)[key]=value end
    item.Parent=parent
    return item
end

local function frame(parent: Instance,name: string,x: number,y: number,w: number,h: number,
        color: Color3,z: number,radius: number?): Frame
    local item=make("Frame",parent,{
        Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundColor3=color,BackgroundTransparency=0,
        BorderSizePixel=0,ZIndex=z,
    }) :: Frame
    if radius and radius>0 then
        make("UICorner",item,{CornerRadius=UDim.new(0,radius)})
    end
    return item
end

local function vectorFallback(container: Frame): Frame
    -- Stylized turtle shell behind a cat head. All primitives have stable
    -- pixel dimensions so it remains readable above a Roblox avatar.
    local art=frame(container,"TurtleCatFallback",0,0,100,100,Branding.DeepBlue,2,50)
    make("UIStroke",art,{Color=Branding.Gold,Thickness=2.5,Transparency=0.05})
    local ring=frame(art,"Orbit",5,5,90,90,Branding.PrimaryBlue,3,45)
    make("UIStroke",ring,{Color=Branding.LightBlue,Thickness=1.5,Transparency=0.2})

    local shell=frame(art,"TurtleShell",12,20,76,60,Branding.DeepBlue,4,28)
    make("UIStroke",shell,{Color=Branding.Gold,Thickness=2,Transparency=0.1})
    local topPlate=frame(shell,"ShellPlate",17,8,42,20,Branding.PrimaryBlue,5,9)
    make("UIStroke",topPlate,{Color=Branding.LightBlue,Thickness=1,Transparency=0.15})
    local midPlate=frame(shell,"ShellCenter",27,23,22,23,Branding.PrimaryBlue,5,7)
    make("UIStroke",midPlate,{Color=Branding.LightBlue,Thickness=1,Transparency=0.15})
    frame(shell,"ShellLeft",8,32,18,15,Branding.PrimaryBlue,5,5)
    frame(shell,"ShellRight",50,32,18,15,Branding.PrimaryBlue,5,5)

    local earL=frame(art,"CatEarL",23,21,24,24,Branding.LightBlue,6,4)
    earL.Rotation=45
    local earR=frame(art,"CatEarR",53,21,24,24,Branding.LightBlue,6,4)
    earR.Rotation=45
    local face=frame(art,"CatFace",22,32,56,46,Branding.White,7,19)
    make("UIStroke",face,{Color=Branding.DeepBlue,Thickness=1.5,Transparency=0.1})
    frame(face,"EyeLeft",14,17,7,8,Branding.DeepBlue,8,4)
    frame(face,"EyeRight",35,17,7,8,Branding.DeepBlue,8,4)
    local nose=frame(face,"Nose",25,28,7,6,Branding.PrimaryBlue,8,3)
    nose.Rotation=45

    local shine=make("TextLabel",art,{
        Name="NorthStar",Size=UDim2.fromOffset(18,19),
        Position=UDim2.fromOffset(41,0),
        BackgroundTransparency=1,Text="✦",
        Font=Enum.Font.GothamBold,TextSize=18,
        TextColor3=Branding.Gold,ZIndex=9,
    })
    return art
end

function Badge.render(tag: BillboardGui)
    tag:SetAttribute("DisplayMode","HQ")
    tag.Size=UDim2.fromOffset(170,146)
    tag.StudsOffsetWorldSpace=Vector3.new(0,3.15,0)
    tag.MaxDistance=Branding.MaxDistance

    local iconRoot=frame(tag,"HQEmblem",35,1,100,100,Branding.DeepBlue,1,50)
    iconRoot.BackgroundTransparency=1
    local fallback=vectorFallback(iconRoot)

    local imageId=tonumber(Branding.LogoAssetId) or 0
    local imageUri: string?=nil
    if imageId>0 and imageId%1==0 then
        imageUri="rbxassetid://"..tostring(imageId)
    elseif type(Branding.LogoGameAssetName)=="string"
        and Branding.LogoGameAssetName:match("^[%w_]+$") then
        -- Roblox Asset Manager can resolve game-local images by their filename,
        -- without needing a hard-coded numeric asset ID.
        imageUri="rbxgameasset://Images/"..Branding.LogoGameAssetName
    end
    if imageUri then
        make("ImageLabel",iconRoot,{
            Name="HQLogo",Size=UDim2.fromScale(1,1),
            Position=UDim2.fromScale(0,0),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScaleType=Enum.ScaleType.Fit,
            Image=imageUri,
            ZIndex=10,
        })
        -- The vector fallback stays behind the image; if Roblox has not
        -- approved/imported the asset, an emblem still remains visible.
        -- IsLoaded is client-only, so we must not hide the fallback on server.
    end

    local label=make("TextLabel",tag,{
        Name="HQLabel",Position=UDim2.fromOffset(0,106),
        Size=UDim2.new(1,0,0,34),
        BackgroundTransparency=1,
        Text="HQ",TextScaled=false,TextSize=26,Font=Enum.Font.GothamBlack,
        TextColor3=Branding.Gold,TextStrokeColor3=Branding.DeepBlue,
        TextStrokeTransparency=0.08,TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center,
        ZIndex=12,
    })
    label:SetAttribute("OfficialHQ",true)
end

return Badge
