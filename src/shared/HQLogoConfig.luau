--!strict
-- HQ-only nameplate. Replace LogoAssetId after uploading your HQ turtle-cat
-- image through Roblox Studio Asset Manager / Creator Dashboard.
-- 0 is intentional until an approved Roblox image asset ID is available.
-- A PNG path, sandbox URL or GitHub URL is not an ImageLabel texture.
local Branding = {
    LogoAssetId = 0,
    MaxDistance = 100,
    PrimaryBlue = Color3.fromRGB(24, 76, 159),
    DeepBlue = Color3.fromRGB(10, 32, 76),
    LightBlue = Color3.fromRGB(175, 205, 255),
    Gold = Color3.fromRGB(247, 208, 131),
    White = Color3.fromRGB(247, 250, 255),
}
return table.freeze(Branding)
