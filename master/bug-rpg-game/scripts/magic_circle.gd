extends Node2D

# 攻撃の前に出る魔法陣。見た目は仮のドット絵（tools/generate_magic_circles.gd で書き出した PNG）。
# charge_time のあいだ回転しながら濃くなり、発射の直前に強く光る。時間になったら fired を出して消える。
#   BIG_RED   ：大技（全方向の円形）の前。二重円＋六芒星＋ルーン風の目盛り
#   YELLOW    ：一斉射撃（全方向の正方形）の前。重ねた四角＋ひし形＋角の点
#   SMALL_RED ：通常弾を撃つ位置。小さな円＋三角

signal fired

enum Kind { BIG_RED, YELLOW, SMALL_RED }

const TEXTURES := {
	Kind.BIG_RED: preload("res://assets/battle/magic_circle/big_red.png"),
	Kind.YELLOW: preload("res://assets/battle/magic_circle/yellow.png"),
	Kind.SMALL_RED: preload("res://assets/battle/magic_circle/small_red.png"),
}
const FADE_TIME := 0.25
const FLASH_START := 0.75  # 充填の何割から光り始めるか
const FLASH_POWER := 1.2   # 発射直前にどれだけ明るくするか（1 を超えると白に近づく）

var kind := Kind.SMALL_RED
var radius := 8.0  # 画像は等倍で表示するので、今は見た目には使っていない
var charge_time := 0.3
var spin := 1.0

var _time := 0.0
var _fired := false


func setup(p_kind: Kind, p_radius: float, p_charge_time: float) -> void:
	kind = p_kind
	radius = p_radius
	charge_time = p_charge_time
	spin = 2.5 if kind == Kind.SMALL_RED else 0.8


func _process(delta: float) -> void:
	_time += delta
	rotation += spin * delta
	if not _fired and _time >= charge_time:
		_fired = true
		fired.emit()
	if _time >= charge_time + FADE_TIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var texture: Texture2D = TEXTURES[kind]
	var progress := clampf(_time / charge_time, 0.0, 1.0)
	var alpha := 0.35 + 0.65 * progress
	if _fired:
		alpha *= 1.0 - clampf((_time - charge_time) / FADE_TIME, 0.0, 1.0)
	var bright := 1.0 + FLASH_POWER * smoothstep(FLASH_START, 1.0, progress)
	# 出現時に少し広がる
	var grow := 0.6 + 0.4 * minf(progress * 3.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(grow, grow))
	draw_texture(texture, -texture.get_size() / 2.0, Color(bright, bright, bright, alpha))
