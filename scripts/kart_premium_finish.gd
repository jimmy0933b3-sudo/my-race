extends Node3D
## Premium final-body detailing for original Monster Kart characters.
## Uses true curved geometry, tailored materials and layered optics instead of
## decals that would blur on mobile or more floating primitive ornaments.
var body_color: Color
var trim_color: Color
var chassis: Node3D
var wheel_parts: Array[Node3D] = []
var eye_highlights: Array[MeshInstance3D] = []
var index := 0
var details := 0
var metallic_palette: Array[Color] = [
 Color("#cde6f0"), Color("#576783"), Color("#22384b"), Color("#eef5fb")
]

func build(kind: int, primary: Color, accent: Color, wheels: Array[Node3D]) -> void:
 name = "HighDefinitionBodyAndCockpit"
 index = kind
 body_color = primary
 trim_color = accent
 wheel_parts = wheels
 _curved_panels()
 _projector_lamps()
 _wheel_studio()
 _carbon_finish()
 _cockpit_details()
 _character_face_gloss()
 _brand_identity()

func _material(color: Color, metallic := 0.0, rough := 0.25, glow := false, alpha := 1.0) -> StandardMaterial3D:
 var mat = StandardMaterial3D.new()
 mat.albedo_color = Color(color.r, color.g, color.b, alpha)
 mat.metallic = metallic
 mat.roughness = rough
 mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
 mat.clearcoat_enabled = metallic > 0.05 or rough < 0.24
 mat.clearcoat = 0.94
 mat.clearcoat_roughness = 0.08
 if glow:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = 1.8
 if alpha < 1.0:
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
 return mat

