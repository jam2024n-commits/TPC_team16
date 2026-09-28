extends Control

# タイトルの「設定」。ミュートと音量（スライダー）を変えられる。変えるとすぐ反映され、記録される（Settings）。
# 「閉じる」か Esc で閉じる

signal closed

@onready var _mute_button: CheckButton = $Panel/MuteButton
@onready var _volume_slider: HSlider = $Panel/VolumeSlider
@onready var _volume_value: Label = $Panel/VolumeValue
@onready var _close_button: Button = $Panel/CloseButton


func _ready() -> void:
	visible = false
	_mute_button.toggled.connect(Settings.set_muted)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_close_button.pressed.connect(close)
	# 開いている間に、矢印キーなどで後ろのタイトルのボタンへ移らないよう、この中だけで行き来させる
	_link_focus([_mute_button, _volume_slider, _close_button])


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_mute_button.set_pressed_no_signal(Settings.muted)
	_volume_slider.set_value_no_signal(Settings.volume * 100.0)
	_update_value_label()
	visible = true
	_mute_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _on_volume_changed(value: float) -> void:
	Settings.set_volume(value / 100.0)
	_update_value_label()


func _update_value_label() -> void:
	_volume_value.text = "%d%%" % roundi(_volume_slider.value)


# 上下（と Tab）で順に移り、端から端へ回る。左右はボタンでは動かさない（スライダーは左右で音量を変える）
func _link_focus(controls: Array) -> void:
	for i in controls.size():
		var c: Control = controls[i]
		var prev: Control = controls[(i - 1 + controls.size()) % controls.size()]
		var next: Control = controls[(i + 1) % controls.size()]
		c.focus_neighbor_top = prev.get_path()
		c.focus_neighbor_bottom = next.get_path()
		c.focus_previous = prev.get_path()
		c.focus_next = next.get_path()
		if not c is Slider:
			c.focus_neighbor_left = c.get_path()
			c.focus_neighbor_right = c.get_path()
