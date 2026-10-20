--!strict
-- Set this to the approved Roblox IMAGE asset ID for the turtle-cat HQ emblem.
-- A PNG file or a GitHub image URL cannot be displayed directly by ImageLabel.
-- Example: LogoAssetId = 123456789012345 (replace with your real approved ID).
local Branding = {
    LogoAssetId = 0,
    MaxDistance = 110,
    Gold = Color3.fromRGB(229, 193, 105),
    DarkGreen = Color3.fromRGB(25, 44, 36),
}
return table.freeze(Branding)
