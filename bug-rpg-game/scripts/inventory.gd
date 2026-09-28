extends Node

signal item_added(id: String)

const DISPLAY_NAMES := {
	"castle_door_key": "カギ",
	"beginning_staff": "はじまりのつえ",
	"mage_robe": "魔導士のローブ",
}
# 試練の間のアイテムは『「〇〇」を獲得した！』と出す
const TRIAL_ITEMS := ["beginning_staff", "mage_robe"]

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


func acquire_message(id: String) -> String:
	if id in TRIAL_ITEMS:
		return "「%s」を獲得した！" % display_name(id)
	return "%sを手に入れた！" % display_name(id)
