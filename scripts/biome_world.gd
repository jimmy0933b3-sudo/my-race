extends Node3D
## Three independently built, fully traversable arcade circuits:
## emerald grasslands, sunlit dune kingdom, and orbital starway.
## All mesh geometry is original, no external assets or textures are needed.
const NAMES = ["", "EMERALD MEADOWS", "GOLDEN DUNES", "STAR RING"]
const ROAD_HALF_WIDTH = 8.6
const SEGMENT_COUNT = 180
var course
var biome := 1
var rng := RandomNumberGenerator.new()
var colors: Array[Color] = []
var landmark_count := 0
var scatter_count := 0
var detail_count := 0
var cached: Dictionary = {}
var sphere_low: SphereMesh
var instance_mesh: SphereMesh

func build(track: Node3D, variant: int) -> void:
 course = track
 biome = clampi(variant, 1, 3)
 name = "BiomeWorld_%d" % biome
 rng.seed = 401033 + biome * 739
 _set_palette()
 _environment()
 _ground()
 _road()
 _districts()
 _small_details()
 _scatter()
 print("BIOME WORLD %s landmarks=%d scatter=%d" % [NAMES[biome], landmark_count, scatter_count])

func _set_palette() -> void:
 match biome:
  1: colors = [Color("#73d69d"), Color("#368a79"), Color("#fff1aa"), Color("#b2f5dc"), Color("#eea4bd")]
  2: colors = [Color("#f9cf85"), Color("#dc9466"), Color("#fef1cf"), Color("#f8a66b"), Color("#81d1c9")]
  3: colors = [Color("#2e335e"), Color("#9a7cec"), Color("#87edff"), Color("#ffa8d1"), Color("#fce9a6")]

func _material(c: Color, glow := false, metal := false) -> StandardMaterial3D:
 var key = c.to_html(true) + "/" + str(glow) + "/" + str(metal)
 if cached.has(key):
  return cached[key]
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = 0.28 if metal else 0.70
 m.metallic = 0.45 if metal else 0.0
 if metal:
  m.clearcoat_enabled = true
  m.clearcoat = 0.6
 if glow:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = 1.55
 cached[key] = m
 return m

func _node(mesh: Mesh, p: Vector3, c: Color, glow := false, metal := false) -> MeshInstance3D:
 var n = MeshInstance3D.new()
 n.mesh = mesh
 n.position = p
 n.material_override = _material(c, glow, metal)
 add_child(n)
 detail_count += 1
 return n

func _box(p: Vector3, s: Vector3, c: Color, glow := false) -> MeshInstance3D:
 var mesh = BoxMesh.new()
 mesh.size = s
 return _node(mesh, p, c, glow)

func _sphere(p: Vector3, size: Vector3, c: Color, glow := false) -> MeshInstance3D:
 if sphere_low == null:
  sphere_low = SphereMesh.new()
  sphere_low.radius = 1.0
  sphere_low.height = 2.0
  sphere_low.radial_segments = 12
  sphere_low.rings = 6
 var n = _node(sphere_low, p, c, glow)
 n.scale = size
 return n

func _cone(p: Vector3, r: float, height: float, c: Color, up := 0.0) -> MeshInstance3D:
 var mesh = CylinderMesh.new()
 mesh.bottom_radius = r
 mesh.top_radius = up
 mesh.height = height
 mesh.radial_segments = 9
 return _node(mesh, p, c)

func _line(a: Vector3, b: Vector3, radius: float, col: Color, glow := false) -> void:
 var d = b - a
 if d.length() < 0.01:
  return
 var cyl = CylinderMesh.new()
 cyl.top_radius = radius
 cyl.bottom_radius = radius
 cyl.height = d.length()
 cyl.radial_segments = 7
 var n = _node(cyl, (a + b) * 0.5, col, glow)
 n.quaternion = Quaternion(Vector3.UP, d.normalized())

