shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform float glow_size = 2.0;
uniform float glow_strength = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float outline = 0.0;

    vec2 size = TEXTURE_PIXEL_SIZE * glow_size;

    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV - vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    outline += texture(TEXTURE, UV - vec2(0, size.y)).a;

    outline = clamp(outline, 0.0, 1.0);

    vec3 result = tex.rgb;

    if (tex.a == 0.0 && outline > 0.0) {
        result = glow_color.rgb * glow_strength;
    }

    COLOR = vec4(result, max(tex.a, outline * glow_strength));
}