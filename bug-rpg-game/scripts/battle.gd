extends CanvasLayer

signal finished(result: String)

@onready var _enemy_sprite: ColorRect = $Root/EnemySprite
@onready var _enemy_name: Label = $Root/EnemyName
@onready var _enemy_hp_label: Label = $Root/EnemyHp
@onready var _player_hp_label: Label = $Root/PlayerHp
@onready var _log: Label = $Root/Log
@onready var _attack_button: Button = $Root/Menu/AttackButton
@onready var _guard_button: Button = $Root/Menu/GuardButton
@onready var _run_button: Button = $Root/Menu/RunButton

var _enemy: EnemyData
var _enemy_hp := 0
var _busy := false
var _guarding := false


func _ready() -> void:
	_attack_button.pressed.connect(_on_attack)
	_guard_button.pressed.connect(_on_guard)
	_run_button.pressed.connect(_on_run)


func setup(data: EnemyData) -> void:
	_enemy = data
	_enemy_hp = data.max_hp
	_enemy_name.text = data.display_name
	_enemy_sprite.color = data.color
	_log.text = "%sが現れた！" % data.display_name
	_refresh()
	_attack_button.grab_focus()


func _refresh() -> void:
	_enemy_hp_label.text = "HP %d/%d" % [_enemy_hp, _enemy.max_hp]
	_player_hp_label.text = "HP %d/%d" % [PlayerStats.hp, PlayerStats.max_hp]


func _say(text: String, wait := 0.8) -> void:
	_log.text = text
	await get_tree().create_timer(wait).timeout


func _on_attack() -> void:
	if _busy:
		return
	_busy = true
	_guarding = false
	var damage := maxi(1, PlayerStats.attack - _enemy.defense)
	_enemy_hp = maxi(_enemy_hp - damage, 0)
	_refresh()
	await _say("あなたの攻撃！ %dのダメージ" % damage)
	if _enemy_hp == 0:
		await _say("%sをたおした！" % _enemy.display_name)
		finished.emit("win")
		return
	await _enemy_turn()


func _on_guard() -> void:
	if _busy:
		return
	_busy = true
	_guarding = true
	await _say("身を守っている")
	await _enemy_turn()


func _on_run() -> void:
	if _busy:
		return
	_busy = true
	await _say("うまくにげきれた！")
	finished.emit("escape")


func _enemy_turn() -> void:
	var damage := maxi(1, _enemy.attack - PlayerStats.defense)
	if _guarding:
		damage = maxi(1, int(damage * 0.5))
	PlayerStats.take_damage(damage)
	_refresh()
	await _say("%sの攻撃！ %dのダメージ" % [_enemy.display_name, damage])
	_guarding = false
	if PlayerStats.is_dead():
		await _say("やられてしまった…")
		finished.emit("lose")
		return
	_busy = false
	_attack_button.grab_focus()
