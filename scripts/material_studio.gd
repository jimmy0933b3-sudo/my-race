extends RefCounted
## Shared original procedural surface shaders. No web assets or packed texture atlases.
## GL Compatibility friendly: object/world position, cheap value noise, no screen reads.

static func road(primary: Color, secondary: Color, glow: float = 0.0) -> ShaderMaterial:
 var shader = Shader.new()
 shader.code = """shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 asphalt : source_color;
uniform vec4 fleck : source_color;
uniform float glow_strength = 0.0;
varying vec3 world_pos;
float hash21(vec2 p) {
 return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float surface_noise(vec2 p) {
 vec2 i = floor(p), f = fract(p);
 f = f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1.,0.)),f.x),
            mix(hash21(i+vec2(0.,1.)),hash21(i+vec2(1.,1.)),f.x), f.y);
}
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}
void fragment() {
 // Art-directed black-top asphalt: aggregate sparkle is tiny and never
 // emissive on the desert course. Lower middle frequencies avoid noisy glare.
 float patch = surface_noise(world_pos.xz * 0.085);
 float wear = surface_noise(world_pos.xz * 0.35);
 float grit = surface_noise(world_pos.xz * 3.1);
 float pebble = surface_noise(world_pos.xz * 14.4);
 float dust = surface_noise(world_pos.xz * 0.95);
 float aggregate = smoothstep(0.91,0.99,hash21(floor(world_pos.xz * 22.0)));
 vec3 base = mix(asphalt.rgb * 0.66, fleck.rgb * 0.64, patch * 0.23 + wear * 0.12);
 base += (grit - 0.50) * 0.055 + (pebble - 0.50) * 0.026;
 base += aggregate * 0.030;
 float tire_a = exp(-pow((UV.y - 0.26) * 30.0, 2.0));
 float tire_b = exp(-pow((UV.y - 0.74) * 30.0, 2.0));
 float skid = (tire_a + tire_b) * (0.30 + dust * 0.28);
 base *= 1.0 - skid * 0.20;
 float faint_cracks = step(0.94,surface_noise(world_pos.xz * 0.21 + vec2(29.0,72.0)));
 base *= 1.0 - faint_cracks * 0.11;
 ALBEDO = clamp(base,vec3(0.014),vec3(0.42));
 METALLIC = 0.0;
 ROUGHNESS = clamp(0.87 + pebble * 0.09 - aggregate * 0.07,0.76,0.98);
 SPECULAR = 0.12;
 EMISSION = base * glow_strength;
}
"""
 var m = ShaderMaterial.new()
 m.shader = shader
 m.set_shader_parameter("asphalt", primary)
 m.set_shader_parameter("fleck", secondary)
 m.set_shader_parameter("glow_strength", glow)
 return m

static func ground(base: Color, highlights: Color, color_dust: Color) -> ShaderMaterial:
 var s = Shader.new()
 s.code = """shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 low_tint : source_color;
uniform vec4 high_tint : source_color;
uniform vec4 dust_tint : source_color;
varying vec3 w;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(17.17,43.39)))*14373.71); }
float noise(vec2 p){
 vec2 i=floor(p), f=fract(p);
 f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1.,0.)),f.x),mix(hash21(i+vec2(0.,1.)),hash21(i+vec2(1.,1.)),f.x),f.y);
}
void vertex(){w=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 float bands=noise(w.xz*0.058);
 float coarse=noise(w.xz*0.55);
 float dots=noise(w.xz*2.7);
 vec3 c=mix(low_tint.rgb,high_tint.rgb, smoothstep(0.25,0.83,bands));
 c=mix(c,dust_tint.rgb,smoothstep(0.56,0.90,coarse)*0.20);
 c*=0.89+0.09*dots;\n float subtle_ridges = noise(w.xz*3.6);\n c*=0.93+0.07*subtle_ridges;
 ALBEDO=c; ROUGHNESS=0.94; SPECULAR=0.11;
}
"""
 var m=ShaderMaterial.new()
 m.shader=s
 m.set_shader_parameter("low_tint",base)
 m.set_shader_parameter("high_tint",highlights)
 m.set_shader_parameter("dust_tint",color_dust)
 return m

static func paint(primary: Color, sparkle: Color) -> ShaderMaterial:
 var s=Shader.new()
 s.code="""shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 body_tint : source_color;
uniform vec4 highlight_tint : source_color;
varying vec3 world_pos;
float hash21(vec2 v){return fract(sin(dot(v,vec2(192.4,37.1)))*14837.28);}
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
void fragment(){
 float glint=step(0.965,hash21(floor(world_pos.xz*25.0)));
 float fade=smoothstep(-0.12,0.91,NORMAL.y);
 ALBEDO=mix(body_tint.rgb*0.75,body_tint.rgb,fade*0.42)+highlight_tint.rgb*(glint*0.19);
 METALLIC=0.23; ROUGHNESS=0.17; SPECULAR=0.88;
 EMISSION=body_tint.rgb*0.025;
}
"""
 var m=ShaderMaterial.new()
 m.shader=s
 m.set_shader_parameter("body_tint",primary)
 m.set_shader_parameter("highlight_tint",sparkle)
 return m
