extends Node3D
## Premium art layer for the 12 original monster racers. All geometry is original
## and deliberately light enough for the Android GL Compatibility renderer.
var coat: Color
var accent: Color
var dark: Color
var pearl := Color("#fdf9ef")
var graphite := Color("#28354d")
var materials: Dictionary = {}
var detail_count := 0
var animated_bits: Array[Node3D] = []
var wheels: Array[Node3D] = []

func decorate(index: int, primary: Color, secondary: Color, wheel_pivots: Array[Node3D]) -> void:
 coat = primary
 accent = secondary
 dark = primary.darkened(0.39)
 wheels = wheel_pivots
 name = "HandcraftedMonsterDetails"
 _paintwork(index)
 _wheels()
 _face(index)
 _species(index)
 _racing_accessories(index)

func _mat(c: Color, metallic := 0.0, glow := false, translucent := false) -> StandardMaterial3D:
 var id = "%s/%.1f/%s/%s" % [c.to_html(true), metallic, str(glow), str(translucent)]
 if materials.has(id):
  return materials[id]
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.metallic = metallic
 m.roughness = 0.27 if metallic > 0.3 else 0.46
 m.clearcoat_enabled = metallic > 0.05
 m.clearcoat = 0.8
 if glow:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = 1.6
 if translucent:
  m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
 materials[id] = m
 return m

func _shape(mesh: Mesh, p: Vector3, c: Color, metal := 0.0, glow := false, parent: Node3D = null, glass := false) -> MeshInstance3D:
 var view = MeshInstance3D.new()
 view.mesh = mesh
 view.position = p
 view.material_override = _mat(c, metal, glow, glass)
 if parent == null:
  add_child(view)
 else:
  parent.add_child(view)
 detail_count += 1
 return view

func _box(p: Vector3, s: Vector3, c: Color, metal := 0.0, glow := false, parent: Node3D = null) -> MeshInstance3D:
 var mesh = BoxMesh.new()
 mesh.size = s
 return _shape(mesh, p, c, metal, glow, parent)

func _orb(p: Vector3, r: Vector3, c: Color, glow := false, glass := false) -> MeshInstance3D:
 var mesh = SphereMesh.new()
 mesh.radius = 1.0
 mesh.height = 2.0
 mesh.radial_segments = 16
 mesh.rings = 8
 var view = _shape(mesh, p, c, 0.0, glow, null, glass)
 view.scale = r
 return view

func _spike(p: Vector3, radius: float, height: float, c: Color, tilt: float = 0.0) -> MeshInstance3D:
 var mesh = CylinderMesh.new()
 mesh.top_radius = 0.0
 mesh.bottom_radius = radius
 mesh.height = height
 mesh.radial_segments = 8
 var view = _shape(mesh, p, c)
 view.rotation.z = tilt
 return view

func _pipe(a: Vector3, b: Vector3, radius: float, c: Color, glow := false) -> MeshInstance3D:
 var diff = b - a
 var mesh = CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = maxf(diff.length(), 0.05)
 mesh.radial_segments = 9
 var view = _shape(mesh, (a + b) * 0.5, c, 0.0, glow)
 view.quaternion = Quaternion(Vector3.UP, diff.normalized())
 return view

func _petal(points: Array[Vector3], c: Color, glass := false) -> void:
 # Double-sided sculpted ribbon, visibly three-dimensional in the race camera.
 var tool = SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 tool.set_material(_mat(c, 0.0, false, glass))
 for a in range(1, points.size() - 1):
  for v in [points[0], points[a], points[a + 1], points[a + 1], points[a], points[0]]:
   tool.add_vertex(v)
 tool.generate_normals()
 var mesh = tool.commit()
 _shape(mesh, Vector3.ZERO, c, 0.0, false, null, glass)

