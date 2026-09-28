extends Node2D

# 試練の間の各層に共通の処理。
# - 開始時（やり直し時も）に「～試練の間　第〇層～」を表示してフェードアウトする
# - 右の境界に内側から触れたとき、この層のオーブを取っていれば次の層へ、取っていなければ同じ層をやり直す
# - 白い扉（ExitDoor）がある層では、オーブを取ると扉が現れ、E で入ると次の層へ

const TITLE_HOLD := 1.0
const TITLE_FADE := 0.5
const TITLE_FONT_SIZE := 12
const KANJI_DIGITS := ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]

@export var floor_number := 1
@export var item_id := ""
@export_file("*.tscn") var next_scene := ""

@onready var _border = $Border  # trial_border.gd
@onready var _player = $Player  # player.gd

var _got_item := false
var _leaving := false
var _door = null  # exit_door.gd


func _ready() -> void:
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
	var label := Label.new()
	label.text = "～試練の間　第%s層～" % kanji_number(floor_number)
	label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	create_tween().tween_property(label, "modulate:a", 0.0, TITLE_FADE).set_delay(TITLE_HOLD)


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
	if _door:
		_door.appear()


func _go_to_next() -> void:
	if _leaving or next_scene == "":
		return
	_leaving = true
	ViewSwitcher.go_to(next_scene)
