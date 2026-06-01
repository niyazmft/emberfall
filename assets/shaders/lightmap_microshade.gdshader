shader_type canvas_item;
render_mode unshaded;

## lightmap_microshade.gdshader
## Sprite normal-map micro-shading for Emberfall 2.5D characters.
##
## Performance tier: medium
## Target platforms: Forward+, Mobile
## Author: Godot Shader Specialist
## References: Art Bible §2, DON-254 Item 4
##
## NOTE: Assumes object-space normal maps (RGB = XYZ) as produced by
## the sprite pipeline. If tangent-space conversion is added later,
## update u_light_dir to match the TBN basis.

group_uniforms "Light Direction";
## Top-left 45° key light per Art Bible §2.
uniform vec3 u_light_dir = vec3(-0.5, -0.5, 1.0);

group_uniforms "Normal Map";
uniform sampler2D u_normal_map : repeat_disable, filter_linear;
uniform float u_normal_strength : hint_range(0.0, 2.0) = 1.0;

group_uniforms "Shading Intensity";
uniform float u_ambient : hint_range(0.0, 1.0) = 0.4;
uniform float u_diffuse_boost : hint_range(0.0, 2.0) = 1.0;
uniform float u_specular_power : hint_range(1.0, 64.0) = 16.0;
uniform float u_specular_intensity : hint_range(0.0, 1.0) = 0.2;

group_uniforms "EPT Differentials (DON-258)";
uniform bool u_HAS_SPEC = false;
uniform bool u_HAS_DIR_AO = false;
uniform bool u_HAS_TRAN = false;
uniform bool u_HAS_CREEP = false;
uniform bool u_HAS_CRACK = false;
uniform bool u_HAS_RIPPLE = false;
uniform bool u_HAS_EMIT = false;
uniform bool u_HAS_PORO = false;
uniform bool u_HAS_STRI = false;
uniform bool u_HAS_OUTLINE = false;

group_uniforms "EPT Mask (Optional)";
uniform sampler2D u_differential_mask : source_color, hint_default_black;

// Procedural helpers for EPT tokens
float ept_hash(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float strike_pattern(vec2 uv) {
	return step(0.5, fract(uv.x * 20.0 + uv.y * 10.0));
}

float ripple_pattern(vec2 uv) {
	vec2 center = vec2(0.5);
	float d = distance(uv, center);
	return step(0.5, fract(d * 30.0));
}

float crack_pattern(vec2 uv) {
	vec2 g = fract(uv * 10.0);
	return max(step(0.95, g.x), step(0.95, g.y));
}

float poro_pattern(vec2 uv) {
	vec2 g = fract(uv * 20.0);
	return 1.0 - smoothstep(0.4, 0.5, distance(g, vec2(0.5)));
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.001) {
		discard;
	}

	// Object-space normal from sprite normal map
	vec3 normal = texture(u_normal_map, UV).rgb * 2.0 - 1.0;
	normal = normalize(normal * vec3(u_normal_strength, u_normal_strength, 1.0));

	// Light vector (top-left 45°)
	vec3 light = normalize(u_light_dir);

	// Diffuse term (Lambert)
	float ndotl = max(dot(normal, light), 0.0);
	float diffuse = u_ambient + ndotl * (1.0 - u_ambient) * u_diffuse_boost;

	// Specular term (Blinn-Phong-ish)
	vec3 view = vec3(0.0, 0.0, 1.0);
	vec3 half_vec = normalize(light + view);
	float spec_base = pow(max(dot(normal, half_vec), 0.0), u_specular_power);

	float spec_mult = 1.0;
	if (u_HAS_SPEC) {
		spec_mult = 3.0; // Stronger specular for SPEC flag
	}
	float specular = spec_base * u_specular_intensity * ndotl * spec_mult;

	vec3 lit = tex.rgb * diffuse + vec3(specular);

	// Apply DIR_AO
	if (u_HAS_DIR_AO) {
		float ao = clamp(dot(normal, vec3(0.7, 0.7, 0.0)) * 0.5 + 0.5, 0.4, 1.0);
		lit *= ao;
	}

	// Apply EMIT
	if (u_HAS_EMIT) {
		lit += tex.rgb * 0.4; // Soft additive glow
	}

	// Procedural Textures for other flags (tokens)
	float token = 0.0;
	if (u_HAS_STRI) token = max(token, strike_pattern(UV) * 0.3);
	if (u_HAS_RIPPLE) token = max(token, ripple_pattern(UV) * 0.3);
	if (u_HAS_CRACK) token = max(token, crack_pattern(UV) * 0.4);
	if (u_HAS_PORO) token = max(token, poro_pattern(UV) * 0.2);

	// Apply token as darkening (prefer baked mask if available)
	vec4 mask_tex = texture(u_differential_mask, UV);
	float mask_val = mask_tex.r; // Red channel for mask

	float final_token = mask_val > 0.001 ? mask_val : token;
	lit = mix(lit, lit * 0.5, final_token);

	// Apply Outline (Inner)
	if (u_HAS_OUTLINE) {
		vec2 size = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
		float alpha = texture(TEXTURE, UV).a;
		float alpha_n = texture(TEXTURE, UV + vec2(0, -size.y)).a;
		float alpha_s = texture(TEXTURE, UV + vec2(0, size.y)).a;
		float alpha_e = texture(TEXTURE, UV + vec2(size.x, 0)).a;
		float alpha_w = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
		float edge = clamp(alpha * 4.0 - (alpha_n + alpha_s + alpha_e + alpha_w), 0.0, 1.0);
		lit = mix(lit, vec3(1.0), edge);
	}

	// CREEP: noise-like overlay
	if (u_HAS_CREEP) {
		float creep = step(0.7, ept_hash(UV * 5.0));
		lit = mix(lit, vec3(0.1, 0.2, 0.1), creep * 0.3);
	}

	// TRAN: pseudo-translucency (just brighten slightly)
	if (u_HAS_TRAN) {
		lit += vec3(0.05, 0.1, 0.1);
	}

	COLOR = vec4(lit, tex.a);
}