func _shape(mesh: Mesh, pos: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
 var node = MeshInstance3D.new()
 node.mesh = mesh
 node.position = pos
 node.material_override = material
 if parent == null:
  add_child(node)
 else:
  parent.add_child(node)
 details += 1
 return node

func _ellipsoid(pos: Vector3, size3: Vector3, col: Color, metal := 0.0, rough := 0.22, alpha := 1.0) -> MeshInstance3D:
 var sphere = SphereMesh.new()
 sphere.radius = 1.0
 sphere.height = 2.0
 sphere.radial_segments = 32
 sphere.rings = 16
 var node = _shape(sphere, pos, _material(col,metal,rough,false,alpha))
 node.scale = size3
 return node

func _ring(pos: Vector3, radius: float, thickness: float, col: Color, metal := 0.8, glow := false, parent: Node3D = null) -> MeshInstance3D:
 var mesh = TorusMesh.new()
 mesh.inner_radius = radius-thickness*0.5
 mesh.outer_radius = radius+thickness*0.5
 mesh.ring_segments = 32
 mesh.rings = 14
 return _shape(mesh,pos,_material(col,metal,0.17,glow),parent)

func _tube(a: Vector3, b: Vector3, radius: float, col: Color, glow := false, parent: Node3D = null) -> MeshInstance3D:
 var diff=b-a
 if diff.length()<0.001:
  return null
 var mesh = CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = diff.length()
 mesh.radial_segments = 12
 var n = _shape(mesh,(a+b)*0.5,_material(col,0.68,0.20,glow),parent)
 n.quaternion = Quaternion(Vector3.UP,diff.normalized())
 return n

func _trace_curve(points: Array[Vector3], radius: float, col: Color, glow := false) -> void:
 for j in range(points.size()-1):
  _tube(points[j],points[j+1],radius,col,glow)

func _curved_panels() -> void:
 var bright=body_color.lightened(0.35)
 var dark=body_color.darkened(0.50)
 for side in [-1.0,1.0]:
  # Long continuous sweeping body-line: chromed shoulder -> lower diffuser.
  var shoulder: Array[Vector3] = [
   Vector3(side*0.54,1.18,-1.82),Vector3(side*0.80,1.34,-1.43),
   Vector3(side*1.08,1.30,-0.76),Vector3(side*1.11,1.16,0.15),
   Vector3(side*1.10,1.17,0.92),Vector3(side*0.94,1.22,1.51)
  ]
  _trace_curve(shoulder,0.040,bright)
  var blade: Array[Vector3] = [
   Vector3(side*1.08,0.65,-1.48),Vector3(side*1.30,0.56,-0.85),
   Vector3(side*1.31,0.54,0.48),Vector3(side*1.18,0.56,1.48)
  ]
  _trace_curve(blade,0.09,dark)
  var inset=_ellipsoid(Vector3(side*1.11,0.91,-0.18),Vector3(0.09,0.13,0.76),dark,0.28)
  inset.rotation.z=side*0.13
  # Ceramic inset pinstripe follows the side intake, with racing number.
  _trace_curve([
   Vector3(side*1.20,1.00,-0.70),
   Vector3(side*1.26,0.93,-0.15),
   Vector3(side*1.21,0.98,0.50)
  ],0.025,trim_color,true)
  _ellipsoid(Vector3(side*0.72,1.23,-1.68),Vector3(0.22,0.06,0.07),bright,0.52)
 _trace_curve([
  Vector3(-0.64,1.31,-1.69),Vector3(-0.40,1.37,-1.86),
  Vector3(0.40,1.37,-1.86),Vector3(0.64,1.31,-1.69)
 ],0.045,bright)
 # Carbon hood scoop and grille: deeply layered instead of flat strips.
 _ellipsoid(Vector3(0,1.32,-1.04),Vector3(0.36,0.075,0.29),dark,0.55,0.36)
 for s in [-1.0,1.0]:
  for j in range(3):
   _tube(Vector3(s*(0.13+j*0.095),1.39,-1.20),Vector3(s*(0.13+j*0.095),1.39,-0.91),0.013,metallic_palette[0])
 # Flowing windshield with glass blue tint and high-gloss highlights.
 _ellipsoid(Vector3(0,1.44,-0.52),Vector3(0.67,0.12,0.13),Color("#aeeaff"),0.48,0.05,0.68)
 for side in [-1.0,1.0]:
  _tube(Vector3(side*0.63,1.38,-0.59),Vector3(side*0.53,1.72,-0.30),0.055,metallic_palette[0])
 _trace_curve([
  Vector3(-0.54,1.73,-0.30),Vector3(-0.30,1.77,-0.33),
  Vector3(0.30,1.77,-0.33),Vector3(0.54,1.73,-0.30)
 ],0.040,metallic_palette[0])

func _projector_lamps() -> void:
 for side in [-1.0,1.0]:
  # Satin reflector bowl, concentric projector lens and fine chromed housing.
  _ellipsoid(Vector3(side*0.75,1.09,-1.83),Vector3(0.24,0.13,0.10),Color("#1a3248"),0.66,0.12)
  _ellipsoid(Vector3(side*0.75,1.09,-1.92),Vector3(0.163,0.085,0.040),Color("#c9f4fc"),0.18,0.06)
  _ellipsoid(Vector3(side*0.75,1.10,-1.963),Vector3(0.095,0.047,0.020),Color("#ffffff"),0.0,0.02)
  _ellipsoid(Vector3(side*0.92,1.03,-1.84),Vector3(0.055,0.040,0.035),trim_color,0.14,0.15)
  # Dual tail lamp with frosted diffuser and polished lens.
  _ellipsoid(Vector3(side*0.83,0.81,1.95),Vector3(0.21,0.10,0.06),Color("#3d132a"),0.24)
  _ellipsoid(Vector3(side*0.83,0.82,2.00),Vector3(0.16,0.06,0.025),Color("#ff506d"),0.12,0.07)
  _ellipsoid(Vector3(side*0.83,0.845,2.029),Vector3(0.105,0.018,0.012),Color("#ffd8c8"),0.10,0.05)
  for i in range(3):
   _ellipsoid(Vector3(side*(0.71+i*0.11),0.84,2.038),Vector3(0.014,0.014,0.007),Color("#fff0e8"),0.0,0.05)

func _wheel_studio() -> void:
 var rubber = _material(Color("#181e2b"),0.0,0.89)
 var tread_shader = Shader.new()
 tread_shader.code = """shader_type spatial;
render_mode diffuse_burley;
void fragment() {
 float fine = smoothstep(0.24,0.3,fract(UV.x*38.0)) * (1.0-smoothstep(0.69,0.74,fract(UV.x*38.0)));
 float groove = step(0.89, fract(UV.y * 7.0 + sin(UV.x * 40.0) * 0.04));
 float v = 0.085 + fine*0.025 - groove*0.065;
 ALBEDO = vec3(v,v*1.05,v*1.17);
 ROUGHNESS = 0.94;
}
"""
 var tire_mat = ShaderMaterial.new()
 tire_mat.shader = tread_shader
 for pivot in wheel_parts:
  var side = signf(pivot.position.x)
  var rim_side=side*0.295
  # Tyre tread ring rotates with original wheel pivot.
  var tire=TorusMesh.new()
  tire.inner_radius=0.505
  tire.outer_radius=0.569
  tire.ring_segments=48
  tire.rings=16
  var rubber_trim=_shape(tire,Vector3(rim_side,0,0),rubber,pivot)
  rubber_trim.rotation.z=PI/2
  # Wheel outer disk and layered deep dish forged spoke spokes.
  var barrel=CylinderMesh.new()
  barrel.top_radius=0.345
  barrel.bottom_radius=0.345
  barrel.height=0.07
  barrel.radial_segments=40
  var main=_shape(barrel,Vector3(rim_side,0,0),_material(metallic_palette[1],0.88,0.14),pivot)
  main.rotation.z=PI/2
  var ring_outer=_ring(Vector3(rim_side+side*0.065,0,0),0.38,0.054,metallic_palette[0],0.94,false,pivot)
  ring_outer.rotation.z=PI/2
  var ring_inner=_ring(Vector3(rim_side+side*0.079,0,0),0.27,0.034,trim_color,0.44,false,pivot)
  ring_inner.rotation.z=PI/2
  for spoke in range(10):
   var a = TAU*float(spoke)/10.0
   var from=Vector3(rim_side+side*0.087,cos(a)*0.105,sin(a)*0.105)
   var to=Vector3(rim_side+side*0.082,cos(a+0.08)*0.335,sin(a+0.08)*0.335)
   _tube(from,to,0.032,metallic_palette[0],false,pivot)
  _shape(barrel,Vector3(rim_side+side*0.102,0,0),_material(trim_color,0.65,0.12),pivot).scale=Vector3(0.48,0.15,0.48)
  # Brake caliper behind wheel, locked to car as non-rotating element.
  _ellipsoid(pivot.position+Vector3(side*0.0,0.20,0.30),Vector3(0.22,0.12,0.17),Color("#da7970"),0.42)
  # Visible sidewall and tread scratches.
  for line_index in range(4):
   var t=TAU*float(line_index)/4.0
   _ellipsoid(pivot.position+Vector3(side*0.306,cos(t)*0.455,sin(t)*0.455),Vector3(0.014,0.034,0.055),metallic_palette[2])

func _carbon_finish() -> void:
 var mesh = BoxMesh.new()
 mesh.size=Vector3(0.42,0.10,1.15)
 var shader = Shader.new()
 shader.code = """shader_type spatial;
render_mode diffuse_burley;
void fragment(){
 vec2 p = floor(UV * vec2(82.0, 28.0));
 float weave=mod(p.x+p.y,2.0);
 float fine=0.07 + weave * 0.055;
 ALBEDO=vec3(fine,fine*1.1,fine*1.26);
 METALLIC=0.32; ROUGHNESS=0.38;
}
"""
 var mat=ShaderMaterial.new()
 mat.shader=shader
 for side in [-1.0,1.0]:
  var fin=_shape(mesh,Vector3(side*1.05,0.58,0.24),mat)
  fin.rotation.z=side*0.10
  var guard=_shape(mesh,Vector3(side*0.45,0.47,1.63),mat)
  guard.scale=Vector3(0.65,0.60,0.42)
 for side in [-1.0,1.0]:
  _tube(Vector3(side*0.32,1.62,1.44),Vector3(side*0.77,1.58,1.64),0.036,metallic_palette[0])

func _cockpit_details() -> void:
 _ellipsoid(Vector3(0,1.48,0.48),Vector3(0.53,0.13,0.35),Color("#27324e"),0.08,0.54)
 for side in [-1.0,1.0]:
  # Seat stitching & padded seat support, plus roll bar.
  for j in range(5):
   _ellipsoid(Vector3(side*0.31,1.32+j*0.074,1.25),Vector3(0.026,0.012,0.018),Color("#b5c5df"),0.28)
  _trace_curve([
   Vector3(side*0.55,1.32,0.55),
   Vector3(side*0.66,1.60,0.66),
   Vector3(side*0.55,1.95,0.99)
  ],0.04,metallic_palette[0])
 _trace_curve([Vector3(-0.55,1.95,0.99),Vector3(0,2.00,1.00),Vector3(0.55,1.95,0.99)],0.048,metallic_palette[0])

func _character_face_gloss() -> void:
 # Character eyes receive tiny, layered catchlights that change with
 # car rotation and lighting. Avoid generic flat sticker-like black dots.
 if index==2:
  _ellipsoid(Vector3(-0.048,2.062,-0.589),Vector3(0.072,0.043,0.017),Color("#ffffff"),0.0,0.045)
  _ellipsoid(Vector3(0.043,1.96,-0.588),Vector3(0.032,0.029,0.009),Color("#a7e6fa"),0.0,0.06)
 else:
  for side in [-1.0,1.0]:
   var sparkle=_ellipsoid(Vector3(side*0.31-0.040,2.102,-0.488),Vector3(0.046,0.058,0.014),Color("#ffffff"),0.0,0.02)
   eye_highlights.append(sparkle)
   _ellipsoid(Vector3(side*0.31+0.052,2.005,-0.486),Vector3(0.019,0.025,0.009),Color("#c6edff"),0.0,0.12)
 for side in [-1.0,1.0]:
  _ellipsoid(Vector3(side*0.49,1.79,-0.33),Vector3(0.18,0.052,0.046),body_color.lightened(0.28),0.04,0.14)

func _brand_identity() -> void:
 var name_list = ["BLAZE", "BUBBLE", "CYCLOPS", "NIGHTWING", "DRACO", "BOLT", "BZZ", "INKY", "MEOWZA", "CHOMP", "BOO", "GLIMMER"]
 # Race identity physically embossed on the spoiler.
 var brand = Label3D.new()
 brand.text = name_list[index]
 brand.font_size = 61
 brand.pixel_size = 0.0038
 brand.outline_size = 7
 brand.modulate = Color("#f8f7e9")
 brand.outline_modulate = Color("#172333")
 brand.position = Vector3(0,1.635,1.35)
 brand.billboard=BaseMaterial3D.BILLBOARD_DISABLED
 brand.rotation.y=PI
 add_child(brand)
 for side in [-1.0,1.0]:
  var label=Label3D.new()
  label.text="%02d" % (index+1)
  label.font_size=72
  label.pixel_size=0.004
  label.outline_size=9
  label.modulate=trim_color
  label.outline_modulate=Color("#101a2a")
  label.position=Vector3(side*1.17,1.02,0.25)
  label.rotation.y=PI*0.5*side
  add_child(label)
