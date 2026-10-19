"""Update embedded source in an existing XML place, preserving map and non-source properties."""
from pathlib import Path
import argparse
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def sync(source: Path, output: Path):
    tree = ET.parse(source)
    root = tree.getroot()
    used = {item.get('referent') for item in root.iter('Item')}
    counter = 0
    def find_or_add(parent, cls, name):
        nonlocal counter
        matches = [i for i in parent.findall('Item') if i.findtext("Properties/string[@name='Name']") == name]
        if matches:
            assert len(matches) == 1 and matches[0].get('class') == cls, f'Instance conflict: {name}'
            return matches[0]
        while True:
            counter += 1
            ref = f'MessengerSync{counter}'
            if ref not in used:
                used.add(ref)
                break
        item = ET.SubElement(parent, 'Item', {'class': cls, 'referent': ref})
        props = ET.SubElement(item, 'Properties')
        ET.SubElement(props, 'string', {'name': 'Name'}).text = name
        return item
    server = find_or_add(root, 'ServerScriptService', 'ServerScriptService')
    rep = find_or_add(root, 'ReplicatedStorage', 'ReplicatedStorage')
    shared = find_or_add(rep, 'Folder', 'Shared')
    starter = find_or_add(root, 'StarterPlayer', 'StarterPlayer')
    client = find_or_add(starter, 'StarterPlayerScripts', 'StarterPlayerScripts')
    count = 0
    for folder, container in [('server', server), ('shared', shared), ('client', client)]:
        for path in sorted((ROOT / 'src' / folder).glob('*.luau')):
            if path.name.endswith('.server.luau'):
                cls, name = 'Script', path.name.removesuffix('.server.luau')
            elif path.name.endswith('.client.luau'):
                cls, name = 'LocalScript', path.name.removesuffix('.client.luau')
            else:
                cls, name = 'ModuleScript', path.stem
            item = find_or_add(container, cls, name)
            props = item.find('Properties')
            node = props.find("ProtectedString[@name='Source']")
            if node is None:
                node = ET.SubElement(props, 'ProtectedString', {'name': 'Source'})
            node.text = path.read_text()
            if cls != 'ModuleScript':
                disabled = props.find("bool[@name='Disabled']")
                if disabled is None:
                    disabled = ET.SubElement(props, 'bool', {'name': 'Disabled'})
                disabled.text = 'false'
            count += 1
    tree.write(output, encoding='utf-8', xml_declaration=True)
    ET.parse(output)
    print(f'Synced {count} sources; map and other instances preserved: {output.name}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=ROOT / 'MilitaryRP.rbxlx')
    parser.add_argument('--output', type=Path, default=ROOT / 'MilitaryRP.rbxlx')
    args = parser.parse_args()
    sync(args.input, args.output)
