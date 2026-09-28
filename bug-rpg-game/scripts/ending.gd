extends Control

# 第三層をクリアしたあとの仮のエンディング。「タイトルに戻る」だけがある

const TITLE_SCENE := "res://scenes/title.tscn"

@onready var _title_button: Button = $TitleButton


func _ready() -> void:
	_title_button.pressed.connect(ViewSwitcher.go_to.bind(TITLE_SCENE))
	_title_button.grab_focus()
