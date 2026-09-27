extends CanvasLayer

const FADE_TIME := 0.4

@onready var _fade: ColorRect = $Fade

var _return_scene_path := ""
var _return_position := Vector2.ZERO
var _busy := false


func enter(scene_path: String, return_position: Vector2) -> void:
	if _busy:
		return
	_return_scene_path = get_tree().current_scene.scene_file_path
	_return_position = return_position
	await _switch(scene_path)


func return_to_field() -> void:
	await _switch(_return_scene_path, _return_position)


func go_to(scene_path: String) -> void:
	await _switch(scene_path)


func _switch(scene_path: String, player_position: Variant = null) -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	var old_scene := get_tree().current_scene
	get_tree().change_scene_to_file(scene_path)
	var scene := await _wait_for_scene(old_scene)
	await get_tree().process_frame
	if player_position != null and scene:
		var player: Node = scene.get_node_or_null("Player")
		if player:
			player.global_position = player_position
	await _fade_to(0.0)
	_busy = false


func _wait_for_scene(old_scene: Node) -> Node:
	for i in 30:
		await get_tree().process_frame
		var scene := get_tree().current_scene
		if scene != null and scene != old_scene:
			return scene
	return null


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
