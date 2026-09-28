extends Node2D

# ボス戦（シューティング）。ボスは画面の中央にいて、次の順で攻撃を繰り返す。
#   通常弾 → 大技（赤い魔法陣 → 全方向の円形。くぐれる隙間あり）→ 通常弾 → 一斉射撃（黄色い魔法陣 → 全方向の正方形。隙間なし）→ …
# 30秒たったら間隔を少し縮める。
# 赤い弾はよけるしかない。黄色い弾は、しゃがみ＋ダッシュ中（壁抜けと同じ条件）だけすり抜けられる（boss_bullet_clip）。
# 自機の攻撃（どちらもボスの方向へまっすぐ飛ぶ）：Space の通常弾（杖を持っているときだけ）、C のチャージ弾（ローブを持っているときだけ）。
# 盾を持っていると、1回だけダメージを受けない（リトライすると戻る）。
# ボスの HP が 0 になると GAME CLEAR（CLEAR_WAIT 秒後に暗転してエンディング scenes/credits.tscn へ）、自機の HP が 0 になると GAME OVER

const MAGIC_CIRCLE := preload("res://scripts/magic_circle.gd")
const TITLE_SCENE := "res://scenes/title.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"
const BGM := preload("res://assets/BGM/BOSS/Battle-Vampire_loop.ogg")

const ARENA := Rect2(12, 12, 456, 246)
const PLAYER_HP := 5
const BOSS_HP := 200
const BOSS_HITBOX := Vector2(40, 24)
const STAFF_ITEM := "beginning_staff"
const SHIELD_ITEM := "ancient_buckler"
const ROBE_ITEM := "mage_robe"

const START_DELAY := 1.0
const SPEED_UP_TIME := 30.0
const SPEED_UP_PACE := 0.8

# 通常弾
const NORMAL_TIME := 4.0
const NORMAL_VOLLEY := 0.8
const NORMAL_POINTS := 3
const NORMAL_POINT_DISTANCE := 48.0
const NORMAL_CIRCLE_RADIUS := 7.0
const NORMAL_CHARGE := 0.3
const NORMAL_SPEED := 100.0

# 大技（赤・全方向の円形）
const BIG_CIRCLE_RADIUS := 60.0
const BIG_CHARGE := 1.2
const RING_COUNT := 64
const RING_GAPS := 4
const RING_GAP_WIDTH := 3
const RING_SPEED := 105.0
const RING_START := 30.0
const SECOND_RING_DELAY := 0.35

# 一斉射撃（黄・全方向の正方形）
const YELLOW_CIRCLE_RADIUS := 60.0
const YELLOW_CHARGE := 1.2
const SQUARE_START := 40.0
const SQUARE_SPACING := 1.6
const YELLOW_SPEED := 90.0

const RECOVER_TIME := 1.0
const END_WAIT := 0.6
# GAME CLEAR を出してから、暗転してエンディングへ進むまで
const CLEAR_WAIT := 3.0

# 自機の攻撃。通常弾は赤い魔法弾と同じ画像、チャージ弾は charge_sheet.png の 5 コマ目（右向き。飛ぶ向きに回す）
const SHOT_SPEED := 300.0
const SHOT_DAMAGE := 1
const SHOT_HIT_RADIUS := 4.0
const CHARGE_SPEED := 220.0
const CHARGE_DAMAGE := 5
const CHARGE_HIT_RADIUS := 8.0
const CHARGE_SHEET := preload("res://assets/battle/bullet/charge/charge_sheet.png")
const CHARGE_FRAME_SIZE := 48.0
const CHARGE_FLY_FRAME := 5
# チャージ弾が当たったときの見た目（6・7 コマ目を順に）
const CHARGE_HIT_FRAMES := [6, 7]
const CHARGE_HIT_FRAME_TIME := 0.1
# 盾で防いだときに、自機の上に盾の絵を少し出す
const SHIELD_FLASH_TIME := 0.6
const SHIELD_FLASH_SIZE := 24.0

