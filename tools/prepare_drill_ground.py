"""Prepare the supplied Meshy FBX with UVs for Studio; run using Blender -b --python."""
from pathlib import Path
import bpy,json,argparse,tempfile,zipfile
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--archive',type=Path,required=True)
parser.add_argument('--triangles',type=int,default=240000)
args=parser.parse_args(__import__('sys').argv[__import__('sys').argv.index('--')+1:])
folder=ROOT/'assets/drill-ground';folder.mkdir(parents=True,exist_ok=True)
temporary=tempfile.TemporaryDirectory(prefix='drill-source-')
sourceFolder=Path(temporary.name)
with zipfile.ZipFile(args.archive) as archive:
 for entry in archive.infolist():
  if Path(entry.filename).suffix.lower() in {'.fbx','.png'}:
   (sourceFolder/Path(entry.filename).name).write_bytes(archive.read(entry))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(next(sourceFolder.glob('Meshy*.fbx'))))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=mesh
mesh.data.transform(mesh.matrix_world);mesh.matrix_world.identity()
coords=[v.co.copy() for v in mesh.data.vertices]
lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
scale=200/(hi.y-lo.y)
for v in mesh.data.vertices:
 v.co.x=(v.co.x-(hi.x+lo.x)/2)*scale
 v.co.y=(v.co.y-(hi.y+lo.y)/2)*scale
 v.co.z=(v.co.z-lo.z)*scale
original=len(mesh.data.polygons)
modifier=mesh.modifiers.new('StudioBudget','DECIMATE');modifier.ratio=min(1,args.triangles/original)
bpy.ops.object.modifier_apply(modifier=modifier.name)
modifier=mesh.modifiers.new('Triangulate','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=modifier.name)
assert mesh.data.uv_layers
mesh.name='ExamDrillGroundVisual'
# Explicit PBR paths replace embedded paths from the source archive.
mat=bpy.data.materials.new('DrillGroundPBR');mat.use_nodes=True
nodes=mat.node_tree.nodes;shader=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
for suffix,socket in [('', 'Base Color'),('_roughness','Roughness'),('_metallic','Metallic'),('_normal','Normal')]:
 image=bpy.data.images.load(str(next(sourceFolder.glob('Meshy*texture'+suffix+'.png'))))
 image.scale(image.size[0],image.size[1])
 image.filepath_raw=str(folder/('DrillGround'+suffix+'.png'));image.file_format='PNG';image.save()
 tex=nodes.new('ShaderNodeTexImage');tex.image=image
 if suffix: image.colorspace_settings.name='Non-Color'
 if suffix=='_normal':
  normal=nodes.new('ShaderNodeNormalMap');mat.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color']);mat.node_tree.links.new(normal.outputs['Normal'],shader.inputs[socket])
 else: mat.node_tree.links.new(tex.outputs['Color'],shader.inputs[socket])
mesh.data.materials.clear();mesh.data.materials.append(mat)
# Split the reduced surface spatially instead of crushing the whole scene into one mesh.
# Vertex positions, UVs and split normals remain identical at chunk boundaries.
import statistics
source=mesh.data
centers=[poly.center.copy() for poly in source.polygons]
groups=[]
def divide(indices):
 if len(indices)<=18000:
  groups.append(indices);return
 spans=[max(centers[i][axis] for i in indices)-min(centers[i][axis] for i in indices) for axis in range(3)]
 axis=max(range(3),key=lambda a:spans[a])
 ordered=sorted(indices,key=lambda i:centers[i][axis]);middle=len(ordered)//2
 divide(ordered[:middle]);divide(ordered[middle:])
divide(list(range(len(source.polygons))))
sourceUV=source.uv_layers.active.data
sourceNormals=[n.vector.copy() for n in source.corner_normals]
parts=[]
for index,indices in enumerate(groups):
 remap={};vertices=[];faces=[];uvs=[];normals=[]
 for faceIndex in indices:
  poly=source.polygons[faceIndex];face=[]
  for loopIndex in poly.loop_indices:
   vi=source.loops[loopIndex].vertex_index
   if vi not in remap: remap[vi]=len(vertices);vertices.append(source.vertices[vi].co.copy())
   face.append(remap[vi]);uvs.append(tuple(sourceUV[loopIndex].uv));normals.append(tuple(sourceNormals[loopIndex]))
  faces.append(face)
 data=bpy.data.meshes.new(f'DrillSurface{index+1:02}')
 data.from_pydata(vertices,[],faces);data.update()
 uv=data.uv_layers.new(name='UVMap')
 for loop,value in zip(uv.data,uvs):loop.uv=value
 for poly in data.polygons:poly.use_smooth=True
 data.normals_split_custom_set(normals)
 obj=bpy.data.objects.new(f'DrillSurface{index+1:02}',data);bpy.context.collection.objects.link(obj)
 data.materials.append(mat);parts.append(obj)
mesh.hide_render=True;mesh.hide_set(True)
bpy.ops.object.select_all(action='DESELECT')
for part in parts:part.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.export_scene.fbx(filepath=str(folder/'ExamDrillGroundHQ.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,bake_anim=False)
(folder/'geometry-report.json').write_text(json.dumps({'sourceTriangles':original,'triangles':len(source.polygons),'parts':len(parts),'maxPartTriangles':max(len(p.data.polygons) for p in parts),'size':list(mesh.dimensions),'uvLayers':len(source.uv_layers),'colorTextureSize':4096,'normalMap':True},indent=2))
bpy.ops.object.camera_add(location=(130,-170,190));camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,10))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=280
scene=bpy.context.scene;scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.samples=12
scene.world=bpy.data.worlds.new("DrillWorld");scene.world.color=(.65,.65,.65)
bpy.ops.object.light_add(type='AREA',location=(0,-50,200));bpy.context.object.data.energy=200000;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=180
scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.render.filepath=str(folder/'preview.png');bpy.ops.render.render(write_still=True)

temporary.cleanup()
