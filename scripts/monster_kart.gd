extends Node3D
## Procedurally sculpted, original monster-karts. No external models or paid assets.
const ROSTER = [
 {"name":"熔岩暴暴","eng":"BLAZE","color":"#ff674f","accent":"#ffdb59","type":"horn","speed":5,"grip":3},
 {"name":"泡泡啵啵","eng":"BUBBLE","color":"#66dbe8","accent":"#ffe48a","type":"slime","speed":3,"grip":5},
 {"name":"獨眼咚咚","eng":"CYCLOPS","color":"#aa85ff","accent":"#f8c4ff","type":"cyclops","speed":4,"grip":4},
 {"name":"夜翼蝙蝙","eng":"NIGHTWING","color":"#6659bf","accent":"#fd81c8","type":"bat","speed":5,"grip":2},
 {"name":"飛龍噴噴","eng":"DRACO","color":"#65d18a","accent":"#ffd674","type":"dragon","speed":4,"grip":4},
 {"name":"機械鏘鏘","eng":"BOLT","color":"#79bdf5","accent":"#fdad3c","type":"robot","speed":5,"grip":3},
 {"name":"蜜蜂嗡嗡","eng":"BZZ","color":"#ffd75d","accent":"#483a68","type":"bee","speed":4,"grip":5},
 {"name":"章魚捲捲","eng":"INKY","color":"#ff8cba","accent":"#91e2ff","type":"octopus","speed":3,"grip":5},
 {"name":"貓怪喵喵","eng":"MEOWZA","color":"#f9bb75","accent":"#fff1cd","type":"cat","speed":4,"grip":5},
 {"name":"恐龍吼吼","eng":"CHOMP","color":"#78c76b","accent":"#f4ef9b","type":"dino","speed":5,"grip":3},
 {"name":"幽靈飄飄","eng":"BOO","color":"#d9e5ff","accent":"#92caff","type":"ghost","speed":3,"grip":5},
 {"name":"水晶閃閃","eng":"GLIMMER","color":"#9fe6f2","accent":"#e6a0ff","type":"crystal","speed":5,"grip":4}
]
var model: Node3D
var wheels: Array[Node3D] = []
var paint: Color
var trim: Color
var shell: Color
var kind_id := 0
var timer := 0.0

func configure(index: int) -> void:
 kind_id = posmod(index, ROSTER.size())
 paint = Color(ROSTER[kind_id]["color"])
 trim = Color(ROSTER[kind_id]["accent"])
 shell = paint.darkened(0.27)
 model = Node3D.new()
 model.name = "AnimatedKart"
 add_child(model)
 _build()

func _mat(col: Color, metallic := 0.0, roughness := 0.45, glow := false) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = col
 m.metallic = metallic
 m.roughness = roughness
 if glow:
  m.emission_enabled = true
  m.emission = col
  m.emission_energy_multiplier = 1.9
 return m

func _mesh(mesh: Mesh, at: Vector3, col: Color, parent: Node3D = model, metal := 0.0, glow := false) -> MeshInstance3D:
 var node = MeshInstance3D.new()
 node.mesh = mesh
 node.position = at
 node.material_override = _mat(col, metal, 0.34 if metal > 0.0 else 0.58, glow)
 parent.add_child(node)
 return node

func _box(at: Vector3, sz: Vector3, col: Color, parent: Node3D = model, metal := 0.0, glow := false) -> MeshInstance3D:
 var b = BoxMesh.new()
 b.size = sz
 return _mesh(b, at, col, parent, metal, glow)

func _ball(at: Vector3, radii: Vector3, col: Color, parent: Node3D = model, glow := false) -> MeshInstance3D:
 var s = SphereMesh.new()
 s.radius = 1.0
 s.height = 2.0
 s.radial_segments = 16
 s.rings = 8
 var n = _mesh(s, at, col, parent, 0.0, glow)
 n.scale = radii
 return n

func _cone(at: Vector3, radius: float, height: float, col: Color, rotate: Vector3 = Vector3.ZERO) -> MeshInstance3D:
 var c = CylinderMesh.new()
 c.top_radius = 0.03
 c.bottom_radius = radius
 c.height = height
 c.radial_segments = 10
 var n = _mesh(c, at, col)
 n.rotation = rotate
 return n

