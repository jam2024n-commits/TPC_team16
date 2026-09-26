extends CanvasLayer

const SHOWN_Y := 6.0
const HIDDEN_Y := -34.0
const HOLD_TIME := 2.5

@onready var _pause_menu: Control = $PauseMenu
@onready var _resume_button: Button = $PauseMenu/Menu/ResumeButton
@onready var _exit_button: Button = $PauseMenu/Menu/ExitButton
@onready var _discovery: Control = $Discovery
@onready var _icon: Control = $Discovery/Icon

var _tween: Tween


func _ready() -> void:
	_pause_menu.visible = false
	_resume_button.pressed.connect(_set_paused.bind(false))
	_exit_button.pressed.connect(get_tree().quit)
	BugRegistry.bug_discovered.connect(_on_bug_discovered)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused
	if paused:
		_resume_button.grab_focus()


func _on_bug_discovered(id: String) -> void:
	print("バグを発見！ (%s)" % id)
	if _tween:
		_tween.kill()
	_discovery.position.y = HIDDEN_Y
	_icon.scale = Vector2.ZERO
	_tween = create_tween()
	_tween.tween_property(_discovery, "position:y", SHOWN_Y, 0.3)
	_tween.tween_property(_icon, "scale", Vector2(1.4, 1.4), 0.15)
	_tween.tween_property(_icon, "scale", Vector2.ONE, 0.1)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(_discovery, "position:y", HIDDEN_Y, 0.3)
