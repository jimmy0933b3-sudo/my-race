extends Node3D
## Fantasy circuit constructed entirely from mobile-friendly 3D meshes.
const SCENERY_ART = preload("res://scripts/scenery_art.gd")
const BIOME_WORLD = preload("res://scripts/biome_world.gd")
const WORLD_OVERHAUL = preload("res://scripts/world_overhaul.gd")
const BARRIER_ART = preload("res://scripts/track_barrier.gd")
const VISUAL_POLISH = preload("res://scripts/visual_polish.gd")
const COURSE_ART_V3 = preload("res://scripts/course_art_v3.gd")
var course_art_v3
var visual_polish
var fences
var premium_road
var map_index := 0
var alternate_detail
var scenery_detail
const SEGMENTS = 180
const HALF_WIDTH = 8.6
var centers: Array[Vector3] = []
var total_length := 0.0
var segment_lengths: Array[float] = []
var track_palette = [Color("#4e5879"), Color("#606c8d")]
var rng := RandomNumberGenerator.new()
var material_cache: Dictionary = {}
var shared_sphere: SphereMesh
var themed_landmarks := 0

func _ready() -> void:
 rng.seed = 80321
 for i in range(SEGMENTS):
  var a = TAU * float(i) / float(SEGMENTS)
  var r1 = 60.0 + 7.0 * sin(a * 3.0 + 0.3)
  var r2 = 47.0 + 6.0 * sin(a * 4.0 + 1.1)
  match map_index:
   1:
    r1 = 69.0 + 8.0 * sin(a * 2.0 + 0.4) + 5.0 * sin(a * 5.0)
    r2 = 48.0 + 7.0 * sin(a * 3.0)
   2:
    r1 = 65.0 + 11.0 * sin(a * 4.0 + 0.3)
    r2 = 51.0 + 6.0 * sin(a * 2.0 + 0.9)
   3:
    r1 = 56.0 + 10.0 * sin(a * 3.0 + 1.2)
    r2 = 57.0 + 9.0 * sin(a * 5.0 + 0.25)
  centers.append(Vector3(cos(a) * r1, 0.12, sin(a) * r2))
 for i in range(SEGMENTS):
  var size = centers[i].distance_to(centers[(i + 1) % SEGMENTS])
  segment_lengths.append(size)
  total_length += size
 _build_world()
 premium_road = WORLD_OVERHAUL.new()
 add_child(premium_road)
 premium_road.build(self, map_index)
 fences = BARRIER_ART.new()
 add_child(fences)
 fences.build(self, map_index)
 visual_polish = VISUAL_POLISH.new()
 add_child(visual_polish)
 visual_polish.build(self)
 course_art_v3 = COURSE_ART_V3.new()
 add_child(course_art_v3)
 course_art_v3.build(self)

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

## Collides against the circuit's continuous boundary, even for cars moved by
## hand-written arcade physics. The nearest segment is projected in 2D, avoiding
## corner holes caused by clamping to individual route sample points.
func constrain_position(candidate: Vector3, clearance: float = 1.45) -> Dictionary:
 var near = nearest_index(candidate)
 var p = Vector2(candidate.x, candidate.z)
 var best_point = Vector2(centers[near].x, centers[near].z)
 var best_sq := INF
 var best_segment: int = near
 for index in [posmod(near - 1, SEGMENTS), near]:
  var a = Vector2(centers[index].x, centers[index].z)
  var next: Vector3 = centers[(index + 1) % SEGMENTS]
  var b = Vector2(next.x, next.z)
  var edge = b - a
  var factor = clampf((p - a).dot(edge) / maxf(edge.length_squared(), 0.00001), 0.0, 1.0)
  var projected = a + edge * factor
  var distance_sq = p.distance_squared_to(projected)
  if distance_sq < best_sq:
   best_sq = distance_sq
   best_point = projected
   best_segment = index
 var gap = p - best_point
 var dist = sqrt(best_sq)
 var allowed = HALF_WIDTH - maxf(0.0, clearance)
 var hit = dist > allowed
 var normal = gap / dist if dist > 0.0001 else Vector2.ZERO
 var inside = best_point + normal * minf(dist, allowed)
 # Keep a small inward separation on impact to prevent repeated contact jitter.
 if hit:
  inside = best_point + normal * maxf(0.0, allowed - 0.12)
 return {
  "position": Vector3(inside.x, candidate.y, inside.y),
  "normal": Vector3(normal.x, 0.0, normal.y),
  "collided": hit,
  "distance": dist,
  "segment": best_segment
 }

