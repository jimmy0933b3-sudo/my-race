extends Node3D
## A second art pass for the circuit: architectural silhouettes, biome-specific
## landmarks and instanced groundcover. Pure procedural 3D, no asset downloads.
const TINTS = [
 Color("#ff80b5"), Color("#7de5b0"),
 Color("#83c0fa"), Color("#ffd07b")
]
var track
var rng := RandomNumberGenerator.new()
var materials: Dictionary = {}
var scene_root: Node3D
var landmark_count := 0
var plant_instances := 0

func decorate(race_track: Node3D) -> void:
 track = race_track
 name = "MonsterWorldDeluxe"
 rng.seed = 278422
 _paint_landscape()
 for zone in range(4):
  _build_district(zone)
 _build_stadium()
 _roadside_accents()

func _mat(c: Color, shiny := false, glow := false, translucent := false) -> StandardMaterial3D:
 var key = "%s-%s-%s-%s" % [c.to_html(true), str(shiny), str(glow), str(translucent)]
 if materials.has(key):
  return materials[key]
 var mat = StandardMaterial3D.new()
 mat.albedo_color = c
 mat.metallic = 0.25 if shiny else 0.0
 mat.roughness = 0.21 if shiny else 0.77
 if shiny:
  mat.clearcoat_enabled = true
  mat.clearcoat = 0.58
 if glow:
  mat.emission_enabled = true
  mat.emission = c
  mat.emission_energy_multiplier = 1.35
 if translucent:
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 materials[key] = mat
 return mat

func _shape(mesh: Mesh, p: Vector3, col: Color, shine := false, glow := false, parent: Node3D = null) -> MeshInstance3D:
 var n = MeshInstance3D.new()
 n.mesh = mesh
 n.position = p
 n.material_override = _mat(col, shine, glow)
 if parent == null:
  scene_root.add_child(n)
 else:
  parent.add_child(n)
 return n

func _box(p: Vector3, sz: Vector3, c: Color, shine := false, glow := false) -> MeshInstance3D:
 var box = BoxMesh.new()
 box.size = sz
 return _shape(box, p, c, shine, glow)

func _orb(p: Vector3, r: Vector3, c: Color, shine := false, glow := false) -> MeshInstance3D:
 var sphere = SphereMesh.new()
 sphere.radius = 1.0
 sphere.height = 2.0
 sphere.radial_segments = 12
 sphere.rings = 7
 var n = _shape(sphere, p, c, shine, glow)
 n.scale = r
 return n

func _cone(p: Vector3, radius: float, height: float, col: Color) -> MeshInstance3D:
 var cylinder = CylinderMesh.new()
 cylinder.top_radius = 0.0
 cylinder.bottom_radius = radius
 cylinder.height = height
 cylinder.radial_segments = 10
 return _shape(cylinder, p, col)

func _beam(a: Vector3, b: Vector3, radius: float, col: Color, glow := false) -> MeshInstance3D:
 var direction = b - a
 var cylinder = CylinderMesh.new()
 cylinder.top_radius = radius
 cylinder.bottom_radius = radius
 cylinder.height = maxf(0.04, direction.length())
 cylinder.radial_segments = 8
 var mesh = _shape(cylinder, (a + b) * 0.5, col, false, glow)
 mesh.quaternion = Quaternion(Vector3.UP, direction.normalized())
 return mesh

func _label(message: String, at: Vector3, width: int = 65, color: Color = Color("#fffde8")) -> void:
 var sign = Label3D.new()
 sign.text = message
 sign.font_size = width
 sign.pixel_size = 0.011
 sign.modulate = color
 sign.outline_modulate = Color("#26324c")
 sign.outline_size = 11
 sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 sign.position = at
 scene_root.add_child(sign)

func _place(index: float, side: float, distance := 20.0, spin := 0.0) -> void:
 scene_root = Node3D.new()
 var p: Vector3 = track.sample(index, side * distance)
 scene_root.position = Vector3(p.x, 0.07, p.z)
 var tangent: Vector3 = track.direction(index)
 scene_root.rotation.y = atan2(-tangent.x, -tangent.z) + spin
 add_child(scene_root)
 landmark_count += 1

