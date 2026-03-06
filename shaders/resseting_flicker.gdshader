shader_type canvas_item;

uniform float flicker_amount = 0.0;  // 0 = off, 1 = full
uniform float time_passed = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (flicker_amount > 0.0) {
        // Fast flicker: horizontal jitter + RGB shift
        float glitch = sin(time_passed * 80.0 + UV.y * 100.0) * 0.03;
        vec2 offset_uv = UV + vec2(glitch * flicker_amount, 0.0);
        tex_color = texture(TEXTURE, offset_uv);

        tex_color.r += sin(time_passed * 60.0) * 0.05 * flicker_amount;
        tex_color.g += sin(time_passed * 70.0) * 0.05 * flicker_amount;
        tex_color.b += sin(time_passed * 90.0) * 0.05 * flicker_amount;
    }

    COLOR = tex_color;
}