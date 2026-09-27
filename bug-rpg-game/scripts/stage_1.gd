extends Node2D

const LOOP_SCENE := "res://scenes/stage_loop.tscn"
const SHORTCUT_POSITION := Vector2(720, 164)

@onready var _door: Node2D = $Door
@onready var _goal: Area2D = $Goal
@onready var _goal_label: Label = $GoalLabel


func _ready() -> void:
	_goal_label.visible = false
	_goal.reached.connect(func() -> void: _goal_label.visible = true)
	_door.bug_word_entered.connect(_on_bug_word_entered)


func _on_bug_word_entered() -> void:
	ViewSwitcher.enter(LOOP_SCENE, SHORTCUT_POSITION)
