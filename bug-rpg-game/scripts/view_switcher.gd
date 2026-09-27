extends CanvasLayer

const MAZE_SCENE_PATH := "res://scenes/maze_backrooms.tscn"
const FADE_TIME := 0.4

@onready var _fade: ColorRect = $Fade

var _return_scene_path := ""
var _return_position := Vector2.ZERO
var _busy := false


func enter_maze(return_position: Vector2) -> void:
	if _busy:
		return
	_busy = true
	_return_scene_path = get_tree().current_scene.scene_file_path
	_return_position = return_position
	await _fade_to(1.0)
	get_tree().change_scene_to_file(MAZE_SCENE_PATH)
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


func return_to_field() -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	get_tree().change_scene_to_file(_return_scene_path)
	var stage := await _wait_for_scene()
	await get_tree().process_frame
	var player: Node = stage.get_node_or_null("Player") if stage else null
	if player:
		player.global_position = _return_position
	await _fade_to(0.0)
	_busy = false


func _wait_for_scene() -> Node:
	for i in 30:
		await get_tree().process_frame
		if get_tree().current_scene != null:
			return get_tree().current_scene
	return null


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
