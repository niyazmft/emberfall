shader_type canvas_item;
render_mode unshaded;

uniform vec3 u_center_color : source_color = vec3(0.1216, 0.1373, 0.1882); // #1f2330 Rich Dark Slate
uniform vec3 u_edge_color : source_color = vec3(0.0431, 0.0471, 0.0627); // #0B0C10 Void Black
uniform float u_falloff : hint_range(0.1, 3.0) = 1.2;

void fragment() {
	vec2 uv = UV;
	float dist = length(uv - vec2(0.5, 0.5)) * 2.0;
	float v = pow(clamp(dist, 0.0, 1.0), u_falloff);
	COLOR = vec4(mix(u_center_color, u_edge_color, v), 1.0);
}