func _mat(c: Color, rough := 0.8, glow := false) -> StandardMaterial3D:
 var key = "%s-%.2f-%s" % [c.to_html(), rough, str(glow)]
 if material_cache.has(key):
  return material_cache[key]
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = rough
 if glow:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = 1.35
 material_cache[key] = m
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
 if shared_sphere == null:
  shared_sphere = SphereMesh.new()
  shared_sphere.radius = 1.0
  shared_sphere.height = 2.0
  shared_sphere.radial_segments = 12
  shared_sphere.rings = 7
 var node = _shape(shared_sphere, pos, col, parent)
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
  for p in [a, b, c, b, d, c]:
   tool.add_vertex(p)
 tool.generate_normals()
 var road = MeshInstance3D.new()
 road.mesh = tool.commit()
 road.material_override = _mat(color)
 add_child(road)

func _build_world() -> void:
 if map_index > 0:
  alternate_detail = BIOME_WORLD.new()
  add_child(alternate_detail)
  alternate_detail.build(self, map_index)
  return
 var env = WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_SKY
 var sky = Sky.new()
 var sky_paint = ProceduralSkyMaterial.new()
 sky_paint.sky_top_color = Color("#649cbe")
 sky_paint.sky_horizon_color = Color("#c8c4cb")
 sky_paint.ground_horizon_color = Color("#98c5b9")
 sky_paint.ground_bottom_color = Color("#7caf93")
 sky.sky_material = sky_paint
 env.environment.sky = sky
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("#c1d6e1")
 env.environment.ambient_light_energy = 0.53
 env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
 env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 add_child(env)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-57, -35, -12)
 sun.light_color = Color("#f4e9d9")
 sun.light_energy = 1.13
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 110.0
 add_child(sun)
 var fill = DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(45, 145, 0)
 fill.light_color = Color("#9dd5ff")
 fill.light_energy = 0.19
 add_child(fill)

 _box(Vector3(0, -0.30, 0), Vector3(355, 0.4, 315), Color("#71c895"))
 _box(Vector3(0, -0.10, 0), Vector3(130, 0.22, 86), Color("#89d7a9"))
 _ribbon(HALF_WIDTH + 2.0, 0.022, Color("#c2bcae"))
 _ribbon(HALF_WIDTH + 0.78, 0.055, Color("#c87490"))
 _ribbon(HALF_WIDTH, 0.086, Color("#27344c"))
 _ribbon(HALF_WIDTH - 0.44, 0.092, Color("#374660"))
 _ribbon(HALF_WIDTH - 3.0, 0.096, Color("#4f5d79"))
 for i in range(0, SEGMENTS, 3):
  var a = at(i, 0.0)
  var b = at(i + 1, 0.0)
  var t = (b - a).normalized()
  var mid = (a + b) * 0.5
  var dash = _box(Vector3(mid.x, 0.105, mid.z), Vector3(0.28, 0.027, 1.65), Color("#eddda5"), null, false)
  dash.rotation.y = atan2(-t.x, -t.z)
 _add_raceway_details()
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
 _add_theme_park()
 scenery_detail = SCENERY_ART.new()
 add_child(scenery_detail)
 scenery_detail.decorate(self)

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

