extends Node3D
## Neon-toy studio showroom for the garage. The race circuits remain physically
## present, while this dedicated stage gives the selector a crafted focal point.
var led_rings: Array[MeshInstance3D] = []
var second := 0.0

func _ready() -> void:
 name="MonsterKartShowroom"
 position=Vector3(7.3,0.04,0)
 _stage()

func _mat(c:Color,glow:=false,metal:=false)->StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=c
 m.roughness=0.2 if metal else 0.73
 m.metallic=0.4 if metal else 0.0
 if glow:
  m.emission_enabled=true
  m.emission=c
  m.emission_energy_multiplier=1.65
 return m

func _node(mesh:Mesh,p:Vector3,c:Color,glow:=false,metal:=false)->MeshInstance3D:
 var n=MeshInstance3D.new()
 n.mesh=mesh
 n.position=p
 n.material_override=_mat(c,glow,metal)
 add_child(n)
 return n

func _cylinder(p:Vector3,rad:float,h:float,c:Color,glow:=false)->void:
 var m=CylinderMesh.new()
 m.top_radius=rad
 m.bottom_radius=rad
 m.height=h
 m.radial_segments=48
 _node(m,p,c,glow,true)

func _ring(p:Vector3,r:float,c:Color,tilt:float=0.0)->MeshInstance3D:
 var mesh=TorusMesh.new()
 mesh.inner_radius=r-0.10
 mesh.outer_radius=r+0.10
 mesh.ring_segments=48
 mesh.rings=9
 var n=_node(mesh,p,c,true)
 n.rotation.x=tilt
 led_rings.append(n)
 return n

func _orb(p:Vector3,r:float,c:Color)->void:
 var m=SphereMesh.new()
 m.radius=r
 m.height=r*2.0
 m.radial_segments=15
 m.rings=7
 _node(m,p,c,true)

func _tube(a:Vector3,b:Vector3,r:float,c:Color)->void:
 var dir=b-a
 var mesh=CylinderMesh.new()
 mesh.top_radius=r
 mesh.bottom_radius=r
 mesh.height=dir.length()
 mesh.radial_segments=8
 var n=_node(mesh,(a+b)*0.5,c,true)
 n.quaternion=Quaternion(Vector3.UP,dir.normalized())

func _stage() -> void:
 _cylinder(Vector3(0,-0.08,0),4.6,0.27,Color("#203456"))
 _cylinder(Vector3(0,0.08,0),4.28,0.21,Color("#425278"))
 _cylinder(Vector3(0,0.19,0),3.9,0.08,Color("#607ba0"))
 _ring(Vector3(0,0.26,0),4.10,Color("#9df3f9"))
 _ring(Vector3(0,0.28,0),3.72,Color("#ffcd99"))
 _ring(Vector3(0,0.32,0),3.18,Color("#db98fa"))
 # Halo-lights, vertical race-gallery beams and asymmetric neon choreography.
 for n in range(12):
  var angle=TAU*float(n)/12.0
  var loc=Vector3(cos(angle)*4.42,0.42,sin(angle)*4.42)
  _orb(loc,0.12,Color("#e5fdff") if n%3 else Color("#ffdd92"))
 for i in range(5):
  var angle=(float(i)/4.0*PI)+PI*0.15
  var start=Vector3(cos(angle)*5.1,0.1,sin(angle)*5.1)
  var end=start+Vector3(0,8.0,0)
  _tube(start,end,0.085,Color("#bbcffb"))
  _orb(end,0.28,Color("#fff1bb"))
 # Two showcase spotlights are cheap and only affect the menu.
 for i in range(2):
  var key=SpotLight3D.new()
  key.position=Vector3(-4.0 if i==0 else 4.0,8.8,1.6)
  key.rotation_degrees=Vector3(-70,0,0)
  key.light_energy=1.6
  key.light_color=Color("#ffe4be") if i==0 else Color("#a9eaff")
  key.spot_range=16.0
  key.spot_angle=44.0
  key.shadow_enabled=false
  add_child(key)
 # Product-stage floating insignia.
 var ring=_ring(Vector3(0,6.8,0),3.75,Color("#badbff"),0.52)
 ring.scale=Vector3(1.0,0.86,1.0)

func _process(dt:float)->void:
 if not visible:
  return
 second+=dt
 for i in range(led_rings.size()):
  if i>2:
   led_rings[i].rotation.y=sin(second*0.30)*0.12
