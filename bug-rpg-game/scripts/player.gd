extends CharacterBody2D

# 横スクロールのプレイヤー。
# world_scale で、速さ・ジャンプ力・重力・当たり判定の大きさをまとめて倍率で変える
# （試練の間は基準解像度 480x270 に合わせて 1.5。方針変更前の 320x180 のシーンは 1）。
# 見た目は、Sprite（画像）があればそれを使い、なければ Body（四角）を使う。
# can_crouch_jump を有効にすると（第三層のみ）、しゃがみジャンプができる：
#   床の上でしゃがんだまま1秒たつと、ため状態（白っぽく点滅）になる。しゃがんだまま歩いてもためは続く。
#   ため状態でジャンプキーを押すと、立ち姿勢に戻って高く跳ぶ（しゃがみを押しているだけでは跳ばない）。
#   しゃがみを離すか、壁抜けで壁を通り抜けると、ためは解除される。
#   しゃがみジャンプで上昇中に、壊せるブロック（smash を持つもの）に下から当たると壊す（頭はそこでぶつかって止まる）
# idle_texture を設定すると（試練の間の主人公）、床の上で立ったまま IDLE_WAIT 以上動かないと待機モーションになる

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

const CROUCH_JUMP_CHARGE_TIME := 1.0
const CROUCH_JUMP_HEIGHT := 280.0 / 3.0  # world_scale 1.5 で 140 ピクセル
const CHARGE_BLINK_PERIOD := 0.12
const CHARGE_BRIGHT := Color(1.9, 1.9, 1.9)

# 待機モーション：idle_texture は同じ大きさのコマが横に IDLE_FRAMES 枚並んだ画像。IDLE_FRAME_TIME ごとに次のコマへ
const IDLE_WAIT := 1.0
const IDLE_FRAMES := 2
const IDLE_FRAME_TIME := 0.5

@export var world_scale := 1.0
@export var can_crouch_jump := false
@export var idle_texture: Texture2D

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _body: ColorRect = get_node_or_null("Body")
@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

var _crouching := false
var _facing := 1
var _dash_left := 0.0
var _dash_cooldown := 0.0
var _charge_time := 0.0
var _charged := false
var _high_jumping := false
var _still_time := 0.0
var _stand_texture: Texture2D


func _ready() -> void:
	if _sprite:
		_stand_texture = _sprite.texture
	_apply_size(STAND_SIZE)


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_update_crouch()
	_update_charge(delta)

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing = 1 if dir > 0.0 else -1
		if _sprite:
			_sprite.flip_h = _facing < 0

	if Input.is_action_just_pressed("dash") and _dash_left <= 0.0 and _dash_cooldown <= 0.0:
		_dash_left = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity.x = _facing * DASH_SPEED * world_scale
		velocity.y = 0.0
	else:
		var speed := (CROUCH_SPEED if _crouching else WALK_SPEED) * world_scale
		velocity.x = move_toward(velocity.x, dir * speed, ACCEL * world_scale * delta)
		velocity.y = minf(velocity.y + GRAVITY * world_scale * delta, MAX_FALL_SPEED * world_scale)
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			if not _crouching:
				velocity.y = JUMP_VELOCITY * world_scale
			elif _charged and _can_stand():
				_crouch_jump()

	# FAKE_BUG: wall_clip
	collision_mask = MASK_CROUCH_DASH if (_crouching and _dash_left > 0.0) else MASK_NORMAL

	move_and_slide()

	# FAKE_BUG: wall_clip
	if collision_mask == MASK_CROUCH_DASH and _overlaps_thin_wall():
		BugRegistry.trigger("wall_clip")

	# FAKE_BUG: crouch_jump
	# 壁抜けで壁を通り抜けたら、しゃがみジャンプのためを解除する
	if _charged and collision_mask == MASK_CROUCH_DASH and _overlaps_thin_wall():
		_reset_charge()

	if _high_jumping:
		if is_on_ceiling():
			_smash_ceiling()
			_high_jumping = false
		elif velocity.y >= 0.0:
			_high_jumping = false

	if is_on_wall():
		_dash_left = 0.0

	_update_idle(delta)


# ---- しゃがみジャンプ ----

func _update_charge(delta: float) -> void:
	if not can_crouch_jump:
		return
	if _crouching:
		if is_on_floor():
			_charge_time += delta
		if _charge_time >= CROUCH_JUMP_CHARGE_TIME:
			_charged = true
	else:
		_reset_charge()
	# ため状態は白っぽく点滅
	var look: CanvasItem = _sprite if _sprite else _body
	if look:
		var bright := _charged and fmod(_charge_time, CHARGE_BLINK_PERIOD) < CHARGE_BLINK_PERIOD / 2.0
		look.modulate = CHARGE_BRIGHT if bright else Color.WHITE


func _reset_charge() -> void:
	_charge_time = 0.0
	_charged = false


# FAKE_BUG: crouch_jump
func _crouch_jump() -> void:
	_crouching = false
	_apply_size(STAND_SIZE)
	velocity.y = -sqrt(2.0 * GRAVITY * CROUCH_JUMP_HEIGHT) * world_scale
	_high_jumping = true
	_reset_charge()
	BugRegistry.trigger("crouch_jump")


# FAKE_BUG: crouch_jump
# しゃがみジャンプで頭をぶつけたブロックが壊せるものなら壊す（頭はそこで止まる）
func _smash_ceiling() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider and collider.has_method("smash") and get_slide_collision(i).get_normal().y > 0.5:
			collider.smash()


func is_charged() -> bool:
	return _charged


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
	var stand := STAND_SIZE * world_scale
	var probe := RectangleShape2D.new()
	probe.size = stand - Vector2(2, 2)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe
	query.transform = Transform2D(0.0, global_position + Vector2(0, -stand.y / 2.0))
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


func _apply_size(base_size: Vector2) -> void:
	var size := base_size * world_scale
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = Vector2(0, -size.y / 2.0)
	if _body:
		_body.size = size
		_body.position = Vector2(-size.x / 2.0, -size.y)
	if _sprite:
		# 画像は足元を基準に置く。しゃがみ中は縦に縮める（しゃがみ用の画像ができるまでの仮）
		# 大きさは1コマ分（待機モーション中はコマが並んだ画像になっているため）
		var frame_size := _sprite.get_rect().size
		_sprite.scale.y = base_size.y / STAND_SIZE.y
		_sprite.position = Vector2(-frame_size.x / 2.0, -frame_size.y * _sprite.scale.y)


# ---- 待機モーション ----

func _update_idle(delta: float) -> void:
	if _sprite == null or idle_texture == null:
		return
	var still := is_on_floor() and not _crouching and _dash_left <= 0.0 and absf(velocity.x) < 1.0
	_still_time = _still_time + delta if still else 0.0
	if _still_time >= IDLE_WAIT:
		if _sprite.texture != idle_texture:
			_sprite.texture = idle_texture
			_sprite.hframes = IDLE_FRAMES
		_sprite.frame = int((_still_time - IDLE_WAIT) / IDLE_FRAME_TIME) % IDLE_FRAMES
	elif _sprite.texture != _stand_texture:
		_sprite.texture = _stand_texture
		_sprite.hframes = 1
		_sprite.frame = 0


func is_idle() -> bool:
	return _sprite != null and idle_texture != null and _sprite.texture == idle_texture
