shader_type spatial;
render_mode unshaded, fog_disabled;


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;


uniform int radius : hint_range(1, 4) = 1;

void fragment() {

    vec2 tex_size = vec2(textureSize(screen_texture, 0));
    vec2 uv = SCREEN_UV;
    vec2 pixel_size = 1.0 / tex_size;

    int r = radius;

    float n = float((r + 1) * (r + 1));


    vec3 m[4];
    vec3 s[4];
    for (int i = 0; i < 4; i++) {
        m[i] = vec3(0.0);
        s[i] = vec3(0.0);
    }


    for (int j = -r; j <= 0; ++j) {
        for (int i = -r; i <= 0; ++i) {
            vec3 c = texture(screen_texture, uv + vec2(float(i), float(j)) * pixel_size).rgb;
            m[0] += c;
            s[0] += c * c;
        }
    }
    

    for (int j = -r; j <= 0; ++j) {
        for (int i = 0; i <= r; ++i) {
            vec3 c = texture(screen_texture, uv + vec2(float(i), float(j)) * pixel_size).rgb;
            m[1] += c;
            s[1] += c * c;
        }
    }


    for (int j = 0; j <= r; ++j) {
        for (int i = -r; i <= 0; ++i) {
            vec3 c = texture(screen_texture, uv + vec2(float(i), float(j)) * pixel_size).rgb;
            m[2] += c;
            s[2] += c * c;
        }
    }


    for (int j = 0; j <= r; ++j) {
        for (int i = 0; i <= r; ++i) {
            vec3 c = texture(screen_texture, uv + vec2(float(i), float(j)) * pixel_size).rgb;
            m[3] += c;
            s[3] += c * c;
        }
    }

    float min_variance = 100000.0;
    vec3 final_color = vec3(0.0);


    for (int k = 0; k < 4; ++k) {
        m[k] /= n;

        s[k] = abs(s[k] / n - m[k] * m[k]);
        

        float variance = s[k].r + s[k].g + s[k].b;
        
        if (variance < min_variance) {
            min_variance = variance;
            final_color = m[k];
        }
    }

    ALBEDO = final_color;
}