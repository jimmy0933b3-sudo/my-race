extends Node3D
## Stage 2 art pass shared by all four circuits: undulating terrain, UV-painted
## racing asphalt, curved neon gates and trackside set dressing.
const MaterialStudio = preload("res://scripts/material_studio.gd")
var track
var biome := 0
var terrain: MeshInstance3D
var road: MeshInstance3D
var deco_count := 0
var rng := RandomNumberGenerator.new()

func build(circuit: Node3D, id: int) -> void:
 track = circuit
 biome = id
 rng.seed = 60403 + id * 71
 name = "OverhauledTrackSurfaces"
 if biome != 3:
  _terrain()
 _road()
 _architectural_gates()
 _grandstand()
 print("STUDIO TRACK MAP=%d deco=%d" % [biome, deco_count])

func _palette() -> Array[Color]:
 match biome:
  0: return [Color("#70c9a5"),Color("#9be0a9"),Color("#d0ad86"),Color("#3e4f70"),Color("#77899e"),Color("#ffa6ca")]
  1: return [Color("#5abb89"),Color("#98e2a5"),Color("#e1c28f"),Color("#314850"),Color("#61777e"),Color("#a8ffb1")]
  2: return [Color("#d99c63"),Color("#f4d195"),Color("#ca8167"),Color("#574d64"),Color("#857384"),Color("#ffc779")]
  _: return [Color("#334078"),Color("#8b87ce"),Color("#6eabdb"),Color("#212e56"),Color("#6472ba"),Color("#a4eaff")]

func _terrain() -> void:
 var pal = _palette()
 var noise = FastNoiseLite.new()
 noise.seed = 81934 + biome * 192
 noise.frequency = 0.014 if biome != 2 else 0.008
 noise.fractal_octaves = 3
 noise.fractal_gain = 0.48
 noise.fractal_type = FastNoiseLite.FRACTAL_FBM
 var grid := 96
 var extent := 156.0
 var positions: Array[Vector3] = []
 for z in range(grid + 1):
  for x in range(grid + 1):
   var px = (float(x) / float(grid) * 2.0 - 1.0) * extent
   var pz = (float(z) / float(grid) * 2.0 - 1.0) * extent
   # Nearby angular samples approximate the closest track without a
   # full 180-point search per vertex (saves millions of GDScript loops).
   var angle = fposmod(atan2(pz/50.0,px/65.0),TAU)
   var candidate = roundi(angle * float(track.SEGMENTS) / TAU)
   var best_sq: float = INF
   for delta in range(-14,15):
    var cpoint: Vector3 = track.centers[posmod(candidate+delta,track.SEGMENTS)]
    var dist_sq = (px-cpoint.x)*(px-cpoint.x)+(pz-cpoint.z)*(pz-cpoint.z)
    best_sq = minf(best_sq,dist_sq)
   var edge_dist = sqrt(best_sq)
   var blend = smoothstep(12.5,41.0,edge_dist)
   var wave = noise.get_noise_2d(px,pz)
   var fine = noise.get_noise_2d(px*2.4+41.0,pz*2.4) * 1.4
   var max_height = 10.0 if biome == 2 else 7.2
   var y = -0.10 + blend * maxf(0.0, wave * max_height + fine + 1.2)
   positions.append(Vector3(px,y,pz))
 # The previous terrain regenerated each face normal separately, causing
 # chunky faceted triangles. Share smoothed normals across the whole grid.
 var smooth_normals: Array[Vector3] = []
 for z in range(grid+1):
  for x in range(grid+1):
   var left = positions[z*(grid+1)+maxi(x-1,0)]
   var right = positions[z*(grid+1)+mini(x+1,grid)]
   var up = positions[maxi(z-1,0)*(grid+1)+x]
   var down = positions[mini(z+1,grid)*(grid+1)+x]
   var tangent_x = (right-left).normalized()
   var tangent_z = (down-up).normalized()
   smooth_normals.append(tangent_z.cross(tangent_x).normalized())
 var tool = SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in range(grid):
  for x in range(grid):
   var idx = z*(grid+1)+x
   for vertex_idx in [idx,idx+grid+1,idx+1,idx+1,idx+grid+1,idx+grid+2]:
    tool.set_normal(smooth_normals[vertex_idx])
    tool.add_vertex(positions[vertex_idx])
 terrain = MeshInstance3D.new()
 terrain.name = "SculptedRollingTerrain"
 terrain.mesh = tool.commit()
 terrain.material_override = MaterialStudio.ground(pal[0],pal[1],pal[2])
 add_child(terrain)

