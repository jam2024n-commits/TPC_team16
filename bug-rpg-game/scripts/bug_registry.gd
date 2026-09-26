extends Node

signal bug_triggered(id: String)

const LIST_PATH := "res://data/fake_bugs.json"

signal bug_discovered(id: String)

var _bugs: Dictionary = {}
var _triggered: Dictionary = {}
var _discovered: Dictionary = {}


func _ready() -> void:
	_load_list()


func exists(id: String) -> bool:
	return _bugs.has(id)


func get_info(id: String) -> Dictionary:
	return _bugs.get(id, {})


func requires_of(id: String) -> Array:
	return get_info(id).get("requires", [])


func is_triggered(id: String) -> bool:
	return _triggered.has(id)


func trigger(id: String) -> void:
	if not exists(id):
		push_error("BugRegistry: 一覧にない偽バグIDです: %s" % id)
		return
	if is_triggered(id):
		return
	_triggered[id] = true
	bug_triggered.emit(id)
	if get_info(id).get("discovery", "normal") == "normal":
		_discovered[id] = true
		bug_discovered.emit(id)


func is_discovered(id: String) -> bool:
	return _discovered.has(id)


func discovered_count() -> int:
	return _discovered.size()


func _load_list() -> void:
	var text := FileAccess.get_file_as_string(LIST_PATH)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("bugs"):
		push_error("BugRegistry: %s を読み込めません" % LIST_PATH)
		return
	for bug: Dictionary in data["bugs"]:
		_bugs[bug["id"]] = bug
