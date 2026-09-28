extends "res://scripts/trial_floor.gd"

# 第三層。新しい操作はしゃがみジャンプ（この層だけ使える）。
# 画面の高さを下段・中段・上段に分けている。上段では上の境界を壊して画面の上へ出られ、
# 上の境界より上に出るとカメラの上の限界を広げて縦にスクロールする。
# 1マスの足場を3回しゃがみジャンプで登った先にオーブがあり、取ると最後の足場の右側に道が左から右へ伸びて、扉が現れる

const SCREEN_TOP := 12.0
const PATH_GROW_TIME := 0.8

@export var world_top := -460

@onready var _camera: Camera2D = $Player/Camera2D
@onready var _path = $Above/Path  # block.gd
@onready var _path_shape: CollisionShape2D = $Above/Path/CollisionShape2D

var _path_width := 0.0


func _ready() -> void:
	super()
	_camera.reset_smoothing.call_deferred()
	_border.top_broken.connect(_on_top_broken)
	# 道はオーブを取るまで隠しておく
	_path_width = _path.size.x
	_path.size = Vector2(0.0, _path.size.y)
	_path.visible = false
	_path_shape.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	super(delta)
	var above: bool = _player.global_position.y < SCREEN_TOP
	_camera.limit_top = world_top if above else 0


func _on_top_broken() -> void:
	# FAKE_BUG: top_boundary_break
	BugRegistry.trigger("top_boundary_break")


func _reveal_exit() -> void:
	_path.visible = true
	# オーブに触れた瞬間（物理の処理中）に呼ばれるので、当たり判定の切り替えは次の処理に回す
	_path_shape.set_deferred("disabled", false)
	var tween := create_tween()
	tween.tween_property(_path, "size:x", _path_width, PATH_GROW_TIME)
	tween.tween_callback(_appear_door)


func _appear_door() -> void:
	if _door:
		_door.appear()
