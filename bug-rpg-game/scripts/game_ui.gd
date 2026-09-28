extends CanvasLayer

signal item_toast_finished

const SHOWN_Y := 9.0
const HIDDEN_Y := -51.0
const ITEM_HOLD_TIME := 1.5
const ITEM_DIM_ALPHA := 0.5
const TITLE_SCENE := "res://scenes/title.tscn"
# この group に入っているシーン（タイトル画面など）では Esc メニューを開かない
const NO_PAUSE_GROUP := "no_pause_menu"
# 試練の間（この group の層）では、タイトルへ戻るボタンを「試練の間を出る」と表示する
const TRIAL_GROUP := "trial_floor"
const TITLE_BUTTON_TEXT := "タイトルへ"
const TRIAL_EXIT_TEXT := "試練の間を出る"
const KEY_ICON := preload("res://scripts/key_icon.gd")
const ORB_ICON := preload("res://scripts/orb_icon.gd")
const ITEM_ICONS := {
	"castle_door_key": KEY_ICON,
	"beginning_staff": ORB_ICON,
	"mage_robe": ORB_ICON,
	"ancient_buckler": ORB_ICON,
}
# 絵があるアイテム（Inventory.item_image）は、ITEM_ICONS より優先して絵を表示する（48x48 を 36 で表示。フルスクリーン（4倍）でドットがちょうど3x3）

@onready var _pause_menu: Control = $PauseMenu
@onready var _menu: Control = $PauseMenu/Menu
@onready var _title_button: Button = $PauseMenu/Menu/TitleButton
@onready var _settings_button: Button = $PauseMenu/Menu/SettingsButton
@onready var _settings_menu = $PauseMenu/SettingsMenu  # settings_menu.gd（タイトルの「設定」と同じもの）
@onready var _resume_button: Button = $PauseMenu/Menu/ResumeButton
@onready var _bug_button: Button = $PauseMenu/Menu/BugButton
@onready var _exit_button: Button = $PauseMenu/Menu/ExitButton
@onready var _bug_book: Control = $PauseMenu/BugBook
@onready var _item_dim: ColorRect = $ItemDim
@onready var _item_get: Control = $ItemGet
@onready var _item_icon: PixelIcon = $ItemGet/Icon
@onready var _item_image: TextureRect = $ItemGet/IconImage
@onready var _item_text: Label = $ItemGet/Text

var _item_tween: Tween
var _item_showing := false
var _was_paused := false


func _ready() -> void:
	_pause_menu.visible = false
	_item_dim.visible = false
	_title_button.pressed.connect(_go_to_title)
	_settings_button.pressed.connect(_settings_menu.open)
	_settings_menu.closed.connect(_settings_button.grab_focus)
	_resume_button.pressed.connect(_set_paused.bind(false))
	_bug_button.pressed.connect(_open_bug_book)
	_exit_button.pressed.connect(get_tree().quit)
	_bug_book.closed.connect(_close_bug_book)
	Inventory.item_added.connect(_on_item_added)


func _input(event: InputEvent) -> void:
	# 設定を開いている間の Esc は、設定の画面が自分で閉じる
	if TextPrompt.is_open() or _item_showing or _settings_menu.visible:
		return
	if event.is_action_pressed("pause_menu"):
		var scene := get_tree().current_scene
		if scene and scene.is_in_group(NO_PAUSE_GROUP):
			return
		if _bug_book.visible:
			_close_bug_book()
		else:
			_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused
	_bug_book.visible = false
	_settings_menu.visible = false
	_menu.visible = true
	if paused:
		var scene := get_tree().current_scene
		_title_button.text = TRIAL_EXIT_TEXT if scene and scene.is_in_group(TRIAL_GROUP) else TITLE_BUTTON_TEXT
		_title_button.grab_focus()


func _go_to_title() -> void:
	_set_paused(false)
	ViewSwitcher.go_to(TITLE_SCENE)


func _open_bug_book() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu.visible = false
	_bug_book.open()


func _close_bug_book() -> void:
	_bug_book.visible = false
	_menu.visible = true
	_bug_button.grab_focus()


# アイテム獲得の演出。演出の間はゲーム内の時間を止め、画面を暗くして、獲得したことをはっきり見せる
func _on_item_added(id: String) -> void:
	_item_text.text = Inventory.acquire_message(id)
	var image := Inventory.item_image(id)
	_item_image.visible = image != null
	_item_icon.visible = image == null
	if image:
		_item_image.texture = image
	else:
		var source: PixelIcon = ITEM_ICONS.get(id, KEY_ICON).new()
		_item_icon.pattern = source.pattern
		_item_icon.colors = source.colors
		_item_icon.queue_redraw()
		source.free()
	var icon: Control = _item_image if image else _item_icon

	if not _item_showing:
		_was_paused = get_tree().paused
	_item_showing = true
	get_tree().paused = true
	if _item_tween:
		_item_tween.kill()

	_item_dim.visible = true
	_item_dim.color.a = 0.0
	_item_get.position.y = HIDDEN_Y
	icon.scale = Vector2.ZERO
	_item_tween = create_tween()
	_item_tween.tween_property(_item_dim, "color:a", ITEM_DIM_ALPHA, 0.2)
	_item_tween.tween_property(_item_get, "position:y", SHOWN_Y, 0.3)
	_item_tween.tween_property(icon, "scale", Vector2(1.4, 1.4), 0.15)
	_item_tween.tween_property(icon, "scale", Vector2.ONE, 0.1)
	_item_tween.tween_interval(ITEM_HOLD_TIME)
	_item_tween.tween_property(_item_get, "position:y", HIDDEN_Y, 0.3)
	_item_tween.parallel().tween_property(_item_dim, "color:a", 0.0, 0.3)
	_item_tween.finished.connect(_on_item_toast_done)


func _on_item_toast_done() -> void:
	_item_dim.visible = false
	_item_showing = false
	get_tree().paused = _was_paused
	item_toast_finished.emit()
