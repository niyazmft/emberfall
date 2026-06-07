shader_type canvas_item;

// sprite_base.gdshader
// 2.5D sprite shader with EPT Deuteranopia differential tokens.
// Target: Mali-G57 @ 1080p (< 0.2ms batch)
// References: asset-specs/ept-deuteranopia-texture-shape-differentials.md

// Deuteranopia Differentials
uniform bool u_HAS_SPEC = false;
uniform bool u_HAS_DIR_AO = false;
uniform bool u_HAS_TRAN = false;
uniform bool u_HAS_CREEP = false;
uniform bool u_HAS_CRACK = false;
uniform bool u_HAS_RIPPLE = false;
uniform bool u_HAS_EMIT = false;
uniform bool u_HAS_PORO = false;
uniform bool u_HAS_STRI = false;

// Differential Textures
uniform sampler2D u_normal_map : hint_normal, repeat_disable, filter_linear;
uniform sampler2D u_mask_1 : hint_default_transparent, repeat_disable, filter_linear;
uniform sampler2D u_mask_2 : hint_default_transparent, repeat_disable, filter_linear;

// Hit Flash
uniform float u_hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 u_hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Shading Constants (Fixed to stay under 12-uniform ceiling)
const vec3 LIGHT_DIR = vec3(-0.5, -0.5, 1.0);
const float AMBIENT_BASE = 0.4;
const float SPECULAR_POWER = 16.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.001) {
		discard;
	}

	// Sample 2x resolution maps
	vec4 normal_data = texture(u_normal_map, UV);

	// Conditional sampling for performance on Mali-G57
	vec4 m1 = vec4(0.0);
	if (u_HAS_DIR_AO || u_HAS_TRAN || u_HAS_CREEP || u_HAS_CRACK) {
		m1 = texture(u_mask_1, UV);
	}

	vec4 m2 = vec4(0.0);
	if (u_HAS_RIPPLE || u_HAS_EMIT || u_HAS_PORO || u_HAS_STRI) {
		m2 = texture(u_mask_2, UV);
	}

	// --- Token Decoding ---
	float t_spec   = normal_data.a * float(u_HAS_SPEC);
	float t_dir_ao = m1.r * float(u_HAS_DIR_AO);
	float t_tran   = m1.g * float(u_HAS_TRAN);
	float t_creep  = m1.b * float(u_HAS_CREEP);
	float t_crack  = m1.a * float(u_HAS_CRACK);
	float t_ripple = m2.r * float(u_HAS_RIPPLE);
	float t_emit   = m2.g * float(u_HAS_EMIT);
	float t_poro   = m2.b * float(u_HAS_PORO);
	float t_stri   = m2.a * float(u_HAS_STRI);

	// --- Shading Logic ---
	vec3 normal = normalize(normal_data.rgb * 2.0 - 1.0);
	vec3 light = normalize(LIGHT_DIR);
	float ndotl = max(dot(normal, light), 0.0);

	// Apply DIR-AO to ambient
	float ambient = AMBIENT_BASE * (1.0 - t_dir_ao * 0.5);
	float diffuse = ndotl;

	// Specular + SPEC token
	vec3 view = vec3(0.0, 0.0, 1.0);
	vec3 half_vec = normalize(light + view);
	float spec_base = pow(max(dot(normal, half_vec), 0.0), SPECULAR_POWER);
	float spec = spec_base * (0.2 + t_spec * 0.8) * ndotl;

	// TRAN (Subsurface-ish)
	float translucency = t_tran * max(dot(-normal, light), 0.0) * 0.5;

	vec3 base_col = tex.rgb * COLOR.rgb;

	// Apply Mask Differentials (CREEP, CRACK, PORO, STRI)
	// These affect luminance to survive desaturation
	float mask_accum = t_creep * 0.2 + t_crack * 0.3 + t_poro * 0.15 + t_stri * 0.1;
	base_col *= (1.0 - mask_accum);

	// RIPPLE (UV distortion simulation via luminance shift)
	// mod() protects against precision loss over time on mobile
	base_col += t_ripple * 0.1 * sin(UV.y * 100.0 + mod(TIME * 5.0, 6.2831853));

	vec3 lit = base_col * (ambient + diffuse + translucency) + vec3(spec);

	// EMIT (Glow)
	lit += t_emit * vec3(1.0, 0.9, 0.7) * 0.5;

	COLOR = vec4(lit, tex.a * COLOR.a);

	// Hit Flash overlay
	COLOR.rgb = mix(COLOR.rgb, u_hit_flash_color.rgb, u_hit_flash * u_hit_flash_color.a);
}