func _ring(pos: Vector3, r: float, c: Color, tilt: float = 0.0, glow := false) -> void:
 var torus = TorusMesh.new()
 torus.inner_radius = r * 0.88
 torus.outer_radius = r
 torus.ring_segments = 26
 torus.rings = 8
 var n = _node(torus, pos, c, glow, true)
 n.rotation.x = tilt

func _sign(label: String, p: Vector3, size := 72) -> void:
 var sign = Label3D.new()
 sign.text = label
 sign.font_size = size
 sign.pixel_size = 0.010
 sign.modulate = colors[2]
 sign.outline_modulate = Color("#26314b")
 sign.outline_size = 11
 sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 sign.position = p
 add_child(sign)

func _environment() -> void:
 var sky = WorldEnvironment.new()
 sky.environment = Environment.new()
 sky.environment.background_mode = Environment.BG_SKY
 var material = ProceduralSkyMaterial.new()
 match biome:
  1:
   material.sky_top_color = Color("#67b8ff")
   material.sky_horizon_color = Color("#c5f4ee")
   material.ground_horizon_color = Color("#95dab4")
   material.ground_bottom_color = Color("#6ab783")
  2:
   material.sky_top_color = Color("#6fb6ee")
   material.sky_horizon_color = Color("#ffdec1")
   material.ground_horizon_color = Color("#e7ab77")
   material.ground_bottom_color = Color("#d79067")
  3:
   material.sky_top_color = Color("#070f2b")
   material.sky_horizon_color = Color("#303368")
   material.ground_horizon_color = Color("#29255e")
   material.ground_bottom_color = Color("#111b3f")
 material.use_debanding = true
 var sk = Sky.new()
 sk.sky_material = material
 sky.environment.sky = sk
 sky.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 sky.environment.ambient_light_color = Color("#baf5f6") if biome == 3 else Color("#e7f6ee")
 sky.environment.ambient_light_energy = 0.78 if biome == 3 else 0.70
 sky.environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
 sky.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 add_child(sky)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-50, 25 if biome == 2 else -40, 0)
 sun.light_color = Color("#b7c4ff") if biome == 3 else Color("#fff1cc")
 sun.light_energy = 1.0 if biome == 3 else 1.65
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 105.0
 add_child(sun)
 var rim = DirectionalLight3D.new()
 rim.rotation_degrees = Vector3(28, 132, 0)
 rim.light_color = Color("#a7ccff") if biome == 3 else Color("#bcfff0")
 rim.light_energy = 0.45
 add_child(rim)

func _ground() -> void:
 match biome:
  1:
   _box(Vector3(0, -0.44, 0), Vector3(375, 0.7, 360), Color("#6ccc91"))
   for i in range(25):
    var a = TAU * float(i) / 25.0
    var rad = 120.0 + rng.randf_range(-12.0, 14.0)
    _sphere(Vector3(cos(a) * rad, 0.0, sin(a) * rad), Vector3(rng.randf_range(13, 25), rng.randf_range(4, 11), rng.randf_range(12, 21)), Color("#62ae90"))
   for i in range(13):
    var a = TAU * float(i) / 13.0
    _sphere(Vector3(cos(a) * 33, -0.06, sin(a) * 26), Vector3(7.0, 0.27, 6.4), Color("#7eda9d"))
  2:
   _box(Vector3(0, -0.45, 0), Vector3(390, 0.75, 360), Color("#f4cb81"))
   for i in range(32):
    var a = TAU * float(i) / 32.0
    var rad = 110.0 + rng.randf_range(-12.0, 26.0)
    _sphere(Vector3(cos(a) * rad, -1.0, sin(a) * rad), Vector3(rng.randf_range(10, 26), rng.randf_range(3, 8), rng.randf_range(13, 23)), Color("#e3ab6d") if i % 3 else Color("#ffd794"))
   for i in range(9):
    var a = TAU * float(i) / 9.0
    _sphere(Vector3(cos(a) * 32, 0.0, sin(a) * 25), Vector3(8, 0.20, 6), Color("#ffe2a4"))
  3:
   # An illuminated race platform above an alien planet and a distant nebula.
   _sphere(Vector3(0, -36.0, 0), Vector3(116, 26, 113), Color("#34437d"))
   _sphere(Vector3(0, -30.0, 0), Vector3(85, 14, 84), Color("#4c5297"))
   for i in range(20):
    var a = TAU * float(i) / 20.0
    var rad = 65.0 + rng.randf_range(2.0, 22.0)
    _sphere(Vector3(cos(a) * rad, -19.0, sin(a) * rad), Vector3(9, 1.4, 8), Color("#4e64a2"))
   _sphere(Vector3(-108, 61, -140), Vector3(34, 34, 34), Color("#dcadff"))
   _ring(Vector3(-108, 61, -140), 45.0, Color("#7be6f5"), 0.31, true)
   _sphere(Vector3(110, 55, -150), Vector3(19, 19, 19), Color("#ffd59c"))
   for n in range(100):
    var a = rng.randf_range(0.0, TAU)
    var distance = rng.randf_range(120.0, 250.0)
    var h = rng.randf_range(25.0, 110.0)
    _sphere(Vector3(cos(a) * distance, h, sin(a) * distance), Vector3.ONE * rng.randf_range(0.26, 0.62), Color("#dde9ff") if n % 4 else Color("#fcbdfd"), true)

