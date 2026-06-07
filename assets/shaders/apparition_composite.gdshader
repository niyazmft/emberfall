shader_type canvas_item;

// Apparition Composite Tint Shader
// Burden Event Asset Spec §2.2
// Single-pass composite tinting for apparition silhouettes.

uniform float u_desaturation_amount : hint_range(0.0, 1.0) = 0.2;
uniform float u_spectral_tint_opacity : hint_range(0.0, 1.0) = 0.4;
uniform vec4 u_spectral_tint_color : source_color = vec4(0.1647, 0.4353, 0.4353, 1.0);
uniform float u_inner_bleed_opacity : hint_range(0.0, 1.0) = 0.15;
uniform vec4 u_inner_bleed_color : source_color = vec4(0.6039, 0.5490, 0.5961, 1.0);
uniform float u_after_trail_opacity : hint_range(0.0, 1.0) = 0.2;
uniform vec4 u_after_trail_color : source_color = vec4(0.7882, 0.6784, 0.6549, 1.0);
uniform float u_intensity : hint_range(0.0, 2.0) = 1.0;

// Dissolve uniforms
uniform float u_dissolve_threshold : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D u_dissolve_noise : repeat_enable;

// Shear uniforms
uniform float u_shear_intensity : hint_range(-2.0, 2.0) = 0.0;

// Hit Flash uniforms
uniform float u_hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 u_hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

vec3 grayscale_weights() {
	return vec3(0.299, 0.587, 0.114);
}

vec3 screen_blend(vec3 base, vec3 blend) {
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

void vertex() {
	// Recoil shear
	VERTEX.x += VERTEX.y * u_shear_intensity;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Dissolve logic
	if (u_dissolve_threshold > 0.0) {
		float noise = texture(u_dissolve_noise, UV).r;
		if (noise < u_dissolve_threshold) {
			discard;
		}
	}

	vec3 col = tex.rgb * COLOR.rgb;
	float alpha = tex.a * COLOR.a;

	if (alpha < 0.001) {
		discard;
	}

	// 1. Desaturation x0.20 (preserve 20 % of original chroma)
	float gray = dot(col, grayscale_weights());
	vec3 desat_col = mix(vec3(gray), col, u_desaturation_amount);

	// 2. Spectral cool tint (Screen 40 %)
	vec3 screen_col = screen_blend(desat_col, u_spectral_tint_color.rgb);
	vec3 tinted = mix(desat_col, screen_col, u_spectral_tint_opacity);

	// 3. Inner edge bleed (Add 15 %)
	vec3 bleed = tinted + u_inner_bleed_color.rgb * u_inner_bleed_opacity;
	bleed = clamp(bleed, 0.0, 1.0);

	// 4. After-image trail (Multiply inverse 20 %)
	vec3 inverse_trail = vec3(1.0) - u_after_trail_color.rgb;
	vec3 trail = mix(vec3(1.0), inverse_trail, u_after_trail_opacity);
	vec3 final_col = bleed * trail;

	COLOR = vec4(final_col * u_intensity, alpha);

	// Hit Flash overlay
	COLOR.rgb = mix(COLOR.rgb, u_hit_flash_color.rgb, u_hit_flash * u_hit_flash_color.a);
}
