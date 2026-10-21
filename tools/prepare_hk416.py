"""Run with Blender --background --python tools/prepare_hk416.py -- --body-zip ... --magazine-zip ...

Preserves source UVs/PBR materials. Axis conversion reflects the mesh, so reverse
face winding after reduction; otherwise Roblox backface culling exposes interiors.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import zipfile

import bpy
import bmesh

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--body-zip', type=Path, required=True)
parser.add_argument('--magazine-zip', type=Path, required=True)
parser.add_argument('--output', type=Path, default=Path('assets/hk416'))
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
args.output.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
report = []
with tempfile.TemporaryDirectory(prefix='hk416-') as temporary:
    for kind, archive in [('Body', args.body_zip), ('Magazine', args.magazine_zip)]:
        directory = Path(temporary) / kind
        directory.mkdir()
        with zipfile.ZipFile(archive) as source:
            for entry in source.infolist():
                if Path(entry.filename).suffix.lower() in {'.fbx', '.png'}:
                    (directory / Path(entry.filename).name).write_bytes(source.read(entry))
        fbx, = directory.glob('*.fbx')
        bpy.ops.import_scene.fbx(filepath=str(fbx))
        meshes = [o for o in bpy.context.selected_objects if o.type == 'MESH']
        if len(meshes) != 1:
            raise ValueError(f'{kind}: expected one mesh, found {len(meshes)}')
        mesh = meshes[0]
        mesh.data.transform(mesh.matrix_world)
        mesh.matrix_world.identity()
        for vertex in mesh.data.vertices:
            x, y, z = vertex.co
            vertex.co = (-y * 3, -(x - .40) * 3, (z + .18) * 3) if kind == 'Body' else (-y * .75, -x * .75, z * .75)
        mesh.name = f'HK416_{kind}_PBR'
        bpy.context.view_layer.objects.active = mesh
        reduction = mesh.modifiers.new('RobloxReduction', 'DECIMATE')
        reduction.ratio = min(1, 8000 / len(mesh.data.polygons))
        bpy.ops.object.modifier_apply(modifier=reduction.name)
        triangles = mesh.modifiers.new('Triangles', 'TRIANGULATE')
        bpy.ops.object.modifier_apply(modifier=triangles.name)
        editable = bmesh.new()
        editable.from_mesh(mesh.data)
        bmesh.ops.reverse_faces(editable, faces=list(editable.faces))
        volume = editable.calc_volume(signed=True)
        assert volume > 0, f'{kind}: inward-facing surface'
        editable.to_mesh(mesh.data)
        editable.free()
        assert mesh.data.uv_layers, f'{kind}: missing original UVs'
        assert len(mesh.data.polygons) <= 20000, f'{kind}: mesh exceeds triangle budget'
        bpy.ops.object.select_all(action='DESELECT')
        mesh.select_set(True)
        bpy.ops.export_scene.fbx(filepath=str((args.output / f'{mesh.name}.fbx').resolve()),
            use_selection=True, object_types={'MESH'}, axis_forward='-Z', axis_up='Y',
            path_mode='COPY', embed_textures=True, add_leaf_bones=False, bake_anim=False)
        report.append({'part': kind, 'source': archive.name,
            'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
            'triangles': len(mesh.data.polygons), 'signedVolume': volume,
            'originalUVLayers': len(mesh.data.uv_layers)})
(args.output / 'geometry-report.json').write_text(json.dumps(report, indent=2) + '\n')
