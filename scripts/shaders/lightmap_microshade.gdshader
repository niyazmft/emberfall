shader_type canvas_item;
render_mode unshaded;

## lightmap_microshade.gdshader
## Sprite normal-map micro-shading for Emberfall 2.5D characters.
##
## Performance tier: medium
## Target platforms: Forward+, Mobile
## Author: Godot Shader Specialist
## References: Art Bible §2, DON-254 Item 4
##
## NOTE: Assumes object-space normal maps (RGB = XYZ) as produced by
## the sprite pipeline. If tangent-space conversion is added later,
## update u_light_dir to match the TBN basis.

group_uniforms "Light Direction";
## Top-left 45° key light per Art Bible §2.
uniform vec3 u_light_dir = vec3(-0.5, -0.5, 1.0);

group_uniforms "Normal Map";
uniform sampler2D u_normal_map : repeat_disable, filter_linear;
uniform float u_normal_strength : hint_range(0.0, 2.0) = 1.0;

group_uniforms "Shading Intensity";
uniform float u_ambient : hint_range(0.0, 1.0) = 0.4;
uniform float u_diffuse_boost : hint_range(0.0, 2.0) = 1.0;
uniform float u_specular_power : hint_range(1.0, 64.0) = 16.0;
uniform float u_specular_intensity : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.001) {
		discard;
	}

	// Object-space normal from sprite normal map
	vec3 normal = texture(u_normal_map, UV).rgb * 2.0 - 1.0;
	normal = normalize(normal * vec3(u_normal_strength, u_normal_strength, 1.0));

	// Light vector (top-left 45°)
	vec3 light = normalize(u_light_dir);

	// Diffuse term (Lambert)
	float ndotl = max(dot(normal, light), 0.0);
	float diffuse = u_ambient + ndotl * (1.0 - u_ambient) * u_diffuse_boost;

	// Specular term (Blinn-Phong-ish)
	vec3 view = vec3(0.0, 0.0, 1.0);
	vec3 half_vec = normalize(light + view);
	float spec = pow(max(dot(normal, half_vec), 0.0), u_specular_power);
	float specular = spec * u_specular_intensity * ndotl;

	vec3 lit = tex.rgb * diffuse + vec3(specular);
	COLOR = vec4(lit, tex.a);
}
