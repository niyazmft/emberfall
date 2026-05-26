shader_type canvas_item;
render_mode unshaded;

## pp_colour_grade_blend.gdshader
## LUT-based colour grade for Emberfall post-process stack.
## Blends a biome-dependent Base LUT with a global Burden LUT.
##
## Performance tier: medium
## Target platforms: Forward+, Mobile
## Author: Godot Shader Specialist
## References: Art Bible §5, MWT-3 §2.1, DON-254 Item 1

group_uniforms "LUT Textures";
uniform sampler3D u_lut_base : repeat_disable, filter_linear;
uniform sampler3D u_lut_burden : repeat_disable, filter_linear;

group_uniforms "Blend Weights";
uniform float lut_weight_base : hint_range(0.0, 1.0) = 1.0;
uniform float lut_weight_burden : hint_range(0.0, 1.0) = 0.0;

group_uniforms "LUT Sampling";
uniform float lut_size : hint_range(1.0, 64.0) = 33.0;

## ── Helpers ──────────────────────────────────────────────────────

vec3 lut_sample(sampler3D lut_tex, vec3 colour) {
	// Scale colour to avoid edge bleeding in discrete 3D LUT.
	// texel centre offset: (size - 1) / size mapped to 0..1
	float scale = (lut_size - 1.0) / lut_size;
	float offset = 1.0 / (2.0 * lut_size);
	vec3 uvw = clamp(colour * scale + offset, offset, 1.0 - offset);
	return texture(lut_tex, uvw).rgb;
}

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 base = lut_sample(u_lut_base, screen.rgb);
	vec3 burden = lut_sample(u_lut_burden, screen.rgb);

	// Weighted blend; weights are independent so caller can overdrive >1.0.
	float w_total = lut_weight_base + lut_weight_burden;
	w_total = max(w_total, 0.001); // prevent div-zero
	vec3 blended = (base * lut_weight_base + burden * lut_weight_burden) / w_total;

	COLOR = vec4(blended, screen.a);
}
