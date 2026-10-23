"""Authored compact hillside layout and new drill-ground scenery."""
import json,math,random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets/academy'
# name, old center, new center, elevation, yaw, building dimensions
P=[
[1,-190,-520,-130,-400,34,-8,168,72], [2,340,-520,85,-465,42,12,168,80],
[3,-580,-280,-470,-190,18,-8,140,74],[4,-580,-130,-465,-65,12,-8,140,74],
[5,310,-290,235,-310,28,-14,220,68],[6,310,-150,260,-180,20,-14,220,68],
[7,300,95,235,0,12,-14,150,84],[8,500,220,400,115,12,-18,136,64],
[9,-580,100,-465,80,8,8,140,68],[10,-270,90,-230,65,8,-8,154,70],
[11,-580,250,-455,215,5,15,144,68],[12,735,-260,455,-260,32,-14,110,76],
[13,735,-500,430,-420,50,12,110,68],[14,-150,500,-180,385,0,10,120,78],
[15,10,500,-25,370,2,10,110,78],[16,745,95,470,-60,24,-14,112,74],
[17,520,560,315,405,2,-12,84,54],[18,700,560,460,390,2,-12,60,54]]
roads=[
[[-650,0,590],[-650,8,230],[-620,16,-100],[-600,32,-380],[-350,44,-535],[0,50,-570],[340,58,-550],[560,42,-340],[600,20,0],[520,4,400],[440,0,600],[-200,0,620],[-650,0,590]],
[[-370,12,-320],[-20,28,-350],[140,24,-340],[150,16,-60],[120,10,35],[-350,10,20],[-370,12,-320]],
[[160,26,-380],[170,20,-220],[170,12,-60],[160,6,180],[200,0,410],[430,0,500],[440,0,600]],
[[-620,12,5],[-350,10,20]],
[[-620,6,160],[-330,6,160],[-50,4,140],[160,6,180],[560,12,220]],
[[-610,0,305],[-330,0,300],[-260,0,470],[180,0,475],[430,0,500]],
[[-350,44,-535],[-345,22,-365],[-370,12,-320]],
[[140,24,-340],[400,30,-355],[560,42,-340]],
[[150,16,-60],[360,20,-95],[595,24,-150]],
[[120,10,35],[355,12,65],[600,18,60]]]
pads=[dict(x=p[3],z=p[4],y=p[5]-.3,r=p[6],w=p[7]+16,d=p[8]+25) for p in P]
pads+= [dict(x=-120,z=-150,y=11.7,r=-8,w=444,d=244),dict(x=-425,z=445,y=-.2,r=10,w=300,d=262),dict(x=180,z=300,y=-.2,r=-10,w=158,d=120),dict(x=-160,z=220,y=2.7,r=8,w=210,d=120),dict(x=345,z=510,y=-.2,r=-12,w=220,d=78)]
def tf(dx,dz,x,z,r):
 a=math.radians(r);return x+dx*math.cos(a)+dz*math.sin(a),z-dx*math.sin(a)+dz*math.cos(a)
# Gate/entry roads are explicit and resolve height differences with ramps.
for p in P:
 _,ox,oz,x,z,y,r,w,d=p
 ex,ez=tf(7,d/2+29,x,z,r)
 nearest=None
 for road in roads[:10]:
  for a,bb in zip(road,road[1:]):
   vx,vz=bb[0]-a[0],bb[2]-a[2];tt=max(0,min(1,((ex-a[0])*vx+(ez-a[2])*vz)/(vx*vx+vz*vz)))
   xx,zz=a[0]+tt*vx,a[2]+tt*vz;dist=math.hypot(xx-ex,zz-ez)
   if nearest is None or dist<nearest[0]:nearest=(dist,[xx,a[1]+tt*(bb[1]-a[1]),zz])
 roads.append([[ex,y,ez],nearest[1]])
