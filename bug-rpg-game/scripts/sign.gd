extends Node2D

@export_multiline var text := ""

@onready var _area: Area2D = $InteractArea


func _ready() -> void:
	_area.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	TextPrompt.show_message("SIGN", text)
