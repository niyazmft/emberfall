shader_type canvas_item;
render_mode unshaded;

## cvd_simulation.gdshader
## Color Vision Deficiency (CVD) simulation for accessibility testing.
## Supports Deuteranopia (red-green color blindness).
##
## References: DON-82, DON-258

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool u_active = true;

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	if (u_active) {
		// Simple LMS-based Deuteranopia simulation matrix
		// This approximates how colors appear to someone with Deuteranopia.
		float r = col.r;
		float g = col.g;
		float b = col.b;

		float dr = 0.625 * r + 0.375 * g;
		float dg = 0.7 * r + 0.3 * g;
		float db = 0.0 * r + 0.3 * g + 0.7 * b;

		col.rgb = vec3(dr, dg, db);
	}
	COLOR = col;
}
