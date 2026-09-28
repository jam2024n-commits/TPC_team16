extends Control

# タイトル画面（簡易版）。「試練の間に入る」で第一層へ進む。「ゲームを終了」で終了。「設定」と「BOSS」は準備中

const FIRST_FLOOR := "res://scenes/trial_floor_1.tscn"

@onready var _enter_button: Button = $Menu/EnterButton
@onready var _settings_button: Button = $Menu/SettingsButton
@onready var _quit_button: Button = $Menu/QuitButton
@onready var _boss_button: Button = $BossButton
@onready var _message: Label = $Message


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_enter_button.pressed.connect(ViewSwitcher.go_to.bind(FIRST_FLOOR))
	_settings_button.pressed.connect(_show_message.bind("設定は準備中です"))
	_quit_button.pressed.connect(get_tree().quit)
	_boss_button.pressed.connect(_show_message.bind("ボス戦は準備中です"))
	_enter_button.grab_focus()


func _show_message(text: String) -> void:
	_message.text = text