func _add_raceway_details() -> void:
 # Checker-painted kerbs, racing lane guides and curved illuminated safety rails.
 for i in range(0, SEGMENTS, 3):
  var tangent = direction(float(i))
  var heading = atan2(-tangent.x, -tangent.z)
  var stripe = Color("#ffffff") if (i / 3) % 2 == 0 else Color("#fe95b2")
  for side in [-1.0, 1.0]:
   var curb = at(i, side * (HALF_WIDTH + 0.31))
   var patch = _box(Vector3(curb.x, 0.117, curb.z), Vector3(0.72, 0.055, 3.4), stripe)
   patch.rotation.y = heading
 for i in range(0, SEGMENTS, 5):
  var tangent = direction(float(i))
  var heading = atan2(-tangent.x, -tangent.z)
  for lane in [-3.45, 3.45]:
   var p = at(i, lane)
   var line = _box(Vector3(p.x, 0.115, p.z), Vector3(0.16, 0.018, 2.55), Color("#b7eaff"), null, true)
   line.rotation.y = heading
 for i in range(0, SEGMENTS, 4):
  for side in [-1.0, 1.0]:
   var a = at(i, side * (HALF_WIDTH + 2.03))
   var b = at(i + 4, side * (HALF_WIDTH + 2.03))
   var delta = b - a
   var beam = _box((a + b) * 0.5 + Vector3(0, 1.32, 0), Vector3(0.24, 0.26, delta.length() + 0.18), Color("#f9f0c5"))
   beam.rotation.y = atan2(-delta.x, -delta.z)
   var neon = _box((a + b) * 0.5 + Vector3(0, 1.51, 0), Vector3(0.16, 0.07, delta.length() + 0.18), Color("#ff9ace") if (i / 4) % 2 == 0 else Color("#8becff"), null, true)
   neon.rotation.y = beam.rotation.y
 # Sparingly placed orientation arrows stand out on bends without clutter.
 for i in range(12, SEGMENTS, 18):
  var t = direction(float(i))
  var heading = atan2(-t.x, -t.z)
  var mark = at(i, 0.0)
  var arrow = _box(Vector3(mark.x, 0.135, mark.z), Vector3(2.6, 0.019, 0.32), Color("#ffe4aa"), null, true)
  arrow.rotation.y = heading

func _add_theme_park() -> void:
 # Four recognisable scenic districts around the circuit.
 var names = ["SUGAR RUSH", "MAGIC FOREST", "STAR FALLS", "MONSTER CITY"]
 var colors = [Color("#ff86b3"), Color("#72ddad"), Color("#8bafff"), Color("#ffc36a")]
 for zone in range(4):
  var index = 19 + zone * 43
  _festival_arch(index, names[zone], colors[zone])
  themed_landmarks += 1
  for j in range(4):
   var progress = index + 7 + j * 6
   for side in [-1.0, 1.0]:
    var p = at(progress, side * (HALF_WIDTH + 12.0 + float((j + zone) % 3) * 2.0))
    match zone:
     0:
      _candy_pole(p, 0.9 + float(j % 2) * 0.26)
     1:
      _mushroom(p, 0.95 + float(j % 3) * 0.24, colors[zone].lightened(0.18))
     2:
      _crystal(p, 2.5 + float(j % 3) * 0.4)
      _star_tower(p + Vector3(3.1, 0, -1.5), 0.8, colors[zone])
     3:
      _star_tower(p, 1.0 + float(j % 2) * 0.28, colors[zone])
 # Central monster festival: centerpiece, confetti sculptures and candy houses.
 _center_mascot(Vector3(0, 1.0, 0))
 for n in range(8):
  var a = TAU * float(n) / 8.0
  var p = Vector3(cos(a) * 18.0, 0.2, sin(a) * 13.0)
  if n % 2 == 0:
   _mushroom(p, 1.35, Color("#ff8fbd"))
  else:
   _candy_pole(p, 1.35)

