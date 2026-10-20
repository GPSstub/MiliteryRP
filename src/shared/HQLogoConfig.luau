--!strict
-- HQ emblem asset configuration.
-- The owner-supplied Roblox image ID takes priority over the fallback
-- game-local asset. If this new asset contains an opaque background, upload a
-- transparent replacement; ImageLabel cannot remove baked-in white pixels.
local Branding={
    LogoAssetId=70816694077389,
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
