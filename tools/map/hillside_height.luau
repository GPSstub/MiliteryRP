--!strict
-- Authored terrain: a low southern campus and forested northern/western ridges.
local plan = game:GetService('HttpService'):JSONDecode(PLAN_JSON)
local function smooth(t: number): number
 t=math.clamp(t,0,1); return t*t*(3-2*t)
end
local function height(x: number,z: number): number
 local north=math.clamp((100-z)/750,0,1)
 local h=2+50*north+4*math.noise(x/170,z/170,19)
 local peaks={{-760,-650,310,235,310},{-320,-850,350,310,180},{220,-850,320,300,190},{700,-700,285,230,290},{-880,-100,220,150,330},{820,-180,185,165,350},{-840,520,90,180,220}}
 for _,p in peaks do
  local e=((x-p[1])/p[4])^2+((z-p[2])/p[5])^2
  h+=p[3]*math.exp(-e*1.5)
 end
 local edge=math.max(math.abs(x)-610,-z-550,0)
 h+=math.min(edge/100,1)*(20*math.noise(x/110,z/110,6)+8*math.noise(x/38,z/38,15))
 -- Terrain terraces stop short of slabs. Soft shoulders join natural slopes.
 for _,p in plan.pads do
  local a=math.rad(p.r);local dx=x-p.x;local dz=z-p.z
  local lx=dx*math.cos(a)-dz*math.sin(a);local lz=dx*math.sin(a)+dz*math.cos(a)
  local dist=math.max(math.abs(lx)-p.w/2,math.abs(lz)-p.d/2)
  if dist<28 then local t=1-smooth(math.max(dist,0)/28);h=h*(1-t)+p.y*t end
 end
 -- Keep roads walkable along their full elevation profile.
 for ri,road in plan.roads do
  local width=if ri<=10 then 17 else 9
  for i=1,#road-1 do
   local a,b=road[i],road[i+1];local vx,vz=b[1]-a[1],b[3]-a[3]
   local t=math.clamp(((x-a[1])*vx+(z-a[3])*vz)/(vx*vx+vz*vz),0,1)
   local dist=math.sqrt((x-a[1]-t*vx)^2+(z-a[3]-t*vz)^2)
   if dist<width+12 then local blend=1-smooth(math.max(dist-width,0)/12);local roadY=a[2]+t*(b[2]-a[2]);h=h*(1-blend)+(roadY-.3)*blend end
  end
 end
 for _,p in plan.pads do
  local a=math.rad(p.r);local dx=x-p.x;local dz=z-p.z
  local lx=dx*math.cos(a)-dz*math.sin(a);local lz=dx*math.sin(a)+dz*math.cos(a)
  if math.abs(lx)<p.w/2-6 and math.abs(lz)<p.d/2-6 then h=p.y end
 end
 return h-2.5
end
