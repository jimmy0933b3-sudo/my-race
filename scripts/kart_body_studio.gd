extends Node3D
## Hand-shaped automotive silhouette, layered resin finish and creature cockpit.
## Organic lofted meshes replace the previous box-like outer vehicle shell.
const Materials = preload("res://scripts/material_studio.gd")
var base_color: Color
var accent: Color
var root_model: Node3D
var nacelles: Array[Node3D] = []
var spoke_count := 0
var seconds := 0.0
var bounce: Node3D

func build(primary: Color, secondary: Color, variant: int) -> void:
 name="CustomBodywork"
 base_color=primary
 accent=secondary
 var shapes = [
  {"z":-1.95,"width":0.38,"height":0.10,"y":0.88},
  {"z":-1.74,"width":0.84,"height":0.24,"y":0.94},
  {"z":-1.29,"width":1.01,"height":0.26,"y":0.97},
  {"z":-0.55,"width":1.10,"height":0.31,"y":0.94},
  {"z":0.28,"width":1.05,"height":0.33,"y":0.92},
  {"z":1.02,"width":1.08,"height":0.32,"y":0.91},
  {"z":1.53,"width":0.98,"height":0.25,"y":0.91},
  {"z":1.85,"width":0.55,"height":0.10,"y":0.88}
 ]
 _loft(shapes,Materials.paint(base_color,accent))
 # Contoured bonnet, with raised central spine and pressed side shoulders.
 var hood = [
  {"z":-1.98,"width":0.20,"height":0.03,"y":1.15},
  {"z":-1.64,"width":0.56,"height":0.07,"y":1.24},
  {"z":-1.20,"width":0.73,"height":0.09,"y":1.29},
  {"z":-0.71,"width":0.80,"height":0.06,"y":1.23},
  {"z":-0.46,"width":0.62,"height":0.01,"y":1.18}
 ]
 _loft(hood,Materials.paint(base_color.lightened(0.17),accent))
 _add_canopy()
 _rear_diffuser()
 _steering()
 _accents(variant)
 _fenders()
 _exhaust()

func _loft(rings: Array, material: Material) -> void:
 var tube = SurfaceTool.new()
 tube.begin(Mesh.PRIMITIVE_TRIANGLES)
 var segments = 20
 for i in range(rings.size()-1):
  var a: Dictionary = rings[i]
  var b: Dictionary = rings[i+1]
  for j in range(segments):
   var p0 = _point(a,j,segments)
   var p1 = _point(a,j+1,segments)
   var p2 = _point(b,j,segments)
   var p3 = _point(b,j+1,segments)
   var ua = float(i)/float(rings.size()-1)
   var ub = float(i+1)/float(rings.size()-1)
   var v0 = float(j)/float(segments)
   var v1 = float(j+1)/float(segments)
   for item in [
    {"p":p0,"uv":Vector2(ua,v0)},{"p":p2,"uv":Vector2(ub,v0)},{"p":p1,"uv":Vector2(ua,v1)},
    {"p":p1,"uv":Vector2(ua,v1)},{"p":p2,"uv":Vector2(ub,v0)},{"p":p3,"uv":Vector2(ub,v1)}
   ]:
    tube.set_uv(item["uv"])
    tube.add_vertex(item["p"])
 tube.generate_normals()
 var view = MeshInstance3D.new()
 view.mesh=tube.commit()
 view.material_override=material
 add_child(view)

func _point(ring: Dictionary, n: int, count: int) -> Vector3:
 var angle=float(n)*TAU/float(count)
 var x=cos(angle)*float(ring["width"])
 var y=float(ring["y"])+sin(angle)*float(ring["height"])
 return Vector3(x,y,float(ring["z"]))

func _mat(color: Color, glow := false, metal := 0.0) -> StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=color
 m.metallic=metal
 m.roughness=0.27 if metal>0.0 else 0.44
 m.clearcoat_enabled=metal>0.0
 if metal>0.0:m.clearcoat=0.9
 if glow:
  m.emission_enabled=true
  m.emission=color
  m.emission_energy_multiplier=1.5
 return m

func _mesh(mesh: Mesh,p:Vector3,color:Color,glow := false,metal := 0.0,parent:Node3D=null)->MeshInstance3D:
 var n=MeshInstance3D.new()
 n.mesh=mesh
 n.position=p
 n.material_override=_mat(color,glow,metal)
 if parent==null:add_child(n)
 else:parent.add_child(n)
 return n

func _ball(p:Vector3,sz:Vector3,color:Color,glow := false)->MeshInstance3D:
 var sp=SphereMesh.new()
 sp.radius=1.0
 sp.height=2.0
 sp.radial_segments=15
 sp.rings=7
 var n=_mesh(sp,p,color,glow)
 n.scale=sz
 return n

func _bar(p:Vector3,sz:Vector3,color:Color,glow:=false,metal:=0.0)->MeshInstance3D:
 var bm=BoxMesh.new()
 bm.size=sz
 return _mesh(bm,p,color,glow,metal)

func _tube(p:Vector3,radius:float,length:float,col:Color,glow:=false)->MeshInstance3D:
 var cyl=CylinderMesh.new()
 cyl.bottom_radius=radius
 cyl.top_radius=radius
 cyl.height=length
 cyl.radial_segments=10
 return _mesh(cyl,p,col,glow,0.4)