func _paintwork(index: int) -> void:
 # Raised sculpted bonnet, lacquer stripes, side-skirts, carbon diffuser.
 _orb(Vector3(0, 1.13, -0.92), Vector3(0.78, 0.17, 0.72), coat.lightened(0.23))
 _box(Vector3(0, 1.277, -0.96), Vector3(0.27, 0.035, 1.10), accent, 0.3)
 _box(Vector3(0, 0.72, -1.81), Vector3(1.56, 0.10, 0.15), graphite, 0.6)
 _box(Vector3(0, 0.82, 1.76), Vector3(1.44, 0.12, 0.17), graphite, 0.5)
 _box(Vector3(0, 0.56, 1.24), Vector3(1.62, 0.09, 0.61), graphite, 0.5)
 _orb(Vector3(0, 1.26, -0.48), Vector3(0.19, 0.05, 0.24), pearl)
 for side in [-1.0, 1.0]:
  _box(Vector3(side * 1.06, 0.78, -0.10), Vector3(0.14, 0.17, 2.18), accent, 0.46)
  _box(Vector3(side * 0.93, 1.06, -0.90), Vector3(0.09, 0.09, 0.84), pearl, 0.5)
  _box(Vector3(side * 0.72, 0.66, -1.77), Vector3(0.30, 0.14, 0.16), accent, 0.6)
  _box(Vector3(side * 0.79, 0.99, 1.55), Vector3(0.45, 0.10, 0.26), pearl, 0.4)
  _orb(Vector3(side * 0.91, 1.10, 0.82), Vector3(0.12, 0.12, 0.28), coat.lightened(0.3))
  for rivet in range(3):
   _orb(Vector3(side * 1.105, 0.87, -0.75 + float(rivet) * 0.63), Vector3(0.043, 0.043, 0.043), pearl)
 # Iconic hood crest as a five-point chrome star, inset in painted nose.
 for j in range(5):
  var angle = TAU * float(j) / 5.0
  _orb(Vector3(cos(angle) * 0.19, 1.36, -1.22 + sin(angle) * 0.18), Vector3(0.075, 0.044, 0.075), accent, true)
 _orb(Vector3(0, 1.38, -1.22), Vector3(0.10, 0.045, 0.10), pearl)
 if index % 3 == 0:
  for i in range(3):
   _box(Vector3(-0.4 + i * 0.4, 1.292, -0.77), Vector3(0.13, 0.025, 0.52), pearl, 0.30)
 elif index % 3 == 1:
  for side in [-1.0, 1.0]:
   var fin = _box(Vector3(side * 0.86, 1.29, 1.34), Vector3(0.22, 0.35, 0.72), accent, 0.32)
   fin.rotation.z = side * 0.15
 else:
  for i in range(4):
   _orb(Vector3(-0.53 + float(i) * 0.35, 1.29, -1.08), Vector3(0.10, 0.05, 0.13), accent, true)

func _wheels() -> void:
 # Alloy wheel rim, colored wheel nut, tire tread and visible suspension coils.
 for pivot in wheels:
  var hub_side = signf(pivot.position.x)
  for side in [-1.0, 1.0]:
   var x = hub_side * (0.27 + (0.03 if side > 0.0 else 0.0))
   var rim_mesh = CylinderMesh.new()
   rim_mesh.top_radius = 0.34
   rim_mesh.bottom_radius = 0.34
   rim_mesh.height = 0.06
   rim_mesh.radial_segments = 16
   var rim = _shape(rim_mesh, Vector3(x, 0, 0), graphite, 0.45, false, pivot)
   rim.rotation.z = PI / 2.0
   for spoke in range(6):
    var a = float(spoke) * TAU / 6.0
    _orb_in_pivot(pivot, Vector3(x * 1.1, sin(a) * 0.20, cos(a) * 0.20), accent)
  _orb_in_pivot(pivot, Vector3(hub_side * 0.34, 0.0, 0.0), pearl)
  for tread in range(8):
   var a = float(tread) * TAU / 8.0
   var strap = _box(Vector3(0, sin(a) * 0.53, cos(a) * 0.53), Vector3(0.47, 0.08, 0.08), Color("#44435a"), 0.02, false, pivot)
   strap.rotation.x = a
  _pipe(Vector3(pivot.position.x * 0.80, 0.87, pivot.position.z), Vector3(pivot.position.x, 0.62, pivot.position.z), 0.08, accent)

