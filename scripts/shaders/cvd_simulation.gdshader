shader_type canvas_item;

uniform int mode : hint_range(0, 4) = 0; // 0: Normal, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia, 4: Achromatopsia
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// CVD matrices from Viénot et al. 1999
// Conversion to LMS, adjustment, then back to RGB

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	vec3 rgb = color.rgb;

	if (mode == 0) {
		COLOR = color;
		return;
	}

	// Simple linear transformation matrices (not fully accurate but good for debug)
	mat3 cvd_mat;
	if (mode == 1) { // Protanopia
		cvd_mat = mat3(
			vec3(0.56667, 0.55833, 0.0),
			vec3(0.43333, 0.44167, 0.24167),
			vec3(0.0, 0.0, 0.75833)
		);
	} else if (mode == 2) { // Deuteranopia
		cvd_mat = mat3(
			vec3(0.625, 0.7, 0.0),
			vec3(0.375, 0.3, 0.3),
			vec3(0.0, 0.0, 0.7)
		);
	} else if (mode == 3) { // Tritanopia
		cvd_mat = mat3(
			vec3(0.95, 0.0, 0.0),
			vec3(0.05, 0.43333, 0.475),
			vec3(0.0, 0.56667, 0.525)
		);
	} else if (mode == 4) { // Achromatopsia
		float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
		COLOR = vec4(vec3(gray), color.a);
		return;
	}

	COLOR = vec4(rgb * cvd_mat, color.a);
}
