shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float strength = 0.0;
uniform float speed = 2.0;
uniform float frequency = 10.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    float wave_x = sin(uv.y * frequency + TIME * speed) * 0.01;
    float wave_y = cos(uv.x * frequency + TIME * speed) * 0.01;

    uv.x += wave_x * strength;
    uv.y += wave_y * strength;

    COLOR = texture(SCREEN_TEXTURE, uv);
}