func _orb_in_pivot(pivot: Node3D, at: Vector3, c: Color) -> void:
 var s = SphereMesh.new()
 s.radius = 0.075
 s.height = 0.15
 s.radial_segments = 8
 s.rings = 4
 _shape(s, at, c, 0.65, false, pivot)

func _face(index: int) -> void:
 var eye = Vector3(0, 1.99, -0.49)
 if index == 2:
  _orb(eye + Vector3(0, 0, -0.03), Vector3(0.40, 0.43, 0.14), accent)
  _orb(eye + Vector3(0, 0, -0.17), Vector3(0.25, 0.28, 0.08), Color("#2c355c"))
  _orb(eye + Vector3(-0.07, 0.10, -0.22), Vector3(0.075, 0.105, 0.06), pearl)
  _pipe(Vector3(-0.4, 2.42, -0.44), Vector3(0.4, 2.42, -0.44), 0.065, dark)
 else:
  for side in [-1.0, 1.0]:
   _orb(Vector3(side * 0.37, 2.08, -0.42), Vector3(0.17, 0.18, 0.075), accent)
   _orb(Vector3(side * 0.28, 2.12, -0.49), Vector3(0.048, 0.065, 0.036), pearl, true)
   var brow = _pipe(Vector3(side * 0.20, 2.41, -0.35), Vector3(side * 0.50, 2.34, -0.28), 0.064, dark)
   brow.rotation.z += (0.1 if index % 2 == 0 else -0.03)
 for side in [-1.0, 1.0]:
  _orb(Vector3(side * 0.58, 1.73, -0.26), Vector3(0.16, 0.10, 0.09), coat.lightened(0.25))
 _orb(Vector3(0, 1.58, -0.47), Vector3(0.32, 0.09, 0.07), Color("#3d334b"))
 for tooth in [-0.17, 0.17]:
  _spike(Vector3(tooth, 1.54, -0.53), 0.075, 0.17, pearl, PI)

