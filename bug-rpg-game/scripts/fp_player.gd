extends CharacterBody3D

const SPEED := 3.0
const DASH_SPEED := 8.0
const DASH_TIME := 0.25
const DASH_COOLDOWN := 0.4
const GRAVITY := 9.8
const MOUSE_SENSITIVITY := 0.003
const EYE_HEIGHT := 1.6
const CROUCH_EYE_HEIGHT := 1.2
const EYE_LERP := 10.0

const MASK_NORMAL := 3
const MASK_CROUCH_DASH := 1

@onready var _camera: Camera3D = $Camera3D

var can_crouch := false
var _crouching := false
var _dash_left := 0.0
var _dash_cooldown := 0.0
var _dash_dir := Vector3.ZERO


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_UNPAUSED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.screen_relative.x * MOUSE_SENSITIVITY)
		_camera.rotation.x = clampf(_camera.rotation.x - event.screen_relative.y * MOUSE_SENSITIVITY, -1.3, 1.3)


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_crouching = can_crouch and Input.is_action_pressed("fp_crouch")

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	if Input.is_action_just_pressed("dash") and _dash_left <= 0.0 and _dash_cooldown <= 0.0:
		_dash_left = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN
		_dash_dir = dir if dir != Vector3.ZERO else -transform.basis.z

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity.x = _dash_dir.x * DASH_SPEED
		velocity.z = _dash_dir.z * DASH_SPEED
	else:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta

	# FAKE_BUG: wall_clip
	collision_mask = MASK_CROUCH_DASH if (_crouching and _dash_left > 0.0) else MASK_NORMAL

	move_and_slide()

	var eye := CROUCH_EYE_HEIGHT if _crouching else EYE_HEIGHT
	_camera.position.y = lerpf(_camera.position.y, eye, clampf(EYE_LERP * delta, 0.0, 1.0))
