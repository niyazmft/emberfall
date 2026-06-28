shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.9, 0.72, 0.18, 0.6);
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float glow_radius : hint_range(0.0, 10.0) = 4.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float alpha = tex_color.a;
    float glow = 0.0;
    float count = 0.0;
    for(float x = -glow_radius; x <= glow_radius; x += 1.0) {
        for(float y = -glow_radius; y <= glow_radius; y += 1.0) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
            glow += texture(TEXTURE, UV + offset).a;
            count += 1.0;
        }
    }
    glow = glow / count;
    vec4 glow_rgba = glow_color * glow * glow_intensity;
    COLOR = mix(glow_rgba, tex_color, alpha);
}
