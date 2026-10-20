--!strict
-- Run once in the Roblox Studio Command Bar, in Edit mode.
-- Adds only MilitaryBaseMap; existing scripts and spawns are preserved.
assert(not workspace:FindFirstChild("MilitaryBaseMap"), "MilitaryBaseMap already exists; rename it before rebuilding")
local root = Instance.new("Model")
root.Name = "MilitaryBaseMap"
root:SetAttribute("Design", "User sketch / military RP / 2026-10-20")
root.Parent = workspace
local C = {grass=Color3.fromRGB(100,117,79),road=Color3.fromRGB(48,53,56),concrete=Color3.fromRGB(172,171,156),wall=Color3.fromRGB(208,204,185),roof=Color3.fromRGB(55,73,66),dark=Color3.fromRGB(35,46,49),white=Color3.fromRGB(238,230,200),gold=Color3.fromRGB(222,174,67),glass=Color3.fromRGB(70,111,127),sand=Color3.fromRGB(168,149,109)}
local function group(name: string): Model
 local m=Instance.new("Model"); m.Name=name; return m
end
local function flush(m: Model)
 m.Parent=root; task.wait()
end
local function part(m: Instance,n: string,s: Vector3,p: Vector3,c: Color3,material: Enum.Material?): Part
 local v=Instance.new("Part"); v.Name=n; v.Size=s; v.Position=p; v.Anchored=true; v.Color=c; v.Material=material or Enum.Material.Concrete; v.TopSurface=Enum.SurfaceType.Smooth; v.BottomSurface=Enum.SurfaceType.Smooth; v.Parent=m; return v
end
local function box(m: Instance,n: string,x: number,y: number,z: number,w: number,h: number,d: number,c: Color3,mat: Enum.Material?): Part
 return part(m,n,Vector3.new(w,h,d),Vector3.new(x,y,z),c,mat)
end
local function label(p: BasePart,t: string,face: Enum.NormalId?)
 local gui=Instance.new("SurfaceGui"); gui.Name="Sign"; gui.Face=face or Enum.NormalId.Front; gui.CanvasSize=Vector2.new(900,200); gui.Parent=p
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Text=t; text.TextColor3=C.white; text.Font=Enum.Font.GothamBold; text.TextScaled=true; text.Parent=gui
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(.04,0); pad.PaddingRight=UDim.new(.04,0); pad.Parent=text
end
local function sign(m: Instance,t: string,x: number,y: number,z: number,w: number)
 local p=box(m,"Sign_"..t,x,y,z,w,5,.6,C.dark); label(p,t); label(p,t,Enum.NormalId.Back)
