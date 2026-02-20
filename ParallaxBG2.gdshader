shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;

void fragment() {
    vec2 size = 1.0 / vec2(textureSize(TEXTURE, 0));
    vec4 color = vec4(0.0);

    color += texture(TEXTURE, UV + size * vec2(-blur_amount, -blur_amount));
    color += texture(TEXTURE, UV + size * vec2( blur_amount, -blur_amount));
    color += texture(TEXTURE, UV + size * vec2(-blur_amount,  blur_amount));
    color += texture(TEXTURE, UV + size * vec2( blur_amount,  blur_amount));

    color *= 0.25;

    COLOR = color;
}
