extends Control

# ボスを倒したあとのエンディング。暗転した画面で
#   1. 「世界は平和を取り戻した。」だけをフェードインし、しばらく表示してフェードアウト
#   2. クレジット（タイトル「試練の間」と、制作・BGM・素材のお礼）をフェードインし、しばらく表示してフェードアウト
# のあと、何も押さなくてもアプリを終了する。BGM はタイトルと同じ曲

const BGM := preload("res://assets/BGM/title/Epilogue_loop.ogg")
const FADE_TIME := 1.5
const PEACE_HOLD := 3.0
const CREDITS_HOLD := 7.0
const GAP := 0.8

@onready var _peace: Control = $Peace
@onready var _credits: Control = $Credits


func _ready() -> void:
	Bgm.play_music(BGM)
	_peace.modulate.a = 0.0
	_credits.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(GAP)
	_show(tween, _peace, PEACE_HOLD)
	tween.tween_interval(GAP)
	_show(tween, _credits, CREDITS_HOLD)
	tween.tween_interval(GAP)
	tween.tween_callback(get_tree().quit)


func _show(tween: Tween, target: Control, hold: float) -> void:
	tween.tween_property(target, "modulate:a", 1.0, FADE_TIME)
	tween.tween_interval(hold)
	tween.tween_property(target, "modulate:a", 0.0, FADE_TIME)
