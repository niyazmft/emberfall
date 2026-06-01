shader_type canvas_item;
render_mode unshaded;

## pp_vignette_dynamic.gdshader
## Dynamic breathing vignette for Emberfall post-process stack.
##
## Performance tier: low
## Target platforms: Forward+, Mobile, Compatibility
## Author: Godot Shader Specialist
## References: Art Bible §5, MWT-3 §2.3, DON-254 Item 3

group_uniforms "Vignette Shape";
uniform float vig_radius : hint_range(0.0, 2.0) = 0.65;
uniform float vig_softness : hint_range(0.0, 1.0) = 0.35;
uniform float vig_opacity : hint_range(0.0, 1.0) = 0.5;

group_uniforms "Vignette Colour";
uniform vec3 vig_color : source_color = vec3(0.0431, 0.0471, 0.0627); // #0B0C10 Void Black

group_uniforms "Dynamic Breathing (Burden Event)";
uniform bool burden_active = false;
uniform float vig_opacity_amp : hint_range(0.0, 0.1) = 0.02;   // 0.48-0.52 range base
uniform float vig_opacity_cycle_s : hint_range(0.0, 10.0) = 4.0;
uniform float vig_radius_amp : hint_range(0.0, 0.1) = 0.02;     // 0.63-0.67 range base
uniform float vig_radius_cycle_s : hint_range(0.0, 10.0) = 5.5;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	float dist = length((uv - vec2(0.5)) * aspect);

	// Base vignette factor
	float vignette = smoothstep(vig_radius, vig_radius - vig_softness, dist);
	vignette = clamp(vignette, 0.0, 1.0);

	// Breathing modulation (only while Burden Event is active)
	float opacity_final = vig_opacity;
	float radius_final = vig_radius;
	if (burden_active) {
		float t = TIME;
		opacity_final += vig_opacity_amp * sin(t * 6.28318530718 / vig_opacity_cycle_s);
		radius_final += vig_radius_amp * sin(t * 6.28318530718 / vig_radius_cycle_s);
		// Recompute with breathed radius
		vignette = smoothstep(radius_final, radius_final - vig_softness, dist);
		vignette = clamp(vignette, 0.0, 1.0);
	}

	vec3 col = texture(SCREEN_TEXTURE, uv).rgb;
	vec3 vigged = mix(vig_color, col, vignette);
	vec3 final_col = mix(col, vigged, opacity_final);

	COLOR = vec4(final_col, 1.0);
}