# 魔法弾の見た目：32x32 のコマが横に4枚並んだ画像を、半分の 16x16 で表示し、1秒に2周アニメーションさせる
const RED_BULLET_TEXTURE := preload("res://assets/battle/bullet/normal/shot_fire01_03.png")
const YELLOW_BULLET_TEXTURE := preload("res://assets/battle/bullet/through_wall/shot_light02_01.png")
const BULLET_FRAME_SIZE := 32.0
const BULLET_FRAME_COUNT := 4
const BULLET_DRAW_SIZE := 16.0
const BULLET_ANIM_FPS := 8.0
const BULLET_HIT_RADIUS := 4.0

enum Phase { WAIT, NORMAL, BIG_RED, YELLOW }
enum State { FIGHT, OVER, CLEAR }

const CYCLE := [Phase.NORMAL, Phase.BIG_RED, Phase.NORMAL, Phase.YELLOW]

@onready var _player = $Player  # boss_player.gd
@onready var _boss = $Boss  # boss_sprite.gd
@onready var _circles: Node2D = $CircleLayer
@onready var _bullet_layer: Node2D = $BulletLayer
@onready var _hp_label: Label = $Hud/HpLabel
@onready var _shield_icon: TextureRect = $Hud/ShieldIcon
@onready var _boss_hp_fill: ColorRect = $Hud/BossHp/Fill
@onready var _clear: Control = $GameOver/Clear
@onready var _game_over: Control = $GameOver/Root
@onready var _retry_button: Button = $GameOver/Root/Buttons/RetryButton
@onready var _title_button: Button = $GameOver/Root/Buttons/TitleButton

var _state := State.FIGHT
var _hp := PLAYER_HP
var _elapsed := 0.0
var _phase := Phase.WAIT
var _phase_left := START_DELAY
var _cycle_index := -1
var _volley_left := 0.0
var _bullets: Array[Dictionary] = []  # {pos, vel, yellow, frame}（frame はアニメーションの開始コマ）
var _boss_hp := BOSS_HP
var _shield := false
var _shield_flash := 0.0
var _shots: Array[Dictionary] = []  # 自機の弾 {pos, vel, charge, frame}
var _hit_effects: Array[Dictionary] = []  # チャージ弾が当たった場所 {pos, time}


func _ready() -> void:
	Bgm.play_music(BGM)
	_game_over.visible = false
	_clear.visible = false
	_player.can_shoot = Inventory.has_item(STAFF_ITEM)
	_player.can_charge = Inventory.has_item(ROBE_ITEM)
	_shield = Inventory.has_item(SHIELD_ITEM)
	_shield_icon.texture = Inventory.item_image(SHIELD_ITEM)
	_shield_icon.visible = _shield
	_player.shot_fired.connect(_on_shot_fired)
	_player.charge_fired.connect(_on_charge_fired)
	_retry_button.pressed.connect(ViewSwitcher.go_to.bind(scene_file_path))
	_title_button.pressed.connect(ViewSwitcher.go_to.bind(TITLE_SCENE))
	_bullet_layer.draw.connect(_draw_bullets)
	_update_hp_label()
	_update_boss_hp_bar()


func _physics_process(delta: float) -> void:
	if _state == State.FIGHT:
		_elapsed += delta
		_update_phase(delta)
		_move_bullets(delta)
		_move_shots(delta)
		_check_boss_hit()
		_check_player_hit()
	_update_effects(delta)
	_bullet_layer.queue_redraw()


# ---- 攻撃の順番 ----

func _pace() -> float:
	return SPEED_UP_PACE if _elapsed >= SPEED_UP_TIME else 1.0


func _update_phase(delta: float) -> void:
	_phase_left -= delta
	if _phase == Phase.NORMAL:
		_volley_left -= delta
		if _volley_left <= 0.0:
			_volley_left = NORMAL_VOLLEY * _pace()
			_normal_volley()
	if _phase_left <= 0.0:
		_next_phase()


