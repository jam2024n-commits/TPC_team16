shader_type canvas_item;

// 試練の間のブロックの枠線（block.gd の enable_outline）。
// 枠線の各点で、真後ろにある背景（画面に固定した trial_background）の明るさを調べ、
// 暗いところでは白っぽい色、明るいところでは黒っぽい色で塗る。
// 背景の細かい模様で色がちらつかないよう、ぼかした背景（ミップマップ）で明るさを見る

uniform sampler2D background : filter_linear_mipmap;
// 背景の画像が画面のどこに置かれているか（x, y, 幅, 高さ。画面の座標）
uniform vec4 background_rect = vec4(0.0, -15.0, 480.0, 300.0);
uniform vec2 screen_size = vec2(480.0, 270.0);
uniform float blur_lod = 3.0;
uniform float threshold = 0.25;
uniform vec4 light_color : source_color = vec4(0.9, 0.9, 0.93, 1.0);
uniform vec4 dark_color : source_color = vec4(0.07, 0.07, 0.1, 1.0);

void fragment() {
	vec2 screen_pos = SCREEN_UV * screen_size;
	vec2 uv = (screen_pos - background_rect.xy) / background_rect.zw;
	vec3 behind = textureLod(background, uv, blur_lod).rgb;
	float brightness = dot(behind, vec3(0.299, 0.587, 0.114));
	COLOR = brightness < threshold ? light_color : dark_color;
}
