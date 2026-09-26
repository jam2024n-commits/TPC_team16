@tool
extends StaticBody2D

@export var size := Vector2(32, 16):
	set(value):
		size = value
		_refresh()
@export var color := Color(0.35, 0.4, 0.5):
	set(value):
		color = value
		_refresh()

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _rect: ColorRect = $Rect


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if _shape == null or _rect == null:
		return
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = size / 2.0
	_rect.position = Vector2.ZERO
	_rect.size = size
	_rect.color = color
