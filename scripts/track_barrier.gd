extends Node3D
## Tangible-looking dual-sided guardrails. Physical driving constraint is
## enforced using the exact same track centerline in track.gd, preventing
## tunneling even when a frame advances more than one mesh segment.
const HEIGHT := 1.88
const EDGE_OFFSET := 0.42
var circuit
var fence_panels := 0
var post_count := 0

func build(track: Node3D, course_id: int) -> void:
 circuit = track
 name = "ContinuousCrashBarriers"
 var palette = [
  [Color("#f5dae1"), Color("#ee7295"), Color("#fff4cb")],
  [Color("#e4f6d4"), Color("#40a88c"), Color("#edffd1")],
  [Color("#f6d5a6"), Color("#c76f51"), Color("#fff4c6")],
  [Color("#8ca8d2"), Color("#6e89ed"), Color("#9ff8ff")]
 ][clampi(course_id, 0, 3)]
 for side in [-1.0, 1.0]:
  # Bottom crash wall, perforation-like dark insert, and luminous upper band.
  _ribbon(side, 0.12, 0.76, palette[0], false)
  _ribbon(side, 0.79, 1.56, palette[1].darkened(0.44), false)
  _ribbon(side, 1.25, 1.42, palette[1], false)
  _ribbon(side, 1.63, HEIGHT, palette[2], course_id == 3)
  _posts(side, palette[1], palette[2], course_id == 3)

func _ribbon(side: float, low: float, high: float, color: Color, glow: bool) -> void:
 var tool = SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(circuit.SEGMENTS):
  var a: Vector3 = circuit.at(i, side * (circuit.HALF_WIDTH + EDGE_OFFSET))
  var b: Vector3 = circuit.at(i + 1, side * (circuit.HALF_WIDTH + EDGE_OFFSET))
  var v0 = Vector3(a.x, low, a.z)
  var v1 = Vector3(b.x, low, b.z)
  var v2 = Vector3(a.x, high, a.z)
  var v3 = Vector3(b.x, high, b.z)
  for p in [v0, v2, v1, v1, v2, v3, v1, v2, v0, v3, v2, v1]:
   tool.add_vertex(p)
  fence_panels += 1
 tool.generate_normals()
 var inst = MeshInstance3D.new()
 inst.name = "Barrier_%s_%s" % [str(side), str(low)]
 inst.mesh = tool.commit()
 var mat = StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.42
 mat.metallic = 0.17
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 if glow:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = 1.85
 inst.material_override = mat
 add_child(inst)

func _posts(side: float, body: Color, crown: Color, neon: bool) -> void:
 var cyl = CylinderMesh.new()
 cyl.top_radius = 0.19
 cyl.bottom_radius = 0.24
 cyl.height = HEIGHT + 0.12
 cyl.radial_segments = 9
 var mat = StandardMaterial3D.new()
 mat.albedo_color = body.darkened(0.18)
 mat.metallic = 0.42
 mat.roughness = 0.28
 var count = int(ceil(float(circuit.SEGMENTS) / 3.0))
 var instances = MultiMesh.new()
 instances.transform_format = MultiMesh.TRANSFORM_3D
 instances.mesh = cyl
 instances.instance_count = count
 for i in range(count):
  var p: Vector3 = circuit.at(i * 3, side * (circuit.HALF_WIDTH + EDGE_OFFSET))
  instances.set_instance_transform(i, Transform3D(Basis(), Vector3(p.x, (HEIGHT + 0.12) * 0.5 + 0.05, p.z)))
 var display = MultiMeshInstance3D.new()
 display.multimesh = instances
 display.material_override = mat
 add_child(display)
 post_count += count
