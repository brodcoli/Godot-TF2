shader_type spatial;

uniform sampler2D albedo : source_color;
instance uniform vec3 light_color : source_color;

void fragment() {
	vec3 base_color = texture(albedo, UV).rgb;
	float mask = clamp(dot(COLOR.rgb, vec3(0.333333)), 0.0, 1.0);
	ALBEDO = mix(base_color, base_color * light_color*1.0, mask * 1.0);

	EMISSION = vec3(mix(vec3(mask), light_color, 0.1)) * mask * 0.2;
	
	ROUGHNESS = 0.2;
	METALLIC = 0.6 * (1.0-mask);
}