func _road() -> void:
 var shoulder = [Color("#c7deab"), Color("#f7d2a1"), Color("#3c4c89")][biome - 1]
 var curb = [Color("#f7ffdf"), Color("#f9bb7f"), Color("#dd9bfa")][biome - 1]
 var asphalt = [Color("#405968"), Color("#875d63"), Color("#293459")][biome - 1]
 var stripe = [Color("#80ca9d"), Color("#ab7472"), Color("#4964a1")][biome - 1]
 course._ribbon(ROAD_HALF_WIDTH + 2.6, -0.05, shoulder)
 course._ribbon(ROAD_HALF_WIDTH + 1.25, 0.012, curb)
 course._ribbon(ROAD_HALF_WIDTH + 0.46, 0.049, asphalt)
 course._ribbon(ROAD_HALF_WIDTH - 0.25, 0.087, stripe)
 course._ribbon(ROAD_HALF_WIDTH - 2.70, 0.099, asphalt.lightened(0.10))
 for i in range(0, SEGMENT_COUNT, 3):
  var forward: Vector3 = course.direction(float(i))
  var heading: float = atan2(-forward.x, -forward.z)
  for side in [-1.0, 1.0]:
   var p: Vector3 = course.at(i, side * (ROAD_HALF_WIDTH + 0.9))
   var tiled = _box(Vector3(p.x, 0.124, p.z), Vector3(0.73, 0.072, 2.8), colors[2] if i % 6 == 0 else colors[4])
   tiled.rotation.y = heading
  var m: Vector3 = course.at(i, 0)
  if i % 2 == 0:
   var dash = _box(Vector3(m.x, 0.130, m.z), Vector3(0.26, 0.025, 2.0), Color("#fff3c3"), biome == 3)
   dash.rotation.y = heading
 for i in range(0, SEGMENT_COUNT, 6):
  for side in [-1.0, 1.0]:
   var p: Vector3 = course.at(i, side * (ROAD_HALF_WIDTH + 2.25))
   _box(Vector3(p.x, 0.94, p.z), Vector3(0.33, 1.88, 0.36), colors[1])
   _sphere(Vector3(p.x, 1.95, p.z), Vector3(0.24, 0.25, 0.24), colors[2], biome == 3)
   var next: Vector3 = course.at(i + 6, side * (ROAD_HALF_WIDTH + 2.25))
   _line(Vector3(p.x, 1.34, p.z), Vector3(next.x, 1.34, next.z), 0.105, colors[3], biome == 3)
 # Finish line, gantry, checker tiles, and illuminated race banner.
 var start: Vector3 = course.at(0)
 var start_forward: Vector3 = course.direction(0.0)
 var angle: float = atan2(-start_forward.x, -start_forward.z)
 var lateral = Vector3(-start_forward.z, 0, start_forward.x)
 for j in range(12):
  var p: Vector3 = start + lateral * ((float(j) - 5.5) * 1.38)
  var patch = _box(Vector3(p.x, 0.151, p.z), Vector3(1.33, 0.04, 0.95), Color("#f3f9f8") if j % 2 else Color("#253450"))
  patch.rotation.y = angle
 for side in [-1.0, 1.0]:
  var p: Vector3 = course.at(0, side * (ROAD_HALF_WIDTH + 2.5))
  _box(Vector3(p.x, 3.5, p.z), Vector3(0.8, 7.0, 0.8), colors[4])
  _sphere(Vector3(p.x, 7.1, p.z), Vector3.ONE * 0.66, colors[2], true)
 var lintel = _box(start + Vector3(0, 6.85, 0), Vector3(22.4, 1.20, 1.1), colors[1])
 lintel.rotation.y = angle
 _sign(NAMES[biome] + "  •  KART CUP", start + Vector3(0, 6.9, 0), 86)

