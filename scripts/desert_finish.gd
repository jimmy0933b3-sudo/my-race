extends Node3D
## Art-directed sandstone desert. Dense but batched rocks, cacti and grasses,
## sculpted mesas, no luminous white stones or billboard-only dressing.
const MAT = preload("res://scripts/material_studio.gd")
var circuit:Node3D
var foliage_groups:Array[MultiMeshInstance3D]=[]
var rock_groups:Array[MultiMeshInstance3D]=[]
var rocks_count:=0
var grass_count:=0
var cactus_count:=0
var mesa_count:=0
var quality_level:=3
var rng:=RandomNumberGenerator.new()

func build(track:Node3D)->void:
 circuit=track
 name="CinematicSandstoneAndFlora"
 rng.seed=2608391
 _rock_fields()
 _dry_grass()
 _cactus_grove()
 _background_mesas()
 set_quality(quality_level)

func _rock_mesh(seed:int)->ArrayMesh:
 # Hand-built irregular boulders, actual asymmetric outline & triangulated
 # facets instead of the original smooth white spheres.
 var tool=SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var ring_count=10
 var around=22
 var matrix:Array[Vector3]=[]
 for ring_idx in range(ring_count+1):
  var v=float(ring_idx)/float(ring_count)
  var latitude=-PI*0.5+PI*v
  for step in range(around):
   var angle=TAU*float(step)/float(around)
   var wobble=0.87+0.16*sin(float(seed)*0.45+angle*5.0+v*7.0)+0.09*cos(angle*9.0-v*13.0)
   var radius=maxf(0.02,cos(latitude))*wobble
   matrix.append(Vector3(cos(angle)*radius,sin(latitude)*0.66*wobble,sin(angle)*radius))
 for ring_idx in range(ring_count):
  for step in range(around):
   var a=ring_idx*around+step
   var b=ring_idx*around+(step+1)%around
   var c=(ring_idx+1)*around+step
   var d=(ring_idx+1)*around+(step+1)%around
   for p in [matrix[a],matrix[c],matrix[b],matrix[b],matrix[c],matrix[d]]:
    tool.add_vertex(p)
 tool.generate_normals()
 return tool.commit()

func _rock_material(tint:Color)->ShaderMaterial:
 var sh=Shader.new()
 sh.code="""shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 stone_tint : source_color;
varying vec3 world_p;
float hash21(vec2 p){return fract(sin(dot(p,vec2(59.23,102.7)))*48193.7);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
return mix(mix(hash21(i),hash21(i+vec2(1.,0.)),f.x),mix(hash21(i+vec2(0.,1.)),hash21(i+vec2(1.,1.)),f.x),f.y);}
void vertex(){world_p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float mineral=noise(world_p.xz*3.8+world_p.y*0.55);
 float grain=noise(world_p.xz*16.0);
 float strata=0.5+0.5*sin(world_p.y*8.0+mineral*2.0);
 float shadowing=0.70+mineral*0.32;
 ALBEDO=stone_tint.rgb*shadowing*(0.80+strata*0.24)+(grain-0.5)*0.032;
 ROUGHNESS=0.96;
 SPECULAR=0.11;
}
"""
 var mat=ShaderMaterial.new()
 mat.shader=sh
 mat.set_shader_parameter("stone_tint",tint)
 return mat

func _multi(mesh:Mesh,material:Material,n:int,tag:String)->MultiMeshInstance3D:
 var mm=MultiMesh.new()
 mm.transform_format=MultiMesh.TRANSFORM_3D
 mm.mesh=mesh
 mm.instance_count=n
 var layer=MultiMeshInstance3D.new()
 layer.name=tag
 layer.multimesh=mm
 layer.material_override=material
 layer.custom_aabb=AABB(Vector3(-160,-6,-160),Vector3(320,65,320))
 add_child(layer)
 return layer

func _rock_fields()->void:
 var tones=[Color("#806a5a"),Color("#a77f65"),Color("#6a7071"),Color("#b38968")]
 for batch in range(4):
  var n=110
  var group=_multi(_rock_mesh(19+batch*13),_rock_material(tones[batch]),n,"SedimentaryRockCluster%d"%batch)
  for i in range(n):
   var progress=rng.randf_range(0,float(circuit.SEGMENTS))
   var side=1.0 if rng.randf()<0.5 else -1.0
   var distance=rng.randf_range(17.5,57.0)
   var p:Vector3=circuit.sample(progress,side*distance)
   var scale3=Vector3(rng.randf_range(0.48,2.0),rng.randf_range(0.5,1.6),rng.randf_range(0.65,2.0))
   var orientation=Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(scale3)
   group.multimesh.set_instance_transform(i,Transform3D(orientation,Vector3(p.x,0.36*scale3.y,p.z)))
  rock_groups.append(group)
  rocks_count+=n

