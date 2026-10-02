extends Node2D

# 試練の間の各層に共通の処理。
# - 開始時（やり直し時も）に「～試練の間　第〇層～」を TITLE_HOLD 秒表示してフェードアウトする
# - 右の境界に内側から触れたとき、この層のオーブを取っていれば次の層へ、取っていなければ同じ層をやり直す
# - 白い扉（ExitDoor）がある層では、オーブを取ると扉が現れ、E で入ると次の層へ

const TITLE_HOLD := 1.5
const TITLE_FADE := 0.5
const TITLE_FONT_SIZE := 24
# 層の表示は行書。細い線が見づらいので、語りと同じく文字と同じ白で1ピクセルのふちを付ける
const TITLE_FONT := preload("res://assets/fonts/KouzanGyousho.ttf")
const TITLE_OUTLINE_SIZE := 1
# 文字を見やすくするため、後ろに黒い半透明の横長の楕円を敷く（ふちはぼかす）
const TITLE_BACK_SIZE := Vector2(340, 56)
const TITLE_BACK_ALPHA := 0.7
const KANJI_DIGITS := ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
const BGM := preload("res://assets/BGM/shiren/village.mp3")
# 壁や障害物（block.gd を使うもの。境界も含む）に付ける枠線。色は背景の明るさで変わる
const BLOCK_OUTLINE := preload("res://shaders/block_outline.tres")
# 試練の間の層が入る group（Esc メニューの表示を変えるのに使う）
const GROUP := "trial_floor"

@export var floor_number := 1
@export var item_id := ""
@export_file("*.tscn") var next_scene := ""

@onready var _border = $Border  # trial_border.gd
@onready var _player = $Player  # player.gd

var _got_item := false
var _leaving := false
var _door = null  # exit_door.gd


func _ready() -> void:
	Bgm.play_music(BGM)
	add_to_group(GROUP)
	for block in find_children("*", "StaticBody2D", true, false):
		if block.has_method("enable_outline"):
			block.enable_outline(BLOCK_OUTLINE)
	var orb := get_node_or_null("Orb")
	if orb:
		orb.collected.connect(_on_orb_collected)
	_door = get_node_or_null("ExitDoor")
	if _door:
		_door.entered.connect(_go_to_next)
	_show_floor_title()


func _physics_process(_delta: float) -> void:
	# FAKE_BUG: boundary_clip
	# 壁抜け中は、右の境界に触れても戻されない
	if not _leaving and _border.is_touching_right(_player) and not _player.is_clipping():
		if _got_item:
			_go_to_next()
		else:
			_leaving = true
			ViewSwitcher.go_to(scene_file_path)


func _show_floor_title() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	# 楕円と文字をまとめてフェードアウトさせる
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var back := TextureRect.new()
	back.texture = _make_title_back_texture()
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	back.size = TITLE_BACK_SIZE
	back.position -= TITLE_BACK_SIZE / 2.0
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)

	var label := Label.new()
	label.text = "～試練の間　第%s層～" % kanji_number(floor_number)
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	label.add_theme_constant_override("outline_size", TITLE_OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	create_tween().tween_property(root, "modulate:a", 0.0, TITLE_FADE).set_delay(TITLE_HOLD)


# 中心から外へ、黒（半透明）→ 透明になる円の画像。横長に引き伸ばして楕円にする
func _make_title_back_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gradient.colors = PackedColorArray([
		Color(0, 0, 0, TITLE_BACK_ALPHA),
		Color(0, 0, 0, TITLE_BACK_ALPHA),
		Color(0, 0, 0, 0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


# 1〜99 を漢数字にする（例：12 → 十二）
static func kanji_number(n: int) -> String:
	var tens := n / 10
	var text := ""
	if tens > 1:
		text += KANJI_DIGITS[tens]
	if tens > 0:
		text += "十"
	return text + KANJI_DIGITS[n % 10]


func _on_orb_collected() -> void:
	_got_item = true
	if item_id != "" and not Inventory.has_item(item_id):
		Inventory.add_item(item_id)
	_reveal_exit()


# オーブを取ったあとに出口を出す。層ごとに演出を変えたいときは上書きする
func _reveal_exit() -> void:
	if _door:
		_door.appear()


func _go_to_next() -> void:
	if _leaving or next_scene == "":
		return
	_leaving = true
	ViewSwitcher.go_to(next_scene)
