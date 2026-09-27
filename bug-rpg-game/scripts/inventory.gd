extends Node

signal item_added(id: String)

const DISPLAY_NAMES := {
	"castle_door_key": "魔王城の扉のカギ（仮）",
}

var _items: Dictionary = {}


func add_item(id: String) -> void:
	if _items.has(id):
		return
	_items[id] = true
	item_added.emit(id)


func has_item(id: String) -> bool:
	return _items.has(id)


func display_name(id: String) -> String:
	return DISPLAY_NAMES.get(id, id)
