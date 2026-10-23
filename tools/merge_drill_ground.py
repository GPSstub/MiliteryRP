"""Merge only the prepared drill ground from a Studio XML snapshot into the complete map."""
from pathlib import Path
import argparse,copy,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('snapshot',type=Path)
parser.add_argument('--replace',action='store_true',help='Replace only the existing drill ground')
args=parser.parse_args()
source=ET.parse(args.snapshot).getroot();tree=ET.parse(ROOT/'MilitaryRP.rbxlx');target=tree.getroot()
def workspace(root):
 return next(i for i in root.findall('Item') if i.get('class')=='Workspace')
grounds=[i for i in workspace(source).findall('Item') if i.findtext("Properties/string[@name='Name']")=='ExamDrillGround']
assert len(grounds)==1,'Expected one imported training ground'
previous=[i for i in workspace(target).findall('Item') if i.findtext("Properties/string[@name='Name']")=='ExamDrillGround']
assert not previous or (args.replace and len(previous)==1),'Ground already exists; use --replace explicitly'
for item in previous: workspace(target).remove(item)
ground=copy.deepcopy(grounds[0]);used={i.get('referent') for i in target.iter('Item')};refs={}
for n,item in enumerate(ground.iter('Item')):
 old=item.get('referent');new=f'ExamGround{n}'
 assert new not in used
 refs[old]=new;item.set('referent',new)
for node in ground.iter('Ref'):
 if node.text in refs: node.text=refs[node.text]
 elif node.text!='null': node.text='null'
shared=target.find('SharedStrings')
if shared is None: shared=ET.SubElement(target,'SharedStrings')
existing={n.get('md5') for n in shared}
needed={n.text for n in ground.iter('SharedString')}
for node in source.findall('SharedStrings/SharedString'):
 if node.get('md5') in needed and node.get('md5') not in existing:
  shared.append(copy.deepcopy(node));existing.add(node.get('md5'))
assert needed<=existing,'Missing mesh shared strings'
workspace(target).append(ground)
tree.write(ROOT/'MilitaryRP.rbxlx',encoding='utf-8',xml_declaration=True)
ET.parse(ROOT/'MilitaryRP.rbxlx')
print('Merged drill ground; all original map instances preserved.')
