shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), 1.0);
}
