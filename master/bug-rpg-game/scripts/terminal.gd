extends Node2D

const INTRO := "help と入力するとコマンド一覧を表示"

var break_handler := Callable()

@onready var _area: Area2D = $InteractArea


func _ready() -> void:
	_area.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	TextPrompt.open("TERMINAL", INTRO, _on_command)


func _on_command(text: String) -> void:
	var command := text.strip_edges().replace(" ", "")
	match command:
		"help":
			TextPrompt.append("commands: help, break;")
		"break":
			TextPrompt.append("error: expected ';' after 'break'")
		"break;":
			if break_handler.is_valid():
				TextPrompt.close()
				break_handler.call()
			else:
				TextPrompt.append("error: 'break' outside loop")
		_:
			TextPrompt.append("unknown command: " + text)
