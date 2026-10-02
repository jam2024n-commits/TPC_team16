extends Node2D

# 2D迷路のゴールの先で、脈絡なく始まる縦シューティング。
# 赤い弾は普通によける。黄色い弾は隙間のない列で飛んできて、普通にはよけられないが、
# しゃがみ+ダッシュ中（壁抜けと同じ条件）は当たり判定がなくなる（bullet_clip）。
# ボスを倒すとカギを入手して元のステージへ戻る。やられたら最初からやり直し

const FIELD := Rect2(80, 0, 160, 180)
const PLAYER_Y := 164.0
const ITEM_ID := "castle_door_key"

const PLAYER_HP := 3
const SHOT_SPEED := 240.0
const SHOT_INTERVAL := 0.12
const SHOT_RADIUS := 1.5

const BOSS_HP := 80
const BOSS_SIZE := Vector2(28, 14)
const BOSS_Y := 30.0
const BOSS_SWAY := 50.0
const BOSS_SWAY_SPEED := 0.8

const START_DELAY := 1.0
const RED_INTERVAL := 0.9
const RED_SPEED := 70.0
const RED_SPREAD := 0.26
const YELLOW_FIRST := 4.0
const YELLOW_INTERVAL := 6.0
const YELLOW_SPEED := 70.0
const YELLOW_GAP := 5.0
const RED_PAUSE_AFTER_YELLOW := 1.5
const BULLET_RADIUS := 2.5

const BG_COLOR := Color(0.02, 0.02, 0.04)
const FIELD_COLOR := Color(0.05, 0.06, 0.12)
const STAR_COLOR := Color(0.5, 0.55, 0.7)
const RED := Color(1.0, 0.25, 0.2)
const YELLOW := Color(1.0, 0.9, 0.2)
const BOSS_COLOR := Color(0.55, 0.35, 0.7)
const BAR_COLOR := Color(0.8, 0.3, 0.3)

const END_WAIT := 1.2

enum State { FIGHT, CLEAR, FAILED }

@onready var _player: Node2D = $Player
@onready var _hp_label: Label = $HpLabel
@onready var _message: Label = $Message

var _state := State.FIGHT
var _time := 0.0
var _hp := PLAYER_HP
var _boss_hp := BOSS_HP
var _boss_pos := Vector2(FIELD.get_center().x, BOSS_Y)
var _boss_flash := 0.0
var _shot_cooldown := 0.0
var _red_timer := START_DELAY
var _yellow_timer := YELLOW_FIRST
var _shots: Array[Vector2] = []
var _bullets: Array[Dictionary] = []  # {pos, vel, yellow}
var _stars: Array[Vector3] = []  # x, y, speed


func _ready() -> void:
	_player.position = Vector2(FIELD.get_center().x, PLAYER_Y)
	_player.min_x = FIELD.position.x + 4.0
	_player.max_x = FIELD.end.x - 4.0
	for i in 40:
		_stars.append(Vector3(randf_range(FIELD.position.x, FIELD.end.x), randf_range(0, FIELD.size.y), randf_range(15, 45)))
	_message.visible = false
	_update_hp_label()


func _physics_process(delta: float) -> void:
	_move_stars(delta)
	if _state == State.FIGHT:
		_time += delta
		_update_boss(delta)
		_update_player_shots(delta)
		_update_bullets(delta)
		_check_player_hit()
	queue_redraw()


func _move_stars(delta: float) -> void:
	for i in _stars.size():
		var s := _stars[i]
		s.y += s.z * delta
		if s.y > FIELD.size.y:
			s = Vector3(randf_range(FIELD.position.x, FIELD.end.x), 0.0, s.z)
		_stars[i] = s


func _update_boss(delta: float) -> void:
	_boss_pos.x = FIELD.get_center().x + sin(_time * BOSS_SWAY_SPEED) * BOSS_SWAY
	_boss_flash = maxf(_boss_flash - delta, 0.0)

	_red_timer -= delta
	if _red_timer <= 0.0:
		_red_timer = RED_INTERVAL
		_fire_red()

	_yellow_timer -= delta
	if _yellow_timer <= 0.0:
		_yellow_timer = YELLOW_INTERVAL
		_fire_yellow_wall()
		_red_timer = maxf(_red_timer, RED_PAUSE_AFTER_YELLOW)


