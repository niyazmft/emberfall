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
		// Convert to linear RGB
		vec3 rgb_linear = col.rgb * col.rgb;

		// Deuteranopia simulation matrix (Machado, Oliveira, and Fernandes 2009)
		const mat3 deut_mat = mat3(
			vec3(0.367, 0.633, 0.000), // R output
			vec3(0.280, 0.720, 0.000), // G output
			vec3(-0.012, 0.027, 0.985)  // B output
		);

		vec3 sim = rgb_linear * deut_mat;

		// Convert back to gamma space
		col.rgb = sqrt(clamp(sim, 0.0, 1.0));
	}
	COLOR = col;
}
