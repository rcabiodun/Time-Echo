shader_type canvas_item;

uniform float intensity : hint_range(0.0, 3.0) = 1.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float time_scale : hint_range(0.1, 20.0) = 8.0;
uniform bool active = false;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float sparks(vec2 uv, float t) {
    float n = 0.0;
    vec2 p = uv * 6.0;
    
    for (float i = 1.0; i < 6.0; i++) {
        vec2 q = p + vec2(i * 0.7, i * 1.3) + t * vec2(2.2, -3.1);
        float h = hash(q);
        n += sin(h * 20.0 + t * (8.0 + i * 4.0)) * (1.0 / i);
    }
    
    return smoothstep(0.4, 0.8, abs(n)) * intensity;
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec4 out_color = base;           // start with base
    
    if (active) {
        float t = TIME * time_scale;
        float spark = sparks(UV + vec2(t * 0.4, 0.0), t);
        
        float lines = step(0.98, hash(UV * 40.0 + floor(t * 12.0))) * 0.7;
        
        vec3 effect = flash_color.rgb * (spark + lines * 1.5);
        
        float edge = 1.0 - smoothstep(0.0, 0.15, min(UV.x, min(1.0-UV.x, min(UV.y, 1.0-UV.y))));
        effect *= (1.0 + edge * 2.0);
        
        out_color.rgb += effect;
        // out_color.a remains base.a
    }
    
    COLOR = out_color;   // always assign exactly once at the end
}