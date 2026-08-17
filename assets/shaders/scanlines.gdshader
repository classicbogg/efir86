shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float scan_opacity : hint_range(0.0, 0.5) = 0.08;
uniform float grain_opacity : hint_range(0.0, 0.5) = 0.04;
uniform float lines : hint_range(80.0, 1400.0) = 640.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	float scan = step(0.52, fract(UV.y * lines));
	float n = hash(floor(SCREEN_UV * vec2(1920.0, 1080.0)) + vec2(TIME * 47.0, TIME * 9.0));
	float a = scan * scan_opacity + n * grain_opacity;
	COLOR = vec4(vec3(0.0), a);
}
