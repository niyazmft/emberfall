shader_type canvas_item;
render_mode unshaded;

## pp_chromatic_aberration.gdshader
## Event-linked chromatic aberration for Emberfall post-process stack.
##
## Performance tier: medium
## Target platforms: Forward+, Mobile
## Author: Godot Shader Specialist
## References: Art Bible §5, MWT-3 §2.2, DON-254 Item 2

group_uniforms "Channel Offsets";
uniform float ca_strength_r : hint_range(-0.05, 0.05) = 0.003;
uniform float ca_strength_b : hint_range(-0.05, 0.05) = -0.005;

group_uniforms "Direction & Wave";
uniform int ca_direction_mode : hint_range(0, 1) = 0;
## 0 = screen centre | 1 = Keeper screen position
uniform vec2 u_keeper_screen_pos = vec2(0.5, 0.5);
uniform float ca_wave : hint_range(0.0, 1.0) = 0.0;
uniform float ca_wave_freq_hz : hint_range(0.0, 10.0) = 2.0;

group_uniforms "Edge Falloff";
uniform float ca_edge_falloff : hint_range(0.0, 1.0) = 1.0;
uniform float ca_edge_power : hint_range(0.1, 4.0) = 1.0;

void fragment() {
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	vec2 uv = SCREEN_UV;

	// Direction centre
	vec2 centre = mix(vec2(0.5), u_keeper_screen_pos, float(ca_direction_mode));
	vec2 dir = (uv - centre) * aspect;
	float dist = length(dir);

	// Wave modulation (2 Hz sine during impact window)
	float wave = ca_wave > 0.0 ? ca_wave * sin(TIME * ca_wave_freq_hz * 6.28318530718) : 0.0;

	// Cosine falloff from centre toward edges
	float falloff = 1.0;
	if (ca_edge_falloff > 0.0) {
		falloff = pow(cos(clamp(dist * 1.57079632679, 0.0, 1.57079632679)), ca_edge_power);
		falloff = mix(1.0, falloff, ca_edge_falloff);
	}

	float r_offset = (ca_strength_r + wave) * falloff;
	float b_offset = (ca_strength_b + wave) * falloff;

	vec2 offset_dir = normalize(dir + 0.0001);
	// Convert aspect-corrected direction back to UV-offset space
	vec2 r_uv = uv + offset_dir * r_offset / aspect;
	vec2 b_uv = uv + offset_dir * b_offset / aspect;

	float r = texture(SCREEN_TEXTURE, r_uv).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, b_uv).b;

	COLOR = vec4(r, g, b, 1.0);
}
