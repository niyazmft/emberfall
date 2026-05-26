// Emberfall Sprint 1 — Burden Event Post-Process Stack (Fused Single-Pass)
// Memory Weight Threshold = 3 visual stack.
// Targets: Art Director review DON-56 (changes requested 2026-05-25)
//
// Pass architecture: ONE fullscreen resolve pass.
//   Stage 1 — Colour-grade blend (35 % warm / 65 % cool)
//   Stage 2 — Chromatic aberration (radial from screen centre / Keeper position)
//   Stage 3 — Dynamic vignette (persistent breathing, CPU-driven opacity + radius)
//   Stage 4 — Film grain + micro-scratches (tiled 256×256 texture)
//
// Performance target: ≤ 0.2 ms/frame persistent (target ~0.12 ms) on Mali-G57 @ 720p
// Mobile-safe: mediump, no derivatives, no discard, no branching.
// Engine: Godot 4.x CanvasItem ColorRect in unshaded mode.

shader_type canvas_item;
render_mode unshaded;

group_uniforms Scene;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D u_grainTex      : repeat_enable, filter_nearest;

group_uniforms BurdenState;
uniform float u_burdenRatio  : hint_range(0.0, 1.0) = 0.0;
uniform float u_time;
uniform vec2  u_caCenter     = vec2(0.5, 0.5);

group_uniforms Precomputed;
// Engine resolves these from burdenRatio + accessibility scalars per frame:
uniform float u_gradeBlend      : hint_range(0.0, 1.0) = 0.0;
uniform float u_caBlend         : hint_range(0.0, 1.0) = 0.0;
uniform float u_caPx            : hint_range(0.0, 0.1) = 0.0;
uniform float u_vigStrengthFinal : hint_range(0.0, 2.0) = 1.3;
uniform float u_grainStrength    : hint_range(0.0, 1.0) = 0.0;
uniform float u_scratchOpacity   : hint_range(0.0, 1.0) = 0.0;

group_uniforms Accessibility;
uniform float u_chromaticAberrationStrength : hint_range(0.0, 1.0) = 1.0;
uniform float u_vignetteStrength            : hint_range(0.0, 1.0) = 0.65;
uniform float u_filmEffectsStrength           : hint_range(0.0, 1.0) = 1.0;

// Art palette constants (Art Bible §5)
const vec3 TEAL     = vec3(0.165, 0.435, 0.435);
const vec3 SILV     = vec3(0.604, 0.549, 0.596);
const vec3 SC_COL   = vec3(0.878, 0.863, 0.820);
const vec3 VIG_COLOR = vec3(0.0431, 0.0471, 0.0627); // #0B0C10

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 s = textureLod(screen_texture, uv, 0.0).rgb;

	// Stage 1 — Colour-grade blend (cool-dominant LUT proxy)
	float lu = dot(s, vec3(0.299, 0.587, 0.114));
	vec3 cool = mix(TEAL, SILV, lu);
	vec3 graded = mix(s, mix(vec3(lu), cool, 0.80), u_gradeBlend);

	// Stage 2 — Chromatic aberration (+12 px R / −12 px B approx in UV space)
	vec2 c = uv - u_caCenter;
	float ca_len = length(c) * u_caPx * u_chromaticAberrationStrength;
	vec2 o = normalize(c) * ca_len;
	vec3 a = graded;
	a.r = textureLod(screen_texture, uv + o, 0.0).r;
	a.b = textureLod(screen_texture, uv - o * 1.5, 0.0).b;
	vec3 ca_result = mix(graded, a, u_caBlend);

	// Stage 3 — Dynamic vignette (strength final includes breathing + radius)
	vec2 d = uv - 0.5;
	d.x *= 1.3889;
	float v = 1.0 - dot(d, d) * u_vigStrengthFinal * u_vignetteStrength;
	v = clamp(v, 0.0, 1.0);
	vec3 vig_result = mix(VIG_COLOR, ca_result, v);

	// Stage 4 — Film grain + micro-scratches (tiled texture)
	vec3 grain = textureLod(u_grainTex, uv * 256.0, 0.0).rgb;
	float scratch = step(0.98, grain.g) * u_scratchOpacity * u_filmEffectsStrength;
	vec3 grain_result = vig_result + (grain.r - 0.5) * u_grainStrength * lu * u_filmEffectsStrength;
	vec3 final = mix(grain_result, SC_COL, scratch);

	COLOR = vec4(clamp(final, 0.0, 1.0), 1.0);
}