end
local site=group("01_GroundAndRoads")
box(site,"Foundation",0,-3,0,1050,5,1000,C.grass,Enum.Material.Grass)
-- Main east-west avenue and connecting north-south roads follow the supplied plan.
box(site,"MainAvenue",0,.05,110,960,.25,38,C.road,Enum.Material.Asphalt)
box(site,"EastRoad",285,.05,-65,38,.25,730,C.road,Enum.Material.Asphalt)
box(site,"WestRoad",-410,.05,-45,28,.25,770,C.road,Enum.Material.Asphalt)
box(site,"BarracksRoad",-165,.05,-205,24,.25,450,C.road,Enum.Material.Asphalt)
box(site,"NorthRoad",-62,.05,-420,715,.25,28,C.road,Enum.Material.Asphalt)
for x=-460,460,28 do box(site,"LaneMark",x,.22,110,13,.05,.65,C.gold) end
for z=-390,280,28 do box(site,"LaneMark",285,.22,z,.65,.05,13,C.gold) end
for _,z in {88,132} do box(site,"AvenueCurb",0,.3,z,960,.6,2,C.concrete) end
for _,x in {263,307} do box(site,"RoadCurb",x,.3,-65,2,.6,730,C.concrete) end
for i=0,7 do box(site,"Crosswalk",-149+i*3,.24,110,1.7,.07,30,C.white) end
flush(site)
local function building(name: string,x: number,z: number,w: number,d: number,h: number,accent: Color3)
 local m=group(name)
 box(m,"RaisedFloor",x,.5,z,w+4,1,d+4,C.concrete)
 box(m,"RearWall",x,h/2+1,z-d/2,w,h,1,C.wall)
 box(m,"LeftWall",x-w/2,h/2+1,z,1,h,d,C.wall)
 box(m,"RightWall",x+w/2,h/2+1,z,1,h,d,C.wall)
 local side=(w-12)/2
 for _,dir in {-1,1} do box(m,"FrontWall",x+dir*(6+side/2),h/2+1,z+d/2,side,h,1,C.wall) end
 box(m,"DoorLintel",x,h-2,z+d/2,12,6,1,C.wall)
 box(m,"Roof",x,h+1.6,z,w+5,1.2,d+5,accent,Enum.Material.Metal)
 for _,dz in {-d/2,d/2} do box(m,"Fascia",x,h,z+dz,w+5,2,1.5,accent) end
 for dx=-w/2+9,w/2-7,14 do
  if math.abs(dx)>10 then
   for _,dz in {-d/2-.55,d/2+.55} do
    box(m,"WindowFrame",x+dx,h*.58,z+dz,9,7,.3,C.dark,Enum.Material.Metal)
    local glass=box(m,"Window",x+dx,h*.58,z+dz+(if dz>0 then .2 else -.2),8,6,.15,C.glass,Enum.Material.Glass); glass.Reflectance=.15
   end
  end
 end
 -- Clear doorway and low approach steps.
 box(m,"EntryStep",x,.25,z+d/2+5,15,.5,8,C.concrete)
 box(m,"EntryCanopy",x,11,z+d/2+4,19,.7,8,accent,Enum.Material.Metal)
 for _,dx in {-8,8} do box(m,"CanopyPost",x+dx,5.5,z+d/2+7,.5,11,.5,C.dark,Enum.Material.Metal) end
 sign(m,name,x,h-1,z+d/2+1,math.min(w-4,54))
 for dx=-w/2+14,w/2-10,25 do
  box(m,"Desk",x+dx,3,z-d/2+8,10,.6,5,C.roof,Enum.Material.Wood)
  for _,sx in {-4,4} do box(m,"DeskLeg",x+dx+sx,1.7,z-d/2+8,.5,2.5,4,C.dark) end
 end
 flush(m); return m
end
building("02_HQ · 본부",-285,-318,170,110,30,C.roof)
building("03_생활관 A",-285,-158,170,100,23,C.roof)
building("04_생활관 B",-285,-52,170,76,23,C.roof)
building("05_교육관",60,-360,300,75,25,C.roof)
building("06_군수창고",213,-260,65,118,22,C.roof)
building("07_장교 숙소",-325,270,140,240,25,C.roof)
building("08_PX",-100,36,64,50,18,Color3.fromRGB(78,101,105))
building("09_의무실",-30,36,60,50,18,Color3.fromRGB(106,119,107))
building("10_행정실",-95,-27,70,46,18,C.roof)
local parade=group("11_ParadeGround · 연병장")
box(parade,"ParadeSurface",75,.1,-170,300,.4,260,C.sand,Enum.Material.Ground)
for _,x in {-77,227} do box(parade,"Edge",x,.4,-170,2,.6,264,C.concrete) end
for _,z in {-302,-38} do box(parade,"Edge",75,.4,z,306,.6,2,C.concrete) end
for row=0,5 do for col=0,10 do box(parade,"FormationPosition",-43+col*23,.34,-250+row*31,3,.08,1.3,C.white) end end
box(parade,"ReviewingPlatform",75,1.5,-285,58,3,20,C.concrete)
box(parade,"PlatformStep",75,.5,-271,62,1,8,C.concrete)
for _,x in {40,110} do
 box(parade,"FlagPole",x,22,-285,.5,44,.5,Color3.fromRGB(180,185,183),Enum.Material.Metal)
 local flag=box(parade,"UnitFlag",x+6,39,-285,12,7,.15,C.roof,Enum.Material.Fabric); label(flag,"국군",Enum.NormalId.Front); label(flag,"국군",Enum.NormalId.Back)
