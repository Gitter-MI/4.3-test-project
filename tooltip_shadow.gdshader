shader_type canvas_item;

uniform float shadow_offset = 2.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.4);

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 shadow = texture(TEXTURE, UV - vec2(shadow_offset) / vec2(textureSize(TEXTURE, 0)));
    
    if (shadow.a > 0.0) {
        COLOR = mix(shadow_color, color, color.a);
    } else {
        COLOR = color;
    }
}