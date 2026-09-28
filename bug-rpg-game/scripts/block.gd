@tool
extends StaticBody2D

const OUTLINE_WIDTH := 1.0

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

var _outline: Node2D


func _ready() -> void:
	_refresh()


# 内側のふちに枠線を付ける（試練の間で、背景と見分けやすくするため。trial_floor.gd が呼ぶ）。
# 色は material（shaders/block_outline.tres）が背景の明るさで決める
func enable_outline(material: Material) -> void:
	if _outline == null:
		_outline = Node2D.new()
		_outline.draw.connect(_draw_outline)
		add_child(_outline)
	_outline.material = material
	_outline.queue_redraw()


func _refresh() -> void:
	if _shape == null or _rect == null:
		return
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = size / 2.0
	_rect.position = Vector2.ZERO
	_rect.size = size
	_rect.color = color
	if _outline:
		_outline.queue_redraw()


func _draw_outline() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var w := minf(OUTLINE_WIDTH, size.x)
	var h := minf(OUTLINE_WIDTH, size.y)
	_outline.draw_rect(Rect2(0.0, 0.0, size.x, h), Color.WHITE)
	_outline.draw_rect(Rect2(0.0, size.y - h, size.x, h), Color.WHITE)
	_outline.draw_rect(Rect2(0.0, 0.0, w, size.y), Color.WHITE)
	_outline.draw_rect(Rect2(size.x - w, 0.0, w, size.y), Color.WHITE)