func _road() -> void:
 var pal = _palette()
 var tool = SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var full_length = track.total_length
 var along := 0.0
 var lanes = [-7.95,-7.08,-3.0,0.0,3.0,7.08,7.95]
 for i in range(track.SEGMENTS):
  var next = (i+1)%track.SEGMENTS
  var section = [track.at(i, lanes[0]),track.at(i,lanes[1]),track.at(i,lanes[2]),track.at(i,lanes[3]),track.at(i,lanes[4]),track.at(i,lanes[5]),track.at(i,lanes[6])]
  var other = [track.at(next, lanes[0]),track.at(next,lanes[1]),track.at(next,lanes[2]),track.at(next,lanes[3]),track.at(next,lanes[4]),track.at(next,lanes[5]),track.at(next,lanes[6])]
  var advance = track.segment_lengths[i]
  for lane_index in range(lanes.size()-1):
   var u0 = float(lane_index)/float(lanes.size()-1)
   var u1 = float(lane_index+1)/float(lanes.size()-1)
   var p0 = section[lane_index]
   var p1 = section[lane_index+1]
   var p2 = other[lane_index]
   var p3 = other[lane_index+1]
   p0.y = 0.102
   p1.y = 0.102
   p2.y = 0.102
   p3.y = 0.102
   # Upward-facing triangles: correct physical lighting and consistent paint.
   var vertices = [p0,p1,p2,p1,p3,p2]
   var uvs = [Vector2(along/3.0,u0),Vector2(along/3.0,u1),Vector2((along+advance)/3.0,u0),
    Vector2(along/3.0,u1),Vector2((along+advance)/3.0,u1),Vector2((along+advance)/3.0,u0)]
   for j in range(6):
    tool.set_uv(uvs[j])
    tool.add_vertex(vertices[j])
  along += advance
 tool.generate_normals()
 road = MeshInstance3D.new()
 road.name = "ProceduralFineGrainAsphalt"
 road.mesh = tool.commit()
 road.material_override = MaterialStudio.road(pal[3],pal[4],0.06 if biome==3 else 0.0)
 add_child(road)
 # Fine road shoulder stripes and dashboard-friendly dash markings.
 for i in range(0,track.SEGMENTS,4):
  var direction: Vector3 = track.direction(float(i))
  var angle: float = atan2(-direction.x,-direction.z)
  for lane in [-7.44,7.44]:
   var at: Vector3 = track.at(i,lane)
   var dash = _box(Vector3(at.x,0.146,at.z),Vector3(0.16,0.018,3.2),pal[5],true)
   dash.rotation.y = angle
  if i%8==0:
   var mark: Vector3 = track.at(i)
   var centerline = _box(Vector3(mark.x,0.147,mark.z),Vector3(0.22,0.02,2.75),Color("#fff3dd"),biome==3)
   centerline.rotation.y = angle

func _material(c: Color, glow := false) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = 0.48
 m.metallic = 0.12
 if glow:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = 1.6
 return m

func _box(at: Vector3, dims: Vector3, col: Color, glow := false) -> MeshInstance3D:
 var mesh = BoxMesh.new()
 mesh.size = dims
 var node = MeshInstance3D.new()
 node.mesh = mesh
 node.position = at
 node.material_override = _material(col,glow)
 add_child(node)
 deco_count += 1
 return node

