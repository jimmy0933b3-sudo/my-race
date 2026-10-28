extends Node3D
## Third-generation authored racecourse art: detailed circuit furniture, iconic
## 3D landmarks, painted apex strips, directional signage, themed vegetation.
## Uses batched MultiMeshes so visual density does not mean thousands of draws.
var circuit: Node3D
var biome := 0
var landmark_count := 0
var strip_count := 0
var scene_instances := 0
var batched: Array[MultiMeshInstance3D] = []
var quality_level := 3
var rng := RandomNumberGenerator.new()
var colors: Array[Color] = []

func build(track: Node3D) -> void:
 circuit=track
 biome=clampi(track.map_index,0,3)
 rng.seed=683190 + biome*9007
 name="WorldArtDirectionV3"
 _palette()
 _curb_and_asphalt_details()
 _curve_signs()
 _festival_signage()
 _big_signature_landmarks()
 _landscape_instancing()
 set_quality(quality_level)
 print("V3 COURSE %d: %d iconic structures, %d curb sections, %d batched scenery" % [biome,landmark_count,strip_count,scene_instances])

func _palette() -> void:
 match biome:
  0: colors=[Color("#e5a8ba"),Color("#ffd6b3"),Color("#709f9c"),Color("#38516a"),Color("#f2e7d4")]
  1: colors=[Color("#74cba4"),Color("#dbf5c5"),Color("#578f81"),Color("#506c86"),Color("#f5e6bb")]
  2: colors=[Color("#d49a73"),Color("#ffe0b4"),Color("#b77d69"),Color("#62617a"),Color("#f5ddb8")]
  _: colors=[Color("#9b91e7"),Color("#78d5eb"),Color("#4d67a1"),Color("#2e396c"),Color("#e9c8ff")]

func _mat(tint: Color, metallic := 0.0, luminous := false) -> StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=tint
 m.metallic=metallic
 m.roughness=0.38 if metallic>0.0 else 0.72
 if metallic>0.0:
  m.clearcoat_enabled=true
  m.clearcoat=0.58
 if luminous:
  m.emission_enabled=true
  m.emission=tint
  m.emission_energy_multiplier=0.85 if biome==0 else 1.25
 return m

func _shape(mesh:Mesh,pos:Vector3,tint:Color,metallic:=0.0,luminous:=false,parent:Node3D=null)->MeshInstance3D:
 var view=MeshInstance3D.new()
 view.mesh=mesh
 view.position=pos
 view.material_override=_mat(tint,metallic,luminous)
 (parent if parent!=null else self).add_child(view)
 landmark_count+=1
 return view

func _box(pos:Vector3,dimensions:Vector3,tint:Color,metallic:=0.0,luminous:=false,parent:Node3D=null)->MeshInstance3D:
 var mesh=BoxMesh.new()
 mesh.size=dimensions
 return _shape(mesh,pos,tint,metallic,luminous,parent)

func _orb(pos:Vector3,radii:Vector3,tint:Color,luminous:=false,parent:Node3D=null)->MeshInstance3D:
 var m=SphereMesh.new()
 m.radius=1.0
 m.height=2.0
 m.radial_segments=20
 m.rings=10
 var n=_shape(m,pos,tint,0.0,luminous,parent)
 n.scale=radii
 return n

func _cone(pos:Vector3,bottom:float,top:float,height:float,tint:Color,parent:Node3D=null)->MeshInstance3D:
 var m=CylinderMesh.new()
 m.bottom_radius=bottom
 m.top_radius=top
 m.height=height
 m.radial_segments=20
 return _shape(m,pos,tint,0.08,false,parent)

func _beam(a:Vector3,b:Vector3,width:float,color:Color,luminous:=false,parent:Node3D=null)->void:
 var delta=b-a
 if delta.length_squared()<0.00001:
  return
 var m=CylinderMesh.new()
 m.top_radius=width
 m.bottom_radius=width
 m.height=delta.length()
 m.radial_segments=10
 var n=_shape(m,(a+b)*0.5,color,0.47,luminous,parent)
 n.quaternion=Quaternion(Vector3.UP,delta.normalized())

func _ring(pos:Vector3,r:float,thickness:float,color:Color,luminous:=false)->MeshInstance3D:
 var m=TorusMesh.new()
 m.inner_radius=r-thickness*0.5
 m.outer_radius=r+thickness*0.5
 m.ring_segments=50
 m.rings=14
 return _shape(m,pos,color,0.36,luminous)

