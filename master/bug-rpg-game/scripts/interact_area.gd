extends Area2D

signal interacted

@export var size := Vector2(24, 24)
@export var hint_text := "E: CHECK"

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _hint: Label = $Hint

var _player_inside := false


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(0, -size.y / 2.0)
	_hint.text = hint_text
	_hint.position = Vector2(-60, -size.y - 21)
	_hint.size = Vector2(120, 18)
	_hint.visible = false
	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))


# 入力イベントで受ける（看板を E で閉じたとき、同じ押下で開き直さないため）
func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit()


func _on_body(body: Node2D, inside: bool) -> void:
	if body is CharacterBody2D:
		_player_inside = inside
		_hint.visible = inside
