extends "res://scripts/block.gd"

# しゃがみジャンプで下から当たると壊れるブロック（第三層）。明るい橙色に、ひびの線を入れた見た目。
# 壊れるときは破片が飛び散る。層をやり直すと元に戻る（シーンを読み直すため）

signal smashed

const DEBRIS := preload("res://scripts/break_debris.gd")
const CRACK_COLOR := Color(0.55, 0.28, 0.08)
const CRACK_STEP := 18.0

var _smashed := false


func _ready() -> void:
	super()
	var cracks := Node2D.new()
	cracks.draw.connect(_draw_cracks.bind(cracks))
	add_child(cracks)


func smash() -> void:
	if _smashed:
		return
	_smashed = true
	var debris = DEBRIS.new()
	debris.setup(Rect2(global_position, size), color)
	get_parent().add_child(debris)
	smashed.emit()
	queue_free()


# ひびの線：横 CRACK_STEP ごとに、上から下へのジグザグ線と小さな枝を描く
func _draw_cracks(canvas: Node2D) -> void:
	var x := 3.0
	var i := 0
	while x < size.x - 3.0:
		var sway := 3.0 if i % 2 == 0 else -3.0
		var points := PackedVector2Array([
			Vector2(x, 0.0),
			Vector2(x + sway, size.y * 0.4),
			Vector2(x - sway * 0.5, size.y * 0.7),
			Vector2(x + sway, size.y),
		])
		canvas.draw_polyline(points, CRACK_COLOR, 1.0)
		canvas.draw_line(points[1], points[1] + Vector2(sway * 1.5, size.y * 0.2), CRACK_COLOR, 1.0)
		x += CRACK_STEP
		i += 1
