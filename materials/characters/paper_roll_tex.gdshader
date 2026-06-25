shader_type spatial;

uniform sampler2D tex : source_color, filter_linear;
uniform sampler2D paper_roll_tex : source_color, filter_linear;

void fragment() {
	ALBEDO = texture(tex, UV).rgb * texture(paper_roll_tex, UV).rgb;
	ROUGHNESS = 1.0;
}