func _next_phase() -> void:
	_cycle_index = (_cycle_index + 1) % CYCLE.size()
	_phase = CYCLE[_cycle_index]
	match _phase:
		Phase.NORMAL:
			_phase_left = NORMAL_TIME * _pace()
			_volley_left = 0.0
		Phase.BIG_RED:
			_phase_left = BIG_CHARGE + SECOND_RING_DELAY + RECOVER_TIME * _pace()
			_spawn_circle(MAGIC_CIRCLE.Kind.BIG_RED, _boss.position, BIG_CIRCLE_RADIUS, BIG_CHARGE, _fire_big_red)
		Phase.YELLOW:
			_phase_left = YELLOW_CHARGE + RECOVER_TIME * _pace()
			_spawn_circle(MAGIC_CIRCLE.Kind.YELLOW, _boss.position, YELLOW_CIRCLE_RADIUS, YELLOW_CHARGE, _fire_yellow_square)


func _spawn_circle(kind: int, pos: Vector2, radius: float, charge: float, on_fired: Callable) -> void:
	var circle = MAGIC_CIRCLE.new()
	circle.setup(kind, radius, charge)
	circle.position = pos
	circle.fired.connect(func() -> void:
		if _state == State.FIGHT:
			on_fired.call())
	_circles.add_child(circle)


# 通常弾：ボスの周りの数か所に小さな赤い魔法陣を出し、そこから自機を狙って撃つ
func _normal_volley() -> void:
	var base := randf() * TAU
	for i in NORMAL_POINTS:
		var point: Vector2 = _boss.position + Vector2.from_angle(base + i * TAU / NORMAL_POINTS) * NORMAL_POINT_DISTANCE
		_spawn_circle(MAGIC_CIRCLE.Kind.SMALL_RED, point, NORMAL_CIRCLE_RADIUS, NORMAL_CHARGE, _fire_aimed.bind(point))


func _fire_aimed(from: Vector2) -> void:
	var dir: Vector2 = (_player.global_position - from).normalized()
	_add_bullet(from, dir * NORMAL_SPEED, false)


# 大技：赤い弾の円を2重に撃つ。どちらの円にも、くぐれる隙間がある（2つ目は隙間の位置が変わる）
func _fire_big_red() -> void:
	_fire_ring(randf() * TAU)
	get_tree().create_timer(SECOND_RING_DELAY, false).timeout.connect(func() -> void:
		if _state == State.FIGHT:
			_fire_ring(randf() * TAU))


func _fire_ring(offset: float) -> void:
	var skip := {}
	var section := RING_COUNT / RING_GAPS
	for g in RING_GAPS:
		var start := g * section + randi_range(0, section - RING_GAP_WIDTH)
		for k in RING_GAP_WIDTH:
			skip[start + k] = true
	for i in RING_COUNT:
		if skip.has(i):
			continue
		var dir := Vector2.from_angle(offset + i * TAU / RING_COUNT)
		_add_bullet(_boss.position + dir * RING_START, dir * RING_SPEED, false)


# 一斉射撃：黄色い弾を正方形に隙間なく並べ、正方形のまま広げる
func _fire_yellow_square() -> void:
	var count := int(SQUARE_START * 2.0 / SQUARE_SPACING)
	for side in 4:
		var normal := Vector2.from_angle(side * PI / 2.0)
		var along := normal.orthogonal()
		for i in count:
			var t := -SQUARE_START + i * SQUARE_SPACING
			var offset := normal * SQUARE_START + along * t
			_add_bullet(_boss.position + offset, offset / SQUARE_START * YELLOW_SPEED, true)


func _add_bullet(pos: Vector2, vel: Vector2, yellow: bool) -> void:
	# 全部の弾が同じ動きにならないよう、開始のコマをずらす
	_bullets.append({"pos": pos, "vel": vel, "yellow": yellow, "frame": randi() % BULLET_FRAME_COUNT})


