--!strict
-- Studio Edit-mode upgrade. Preserves current building footprints and map position.
-- Previous buildings are backed up in ServerStorage before replacement.
local root=workspace:FindFirstChild("MilitaryBaseMap") :: Model
assert(root,"MilitaryBaseMap is missing")
local storage=game:GetService("ServerStorage")
local backup=Instance.new("Folder"); backup.Name="MilitaryBuildings_Backup_"..os.date("%Y%m%d_%H%M%S"); backup.Parent=storage
local cream=Color3.fromRGB(210,201,180)
local dark=Color3.fromRGB(48,51,52)
local roofColor=Color3.fromRGB(58,65,70)
local wood=Color3.fromRGB(110,82,58)
local function part(m: Instance,n: string,cf: CFrame,s: Vector3,c: Color3,mat: Enum.Material?): Part
 local p=Instance.new("Part"); p.Name=n; p.Size=s; p.CFrame=cf; p.Anchored=true; p.Material=mat or Enum.Material.Concrete; p.Color=c; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=m; return p
end
local function text(p: BasePart,t: string)
 local g=Instance.new("SurfaceGui"); g.Face=Enum.NormalId.Back; g.CanvasSize=Vector2.new(1000,160); g.Parent=p
 local l=Instance.new("TextLabel"); l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=1; l.TextColor3=cream; l.Font=Enum.Font.GothamBold; l.TextScaled=true; l.Text=t; l.Parent=g
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(.04,0); pad.PaddingRight=UDim.new(.04,0); pad.Parent=l
end
local targets={}
for _,m in root:GetChildren() do if m:IsA("Model") and m:FindFirstChild("RaisedFloor") then table.insert(targets,m) end end
local results={}
for index,old in targets do
 local floor=old:FindFirstChild("RaisedFloor") :: BasePart
 local w,d=floor.Size.X-4,floor.Size.Z-4
 local origin=floor.CFrame*CFrame.new(0,.5,0)
 local stories=if string.find(old.Name,"HQ",1,true) then 3 else 2
 local h=stories*16
 local brick=if index%3==0 then Color3.fromRGB(139,88,66) elseif index%3==1 then Color3.fromRGB(153,83,64) else Color3.fromRGB(126,76,62)
 local m=Instance.new("Model"); m.Name=old.Name; m:SetAttribute("Floors",stories); m:SetAttribute("Style","Red brick / accessible interior stairs"); m:SetAttribute("FloorHeight",16)
 local function b(n: string,x: number,y: number,z: number,sx: number,sy: number,sz: number,c: Color3,mat: Enum.Material?): Part
  return part(m,n,origin*CFrame.new(x,y,z),Vector3.new(sx,sy,sz),c,mat)
 end
 b("RaisedFloor",0,-.5,0,w+4,1,d+4,cream)
 -- Facades consist of piers and spandrels, leaving actual window openings.
 local function facade(length: number,side: number)
  local function f(n: string,u: number,y: number,depth: number,sw: number,sh: number,sd: number,c: Color3,mat: Enum.Material?): Part
   local cf=if side==0 then CFrame.new(0,0,d/2) elseif side==1 then CFrame.new(0,0,-d/2)*CFrame.Angles(0,math.pi,0) elseif side==2 then CFrame.new(w/2,0,0)*CFrame.Angles(0,math.pi/2,0) else CFrame.new(-w/2,0,0)*CFrame.Angles(0,-math.pi/2,0)
   return part(m,n,origin*cf*CFrame.new(u,y,depth),Vector3.new(sw,sh,sd),c,mat)
  end
  local bays=math.max(3,math.floor(length/15)); if bays%2==0 then bays+=1 end
  local pitch=length/bays; local glassWidth=math.min(8,pitch-3)
  for level=0,stories-1 do
   local y=level*16
   for bay=0,bays-1 do
    local u=-length/2+(bay+.5)*pitch
    if side==0 and level==0 and bay==math.floor(bays/2) then
     local opening=math.min(10,pitch-2)
     f("EntryLintel",u,13,0,pitch,6,1.2,brick,Enum.Material.Brick)
     for _,sgn in {-1,1} do f("DoorJamb",u+sgn*(opening/2+(pitch-opening)/4),5,0,(pitch-opening)/2,10,1.2,brick,Enum.Material.Brick) end
     f("DoorFrameTop",u,10.2,.7,opening+1,.5,.4,cream)
     for _,sgn in {-1,1} do f("DoorFrame",u+sgn*(opening/2),5,.7,.4,10,.4,cream) end
    else
     f("BrickBelowWindow",u,y+2.5,0,pitch,5,1.2,brick,Enum.Material.Brick)
     f("BrickAboveWindow",u,y+14,0,pitch,4,1.2,brick,Enum.Material.Brick)
     local pier=(pitch-glassWidth)/2
     for _,sgn in {-1,1} do f("BrickPier",u+sgn*(glassWidth/2+pier/2),y+8.5,0,pier,7,1.2,brick,Enum.Material.Brick) end
     local g=f("WindowGlass",u,y+8.5,.05,glassWidth,7,.16,Color3.fromRGB(113,148,158),Enum.Material.Glass); g.Transparency=.35; g.Reflectance=.12
     f("StoneSill",u,y+4.9,.6,glassWidth+1.2,.5,2,cream)
     f("StoneLintel",u,y+12.2,.3,glassWidth+1.2,.6,1.5,cream)
     for _,sgn in {-1,1} do f("WindowFrame",u+sgn*glassWidth/2,y+8.5,.25,.25,7,.3,dark,Enum.Material.Metal) end
     f("WindowMullion",u,y+8.5,.25,.2,7,.3,dark,Enum.Material.Metal)
     f("WindowCrossbar",u,y+8.5,.25,glassWidth,.2,.3,dark,Enum.Material.Metal)
    end
   end
   if level>0 then f("FloorBeltCourse",0,y,.35,length+1,.7,1.7,cream) end
  end
  f("Cornice",0,h+.1,0,length+3,1,2.8,cream)
 end
 facade(w,0); task.wait(); facade(w,1); task.wait(); facade(d,2); task.wait(); facade(d,3); task.wait()
 for _,x in {-w/2,w/2} do for _,z in {-d/2,d/2} do
  b("CornerPier",x,h/2,z,1.8,h,1.8,brick,Enum.Material.Brick)
  for y=2,h-1,4 do b("CornerQuoin",x,y,z,2.1,1,2.1,cream) end
 end end
 -- Every upper storey has a real floor, with a stair opening along its right side.
 for level=1,stories-1 do
  local y=level*16
  b("Floor"..(level+1),-6,y-.4,0,w-12,.8,d-1,cream)
  local remaining=d-28
  b("StairLanding"..level,w/2-6,y-.4,14,12,.8,remaining,cream)
  local start=-d/2+2
  for step=1,24 do
   local top=(level-1)*16+step*16/24
   b("StairTread",w/2-6,top-.32,start+step-.5,8,.64,1.06,cream)
  end
  for _,x in {w/2-10.3,w/2-1.7} do
   local a=(origin*Vector3.new(x,(level-1)*16+3,start)); local c=(origin*Vector3.new(x,y+3,start+24))
   part(m,"StairHandrail",CFrame.lookAt((a+c)/2,c),Vector3.new(.25,.25,(c-a).Magnitude),dark,Enum.Material.Metal)
   for step=0,24,4 do b("RailPost",x,(level-1)*16+step*16/24+1.5,start+step,.2,3,.2,dark,Enum.Material.Metal) end
  end
  -- Guard the long edge of the upper floor opening.
  b("LandingGuardrail",w/2-12,y+3,-d/2+14,.25,.25,26,dark,Enum.Material.Metal)
  for z=-d/2+2,-d/2+26,4 do b("LandingGuardPost",w/2-12,y+1.5,z,.2,3,.2,dark,Enum.Material.Metal) end
 end
 -- Pitched standing-seam roof over a closed attic slab.
 b("AtticCeiling",0,h+.65,0,w+2,1,d+2,cream)
 local rise=math.min(10,d*.19); local half=d/2+2; local slope=math.atan(rise/half); local slopeLength=math.sqrt(half*half+rise*rise)
 for _,sgn in {-1,1} do
  local cf=origin*CFrame.new(0,h+1+rise/2,sgn*half/2)*CFrame.Angles(sgn*slope,0,0)
  part(m,"PitchedRoof",cf,Vector3.new(w+6,.65,slopeLength),roofColor,Enum.Material.Metal)
  for x=-w/2,w/2,10 do part(m,"RoofSeam",cf*CFrame.new(x,.4,0),Vector3.new(.12,.16,slopeLength),Color3.fromRGB(83,89,91),Enum.Material.Metal) end
 end
 b("RidgeCap",0,h+rise+1,0,w+6,.7,1,roofColor,Enum.Material.Metal)
 -- Triangular gable ends, closed by fitted horizontal masonry courses.
 for j=0,math.ceil(rise)-1 do
  local width=math.max(.2,2*half*(1-(j+.5)/rise))
  for _,x in {-w/2,w/2} do b("GableBrick",x,h+1+j+.5,0,1,1,width,brick,Enum.Material.Brick) end
 end
 for _,x in {-w/2-1,w/2+1} do
  b("Downpipe",x,h/2,d/2+1,.5,h,.5,dark,Enum.Material.Metal)
 end
 for _,z in {-d/2-1,d/2+1} do b("RainGutter",0,h+.5,z,w+5,.6,.7,dark,Enum.Material.Metal) end
 -- Entrance porch, lanterns, sign, and a clear passage.
 b("Porch",0,.0,d/2+4,18,.4,8,cream)
 b("Canopy",0,11.5,d/2+3,18,.6,7,roofColor,Enum.Material.Metal)
 for _,x in {-8,8} do
  b("PorchColumn",x,5.5,d/2+6,.7,11,.7,cream)
  local lamp=b("EntryLantern",x,8,d/2+1,1.1,1.8,1,Color3.fromRGB(244,211,151),Enum.Material.Neon)
  local light=Instance.new("PointLight"); light.Brightness=.4; light.Range=12; light.Color=lamp.Color; light.Parent=lamp
 end
 local board=b("BuildingSign",0,14,d/2+1,math.min(w-5,56),3,.5,dark); text(board,old.Name)
 -- Furnished upper levels leave a central corridor and the stair bay clear.
 for level=0,stories-1 do
  local y=level*16
  if string.find(old.Name,"생활관",1,true) or string.find(old.Name,"숙소",1,true) then
   for x=-w/2+12,w/2-26,21 do
    for _,z in {-d/2+15,d/2-17} do
     b("BedFrame",x,y+2,z,8,1,13,dark,Enum.Material.Metal)
     b("Mattress",x,y+2.8,z,7.6,.6,12.5,Color3.fromRGB(122,133,106),Enum.Material.Fabric)
     b("Pillow",x,y+3.2,z-4.5,6,.3,3,cream,Enum.Material.Fabric)
     b("Locker",x+7,y+4,z-4,4,8,5,Color3.fromRGB(85,96,82),Enum.Material.Metal)
    end
   end
  elseif not string.find(old.Name,"KCTC",1,true) then
   b("MeetingTable",-7,y+3.6,0,math.min(32,w-28),.8,8,wood,Enum.Material.Wood)
   for _,dz in {-7,7} do for dx=-16,3,9 do
    b("Chair",dx,y+2.1,dz,4,.7,4,dark)
    b("ChairBase",dx,y+1,dz,1,2,1,dark)
   end end
  end
  local guide=b("FloorDirectory",-w/2+1,y+8,0,.3,3,9,dark)
  guide:SetAttribute("Floor",level+1)
 end
 -- Retain an exact copy of the pre-upgrade building for rollback.
 local copy=old:Clone(); copy.Parent=backup
 m.Parent=root; old:Destroy(); task.wait()
 table.insert(results,{name=m.Name,floors=stories,parts=#m:GetDescendants()})
end
local decorative={RoofSeam=true,CornerQuoin=true,StoneSill=true,StoneLintel=true,WindowFrame=true,WindowMullion=true,WindowCrossbar=true,Downpipe=true,RainGutter=true,BuildingSign=true,FloorDirectory=true}
for _,m in root:GetChildren() do
 if m:GetAttribute("Floors") then
  for _,v in m:GetDescendants() do
   if v:IsA("BasePart") then
    v.CanTouch=false
    if decorative[v.Name] then v.CanCollide=false; v.CanQuery=false; v.CastShadow=false end
   end
  end
 end
end
root:SetAttribute("ArchitectureVersion",2)
return game:GetService("HttpService"):JSONEncode({backup=backup:GetFullName(),buildings=results})
