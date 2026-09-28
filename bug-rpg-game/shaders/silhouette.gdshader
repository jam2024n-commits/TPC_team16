shader_type canvas_item;

// 画像の形だけを1色で塗る（アイテム一覧で、まだ持っていないアイテムを影で見せる）
uniform vec4 tint : source_color = vec4(0.3, 0.3, 0.36, 1.0);

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);
}
