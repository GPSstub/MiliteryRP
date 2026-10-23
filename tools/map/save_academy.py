"""Merge academy scenery into the complete place, preserving scripts and old scenery.
The initial backup is mandatory. Never calls the test-place generator.
"""
from pathlib import Path
import xml.etree.ElementTree as E
import json, math, hashlib
ROOT=Path(__file__).resolve().parents[2]
backup=ROOT/'backups/MilitaryRP.before-academy-20261022.rbxlx'
assert backup.exists()
path=ROOT/'MilitaryRP.rbxlx'
tree=E.parse(path);root=tree.getroot()
def name(i):return i.findtext("Properties/string[@name='Name']")
world=next(i for i in root.findall('Item') if i.get('class')=='Workspace')
assert not any(name(i)=='AcademyCampus' for i in world.findall('Item')),'Already installed'
script_hash=lambda:hashlib.sha256(''.join(i.text or '' for i in root.iter('ProtectedString')).encode()).hexdigest()
before=script_hash();counter=0
used={i.get('referent') for i in root.iter('Item')}
def item(parent,cls,n):
 global counter
 counter+=1;ref=f'Academy20261022_{counter}';assert ref not in used
 i=E.SubElement(parent,'Item',{'class':cls,'referent':ref});E.SubElement(i,'Properties');prop(i,'string','Name',n);return i

def prop(i,typ,n,v):
 ps=i.find('Properties');old=ps.find(f"*[@name='{n}']")
 if old is not None:ps.remove(old)
 p=E.SubElement(ps,typ,{'name':n})
 if isinstance(v,dict):
  for k,val in v.items():E.SubElement(p,k).text=str(val)
 else:p.text=str(v).lower() if isinstance(v,bool) else str(v)
 return p

def frame(i,p,yaw=0,pitch=0):
 a=math.radians(yaw);b=math.radians(pitch);ca,sa,cb,sb=math.cos(a),math.sin(a),math.cos(b),math.sin(b)
 vals=[ca,0,sa,sb*sa,cb,-sb*ca,-cb*sa,sb,cb*ca]
 prop(i,'CoordinateFrame','CFrame',dict(zip(['X','Y','Z']+[f'R{x}{y}' for x in range(3) for y in range(3)],p+vals)))
materials={'Wood':512,'Glass':1568,'Neon':288,'WoodPlanks':528,'Brick':848,'Rubber':2311,'Fabric':1312,'Concrete':816,'Grass':1280,'Asphalt':1376,'Metal':1088}
ss=next((i for i in root.findall('Item') if i.get('class')=='ServerStorage'),None)
if ss is None:ss=item(root,'ServerStorage','ServerStorage')
archive=item(ss,'Folder','BeforeAcademy_20261022')
archived=[]
for i in list(world.findall('Item')):
 n=name(i) or ''
 if n in ('TestFloor','SportsStadium','Scene','Part') or n.startswith('05_'):
  world.remove(i);archive.append(i);archived.append(n)
# Translation keeps existing drill model, markers, meshes and all references intact.
for i in world.findall('Item'):
 if name(i)=='ExamDrillGround':
  for cf in i.findall('.//CoordinateFrame'):
   for k,v in [('X',-324.644165),('Z',10.0011)]:
    e=cf.find(k)
    if e is not None:e.text=str(float(e.text)+v)
 if name(i)=='RankSpawn':frame(i,[620,1,575])
model=item(world,'Model','AcademyCampus')
origin=item(model,'Part','Origin');prop(origin,'bool','Anchored',True);prop(origin,'bool','CanCollide',False);prop(origin,'float','Transparency',1);prop(origin,'Vector3','size',dict(X=1,Y=1,Z=1));frame(origin,[0,0,0])
G=json.load(open(ROOT/'assets/academy/manifest.json'))
for g in G:
 zone=item(model,'Model',g['name'])
 if 'floors' in g:
  value=item(zone,'IntValue','Floors');prop(value,'int','Value',g['floors'])
 for a in g['parts']:
  p=item(zone,'Part',a['n']);prop(p,'bool','Anchored',True);prop(p,'bool','CanTouch',False)
  prop(p,'Vector3','size',dict(zip('XYZ',a['s'])));frame(p,a['p'],a['r'],a.get('pitch',0))
  prop(p,'Color3uint8','Color3uint8',0xFF000000+(a['c'][0]<<16)+(a['c'][1]<<8)+a['c'][2]);prop(p,'token','Material',materials[a['m']]);prop(p,'token','shape',0 if a['shape']=='Ball' else 1)
  prop(p,'token','TopSurface',0);prop(p,'token','BottomSurface',0)
  if 'alpha' in a:prop(p,'float','Transparency',a['alpha'])
  if 'text' in a:
   gui=item(p,'SurfaceGui','Sign');prop(gui,'token','Face',5);prop(gui,'Vector2','CanvasSize',dict(X=1000,Y=150))
   label=item(gui,'TextLabel','TextLabel');prop(label,'UDim2','Size',dict(XS=1,XO=0,YS=1,YO=0));prop(label,'float','BackgroundTransparency',1);prop(label,'string','Text',a['text']);prop(label,'bool','TextScaled',True);prop(label,'token','Font',19);prop(label,'Color3','TextColor3',dict(R=236/255,G=230/255,B=207/255))
lighting=next((i for i in root.findall('Item') if i.get('class')=='Lighting'),None)
if lighting is not None:
 prop(lighting,'float','ClockTime',14);prop(lighting,'float','Brightness',2)
 prop(lighting,'Color3','Ambient',dict(R=110/255,G=116/255,B=125/255));prop(lighting,'Color3','OutdoorAmbient',dict(R=135/255,G=140/255,B=148/255))
assert before==script_hash(),'Scripts must remain identical'
out=E.Element('roblox',{'version':'4'});out.append(model)
E.ElementTree(out).write(ROOT/'assets/academy/AcademyCampus.rbxmx',encoding='utf-8',xml_declaration=True)
tmp=path.with_suffix('.academy.tmp');tree.write(tmp,encoding='utf-8',xml_declaration=True);E.parse(tmp);tmp.replace(path)
print('Saved complete place. Buildings:',sum('floors' in g for g in G),'Scenery parts:',sum(len(g['parts']) for g in G),'Archived originals:',archived,'Script hash unchanged:',before)