func _districts() -> void:
 for n in range(23):
  var idx: float = float(n) * float(SEGMENT_COUNT) / 23.0 + 3.0
  var side = -1.0 if n % 2 == 0 else 1.0
  var distance = 21.0 + float(n % 3) * 5.0
  var p: Vector3 = course.sample(idx, side * distance)
  match biome:
   1:
    if n % 5 == 0: _windmill(p, 0.85 + (n % 3) * 0.25)
    elif n % 3 == 0: _farm_house(p, 0.90 + (n % 2) * 0.25)
    else: _fluffy_tree(p, 1.35 + (n % 4) * 0.24)
   2:
    if n % 5 == 0: _pyramid(p, 1.1 + (n % 3) * 0.20)
    elif n % 3 == 0: _oasis(p, 0.8 + (n % 2) * 0.20)
    else: _canyon(p, 0.95 + (n % 4) * 0.18)
   3:
    if n % 5 == 0: _observatory(p, 0.95 + (n % 3) * 0.18)
    elif n % 3 == 0: _space_station(p, 1.1)
    else: _asteroid_cluster(p, 1.2 + (n % 4) * 0.16)
  landmark_count += 1
 for i in range(4):
  var idx = 16.0 + i * 44.0
  var p: Vector3 = course.sample(idx, -1.0 * (ROAD_HALF_WIDTH + 9.8))
  _billboard(p, i)
  landmark_count += 1

func _fluffy_tree(p: Vector3, s: float) -> void:
 _cone(p + Vector3(0, s * 1.45, 0), s * 0.42, s * 2.9, Color("#8c6d55"), s * 0.34)
 for j in range(5):
  var a = float(j) * TAU / 5.0
  _sphere(p + Vector3(cos(a) * s * 1.3, 3.6 * s + sin(a) * s * 0.25, sin(a) * s * 1.10), Vector3(1.55, 1.36, 1.50) * s, [Color("#77d6a4"), Color("#9ee7b6"), Color("#c3eaa0")][j % 3])
 _sphere(p + Vector3(0, s * 4.5, 0), Vector3(1.65, 1.45, 1.7) * s, Color("#8ae0ac"))
 for j in range(4):
  var a = float(j) * TAU / 4.0
  _sphere(p + Vector3(cos(a) * s * 1.4, 3.2 * s, sin(a) * s * 1.3), Vector3.ONE * s * 0.18, Color("#ffd99c"), true)

