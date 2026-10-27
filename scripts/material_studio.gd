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
 // Four distinct spatial frequencies: broad age variation, tar, gravel
 // and sharp reflective aggregate. All detail remains crisp on 8x MSAA.
 float broad = surface_noise(world_pos.xz * 0.13);
 float age = surface_noise(world_pos.xz * 0.58);
 float grain = surface_noise(world_pos.xz * 5.7);
 float gravel = surface_noise(world_pos.xz * 22.0);
 float aggregate = step(0.945, hash21(floor(world_pos.xz * 13.0)));
 vec3 base = mix(asphalt.rgb * 0.73, fleck.rgb, broad * 0.38 + age * 0.18);
 base += (grain - 0.5) * 0.087 + (gravel - 0.5) * 0.036 + aggregate * 0.07;
 // Thin, soft tire-wear bands embedded in asphalt, not floating geometry.
 float l = exp(-pow((UV.y - 0.28) * 34.0, 2.0));
 float r = exp(-pow((UV.y - 0.72) * 34.0, 2.0));
 float faded = surface_noise(world_pos.xz * 1.3);
 float wear = (l + r) * (0.38 + faded * 0.36);
 base = mix(base, base * 0.57, wear);
 float seams = step(0.985, surface_noise(world_pos.xz * 0.27 + vec2(113.0,17.0)));
 base *= 1.0 - seams * 0.10;
 ALBEDO = max(base, vec3(0.015));
 ROUGHNESS = 0.78 + gravel * 0.13;
 SPECULAR = 0.14;
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
 c*=0.93+0.12*dots;
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
