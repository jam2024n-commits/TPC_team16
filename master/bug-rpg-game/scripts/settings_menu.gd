extends Control

# 設定の画面（タイトルと Esc メニューで共通）。ミュートと音量（スライダー）を変えられる。変えるとすぐ反映され、記録される（Settings）。
# show_reset を有効にすると（タイトルのみ）、「全データリセット」ボタンを出す。押すと確認を出し、「消す」でアイテムと設定を最初の状態に戻す。
# 「閉じる」か Esc で閉じる（確認を出している間の Esc は確認だけを閉じる）

signal closed

const RESET_DONE_TEXT := "リセットしました"

@export var show_reset := false

@onready var _panel: Control = $Panel
@onready var _mute_button: CheckButton = $Panel/MuteButton
@onready var _volume_slider: HSlider = $Panel/VolumeSlider
@onready var _volume_value: Label = $Panel/VolumeValue
@onready var _reset_button: Button = $Panel/ResetButton
@onready var _message: Label = $Panel/Message
@onready var _close_button: Button = $Panel/CloseButton
@onready var _confirm: Control = $Panel/Confirm
@onready var _confirm_yes: Button = $Panel/Confirm/Buttons/YesButton
@onready var _confirm_no: Button = $Panel/Confirm/Buttons/NoButton


func _ready() -> void:
	visible = false
	_confirm.visible = false
	_mute_button.toggled.connect(Settings.set_muted)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_close_button.pressed.connect(close)
	_reset_button.pressed.connect(_open_confirm)
	_confirm_yes.pressed.connect(_reset_all)
	_confirm_no.pressed.connect(_close_confirm)
	if show_reset:
		_link_focus([_mute_button, _volume_slider, _reset_button, _close_button])
	else:
		# リセットのボタンを出さない分、下を詰める
		var gap := _close_button.position.y - _reset_button.position.y
		_reset_button.visible = false
		_message.visible = false
		_close_button.position.y -= gap
		_panel.size.y -= gap
		_link_focus([_mute_button, _volume_slider, _close_button])
	# 確認の中も、左右（と上下・Tab）で2つのボタンだけを行き来させる
	_link_focus([_confirm_no, _confirm_yes])


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _confirm.visible:
			_close_confirm()
		else:
			close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_refresh()
	_message.text = ""
	_confirm.visible = false
	visible = true
	_mute_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _refresh() -> void:
	_mute_button.set_pressed_no_signal(Settings.muted)
	_volume_slider.set_value_no_signal(Settings.volume * 100.0)
	_update_value_label()


func _on_volume_changed(value: float) -> void:
	Settings.set_volume(value / 100.0)
	_update_value_label()


func _update_value_label() -> void:
	_volume_value.text = "%d%%" % roundi(_volume_slider.value)


func _open_confirm() -> void:
	_confirm.visible = true
	_confirm_no.grab_focus()


func _close_confirm() -> void:
	_confirm.visible = false
	_reset_button.grab_focus()


# 全データリセット：アイテム（Inventory）、進み具合（Progress）、音の設定（Settings）を最初の状態に戻し、記録も消す
func _reset_all() -> void:
	Inventory.reset()
	Progress.reset()
	Settings.reset()
	_refresh()
	_message.text = RESET_DONE_TEXT
	_close_confirm()


# 上下（と Tab）で順に移り、端から端へ回る。左右はボタンでは動かさない（スライダーは左右で音量を変える）。
# 2つだけのとき（確認のボタン）は、左右でも行き来する
func _link_focus(controls: Array) -> void:
	for i in controls.size():
		var c: Control = controls[i]
		var prev: Control = controls[(i - 1 + controls.size()) % controls.size()]
		var next: Control = controls[(i + 1) % controls.size()]
		c.focus_neighbor_top = prev.get_path()
		c.focus_neighbor_bottom = next.get_path()
		c.focus_previous = prev.get_path()
		c.focus_next = next.get_path()
		if controls.size() == 2:
			c.focus_neighbor_left = prev.get_path()
			c.focus_neighbor_right = next.get_path()
		elif not c is Slider:
			c.focus_neighbor_left = c.get_path()
			c.focus_neighbor_right = c.get_path()
