extends Node2D

@onready var _goal: Area2D = $Goal
@onready var _goal_label: Label = $GoalLabel


func _ready() -> void:
	_goal_label.visible = false
	_goal.reached.connect(_on_goal_reached)


func _on_goal_reached() -> void:
	_goal_label.visible = true
	var route := "bug" if BugRegistry.is_triggered("wall_clip") else "normal"
	print("stage_tutorial: goal reached (route: %s)" % route)
