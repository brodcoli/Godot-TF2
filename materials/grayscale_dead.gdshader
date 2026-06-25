shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float amount = 1.0;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = mix(screen_color, vec4(vec3(luminance), screen_color.a) * vec4(1.0, 0.7, 0.7, 1.0), amount);
}
