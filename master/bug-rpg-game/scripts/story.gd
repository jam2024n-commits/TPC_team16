extends Control

# 暗転した画面に文章を出す（試練の間に入るときの語り、初めてボスに挑むときの語り）。
# 文章をフェードインし、HOLD 秒表示してフェードアウトしたら next_scene へ進む。
# progress_flag を設定すると、表示したときに Progress に記録する（次からは出さない、などに使う）

@export_multiline var text := ""
@export var hold := 3.0
@export_file("*.tscn") var next_scene := ""
@export var progress_flag := ""

const FADE_IN := 1.0
const FADE_OUT := 1.0

@onready var _label: Label = $Text


func _ready() -> void:
	Progress.mark(progress_flag)
	_label.text = text
	_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, FADE_IN)
	tween.tween_interval(hold)
	tween.tween_property(_label, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(ViewSwitcher.go_to.bind(next_scene))
