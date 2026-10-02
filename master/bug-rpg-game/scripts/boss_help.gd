extends CanvasLayer

# ボス戦の最初に出す操作説明のウィンドウ。出ている間はゲームを止める（get_tree().paused）。
# 「×」か Esc で閉じる（閉じるボタンにフォーカスがあるので Enter / Space でも閉じる）。閉じると closed を出す。
# 攻撃は、そのアイテムを持っていないときは暗くして「アイテムが必要」と出す（アイテム名は出さない。アイテム一覧の「？？？」と同じ）

signal closed

const LOCKED_NOTE := "（アイテムが必要）"
const KEY_COLOR := Color(1, 0.85, 0.45)
const TEXT_COLOR := Color(1, 1, 1)
const LOCKED_COLOR := Color(1, 1, 1, 0.35)
const FONT_SIZE := 12

@onready var _rows: GridContainer = $Root/Panel/Rows
@onready var _close_button: Button = $Root/Panel/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close_button.pressed.connect(close)


func _input(event: InputEvent) -> void:
	# Esc メニュー（GameUI）より先に受け取り、説明を閉じるだけにする
	if visible and event.is_action_pressed("pause_menu"):
		close()
		get_viewport().set_input_as_handled()


# can_shoot / can_charge：通常攻撃・チャージ攻撃が使えるか（杖・ローブを持っているか）
func open(can_shoot: bool, can_charge: bool) -> void:
	for child in _rows.get_children():
		child.free()
	_add_row("WASD / 矢印", "移動")
	_add_row("Space", "通常攻撃", "（押し続けると連射）", can_shoot)
	_add_row("C", "チャージ攻撃", "（1秒押し続ける）", can_charge)
	_add_row("Ctrl", "しゃがむ")
	_add_row("Shift", "ダッシュ", "（押した向きへ）")
	_add_row("Esc", "メニュー")
	visible = true
	get_tree().paused = true
	_close_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


# 使えないときは detail の代わりに LOCKED_NOTE を付ける
func _add_row(key: String, action: String, detail := "", enabled := true) -> void:
	var key_label := _make_label(key, KEY_COLOR if enabled else LOCKED_COLOR)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rows.add_child(key_label)
	_rows.add_child(_make_label(action + detail if enabled else action + LOCKED_NOTE, TEXT_COLOR if enabled else LOCKED_COLOR))


func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
