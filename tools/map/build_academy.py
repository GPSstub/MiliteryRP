"""Deterministic academy scenery manifest. Edit-time geometry only; no gameplay scripts."""
from pathlib import Path
import json, math
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/academy'
OUT.mkdir(exist_ok=True)
C={'brick':[139,89,73],'cream':[211,204,185],'stone':[164,163,151],'roof':[63,74,72],'glass':[100,139,149],'dark':[43,52,54],'white':[232,229,210],'wood':[125,95,65],'green':[77,99,66],'grass':[91,112,73],'road':[56,59,59],'gold':[214,182,99],'water':[69,116,128],'blue':[54,75,94]}
groups=[]; current=None

def group(name):
 global current
 current={'name':name,'parts':[]};groups.append(current)

def b(n,x,y,z,w,h,d,c='cream',mat='Concrete',yaw=0,shape='Block',text=None,alpha=0):
 p=dict(n=n,p=[x,y,z],s=[w,h,d],c=(C[c] if isinstance(c,str) else c),m=mat,r=yaw,shape=shape)
 if text:p['text']=text
 if alpha:p['alpha']=alpha
 current['parts'].append(p);return p

def sign(t,x,y,z,w=24,yaw=0): b('안내판',x,y,z,w,3,.4,'dark','Metal',yaw,text=t)
def line(n,a,bb,width=.4,height=.1,c='white',y=.55):
 x,z=a;xx,zz=bb;ln=math.hypot(xx-x,zz-z)
 b(n,(x+xx)/2,y,(z+zz)/2,width,height,ln,c,'Concrete',math.degrees(math.atan2(xx-x,zz-z)))
def desk(x,y,z):
 b('책상 상판',x,y+2.8,z,5,.4,3,'wood','Wood')
 for dx in [-2,2]:b('책상 다리',x+dx,y+1.3,z,.3,2.6,2,'dark','Metal')
 b('의자',x,y+1.5,z+3,2.5,.4,2.5,'blue','Fabric');b('의자 등받이',x,y+2.7,z+4,2.5,2,.3,'blue','Fabric')
 for dx in [-.9,.9]:b('의자 다리',x+dx,y+.7,z+3,.25,1.4,2,'dark','Metal')

