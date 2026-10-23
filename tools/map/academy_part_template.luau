--!strict
-- Edit-time staging importer. Geometry is built outside Workspace in bounded chunks.
local root = game:GetService("ServerStorage"):FindFirstChild("AcademyCampus")
assert(root, "Staging model missing")
local data = game:GetService("HttpService"):JSONDecode(PAYLOAD)
local zone = root:FindFirstChild(data.name)
if not zone then
 zone = Instance.new("Model")
 zone.Name = data.name
 zone.Parent = root
end
if data.floors then zone:SetAttribute("Floors",data.floors) end
local origin = (root:FindFirstChild("Origin") :: BasePart).CFrame
local chunk = Instance.new("Model")
chunk.Name = "Geometry_" .. tostring(data.batch)
for _, a in data.parts do
 local p = Instance.new("Part")
 p.Name = a.n
 p.Size = Vector3.new(unpack(a.s))
 p.CFrame = origin * CFrame.new(unpack(a.p)) * CFrame.Angles(math.rad(a.pitch or 0),math.rad(a.r),0)
 p.Color = Color3.fromRGB(unpack(a.c))
 p.Material = Enum.Material[a.m]
 p.Shape = Enum.PartType[a.shape]
 p.Anchored = true
 p.TopSurface = Enum.SurfaceType.Smooth
 p.BottomSurface = Enum.SurfaceType.Smooth
 p.Transparency = a.alpha or 0
 p.CanTouch = false
 if a.text then
  local gui = Instance.new("SurfaceGui")
  gui.Face = Enum.NormalId.Front
  gui.CanvasSize = Vector2.new(1000,150)
  gui.Parent = p
  local label = Instance.new("TextLabel")
  label.Size = UDim2.fromScale(1,1)
  label.BackgroundTransparency = 1
  label.TextColor3 = Color3.fromRGB(236,230,207)
  label.Font = Enum.Font.GothamBold
  label.TextScaled = true
  label.Text = a.text
  label.Parent = gui
 end
 p.Parent = chunk
end
chunk.Parent = zone
task.wait()
return data.name .. ' / ' .. #data.parts .. ' parts'