func _letters(text_value:String,pos:Vector3,size:int,color:Color)->void:
 var label=Label3D.new()
 label.text=text_value
 label.position=pos
 label.font_size=size
 label.pixel_size=0.010
 label.outline_size=9
 label.modulate=color
 label.outline_modulate=Color("#243047")
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 add_child(label)
 landmark_count+=1

func _multi(mesh:Mesh,material:Material,points:Array[Transform3D],tints:Array[Color],tag:String)->void:
 var mm=MultiMesh.new()
 mm.transform_format=MultiMesh.TRANSFORM_3D
 mm.use_colors=true
 mm.mesh=mesh
 mm.instance_count=points.size()
 for i in range(points.size()):
  mm.set_instance_transform(i,points[i])
  mm.set_instance_color(i,tints[i])
 var n=MultiMeshInstance3D.new()
 n.name=tag
 n.multimesh=mm
 n.material_override=material
 n.custom_aabb=AABB(Vector3(-180,-5,-180),Vector3(360,70,360))
 add_child(n)
 batched.append(n)
 scene_instances+=mm.instance_count

func _curb_and_asphalt_details()->void:
 # Red-and-cream alternating raised apex paint, geometry follows the road
 # tangent. These strips improve visibility at speed on the bright festival.
 var base=BoxMesh.new()
 base.size=Vector3(0.74,0.052,1.8)
 var mat=_mat(Color.WHITE,0.08)
 mat.vertex_color_use_as_albedo=true
 var strips:Array[Transform3D]=[]
 var shades:Array[Color]=[]
 for i in range(circuit.SEGMENTS):
  for side in [-1.0,1.0]:
   var pos:Vector3=circuit.at(i,side*7.53)
   var heading:Vector3=circuit.direction(float(i))
   var theta=atan2(-heading.x,-heading.z)
   var normal=Vector3.UP
   var basis=Basis(normal,theta)
   strips.append(Transform3D(basis,Vector3(pos.x,0.171,pos.z)))
   shades.append(colors[0] if i%2==0 else colors[4])
   strip_count+=1
 _multi(base,mat,strips,shades,"PaintedRumbleStrip180x2")
 # Micro-height shoulder studs: 4 rows, batched for depth on turns.
 var reflect=SphereMesh.new()
 reflect.radius=0.095
 reflect.height=0.19
 reflect.radial_segments=9
 reflect.rings=4
 var coords:Array[Transform3D]=[]
 var tones:Array[Color]=[]
 for i in range(0,circuit.SEGMENTS,2):
  for side in [-1.0,1.0]:
   var p:Vector3=circuit.at(i,side*7.10)
   coords.append(Transform3D(Basis(),Vector3(p.x,0.187,p.z)))
   tones.append(colors[1])
 _multi(reflect,mat,coords,tones,"ReflectorDots")
 # Painted pit-lane start: repeated colored tiles instead of a floating slab.
 var tile_mesh=BoxMesh.new()
 tile_mesh.size=Vector3(0.7,0.025,0.54)
 var tile_pos:Array[Transform3D]=[]
 var tile_col:Array[Color]=[]
 for step in range(3):
  for lane in range(17):
   var x=-7.4+float(lane)*0.925
   var p:Vector3=circuit.sample(float(step)*0.34,x)
   tile_pos.append(Transform3D(Basis(Vector3.UP,atan2(-circuit.direction(0.0).x,-circuit.direction(0.0).z)),Vector3(p.x,0.184,p.z)))
   tile_col.append(Color("#ecf7f4") if (lane+step)%2==0 else colors[3])
 _multi(tile_mesh,mat,tile_pos,tile_col,"StartLineChecker")

func _curve_signs()->void:
 # Steering cues and track safety signage on outside of sharp bends.
 for i in range(4,circuit.SEGMENTS,8):
  var previous:Vector3=circuit.direction(float(i-4))
  var following:Vector3=circuit.direction(float(i+4))
  var cross=previous.x*following.z-previous.z*following.x
  if absf(cross)<0.05:
   continue
  var side=1.0 if cross>0.0 else -1.0
  var p:Vector3=circuit.at(i,side*12.0)
  var sign=_box(Vector3(p.x,2.55,p.z),Vector3(3.8,1.48,0.20),colors[3],0.38)
  sign.rotation.y=atan2(-following.x,-following.z)
  _letters("❮ ❮ ❮" if cross>0.0 else "❯ ❯ ❯",Vector3(p.x,2.50,p.z),88,colors[1])
  for pole in [-1.5,1.5]:
   _beam(Vector3(p.x+pole,0,p.z),Vector3(p.x+pole,2.5,p.z),0.085,colors[2])
 # Sidewalk bollards with colored lenses at fixed positions.
 for i in range(0,circuit.SEGMENTS,9):
  for side in [-1.0,1.0]:
   var p:Vector3=circuit.at(i,side*11.0)
   _cone(Vector3(p.x,0.91,p.z),0.32,0.19,1.75,colors[3])
   _orb(Vector3(p.x,1.96,p.z),Vector3(0.28,0.11,0.28),colors[1])

