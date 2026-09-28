extends SceneTree

# 担当の人から届いた画像を、ゲームで使える形に変換して書き出す（元の画像はそのまま残す）。
# 実行: godot --headless --path . --script res://tools/convert_art_assets.gd
# そのあと: godot --headless --path . --import
#
# - ビーズ図案（bead-pattern*.png）：1マスを30ピクセルに拡大し、空きマスに方眼の点を打った画像。
#   各マスの色を1つ読み取って等倍のドット絵に戻す（方眼の点は消える）
# - 試練の間の背景：画面の横幅（480）に合わせて縮める。上下は表示するときに切る
# - ボス戦の背景：画面と同じ 16:9 に切る
# 画像が差し替わったら、このツールをもう一度実行すればよい

const BEAD_CELL := 30
# マスの中心には方眼の点があるので、中心を避けた4か所を読み、多い色をそのマスの色にする
const BEAD_SAMPLES := [Vector2i(4, 4), Vector2i(25, 4), Vector2i(4, 25), Vector2i(25, 25)]

const BEAD_PATTERNS := {
	"res://assets/stick/bead-pattern.png": "res://assets/stick/staff.png",
	"res://assets/shield/bead-pattern_1.png": "res://assets/shield/buckler.png",
}
const TRIAL_BACKGROUND_SOURCE := "res://assets/background/shiren/075c3df9588eef07ffbd76fc626d033d_t.jpeg"
const TRIAL_BACKGROUND := "res://assets/background/shiren/trial_background.png"
# ボス戦の背景は細かい1枚絵なので縮めずに、画面と同じ 16:9 になるよう左右（または上下）を切るだけにする。
# 縮めるのは表示するとき（boss_battle.tscn の Background。滑らかに縮める）
const BOSS_BACKGROUND_SOURCE := "res://assets/background/BOSS/Gemini_Generated_Image_ao04d9ao04d9ao04.jpg"
const BOSS_BACKGROUND := "res://assets/background/BOSS/boss_background.png"
const SCREEN_WIDTH := 480
const SCREEN_HEIGHT := 270


func _initialize() -> void:
	for source in BEAD_PATTERNS:
		_save(_from_bead_pattern(_load(source)), BEAD_PATTERNS[source])
	var background := _load(TRIAL_BACKGROUND_SOURCE)
	var height := roundi(background.get_height() * float(SCREEN_WIDTH) / background.get_width())
	background.resize(SCREEN_WIDTH, height, Image.INTERPOLATE_CUBIC)
	_save(background, TRIAL_BACKGROUND)
	_save(_crop_to_screen_ratio(_load(BOSS_BACKGROUND_SOURCE)), BOSS_BACKGROUND)
	quit()


func _crop_to_screen_ratio(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var ratio := float(SCREEN_WIDTH) / SCREEN_HEIGHT
	var crop := Rect2i(0, 0, w, h)
	if float(w) / h > ratio:
		crop.size.x = roundi(h * ratio)
		crop.position.x = (w - crop.size.x) / 2
	else:
		crop.size.y = roundi(w / ratio)
		crop.position.y = (h - crop.size.y) / 2
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