end
sign(parade,"연병장  /  PARADE GROUND",75,6,-38,74)
flush(parade)
local park=group("12_MotorPool · 차량고")
box(park,"Hardstanding",45,.05,59,230,.25,46,C.road,Enum.Material.Asphalt)
for i=0,7 do box(park,"ParkingLine",-65+i*30,.25,57,.4,.05,34,C.white) end
for i=0,3 do
 local x=-49+i*51
 box(park,"TruckChassis",x,3.5,53,14,2,25,C.dark,Enum.Material.Metal)
 box(park,"TruckCab",x,7,45,14,6,8,C.roof,Enum.Material.Metal)
 box(park,"Windshield",x,8,40.9,11,3,.2,C.glass,Enum.Material.Glass)
 box(park,"CanvasBed",x,7,58,14,6,16,Color3.fromRGB(87,95,66),Enum.Material.Fabric)
 for _,dx in {-7.2,7.2} do for _,dz in {-7,7} do
  local wheel=box(park,"Wheel",x+dx,2.7,53+dz,2.3,5.4,5.4,C.dark,Enum.Material.Rubber); wheel.Shape=Enum.PartType.Cylinder
 end end
end
sign(park,"차량 집결지",177,7,63,32)
flush(park)
-- KCTC area: navigable mock village with open doorways and cover.
local training=group("13_KCTC_TrainingGround")
box(training,"TrainingPad",-48,-.05,287,365,.6,270,Color3.fromRGB(132,124,103),Enum.Material.Ground)
box(training,"TrainingStreet",-45,.3,280,350,.4,22,C.road,Enum.Material.Asphalt)
sign(training,"KCTC  ·  시가지 훈련장",-42,10,150,105)
for _,x in {-103,19} do box(training,"EntryPillar",x,5,150,2,10,2,C.dark) end
flush(training)
for row=0,1 do for col=0,3 do
 local x=-184+col*89; local z=217+row*137
 local m=building("KCTC_"..tostring(row*4+col+1),x,z,56,65,17+((col+row)%2)*6,Color3.fromRGB(103,106,98))
 -- A cover wall beside every mock house, outside its entrance.
 box(m,"CoverWall",x+32,3,z+23,3,6,20,C.concrete)
end end
local range=group("14_RifleRange · 사격장")
box(range,"RangeGround",402,.0,290,155,.3,268,C.sand,Enum.Material.Ground)
for _,x in {324,481} do box(range,"SafetyWall",x,7,290,3,14,272,C.concrete) end
box(range,"Backstop",402,10,421,160,20,12,Color3.fromRGB(106,100,79),Enum.Material.Ground)
box(range,"FiringRoof",402,13,182,155,1,34,C.roof,Enum.Material.Metal)
for _,x in {330,378,426,474} do box(range,"RoofPost",x,6.5,182,1,13,1,C.dark,Enum.Material.Metal) end
for lane=0,5 do
 local x=341+lane*24
 box(range,"LaneMark",x,.24,294,.4,.1,206,C.white)
 box(range,"FiringBench",x,3,188,14,.8,5,C.roof)
 for _,z in {280,335,391} do
  box(range,"TargetPost",x,4,z,.6,8,.6,C.dark)
  local target=box(range,"Target",x,8,z,7,9,.5,C.white)
  label(target,"◎",Enum.NormalId.Front); label(target,"◎",Enum.NormalId.Back)
 end
end
sign(range,"사격장  /  FIRING RANGE",402,17,164,100)
flush(range)
local obstacle=group("15_ObstacleCourse · 체력단련장")
box(obstacle,"Track",-96,.0,-216,84,.3,190,C.sand,Enum.Material.Ground)
for i=0,5 do
 local z=-287+i*27
 box(obstacle,"Hurdle",-110,2.5,z,36,1,1.5,C.roof,Enum.Material.Wood)
 for _,x in {-127,-93} do box(obstacle,"HurdleLeg",x,1.2,z,1,2.4,1,C.roof) end