def building(name,x,z,w,d,floors,kind,brick='brick'):
 group(name);current['floors']=floors;current['kind']=kind
 # 16-stud floor pitch; 12-wide corridor; west staircase 12x38, holes on upper floors.
 def q(n,dx,y,dz,sw,sh,sd,c='cream',mat='Concrete',**kw):return b(n,x+dx,y,z+dz,sw,sh,sd,c,mat,**kw)
 q('기초',0,.2,0,w+4,.4,d+4,'stone')
 for f in range(floors):
  y=.4+16*f
  if f==0:q('1층 바닥',0,y,0,w,.4,d,'cream')
  else:
   q('상층 바닥',7,y,0,w-14,.4,d)
   q('계단실 앞참',-w/2+7,y,(d/2+16.8)/2,14,.4,d/2-16.8)
   q('계단실 뒤참',-w/2+7,y,-(d/2+16.8)/2,14,.4,d/2-16.8)
  # fully open glazed facades: modular piers, spandrels, real glass.
  for side in [-1,1]:
   bays=int(w/14);pitch=w/bays
   for j in range(bays):
    dx=-w/2+(j+.5)*pitch
    entry=f==0 and j==bays//2
    if entry:
     q('출입문 상인방',dx,y+13,side*d/2,pitch,6,1.1,brick,'Brick')
     for sg in [-1,1]:q('출입문 문틀',dx+sg*(pitch/2-.4),y+5,side*d/2,.8,10,1.4,'stone')
    else:
     q('창하벽',dx,y+2,side*d/2,pitch,4,1.1,brick,'Brick')
     q('창상벽',dx,y+13,side*d/2,pitch,6,1.1,brick,'Brick')
     for sg in [-1,1]:q('창 기둥',dx+sg*(pitch/2-1),y+7,side*d/2,2,6,1.1,brick,'Brick')
     q('유리창',dx,y+7,side*d/2,pitch-4,6,.2,'glass','Glass',alpha=.38)
     q('창 세로 프레임',dx,y+7,side*d/2+.2,.25,6,.35,'dark','Metal')
     q('창 가로 프레임',dx,y+7,side*d/2+.25,pitch-4,.25,.35,'dark','Metal')
     q('석재 창턱',dx,y+3.9,side*(d/2+.5),pitch-3,.4,2,'stone')
   q('층간 수평띠',0,y+15.5,side*d/2,w+1,1,1.5,'stone')
  for side in [-1,1]:q('측벽',side*w/2,y+8,0,1.1,16,d,brick,'Brick')
  # paired rooms with openings to wide central corridor, far west reserved for stairs
  roomstart=-w/2+16; usable=w-18;count=max(2,int(usable/26));rw=usable/count
  for j in range(count):
   dx=roomstart+(j+.5)*rw
   for side in [-1,1]:
    q('복도 칸막이',dx-3,y+5.5,side*7,rw-6,11,.5)
    q('방 문 상인방',dx+rw/2-3,y+10,side*7,6,2,.5)
    if j==0 and side==1 and f>0:
     q('계단 연결벽',dx-rw/2,y+6,12.5,.5,12,11)
     q('계단 연결벽',dx-rw/2,y+6,(26+d/2)/2,.5,12,d/2-26)
     q('계단 연결문 상인방',dx-rw/2,y+10,22,.5,4,8)
    else:
     q('실 구획벽',dx-rw/2,y+6,side*(d/4+3.5),.5,12,d/2-7)
    zz=side*(d/4+4)
    sign(f'{f+1}{j+1:02d}  '+{'barracks':'생활실','office':'행정실','class':'강의실','library':'열람실','medical':'진료실','mess':'식당','museum':'전시실','gym':'체력단련실','hall':'회의실','service':'보급실'}[kind],x+dx,y+9,z+side*7.3, min(rw-7,16),180 if side>0 else 0)
    if kind=='barracks':
     for k in [-1,1]:
      bx=dx+k*6
      for by in [2,7]:
       q('침상 프레임',bx,y+by,zz,5,.5,9,'dark','Metal');q('매트리스',bx,y+by+.5,zz,4.7,.6,8.7,'blue','Fabric');q('베개',bx,y+by+1,zz-3,3,.5,1.5,'white','Fabric')
      for a in [-2.4,2.4]:
       for v in [-4.4,4.4]:q('이층침대 기둥',bx+a,y+4.5,zz+v,.3,9,.3,'dark','Metal')
     q('개인 관물대',dx,y+4,side*(d/2-3),rw-3,8,3,'green','Metal')
     for v in [-6,0,6]:q('관물대 손잡이',dx+v,y+4,side*(d/2-4.6),.3,1,.3,'dark','Metal')
    elif kind in ('class','office','hall'):
     for k in [-1,1]:
      for row in [-1,1]:desk(x+dx+k*5,y,z+zz+row*5)
     q('칠판' if kind=='class' else '게시판',dx,y+7,side*(d/2-.7),rw-5,4,.3,'green')
    elif kind=='library':
     for k in [-1,1]:
      q('서가',dx+k*7,y+4,zz,3,8,10,'wood','Wood')
      for yy in [1,3,5,7]:
       q('책장 선반',dx+k*7,y+yy,zz,3,.3,10,'cream','Wood')
       for a in range(4):q('서적 묶음',dx+k*7,y+yy+1,zz-3+a*2,2.7,1.5,1.4,['blue','brick','green','gold'][a],'Fabric')
     desk(x+dx,y,z+side*12)
    elif kind=='medical':
     for k in [-1,1]:
      q('병상',dx+k*6,y+2,zz,5,1,10,'white','Metal');q('병상 매트리스',dx+k*6,y+2.8,zz,4.8,.6,9,'blue','Fabric');q('병상 다리',dx+k*6,y+.8,zz,4,1.6,7,'dark','Metal')
     q('의약품 수납장',dx,y+4,side*(d/2-2),rw-3,8,2,'white','Metal')
    elif kind=='mess':
     q('식탁',dx,y+3,zz,rw-5,.5,7,'white','Metal')
     for k in [-1,1]:q('긴 의자',dx,y+1.6,zz+k*5,rw-5,.5,2,'wood','Wood');q('의자 받침',dx,y+.7,zz+k*5,rw-7,1.4,1,'dark','Metal')
     q('식탁 받침',dx,y+1.4,zz,2,2.8,5,'dark','Metal')
    elif kind=='gym':
     q('운동 매트',dx,y+.4,zz,12,.5,12,'blue','Rubber')
     for k in [-1,1]:q('철봉 기둥',dx+k*5,y+4,zz,.5,8,.5,'dark','Metal')
     q('철봉',dx,y+8,zz,10,.5,.5,'dark','Metal')
    elif kind=='museum':
     q('전시대',dx,y+2,zz,10,4,6,'stone');q('전시 모형',dx,y+5,zz,6,2,3,'green','Metal');q('전시 배경',dx,y+6,side*(d/2-1),rw-3,10,.4,'blue')
    else:
     for k in [-1,1]:q('보급 선반',dx+k*6,y+4,zz,8,8,8,'green','Metal')
  # luminaires and corridor stripes
  for dx in range(int(-w/2+23),int(w/2-5),22):q('천장 등기구',dx,y+14.6,0,6,.25,2,'white','Neon')
  if f<floors-1:
   # 24 treads, rise 2/3, run 1.4 = 33.6, inside a 48+ depth stairwell
   for s in range(24):q('계단',-w/2+7,y+(s+1)*2/3-.25,-16.8+(s+.5)*1.4,10,.5,1.4,'stone')
   for zz in [-16,0,16]:q('계단 난간 기둥',-w/2+12.3,y+((zz+16.8)/33.6*16)+1.5,zz,.25,3,.25,'dark','Metal')
   # sloping rail along stair flight
   p=q('계단 손잡이',-w/2+12.3,y+9.7,0,.35,.35,37.2,'dark','Metal');p['pitch']=-25.46
  # stairwell guard at landing keeps opening free
  if f>0:q('계단실 측면 난간',-w/2+14,y+1.8,0,.3,3.4,34,'dark','Metal')
 q('옥상 슬래브',0,floors*16+.7,0,w+3,1,d+3,'roof')
 for side in [-1,1]:
  q('옥상 파라펫',0,floors*16+2,side*d/2,w+2,2,1,'stone')
  q('옥상 파라펫',side*w/2,floors*16+2,0,1,2,d,'stone')
 for dx in [-w/4,w/4]:q('옥상 공조기',dx,floors*16+2.7,-d/4,9,3,6,'dark','Metal')
 # actual entrance centered on facade bay, not generic midpoint
 pitch=w/int(w/14);entry=-w/2+(int(w/14)//2+.5)*pitch
 q('현관 캐노피',entry,11,d/2+5,20,.6,10,'roof','Metal')
 for dx in [-9,9]:q('현관 기둥',entry+dx,5.5,d/2+9,.6,11,.6,'stone')
 sign(name,x+entry,13,z+d/2+1,min(w-10,58),180)
 q('현관 보행로',entry,.25,d/2+16,18,.3,28,'stone')
 for side in [-1,1]:q('배수 홈통',side*(w/2-.8),floors*8,d/2+1,.4,floors*16,.4,'dark','Metal')

group('00_지반과 도로')
b('캠퍼스 대지',0,-1.5,0,1700,3,1500,'grass','Grass')
# Roads border distinct blocks and remain clear of structures.
for x in [-740,-430,140,620]:
 b('남북 도로',x,.05,0,28,.1,1330,'road','Asphalt')
 for dx in [-20,20]:b('인도',x+dx,.2,0,10,.4,1330,'stone')
 for z in range(-630,650,26):b('중앙선',x,.13,z,.35,.06,12,'gold')
for z in [-630,-390,-30,310,640]:
 b('동서 도로',0,.07,z,1500,.1,26,'road','Asphalt')
 for dz in [-19,19]:b('인도',0,.22,z+dz,1500,.4,10,'stone')
 for x in range(-720,730,26):b('중앙선',x,.15,z,12,.06,.35,'gold')
# plaza to existing parade; widths never under 8 studs
b('연병장 주변 보도',-170,.03,-170,590,.1,228,'stone')
# buildings grouped by geographic role, 1-4 stories
building('01 학교본부',-190,-520,168,72,3,'office','cream')
building('02 을지강당',340,-520,168,80,2,'hall')
building('03 화랑관 A 생활관',-580,-280,140,74,4,'barracks')
building('04 화랑관 B 생활관',-580,-130,140,74,4,'barracks')
building('05 충무관 교육동',310,-290,220,68,3,'class')
building('06 흥무관 교육동',310,-150,220,68,3,'class')
building('07 도서관',300,95,150,84,3,'library','cream')
building('08 익양관 교육동',500,220,136,64,2,'class')
building('09 육사병원',-580,100,140,68,2,'medical','cream')
building('10 생도회관 및 식당',-270,90,154,70,2,'mess')
building('11 육군박물관',-580,250,144,68,2,'museum','cream')
building('12 군수지원단',735,-260,110,76,2,'service')
building('13 군악대',735,-500,110,68,1,'hall')
building('14 서애관 체육관',-150,500,120,78,1,'gym','cream')
building('15 양지관 체육관',10,500,110,78,1,'gym','cream')
building('16 장교회관',745,95,112,74,3,'office')
building('17 방문객 안내소',520,560,84,54,1,'office','cream')
building('18 정문 위병소',700,560,60,54,1,'office','cream')

group('20_화랑정원과 붕어지')
b('연못 테두리',-210,.25,225,172,.5,90,'stone')
b('수면',-210,.6,225,160,.4,78,'water','Glass',alpha=.18)
for dx in [-92,92]:b('수변 산책로',-210+dx,.2,225,12,.4,110,'cream')
for dz in [-53,53]:b('수변 산책로',-210,.2,225+dz,196,.4,12,'cream')
b('목재 다리',-210,1.2,225,12,.8,100,'wood','WoodPlanks')
for x in [-217,-203]:
 for z in range(178,274,8):b('다리 난간',x,2.8,z,.4,3.2,.4,'dark','Metal')
 b('다리 손잡이',x,4.4,225,.5,.5,100,'dark','Metal')
# formal memorial, abstract deliberate stone form
b('기념광장',-30,.2,150,100,.4,100,'stone')
for y,s in [(1,30),(2,24),(3,18)]:b('기념탑 기단',-30,y,150,s,1,s,'cream')
b('기념탑',-30,17,150,5,28,5,'stone')
sign('조국 · 명예 · 헌신',-30,4,160,20,180)

group('21_체육시설')
# rectangular rounded running track using straightaways and semicircular line segments
cx,cz=-490,480
b('육상 트랙',cx,.12,cz,290,.2,250,'brick','Rubber')
b('축구장',cx,.28,cz,210,.1,150,'green','Grass')
for x in [cx-100,cx+100]:line('터치라인',(x,cz-70),(x,cz+70),y=.4)
for z in [cz-70,cz+70]:line('터치라인',(cx-100,z),(cx+100,z),y=.4)
line('하프라인',(cx,cz-70),(cx,cz+70),y=.4)
for i in range(40):
 a=i*math.tau/40;aa=(i+1)*math.tau/40;line('센터서클',(cx+22*math.cos(a),cz+22*math.sin(a)),(cx+22*math.cos(aa),cz+22*math.sin(aa)),y=.4)
for side in [-1,1]:
 gx=cx+side*101
 for dz in [-12,12]:b('골대',gx,5,cz+dz,.5,10,.5,'white','Metal')
 b('골대 가로대',gx,10,cz,.5,.5,24,'white','Metal')
 for zz in range(-12,13,3):b('골망',gx+side*5,5,cz+zz,.12,10,.12,'white','Metal')
 for yy in range(1,11,2):b('골망',gx+side*5,yy,cz,.12,.12,24,'white','Metal')
 for lane in range(5):
  zoff=83+lane*5
  line('육상 주로',(cx-55,cz+side*zoff),(cx+55,cz+side*zoff),y=.27)
  for i in range(24):
   a=-math.pi/2+i*math.pi/24;aa=a+math.pi/24
   line('육상 주로',(cx+side*(55+zoff*math.cos(a)),cz+zoff*math.sin(a)),(cx+side*(55+zoff*math.cos(aa)),cz+zoff*math.sin(aa)),y=.27)
# basketball court east
b('농구 코트',350,.2,455,145,.3,96,'blue','Rubber')
for z in [410,500]:line('농구 경계',(280,z),(420,z),y=.4)
for x in [280,420]:line('농구 경계',(x,410),(x,500),y=.4)
for x in [285,415]:
 b('농구대 지주',x,7,455,.8,14,.8,'dark','Metal');b('백보드',x,13,455,.5,6,10,'white')
# low bleachers clear of paths
for row in range(4):b('관람석',350,1+row,520+row*3,130,1,3,'stone')

group('22_정문과 주차장')
for x in [600,640]:b('정문 석주',x,8,610,5,16,5,'stone')
b('정문 상부',620,17,610,48,3,7,'cream');sign('국군 생활 RP · 육군사관학교',620,17,614,44,180)
for x in [605,635]:b('차단기 지주',x,2,603,1,4,1,'dark','Metal')
# barriers shown raised to keep traversable
for x in [605,635]:b('열린 차단기',x,8,603,.5,12,.5,'white','Metal')
b('방문객 주차장',340,.12,580,200,.2,78,'road','Asphalt')
for x in range(250,440,15):line('주차 구획',(x,547),(x,570),y=.3);line('주차 구획',(x,590),(x,613),y=.3)
for x in [500,710]:
 for z in range(596,624,4):b('횡단보도',x,.18,z,25,.1,1.7,'white')

group('23_조경과 가로시설')
def tree(x,z,i):
 b('수목 줄기',x,4,z,1.5,8,1.5,'wood','Wood')
 b('수관',x,11,z,10,15,10,[[58,82,53],[67,91,58],[79,99,63]][i%3],'Grass',shape='Ball')
for z in [-365,-5,335]:
 for i,x in enumerate(range(-700,600,46)):tree(x,z,i)
for x in [-790,810]:
 for i,z in enumerate(range(-670,680,35)):tree(x,z,i)
for z in [-690,700]:
 for i,x in enumerate(range(-760,800,35)):tree(x,z,i)
for x in [-450,160,600]:
 for z in range(-580,620,105):
  b('가로등',x,8,z,.4,16,.4,'dark','Metal');b('등기구',x,16,z,3,.6,2,'white','Neon')
for x in [-340,-80,35]:
 for z in [175,275]:
  b('벤치',x,1.7,z,10,.5,2.5,'wood','Wood');b('벤치 등받이',x,3,z+1.3,10,2,.4,'wood','Wood')
  for dx in [-4,4]:b('벤치 받침',x+dx,.7,z,.5,1.4,2,'dark','Metal')
# perimeter fencing, gate gap on south
for x in [-830,830]:
 b('외곽 담장',x,2.5,0,1.2,5,1450,'stone')
 for z in range(-720,721,30):b('담장 기둥',x,3.5,z,2,7,2,'cream')
for z in [-725,725]:
 for start,end in [(-830,590),(650,830)]:
  b('외곽 담장',(start+end)/2,2.5,z,end-start,5,1.2,'stone')
  for x in range(start,end,30):b('담장 기둥',x,3.5,z,2,7,2,'cream')
# front exit road joins edge gate
b('진입로',620,.06,690,28,.1,110,'road','Asphalt')
(OUT/'manifest.json').write_text(json.dumps(groups,ensure_ascii=False,separators=(',',':')))
print(len(groups),'zones;',sum(len(g['parts']) for g in groups),'parts')
