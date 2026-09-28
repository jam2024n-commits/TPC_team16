extends SceneTree

# 担当の人から届いた画像を、ゲームで使える形に変換して書き出す（元の画像はそのまま残す）。
# 実行: godot --headless --path . --script res://tools/convert_art_assets.gd
# そのあと: godot --headless --path . --import
#
# - ビーズ図案（bead-pattern*.png）：1マスを30ピクセルに拡大し、空きマスに方眼の点を打った画像。
#   各マスの色を1つ読み取って等倍のドット絵に戻す（方眼の点は消える）。チャージ攻撃のコマは横に並べて1枚にする
# - 試練の間の背景：画面の横幅（480）に合わせて縮める。上下は表示するときに切る
# - ボス戦の背景：画面と同じ 16:9 に切る
# - タイトルの背景：画面と同じ 16:9 に切る（扉全体と足元の草地が入る高さ）
# 画像が差し替わったら、このツールをもう一度実行すればよい

const BEAD_CELL := 30
# マスの中心には方眼の点があるので、中心を避けた4か所を読み、多い色をそのマスの色にする
const BEAD_SAMPLES := [Vector2i(4, 4), Vector2i(25, 4), Vector2i(4, 25), Vector2i(25, 25)]

const BEAD_PATTERNS := {
	"res://assets/stick/bead-pattern.png": "res://assets/stick/staff.png",
	"res://assets/shield/bead-pattern_1.png": "res://assets/shield/buckler.png",
	"res://assets/mant/bead-pattern_13.png": "res://assets/mant/mantle.png",
}
# チャージ攻撃のコマ（ビーズ図案）。この順に横に並べて1枚にする（1コマ 48x48）。
# 0〜3：ためている間（2〜5番）、4：ため終わり（6番）、5：飛んでいく弾（7番）、6〜7：当たったとき（9・10番）
const CHARGE_FRAMES := [
	"res://assets/battle/bullet/charge/bead-pattern_2.png",
	"res://assets/battle/bullet/charge/bead-pattern_3.png",
	"res://assets/battle/bullet/charge/bead-pattern_4.png",
	"res://assets/battle/bullet/charge/bead-pattern_5.png",
	"res://assets/battle/bullet/charge/bead-pattern_6.png",
	"res://assets/battle/bullet/charge/bead-pattern_7.png",
	"res://assets/battle/bullet/charge/bead-pattern_9.png",
	"res://assets/battle/bullet/charge/bead-pattern_10.png",
]
const CHARGE_SHEET := "res://assets/battle/bullet/charge/charge_sheet.png"
const TRIAL_BACKGROUND_SOURCE := "res://assets/background/shiren/075c3df9588eef07ffbd76fc626d033d_t.jpeg"
const TRIAL_BACKGROUND := "res://assets/background/shiren/trial_background.png"
# ボス戦の背景は細かい1枚絵なので縮めずに、画面と同じ 16:9 になるよう左右（または上下）を切るだけにする。
# 縮めるのは表示するとき（boss_battle.tscn の Background。滑らかに縮める）
const BOSS_BACKGROUND_SOURCE := "res://assets/background/BOSS/Gemini_Generated_Image_ao04d9ao04d9ao04.jpg"
const BOSS_BACKGROUND := "res://assets/background/BOSS/boss_background.png"
# タイトルの背景（正方形の1枚絵）。16:9 に切るときの縦の位置（0＝一番上、0.5＝真ん中、1＝一番下）
const TITLE_BACKGROUND_SOURCE := "res://assets/background/title/ChatGPT_Image_2026928_23_38_53.png"
const TITLE_BACKGROUND := "res://assets/background/title/title_background.png"
const TITLE_BACKGROUND_ANCHOR_Y := 0.45
const SCREEN_WIDTH := 480
const SCREEN_HEIGHT := 270


func _initialize() -> void:
	for source in BEAD_PATTERNS:
		_save(_from_bead_pattern(_load(source)), BEAD_PATTERNS[source])
	_save(_sheet(CHARGE_FRAMES), CHARGE_SHEET)
	var background := _load(TRIAL_BACKGROUND_SOURCE)
	var height := roundi(background.get_height() * float(SCREEN_WIDTH) / background.get_width())
	background.resize(SCREEN_WIDTH, height, Image.INTERPOLATE_CUBIC)
	_save(background, TRIAL_BACKGROUND)
	_save(_crop_to_screen_ratio(_load(BOSS_BACKGROUND_SOURCE)), BOSS_BACKGROUND)
	_save(_crop_to_screen_ratio(_load(TITLE_BACKGROUND_SOURCE), TITLE_BACKGROUND_ANCHOR_Y), TITLE_BACKGROUND)
	quit()


# ビーズ図案を1コマずつドット絵に戻し、横に並べて1枚にする
func _sheet(sources: Array) -> Image:
	var frames: Array[Image] = []
	for source in sources:
		frames.append(_from_bead_pattern(_load(source)))
	var frame_size := frames[0].get_size()
	var img := Image.create_empty(frame_size.x * frames.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		img.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frame_size), Vector2i(frame_size.x * i, 0))
	return img


# 画面と同じ 16:9 に切る。anchor は余る方向のどこを残すか（0.5 なら真ん中）
func _crop_to_screen_ratio(src: Image, anchor := 0.5) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var ratio := float(SCREEN_WIDTH) / SCREEN_HEIGHT
	var crop := Rect2i(0, 0, w, h)
	if float(w) / h > ratio:
		crop.size.x = roundi(h * ratio)
		crop.position.x = int((w - crop.size.x) * anchor)
	else:
		crop.size.y = roundi(w / ratio)
		crop.position.y = int((h - crop.size.y) * anchor)
	return src.get_region(crop)


func _load(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, path: String) -> void:
	var err := img.save_png(ProjectSettings.globalize_path(path))
	print(path, " ", img.get_size(), " -> ", "OK" if err == OK else "error %d" % err)


func _from_bead_pattern(src: Image) -> Image:
	var w := src.get_width() / BEAD_CELL
	var h := src.get_height() / BEAD_CELL
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var counts := {}
			for offset in BEAD_SAMPLES:
				var c := src.get_pixelv(Vector2i(x, y) * BEAD_CELL + offset)
				if c.a < 0.5:
					c = Color(0, 0, 0, 0)
				counts[c] = counts.get(c, 0) + 1
			var best: Color = counts.keys()[0]
			for c in counts:
				if counts[c] > counts[best]:
					best = c
			img.set_pixel(x, y, best)
	return img
