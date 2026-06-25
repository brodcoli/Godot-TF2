shader_type canvas_item;

uniform vec4 crosshair_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float width = 0.05;
uniform float length = 0.15;
uniform float gap = 0.1;
uniform float dot_size = 0.02;
uniform bool show_dot = true;

const float threshold = 0.8;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {

    vec2 uv = UV - 0.5;
    float dist_x = abs(uv.x);
    float dist_y = abs(uv.y);
    

    bool v_bar = (dist_x < width / 2.0) && (dist_y > gap) && (dist_y < gap + length);
    

    bool h_bar = (dist_y < width / 2.0) && (dist_x > gap) && (dist_x < gap + length);
    

    float dot_dist = length(uv);

    
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	

    if (v_bar || h_bar) {
        float luminance = max(max(screen_color.r, screen_color.g), screen_color.b);
        
        if (luminance >= threshold) {
            COLOR = vec4(0.1, 0.1, 0.1, 1.0);
        } else {
            COLOR = vec4(1.0, 1.0, 1.0, 1.0);
        }
    } else {
        COLOR = vec4(0.0);
    }
}