func _species(index: int) -> void:
 match index:
  0: # Fire demon: layered flame crest, lava shards and soot marks.
   for n in range(5):
    var x = (float(n) - 2.0) * 0.24
    _spike(Vector3(x, 2.68 + 0.1 * (2 - abs(n - 2)), 0.36), 0.18, 0.71, Color("#ffbb54") if n % 2 == 0 else Color("#ff7a43"), -x * 0.4)
   for s in [-1.0, 1.0]:
    _spike(Vector3(s * 0.77, 1.87, 0.50), 0.16, 0.52, dark, s * 0.6)
    _orb(Vector3(s * 0.66, 2.04, -0.22), Vector3(0.13, 0.09, 0.10), Color("#fa9b52"), true)
  1: # Gelatin blob with glassy bubbles and wavy stalks.
   for n in range(7):
    var a = float(n) * TAU / 7.0
    var bubble = _orb(Vector3(cos(a) * 0.63, 2.22 + (n % 3) * 0.15, sin(a) * 0.56 + 0.28), Vector3(0.17 + (n % 2) * 0.06, 0.18, 0.18), Color(0.75, 0.96, 1.0, 0.67), false, true)
    animated_bits.append(bubble)
   for s in [-1.0, 1.0]:
    _pipe(Vector3(s * 0.43, 2.49, 0.38), Vector3(s * 0.67, 2.99, 0.38), 0.10, coat)
    _orb(Vector3(s * 0.67, 3.01, 0.38), Vector3(0.24, 0.23, 0.24), accent)
  2: # Cyclops stone guardian, facial armor and crown.
   for n in range(5):
    _spike(Vector3((n - 2) * 0.25, 2.78 - abs(n - 2) * 0.08, 0.38), 0.19, 0.53, accent)
   for s in [-1.0, 1.0]:
    _orb(Vector3(s * 0.7, 1.98, 0.1), Vector3(0.23, 0.35, 0.22), dark)
  3: # Night bat swept wings, purple membrane and white fangs.
   for s in [-1.0, 1.0]:
    _petal([Vector3(s * 0.58, 2.11, 0.1), Vector3(s * 1.65, 2.59, 0.3), Vector3(s * 1.48, 1.84, 0.28), Vector3(s * 1.07, 2.03, 0.45)], accent)
    _spike(Vector3(s * 0.47, 2.78, 0.2), 0.22, 0.64, dark, s * 0.24)
    _spike(Vector3(s * 0.20, 1.56, -0.55), 0.07, 0.24, pearl, PI)
  4: # Leaf-dragon horn pair, scales, frill and snout.
   _orb(Vector3(0, 1.74, -0.65), Vector3(0.45, 0.22, 0.28), accent)
   for s in [-1.0, 1.0]:
    _spike(Vector3(s * 0.53, 2.73, 0.33), 0.21, 0.77, pearl, s * 0.3)
    _orb(Vector3(s * 0.31, 1.84, -0.85), Vector3(0.085, 0.065, 0.055), dark)
   for n in range(5):
    _spike(Vector3(0, 2.60 - 0.10 * n, 0.65 + n * 0.23), 0.18, 0.41, Color("#c7f8a6"))
  5: # Robot: exposed screws, illuminated side gauges, antennae.
   for s in [-1.0, 1.0]:
    _orb(Vector3(s * 0.82, 1.94, 0.24), Vector3(0.21, 0.25, 0.24), Color("#596c82"))
    _orb(Vector3(s * 0.83, 1.94, -0.02), Vector3(0.15, 0.15, 0.07), accent, true)
    _pipe(Vector3(s * 0.42, 2.52, 0.29), Vector3(s * 0.60, 3.02, 0.30), 0.057, graphite)
    _orb(Vector3(s * 0.60, 3.06, 0.30), Vector3(0.15, 0.15, 0.15), Color("#a4f6ff"), true)
   for n in range(4):
    _box(Vector3(-0.32 + n * 0.21, 1.59, -0.55), Vector3(0.10, 0.05, 0.06), accent, 0.5)
  6: # Bee with curved transparent wings and striped armored body.
   for s in [-1.0, 1.0]:
    _petal([Vector3(s * 0.47, 2.54, 0.23), Vector3(s * 1.30, 3.08, 0.06), Vector3(s * 1.05, 2.54, 0.67), Vector3(s * 0.73, 2.33, 0.73)], Color(0.75, 0.97, 1.0, 0.77), true)
    _orb(Vector3(s * 0.74, 2.17, 0.21), Vector3(0.18, 0.18, 0.18), graphite)
   for n in range(3):
    _box(Vector3(0, 1.93 + 0.25 * n, 0.98), Vector3(1.26, 0.09, 0.10), graphite)
  7: # Ink octopus: multiple curved arms with pearly suckers.
   for n in range(6):
    var a = TAU * float(n) / 6.0
    var p0 = Vector3(cos(a) * 0.5, 1.63, sin(a) * 0.38 + 0.33)
    var p1 = p0 + Vector3(cos(a) * 0.34, -0.29, sin(a) * 0.35)
    var p2 = p1 + Vector3(cos(a) * 0.24, 0.28, sin(a) * 0.21)
    _pipe(p0, p1, 0.12, accent)
    _pipe(p1, p2, 0.09, coat)
    _orb(p2, Vector3(0.12, 0.12, 0.12), pearl)
  8: # Cat: pointed ears, whiskers, tabby stripes and a curling tail.
   for s in [-1.0, 1.0]:
    _spike(Vector3(s * 0.49, 2.88, 0.23), 0.21, 0.44, Color("#ffc7cf"), s * 0.2)
    for n in range(3):
     _pipe(Vector3(s * 0.28, 1.69, -0.5), Vector3(s * (0.55 + n * 0.08), 1.74 + (n - 1) * 0.10, -0.57), 0.018, pearl)
    _box(Vector3(s * 0.62, 2.40, 0.04), Vector3(0.12, 0.12, 0.35), dark)
   _pipe(Vector3(0, 1.50, 0.94), Vector3(0.30, 2.06, 1.52), 0.13, coat)
   _orb(Vector3(0.30, 2.07, 1.52), Vector3(0.18, 0.18, 0.18), accent)
  9: # Dinosaur: plated back, tiny arms, and toothy snout.
   _orb(Vector3(0, 1.78, -0.64), Vector3(0.44, 0.25, 0.30), Color("#c1eb80"))
   for n in range(6):
    _spike(Vector3(0, 2.71 - float(n) * 0.17, 0.55 + float(n) * 0.2), 0.20, 0.49, accent)
   for s in [-1.0, 1.0]:
    _pipe(Vector3(s * 0.67, 1.78, 0), Vector3(s * 0.92, 1.53, -0.39), 0.14, coat)
    _spike(Vector3(s * 0.9, 1.44, -0.39), 0.08, 0.22, pearl, PI)
  10: # Ghost: floating mist beads, ragged hem, cold aura.
   for n in range(8):
    var a = TAU * float(n) / 8.0
    _orb(Vector3(cos(a) * 0.69, 1.35 + (n % 2) * 0.12, sin(a) * 0.58 + 0.23), Vector3(0.19, 0.29, 0.19), Color("#f4f7ff"))
    var mote = _orb(Vector3(cos(a) * 1.0, 2.15 + (n % 3) * 0.16, sin(a) * 0.89), Vector3(0.11, 0.11, 0.11), Color("#b5eaff"), true)
    animated_bits.append(mote)
  11: # Crystal guardian: multifaceted crown and glowing shards.
   for n in range(7):
    var a = TAU * float(n) / 7.0
    var tip = _spike(Vector3(cos(a) * 0.55, 2.75 + (n % 3) * 0.11, sin(a) * 0.43 + 0.26), 0.17, 0.52 + (n % 3) * 0.13, accent)
    tip.rotation.z = -cos(a) * 0.30
    _orb(Vector3(cos(a) * 0.75, 1.80, sin(a) * 0.62 + 0.30), Vector3(0.12, 0.24, 0.12), Color("#eafaff"), true)

