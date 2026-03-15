shader_type canvas_item;

uniform sampler2D screen_texture : source_color, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 8.0) = 2.5;   // 0 = sharp, 4–6 = nice soft background blur

void fragment() {
    // Use mipmaps + bilinear filtering to fake blur very cheaply
    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    COLOR = color;
}