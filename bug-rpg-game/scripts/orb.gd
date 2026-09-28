extends Area2D

# 試練の間のアイテム（黄色い球。以降「オーブ」）。プレイヤーが触れると collected を出して消える

signal collected

const RADIUS := 6.0
const GLOW_RADIUS := 10.5
const COLOR := Color(1.0, 0.88, 0.3)
const BOB_HEIGHT := 3.0
const BOB_SPEED := 3.0

var _time := 0.0
var _taken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2(0, sin(_time * BOB_SPEED) * BOB_HEIGHT)
	draw_circle(center, GLOW_RADIUS, Color(COLOR, 0.25))
	draw_circle(center, RADIUS, COLOR)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is CharacterBody2D:
		return
	_taken = true
	collected.emit()
	queue_free()
