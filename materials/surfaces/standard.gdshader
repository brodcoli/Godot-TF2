shader_type spatial;

uniform sampler2D albedo : source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec4 color = texture(albedo, UV);
	ALBEDO = color.rgb;
}
