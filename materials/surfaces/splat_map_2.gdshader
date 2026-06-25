shader_type spatial;

uniform sampler2D black_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D white_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D blend_height : filter_linear_mipmap, repeat_enable;
uniform float height_strength : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float blend_softness : hint_range(0.001, 0.5, 0.001) = 0.12;
uniform float height_midpoint : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform bool height_belongs_to_white = true;

void fragment() {
	vec4 black_color = texture(black_albedo, UV);
	vec4 white_color = texture(white_albedo, UV);
	
	float paint = COLOR.r;
	float height = texture(blend_height, UV).r;
	float height_offset = height - height_midpoint;
	
	if (!height_belongs_to_white) {
		height_offset *= -1.0;
	}
	
	float blend_mask = smoothstep(
		0.5 - blend_softness,
		0.5 + blend_softness,
		paint + height_offset * height_strength
	);
	
	ALBEDO = mix(black_color.rgb, white_color.rgb, blend_mask);
}