func _racing_accessories(index: int) -> void:
 # Functional-looking gear gives every monster car a coherent toy-grade finish.
 for s in [-1.0, 1.0]:
  _pipe(Vector3(s * 0.77, 1.09, 1.24), Vector3(s * 0.77, 1.39, 1.53), 0.075, graphite)
  _orb(Vector3(s * 0.77, 1.49, 1.56), Vector3(0.23, 0.11, 0.23), Color("#e3eeff"))
  _orb(Vector3(s * 0.77, 1.52, 1.56), Vector3(0.13, 0.08, 0.13), accent, true)
  _box(Vector3(s * 0.70, 0.74, -1.88), Vector3(0.38, 0.16, 0.14), Color("#f0f9ff"), 0.15, true)
  _orb(Vector3(s * 0.63, 1.11, 0.81), Vector3(0.18, 0.18, 0.18), graphite)
 _box(Vector3(0, 0.71, 1.91), Vector3(1.58, 0.08, 0.16), graphite, 0.35)
 _box(Vector3(0, 0.78, 1.95), Vector3(0.86, 0.12, 0.11), accent, 0.55)
 var plate = Label3D.new()
 plate.text = "%02d" % (index + 1)
 plate.font_size = 72
 plate.pixel_size = 0.0029
 plate.modulate = pearl
 plate.outline_size = 6
 plate.outline_modulate = graphite
 plate.position = Vector3(0, 0.79, 1.99)
 plate.rotation.y = PI
 add_child(plate)

func animate_details(dt: float, elapsed: float, velocity: float) -> void:
 for i in range(animated_bits.size()):
  var bit = animated_bits[i]
  if is_instance_valid(bit):
   bit.position.y += sin(elapsed * 2.2 + float(i) * 1.7) * dt * 0.13
