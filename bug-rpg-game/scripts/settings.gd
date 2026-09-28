extends Node

# 設定（Autoload: Settings）。今は音量とミュートだけ。
# 全体の音量（Master バス）に反映し、SETTINGS_PATH に記録して次に起動したときも使う

signal changed

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "sound"
const DEFAULT_VOLUME := 1.0

var volume := DEFAULT_VOLUME  # 0〜1
var muted := false


func _ready() -> void:
	_load()
	_apply()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply()
	_save()


func set_muted(value: bool) -> void:
	muted = value
	_apply()
	_save()


# 全データリセット（タイトルの設定）：最初の値に戻し、記録も消す
func reset() -> void:
	volume = DEFAULT_VOLUME
	muted = false
	_apply()
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
	AudioServer.set_bus_mute(bus, muted or volume <= 0.0)
	changed.emit()


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "volume", volume)
	file.set_value(SECTION, "muted", muted)
	file.save(SETTINGS_PATH)


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	volume = clampf(float(file.get_value(SECTION, "volume", DEFAULT_VOLUME)), 0.0, 1.0)
	muted = bool(file.get_value(SECTION, "muted", false))
