extends Node2D

# 試練の間の境界（画面の上下左右の枠）。ステージ側に置く。
# right_clippable を有効にすると、右の境界だけ壁抜けできる壁になり、色も壁抜けできる壁と同じになる（第二層）

# 壁抜けできる壁の色（各層の、壁抜けできる壁にも同じ色を使う）
const CLIP_COLOR := Color(0.6, 0.5, 0.7)
const CLIP_LAYER := 2

@export var right_clippable := false

@onready var _right = $Right  # block.gd（color を持つ）
@onready var _right_touch: Area2D = $RightTouch


func _ready() -> void:
	if right_clippable:
		# FAKE_BUG: boundary_clip
		_right.collision_layer = CLIP_LAYER
		_right.color = CLIP_COLOR


# 右の境界に内側から触れているか（外側から触れた場合は数えない）
func is_touching_right(body: Node2D) -> bool:
	return _right_touch.overlaps_body(body) and body.global_position.x < _right.global_position.x
