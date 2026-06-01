shader_type canvas_item;

## sprite_debug.gdshader
## Debug overlay for EPT Deuteranopia differential tokens.
## Isolates specific token masks for QA verification.

group_uniforms "Debug Control";
## 0: Normal, 1: SPEC, 2: DIR-AO, 3: TRAN, 4: CREEP, 5: CRACK, 6: RIPPLE, 7: EMIT, 8: PORO, 9: STRI
uniform int u_debug_selector : hint_range(0, 9) = 0;

group_uniforms "Differential Textures";
uniform sampler2D u_normal_map : hint_normal, repeat_disable, filter_linear;
uniform sampler2D u_mask_1 : hint_default_transparent, repeat_disable, filter_linear;
uniform sampler2D u_mask_2 : hint_default_transparent, repeat_disable, filter_linear;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.001) {
		discard;
	}

	vec4 normal_data = texture(u_normal_map, UV);
	vec4 m1 = texture(u_mask_1, UV);
	vec4 m2 = texture(u_mask_2, UV);

	float val = 0.0;

	if (u_debug_selector == 1) val = normal_data.a; // SPEC
	else if (u_debug_selector == 2) val = m1.r; // DIR-AO
	else if (u_debug_selector == 3) val = m1.g; // TRAN
	else if (u_debug_selector == 4) val = m1.b; // CREEP
	else if (u_debug_selector == 5) val = m1.a; // CRACK
	else if (u_debug_selector == 6) val = m2.r; // RIPPLE
	else if (u_debug_selector == 7) val = m2.g; // EMIT
	else if (u_debug_selector == 8) val = m2.b; // PORO
	else if (u_debug_selector == 9) val = m2.a; // STRI

	if (u_debug_selector == 0) {
		COLOR = tex * COLOR;
	} else {
		COLOR = vec4(vec3(val), tex.a);
	}
}
