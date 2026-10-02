extends Node

# 進み具合の記録（Autoload: Progress）。「試練の間に初めて入った」「初めてボスに挑んだ」などの印を持つ。
# アイテムと同じファイル（Inventory.SAVE_PATH）の別の区画に記録し、次に起動したときも残る。全データリセットで消える

const SECTION := "progress"
# 試練の間に入るときの語りを見た（2回目からは短い語りになる）
const TRIAL_INTRO_SEEN := "trial_intro_seen"
# 初めてボスに挑むときの語りを見た
const BOSS_INTRO_SEEN := "boss_intro_seen"

var _flags: Dictionary = {}


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(Inventory.SAVE_PATH) != OK or not file.has_section(SECTION):
		return
	for key in file.get_section_keys(SECTION):
		if file.get_value(SECTION, key, false):
			_flags[key] = true


func has(flag: String) -> bool:
	return _flags.has(flag)


func mark(flag: String) -> void:
	if flag == "" or _flags.has(flag):
		return
	_flags[flag] = true
	# ほかの区画（アイテム）を消さないよう、読み込んでから書き足す
	var file := ConfigFile.new()
	file.load(Inventory.SAVE_PATH)
	file.set_value(SECTION, flag, true)
	file.save(Inventory.SAVE_PATH)


# 全データリセット：記録はファイルごと Inventory.reset が消すので、ここでは覚えている印を消すだけ
func reset() -> void:
	_flags = {}
