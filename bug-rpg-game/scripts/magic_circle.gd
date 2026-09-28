extends Node2D

# 攻撃の前に出る魔法陣（仮の見た目。スクリプトで図形を描いている）。
# charge_time のあいだ回転しながら濃くなり、発射の直前に強く光る。時間になったら fired を出して消える。
#   BIG_RED   ：大技（全方向の円形）の前。二重円＋六芒星＋ルーン風の目盛り
#   YELLOW    ：一斉射撃（全方向の正方形）の前。重ねた四角＋ひし形＋角の点
#   SMALL_RED ：通常弾を撃つ位置。小さな円＋三角

signal fired

enum Kind { BIG_RED, YELLOW, SMALL_RED }

const RED := Color(1.0, 0.25, 0.2)
const YELLOW := Color(1.0, 0.85, 0.25)
const FADE_TIME := 0.25
const FLASH_START := 0.75  # 充填の何割から光り始めるか

var kind := Kind.SMALL_RED
var radius := 8.0
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
	var color := RED if kind != Kind.YELLOW else YELLOW
	var progress := clampf(_time / charge_time, 0.0, 1.0)
	var alpha := 0.35 + 0.65 * progress
	if _fired:
		alpha *= 1.0 - clampf((_time - charge_time) / FADE_TIME, 0.0, 1.0)
	var flash := smoothstep(FLASH_START, 1.0, progress)
	var line := Color(color.lerp(Color.WHITE, flash * 0.6), alpha)
	var glow := Color(color, alpha * (0.12 + 0.25 * flash))
	# 出現時に少し広がる
	var r := radius * (0.6 + 0.4 * minf(progress * 3.0, 1.0))

	draw_circle(Vector2.ZERO, r, glow)
	match kind:
		Kind.BIG_RED:
			_draw_big_red(r, line)
		Kind.YELLOW:
			_draw_yellow(r, line)
		Kind.SMALL_RED:
			_draw_small_red(r, line)


func _draw_big_red(r: float, line: Color) -> void:
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, line, 1.5)
	draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 48, line, 1.0)
	draw_arc(Vector2.ZERO, r * 0.35, 0.0, TAU, 24, line, 1.0)
	# 六芒星
	for start in [0.0, PI / 3.0]:
		var points := PackedVector2Array()
		for i in 4:
			points.append(Vector2.from_angle(start + i * TAU / 3.0) * r * 0.82)
		draw_polyline(points, line, 1.0)
	# ルーン風の目盛り（逆回転）
	for i in 12:
		var a := -_time * 1.6 + i * TAU / 12.0
		var dir := Vector2.from_angle(a)
		var tangent := dir.orthogonal()
		var p := dir * r * 0.91
		draw_line(p - tangent * 2.0, p + tangent * 2.0, line, 1.0)
		if i % 2 == 0:
			draw_line(p, p + dir * 2.5, line, 1.0)


func _draw_yellow(r: float, line: Color) -> void:
	# 45度ずらした四角を2つ重ねる
	for offset in [0.0, PI / 4.0]:
		_draw_square(r * 0.9, offset, line, 1.5)
	_draw_square(r * 0.55, -_time * 1.4, line, 1.0)
	draw_arc(Vector2.ZERO, r * 0.95, 0.0, TAU, 48, line, 1.0)
	draw_arc(Vector2.ZERO, r * 0.3, 0.0, TAU, 24, line, 1.0)
	# 角の点
	for i in 8:
		draw_circle(Vector2.from_angle(i * TAU / 8.0) * r * 0.9, 1.5, line)


func _draw_small_red(r: float, line: Color) -> void:
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, line, 1.0)
	var points := PackedVector2Array()
	for i in 4:
		points.append(Vector2.from_angle(-PI / 2.0 + i * TAU / 3.0) * r * 0.8)
	draw_polyline(points, line, 1.0)


func _draw_square(half: float, angle: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in 5:
		points.append(Vector2.from_angle(angle + PI / 4.0 + i * TAU / 4.0) * half * sqrt(2.0))
	draw_polyline(points, color, width)