func _farm_house(p: Vector3, s: float) -> void:
 _box(p + Vector3(0, 2.0 * s, 0), Vector3(6.8, 4.0, 5.1) * s, Color("#fae9c6"))
 var roof = _cone(p + Vector3(0, 5.25 * s, 0), 4.15 * s, 2.5 * s, Color("#f3a7a7"))
 roof.rotation.y = PI / 4.0
 for side in [-1.0, 1.0]:
  _box(p + Vector3(side * 1.9 * s, 2.6 * s, -2.68 * s), Vector3(1.2, 1.5, 0.16) * s, Color("#a4f1ff"), true)
 _box(p + Vector3(0, 1.0 * s, -2.69 * s), Vector3(1.28, 2.0, 0.15) * s, Color("#bc8170"))
 for j in range(4):
  _box(p + Vector3(-3.3 * s + j * 2.2 * s, 0.35 * s, -5.0 * s), Vector3(0.16, 0.75, 0.15) * s, Color("#f1e1a7"))
 _sign("MEADOW FARM", p + Vector3(0, 4.05 * s, -2.98 * s), 64)

func _windmill(p: Vector3, s: float) -> void:
 _cone(p + Vector3(0, 4.7 * s, 0), 1.52 * s, 9.1 * s, Color("#f7e6d5"), 0.9 * s)
 _cone(p + Vector3(0, 9.8 * s, 0), 1.8 * s, 2.6 * s, Color("#b487ad"))
 _sphere(p + Vector3(0, 7.9 * s, -1.30 * s), Vector3.ONE * 0.63 * s, Color("#f5d489"))
 for i in range(4):
  var a = float(i) * TAU / 4.0
  var center = p + Vector3(0, 7.9 * s, -1.48 * s)
  var tip = center + Vector3(cos(a) * 3.4 * s, sin(a) * 3.4 * s, 0)
  _line(center, tip, 0.18 * s, Color("#dfc8a7"))
  _box(tip, Vector3(1.1, 1.1, 0.22) * s, Color("#f9efcd"))
 _sign("WINDY HILL", p + Vector3(0, 4.3 * s, -1.72 * s), 60)

func _pyramid(p: Vector3, s: float) -> void:
 _box(p + Vector3(0, 0.33 * s, 0), Vector3(12.0, 0.64, 12.0) * s, Color("#d79b63"))
 for n in range(5):
  var w = (9.0 - n * 1.5) * s
  _box(p + Vector3(0, (n + 1) * 0.91 * s, 0), Vector3(w, 0.9 * s, w), [Color("#dca572"), Color("#efbc80")][n % 2])
 _cone(p + Vector3(0, 6.2 * s, 0), 1.5 * s, 2.8 * s, Color("#fff0b4"))
 for j in range(4):
  var angle = float(j) * TAU / 4.0
  _cone(p + Vector3(cos(angle) * 7.5 * s, 1.7 * s, sin(angle) * 7.5 * s), 0.7 * s, 3.4 * s, Color("#bd8567"))
 _sign("SUN TEMPLE", p + Vector3(0, 4.0 * s, -4.7 * s), 63)

func _canyon(p: Vector3, s: float) -> void:
 for n in range(3):
  var x = (n - 1) * 2.6 * s
  var h = (3.0 + (n % 3) * 1.5) * s
  for tier in range(3):
   _box(p + Vector3(x, (tier + 0.5) * h / 3.0, n * 0.8 * s), Vector3((3.3 - tier * 0.3) * s, h / 3.0, 3.3 * s), Color("#cc8360") if (n + tier) % 2 else Color("#e8a276"))
  _cone(p + Vector3(x, h + 0.45 * s, n * 0.8 * s), 1.7 * s, 0.9 * s, Color("#eab783"))
 for side in [-1.0, 1.0]:
  _box(p + Vector3(side * 4.0 * s, 0.25 * s, -1.5 * s), Vector3(2.3, 0.5, 1.1) * s, Color("#be8163"))

