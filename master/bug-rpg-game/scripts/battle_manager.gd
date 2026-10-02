extends CanvasLayer

signal battle_ended(result: String)

const BATTLE_SCENE := preload("res://scenes/battle.tscn")
const FADE_TIME := 0.4

@onready var _fade: ColorRect = $Fade

var active := false


func start(enemy: Node) -> void:
	if active:
		return
	active = true
	var stage := get_tree().current_scene
	stage.process_mode = Node.PROCESS_MODE_DISABLED

	await _fade_to(1.0)
	var battle := BATTLE_SCENE.instantiate()
	add_child(battle)
	battle.setup(enemy.data)
	await _fade_to(0.0)

	var result: String = await battle.finished

	await _fade_to(1.0)
	battle.queue_free()
	match result:
		"win":
			enemy.defeat()
			stage.process_mode = Node.PROCESS_MODE_INHERIT
		"escape":
			enemy.disarm()
			stage.process_mode = Node.PROCESS_MODE_INHERIT
		"lose":
			PlayerStats.reset()
			get_tree().reload_current_scene()
	await _fade_to(0.0)

	active = false
	battle_ended.emit(result)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
