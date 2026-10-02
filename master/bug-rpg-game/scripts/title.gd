extends Control

# タイトル画面（簡易版）。「試練の間に入る」で第一層へ、「BOSS」でボス戦へ進む。「ゲームを終了」で終了。
# 「アイテム一覧」で、試練の間で手に入れたアイテムを見られる（scenes/item_list.tscn）。
# 「設定」でミュートと音量を変えられる（scenes/settings_menu.tscn）。
# 試練の間に入るとき・初めてボスに挑むときは、先に暗転した画面で語りを出す（scenes/trial_intro_first.tscn など）

# 試練の間：初めては長い語り、2回目からは短い語りのあと、第一層へ
const TRIAL_INTRO_FIRST := "res://scenes/trial_intro_first.tscn"
const TRIAL_INTRO_AGAIN := "res://scenes/trial_intro_again.tscn"
# ボス戦：初めてのときだけ語りのあと、ボス戦へ
const BOSS_INTRO := "res://scenes/boss_intro.tscn"
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
	_enter_button.pressed.connect(_enter_trial)
	_items_button.pressed.connect(_item_list.open)
	_item_list.closed.connect(_items_button.grab_focus)
	_settings_button.pressed.connect(_settings_menu.open)
	_settings_menu.closed.connect(_settings_button.grab_focus)
	_quit_button.pressed.connect(get_tree().quit)
	_boss_button.pressed.connect(_enter_boss)
	_enter_button.grab_focus()


func _enter_trial() -> void:
	ViewSwitcher.go_to(TRIAL_INTRO_AGAIN if Progress.has(Progress.TRIAL_INTRO_SEEN) else TRIAL_INTRO_FIRST)


func _enter_boss() -> void:
	ViewSwitcher.go_to(BOSS_BATTLE if Progress.has(Progress.BOSS_INTRO_SEEN) else BOSS_INTRO)
