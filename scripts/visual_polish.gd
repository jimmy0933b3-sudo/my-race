extends Node3D
## Mobile-first finishing pass: real atmospheric perspective, bloom, sharp edge
## anti-aliasing and batched fine foliage. Effects are scaled by quality preset.
const MAX_DECORATIONS := 3150
var circuit: Node3D
var biome := 0
var level := 3
var environment: Environment
var sun: DirectionalLight3D
var decoration: Array[MultiMeshInstance3D] = []
var decorated_count := 0
var cloud_group: Node3D
var atmosphere_ready := false

func build(track: Node3D) -> void:
 circuit = track
 biome = clampi(track.map_index, 0, 3)
 name = "QualityArtAndAtmosphere"
 _find_lighting(circuit)
 _build_flora()
 _build_sky_landmarks()
 set_quality(level)

func _find_lighting(node: Node) -> void:
 for child in node.get_children():
  if child is WorldEnvironment:
   environment = child.environment
  elif child is DirectionalLight3D and sun == null:
   sun = child
  if environment == null or sun == null:
   _find_lighting(child)

func _build_flora() -> void:
 # Three material / batched multimesh groups. Each group is one draw call,
 # with local randomized scale, tilt, orientation and per-instance color.
 var mesh = ArrayMesh.new()
 var vertices = PackedVector3Array()
 var normals = PackedVector3Array()
 for blade in range(3):
  var angle = float(blade) * TAU / 3.0
  var right = Vector3(cos(angle), 0, sin(angle))
  var a = right * -0.14
  var b = right * 0.14
  var tip = Vector3(0, 0.72, 0) + right * 0.08
  for v in [a,b,tip,tip,b,a]:
   vertices.append(v)
   normals.append(Vector3.UP)
 var data: Array = []
 data.resize(Mesh.ARRAY_MAX)
 data[Mesh.ARRAY_VERTEX] = vertices
 data[Mesh.ARRAY_NORMAL] = normals
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
 var palette: Array = []
 match biome:
  0: palette = [Color("#8be8b8"),Color("#c8ec96"),Color("#ffc3d9")]
  1: palette = [Color("#57b986"),Color("#baf2a3"),Color("#f8d5a1")]
  2: palette = [Color("#d99e6c"),Color("#f6c18a"),Color("#9ccaaa")]
  _: palette = [Color("#65b7ea"),Color("#b59af2"),Color("#f8a8da")]
 var material = StandardMaterial3D.new()
 material.albedo_color = Color.WHITE
 material.vertex_color_use_as_albedo = true
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 material.roughness = 0.83
 material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
 for group in range(3):
  var rng = RandomNumberGenerator.new()
  rng.seed = 71833 + biome * 221 + group * 31
  var mm = MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.use_colors = true
  mm.mesh = mesh
  mm.instance_count = 1050
  for i in range(560):
   var segment = rng.randf_range(0.0,float(circuit.SEGMENTS))
   var outward = rng.randf_range(12.4, 43.0)
   var side = -1.0 if rng.randf() < 0.5 else 1.0
   var pos = circuit.sample(segment,side*outward)
   var sx = rng.randf_range(0.6,1.9)
   var sy = rng.randf_range(0.55,2.25)
   var transform = Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(sx,sy,sx)),Vector3(pos.x,0.02,pos.z))
   if biome == 3:
    transform.origin.y = rng.randf_range(-1.6,3.5)
    transform.basis = transform.basis.scaled(Vector3(0.55,0.55,0.55))
   mm.set_instance_transform(i,transform)
   mm.set_instance_color(i,palette[(i+group)%palette.size()].lightened(rng.randf_range(0,0.12)))
  var inst = MultiMeshInstance3D.new()
  inst.name = "BatchedNature_%d" % group
  inst.multimesh = mm
  inst.material_override = material
  inst.custom_aabb = AABB(Vector3(-160,-6,-160),Vector3(320,32,320))
  add_child(inst)
  decoration.append(inst)
  decorated_count += mm.instance_count

