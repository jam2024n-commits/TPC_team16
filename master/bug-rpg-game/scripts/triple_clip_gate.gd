extends Area2D

signal completed

const SEQUENCE := [1, -1, 1]

var _history: Array = []
var _done := false


func _ready() -> void:
	body_entered.connect(_on_entered)


func _on_entered(body: Node) -> void:
	if _done or not body is CharacterBody2D:
		return
	var vx: float = body.velocity.x
	if vx == 0.0:
		return
	var dir: int = 1 if vx > 0.0 else -1
	_history.append(dir)
	if _history.size() > SEQUENCE.size():
		_history.pop_front()
	if _history == SEQUENCE:
		_done = true
		# FAKE_BUG: triple_clip
		completed.emit()
