shader_type canvas_item;
render_mode unshaded;

## cvd_simulation.gdshader
## Color Vision Deficiency (CVD) simulation for accessibility testing.
## Supports Deuteranopia (red-green color blindness).
##
## This implementation uses a standard LMS-based simulation matrix
## to approximate Deuteranopia (Vienot et al. 1999).
##
## References: DON-82, DON-258

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool u_active = true;

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	if (u_active) {
		// Convert to linear RGB (approximate)
		vec3 rgb = pow(col.rgb, vec3(2.2));

		// Deuteranopia simulation matrix (Machado, Oliveira, and Fernandes 2009)
		// Note: mat3 constructor in GLSL/GDShader is COLUMN-MAJOR.
		mat3 deut_mat = mat3(
			vec3(0.367, 0.280, -0.012), // Column 1
			vec3(0.633, 0.720, 0.027),  // Column 2
			vec3(0.000, 0.000, 0.985)   // Column 3
		);

		vec3 sim = deut_mat * rgb;

		// Convert back to gamma space
		col.rgb = pow(clamp(sim, 0.0, 1.0), vec3(1.0 / 2.2));
	}
	COLOR = col;
}