func _festival_arch(index: int, name: String, color: Color) -> void:
 var t = direction(float(index))
 var mid = at(index)
 for side in [-1.0, 1.0]:
  var p = at(index, side * (HALF_WIDTH + 2.55))
  _box(Vector3(p.x, 3.2, p.z), Vector3(0.85, 6.4, 0.85), color)
  _box(Vector3(p.x, 3.15, p.z), Vector3(0.98, 0.18, 0.98), Color("#fff1c4"), null, true)
  _ball(Vector3(p.x, 6.75, p.z), Vector3(0.77, 0.77, 0.77), Color("#fff0a8"))
 var bar = _box(mid + Vector3(0, 6.55, 0), Vector3(HALF_WIDTH * 2.0 + 6.4, 1.33, 1.20), color)
 bar.rotation.y = atan2(-t.x, -t.z)
 var crest = _ball(mid + Vector3(0, 7.68, 0), Vector3(1.02, 1.02, 0.63), Color("#fff0a4"))
 var banner = Label3D.new()
 banner.text = name
 banner.font_size = 76
 banner.pixel_size = 0.014
 banner.modulate = Color("#fffdf0")
 banner.outline_modulate = Color("#29334e")
 banner.outline_size = 15
 banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 banner.position = mid + Vector3(0, 6.55, 0)
 add_child(banner)

func _mushroom(p: Vector3, scale_factor: float, cap: Color) -> void:
 _box(p + Vector3(0, 1.7 * scale_factor, 0), Vector3(0.75, 3.4, 0.75) * scale_factor, Color("#fff0d1"))
 _ball(p + Vector3(0, 3.55 * scale_factor, 0), Vector3(2.3, 0.98, 2.3) * scale_factor, cap)
 for side in [-1.0, 1.0]:
  _ball(p + Vector3(side * 1.0 * scale_factor, 4.14 * scale_factor, -0.3), Vector3(0.38, 0.13, 0.38) * scale_factor, Color("#fffbe8"))

func _candy_pole(p: Vector3, scale_factor: float) -> void:
 _box(p + Vector3(0, 2.45 * scale_factor, 0), Vector3(0.60, 4.9, 0.60) * scale_factor, Color("#f8d5eb"))
 for stripe in range(5):
  _box(p + Vector3(0, (0.8 + float(stripe) * 0.83) * scale_factor, 0), Vector3(0.70, 0.28, 0.70) * scale_factor, Color("#ff8bba"))
 _ball(p + Vector3(0, 5.30 * scale_factor, 0), Vector3(1.55, 1.55, 1.55) * scale_factor, Color("#8be5ed"))
 _ball(p + Vector3(0, 5.30 * scale_factor, -0.6 * scale_factor), Vector3(0.64, 0.64, 1.02) * scale_factor, Color("#d7f8ff"))

func _star_tower(p: Vector3, scale_factor: float, color: Color) -> void:
 _box(p + Vector3(0, 2.0 * scale_factor, 0), Vector3(2.0, 4.0, 2.0) * scale_factor, color.darkened(0.13))
 _box(p + Vector3(0, 4.28 * scale_factor, 0), Vector3(2.65, 0.46, 2.65) * scale_factor, Color("#ffe7b5"))
 _cone(p + Vector3(0, 5.55 * scale_factor, 0), Vector3(1.3, 1.15, 1.3) * scale_factor, color)
 _ball(p + Vector3(0, 6.74 * scale_factor, 0), Vector3(0.40, 0.40, 0.40) * scale_factor, Color("#fff7ba"))

func _center_mascot(p: Vector3) -> void:
 _ball(p + Vector3(0, 3.4, 0), Vector3(3.3, 3.1, 2.9), Color("#b09bff"))
 for side in [-1.0, 1.0]:
  _cone(p + Vector3(side * 1.65, 6.60, 0), Vector3(0.65, 1.23, 0.65), Color("#ffe3a5"))
  _ball(p + Vector3(side * 1.05, 4.05, -2.45), Vector3(0.73, 0.91, 0.42), Color("#fff9f2"))
  _ball(p + Vector3(side * 1.05, 4.02, -2.83), Vector3(0.29, 0.42, 0.16), Color("#34405a"))
 _ball(p + Vector3(0, 2.45, -2.80), Vector3(1.25, 0.40, 0.26), Color("#53477b"))