func _oasis(p: Vector3, s: float) -> void:
 _sphere(p, Vector3(6, 0.23, 4.5) * s, Color("#88dad0"), true)
 _sphere(p + Vector3(0, -0.1 * s, 0), Vector3(4.7, 0.17, 3.5) * s, Color("#a0f2e1"), true)
 for j in range(4):
  var a = float(j) * TAU / 4.0
  var q = p + Vector3(cos(a) * 5.4 * s, 0, sin(a) * 4.4 * s)
  _line(q, q + Vector3(cos(a) * 0.5 * s, 4.2 * s, sin(a) * 0.5 * s), 0.21 * s, Color("#ae825a"))
  for k in range(5):
   var ang = float(k) * TAU / 5.0
   _line(q + Vector3(0, 4.1 * s, 0), q + Vector3(cos(ang) * 2.0 * s, 3.2 * s, sin(ang) * 2.0 * s), 0.26 * s, Color("#60aa80"))
 _sign("OASIS", p + Vector3(0, 6.5 * s, 0), 64)

func _observatory(p: Vector3, s: float) -> void:
 _box(p + Vector3(0, 2.0 * s, 0), Vector3(7.5, 4.0, 7.5) * s, Color("#5867a4"))
 _sphere(p + Vector3(0, 4.1 * s, 0), Vector3(4.4, 3.0, 4.4) * s, Color("#8197de"), true)
 _ring(p + Vector3(0, 4.7 * s, 0), 4.9 * s, Color("#a3f4ff"), 0.23, true)
 for side in [-1.0, 1.0]:
  _cone(p + Vector3(side * 3.0 * s, 1.8 * s, -2.6 * s), 0.48 * s, 3.6 * s, Color("#91d9f2"))
  _sphere(p + Vector3(side * 3.0 * s, 3.7 * s, -2.6 * s), Vector3.ONE * 0.48 * s, colors[4], true)
 _sign("OBSERVATORY", p + Vector3(0, 2.5 * s, -4.0 * s), 56)

func _space_station(p: Vector3, s: float) -> void:
 _sphere(p + Vector3(0, 4.6 * s, 0), Vector3(3.8, 2.2, 3.8) * s, Color("#d0cafa"), true)
 _ring(p + Vector3(0, 4.5 * s, 0), 5.1 * s, Color("#8feeff"), 0.5, true)
 for side in [-1.0, 1.0]:
  _box(p + Vector3(side * 5.7 * s, 4.5 * s, 0), Vector3(5.2, 0.26, 3.5) * s, Color("#5274c6"))
  for j in range(3):
   _box(p + Vector3(side * 5.7 * s, 4.74 * s, (j - 1) * 0.95 * s), Vector3(4.8, 0.06, 0.10) * s, colors[2], true)
  _line(p + Vector3(side * 2.6 * s, 4.5 * s, 0), p + Vector3(side * 4.5 * s, 4.5 * s, 0), 0.22 * s, colors[4])
 _sphere(p + Vector3(0, 4.3 * s, -3.2 * s), Vector3(0.85, 0.7, 0.75) * s, colors[4], true)

func _asteroid_cluster(p: Vector3, s: float) -> void:
 for j in range(5):
  var a = TAU * float(j) / 5.0
  var q = p + Vector3(cos(a) * 2.9 * s, 2.2 * s + (j % 3) * 1.1 * s, sin(a) * 2.7 * s)
  _sphere(q, Vector3(1.20 + (j % 2) * 0.35, 0.8, 0.95) * s, Color("#7778ae") if j % 2 else Color("#b3a0d7"))
  _sphere(q + Vector3(-0.3 * s, 0.45 * s, -0.2 * s), Vector3.ONE * 0.15 * s, Color("#d7cefa"), true)

func _billboard(p: Vector3, index: int) -> void:
 var tint = colors[4] if index % 2 else colors[2]
 _box(p + Vector3(0, 2.1, 0), Vector3(6.5, 3.3, 0.45), colors[1])
 _box(p + Vector3(0, 2.1, -0.28), Vector3(6.0, 2.9, 0.13), colors[0])
 _box(p + Vector3(0, 3.85, -0.33), Vector3(6.65, 0.13, 0.13), tint, true)
 for side in [-1.0, 1.0]:
  _box(p + Vector3(side * 2.6, 0.5, 0), Vector3(0.33, 1.1, 0.33), colors[1])
 var words = ["GO GO GO!", "MONSTER CUP", "TURBO!", "3D KART"]
 _sign(words[index], p + Vector3(0, 2.1, -0.37), 59)

