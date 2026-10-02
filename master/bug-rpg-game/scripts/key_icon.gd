class_name KeyIcon
extends PixelIcon


func _init() -> void:
	pattern = [
		"...KKKKK....",
		"..KYYYYYK...",
		"..KYK.KYK...",
		"..KYYYYYK...",
		"...KKYKK....",
		"....KYK.....",
		"....KYKKK...",
		"....KYYYK...",
		"....KYKKK...",
		"....KYYK....",
		"....KKKK....",
	]
	colors = {
		"Y": Color(0.95, 0.78, 0.2),
		"K": Color(0.25, 0.15, 0.05),
	}
