extends Node3D
## Fantasy circuit constructed entirely from mobile-friendly 3D meshes.
const SEGMENTS := 180
const HALF_WIDTH := 8.6
var centers: Array[Vector3] = []
var total_length := 0.0
var segment_lengths: Array[float] = []
var track_palette = [Color("#4e5879"), Color("#606c8d")]
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.seed = 80321
 for i in range(SEGMENTS):
  var a = TAU * float(i) / float(SEGMENTS)
  var r1 = 60.0 + 7.0 * sin(a * 3.0 + 0.3)
  var r2 = 47.0 + 6.0 * sin(a * 4.0 + 1.1)
  centers.append(Vector3(cos(a) * r1, 0.12, sin(a) * r2))
 for i in range(SEGMENTS):
  var size = centers[i].distance_to(centers[(i + 1) % SEGMENTS])
  segment_lengths.append(size)
  total_length += size
 _build_world()

func at(index: int, lane: float = 0.0) -> Vector3:
 var i = posmod(index, SEGMENTS)
 var tangent = (centers[(i + 1) % SEGMENTS] - centers[posmod(i - 1, SEGMENTS)]).normalized()
 var lateral = Vector3(-tangent.z, 0, tangent.x)
 return centers[i] + lateral * lane

func sample(progress: float, lane: float = 0.0) -> Vector3:
 var idx = fposmod(progress, float(SEGMENTS))
 var i = int(floor(idx))
 var alpha = idx - float(i)
 var tangent = (centers[(i + 1) % SEGMENTS] - centers[posmod(i - 1, SEGMENTS)]).normalized()
 var lateral = Vector3(-tangent.z, 0, tangent.x)
 return centers[i].lerp(centers[(i + 1) % SEGMENTS], alpha) + lateral * lane

func direction(progress: float) -> Vector3:
 return (sample(progress + 1.0) - sample(progress - 1.0)).normalized()

func nearest_index(pos: Vector3) -> int:
 var best := 0
 var best_d := INF
 for i in range(SEGMENTS):
  var d = pos.distance_squared_to(centers[i])
  if d < best_d:
   best = i
   best_d = d
 return best

func _mat(c: Color, rough := 0.8, glow := false) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = rough
 if glow:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = 1.35
 return m

func _shape(mesh: Mesh, at: Vector3, col: Color, parent: Node3D = null, glow := false) -> MeshInstance3D:
 var node = MeshInstance3D.new()
 node.mesh = mesh
 node.position = at
 node.material_override = _mat(col, 0.65, glow)
 if parent == null:
  add_child(node)
 else:
  parent.add_child(node)
 return node

func _box(pos: Vector3, size: Vector3, col: Color, parent: Node3D = null, glow := false) -> MeshInstance3D:
 var mesh = BoxMesh.new()
 mesh.size = size
 return _shape(mesh, pos, col, parent, glow)

func _ball(pos: Vector3, scale3: Vector3, col: Color, parent: Node3D = null) -> MeshInstance3D:
 var mesh = SphereMesh.new()
 mesh.radius = 1.0
 mesh.height = 2.0
 mesh.radial_segments = 12
 mesh.rings = 7
 var node = _shape(mesh, pos, col, parent)
 node.scale = scale3
 return node