func _small_details() -> void:
 for i in range(0, SEGMENT_COUNT, 7):
  var ix: float = float(i)
  var direction: Vector3 = course.direction(ix)
  for side in [-1.0, 1.0]:
   var p: Vector3 = course.sample(ix, side * 11.5)
   if biome == 1:
    # Wooden protective posts, grass tuft and floral marker.
    _cone(p + Vector3(0, 0.5, 0), 0.22, 1.0, Color("#eed8a3"))
    _sphere(p + Vector3(0.32, 0.20, 0), Vector3(0.45, 0.35, 0.42), Color("#56bd85"))
    _sphere(p + Vector3(0.35, 0.49, 0), Vector3.ONE * 0.16, Color("#fff4b4"), true)
   elif biome == 2:
    # Sandstone ribs and cacti with arms.
    _sphere(p + Vector3(0, 0.3, 0), Vector3(1.35, 0.40, 1.25), Color("#e3a875"))
    _line(p, p + Vector3(0, 2.45, 0), 0.34, Color("#64ad83"))
    _line(p + Vector3(0, 1.0, 0), p + Vector3(side * 0.85, 1.45, 0), 0.25, Color("#78c18b"))
    _line(p + Vector3(side * 0.85, 1.45, 0), p + Vector3(side * 0.85, 1.95, 0), 0.21, Color("#78c18b"))
   else:
    # Neon beacons: they make the space track readable in the dark.
    _box(p + Vector3(0, 1.0, 0), Vector3(0.48, 2.0, 0.52), colors[1])
    _sphere(p + Vector3(0, 2.16, 0), Vector3.ONE * 0.36, colors[2], true)
  var p2: Vector3 = course.sample(ix + 3.0)
  if biome == 3 and i % 14 == 0:
   _ring(p2 + Vector3(0, 0.22, 0), 2.6, colors[2], PI / 2.0, true)

func _scatter() -> void:
 # Four draw calls / biome. Per-instance colors for meadow flowers, dunes and stars.
 if instance_mesh == null:
  instance_mesh = SphereMesh.new()
  instance_mesh.radius = 0.25
  instance_mesh.height = 0.5
  instance_mesh.radial_segments = 6
  instance_mesh.rings = 3
 for batch in range(4):
  var mesh = MultiMesh.new()
  mesh.transform_format = MultiMesh.TRANSFORM_3D
  mesh.use_colors = true
  mesh.mesh = instance_mesh
  mesh.instance_count = 210
  for j in range(210):
   var index = rng.randf_range(0.0, float(SEGMENT_COUNT))
   var dist = rng.randf_range(13.8, 42.0)
   var side = -1.0 if rng.randf() < 0.5 else 1.0
   var p: Vector3 = course.sample(index, side * dist)
   var s = rng.randf_range(0.3, 0.9)
   var h = 0.27
   if biome == 3:
    h = rng.randf_range(-3.5, 3.0)
    s *= 1.5
   mesh.set_instance_transform(j, Transform3D(Basis().scaled(Vector3(s, s * 1.2, s)), Vector3(p.x, h, p.z)))
   var palette: Array[Color]
   match biome:
    1: palette = [Color("#ffb8e1"), Color("#fff4b4"), Color("#bbf3e5"), Color("#92dcb7")]
    2: palette = [Color("#e5a56e"), Color("#ffe0a1"), Color("#f5c786"), Color("#d99878")]
    _: palette = [Color("#94d8ff"), Color("#cdb6ff"), Color("#ffe7a9"), Color("#fbb4e8")]
   mesh.set_instance_color(j, palette[batch % 4])
  var display = MultiMeshInstance3D.new()
  display.multimesh = mesh
  var mat = _material(Color.WHITE, biome == 3)
  mat.vertex_color_use_as_albedo = true
  display.material_override = mat
  add_child(display)
  scatter_count += 210
