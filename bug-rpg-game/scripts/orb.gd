extends Area2D

# 試練の間のアイテム（以降「オーブ」）。プレイヤーが触れると collected を出して消える。
# texture を設定するとその画像（杖・盾など）を、設定しなければ黄色い球を表示する

signal collected

const RADIUS := 6.0
const GLOW_RADIUS := 10.5
const COLOR := Color(1.0, 0.88, 0.3)
const BOB_HEIGHT := 3.0
const BOB_SPEED := 3.0

@export var texture: Texture2D
# 画像を表示する大きさ。48x48 の画像を 24 で表示すると、フルスクリーン（4倍）でドットがちょうど2x2になる
@export var texture_size := 24.0

var _time := 0.0
var _taken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2(0, sin(_time * BOB_SPEED) * BOB_HEIGHT)
	if texture:
		draw_circle(center, texture_size * 0.55, Color(COLOR, 0.25))
		var draw_size := Vector2(texture_size, texture_size)
		draw_texture_rect(texture, Rect2(center - draw_size / 2.0, draw_size), false)
		return
	draw_circle(center, GLOW_RADIUS, Color(COLOR, 0.25))
	draw_circle(center, RADIUS, COLOR)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is CharacterBody2D:
		return
	_taken = true
	collected.emit()
	queue_free()
