class_name BossIcon
extends PixelIcon


func _init() -> void:
	pattern = [
		"K..........K",
		"KK..KKKK..KK",
		".KKPPPPPPKK.",
		".PPPPPPPPPP.",
		"PPRRPPPPRRPP",
		"PPRRPPPPRRPP",
		"PPPPPPPPPPPP",
		".PPWKWKWKPP.",
		".PPKWKWKWPP.",
		"..PPPPPPPP..",
		"...PPPPPP...",
	]
	colors = {
		"K": Color(0.2, 0.15, 0.2),
		"P": Color(0.5, 0.25, 0.6),
		"R": Color(1.0, 0.2, 0.2),
		"W": Color(0.95, 0.95, 0.9),
	}
