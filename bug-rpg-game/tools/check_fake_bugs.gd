extends SceneTree

# 実行: godot --headless --path . --script res://tools/check_fake_bugs.gd

const LIST_PATH := "res://data/fake_bugs.json"
const REQUIRED_FIELDS := ["id", "title", "files", "trigger", "effect", "requires", "route", "stage", "hint", "discovery", "note"]
const TAG_PREFIX := "# FAKE_BUG: "

var _problems: Array[String] = []


func _initialize() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LIST_PATH))
	if typeof(data) != TYPE_DICTIONARY or not data.has("bugs"):
		print("NG: %s を読み込めません" % LIST_PATH)
		quit(1)
		return

	var ids: Dictionary = {}
	for bug: Dictionary in data["bugs"]:
		for field in REQUIRED_FIELDS:
			if not bug.has(field):
				_problems.append("項目不足: %s に %s がない" % [bug.get("id", "?"), field])
		if bug.has("id"):
			if ids.has(bug["id"]):
				_problems.append("ID重複: %s" % bug["id"])
			ids[bug["id"]] = true

	var tagged: Dictionary = {}
	for path in _find_scripts("res://"):
		var line_no := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			line_no += 1
			var at := line.find(TAG_PREFIX)
			if at == -1:
				continue
			var tag_id := line.substr(at + TAG_PREFIX.length()).strip_edges()
			if not tagged.has(tag_id):
				tagged[tag_id] = []
			tagged[tag_id].append(path)
			if not ids.has(tag_id):
				_problems.append("一覧にないタグ: %s (%s:%d)" % [tag_id, path, line_no])

	for bug: Dictionary in data["bugs"]:
		var id: String = bug.get("id", "")
		for req: String in bug.get("requires", []):
			if not ids.has(req):
				_problems.append("requires が一覧にない: %s -> %s" % [id, req])
		for file: String in bug.get("files", []):
			var res_path := "res://" + file
			if not FileAccess.file_exists(res_path):
				_problems.append("files のファイルがない: %s -> %s" % [id, file])
			elif not (tagged.get(id, []) as Array).has(res_path):
				_problems.append("files にタグがない: %s -> %s" % [id, file])

	if _problems.is_empty():
		print("OK: %d 件の偽バグ、問題なし" % ids.size())
		quit(0)
	else:
		for p in _problems:
			print("NG: ", p)
		print("計 %d 件の問題" % _problems.size())
		quit(1)


func _find_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for sub in DirAccess.get_directories_at(dir_path):
		if sub.begins_with(".") or sub == "tools":
			continue
		found.append_array(_find_scripts(dir_path.path_join(sub)))
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".gd"):
			found.append(dir_path.path_join(f))
	return found
