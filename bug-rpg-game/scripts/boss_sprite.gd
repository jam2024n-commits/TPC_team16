extends AnimatedSprite2D

# ボスの見た目。ノーマル4枚を1秒で1周ループする（default）。
# 被ダメージ時は「ノーマル1→赤1→ノーマル2→赤2…」と交互にする（damage）。自機の攻撃ができるまで damage は使わない

const DIR := "res://assets/characters/boss/"
const FRAME_COUNT := 4
const LOOP_TIME := 1.0


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("damage")
	for i in range(1, FRAME_COUNT + 1):
		var normal: Texture2D = load(DIR + "bat_frame%d_64x64.png" % i)
		var red: Texture2D = load(DIR + "bat_damage_frame%d_64x64.png" % i)
		frames.add_frame("default", normal)
		frames.add_frame("damage", normal)
		frames.add_frame("damage", red)
	frames.set_animation_speed("default", FRAME_COUNT / LOOP_TIME)
	frames.set_animation_speed("damage", FRAME_COUNT * 2 / LOOP_TIME)
	frames.set_animation_loop("damage", false)
	sprite_frames = frames
	animation_finished.connect(play.bind("default"))
	play("default")


func play_damage() -> void:
	play("damage")
