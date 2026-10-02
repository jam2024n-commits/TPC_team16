extends CharacterBody2D

# ボス戦（シューティング）の自機。WASD / 矢印で8方向に移動する。
# Ctrl（しゃがみ）＋ Shift（ダッシュ）＋ WASD で押した向きにダッシュし、その間だけ黄色い球をすり抜けられる。
# 向きを押していなければ、最後に向いていた左右の方向にダッシュする。
# 見た目は右向きの画像で、左に動くと左右反転する。しゃがみ中は縦に縮める。
# idle_texture を設定すると、立ったまま IDLE_WAIT 以上動かないと待機モーションになる
# 攻撃（どちらもボスの方向へ飛ぶ。弾を動かすのは boss_battle.gd）：
#   Space：通常弾。押している間は連射する。can_shoot（杖を持っている）のときだけ
#   C：チャージ。押してから CHARGE_TIME たつと自動でチャージ弾を撃つ。それまでに離すと何も出ない。撃ったあとは押し直す。can_charge（魔導士のローブを持っている）のときだけ

signal shot_fired(from: Vector2)
signal charge_fired(from: Vector2)

const SPEED := 120.0
const CROUCH_SPEED := 60.0
const DASH_SPEED := 270.0
const DASH_TIME := 0.3
const DASH_COOLDOWN := 0.5
const INVINCIBLE_TIME := 1.0
const BLINK_PERIOD := 0.15

# 待機モーション：idle_texture は同じ大きさのコマが横に IDLE_FRAMES 枚並んだ画像。IDLE_FRAME_TIME ごとに次のコマへ
const IDLE_WAIT := 1.0
const IDLE_FRAMES := 2
const IDLE_FRAME_TIME := 0.5

const SHOT_INTERVAL := 0.15
const CHARGE_TIME := 1.0
# チャージ中の見た目（charge_sheet.png の 0〜3 コマを順に、最後の CHARGED_SHOW_TIME だけ 4 コマ目＝ため終わり）
const CHARGE_SHEET := preload("res://assets/battle/bullet/charge/charge_sheet.png")
const CHARGE_FRAME_SIZE := 48.0
const CHARGING_FRAMES := 4
const CHARGED_FRAME := 4
const CHARGED_SHOW_TIME := 0.2

# 弾との当たり判定は体の中心付近だけ
const HITBOX_SIZE := Vector2(6, 6)

@export var can_shoot := false
@export var can_charge := false
@export var idle_texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite

var _crouching := false
var _facing := 1.0
var _dash_left := 0.0
var _dash_cooldown := 0.0
var _dash_dir := Vector2.RIGHT
var _invincible_left := 0.0
var _shot_cooldown := 0.0
var _charging := false
var _charge_time := 0.0
var _charge_effect: Node2D
var _still_time := 0.0
var _stand_texture: Texture2D


func _ready() -> void:
	_stand_texture = _sprite.texture
	# チャージ中の見た目は自機の手前に重ねる
	_charge_effect = Node2D.new()
	_charge_effect.draw.connect(_draw_charge)
	add_child(_charge_effect)


func _physics_process(delta: float) -> void:
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_invincible_left = maxf(_invincible_left - delta, 0.0)

	var crouch := Input.is_action_pressed("boss_crouch")
	if crouch != _crouching:
		_crouching = crouch
		_sprite.scale.y = 0.5 if _crouching else 1.0
		_sprite.position.y = _sprite.get_rect().size.y / 4.0 if _crouching else 0.0

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

	_update_shot(delta)
	_update_charge(delta)
	_update_idle(delta, dir)

	# 無敵中は点滅
	_sprite.visible = _invincible_left <= 0.0 or fmod(_invincible_left, BLINK_PERIOD) < BLINK_PERIOD / 2.0


func _update_shot(delta: float) -> void:
	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	if can_shoot and Input.is_action_pressed("shoot") and _shot_cooldown <= 0.0:
		_shot_cooldown = SHOT_INTERVAL
		shot_fired.emit(global_position)


func _update_charge(delta: float) -> void:
	if not can_charge:
		_charging = false
	elif Input.is_action_just_pressed("charge_shot"):
		_charging = true
		_charge_time = 0.0
	elif not Input.is_action_pressed("charge_shot"):
		_charging = false
	if _charging:
		_charge_time += delta
		if _charge_time >= CHARGE_TIME:
			_charging = false
			charge_fired.emit(global_position)
	_charge_effect.queue_redraw()


func _draw_charge() -> void:
	if not _charging:
		return
	var frame := CHARGED_FRAME
	var charging_time := CHARGE_TIME - CHARGED_SHOW_TIME
	if _charge_time < charging_time:
		frame = mini(int(_charge_time / charging_time * CHARGING_FRAMES), CHARGING_FRAMES - 1)
	var size := Vector2(CHARGE_FRAME_SIZE, CHARGE_FRAME_SIZE)
	var region := Rect2(frame * CHARGE_FRAME_SIZE, 0.0, CHARGE_FRAME_SIZE, CHARGE_FRAME_SIZE)
	_charge_effect.draw_texture_rect_region(CHARGE_SHEET, Rect2(-size / 2.0, size), region)


func _update_idle(delta: float, dir: Vector2) -> void:
	if idle_texture == null:
		return
	var still := dir == Vector2.ZERO and not _crouching and _dash_left <= 0.0
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


func is_charging() -> bool:
	return _charging


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
