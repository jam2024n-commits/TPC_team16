extends "res://scripts/trial_floor.gd"

# 第二層。右の境界を壁抜けした先に、まだ続きがある（「端だと思っていたものに、実はまだ奥があった」）。
# 境界の外に出るとカメラの右の限界を広げ、横スクロールが始まる

const SCREEN_WIDTH := 320

@export var world_width := 640

@onready var _camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	super()
	# 開始時はカメラをなめらかに動かさず、最初から1画面目に合わせる
	_camera.reset_smoothing.call_deferred()


func _physics_process(delta: float) -> void:
	super(delta)
	var outside: bool = _player.global_position.x > SCREEN_WIDTH
	_camera.limit_right = world_width if outside else SCREEN_WIDTH
	if outside:
		# FAKE_BUG: boundary_clip
		BugRegistry.trigger("boundary_clip")
