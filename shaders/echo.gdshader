shader_type canvas_item;

// ----------------------------
// ✨ Adjustable ghost properties
// ----------------------------
uniform float ghost_strength = 0.5;  // starting opacity of the ghost (0-1)
uniform float trail_fade = 0.15;     // how fast the trail fades (0-1)
uniform vec4 ghost_tint = vec4(0.5, 0.7, 1.0, 1.0); // ghost color (default blueish)
uniform vec2 uv_offset = vec2(0.0, 0.0); // optional shift for a ghostly offset

void fragment() {
    // Sample the sprite texture at UV
    vec4 tex_color = texture(TEXTURE, UV + uv_offset);
    
    // Apply ghost tint
    tex_color.rgb *= ghost_tint.rgb;
    
    // Fade the alpha over time
    tex_color.a *= ghost_strength * (1.0 - trail_fade);
    
    COLOR = tex_color;
}