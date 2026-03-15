shader_type canvas_item;

uniform sampler2D screen_texture : 
    source_color, 
    filter_nearest, 
    repeat_disable;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float cube_size : hint_range(0.005, 0.1) = 0.028;
uniform float explosion : hint_range(0.0, 12.0) = 5.5;
uniform float rotation_amount : hint_range(0.0, 3.0) = 1.2;

// Simple 2D hash function
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Divide screen into grid cells
    vec2 cell = floor(uv / cube_size);
    vec2 local = fract(uv / cube_size);
    
    // Per-cell random values
    vec2 rand_dir = normalize(hash(cell));
    float rand_rot  = hash(cell * 1.3).x * rotation_amount;
    float rand_scale = 0.8 + 0.4 * hash(cell * 2.7).x;   // slight size variation
    
    // Explosion displacement
    vec2 offset = rand_dir * progress * explosion;
    
    // Local position relative to cell center
    vec2 center = (cell + 0.5) * cube_size;
    vec2 rel = (cell * cube_size + local) - center;
    
    // Apply rotation (column-major 2×2 matrix)
    float angle = rand_rot * progress;
    mat2 rot = mat2(
        vec2( cos(angle),  sin(angle)),
        vec2(-sin(angle),  cos(angle))
    );
    vec2 rotated = rot * rel * rand_scale;   // slight per-cube size variation
    
    // Final sample position
    vec2 sample_uv = center + rotated + offset;
    
    // Sample original screen
    vec4 color = texture(screen_texture, sample_uv);
    
    // Fade out as cubes fly away
    float visibility = 1.0 - progress * 0.85;
    color.a *= visibility;
    
    // Optional: darken a bit as they move
    // color.rgb *= (1.0 - progress * 0.4);
    
    // Clip anything that flew off-screen
    if (sample_uv.x < 0.0 || sample_uv.x > 1.0 ||
        sample_uv.y < 0.0 || sample_uv.y > 1.0) {
        color = vec4(0.0);
    }
    
    COLOR = color;
}