func _festival_signage()->void:
 for i in range(4):
  var idx=(i*43+13)%circuit.SEGMENTS
  var outside:Vector3=circuit.at(idx,18.0)
  var heading:Vector3=circuit.direction(float(idx))
  var facing=atan2(-heading.x,-heading.z)
  var base=_box(Vector3(outside.x,2.0,outside.z),Vector3(8.2,3.5,0.7),colors[3],0.35)
  base.rotation.y=facing
  _letters(["SWEET START!","GREAT DRIVING!","KEEP GOING!","YOU CAN DO IT!"][i],Vector3(outside.x,2.12,outside.z),58,colors[4])
  for side in [-1.0,1.0]:
   _orb(Vector3(outside.x+side*3.7,3.72,outside.z),Vector3(0.27,0.27,0.27),colors[1],biome==3)

func _big_signature_landmarks()->void:
 match biome:
  0:
   _ferris_wheel(Vector3(0,0,0))
   _theme_circus()
  1:
   _giant_windmill(Vector3(0,0,0))
   _grassland_story()
  2:
   _desert_temple(Vector3(0,0,0))
   _desert_story()
  3:
   _orbital_monument(Vector3(0,0,0))
   _space_story()

func _ferris_wheel(center:Vector3)->void:
 center+=Vector3(-3,20,2)
 for support in [-1.0,1.0]:
  _beam(center+Vector3(support*10,-19,0),center+Vector3(0,-1,support*2.4),0.49,colors[3])
 for arc in range(2):
  var prev:Vector3=Vector3.ZERO
  for j in range(49):
   var a=TAU*float(j)/48.0
   var p=center+Vector3(cos(a)*14,sin(a)*14,(arc-0.5)*2.6)
   if j>0:
    _beam(prev,p,0.21,colors[0])
   prev=p
 for spoke in range(12):
  var angle=TAU*float(spoke)/12.0
  var x=cos(angle)*14
  var y=sin(angle)*14
  _beam(center,center+Vector3(x,y,0),0.13,colors[4])
  _orb(center+Vector3(x,y+0.8,0),Vector3(0.95,0.66,0.84),colors[1])
 _orb(center,Vector3(1.6,1.6,1.1),colors[0])
 _letters("MONSTER FUN",center+Vector3(0,-19,12),92,colors[4])

func _theme_circus()->void:
 for ring in range(7):
  var a=float(ring)*TAU/7.0
  var p=Vector3(cos(a)*22,0,sin(a)*21)
  var shade=colors[ring%colors.size()]
  _cone(Vector3(p.x,2.9,p.z),4.0,0.0,5.8,shade)
  _cone(Vector3(p.x,6.0,p.z),4.35,0.0,4.3,colors[1])
  _box(Vector3(p.x,1.25,p.z),Vector3(3.0,2.5,2.7),colors[3])
  for j in range(6):
   var a2=float(j)*TAU/6.0
   var q=p+Vector3(cos(a2)*4.6,0,sin(a2)*4.6)
   _orb(q+Vector3.UP*2.9,Vector3(0.36,0.36,0.36),colors[0])

func _giant_windmill(center:Vector3)->void:
 _cone(center+Vector3(0,9,0),4.2,2.0,18,Color("#e5ddc9"))
 _cone(center+Vector3(0,19.5,0),3.4,0,3.5,colors[0])
 _orb(center+Vector3(0,15.8,-4.0),Vector3(1.7,1.7,1.7),colors[3])
 for i in range(6):
  var a=TAU*float(i)/6.0
  var start=center+Vector3(0,15.8,-5.0)
  var stop=start+Vector3(cos(a)*13,sin(a)*13,0)
  _beam(start,stop,0.16,colors[3])
  var tip=stop
  _orb(tip,Vector3(1.05,0.49,0.18),colors[1])
 _letters("EMERALD VALLEY",center+Vector3(0,2.0,-6.0),68,colors[4])

func _grassland_story()->void:
 for i in range(9):
  var a=float(i)*TAU/9.0
  var p=Vector3(cos(a)*29,0,sin(a)*28)
  var tint=colors[0] if i%2==0 else colors[1]
  _cone(p+Vector3(0,3.3,0),0.34,0.24,6.6,colors[3])
  for layer in range(3):
   _cone(p+Vector3(0,4.8+layer*1.6,0),4.2-layer*0.75,0.35,4.0,tint)
  _orb(p+Vector3(0,9.0,0),Vector3(0.55,0.55,0.55),colors[4])

