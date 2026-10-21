-- Paste into Roblox Studio Command Bar in EDIT mode, after uploading the
-- material images to Asset Manager. Each URL must be an IMAGE asset id.
-- Empty values intentionally leave the corresponding material map untouched.
local ServerStorage=game:GetService("ServerStorage")
local folder=ServerStorage:FindFirstChild("HK416Assets")
assert(folder, "Missing ServerStorage/HK416Assets; import the meshes first")

-- Replace the empty strings with your own rbxassetid://123... IDs.
-- A separate UV map is used for Body and Magazine; do NOT assume the same
-- ColorMap texture will fit both unrelated imported OBJ UV layouts.
local textures={
    Body={
        ColorMap="",
        NormalMap="",
        RoughnessMap="",
        MetalnessMap="",
    },
    Magazine={
        ColorMap="",
        NormalMap="",
        RoughnessMap="",
        MetalnessMap="",
    },
}

local allowed={ColorMap=true,NormalMap=true,RoughnessMap=true,MetalnessMap=true}
local installed=0
for name,maps in pairs(textures) do
    local part=folder:FindFirstChild(name)
    assert(part and part:IsA("MeshPart"),"Missing HK416Assets/"..name.." MeshPart")
    local appearance=part:FindFirstChildOfClass("SurfaceAppearance")
    local changed=0
    for field,id in pairs(maps) do
        assert(allowed[field],"Invalid SurfaceAppearance field "..tostring(field))
        if id~="" then
            assert(type(id)=="string" and id:match("^rbxassetid://%d+$"),
                name.."."..field.." needs a Roblox image asset ID, such as rbxassetid://12345")
            if not appearance then
                appearance=Instance.new("SurfaceAppearance")
                appearance.Name="HK416Surface"
                appearance.Parent=part
            end
            appearance[field]=id
            changed+=1
        end
    end
    installed+=changed
    print(name,changed.." material map(s) attached")
end
if installed==0 then
    warn("No texture asset IDs entered yet. Add IDs to the textures table and run again.")
else
    print("HK416 SurfaceAppearance maps updated; save the place and restart Play.")
end
