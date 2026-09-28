extends Node

# 持っているアイテム（Autoload: Inventory）。
# 試練の間のアイテムは SAVE_PATH に記録し、次に起動したときも持っている（タイトルの「アイテム一覧」、ボス戦の効果に使う）

signal item_added(id: String)

const DISPLAY_NAMES := {
	"castle_door_key": "カギ",
	"beginning_staff": "はじまりのつえ",
	"mage_robe": "魔導士のローブ",
	"ancient_buckler": "風神の盾",
}
# 試練の間のアイテムは『「〇〇」を獲得した！』と出す。アイテム一覧もこの順に並べる
const TRIAL_ITEMS := ["beginning_staff", "ancient_buckler", "mage_robe"]
# 絵があるアイテム（48x48）。絵がないものは黄色い球のアイコンで表す
const ITEM_IMAGES := {
	"beginning_staff": preload("res://assets/stick/staff.png"),
	"ancient_buckler": preload("res://assets/shield/buckler.png"),
	"mage_robe": preload("res://assets/mant/mantle.png"),
}

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "items"

var _items: Dictionary = {}


func _ready() -> void:
	_load()


func add_item(id: String) -> void:
	if _items.has(id):
		return
	_items[id] = true
	if id in TRIAL_ITEMS:
		_save()
	item_added.emit(id)


# 全データリセット（タイトルの設定）：持っているアイテムを全部なくし、記録も消す
func reset() -> void:
	_items = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func has_item(id: String) -> bool:
	return _items.has(id)


func display_name(id: String) -> String:
	return DISPLAY_NAMES.get(id, id)


func item_image(id: String) -> Texture2D:
	return ITEM_IMAGES.get(id)


func acquire_message(id: String) -> String:
	if id in TRIAL_ITEMS:
		return "「%s」を獲得した！" % display_name(id)
	return "%sを手に入れた！" % display_name(id)


# 試練の間のアイテムだけを記録する（方針変更前のカギなどは記録しない）。
# 同じファイルに Progress の区画もあるので、読み込んでから書き換える
func _save() -> void:
	var file := ConfigFile.new()
	file.load(SAVE_PATH)
	for id in TRIAL_ITEMS:
		file.set_value(SAVE_SECTION, id, _items.has(id))
	file.save(SAVE_PATH)


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	for id in TRIAL_ITEMS:
		if file.get_value(SAVE_SECTION, id, false):
			_items[id] = true
