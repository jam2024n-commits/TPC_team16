extends CanvasLayer

const MAX_LOG_LINES := 4

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Panel/Title
@onready var _log: Label = $Root/Panel/Log
@onready var _field: LineEdit = $Root/Panel/Input
@onready var _close_hint: Label = $Root/Panel/CloseHint

var _handler: Callable
var _was_paused := false


func _ready() -> void:
	_root.visible = false
	_field.text_submitted.connect(_on_submitted)


func is_open() -> bool:
	return _root.visible


func open(title: String, message: String, handler: Callable) -> void:
	_handler = handler
	_field.visible = true
	_close_hint.visible = false
	_show(title, message)
	_field.text = ""
	_field.grab_focus()
	_field.edit()


# 入力欄なしで文章だけを出す（看板など）。E / Enter / Esc で閉じる
func show_message(title: String, message: String) -> void:
	_handler = Callable()
	_field.visible = false
	_close_hint.visible = true
	_show(title, message)


func append(text: String) -> void:
	var lines := (_log.text + "\n" + text).split("\n")
	_log.text = "\n".join(lines.slice(maxi(0, lines.size() - MAX_LOG_LINES)))


func close() -> void:
	_root.visible = false
	_field.release_focus()
	get_tree().paused = _was_paused


func _show(title: String, message: String) -> void:
	_title.text = title
	_log.text = message
	_was_paused = get_tree().paused
	get_tree().paused = true
	_root.visible = true


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("pause_menu") or (not _field.visible and _is_message_close(event)):
		close()
		get_viewport().set_input_as_handled()


func _is_message_close(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo \
		and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER)


func _on_submitted(text: String) -> void:
	_field.text = ""
	append("> " + text)
	_handler.call(text)
	if is_open():
		_field.edit()