end
for i=0,3 do
 box(obstacle,"ClimbWall",-64,2+i%2*2,-278+i*42,15,4+i%2*4,2,C.roof,Enum.Material.Wood)
end
sign(obstacle,"체력단련장",-99,8,-110,72)
flush(obstacle)
local boundary=group("16_PerimeterAndGate")
-- Fence panels and regularly spaced posts; road gates remain open for passage.
for x=-490,490,28 do
 for _,z in {-451,451} do
  box(boundary,"FencePost",x,6,z,.7,12,.7,C.dark,Enum.Material.Metal)
  for _,y in {3,6,9} do box(boundary,"FenceRail",x+14,y,z,28,.3,.3,C.dark,Enum.Material.Metal) end
 end
end
for z=-437,431,28 do
 for _,x in {-490,490} do
  if math.abs(z-110)>30 then
   box(boundary,"FencePost",x,6,z,.7,12,.7,C.dark,Enum.Material.Metal)
   for _,y in {3,6,9} do box(boundary,"FenceRail",x,y,z+14,.3,.3,28,C.dark,Enum.Material.Metal) end
  end
 end
end
for _,x in {-460,460} do
 box(boundary,"GatePillar",x,9,83,4,18,4,C.concrete)
 box(boundary,"GatePillar",x,9,137,4,18,4,C.concrete)
 local arch=box(boundary,"GateArch",x,19,110,4,5,58,C.roof); label(arch,"국군 생활 RP",Enum.NormalId.Left); label(arch,"국군 생활 RP",Enum.NormalId.Right)
end
flush(boundary)
building("17_위병소",443,57,45,32,14,C.roof)
local landscape=group("18_LandscapeAndLighting")
local random=Random.new(2210)
for i=1,65 do
 local x=if i<34 then -470+random:NextNumber(-8,8) else 465+random:NextNumber(-8,8)
 local z=-420+(i%33)*25
 if math.abs(z-110)>50 then
  box(landscape,"TreeTrunk",x,6,z,2,12,2,Color3.fromRGB(92,77,58),Enum.Material.Wood)
  local crown=box(landscape,"TreeCrown",x,15,z,14,19,14,Color3.fromRGB(65+random:NextInteger(0,20),91+random:NextInteger(0,15),62),Enum.Material.Grass); crown.Shape=Enum.PartType.Ball; crown.CanCollide=false; crown.CanTouch=false
 end
end
for x=-360,360,90 do
 box(landscape,"LampPost",x,11,137,.6,22,.6,C.dark,Enum.Material.Metal)
 box(landscape,"LampArm",x+3,22,137,6,.5,.5,C.dark,Enum.Material.Metal)
 local lamp=box(landscape,"Lamp",x+6,21.7,137,3,.5,2,C.white,Enum.Material.Neon)
 local light=Instance.new("PointLight"); light.Brightness=.7; light.Range=30; light.Color=Color3.fromRGB(255,224,170); light.Parent=lamp
end
-- Low beds and benches framing the spawn plaza.
for _,x in {-12,12} do
 box(landscape,"Planter",x,.7,-2,5,1.4,12,C.concrete)
 box(landscape,"Shrub",x,2,-2,4,2.2,10,C.grass,Enum.Material.Grass)
end
for _,x in {-190,180} do
 for i=0,2 do
  box(landscape,"Bench",x,2,15+i*18,14,.7,3,C.roof,Enum.Material.Wood)
  for _,dx in {-5,5} do box(landscape,"BenchLeg",x+dx,1,15+i*18,1,2,3,C.dark) end
 end