func _build_district(zone: int) -> void:
 var start = 19.0 + float(zone) * 43.0
 # City scale raises as the car approaches. All scenery stays outside the road.
 for n in range(8):
  var at_index = start - 8.0 + float(n) * 4.8
  var scale_f = 0.75 + (n % 3) * 0.14
  for side in [-1.0, 1.0]:
   _place(at_index, side, 17.5 + (n % 2) * 6.5, 0.12 * float(n % 3))
   match zone:
    0: _candy_shop(scale_f) if n % 2 == 0 else _ice_palace(scale_f)
    1: _tree_house(scale_f) if n % 2 == 0 else _giant_fungi(scale_f)
    2: _moon_falls(scale_f) if n % 2 == 0 else _constellation_gate(scale_f)
    3: _monster_tower(scale_f, n) if n % 2 == 0 else _neon_rocket(scale_f)
 # Massive landmarks provide a silhouette visible across the map.
 _place(start + 12.0, 1.0, 34.0)
 match zone:
  0: _ice_palace(2.1)
  1: _tree_house(2.2)
  2: _moon_falls(2.0)
  3: _monster_tower(2.2, 2)

func _candy_shop(s: float) -> void:
 # Strawberry bakery with icing, candy awning, shop front and glowing windows.
 _box(Vector3(0, s * 2.2, 0), Vector3(6.1, 4.4, 5.4) * s, Color("#fff0d8"))
 _box(Vector3(0, 4.4 * s, 0), Vector3(6.85, 0.34, 6.15) * s, Color("#f58bb9"))
 _orb(Vector3(0, 4.85 * s, 0), Vector3(3.38, 1.4, 3.06) * s, Color("#fbc5d9"))
 _orb(Vector3(0, 5.05 * s, 0), Vector3(2.67, 0.90, 2.38) * s, Color("#ff8ea9"))
 _orb(Vector3(0, 6.10 * s, -0.7 * s), Vector3(0.65, 0.65, 0.65) * s, Color("#d85976"), true)
 for side in [-1.0, 1.0]:
  _box(Vector3(side * 1.85 * s, 2.55 * s, -2.78 * s), Vector3(1.30, 1.70, 0.16) * s, Color("#8fe8ed"), true, true)
  _box(Vector3(side * 1.85 * s, 2.50 * s, -2.90 * s), Vector3(0.13, 1.67, 0.12) * s, Color("#fffefa"))
  _orb(Vector3(side * 2.42 * s, 0.46 * s, -2.45 * s), Vector3(0.51, 0.52, 0.51) * s, Color("#ffe88c"))
 _box(Vector3(0, 1.12 * s, -2.75 * s), Vector3(1.1, 2.20, 0.25) * s, Color("#a76c9d"))
 _box(Vector3(0, 0.24 * s, -3.17 * s), Vector3(3.4, 0.35, 1.05) * s, Color("#ffffff"))
 _label("SWEET SHOP", Vector3(0, 3.82 * s, -3.10 * s), 70)

func _ice_palace(s: float) -> void:
 # Soft serve spiral spires and striped sweet towers.
 for side in [-1.0, 1.0]:
  _box(Vector3(side * 2.2 * s, 2.4 * s, 0), Vector3(2.05, 4.8, 2.15) * s, Color("#f9d5f2"))
  for stripe in range(5):
   _box(Vector3(side * 2.2 * s, (0.9 + stripe * 0.79) * s, 0), Vector3(2.18, 0.21, 2.28) * s, Color("#ff91c1"))
  _cone(Vector3(side * 2.2 * s, 5.7 * s, 0), 1.35 * s, 2.4 * s, Color("#c9a5fd"))
 _box(Vector3(0, 2.3 * s, 0), Vector3(4.2, 4.6, 3.9) * s, Color("#ffefcd"))
 _orb(Vector3(0, 4.9 * s, 0), Vector3(2.5, 1.0, 2.45) * s, Color("#ff83a9"))
 _cone(Vector3(0, 6.0 * s, 0), 1.35 * s, 2.6 * s, Color("#fff0ca"))
 for n in range(8):
  var a = TAU * float(n) / 8.0
  _orb(Vector3(cos(a) * 1.9, 5.35 * s, sin(a) * 1.85) * s, Vector3.ONE * 0.40 * s, Color("#ffe3a0"))
 _label("CANDYLAND", Vector3(0, 3.1 * s, -2.2 * s), 88)