func _orb(at: Vector3, radius: float, col: Color, glow := false) -> void:
 var sphere = SphereMesh.new()
 sphere.radius = radius
 sphere.height = radius*2.0
 sphere.radial_segments = 10
 sphere.rings = 6
 var node = MeshInstance3D.new()
 node.mesh = sphere
 node.position = at
 node.material_override = _material(col,glow)
 add_child(node)
 deco_count += 1

func _beam(start: Vector3, finish: Vector3, radius: float, col: Color, glow := false) -> void:
 var d = finish-start
 var mesh = CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = d.length()
 mesh.radial_segments = 8
 var node = MeshInstance3D.new()
 node.mesh = mesh
 node.position = (start+finish)*0.5
 node.quaternion = Quaternion(Vector3.UP,d.normalized())
 node.material_override = _material(col,glow)
 add_child(node)
 deco_count += 1

func _architectural_gates() -> void:
 # Designed arch silhouettes, with 3D curves instead of square tubes.
 var pal = _palette()
 for gate in range(5):
  var progress = 23.0 + float(gate)*34.0
  var center: Vector3 = track.sample(progress)
  var forward: Vector3 = track.direction(progress)
  var lateral = Vector3(-forward.z,0,forward.x)
  var arch_top := 7.4 if biome==3 else 8.3
  var arch_points: Array[Vector3] = []
  for j in range(15):
   var theta = PI-float(j)*PI/14.0
   var pt=center+lateral*cos(theta)*11.0
   pt.y = 0.65+sin(theta)*arch_top
   arch_points.append(pt)
  for j in range(arch_points.size()-1):
   _beam(arch_points[j],arch_points[j+1],0.43,pal[1])
   _beam(arch_points[j]+forward*0.27,arch_points[j+1]+forward*0.27,0.085,pal[5],true)
  _orb(arch_points[7]+Vector3.UP*0.55,0.62,pal[5],true)
  for side in [-1.0,1.0]:
   var foot = center+lateral*side*11.0
   _box(foot+Vector3(0,0.55,0),Vector3(1.35,1.10,1.35),pal[4])
  var board = Label3D.new()
  board.text = ["MONSTER FESTIVAL","FLOWER VALLEY","SUNSET RALLY","STARLIGHT GP"][biome]
  board.position = arch_points[7]+Vector3(0,-1.05,0)
  board.font_size = 75
  board.pixel_size = 0.009
  board.outline_size = 11
  board.modulate = pal[2]
  board.outline_modulate = Color("#243047")
  board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  add_child(board)

func _grandstand() -> void:
 # Finishing zone. Layered architecture and spectators make starts feel alive.
 var center: Vector3 = track.sample(0.0,22.0)
 var tangent: Vector3 = track.direction(0.0)
 var stand = Node3D.new()
 stand.position = center
 stand.rotation.y = atan2(-tangent.x,-tangent.z)
 add_child(stand)
 var pal = _palette()
 for row in range(5):
  var step = MeshInstance3D.new()
  var bm = BoxMesh.new()
  bm.size = Vector3(23.0,0.8,2.0)
  step.mesh = bm
  step.position = Vector3(0,0.75+row*1.02, row*1.75)
  step.material_override = _material(pal[4])
  stand.add_child(step)
  for seat in range(12):
   var b = MeshInstance3D.new()
   var sphere = SphereMesh.new()
   sphere.radius = 0.42
   sphere.height = 0.84
   sphere.radial_segments = 8
   sphere.rings = 4
   b.mesh = sphere
   b.position = Vector3((seat-5.5)*1.72,1.62+row*1.02,row*1.75)
   b.material_override = _material(pal[(seat+row)%pal.size()])
   stand.add_child(b)
 var roof = MeshInstance3D.new()
 var roof_mesh = BoxMesh.new()
 roof_mesh.size = Vector3(25.0,0.48,12.0)
 roof.mesh = roof_mesh
 roof.position = Vector3(0,7.3,4.2)
 roof.material_override = _material(pal[1])
 stand.add_child(roof)
 deco_count += 65
