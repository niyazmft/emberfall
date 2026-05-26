// Emberfall Sprint 1 — Apparition Composite Material
// Spectral tint + inner-edge bleed + procedural dissolve for Burden Event apparitions.
// Applied to each of the 3 stacked silhouette sprites in the rig (see apparition_composite_spec.md).
//
// Performance target: ≤ 0.05 ms/sprite on Mali-G57 @ 720p
// Shader complexity: ~17 ALU, 1 texture, 7 uniforms, 0 branches, 0 discard
// Mobile-safe: mediump implicitly via Godot CanvasItem defaults; no pow(), no derivatives.

shader_type canvas_item;
render_mode blend_mix;

group_uniforms Apparition;
uniform float u_tintStrength   : hint_range(0.0, 1.0) = 0.70;
uniform float u_edgeBleed      : hint_range(0.0, 1.0) = 0.45;
uniform float u_dissolve       : hint_range(0.0, 1.0) = 0.0;
uniform float u_alphaMaster    : hint_range(0.0, 1.0) = 1.0;
uniform float u_time           : hint_range(0.0, 10000.0) = 0.0;
uniform float u_shear          : hint_range(-0.5, 0.5) = 0.0;
uniform float u_saturationDampen : hint_range(0.0, 1.0) = 0.0; // Saturation guard (off by default, see apparition_material_pipeline.md §6)

group_uniforms Palette;
uniform vec3 u_spectralTint : source_color = vec3(0.165, 0.435, 0.435); // TEAL (#2A6F6F)

void vertex() {
	// Recoil shear: skew sprite horizontally based on vertical position.
	// Engine drives u_shear from Keeper recoil events.
	VERTEX.x += u_shear * VERTEX.y;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float a = tex.a;

	// Inner-edge bleed: peaks where anti-aliased alpha is mid-range.
	float edge = 4.0 * a * (1.0 - a);
	vec3 glow = u_spectralTint * edge * u_edgeBleed;

	// Spectral cool tint (full silhouette)
	vec3 tinted = mix(tex.rgb, u_spectralTint, u_tintStrength * a);

	// Procedural dissolve (absolve effect). 2D hash seeded by UV and time.
	float noise = fract(sin(dot(UV * 100.0, vec2(12.9898, 78.233)) + u_time * 0.1) * 43758.5453);
	float dissolveMask = step(u_dissolve, noise);

	vec3 final = tinted + glow;

	// Saturation guard (DON-256 §6)
	float gray = dot(final, vec3(0.299, 0.587, 0.114));
	final = mix(final, vec3(gray), u_saturationDampen);

	float finalAlpha = a * dissolveMask * u_alphaMaster;

	COLOR = vec4(final * finalAlpha, finalAlpha);
}