func _build_sky_landmarks() -> void:
 cloud_group = Node3D.new()
 cloud_group.name="LayeredCloudsAndAtmosphere"
 add_child(cloud_group)
 var rng = RandomNumberGenerator.new()
 rng.seed = 99371 + biome * 121
 if biome == 3:
  # Painted star clusters & layered outer-space nebula glints.
  for n in range(34):
   var a = rng.randf_range(0.0,TAU)
   var radius = rng.randf_range(150.0,260.0)
   var h = rng.randf_range(28.0,135.0)
   var pos = Vector3(cos(a)*radius,h,sin(a)*radius)
   _cloud_ball(pos,Vector3.ONE*rng.randf_range(0.5,1.8),[Color("#b1caff"),Color("#ffe0c4"),Color("#d9b8f7")][n%3],true)
 else:
  # Genuine layered cumulus silhouettes, more complex than 2 spheres.
  for n in range(16):
   var angle = TAU*float(n)/16.0+0.15
   var radius = rng.randf_range(92.0,180.0)
   var p = Vector3(cos(angle)*radius,rng.randf_range(21.0,42.0),sin(angle)*radius)
   var scale_f = rng.randf_range(0.8,1.5)
   var c = Color("#fffaf1") if biome != 2 else Color("#b9c6ca")
   for part in range(5):
    var off = Vector3((part-2)*3.2*scale_f,sin(part*1.7)*0.7,-float(part%2)*1.6)
    var height_f = 2.3+2.1*(1.0-abs(part-2)/2.0)
    _cloud_ball(p+off,Vector3(5.2,height_f,3.0)*scale_f,c,false)

func _cloud_ball(pos:Vector3,dims:Vector3,col:Color,glow:bool)->void:
 var sphere = SphereMesh.new()
 sphere.radius = 1.0
 sphere.height = 2.0
 sphere.radial_segments = 12
 sphere.rings = 7
 var node = MeshInstance3D.new()
 node.mesh = sphere
 node.position = pos
 node.scale = dims
 var mat=StandardMaterial3D.new()
 mat.albedo_color = col
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
 if glow:
  mat.emission_enabled=true
  mat.emission=col
  mat.emission_energy_multiplier=1.4
 node.material_override=mat
 cloud_group.add_child(node)

func set_quality(value:int)->void:
 level=clampi(value,0,3)
 var amounts=[0.12,0.48,0.78,1.0]
 for inst in decoration:
  if is_instance_valid(inst):
   inst.multimesh.visible_instance_count=int(floor(1050.0*amounts[level]))
 if cloud_group!=null:
  cloud_group.visible=level>0
 if environment != null:
  environment.fog_enabled = level>0
  environment.fog_density = 0.00115 if biome==0 else (0.00078 if biome==2 else (0.0011 if biome==3 else 0.0017))
  environment.fog_light_color = [
   Color("#a8c6bd"),Color("#badfeb"),Color("#a9a6a0"),Color("#6c72ae")
  ][biome]
  environment.fog_sky_affect=0.04 if biome==2 else (0.07 if biome==0 else 0.17)
  environment.fog_sun_scatter=0.012 if biome==2 else (0.055 if biome==0 else 0.14)
  # The opening theme park has many emissive decorations: disable global
  # bloom there so the actual road and guardrail silhouettes stay legible.
  environment.glow_enabled = level>=2 and biome!=0 and biome!=2
  environment.glow_intensity=0.82 if level==3 else 0.58
  environment.glow_bloom=0.11 if level==3 else 0.06
  environment.glow_hdr_threshold=1.12
  environment.adjustment_enabled=true
  environment.adjustment_contrast=1.13 if biome==2 else (1.12 if biome==0 else (1.09 if level==3 else (1.045 if level>0 else 1.0)))
  environment.adjustment_saturation=0.98 if biome==2 else (0.93 if biome==0 else (1.10 if level==3 else (1.075 if level>0 else 1.0)))
  environment.adjustment_brightness=0.78 if biome==2 else (0.88 if biome==0 else 1.0)
 if sun!=null:
  sun.shadow_enabled=level>0
  sun.directional_shadow_max_distance=170.0 if level==3 else 125.0
  sun.shadow_blur=1.45 if level==3 else (1.15 if level==2 else 0.78)
 atmosphere_ready=true