func _add_canopy() -> void:
 # Sculpted bucket-seat, carbon dashboard, mirrored side panels.
 _ball(Vector3(0,1.21,0.93),Vector3(0.62,0.36,0.49),Color("#2b3559"))
 _ball(Vector3(0,1.23,1.21),Vector3(0.58,0.48,0.20),accent.darkened(0.4))
 for side in [-1.0,1.0]:
  var pillar=_tube(Vector3(side*0.83,1.21,0.71),0.067,0.62,Color("#d6eff7"))
  pillar.rotation.z=side*0.42
  _ball(Vector3(side*0.91,1.29,0.32),Vector3(0.18,0.12,0.27),accent)
  _bar(Vector3(side*0.92,1.02,1.26),Vector3(0.17,0.12,0.65),base_color.lightened(0.22),false,0.4)
 # Inset animated dashboard meters in a polished wraparound enclosure.
 _ball(Vector3(0,1.33,-0.26),Vector3(0.64,0.11,0.17),Color("#202d47"))
 for side in [-1.0,1.0]:
  _ball(Vector3(side*0.28,1.42,-0.25),Vector3(0.105,0.027,0.07),Color("#83f5ed"),true)

func _rear_diffuser() -> void:
 for side in [-1.0,1.0]:
  var fairing=_ball(Vector3(side*0.76,0.69,1.39),Vector3(0.35,0.24,0.57),base_color.darkened(0.24))
  fairing.rotation.z=side*0.14
  _bar(Vector3(side*0.78,0.83,1.92),Vector3(0.45,0.11,0.12),accent,true)
  _ball(Vector3(side*0.50,0.75,1.94),Vector3(0.19,0.09,0.04),Color("#ff545c"),true)
 _bar(Vector3(0,0.56,1.91),Vector3(1.36,0.16,0.15),Color("#27334d"),false,0.7)
 for i in range(5):
  _bar(Vector3(-0.56+i*0.28,0.53,1.97),Vector3(0.05,0.27,0.12),Color("#111a2c"),false,0.4)

func _steering() -> void:
 var metal=Color("#434e6d")
 var wheel=_tube(Vector3(0,1.46,-0.09),0.05,0.40,metal)
 wheel.rotation.x=0.55
 var tor=TorusMesh.new()
 tor.inner_radius=0.20
 tor.outer_radius=0.27
 tor.ring_segments=22
 tor.rings=8
 var display=_mesh(tor,Vector3(0,1.65,-0.28),Color("#253049"),false,0.3)
 display.rotation.x=0.55
 _ball(Vector3(0,1.66,-0.30),Vector3(0.11,0.06,0.11),accent,true)

func _accents(index:int) -> void:
 # Body-kit identity: a crest and patterned hood decal by creature family.
 for side in [-1.0,1.0]:
  _ball(Vector3(side*0.71,1.13,-1.61),Vector3(0.19,0.12,0.08),Color("#fff8e5"),true)
  _ball(Vector3(side*0.78,0.90,-1.84),Vector3(0.21,0.07,0.06),accent,true)
  var spoiler=_bar(Vector3(side*0.83,1.29,1.48),Vector3(0.15,0.40,0.30),base_color.darkened(0.25),false,0.5)
  spoiler.rotation.z=side*0.08
 _bar(Vector3(0,1.55,1.54),Vector3(2.15,0.13,0.35),base_color.lightened(0.22),false,0.4)
 for j in range(4):
  var side=-0.5+float(j)/3.0
  _bar(Vector3(side*0.82,1.63,1.54),Vector3(0.075,0.018,0.29),accent,true)
 for i in range(3):
  var z=-1.45+i*0.31
  if index%4==0:
   _bar(Vector3(0,1.36-i*0.03,z),Vector3(0.19,0.026,0.20),accent,true)
  elif index%4==1:
   for side in [-1.0,1.0]:
    _ball(Vector3(side*0.33,1.33-i*0.02,z),Vector3(0.09,0.025,0.11),accent,true)
  elif index%4==2:
   _bar(Vector3(0,1.36-i*0.03,z),Vector3(0.47,0.024,0.08),accent,true)
  else:
   _ball(Vector3(0,1.38-i*0.03,z),Vector3(0.13,0.018,0.12),Color("#f9ffff"),true)
 # Creature-shaped ceramic badges.
 _ball(Vector3(0,1.38,-1.70),Vector3(0.18,0.06,0.23),accent)
 _ball(Vector3(-0.07,1.42,-1.76),Vector3(0.045,0.025,0.06),Color.WHITE,true)

func _fenders() -> void:
 for side in [-1.0,1.0]:
  for z in [-1.14,1.12]:
   var cover=_ball(Vector3(side*1.00,0.92,z),Vector3(0.32,0.25,0.73),base_color.darkened(0.17))
   cover.rotation.z=-side*0.19
   _ball(Vector3(side*1.27,0.76,z),Vector3(0.09,0.19,0.54),accent)
   _ball(Vector3(side*1.08,1.17,z-0.08),Vector3(0.11,0.058,0.44),base_color.lightened(0.35))

func _exhaust() -> void:
 for side in [-1.0,1.0]:
  _tube(Vector3(side*0.54,0.86,1.92),0.18,0.20,Color("#778ca4"))
  _ball(Vector3(side*0.54,0.87,2.04),Vector3(0.12,0.10,0.04),Color("#111c35"))
  var flame=_ball(Vector3(side*0.54,0.86,2.15),Vector3(0.08,0.10,0.18),Color("#90edff"),true)
  nacelles.append(flame)

func animate_body(dt:float,speed:float,drifting:bool) -> void:
 seconds += dt
 for i in range(nacelles.size()):
  var flame=nacelles[i]
  flame.scale.z=0.14+clampf(speed/50.0,0.0,1.0)*0.22+(0.07 if drifting else 0.0)
  flame.visible=speed>4.0