func _cone(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
 var mesh = CylinderMesh.new()
 mesh.top_radius = 0.0
 mesh.bottom_radius = 1.0
 mesh.height = 2.0
 mesh.radial_segments = 9
 var n = _shape(mesh, pos, col)
 n.scale = size
 return n

func _ribbon(half_width: float, y: float, color: Color) -> void:
 var tool = SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(SEGMENTS):
  var a = at(i, -half_width)
  var b = at(i, half_width)
  var c = at(i + 1, -half_width)
  var d = at(i + 1, half_width)
  a.y = y
  b.y = y
  c.y = y
  d.y = y
  for p in [a, c, b, b, c, d]:
   tool.add_vertex(p)
 tool.generate_normals()
 var road = MeshInstance3D.new()
 road.mesh = tool.commit()
 road.material_override = _mat(color)
 add_child(road)

func _build_world() -> void:
 var env = WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("#98d8fa")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("#cce9ff")
 env.environment.ambient_light_energy = 0.75
 env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
 env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 add_child(env)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-57, -35, -12)
 sun.light_color = Color("#fff3d6")
 sun.light_energy = 1.6
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 110.0
 add_child(sun)
 var fill = DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(45, 145, 0)
 fill.light_color = Color("#9dd5ff")
 fill.light_energy = 0.4
 add_child(fill)

 _box(Vector3(0, -0.30, 0), Vector3(355, 0.4, 315), Color("#71c895"))
 _box(Vector3(0, -0.10, 0), Vector3(130, 0.22, 86), Color("#89d7a9"))
 _ribbon(HALF_WIDTH + 1.8, 0.02, Color("#eadbc1"))
 _ribbon(HALF_WIDTH + 0.70, 0.055, Color("#e87da1"))
 _ribbon(HALF_WIDTH, 0.085, Color("#485774"))
 _ribbon(HALF_WIDTH - 0.45, 0.090, Color("#57667d"))
 for i in range(0, SEGMENTS, 3):
  var a = at(i, 0.0)
  var b = at(i + 1, 0.0)
  var t = (b - a).normalized()
  var mid = (a + b) * 0.5
  var dash = _box(Vector3(mid.x, 0.105, mid.z), Vector3(0.28, 0.027, 1.65), Color("#ffe9a4"), null, true)
  dash.rotation.y = atan2(-t.x, -t.z)
 for i in range(0, SEGMENTS, 5):
  for side in [-1.0, 1.0]:
   var p = at(i, side * (HALF_WIDTH + 1.0))
   _ball(Vector3(p.x, 0.30, p.z), Vector3(0.53, 0.44, 0.53), Color("#fff0d0"))
   if i % 10 == 0:
    var rail = _box(Vector3(p.x, 1.0, p.z), Vector3(0.29, 1.75, 0.29), Color("#fff3ce"))
    var orb = _ball(Vector3(p.x, 1.94, p.z), Vector3(0.36, 0.36, 0.36), Color("#ffc9d9"))

 # Finish stripe and start gantry.
 var p0 = at(0)
 var t0 = direction(0.0)
 var bar = _box(Vector3(p0.x, 0.119, p0.z), Vector3(HALF_WIDTH * 2.0, 0.04, 1.2), Color("#e9f5ff"))
 bar.rotation.y = atan2(-t0.x, -t0.z)
 var across = Vector3(-t0.z, 0, t0.x)
 for j in range(10):
  var q = p0 + across * (float(j) - 4.5) * 1.7
  var tile = _box(Vector3(q.x, 0.15, q.z), Vector3(1.65, 0.03, 0.55), Color("#343f68") if j % 2 == 0 else Color("#ffffff"))
  tile.rotation.y = bar.rotation.y
 for side in [-1.0, 1.0]:
  var q = at(0, side * (HALF_WIDTH + 1.4))
  _box(Vector3(q.x, 3.3, q.z), Vector3(0.78, 6.6, 0.78), Color("#ffe4aa"))
 _box(Vector3(p0.x, 6.65, p0.z), Vector3(19.5, 1.25, 1.2), Color("#ff7da4"))

 # Inner festival village, outer forest and pastel mountain silhouettes.
 for i in range(75):
  var a = rng.randf_range(0.0, TAU)
  var rr = rng.randf_range(90.0, 153.0)
  var point = Vector3(cos(a) * rr, -0.1, sin(a) * rr)
  if rng.randf() < 0.74:
   _tree(point, rng.randf_range(0.75, 1.65))
  else:
   _crystal(point, rng.randf_range(0.8, 2.3))
 for i in range(28):
  var a = float(i) * TAU / 28.0 + 0.12
  var p = Vector3(cos(a) * 120.0, 0.0, sin(a) * 106.0)
  _cone(Vector3(p.x, 8.0, p.z), Vector3(rng.randf_range(6.0, 10.0), rng.randf_range(8.0, 13.0), rng.randf_range(6.0, 10.0)), Color("#9ec9c0") if i % 2 == 0 else Color("#8dabc4"))
 for i in range(15):
  var a = float(i) * TAU / 15.0
  var p = Vector3(cos(a) * 29.0, 0.0, sin(a) * 22.0)
  _tree(p, rng.randf_range(0.7, 1.2))
 # Colorful balloons and clouds in the central party area.
 for i in range(10):
  var p = Vector3(rng.randf_range(-28.0, 28.0), rng.randf_range(10.0, 20.0), rng.randf_range(-25.0, 25.0))
  _ball(p, Vector3(1.7, 2.1, 1.7), [Color("#ffabb9"), Color("#ffe190"), Color("#91e6fb"), Color("#c4a9fc")][i % 4])
  _box(p + Vector3(0, -2.5, 0), Vector3(0.06, 1.2, 0.06), Color("#f7e9df"))
 for i in range(7):
  var a = float(i) * 1.7
  var cloud = Vector3(cos(a) * 88.0, 24.0 + 3.0 * sin(a), sin(a) * 69.0)
  _ball(cloud, Vector3(6.4, 2.0, 3.0), Color("#f5fcff"))
  _ball(cloud + Vector3(3.7, 0.2, 0), Vector3(4.0, 1.7, 2.6), Color("#f5fcff"))
 _box(Vector3(0, 0.1, 0), Vector3(12, 0.35, 12), Color("#f9d992"))
 _box(Vector3(0, 0.46, 0), Vector3(7.6, 0.42, 7.6), Color("#ff99b8"))

func _tree(p: Vector3, size: float) -> void:
 _box(p + Vector3(0, size * 1.4, 0), Vector3(size * 0.6, size * 2.8, size * 0.6), Color("#9b795e"))
 var colors = [Color("#7dd4a4"), Color("#9ee3bf"), Color("#c9e59f"), Color("#93d8d6"), Color("#ffc0d3")]
 var c = colors[rng.randi_range(0, colors.size() - 1)]
 _ball(p + Vector3(0, size * 3.1, 0), Vector3(size * 1.7, size * 1.55, size * 1.7), c)
 _ball(p + Vector3(size * 0.7, size * 3.45, 0), Vector3(size * 1.0, size * 0.96, size * 1.0), c.lightened(0.08))

func _crystal(p: Vector3, size: float) -> void:
 var c = [Color("#b5b4f9"), Color("#87e5ea"), Color("#f9accd")][rng.randi_range(0, 2)]
 _cone(p + Vector3(0, size, 0), Vector3(size * 0.7, size, size * 0.7), c)
 _cone(p + Vector3(size * 0.8, size * 0.55, 0), Vector3(size * 0.45, size * 0.55, size * 0.45), c.lightened(0.18))