func _tree_house(s: float) -> void:
 # Giant canopy clusters, hanging star lanterns and cozy treetop room.
 _cone(Vector3(0, 3.05 * s, 0), 1.65 * s, 6.0 * s, Color("#87645e"))
 _orb(Vector3(0, 8.1 * s, 0), Vector3(4.2, 2.6, 3.7) * s, Color("#6ecda2"))
 _orb(Vector3(-2.1 * s, 7.4 * s, 0.6 * s), Vector3(2.65, 2.1, 2.8) * s, Color("#8ce4b5"))
 _orb(Vector3(2.2 * s, 7.8 * s, 0.3 * s), Vector3(2.8, 2.2, 2.65) * s, Color("#9de6c3"))
 _box(Vector3(0, 5.4 * s, -1.2 * s), Vector3(3.1, 2.2, 2.8) * s, Color("#ffdfb0"))
 _cone(Vector3(0, 7.0 * s, -1.2 * s), 2.6 * s, 1.75 * s, Color("#d585ba"))
 _orb(Vector3(0, 5.5 * s, -2.67 * s), Vector3(0.56, 0.62, 0.19) * s, Color("#e6faff"), true, true)
 for side in [-1.0, 1.0]:
  _beam(Vector3(side * 3.1 * s, 7.9 * s, -0.8 * s), Vector3(side * 3.1 * s, 5.4 * s, -0.8 * s), 0.06 * s, Color("#f5dbb9"))
  _orb(Vector3(side * 3.1 * s, 5.12 * s, -0.8 * s), Vector3.ONE * 0.32 * s, Color("#ffeea2"), false, true)
 _label("TREE CLUB", Vector3(0, 3.95 * s, -2.75 * s), 57)

func _giant_fungi(s: float) -> void:
 # A grove of highly legible oversized spotted mushrooms.
 for n in range(3):
  var x = (n - 1) * 2.9 * s
  var h = (2.0 + float((n + 1) % 3) * 0.7) * s
  _cone(Vector3(x, h * 0.54, 0), 0.55 * s, h, Color("#fff1d5"))
  var cap = Color("#f8a1c2") if n % 2 == 0 else Color("#9c8ff1")
  _orb(Vector3(x, h, 0), Vector3(1.6, 0.72, 1.55) * s, cap)
  for dot in range(4):
   var a = float(dot) * TAU / 4.0
   _orb(Vector3(x + cos(a) * 0.87 * s, h + 0.5 * s, sin(a) * 0.88 * s), Vector3(0.26, 0.12, 0.26) * s, Color("#fff4db"))
  _orb(Vector3(x - 0.23 * s, 0.8 * s, -0.42 * s), Vector3(0.16, 0.21, 0.06) * s, Color("#303a58"))
  _orb(Vector3(x + 0.23 * s, 0.8 * s, -0.42 * s), Vector3(0.16, 0.21, 0.06) * s, Color("#303a58"))
  _orb(Vector3(x, 0.53 * s, -0.46 * s), Vector3(0.20, 0.08, 0.04) * s, Color("#e67899"))

func _moon_falls(s: float) -> void:
 # Tiered crystal aqueduct, luminous turquoise lagoon and waterfall curtains.
 var water = CylinderMesh.new()
 water.top_radius = 7.5 * s
 water.bottom_radius = 7.5 * s
 water.height = 0.15
 water.radial_segments = 30
 _shape(water, Vector3(0, 0.05, 0), Color("#6ddde7"), true, true)
 _box(Vector3(0, 3.15 * s, 0.9 * s), Vector3(6.8, 6.3, 3.0) * s, Color("#819dbd"))
 _box(Vector3(0, 6.3 * s, 0.9 * s), Vector3(7.6, 0.48, 3.9) * s, Color("#afd3eb"))
 _box(Vector3(0, 4.35 * s, -0.75 * s), Vector3(4.5, 3.75, 0.33) * s, Color("#95f0f4"), true, true)
 for side in [-1.0, 1.0]:
  _box(Vector3(side * 2.4 * s, 2.4 * s, -0.9 * s), Vector3(0.20, 4.2, 0.22) * s, Color("#e2ffff"), false, true)
  _cone(Vector3(side * 3.55 * s, 7.5 * s, 0), 1.0 * s, 3.9 * s, Color("#a2bfff"))
  _orb(Vector3(side * 3.55 * s, 9.5 * s, 0), Vector3.ONE * 0.40 * s, Color("#dfffff"), false, true)
 for n in range(6):
  var a = float(n) * TAU / 6.0
  _orb(Vector3(cos(a) * 5.2 * s, 0.45 * s, sin(a) * 4.5 * s), Vector3(0.25, 0.45, 0.25) * s, Color("#f0fdff"), false, true)
 _label("MOON FALLS", Vector3(0, 6.85 * s, -1.18 * s), 72)

