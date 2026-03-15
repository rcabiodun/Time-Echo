shader_type canvas_item;

// Controls
uniform vec4 glow_color : source_color = vec4(0.7, 1.0, 0.85, 1.0);  // soft cyan-green – change to your preference (gold: 1.0,0.9,0.6 / purple: 0.9,0.7,1.0)
uniform float glow_intensity : hint_range(0.0, 4.0) = 1.2;
uniform float glow_size : hint_range(0.5, 8.0) = 2.5;          // larger = softer/bigger halo
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;        // 0 = no pulse
uniform bool active = false;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec4 color = base;
    
    if (active && glow_intensity > 0.01) {
        vec2 pixel_size = TEXTURE_PIXEL_SIZE * glow_size;
        vec4 glow = vec4(0.0);
        
        // Simple soft multi-sample (cross + diagonals) – cheap but nice diffusion
        // You can add more samples for even softer glow (but costs perf)
        glow += texture(TEXTURE, UV + vec2( pixel_size.x, 0.0));
        glow += texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0));
        glow += texture(TEXTURE, UV + vec2(0.0,  pixel_size.y));
        glow += texture(TEXTURE, UV + vec2(0.0, -pixel_size.y));
        glow += texture(TEXTURE, UV + vec2( pixel_size.x,  pixel_size.y)) * 0.7;
        glow += texture(TEXTURE, UV + vec2(-pixel_size.x,  pixel_size.y)) * 0.7;
        glow += texture(TEXTURE, UV + vec2( pixel_size.x, -pixel_size.y)) * 0.7;
        glow += texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)) * 0.7;
        glow += texture(TEXTURE, UV) * 1.2;  // center stronger
        
        glow /= 7.2;  // normalize roughly
        
        // Apply color & intensity + gentle pulse
        float pulse = 1.0;
        if (pulse_speed > 0.01) {
            pulse = 0.95 + 0.1 * sin(TIME * pulse_speed * 6.28 + UV.x * 4.0 + UV.y * 3.0);
        }
        
        vec3 glow_rgb = glow_color.rgb * glow.a * glow_intensity * pulse;
        
        // Add to base (screen-like blend for glow feel)
        color.rgb += glow_rgb;
        
        // Optional: slight over-saturation for magical feel
        // color.rgb = mix(color.rgb, color.rgb * 1.15, 0.25);
    }
    
    COLOR = color;
}