# 自機を狙った3方向の赤い弾
func _fire_red() -> void:
	var from := _boss_pos + Vector2(0, BOSS_SIZE.y / 2.0)
	var aim := (_player.position - from).angle()
	for i in [-1, 0, 1]:
		_bullets.append({"pos": from, "vel": Vector2.from_angle(aim + i * RED_SPREAD) * RED_SPEED, "yellow": false})


# 画面の端から端まで隙間なく並んだ黄色い弾の列（普通にはよけられない）
func _fire_yellow_wall() -> void:
	var y := _boss_pos.y + BOSS_SIZE.y
	var x := FIELD.position.x + BULLET_RADIUS
	while x < FIELD.end.x:
		_bullets.append({"pos": Vector2(x, y), "vel": Vector2(0, YELLOW_SPEED), "yellow": true})
		x += YELLOW_GAP


func _update_player_shots(delta: float) -> void:
	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	if Input.is_action_pressed("shoot") and _shot_cooldown <= 0.0:
		_shot_cooldown = SHOT_INTERVAL
		_shots.append(_player.position + Vector2(0, -6))

	var boss_rect := _boss_rect()
	var alive: Array[Vector2] = []
	for shot in _shots:
		shot.y -= SHOT_SPEED * delta
		if boss_rect.has_point(shot):
			_boss_hp -= 1
			_boss_flash = 0.05
			if _boss_hp <= 0:
				_on_clear()
				return
		elif shot.y > -4.0:
			alive.append(shot)
	_shots = alive


func _update_bullets(delta: float) -> void:
	var bounds := FIELD.grow(8.0)
	var alive: Array[Dictionary] = []
	for b in _bullets:
		b.pos += b.vel * delta
		if bounds.has_point(b.pos):
			alive.append(b)
	_bullets = alive


func _check_player_hit() -> void:
	var box: Rect2 = _player.hitbox()
	for b in _bullets:
		if not _circle_hits_rect(b.pos, BULLET_RADIUS, box):
			continue
		if b.yellow and _player.is_clipping():
			# FAKE_BUG: bullet_clip
			BugRegistry.trigger("bullet_clip")
			continue
		if _player.is_invincible():
			continue
		_bullets.erase(b)
		_on_player_hit()
		return


func _circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := center.clamp(rect.position, rect.end)
	return center.distance_squared_to(closest) < radius * radius


func _on_player_hit() -> void:
	_hp -= 1
	_update_hp_label()
	if _hp <= 0:
		_on_failed()
	else:
		_player.start_invincible()


func _on_clear() -> void:
	_state = State.CLEAR
	_bullets.clear()
	_shots.clear()
	_show_message("CLEAR!")
	await get_tree().create_timer(END_WAIT, false).timeout
	if not Inventory.has_item(ITEM_ID):
		Inventory.add_item(ITEM_ID)
		await GameUI.item_toast_finished
	ViewSwitcher.return_to_field()


func _on_failed() -> void:
	_state = State.FAILED
	_player.visible = false
	_player.set_physics_process(false)
	_show_message("GAME OVER")
	await get_tree().create_timer(END_WAIT, false).timeout
	ViewSwitcher.go_to(scene_file_path)


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true


func _update_hp_label() -> void:
	_hp_label.text = "HP " + "■".repeat(maxi(_hp, 0)) + "□".repeat(PLAYER_HP - maxi(_hp, 0))


func _boss_rect() -> Rect2:
	return Rect2(_boss_pos - BOSS_SIZE / 2.0, BOSS_SIZE)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(320, 180)), BG_COLOR)
	draw_rect(FIELD, FIELD_COLOR)
	for s in _stars:
		draw_rect(Rect2(s.x, s.y, 1, 1), STAR_COLOR)
	if _state != State.CLEAR:
		draw_rect(_boss_rect(), Color.WHITE if _boss_flash > 0.0 else BOSS_COLOR)
	for shot in _shots:
		draw_circle(shot, SHOT_RADIUS, RED)
	for b in _bullets:
		draw_circle(b.pos, BULLET_RADIUS, YELLOW if b.yellow else RED)
	# ボスの体力（右側の余白）
	var bar := Rect2(FIELD.end.x + 12, 20, 8, 120)
	draw_rect(bar, Color(0.15, 0.15, 0.18))
	var ratio := clampf(float(_boss_hp) / BOSS_HP, 0.0, 1.0)
	draw_rect(Rect2(bar.position.x, bar.end.y - bar.size.y * ratio, bar.size.x, bar.size.y * ratio), BAR_COLOR)
