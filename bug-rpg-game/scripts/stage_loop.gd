extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const START_POSITION := Vector2(24, 164)
const ENEMY_POSITION := Vector2(380, 164)
const RETURN_WINDOW := 1.0

@onready var _player: CharacterBody2D = $Player
@onready var _loop_end: Area2D = $LoopEnd
@onready var _terminal: Node2D = $Terminal

var _enemy: Node2D
var _enter_pressed_at := -INF
var _escaping := false


func _ready() -> void:
	_loop_end.body_entered.connect(_on_loop_end_reached)
	# FAKE_BUG: loop_break
	_terminal.break_handler = _escape.bind("loop_break")
	_spawn_enemy()


func _input(event: InputEvent) -> void:
	if _escaping or not event is InputEventKey or not event.pressed or event.echo:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_enter_pressed_at = now
	elif event.unicode == ";".unicode_at(0) and now - _enter_pressed_at <= RETURN_WINDOW:
		# FAKE_BUG: loop_return
		_escape("loop_return")
	else:
		_enter_pressed_at = -INF


func _on_loop_end_reached(body: Node2D) -> void:
	if body != _player or _escaping:
		return
	# FAKE_BUG: infinite_loop
	BugRegistry.trigger("infinite_loop")
	_player.global_position = START_POSITION
	_player.velocity = Vector2.ZERO
	_spawn_enemy()


func _spawn_enemy() -> void:
	if is_instance_valid(_enemy):
		_enemy.queue_free()
	_enemy = ENEMY_SCENE.instantiate()
	_enemy.remember_defeat = false
	_enemy.position = ENEMY_POSITION
	add_child(_enemy)


func _escape(bug_id: String) -> void:
	if _escaping:
		return
	_escaping = true
	BugRegistry.trigger(bug_id)
	ViewSwitcher.return_to_field()