func _constellation_gate(s: float) -> void:
 # Floating orbital rings are a striking shortcut to fantasy scale.
 for side in [-1.0, 1.0]:
  _cone(Vector3(side * 2.8 * s, 3.0 * s, 0), 0.95 * s, 5.9 * s, Color("#7486ce"))
  _orb(Vector3(side * 2.8 * s, 6.5 * s, 0), Vector3.ONE * 0.52 * s, Color("#b1faff"), false, true)
 var ring = TorusMesh.new()
 ring.inner_radius = 2.1 * s
 ring.outer_radius = 2.5 * s
 ring.ring_segments = 24
 ring.rings = 7
 var view = _shape(ring, Vector3(0, 6.0 * s, 0), Color("#a7ebff"), true, true)
 view.rotation.x = PI * 0.32
 _orb(Vector3(0, 6.4 * s, 0), Vector3.ONE * 1.2 * s, Color("#d5b8f8"), true, true)
 for n in range(5):
  var a = TAU * float(n) / 5.0
  _orb(Vector3(cos(a) * 2.7 * s, (6.0 + sin(a) * 1.7) * s, sin(a) * 1.1 * s), Vector3.ONE * 0.24 * s, Color("#fffbd3"), false, true)

func _monster_tower(s: float, n: int) -> void:
 # Pastel skyline with stepped roofs, glowing floors, ears and expressive face.
 var color = [Color("#84b6ea"), Color("#e5a3ca"), Color("#9adaac")][n % 3]
 _box(Vector3(0, 4.7 * s, 0), Vector3(4.5, 9.4, 4.5) * s, color)
 for h in range(1, 7):
  _box(Vector3(0, h * 1.28 * s, -2.34 * s), Vector3(4.05, 0.12, 0.18) * s, Color("#f9dfae"), false, true)
  for side in [-1.0, 1.0]:
   _box(Vector3(side * 1.2 * s, (h * 1.28 + 0.48) * s, -2.36 * s), Vector3(0.75, 0.76, 0.13) * s, Color("#d7faff"), true, true)
 _box(Vector3(0, 9.6 * s, 0), Vector3(5.0, 0.58, 5.0) * s, Color("#ffdc9d"))
 for side in [-1.0, 1.0]:
  _cone(Vector3(side * 1.50 * s, 10.95 * s, 0), 0.76 * s, 2.10 * s, Color("#ff9dbb"))
  _orb(Vector3(side * 0.75 * s, 7.05 * s, -2.5 * s), Vector3(0.35, 0.44, 0.14) * s, Color("#273454"))
 _orb(Vector3(0, 6.0 * s, -2.53 * s), Vector3(0.40, 0.16, 0.12) * s, Color("#fff2d6"))
 _label("MONSTER INC", Vector3(0, 4.60 * s, -2.55 * s), 68)

func _neon_rocket(s: float) -> void:
 # Retro-futurist robot fuel station with towering color tubes.
 _box(Vector3(0, 1.9 * s, 0), Vector3(6.1, 3.8, 5.6) * s, Color("#50678d"))
 _box(Vector3(0, 3.9 * s, 0), Vector3(6.7, 0.45, 6.2) * s, Color("#89e7e6"), true, true)
 for side in [-1.0, 1.0]:
  _box(Vector3(side * 1.75 * s, 2.17 * s, -2.91 * s), Vector3(1.2, 1.9, 0.20) * s, Color("#92caff"), true, true)
  _cone(Vector3(side * 2.12 * s, 6.2 * s, 0.3 * s), 0.96 * s, 4.0 * s, Color("#fa8fb2"))
  _orb(Vector3(side * 2.12 * s, 8.2 * s, 0.3 * s), Vector3(0.44, 0.62, 0.44) * s, Color("#f8ea9b"), false, true)
 _label("TURBO PIT", Vector3(0, 4.6 * s, -3.0 * s), 68)

