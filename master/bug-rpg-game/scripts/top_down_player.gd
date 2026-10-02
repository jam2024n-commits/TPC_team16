extends CharacterBody2D

# 見下ろし視点のプレイヤー。移動は上下左右の4方向。しゃがみは Ctrl / C（S は下移動に使うため）

const TILE := 8.0
const WALK_SPEED := 60.0
const CROUCH_SPEED := 30.0
const DASH_SPEED := 180.0
const DASH_TIME := 0.15
const DASH_COOLDOWN := 0.4

const MASK_NORMAL := 3
const MASK_CROUCH_DASH := 1

const STAND_SIZE := Vector2(6, 6)
const CROUCH_SIZE := Vector2(4, 4)
const STAND_COLOR := Color(0.9, 0.4, 0.3)
const CROUCH_COLOR := Color(0.65, 0.3, 0.22)

@onready var _body: ColorRect = $Body

var _crouching := false
var _facing := Vector2.RIGHT
var _dash_left := 0.0
var _dash_cooldown := 0.0


func _ready() -> void:
	_apply_look()


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	var crouch := Input.is_action_pressed("fp_crouch")
	if crouch != _crouching:
		_crouching = crouch
		_apply_look()

	var dir := _input_dir()
	if dir != Vector2.ZERO:
		_facing = dir

	if Input.is_action_just_pressed("dash") and _dash_left <= 0.0 and _dash_cooldown <= 0.0:
		_dash_left = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN

	var move := dir
	var speed := CROUCH_SPEED if _crouching else WALK_SPEED
	if _dash_left > 0.0:
		_dash_left -= delta
		move = _facing
		speed = DASH_SPEED
	velocity = move * speed
	_align_to_lane(move, speed, delta)

	# FAKE_BUG: wall_clip
	collision_mask = MASK_CROUCH_DASH if (_crouching and _dash_left > 0.0) else MASK_NORMAL

	move_and_slide()

	if is_on_wall():
		_dash_left = 0.0


func _input_dir() -> Vector2:
	var x := Input.get_axis("move_left", "move_right")
	var y := Input.get_axis("move_up", "move_down")
	if x != 0.0:
		return Vector2(signf(x), 0.0)
	if y != 0.0:
		return Vector2(0.0, signf(y))
	return Vector2.ZERO


# 進行方向と直角の向きを通路の中心へ寄せる（1マス幅の通路で曲がりやすくするため）
func _align_to_lane(move: Vector2, speed: float, delta: float) -> void:
	if move.x != 0.0:
		var target := (floorf(position.y / TILE) + 0.5) * TILE
		velocity.y = clampf((target - position.y) / delta, -speed, speed)
	elif move.y != 0.0:
		var target := (floorf(position.x / TILE) + 0.5) * TILE
		velocity.x = clampf((target - position.x) / delta, -speed, speed)


func _apply_look() -> void:
	var size := CROUCH_SIZE if _crouching else STAND_SIZE
	_body.size = size
	_body.position = -size / 2.0
	_body.color = CROUCH_COLOR if _crouching else STAND_COLOR
