shader_type canvas_item;
render_mode unshaded;

## vignette.gdshader
## Standalone vignette shader for Emberfall.
## DON-56: Update default color to #0B0C10 and fix mixing logic.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float u_vignetteOpacity : hint_range(0.0, 1.0) = 0.5;
uniform float u_vignetteRadius : hint_range(0.0, 2.0) = 0.8;
uniform float u_vignetteSoftness : hint_range(0.0, 1.0) = 0.4;
uniform vec3 u_vigColor : source_color = vec3(0.0431, 0.0471, 0.0627); // #0B0C10 Void Black

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 screen_col = textureLod(screen_texture, uv, 0.0);

	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	float dist = length((uv - vec2(0.5)) * aspect);
	float v = smoothstep(u_vignetteRadius - u_vignetteSoftness, u_vignetteRadius, dist);

	vec3 vigged_col = mix(screen_col.rgb, u_vigColor, v);
	vec3 final_col = mix(screen_col.rgb, vigged_col, u_vignetteOpacity);

	COLOR = vec4(final_col, screen_col.a);
}