plan=dict(buildings=P,roads=roads,pads=pads,parade=dict(x=-120,y=12,z=-150,r=-8,w=420,d=220))
(OUT/'hillside-plan.json').write_text(json.dumps(plan,separators=(',',':')))
# Reuse original primitive helpers without executing its original map layout.
source=(ROOT/'tools/map/build_academy.py').read_text().split("group('00_지반과 도로')")[0]
ns={'__file__':str(ROOT/'tools/map/build_academy.py')};exec(source,ns)
b,group,sign,line=[ns[k] for k in ['b','group','sign','line']]
group('24_곡선도로와 옹벽')
for ri,road in enumerate(roads):
 width=22 if ri<10 else 12
 for aa,bb in zip(road,road[1:]):
  dist=math.dist(aa,bb);steps=max(1,math.ceil(dist/16))
  for i in range(steps):
   a=[aa[k]+(bb[k]-aa[k])*i/steps for k in range(3)];c=[aa[k]+(bb[k]-aa[k])*(i+1)/steps for k in range(3)]
   horizontal=math.hypot(c[0]-a[0],c[2]-a[2]);length=math.dist(a,c);r=math.degrees(math.atan2(c[0]-a[0],c[2]-a[2]));pitch=-math.degrees(math.atan2(c[1]-a[1],horizontal))
   mid=[(a[k]+c[k])/2 for k in range(3)]
   q=b('경사 차도' if ri<10 else '진입 경사로',mid[0],mid[1]+.5,mid[2],width,.5,length+.2,'road' if ri<10 else 'stone','Asphalt' if ri<10 else 'Concrete',yaw=r);q['pitch']=pitch
   if ri<10:
    for side in [-1,1]:
     x,z=tf(side*(width/2+2),0,mid[0],mid[2],r);q=b('도로 연석',x,mid[1]+.75,z,3,.7,length+.2,'stone',yaw=r);q['pitch']=pitch
    if i%2==0:q=b('차선',mid[0],mid[1]+.78,mid[2],.35,.05,length*.55,'gold',yaw=r);q['pitch']=pitch
for p in P:
 _,ox,oz,x,z,y,r,w,d=p
 if y>=12:
  for side in [-1,1]:
   px,pz=tf(side*(w/2+7),0,x,z,r);b('테라스 옹벽',px,y-2.5,pz,2,5,d+18,'stone','Cobblestone',r)
  px,pz=tf(0,-d/2-9,x,z,r);b('테라스 옹벽',px,y-2.5,pz,w+16,5,2,'stone','Cobblestone',r)
# New parade built in local coordinates, then placed on the authored terrace.
group('NewDrillGeometry')
b('WalkableFloor',0,11.7,0,420,.6,220,[160,153,133],'Concrete')
for z in [-111,111]:b('연병장 배수로',0,12.1,z,424,.2,2,'dark','Metal')
for x in [-211,211]:b('연병장 배수로',x,12.1,0,2,.2,224,'dark','Metal')
for row in range(2):
 for col in range(3):
  cx=-138+col*138;cz=-38+row*90
  for zz in [-20,20]:line('시험 구획',(cx-64,cz+zz),(cx+64,cz+zz),.3,.06,'white',12.06)
  for xx in [-64,64]:line('시험 구획',(cx+xx,cz-20),(cx+xx,cz+20),.3,.06,'white',12.06)
  for j in range(30):b('대열 위치',cx+(j-14.5)*4,12.09,cz,1,.06,1,'white')
  b('구역 번호',cx,12.1,cz-16,8,.08,4,'gold')
b('사열대 기단',0,13.5,-91,76,3,24,'stone')
for i in range(6):b('사열대 계단',0,12+(i+1)*.25,-74-i*1.4,30,(i+1)*.5,1.4,'stone')
b('사열대 캐노피',0,27,-93,78,1,22,'roof','Metal')
for x in [-36,36]:b('사열대 기둥',x,20,-98,1,14,1,'cream')
sign('화랑연병장 · 조국과 국민을 위하여',0,23,-102,64,180)
for x in [-45,45]:
 b('국기게양대 기단',x,12.7,-92,7,1.4,7,'stone');b('국기게양대',x,27,-92,.5,30,.5,'white','Metal')
# Monument keeps identity without pretending a primitive is a sculpted statue.
b('사열대 표장',0,19,-102,5,5,.5,'gold','Metal',yaw=45)
for side in [-1,1]:
 for r in range(3):b('관람석',side*220,12.5+r*.7,-58+r*3,10,1,55,'stone')
for a in ns['current']['parts']:
 a['p'][0],a['p'][2]=tf(a['p'][0],a['p'][2],-120,-150,-8);a['r']-=8
# parking and gate: 1-floor shelters retained; replace surrounding scene.
group('25_정문광장')
b('주차장',345,.15,510,210,.3,72,'road','Asphalt',-12)
for dx in range(-95,100,15):
 for dz in [-22,22]:
  x,z=tf(dx,dz,345,510,-12);b('주차선',x,.34,z,.25,.05,22,'white',yaw=-12)
for dx in [-20,20]:b('정문 석주',440+dx,8,570,5,16,5,'stone')
b('정문 상부',440,17,570,48,3,6,'cream');sign('육군사관학교 · 국군 생활 RP',440,17,574,44,180)
for x in [420,460]:b('개방 차단기',x,6,554,.5,12,.5,'white','Metal')
# serialize compact scenery; existing buildings will be transformed, not regenerated.
(OUT/'hillside-environment.json').write_text(json.dumps(ns['groups'],ensure_ascii=False,separators=(',',':')))
print('Layout:',len(P),'buildings; new environment:',sum(len(g['parts']) for g in ns['groups']),'parts')
