shader_type canvas_item;
render_mode unshaded;

## pp_burden_master.gdshader
## Consolidated post-process stack for Emberfall.
## Merges vignette, colour grading, and chromatic aberration into a single resolve pass.
##
## Performance tier: medium
## Target platforms: Forward+, Mobile
## Author: Jules
## References: DON-263 Engine integration

// Global skip-gate logic
global uniform bool u_burden_active;
global uniform sampler2D u_burden_scratch_buffer;

// Godot 4 Screen Texture
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- Vignette Uniforms ---
group_uniforms "Vignette Shape";
uniform float vig_radius : hint_range(0.0, 2.0) = 0.65;
uniform float vig_softness : hint_range(0.0, 1.0) = 0.35;
uniform float vig_opacity : hint_range(0.0, 1.0) = 0.5;
group_uniforms "Vignette Colour";
uniform vec3 vig_color : source_color = vec3(0.0431, 0.0471, 0.0627); // #0B0C10 Void Black
group_uniforms "Vignette Dynamic Breathing";
uniform float vig_opacity_amp : hint_range(0.0, 0.1) = 0.02;
uniform float vig_opacity_cycle_s : hint_range(0.0, 10.0) = 4.0;
uniform float vig_radius_amp : hint_range(0.0, 0.1) = 0.02;
uniform float vig_radius_cycle_s : hint_range(0.0, 10.0) = 5.5;

// --- Colour Grade Uniforms ---
group_uniforms "LUT Textures";
uniform sampler3D u_lut_base : repeat_disable, filter_linear;
uniform sampler3D u_lut_burden : repeat_disable, filter_linear;
group_uniforms "LUT Blend Weights";
uniform float lut_weight_base : hint_range(0.0, 1.0) = 1.0;
uniform float lut_weight_burden : hint_range(0.0, 1.0) = 0.0;
group_uniforms "LUT Sampling";
uniform float lut_size : hint_range(1.0, 64.0) = 33.0;

// --- Chromatic Aberration Uniforms ---
group_uniforms "CA Channel Offsets";
uniform float ca_strength_r : hint_range(-0.05, 0.05) = 0.003;
uniform float ca_strength_b : hint_range(-0.05, 0.05) = -0.005;
group_uniforms "CA Direction & Wave";
uniform int ca_direction_mode : hint_range(0, 1) = 0;
uniform vec2 u_keeper_screen_pos = vec2(0.5, 0.5);
uniform float ca_wave : hint_range(0.0, 1.0) = 0.0;
uniform float ca_wave_freq_hz : hint_range(0.0, 10.0) = 2.0;
group_uniforms "CA Edge Falloff";
uniform float ca_edge_falloff : hint_range(0.0, 1.0) = 1.0;
uniform float ca_edge_power : hint_range(0.1, 4.0) = 1.0;

// --- Helpers ---

vec3 lut_sample(sampler3D lut_tex, vec3 colour) {
	float scale = (lut_size - 1.0) / lut_size;
	float offset = 1.0 / (2.0 * lut_size);
	vec3 uvw = clamp(colour * scale + offset, offset, 1.0 - offset);
	return texture(lut_tex, uvw).rgb;
}

void fragment() {
	// Skip-gate check (redundant with node visibility but safe)
	if (!u_burden_active) {
		COLOR = texture(screen_texture, SCREEN_UV);
		return;
	}

	vec2 uv = SCREEN_UV;
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);

	// 1. Chromatic Aberration (Resolve pass 1, 2, 3 - merged into coordinated texture fetches)
	vec2 centre = mix(vec2(0.5), u_keeper_screen_pos, float(ca_direction_mode));
	vec2 dir = (uv - centre) * aspect;
	float dist = length(dir);

	float wave = ca_wave > 0.0 ? ca_wave * sin(TIME * ca_wave_freq_hz * 6.28318530718) : 0.0;
	float ca_falloff = 1.0;
	if (ca_edge_falloff > 0.0) {
		ca_falloff = pow(cos(clamp(dist * 1.57079632679, 0.0, 1.57079632679)), ca_edge_power);
		ca_falloff = mix(1.0, ca_falloff, ca_edge_falloff);
	}

	float r_offset = (ca_strength_r + wave) * ca_falloff;
	float b_offset = (ca_strength_b + wave) * ca_falloff;
	vec2 offset_dir = normalize(dir + 0.0001);
	vec2 r_uv = uv + offset_dir * r_offset / aspect;
	vec2 b_uv = uv + offset_dir * b_offset / aspect;

	float r = texture(screen_texture, r_uv).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, b_uv).b;
	vec3 raw_col = vec3(r, g, b);

	// 2. Colour Grading
	vec3 base_lut = lut_sample(u_lut_base, raw_col);
	vec3 burden_lut = lut_sample(u_lut_burden, raw_col);
	float w_total = max(lut_weight_base + lut_weight_burden, 0.001);
	vec3 graded_col = (base_lut * lut_weight_base + burden_lut * lut_weight_burden) / w_total;

	// 3. Vignette
	float t = TIME;
	float opacity_final = vig_opacity + vig_opacity_amp * sin(t * 6.28318530718 / vig_opacity_cycle_s);
	float radius_final = vig_radius + vig_radius_amp * sin(t * 6.28318530718 / vig_radius_cycle_s);

	float vignette = smoothstep(radius_final, radius_final - vig_softness, dist);
	vignette = clamp(vignette, 0.0, 1.0);

	vec3 vigged_col = mix(vig_color, graded_col, vignette);
	vec3 final_col = mix(graded_col, vigged_col, opacity_final);

	COLOR = vec4(final_col, 1.0);
}
