extends Control

# タイトルの「アイテム一覧」。試練の間のアイテムを順に並べる。
# 持っているものは絵と名前、まだ持っていないものは影と「？？？」。「閉じる」か Esc で閉じる

signal closed

const ORB_ICON := preload("res://scripts/orb_icon.gd")
const SILHOUETTE := preload("res://shaders/silhouette.gdshader")
const ICON_SIZE := 36.0
const UNKNOWN_NAME := "？？？"

@onready var _rows: VBoxContainer = $Panel/Rows
@onready var _close_button: Button = $Panel/CloseButton

var _silhouette := ShaderMaterial.new()


func _ready() -> void:
	visible = false
	_silhouette.shader = SILHOUETTE
	_close_button.pressed.connect(close)
	# 開いている間に、矢印キーなどで後ろのタイトルのボタンへ移らないようにする
	var self_path := _close_button.get_path()
	_close_button.focus_neighbor_top = self_path
	_close_button.focus_neighbor_bottom = self_path
	_close_button.focus_neighbor_left = self_path
	_close_button.focus_neighbor_right = self_path
	_close_button.focus_next = self_path
	_close_button.focus_previous = self_path


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_rebuild()
	visible = true
	_close_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _rebuild() -> void:
	for child in _rows.get_children():
		child.free()
	for id in Inventory.TRIAL_ITEMS:
		var owned := Inventory.has_item(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_make_icon(id, owned))
		var label := Label.new()
		label.text = Inventory.display_name(id) if owned else UNKNOWN_NAME
		label.add_theme_font_size_override("font_size", 12)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if not owned:
			label.modulate = Color(0.6, 0.6, 0.65)
		row.add_child(label)
		_rows.add_child(row)


# 絵があるアイテムは絵（48x48 を 36 で表示）、ないものは黄色い球のアイコン
func _make_icon(id: String, owned: bool) -> Control:
	var image := Inventory.item_image(id)
	if image:
		var rect := TextureRect.new()
		rect.texture = image
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		if not owned:
			rect.material = _silhouette
		return rect
	var icon: PixelIcon = ORB_ICON.new()
	icon.silhouette = not owned
	icon.custom_minimum_size = Vector2(icon.pattern[0].length(), icon.pattern.size()) * PixelIcon.CELL
	# 絵のアイテムと幅をそろえるため、同じ大きさの枠の中央に置く
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	box.add_child(icon)
	return box
