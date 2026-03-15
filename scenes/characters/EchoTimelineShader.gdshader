shader_type canvas_item;

uniform float flicker_amount = 0.0;  // 0 = off, 1 = full
uniform float time_passed = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (flicker_amount > 0.0) {
        // Smooth subtle pulse: gentle alpha + slight color tint
        float pulse = 0.3 + 0.2 * sin(time_passed * 5.0);
        tex_color.rgb *= vec3(0.5, 0.7, 1.0); // light blue tint
        tex_color.a *= mix(1.0, pulse, flicker_amount);
    }

    COLOR = tex_color;
}