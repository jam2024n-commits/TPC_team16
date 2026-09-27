extends Node

var _defeated: Dictionary = {}


func mark_defeated(key: String) -> void:
	_defeated[key] = true


func is_defeated(key: String) -> bool:
	return _defeated.has(key)