end
sign(landscape,"국군 생활 RP  |  부대 안내",0,10,-12,60)
for _,x in {-29,29} do box(landscape,"InformationPost",x,5,-12,1,10,1,C.dark) end
flush(landscape)
do
local root=workspace:FindFirstChild("MilitaryBaseMap") :: Model
local warehouse=root:FindFirstChild("06_군수창고") :: Model
warehouse:PivotTo(warehouse:GetPivot()+Vector3.new(140,0,0))
local pool=root:FindFirstChild("12_MotorPool · 차량고") :: Model
pool:PivotTo(pool:GetPivot()+Vector3.new(105,0,0))
local pad=pool:FindFirstChild("Hardstanding") :: BasePart; pad.Size=Vector3.new(220,.25,46)
local poolSign=pool:FindFirstChild("Sign_차량 집결지") :: BasePart; poolSign.Position=Vector3.new(239,7,77)
local course=root:FindFirstChild("15_ObstacleCourse · 체력단련장") :: Model
local track=course:FindFirstChild("Track") :: BasePart; track.Position=Vector3.new(-115,0,-216); track.Size=Vector3.new(65,.3,190)
for _,v in course:GetChildren() do if v.Name=="ClimbWall" and v:IsA("BasePart") then v.Position=Vector3.new(-85,v.Position.Y,v.Position.Z); v.Size=Vector3.new(10,v.Size.Y,2) end end
local function furniture(m: Instance,n: string,p: Vector3,s: Vector3,c: Color3): Part
 local v=Instance.new("Part"); v.Name=n; v.Size=s; v.Position=p; v.Color=c; v.Material=Enum.Material.SmoothPlastic; v.Anchored=true; v.TopSurface=Enum.SurfaceType.Smooth; v.Parent=m; return v
end
for _,spec in {{"03_생활관 A",-158,100},{"04_생활관 B",-52,76}} do
 local m=root:FindFirstChild(spec[1] :: string) :: Model
 local z=spec[2] :: number; local d=spec[3] :: number
 for _,dx in {-62,-40,-18,18,40,62} do
  for _,dz in {-d/2+22,d/2-20} do
   local p=Vector3.new(-285+dx,0,z+dz)
   for _,y in {2.5,7} do
    furniture(m,"BunkFrame",p+Vector3.new(0,y,0),Vector3.new(9,.6,15),Color3.fromRGB(50,59,56))
    furniture(m,"Mattress",p+Vector3.new(0,y+.6,0),Vector3.new(8.5,.7,14),Color3.fromRGB(105,121,99))
    furniture(m,"Pillow",p+Vector3.new(0,y+1.1,-5),Vector3.new(7,.4,3),Color3.fromRGB(210,211,192))
   end
   for _,sx in {-4,4} do for _,sz in {-7,7} do furniture(m,"BunkPost",p+Vector3.new(sx,4.5,sz),Vector3.new(.4,8,.4),Color3.fromRGB(50,59,56)) end end
  end
 end
 task.wait()
end
local hq=root:FindFirstChild("02_HQ · 본부") :: Model
furniture(hq,"BriefingTable",Vector3.new(-285,4,-310),Vector3.new(46,1,18),Color3.fromRGB(82,91,78))
for x=-304,-264,8 do for _,z in {-324,-296} do
 furniture(hq,"BriefingChair",Vector3.new(x,2.5,z),Vector3.new(5,1,5),Color3.fromRGB(55,73,66))
 furniture(hq,"ChairBase",Vector3.new(x,1.2,z),Vector3.new(1,2,1),Color3.fromRGB(42,44,43))
end end
-- Gate approaches connect the road ends to the fence opening.
local roads=root:FindFirstChild("01_GroundAndRoads") :: Model
for _,x in {-487,487} do local p=furniture(roads,"GateApproach",Vector3.new(x,.05,110),Vector3.new(20,.25,38),Color3.fromRGB(48,53,56)); p.Material=Enum.Material.Asphalt end
end
root:SetAttribute("Complete",true)
local camera=workspace.CurrentCamera
if camera then camera.CFrame=CFrame.lookAt(Vector3.new(850,850,1000),Vector3.new(0,0,-10)) end
local count=0
for _,v in root:GetDescendants() do if v:IsA("BasePart") then count+=1 end end
return "MilitaryBaseMap complete: "..count.." anchored parts"