func _build_stadium() -> void:
 # The central festival is a landmark, rather than a lonely cube.
 scene_root = Node3D.new()
 scene_root.position = Vector3(0, 0.1, 0)
 add_child(scene_root)
 _box(Vector3(0, 0.82, 0), Vector3(17, 1.1, 17), Color("#ffdd9a"))
 for n in range(12):
  var a = TAU * float(n) / 12.0
  _orb(Vector3(cos(a) * 8.4, 1.55, sin(a) * 8.4), Vector3(0.55, 0.55, 0.55), Color("#ff96b1"), true, true)
 for side in [-1.0, 1.0]:
  _cone(Vector3(side * 9.0, 7.5, 0), 1.5, 12.3, Color("#9c82ea"))
  _orb(Vector3(side * 9.0, 13.7, 0), Vector3(1.22, 1.2, 1.22), Color("#fff6b9"), false, true)
 _label("MONSTER KART", Vector3(0, 7.8, -7.15), 132, Color("#ffdb8d"))
 for n in range(6):
  var a = TAU * float(n) / 6.0
  var origin = Vector3(cos(a) * 22.0, 1.1, sin(a) * 17.0)
  _orb(origin, Vector3(1.25, 1.25, 1.25), TINTS[n % 4], true, true)
  _cone(origin + Vector3(0, 1.6, 0), 0.45, 1.55, Color("#f7ecff"))
 _scatter_groundcover()

func _roadside_accents() -> void:
 for n in range(12):
  var progress = 6.0 + n * 14.5
  _place(progress, -1.0 if n % 2 == 0 else 1.0, 12.9)
  # Decorative race-direction billboards with curved-looking lighting bars.
  var c = TINTS[(n / 3) % 4]
  _box(Vector3(0, 1.85, 0), Vector3(4.9, 2.9, 0.36), Color("#2b3a5b"))
  _box(Vector3(0, 1.90, -0.21), Vector3(4.50, 2.44, 0.14), c, true)
  _box(Vector3(0, 3.50, -0.24), Vector3(4.85, 0.17, 0.16), Color("#fff1c4"), false, true)
  for side in [-1.0, 1.0]:
   _box(Vector3(side * 2.1, 0.55, 0.2), Vector3(0.29, 1.2, 0.34), Color("#f8e4bf"))
  _label(["GO! GO!", "★ BOOST ★", "KART CUP", "MONSTER!"][n % 4], Vector3(0, 1.82, -0.41), 48)

func _scatter_groundcover() -> void:
 # Hundreds of flowers / fireflies / grass dots use only four draw calls.
 var ico = SphereMesh.new()
 ico.radius = 0.22
 ico.height = 0.44
 ico.radial_segments = 6
 ico.rings = 3
 for biome in range(4):
  var instances = MultiMesh.new()
  instances.transform_format = MultiMesh.TRANSFORM_3D
  instances.use_colors = true
  instances.mesh = ico
  var n = 210
  instances.instance_count = n
  for i in range(n):
   var t = 14.0 + float(biome) * 43.0 + rng.randf_range(0.0, 42.0)
   var dist = rng.randf_range(13.0, 42.0)
   var side = -1.0 if rng.randf() < 0.5 else 1.0
   var p: Vector3 = track.sample(t, side * dist)
   var size = rng.randf_range(0.25, 0.75)
   var elevated = 0.45 if biome == 2 else 0.10
   var transform = Transform3D(Basis().scaled(Vector3(size, size * 1.2, size)), Vector3(p.x, elevated, p.z))
   instances.set_instance_transform(i, transform)
   var palette: Array[Color]
   match biome:
    0: palette = [Color("#ffb4d1"), Color("#ffe99d"), Color("#ff89b2")]
    1: palette = [Color("#a5fbdb"), Color("#ddff9d"), Color("#ffd6ff")]
    2: palette = [Color("#7ee8ff"), Color("#c9adf9"), Color("#eafaff")]
    _: palette = [Color("#ffe38b"), Color("#ffb7a0"), Color("#90def8")]
   instances.set_instance_color(i, palette[i % palette.size()])
  var display = MultiMeshInstance3D.new()
  display.multimesh = instances
  var mat = _mat(Color.WHITE, false, biome == 2)
  mat.vertex_color_use_as_albedo = true
  display.material_override = mat
  add_child(display)
  plant_instances += n
