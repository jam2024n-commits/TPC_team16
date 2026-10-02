class_name OrbIcon
extends PixelIcon


func _init() -> void:
	pattern = [
		"....KKKK....",
		"..KKYYYYKK..",
		".KYYWWYYYYK.",
		".KYWWYYYYYK.",
		"KYYWYYYYYYOK",
		"KYYYYYYYYYOK",
		"KYYYYYYYYOOK",
		".KYYYYYYOOK.",
		".KYYYYOOOOK.",
		"..KKOOOOKK..",
		"....KKKK....",
	]
	colors = {
		"Y": Color(1.0, 0.88, 0.3),
		"O": Color(0.85, 0.6, 0.15),
		"W": Color(1.0, 1.0, 0.85),
		"K": Color(0.35, 0.25, 0.05),
	}
