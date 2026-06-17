shader_type canvas_item;
render_mode unshaded;

## cvd_simulation.gdshader
## Color Vision Deficiency (CVD) simulation for accessibility testing.
## Supports Protanopia, Deuteranopia, and Tritanopia.
##
## This implementation uses standard matrices to approximate CVD.
## References: DON-82, DON-258, Machado et al. 2009

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int u_mode : hint_range(0, 3) = 2; // 0: None, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);

	if (u_mode > 0) {
		// Convert to linear RGB
		vec3 rgb_linear = col.rgb * col.rgb;
		vec3 sim;

		if (u_mode == 1) { // Protanopia
			const mat3 prot_mat = mat3(
				vec3(0.152, 0.115, -0.004),
				vec3(1.053, 0.786, -0.048),
				vec3(-0.205, 0.099, 1.052)
			);
			sim = prot_mat * rgb_linear;
		} else if (u_mode == 2) { // Deuteranopia
			const mat3 deut_mat = mat3(
				vec3(0.367, 0.280, -0.012),
				vec3(0.861, 0.673, 0.043),
				vec3(-0.228, 0.047, 0.969)
			);
			sim = deut_mat * rgb_linear;
		} else if (u_mode == 3) { // Tritanopia
			const mat3 trit_mat = mat3(
				vec3(1.016, 0.006, 0.023),
				vec3(0.054, 0.951, -0.156),
				vec3(-0.071, 0.043, 1.133)
			);
			sim = trit_mat * rgb_linear;
		}

		// Convert back to gamma space
		col.rgb = sqrt(clamp(sim, 0.0, 1.0));
	}

	COLOR = col;
}