func _build() -> void:
 # Thick glossy kart body, bumper, wing, headlamps, exhausts.
 _box(Vector3(0, 0.72, 0), Vector3(2.15, 0.53, 3.15), shell, model, 0.22)
 _box(Vector3(0, 0.99, -0.25), Vector3(1.90, 0.38, 1.88), paint)
 _box(Vector3(0, 0.89, -1.59), Vector3(2.31, 0.30, 0.38), trim, model, 0.36)
 _box(Vector3(0, 0.82, 1.55), Vector3(2.30, 0.24, 0.28), trim, model, 0.20)
 _box(Vector3(0, 1.17, 1.29), Vector3(2.35, 0.15, 0.42), paint)
 _box(Vector3(0, 0.58, -1.82), Vector3(1.50, 0.12, 0.23), Color("#ecf7ff"))
 _box(Vector3(0, 1.1, 0.9), Vector3(1.50, 0.34, 0.65), shell)
 for side in [-1.0, 1.0]:
  _box(Vector3(side * 0.75, 1.12, -1.47), Vector3(0.40, 0.20, 0.12), Color("#f9fff0"), model, 0.0, true)
  _box(Vector3(side * 0.71, 0.83, 1.66), Vector3(0.37, 0.20, 0.10), Color("#ff5768"), model, 0.0, true)
  _box(Vector3(side * 0.83, 0.60, 1.75), Vector3(0.27, 0.23, 0.46), Color("#49526e"), model, 0.6)
  for front in [-1.10, 1.13]:
   var pivot = Node3D.new()
   pivot.position = Vector3(side * 1.12, 0.56, front)
   model.add_child(pivot)
   wheels.append(pivot)
   var tire = CylinderMesh.new()
   tire.top_radius = 0.56
   tire.bottom_radius = 0.56
   tire.height = 0.44
   tire.radial_segments = 20
   var wheel = _mesh(tire, Vector3.ZERO, Color("#282b44"), pivot)
   wheel.rotation.z = PI / 2.0
   var hub = CylinderMesh.new()
   hub.top_radius = 0.29
   hub.bottom_radius = 0.29
   hub.height = 0.47
   hub.radial_segments = 12
   var disk = _mesh(hub, Vector3.ZERO, trim, pivot, 0.6)
   disk.rotation.z = PI / 2.0
 # Driver creature is the visual and mechanic identity of each car.
 _ball(Vector3(0, 1.82, 0.31), Vector3(0.80, 0.83, 0.72), paint)
 var eye_color = Color("#ffffff")
 var pupil = Color("#202441")
 if ROSTER[kind_id]["type"] == "cyclops":
  _ball(Vector3(0, 1.96, -0.36), Vector3(0.34, 0.37, 0.18), eye_color)
  _ball(Vector3(0, 1.96, -0.51), Vector3(0.14, 0.19, 0.09), pupil)
 else:
  for side in [-1.0, 1.0]:
   _ball(Vector3(side * 0.31, 2.04, -0.28), Vector3(0.22, 0.26, 0.16), eye_color)
   _ball(Vector3(side * 0.31, 2.03, -0.41), Vector3(0.10, 0.13, 0.07), pupil)
 _ball(Vector3(0, 1.62, -0.39), Vector3(0.26, 0.12, 0.06), shell)
 var costume: String = ROSTER[kind_id]["type"]
 match costume:
  "horn":
   _cone(Vector3(-0.50, 2.63, 0.19), 0.30, 0.88, trim, Vector3(0, 0, -0.25))
   _cone(Vector3(0.50, 2.63, 0.19), 0.30, 0.88, trim, Vector3(0, 0, 0.25))
   _cone(Vector3(0, 2.75, 0.48), 0.19, 0.50, Color("#ffd455"))
  "slime":
   _ball(Vector3(0, 2.58, 0.30), Vector3(0.49, 0.21, 0.42), trim)
   _ball(Vector3(-0.48, 2.38, 0.24), Vector3(0.20, 0.37, 0.20), paint)
   _ball(Vector3(0.51, 2.32, 0.24), Vector3(0.20, 0.33, 0.20), paint)
  "cyclops":
   for side in [-1.0, 1.0]:
    _cone(Vector3(side * 0.57, 2.62, 0.38), 0.23, 0.76, trim, Vector3(0, 0, side * 0.45))
  "bat":
   for side in [-1.0, 1.0]:
    var wing = _box(Vector3(side * 1.00, 2.06, 0.42), Vector3(0.95, 0.08, 0.71), trim)
    wing.rotation.z = side * 0.32
    _cone(Vector3(side * 0.47, 2.56, 0.15), 0.32, 0.75, shell)
  "dragon":
   for n in range(3):
    _cone(Vector3(0, 2.61 - n * 0.06, 0.25 + n * 0.39), 0.22, 0.58, trim)
   _ball(Vector3(-0.51, 1.72, -0.15), Vector3(0.20, 0.27, 0.31), Color("#ffe58a"))
   _ball(Vector3(0.51, 1.72, -0.15), Vector3(0.20, 0.27, 0.31), Color("#ffe58a"))
  "robot":
   _box(Vector3(0, 2.55, 0.28), Vector3(0.92, 0.14, 0.76), Color("#e8eef7"), model, 0.8)
   _box(Vector3(0, 1.99, -0.45), Vector3(1.0, 0.22, 0.13), Color("#b4ffff"), model, 0.5, true)
   _cone(Vector3(0, 2.90, 0.25), 0.11, 0.58, trim)
   _ball(Vector3(0, 3.23, 0.25), Vector3(0.16, 0.16, 0.16), Color("#ff6592"), model, true)
  "bee":
   for n in range(3):
    _box(Vector3(0, 1.34, 0.82 + n * 0.29), Vector3(1.72, 0.15, 0.10), trim)
   for side in [-1.0, 1.0]:
    _ball(Vector3(side * 0.67, 2.56, 0.47), Vector3(0.46, 0.11, 0.37), Color("#e6faff"))
    _cone(Vector3(side * 0.31, 2.81, 0.1), 0.09, 0.50, trim)
  "octopus":
   for n in range(5):
    var a = TAU * float(n) / 5.0
    _ball(Vector3(cos(a) * 0.55, 1.40, sin(a) * 0.5 + 0.20), Vector3(0.19, 0.32, 0.22), trim)
   _ball(Vector3(0, 2.61, 0.31), Vector3(0.40, 0.21, 0.38), paint.lightened(0.15))
  "cat":
   for side in [-1.0, 1.0]:
    _cone(Vector3(side * 0.48, 2.52, 0.27), 0.35, 0.67, trim)
    _box(Vector3(side * 0.52, 1.74, -0.44), Vector3(0.28, 0.035, 0.1), Color("#f3f0e7"))
   _ball(Vector3(0, 1.82, -0.46), Vector3(0.14, 0.11, 0.10), Color("#fa7698"))
  "dino":
   for n in range(4):
    _cone(Vector3(0, 2.62 - n * 0.1, 0.02 + n * 0.32), 0.25, 0.52, trim)
   _ball(Vector3(0, 1.73, -0.41), Vector3(0.48, 0.23, 0.30), paint.lightened(0.1))
  "ghost":
   _ball(Vector3(0, 2.58, 0.35), Vector3(0.53, 0.18, 0.40), Color("#eff4ff"))
   for side in [-1.0, 1.0]:
    _ball(Vector3(side * 0.59, 1.45, 0.33), Vector3(0.19, 0.30, 0.25), Color("#edf8ff"))
   _ball(Vector3(0, 1.61, -0.5), Vector3(0.13, 0.20, 0.09), Color("#43476e"))
  "crystal":
   for n in range(5):
    var a = float(n) * TAU / 5.0
    var spike = _cone(Vector3(cos(a) * 0.44, 2.66, sin(a) * 0.37 + 0.3), 0.24, 0.81, trim)
    spike.rotation.z = -cos(a) * 0.40
   _ball(Vector3(0, 1.42, -1.15), Vector3(0.25, 0.14, 0.26), Color("#d9ffff"), model, true)

func animate_kart(dt: float, drive_speed: float, drifting: bool) -> void:
 timer += dt * maxf(1.0, drive_speed * 0.24)
 if model:
  model.position.y = sin(timer * 1.7) * 0.038
  model.rotation.z = lerpf(model.rotation.z, (-0.095 if drifting else 0.0), minf(1.0, dt * 6.0))
 for wheel in wheels:
  wheel.rotation.x += drive_speed * dt * 1.4