func _desert_temple(center:Vector3)->void:
 for tier in range(7):
  var d=26.0-float(tier)*3.2
  var b=_box(center+Vector3(0,tier*1.6+0.1,0),Vector3(d,1.6,d),colors[2] if tier%2 else colors[1])
  b.rotation.y=0.04*float(tier)
 for side in [-1.0,1.0]:
  _cone(center+Vector3(side*16,5,0),3.7,1.4,10,colors[2])
  _orb(center+Vector3(side*16,10.6,0),Vector3(1.5,1.5,1.5),colors[4])
 _letters("DUNE EXPEDITION",center+Vector3(0,13,14),75,colors[4])

func _desert_story()->void:
 for i in range(10):
  var a=TAU*float(i)/10.0
  var radius=26.0+float(i%3)*5.0
  var p=Vector3(cos(a)*radius,0,sin(a)*radius)
  for level in range(4):
   var block=_box(p+Vector3(0,level*1.7+0.5,0),Vector3(4.4-level*0.4,1.8,4.0-level*0.38),colors[2] if level%2 else colors[1])
   block.rotation.y=a
  _cone(p+Vector3(0,9.0,0),2.6,0.0,5.0,colors[3])

func _orbital_monument(center:Vector3)->void:
 _orb(center+Vector3(0,18,0),Vector3(8,8,8),colors[2])
 for i in range(4):
  angle_ring(i,center+Vector3(0,18,0))
 for arm in range(8):
  var a=float(arm)*TAU/8.0
  var point=center+Vector3(cos(a)*21,0,sin(a)*21)
  _cone(point+Vector3(0,9.0,0),1.4,0.6,18,colors[3])
  _orb(point+Vector3(0,18.6,0),Vector3(1.35,1.35,1.35),colors[1],true)
 _letters("ORBITAL GP",center+Vector3(0,5,15),100,colors[4])

func angle_ring(i:int,p:Vector3)->void:
 var ring=_ring(p,12.0+float(i)*2.8,0.28,colors[1] if i%2 else colors[4],true)
 ring.rotation_degrees=Vector3(28+i*16,34+i*33,15+i*22)

func _space_story()->void:
 for j in range(10):
  var a=float(j)*TAU/10.0
  var p=Vector3(cos(a)*31,0,sin(a)*31)
  var c=_cone(p+Vector3(0,5.0,0),1.55,0.75,10.0,colors[2])
  c.rotation.z=0.10*sin(a)
  _orb(p+Vector3(0,11.1,0),Vector3(1.2,1.2,1.2),colors[1],true)
  _ring(p+Vector3(0,7.2,0),3.3,0.18,colors[4],true).rotation.x=0.4

func _landscape_instancing()->void:
 var m=SphereMesh.new()
 m.radius=1.0
 m.height=2.0
 m.radial_segments=10
 m.rings=6
 var mat=_mat(Color.WHITE,0.1)
 mat.vertex_color_use_as_albedo=true
 for group in range(4):
  var transform_list:Array[Transform3D]=[]
  var tint_list:Array[Color]=[]
  for i in range(360):
   var progress=rng.randf_range(0.0,float(circuit.SEGMENTS))
   var outside=(-1.0 if rng.randf()<0.5 else 1.0)*rng.randf_range(18.0,66.0)
   var pos:Vector3=circuit.sample(progress,outside)
   var base_size=rng.randf_range(0.9,2.1)
   var height=base_size*rng.randf_range(0.7,1.8)
   if biome==3:
    height=base_size*rng.randf_range(0.8,2.8)
   var basis=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(base_size,height,base_size))
   var y=height if biome!=3 else rng.randf_range(1.2,7.0)
   transform_list.append(Transform3D(basis,Vector3(pos.x,y,pos.z)))
   tint_list.append(colors[(group+i)%colors.size()].darkened(rng.randf_range(0.02,0.23)))
  _multi(m,mat,transform_list,tint_list,"LayeredScenery_%d" % group)

func set_quality(level:int)->void:
 quality_level=clampi(level,0,3)
 var fractions=[0.14,0.42,0.76,1.0]
 # Keep small primary strips in every mode, thin secondary scenic scatter.
 for batch in batched:
  if is_instance_valid(batch):
   if batch.name.begins_with("LayeredScenery"):
    batch.multimesh.visible_instance_count=int(360.0*fractions[quality_level])