# ---- 弾の移動と当たり判定 ----

func _move_bullets(delta: float) -> void:
	var bounds := ARENA.grow(8.0)
	var alive: Array[Dictionary] = []
	for b in _bullets:
		b.pos += b.vel * delta
		if bounds.has_point(b.pos):
			alive.append(b)
	_bullets = alive


func _check_player_hit() -> void:
	var box: Rect2 = _player.hitbox()
	for b in _bullets:
		if not _circle_hits_rect(b.pos, BULLET_HIT_RADIUS, box):
			continue
		if b.yellow and _player.is_clipping():
			# FAKE_BUG: boss_bullet_clip
			BugRegistry.trigger("boss_bullet_clip")
			continue
		if _player.is_invincible():
			return
		_bullets.erase(b)
		_on_player_hit()
		return
	# ボスの体に触れてもダメージ
	if not _player.is_invincible() and Rect2(_boss.position - BOSS_HITBOX / 2.0, BOSS_HITBOX).intersects(box):
		_on_player_hit()


func _circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := center.clamp(rect.position, rect.end)
	return center.distance_squared_to(closest) < radius * radius


func _on_player_hit() -> void:
	# 盾を持っていれば、1回だけダメージを受けない（無敵時間は普通に当たったときと同じ）
	if _shield:
		_shield = false
		_shield_icon.visible = false
		_shield_flash = SHIELD_FLASH_TIME
		_player.start_invincible()
		return
	_hp -= 1
	_update_hp_label()
	if _hp <= 0:
		_on_game_over()
	else:
		_player.start_invincible()


func _update_hp_label() -> void:
	var hp := maxi(_hp, 0)
	_hp_label.text = "HP " + "■".repeat(hp) + "□".repeat(PLAYER_HP - hp)


# ---- 自機の攻撃 ----

func _on_shot_fired(from: Vector2) -> void:
	if _state != State.FIGHT:
		return
	var dir: Vector2 = (_boss.position - from).normalized()
	_shots.append({"pos": from, "vel": dir * SHOT_SPEED, "charge": false, "frame": randi() % BULLET_FRAME_COUNT})


func _on_charge_fired(from: Vector2) -> void:
	if _state != State.FIGHT:
		return
	var dir: Vector2 = (_boss.position - from).normalized()
	_shots.append({"pos": from, "vel": dir * CHARGE_SPEED, "charge": true, "frame": 0})


func _move_shots(delta: float) -> void:
	var bounds := ARENA.grow(8.0)
	var alive: Array[Dictionary] = []
	for s in _shots:
		s.pos += s.vel * delta
		if bounds.has_point(s.pos):
			alive.append(s)
	_shots = alive


func _check_boss_hit() -> void:
	var box := Rect2(_boss.position - BOSS_HITBOX / 2.0, BOSS_HITBOX)
	var alive: Array[Dictionary] = []
	var damage := 0
	for s in _shots:
		var radius := CHARGE_HIT_RADIUS if s.charge else SHOT_HIT_RADIUS
		if not _circle_hits_rect(s.pos, radius, box):
			alive.append(s)
			continue
		damage += CHARGE_DAMAGE if s.charge else SHOT_DAMAGE
		if s.charge:
			_hit_effects.append({"pos": s.pos, "time": 0.0})
	_shots = alive
	if damage > 0:
		_damage_boss(damage)


func _damage_boss(damage: int) -> void:
	_boss_hp = maxi(_boss_hp - damage, 0)
	_update_boss_hp_bar()
	_boss.play_damage()
	if _boss_hp <= 0:
		_on_game_clear()


func _update_boss_hp_bar() -> void:
	_boss_hp_fill.scale.x = float(_boss_hp) / BOSS_HP


