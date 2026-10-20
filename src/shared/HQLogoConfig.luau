--!strict
-- HQ-only nameplate. Approved Roblox image asset supplied by the game owner.
-- LogoAssetId takes priority over the optional game-local HQLogo image.
-- If it is not yet approved or accessible to this experience, a GUI fallback remains.
-- A PNG path, sandbox URL or GitHub URL is not an ImageLabel texture.
local Branding = {
    LogoAssetId = 115201559367134,
    -- Alternative to entering an ID: import HQLogo.png under Asset Manager
    -- > Images in this Roblox experience. ImageLabel accepts rbxgameasset URIs.
    LogoGameAssetName = "HQLogo",
    -- Display the HQ overhead emblem only to nearby players (studs).
    MaxDistance = 25,
    PrimaryBlue = Color3.fromRGB(24, 76, 159),
    DeepBlue = Color3.fromRGB(10, 32, 76),
    LightBlue = Color3.fromRGB(175, 205, 255),
    Gold = Color3.fromRGB(247, 208, 131),
    White = Color3.fromRGB(247, 250, 255),
}
return table.freeze(Branding)
