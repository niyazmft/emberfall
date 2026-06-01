shader_type canvas_item;
render_mode unshaded;

## pp_burden_stack_mid.gdshader
## Consolidated post-process stack for Burden Event (Mid Tier).
## DON-56: Symmetrical Bilateral CA and Correct Vignette Mixing.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

group_uniforms "LUT Textures";
uniform sampler3D u_lut_base : repeat_disable, filter_linear;
uniform sampler3D u_lut_burden : repeat_disable, filter_linear;

group_uniforms "Weights & Parameters";
uniform float lut_weight_base : hint_range(0.0, 2.0) = 1.0;
uniform float lut_weight_burden : hint_range(0.0, 2.0) = 0.0;
uniform float lut_size : hint_range(1.0, 64.0) = 33.0;

uniform float u_caBlend : hint_range(0.0, 1.0) = 0.5;
uniform vec2 u_caOffset = vec2(0.002, 0.0);

uniform float u_vignetteOpacity : hint_range(0.0, 1.0) = 0.5;
uniform float u_vignetteRadius : hint_range(0.0, 2.0) = 0.8;
uniform float u_vignetteSoftness : hint_range(0.0, 1.0) = 0.4;

const vec3 VIG_COLOR = vec3(0.0431, 0.0471, 0.0627); // #0B0C10 Void Black

vec3 lut_sample(sampler3D lut_tex, vec3 colour) {
	float scale = (lut_size - 1.0) / lut_size;
	float offset = 1.0 / (2.0 * lut_size);
	vec3 uvw = clamp(colour * scale + offset, offset, 1.0 - offset);
	return texture(lut_tex, uvw).rgb;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 central_sample = textureLod(screen_texture, uv, 0.0);

	// 1. Symmetrical Bilateral Chromatic Aberration
	// Optimized: 3 texture fetches
	vec2 o = u_caOffset;
	vec3 ca;
	ca.r = textureLod(screen_texture, uv + o, 0.0).r;
	ca.g = central_sample.g;
	ca.b = textureLod(screen_texture, uv - o, 0.0).b;
	// Jules: Fixed bilateral CA logic (R+o, B-o) and optimized fetches
	vec3 ca_result = mix(central_sample.rgb, ca, u_caBlend);

	// 2. Colour Grading
	vec3 graded;
	float w_total = lut_weight_base + lut_weight_burden;
	if (w_total > 0.001) {
		vec3 grade_base = lut_sample(u_lut_base, ca_result);
		vec3 grade_burden = lut_sample(u_lut_burden, ca_result);
		graded = (grade_base * lut_weight_base + grade_burden * lut_weight_burden) / w_total;
	} else {
		graded = ca_result;
	}

	// 3. Vignette
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	float dist = length((uv - vec2(0.5)) * aspect);
	float v = smoothstep(u_vignetteRadius - u_vignetteSoftness, u_vignetteRadius, dist);

	vec3 vigged = mix(graded, VIG_COLOR, v);
	vec3 final_color = mix(graded, vigged, u_vignetteOpacity);

	COLOR = vec4(final_color, central_sample.a);
}
