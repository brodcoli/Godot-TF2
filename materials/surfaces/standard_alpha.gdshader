shader_type spatial;

uniform sampler2D albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D opacity : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_stength : hint_range(0.0, 1.0, 0.05) = 0.2;

void fragment() {
	vec4 color = texture(albedo, UV);
	vec3 normal_sample = texture(normal, UV).rgb;

	ALBEDO = color.rgb;
	ALPHA = color.a * texture(opacity, UV).r;
	NORMAL_MAP = normal_sample;
	NORMAL_MAP_DEPTH = normal_stength;
}