func _grass_mesh()->ArrayMesh:
 var t=SurfaceTool.new()
 t.begin(Mesh.PRIMITIVE_TRIANGLES)
 for stem in range(5):
  var angle=TAU*float(stem)/5.0
  var dx=cos(angle)
  var dz=sin(angle)
  var a=Vector3(dx*0.30,0,dz*0.30)
  var b=Vector3(dx*0.65,0,dz*0.65)
  var peak=Vector3(dx*0.35,0.64+float(stem%3)*0.07,dz*0.35)
  for point in [a,peak,b,b,peak,a]:
   t.add_vertex(point)
 t.generate_normals()
 return t.commit()

func _dry_grass()->void:
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color("#66795b")
 mat.roughness=0.91
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 var m=_grass_mesh()
 for batch in range(3):
  var n=310
  var g=_multi(m,mat,n,"DuneGrassTufts%d"%batch)
  for i in range(n):
   var progress=rng.randf_range(0,float(circuit.SEGMENTS))
   var sign=1.0 if rng.randf()>0.5 else -1.0
   var p:Vector3=circuit.sample(progress,sign*rng.randf_range(14.2,65.0))
   var scale3=Vector3(rng.randf_range(0.8,2.8),rng.randf_range(0.4,1.6),rng.randf_range(0.8,2.8))
   g.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(scale3),Vector3(p.x,0.05,p.z)))
  foliage_groups.append(g)
  grass_count+=n

func _cactus_grove()->void:
 # Three instanced pieces per cactus: a ribbed trunk and two tapering arms.
 var trunk=CylinderMesh.new()
 trunk.top_radius=0.23
 trunk.bottom_radius=0.33
 trunk.height=3.4
 trunk.radial_segments=12
 var arm=CylinderMesh.new()
 arm.top_radius=0.14
 arm.bottom_radius=0.23
 arm.height=1.65
 arm.radial_segments=10
 var green=StandardMaterial3D.new()
 green.albedo_color=Color("#567d63")
 green.roughness=0.87
 var n=78
 var stems=_multi(trunk,green,n,"DesertCactiTrunks")
 var left=_multi(arm,green,n,"DesertCactiLeftArms")
 var right=_multi(arm,green,n,"DesertCactiRightArms")
 for i in range(n):
  var p:Vector3=circuit.sample(rng.randf_range(0,float(circuit.SEGMENTS)),(1.0 if i%2==0 else -1.0)*rng.randf_range(18.5,55.0))
  var s=rng.randf_range(0.60,1.65)
  stems.multimesh.set_instance_transform(i,Transform3D(Basis().scaled(Vector3(s,s,s)),Vector3(p.x,1.70*s,p.z)))
  var l=Basis(Vector3.FORWARD,0.55).scaled(Vector3(s,s*0.76,s))
  var r=Basis(Vector3.FORWARD,-0.55).scaled(Vector3(s,s*0.69,s))
  left.multimesh.set_instance_transform(i,Transform3D(l,Vector3(p.x-0.56*s,2.0*s,p.z)))
  right.multimesh.set_instance_transform(i,Transform3D(r,Vector3(p.x+0.56*s,2.2*s,p.z)))
 cactus_count+=n
 foliage_groups.append(stems)
 foliage_groups.append(left)
 foliage_groups.append(right)

func _background_mesas()->void:
 # Massive but subdued layered erosion silhouettes on the distant horizon.
 # Each solid has a rocky beveled lip and a flat cap instead of a sphere.
 for i in range(16):
  var a=TAU*float(i)/16.0+0.12
  var dist=rng.randf_range(116.0,170.0)
  var p=Vector3(cos(a)*dist,0,sin(a)*dist)
  var height=rng.randf_range(13.0,33.0)
  var radius=rng.randf_range(6.5,14.0)
  for layer in range(4):
   var bottom=radius*(1.0-float(layer)*0.075)
   var top=bottom*(0.76+0.05*cos(float(i*7+layer)))
   var h=height/4.0
   var mesh=CylinderMesh.new()
   mesh.bottom_radius=bottom
   mesh.top_radius=top
   mesh.height=h
   mesh.radial_segments=11
   var layer_node=MeshInstance3D.new()
   layer_node.mesh=mesh
   layer_node.position=p+Vector3(0,(float(layer)+0.5)*h-0.3,0)
   layer_node.material_override=_rock_material([Color("#ad795d"),Color("#9e6f59"),Color("#b48460"),Color("#bb916e")][layer])
   layer_node.scale=Vector3(1.0,1.0,rng.randf_range(0.70,1.2))
   add_child(layer_node)
  mesa_count+=1

func set_quality(value:int)->void:
 quality_level=clampi(value,0,3)
 var share=[0.20,0.46,0.78,1.0][quality_level]
 for g in rock_groups:
  g.multimesh.visible_instance_count=roundi(g.multimesh.instance_count*share)
 for g in foliage_groups:
  g.multimesh.visible_instance_count=roundi(g.multimesh.instance_count*share)
