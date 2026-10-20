--!strict
-- HQ emblem asset configuration.
-- The previous 115201559367134 image contains a solid white square.
-- It is deliberately NOT used anymore because ImageLabel cannot erase pixels
-- of an uploaded texture. Import the supplied transparent HQLogo_Transparent.png
-- in Roblox Studio Asset Manager > Images, with the exact name below.
-- Or enter the NEW approved image ID in LogoAssetId to use rbxassetid://...
local Branding={
    LogoAssetId=0,
    LogoGameAssetName="HQLogo_Transparent",
    MaxDistance=25,
    IconSize=60, -- GUI pixels; smaller than the old 100px icon
    OffsetY=2.35, -- studs above the avatar's head
    PrimaryBlue=Color3.fromRGB(68,123,206),
    DeepBlue=Color3.fromRGB(22,55,118),
    LightBlue=Color3.fromRGB(194,218,255),
    Gold=Color3.fromRGB(247,208,131),
    White=Color3.fromRGB(247,250,255),
}
return table.freeze(Branding)
