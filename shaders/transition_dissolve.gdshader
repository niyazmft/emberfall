shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.5) = 0.1;
uniform float noise_scale : hint_range(1.0, 50.0) = 20.0;
uniform float ember_intensity : hint_range(0.0, 2.0) = 0.8;

// Simple 2D hash for deterministic noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float center_dist = distance(uv, vec2(0.5));
    
    // Dissolve edge noise
    float noise = hash(uv * noise_scale);
    float edge = smoothstep(progress - edge_width, progress, center_dist + noise * 0.15);
    
    // Ember glow at the dissolve edge
    float ember = smoothstep(progress - edge_width * 2.0, progress - edge_width, center_dist + noise * 0.15);
    ember = ember * (1.0 - edge) * ember_intensity;
    
    vec4 ember_color = vec4(0.9, 0.5, 0.1, 1.0) * ember;
    vec4 final_color = mix(ember_color, fade_color, edge);
    
    COLOR = final_color;
}
