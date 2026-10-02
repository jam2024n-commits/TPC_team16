extends Node2D

# シューティングの自機。左右移動の1軸のみ。しゃがみ（S）とダッシュ（Shift）はほかの場面と同じ

const SPEED := 90.0
const CROUCH_SPEED := 45.0
const DASH_SPEED := 180.0
const DASH_TIME := 0.3
const DASH_COOLDOWN := 0.5
const INVINCIBLE_TIME := 1.0

const HITBOX_SIZE := Vector2(4, 4)
const STAND_SIZE := Vector2(8, 8)
const CROUCH_SIZE := Vector2(6, 5)
const STAND_COLOR := Color(0.9, 0.4, 0.3)
const CROUCH_COLOR := Color(0.65, 0.3, 0.22)

@onready var _body: ColorRect = $Body

var min_x := 0.0
var max_x := 320.0
var _crouching := false
var _facing := 1.0
var _dash_left := 0.0
var _dash_cooldown := 0.0
var _invincible_left := 0.0


func _ready() -> void:
	_apply_look()


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_invincible_left = maxf(_invincible_left - delta, 0.0)
	var crouch := Input.is_action_pressed("crouch")
	if crouch != _crouching:
		_crouching = crouch
		_apply_look()

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing = signf(dir)
	if Input.is_action_just_pressed("dash") and _dash_left <= 0.0 and _dash_cooldown <= 0.0:
		_dash_left = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN

	var velocity := dir * (CROUCH_SPEED if _crouching else SPEED)
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _facing * DASH_SPEED
	position.x = clampf(position.x + velocity * delta, min_x, max_x)

	# 無敵中は点滅
	visible = _invincible_left <= 0.0 or fmod(_invincible_left, 0.15) < 0.08


# しゃがみ中にダッシュしている間（壁抜けと同じ条件）
func is_clipping() -> bool:
	return _crouching and _dash_left > 0.0


func is_invincible() -> bool:
	return _invincible_left > 0.0


func start_invincible() -> void:
	_invincible_left = INVINCIBLE_TIME


func hitbox() -> Rect2:
	return Rect2(position - HITBOX_SIZE / 2.0, HITBOX_SIZE)


func _apply_look() -> void:
	var size := CROUCH_SIZE if _crouching else STAND_SIZE
	_body.size = size
	_body.position = -size / 2.0
	_body.color = CROUCH_COLOR if _crouching else STAND_COLOR
