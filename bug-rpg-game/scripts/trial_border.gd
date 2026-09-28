extends Node2D

# 試練の間の境界（画面の上下左右の枠）。ステージ側に置く。
# right_clippable を有効にすると、右の境界だけ壁抜けできる壁になり、色も壁抜けできる壁と同じになる（第二層）。
# top_breakable を有効にすると、上の境界がしゃがみジャンプで壊せるブロックになる（第三層）。壊すと top_broken を出す

signal top_broken

# 壁抜けできる壁の色（各層の、壁抜けできる壁にも同じ色を使う）
const CLIP_COLOR := Color(0.6, 0.5, 0.7)
const CLIP_LAYER := 2
const BREAKABLE := preload("res://scenes/breakable_block.tscn")

@export var right_clippable := false
@export var top_breakable := false

@onready var _right = $Right  # block.gd（color を持つ）
@onready var _right_touch: Area2D = $RightTouch


func _ready() -> void:
	if right_clippable:
		# FAKE_BUG: boundary_clip
		_right.collision_layer = CLIP_LAYER
		_right.color = CLIP_COLOR
	if top_breakable:
		# FAKE_BUG: top_boundary_break
		var top = $Top
		var block = BREAKABLE.instantiate()
		block.name = "TopBreakable"
		block.position = top.position
		block.size = top.size
		block.smashed.connect(top_broken.emit)
		top.queue_free()
		add_child(block)


# 右の境界に内側から触れているか（外側から触れた場合は数えない）
func is_touching_right(body: Node2D) -> bool:
	return _right_touch.overlaps_body(body) and body.global_position.x < _right.global_position.x
