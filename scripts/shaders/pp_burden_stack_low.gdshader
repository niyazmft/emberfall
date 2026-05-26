// Emberfall Sprint 1 — Burden Event Stack Low Tier
// Grade + vignette only. No CA, no grain, no scratches.
// For devices with severe bandwidth limits or accessibility "Reduce Effects".
// Performance target: ~0.05 ms/frame on Mali-G57 @ 720p

shader_type canvas_item;
render_mode unshaded;

group_uniforms Scene;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

group_uniforms Precomputed;
uniform float u_gradeBlend      : hint_range(0.0, 1.0) = 0.0;
uniform float u_vigStrengthFinal : hint_range(0.0, 2.0) = 1.3;

group_uniforms Accessibility;
uniform float u_vignetteStrength : hint_range(0.0, 1.0) = 0.65;

const vec3 TEAL = vec3(0.165, 0.435, 0.435);
const vec3 SILV = vec3(0.604, 0.549, 0.596);
const vec3 VIG_COLOR = vec3(0.0431, 0.0471, 0.0627); // #0B0C10

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 s = textureLod(screen_texture, uv, 0.0).rgb;

	float lu = dot(s, vec3(0.299, 0.587, 0.114));
	vec3 cool = mix(TEAL, SILV, lu);
	vec3 graded = mix(s, mix(vec3(lu), cool, 0.80), u_gradeBlend);

	vec2 d = uv - 0.5;
	d.x *= 1.3889;
	float v = 1.0 - dot(d, d) * u_vigStrengthFinal * u_vignetteStrength;
	v = clamp(v, 0.0, 1.0);
	vec3 final = mix(VIG_COLOR, graded, v);

	COLOR = vec4(clamp(final, 0.0, 1.0), 1.0);
}
