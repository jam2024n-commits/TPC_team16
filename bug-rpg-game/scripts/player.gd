extends CharacterBody2D

const WALK_SPEED := 80.0
const CROUCH_SPEED := 36.0
const ACCEL := 800.0
const JUMP_VELOCITY := -300.0
const GRAVITY := 900.0
const MAX_FALL_SPEED := 400.0
const DASH_SPEED := 180.0
const DASH_TIME := 0.15
const DASH_COOLDOWN := 0.4

const MASK_NORMAL := 3
const MASK_CROUCH_DASH := 1
const THIN_WALL_MASK := 2

const STAND_SIZE := Vector2(10, 20)
const CROUCH_SIZE := Vector2(10, 10)

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _body: ColorRect = $Body

var _crouching := false
var _facing := 1
var _dash_left := 0.0
var _dash_cooldown := 0.0


func _ready() -> void:
	_apply_size(STAND_SIZE)


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_update_crouch()

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing = 1 if dir > 0.0 else -1

	if Input.is_action_just_pressed("dash") and _dash_left <= 0.0 and _dash_cooldown <= 0.0:
		_dash_left = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity.x = _facing * DASH_SPEED
		velocity.y = 0.0
	else:
		var speed := CROUCH_SPEED if _crouching else WALK_SPEED
		velocity.x = move_toward(velocity.x, dir * speed, ACCEL * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		if is_on_floor() and not _crouching and Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	# FAKE_BUG: wall_clip
	collision_mask = MASK_CROUCH_DASH if (_crouching and _dash_left > 0.0) else MASK_NORMAL

	move_and_slide()

	# FAKE_BUG: wall_clip
	if collision_mask == MASK_CROUCH_DASH and _overlaps_thin_wall():
		BugRegistry.trigger("wall_clip")

	if is_on_wall():
		_dash_left = 0.0


# FAKE_BUG: wall_clip
# しゃがみ中にダッシュしている間（壁抜けできる状態）
func is_clipping() -> bool:
	return _crouching and _dash_left > 0.0


func _update_crouch() -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if not _crouching and wants_crouch and is_on_floor():
		_crouching = true
		_apply_size(CROUCH_SIZE)
	elif _crouching and not wants_crouch and _can_stand():
		_crouching = false
		_apply_size(STAND_SIZE)


func _can_stand() -> bool:
	var probe := RectangleShape2D.new()
	probe.size = STAND_SIZE - Vector2(2, 2)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe
	query.transform = Transform2D(0.0, global_position + Vector2(0, -STAND_SIZE.y / 2.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _overlaps_thin_wall() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape.shape
	query.transform = _shape.global_transform
	query.collision_mask = THIN_WALL_MASK
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _apply_size(size: Vector2) -> void:
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = Vector2(0, -size.y / 2.0)
	_body.size = size
	_body.position = Vector2(-size.x / 2.0, -size.y)