func _update_effects(delta: float) -> void:
	_shield_flash = maxf(_shield_flash - delta, 0.0)
	var end := CHARGE_HIT_FRAMES.size() * CHARGE_HIT_FRAME_TIME
	var alive: Array[Dictionary] = []
	for e in _hit_effects:
		e.time += delta
		if e.time < end:
			alive.append(e)
	_hit_effects = alive


func _on_game_clear() -> void:
	_state = State.CLEAR
	_bullets.clear()
	_shots.clear()
	_player.set_physics_process(false)
	create_tween().tween_property(_boss, "modulate:a", 0.0, END_WAIT)
	await get_tree().create_timer(END_WAIT, false).timeout
	_clear.visible = true
	await get_tree().create_timer(CLEAR_WAIT, false).timeout
	ViewSwitcher.go_to(CREDITS_SCENE)


func _on_game_over() -> void:
	_state = State.OVER
	_player.set_physics_process(false)
	await get_tree().create_timer(END_WAIT, false).timeout
	_game_over.visible = true
	_retry_button.grab_focus()


# ---- 魔法弾の見た目 ----
# 1発につき画像を1回貼るだけにしている。同じ画像が続くとまとめて描かれて軽いので、赤→黄色の順に分けて描く

# 自機の通常弾も赤い魔法弾と同じ画像なので、続けて描く。チャージ弾（数が少ない）はそのあとに1発ずつ回して描く
func _draw_bullets() -> void:
	var step := int(_elapsed * BULLET_ANIM_FPS)
	var size := Vector2(BULLET_DRAW_SIZE, BULLET_DRAW_SIZE)
	for s in _shots:
		if not s.charge:
			_draw_bullet_frame(RED_BULLET_TEXTURE, s.pos, (step + s.frame) % BULLET_FRAME_COUNT, size)
	for yellow in [false, true]:
		var texture: Texture2D = YELLOW_BULLET_TEXTURE if yellow else RED_BULLET_TEXTURE
		for b in _bullets:
			if b.yellow != yellow:
				continue
			_draw_bullet_frame(texture, b.pos, (step + b.frame) % BULLET_FRAME_COUNT, size)
	_draw_charge_shots()
	if _shield_flash > 0.0:
		var shield_size := Vector2(SHIELD_FLASH_SIZE, SHIELD_FLASH_SIZE)
		var alpha := _shield_flash / SHIELD_FLASH_TIME
		_bullet_layer.draw_texture_rect(Inventory.item_image(SHIELD_ITEM), Rect2(_player.global_position - shield_size / 2.0, shield_size), false, Color(1, 1, 1, alpha))


func _draw_bullet_frame(texture: Texture2D, pos: Vector2, frame: int, size: Vector2) -> void:
	var region := Rect2(frame * BULLET_FRAME_SIZE, 0.0, BULLET_FRAME_SIZE, BULLET_FRAME_SIZE)
	_bullet_layer.draw_texture_rect_region(texture, Rect2(pos - size / 2.0, size), region)


func _draw_charge_shots() -> void:
	var size := Vector2(CHARGE_FRAME_SIZE, CHARGE_FRAME_SIZE)
	for s in _shots:
		if not s.charge:
			continue
		_bullet_layer.draw_set_transform(s.pos, s.vel.angle())
		_draw_charge_frame(CHARGE_FLY_FRAME, Vector2.ZERO, size)
	_bullet_layer.draw_set_transform(Vector2.ZERO)
	for e in _hit_effects:
		var index := mini(int(e.time / CHARGE_HIT_FRAME_TIME), CHARGE_HIT_FRAMES.size() - 1)
		_draw_charge_frame(CHARGE_HIT_FRAMES[index], e.pos, size)


func _draw_charge_frame(frame: int, pos: Vector2, size: Vector2) -> void:
	var region := Rect2(frame * CHARGE_FRAME_SIZE, 0.0, CHARGE_FRAME_SIZE, CHARGE_FRAME_SIZE)
	_bullet_layer.draw_texture_rect_region(CHARGE_SHEET, Rect2(pos - size / 2.0, size), region)
