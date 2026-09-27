extends CanvasLayer

signal item_toast_finished

const SHOWN_Y := 6.0
const HIDDEN_Y := -34.0
const BUG_HOLD_TIME := 2.5
const ITEM_HOLD_TIME := 1.2

@onready var _pause_menu: Control = $PauseMenu
@onready var _menu: Control = $PauseMenu/Menu
@onready var _resume_button: Button = $PauseMenu/Menu/ResumeButton
@onready var _bug_button: Button = $PauseMenu/Menu/BugButton
@onready var _exit_button: Button = $PauseMenu/Menu/ExitButton
@onready var _bug_book: Control = $PauseMenu/BugBook
@onready var _discovery: Control = $Discovery
@onready var _discovery_icon: Control = $Discovery/Icon
@onready var _item_get: Control = $ItemGet
@onready var _item_icon: Control = $ItemGet/Icon
@onready var _item_text: Label = $ItemGet/Text

var _tweens: Dictionary = {}


func _ready() -> void:
	_pause_menu.visible = false
	_resume_button.pressed.connect(_set_paused.bind(false))
	_bug_button.pressed.connect(_open_bug_book)
	_exit_button.pressed.connect(get_tree().quit)
	_bug_book.closed.connect(_close_bug_book)
	BugRegistry.bug_discovered.connect(_on_bug_discovered)
	Inventory.item_added.connect(_on_item_added)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if _bug_book.visible:
			_close_bug_book()
		else:
			_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused
	_bug_book.visible = false
	_menu.visible = true
	if paused:
		_resume_button.grab_focus()


func _open_bug_book() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu.visible = false
	_bug_book.open()


func _close_bug_book() -> void:
	_bug_book.visible = false
	_menu.visible = true
	_bug_button.grab_focus()


func _on_bug_discovered(id: String) -> void:
	print("バグを発見！ (%s)" % id)
	_play_banner(_discovery, _discovery_icon, BUG_HOLD_TIME)


func _on_item_added(id: String) -> void:
	_item_text.text = "%sを手に入れた！" % Inventory.display_name(id)
	var tween := _play_banner(_item_get, _item_icon, ITEM_HOLD_TIME)
	tween.finished.connect(item_toast_finished.emit)


func _play_banner(banner: Control, icon: Control, hold: float) -> Tween:
	for other: Control in _tweens:
		_tweens[other].kill()
		other.position.y = HIDDEN_Y
	_tweens.clear()
	banner.position.y = HIDDEN_Y
	icon.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(banner, "position:y", SHOWN_Y, 0.3)
	tween.tween_property(icon, "scale", Vector2(1.4, 1.4), 0.15)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.1)
	tween.tween_interval(hold)
	tween.tween_property(banner, "position:y", HIDDEN_Y, 0.3)
	_tweens[banner] = tween
	return tween
