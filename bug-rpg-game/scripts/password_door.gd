extends Node2D

signal opened
signal bug_word_entered

@export var password := "OPEN"
@export var bug_word := "DEBUG"

@onready var _wall: Node2D = $Wall
@onready var _area: Area2D = $InteractArea


func _ready() -> void:
	_area.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	TextPrompt.open("DOOR", "パスワードを入力してください", _on_submitted)


func _on_submitted(text: String) -> void:
	var word := text.strip_edges().to_upper()
	if word == password.to_upper():
		TextPrompt.close()
		_wall.queue_free()
		_area.queue_free()
		opened.emit()
	elif word == bug_word.to_upper():
		TextPrompt.close()
		# FAKE_BUG: password_debug
		BugRegistry.trigger("password_debug")
		bug_word_entered.emit()
	else:
		TextPrompt.append("パスワードが違います")
