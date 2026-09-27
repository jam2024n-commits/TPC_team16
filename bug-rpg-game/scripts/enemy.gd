extends Node2D

@export var data: EnemyData

@onready var _body: ColorRect = $Body

var _armed := true


func _process(_delta: float) -> void:
	var fully_visible := _is_fully_visible()
	if not _armed:
		if not fully_visible:
			_armed = true
		return
	if fully_visible:
		BattleManager.start(self)


func disarm() -> void:
	_armed = false


func _is_fully_visible() -> bool:
	var viewport := get_viewport()
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var rect := Rect2(global_position + _body.position, _body.size)
	return view.encloses(rect)
