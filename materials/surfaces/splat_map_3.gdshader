shader_type spatial;

uniform sampler2D red_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D red_height : filter_linear_mipmap, repeat_enable;
uniform sampler2D green_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D green_height : filter_linear_mipmap, repeat_enable;
uniform sampler2D blue_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D blue_height : filter_linear_mipmap, repeat_enable;

uniform float height_strength : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float blend_softness : hint_range(0.001, 1.0, 0.001) = 0.12;
uniform float height_midpoint : hint_range(0.0, 1.0, 0.01) = 0.5;

vec3 get_height_blended_weights(vec3 paint, vec3 heights) {
	vec3 weights = max(paint, vec3(0.0));
	float paint_total = weights.r + weights.g + weights.b;

	if (paint_total <= 0.0001) {
		return vec3(1.0, 0.0, 0.0);
	}

	weights /= paint_total;

	vec3 centered_heights = heights - vec3(height_midpoint);
	vec3 height_weights = weights * (vec3(1.0) + centered_heights * height_strength);

	float strongest = max(max(height_weights.r, height_weights.g), height_weights.b);
	vec3 blended = max(height_weights - vec3(strongest - blend_softness), vec3(0.0));

	if (weights.r <= 0.0001) {
		blended.r = 0.0;
	}
	if (weights.g <= 0.0001) {
		blended.g = 0.0;
	}
	if (weights.b <= 0.0001) {
		blended.b = 0.0;
	}

	float blend_total = blended.r + blended.g + blended.b;

	if (blend_total <= 0.0001) {
		return weights;
	}

	return blended / blend_total;
}

void fragment() {
	vec4 red_color = texture(red_albedo, UV);
	vec4 green_color = texture(green_albedo, UV);
	vec4 blue_color = texture(blue_albedo, UV);

	vec3 heights = vec3(
		texture(red_height, UV).r,
		texture(green_height, UV).r,
		texture(blue_height, UV).r
	);

	vec3 paint = COLOR.rgb;
	vec3 weights = get_height_blended_weights(paint, heights);
	
	ALBEDO =
		red_color.rgb * weights.r +
		green_color.rgb * weights.g +
		blue_color.rgb * weights.b;
}