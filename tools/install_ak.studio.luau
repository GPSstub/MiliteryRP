--!strict
-- Select the imported AK Model (or both MeshParts) in Edit mode, then run.
local Selection=game:GetService("Selection")
local ServerStorage=game:GetService("ServerStorage")
assert(not ServerStorage:FindFirstChild("AKAssets"),"AKAssets already exists; preserve it before reinstalling")
local found: {[string]: MeshPart}={}
local function collect(item: Instance)
    if item:IsA("MeshPart") and (item.Name=="Body" or item.Name=="Magazine" or item.Name=="Cube" or item.Name=="Magazine_shell") then
        local name=if item.Name=="Cube" then "Body" elseif item.Name=="Magazine_shell" then "Magazine" else item.Name
        assert(not found[name],"Duplicate mesh: "..name)
        found[name]=item
    end
end
for _,item in Selection:Get() do
    collect(item)
    for _,child in item:GetDescendants() do collect(child) end
end
assert(found.Body and found.Magazine,"Select imported Body and Magazine meshes")
local folder=Instance.new("Folder")
folder.Name="AKAssets"
folder:SetAttribute("SourceRevision","AK-Rounded-Hex-20261022")
local offsets={Body=Vector3.new(-0.0735,0.192,-0.49821067),Magazine=Vector3.new(0,-0.25538117,-0.83833921)}
for name,source in found do
    local mesh=source:Clone()
    mesh.Name=name
    mesh.Anchored=true
    mesh.CanCollide=false
    mesh.CanTouch=false
    mesh.CanQuery=false
    mesh.Massless=true
    mesh:SetAttribute("HandleOffset",CFrame.new(offsets[name])*CFrame.Angles(0,0,math.pi)*CFrame.Angles(math.pi/2,0,0))
    mesh.CFrame=CFrame.new(offsets[name])*CFrame.Angles(0,0,math.pi)*CFrame.Angles(math.pi/2,0,0)
    mesh.Parent=folder
end
folder.Parent=ServerStorage
print("AKAssets installed: Body + Magazine; AK is granted on every spawn")
