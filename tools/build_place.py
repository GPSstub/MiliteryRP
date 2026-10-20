"""Generate a standalone Roblox XML place from the same sources Rojo uses."""
from pathlib import Path
import xml.etree.ElementTree as ET
import argparse
import json
ROOT = Path(__file__).resolve().parents[1]

def build(output=None, overwrite=False):
    target = Path(output) if output is not None else ROOT/'MilitaryRP.test.rbxlx'
    # Full place contains the real 18-building map. This test-place generator
    # MUST NEVER overwrite it, even with --overwrite.
    if target.resolve() == (ROOT/'MilitaryRP.rbxlx').resolve():
        raise ValueError('Refusing to replace the complete MilitaryRP.rbxlx map; use tools/sync_place.py')
    if target.exists() and not overwrite:
        raise FileExistsError(f'Output already exists: {target}; pass --overwrite for TEST files only')
    target.parent.mkdir(parents=True, exist_ok=True)
    root = ET.Element('roblox', {'version': '4'})
    ET.SubElement(root, 'External').text = 'null'
    ET.SubElement(root, 'External').text = 'nil'
    counter = 0
    def item(parent, cls, name):
        nonlocal counter
        counter += 1
        node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'RBX{counter}'})
        props = ET.SubElement(node, 'Properties')
        ET.SubElement(props, 'string', {'name': 'Name'}).text = name
        return node
    def source(parent, cls, name, path):
        node = item(parent, cls, name)
        ET.SubElement(node.find('Properties'), 'ProtectedString', {'name':'Source'}).text = path.read_text()
    world=item(root, 'Workspace', 'Workspace')
    floor=item(world, 'Part', 'TestFloor')
    props=floor.find('Properties')
    ET.SubElement(props,'bool',{'name':'Anchored'}).text='true'
    vector=ET.SubElement(props,'Vector3',{'name':'size'})
    for axis,value in zip(('X','Y','Z'),(120,1,120)): ET.SubElement(vector,axis).text=str(value)
    frame=ET.SubElement(props,'CoordinateFrame',{'name':'CFrame'})
    for key,value in {'X':0,'Y':-0.5,'Z':0,'R00':1,'R01':0,'R02':0,'R10':0,'R11':1,'R12':0,'R20':0,'R21':0,'R22':1}.items(): ET.SubElement(frame,key).text=str(value)
    spawn=item(world,'SpawnLocation','RankSpawn')
    props=spawn.find('Properties')
    ET.SubElement(props,'bool',{'name':'Anchored'}).text='true'
    ET.SubElement(props,'bool',{'name':'Neutral'}).text='true'
    ET.SubElement(props,'float',{'name':'Duration'}).text='0'
    vector=ET.SubElement(props,'Vector3',{'name':'size'})
    for axis,value in zip(('X','Y','Z'),(8,1,8)): ET.SubElement(vector,axis).text=str(value)
    frame=ET.SubElement(props,'CoordinateFrame',{'name':'CFrame'})
    for key,value in {'X':0,'Y':0.5,'Z':0,'R00':1,'R01':0,'R02':0,'R10':0,'R11':1,'R12':0,'R20':0,'R21':0,'R22':1}.items(): ET.SubElement(frame,key).text=str(value)
    chat=item(root, 'TextChatService', 'TextChatService')
    props=chat.find('Properties')
    ET.SubElement(props,'token',{'name':'ChatVersion'}).text='1'
    ET.SubElement(props,'bool',{'name':'CreateDefaultTextChannels'}).text='true'
    ET.SubElement(props,'bool',{'name':'CreateDefaultCommands'}).text='true' 
    rep = item(root, 'ReplicatedStorage', 'ReplicatedStorage')
    shared = item(rep, 'Folder', 'Shared')
    server = item(root, 'ServerScriptService', 'ServerScriptService')
    starter = item(root, 'StarterPlayer', 'StarterPlayer')
    client = item(starter, 'StarterPlayerScripts', 'StarterPlayerScripts')
    for folder, parent in [('shared', shared), ('server', server), ('client', client)]:
        for path in sorted((ROOT/'src'/folder).glob('*.luau')):
            if path.name.endswith('.server.luau'):
                cls, name = 'Script', path.name.removesuffix('.server.luau')
            elif path.name.endswith('.client.luau'):
                cls, name = 'LocalScript', path.name.removesuffix('.client.luau')
            else:
                cls, name = 'ModuleScript', path.stem
            source(parent, cls, name, path)
    ET.indent(root)
    ET.ElementTree(root).write(target, encoding='utf-8', xml_declaration=True)
    parsed = ET.parse(target)
    scripts = parsed.findall('.//ProtectedString')
    assert len(scripts) == len(list((ROOT/'src').rglob('*.luau')))
    for node in scripts:
        assert node.text and node.text.startswith('--!strict')
    print(f'Built {target.name}: {len(scripts)} embedded scripts; XML parsed successfully.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build a minimal TEST place, never the completed map')
    parser.add_argument('--output', type=Path, default=ROOT/'MilitaryRP.test.rbxlx')
    parser.add_argument('--overwrite', action='store_true', help='Allow replacing an existing TEST output')
    args = parser.parse_args()
    build(args.output, args.overwrite)
