extends CharacterBody2D

# ボス戦（シューティング）の自機。WASD / 矢印で8方向に移動する。
# Ctrl / C（しゃがみ）＋ Shift（ダッシュ）＋ WASD で押した向きにダッシュし、その間だけ黄色い球をすり抜けられる。
# 向きを押していなければ、最後に向いていた左右の方向にダッシュする。
# 見た目は右向きの画像で、左に動くと左右反転する。しゃがみ中は縦に縮める

const SPEED := 120.0
const CROUCH_SPEED := 60.0
const DASH_SPEED := 270.0
const DASH_TIME := 0.3
const DASH_COOLDOWN := 0.5
const INVINCIBLE_TIME := 1.0
const BLINK_PERIOD := 0.15

# 弾との当たり判定は体の中心付近だけ
const HITBOX_SIZE := Vector2(6, 6)

@onready var _sprite: Sprite2D = $Sprite

var _crouching := false
var _facing := 1.0
var _dash_left := 0.0
var _dash_cooldown := 0.0
var _dash_dir := Vector2.RIGHT
var _invincible_left := 0.0


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_invincible_left = maxf(_invincible_left - delta, 0.0)

	var crouch := Input.is_action_pressed("fp_crouch")
	if crouch != _crouching:
		_crouching = crouch
		_sprite.scale.y = 0.5 if _crouching else 1.0
		_sprite.position.y = _sprite.texture.get_height() / 4.0 if _crouching else 0.0

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.x != 0.0:
		_facing = signf(dir.x)
		_sprite.flip_h = _facing < 0.0

	if Input.is_action_just_pressed("dash") and _dash_left <= 0.0 and _dash_cooldown <= 0.0:
		_dash_left = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN
		_dash_dir = dir.normalized() if dir != Vector2.ZERO else Vector2(_facing, 0.0)

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * DASH_SPEED
	else:
		velocity = dir.normalized() * (CROUCH_SPEED if _crouching else SPEED)
	move_and_slide()

	# 無敵中は点滅
	_sprite.visible = _invincible_left <= 0.0 or fmod(_invincible_left, BLINK_PERIOD) < BLINK_PERIOD / 2.0


# FAKE_BUG: boss_bullet_clip
# しゃがみ中にダッシュしている間（壁抜けと同じ条件）
func is_clipping() -> bool:
	return _crouching and _dash_left > 0.0


func is_invincible() -> bool:
	return _invincible_left > 0.0


func start_invincible() -> void:
	_invincible_left = INVINCIBLE_TIME


func hitbox() -> Rect2:
	return Rect2(global_position - HITBOX_SIZE / 2.0, HITBOX_SIZE)
