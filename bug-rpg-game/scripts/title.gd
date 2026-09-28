extends Control

# タイトル画面（簡易版）。「試練の間に入る」で第一層へ、「BOSS」でボス戦へ進む。「ゲームを終了」で終了。
# 「アイテム一覧」で、試練の間で手に入れたアイテムを見られる（scenes/item_list.tscn）。
# 「設定」でミュートと音量を変えられる（scenes/settings_menu.tscn）

const FIRST_FLOOR := "res://scenes/trial_floor_1.tscn"
const BOSS_BATTLE := "res://scenes/boss_battle.tscn"
const BGM := preload("res://assets/BGM/title/Epilogue_loop.ogg")

@onready var _enter_button: Button = $Menu/EnterButton
@onready var _items_button: Button = $Menu/ItemsButton
@onready var _settings_button: Button = $Menu/SettingsButton
@onready var _quit_button: Button = $Menu/QuitButton
@onready var _boss_button: Button = $BossButton
@onready var _item_list = $ItemList  # item_list.gd
@onready var _settings_menu = $SettingsMenu  # settings_menu.gd


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Bgm.play_music(BGM)
	_enter_button.pressed.connect(ViewSwitcher.go_to.bind(FIRST_FLOOR))
	_items_button.pressed.connect(_item_list.open)
	_item_list.closed.connect(_items_button.grab_focus)
	_settings_button.pressed.connect(_settings_menu.open)
	_settings_menu.closed.connect(_settings_button.grab_focus)
	_quit_button.pressed.connect(get_tree().quit)
	_boss_button.pressed.connect(ViewSwitcher.go_to.bind(BOSS_BATTLE))
	_enter_button.grab_focus()

