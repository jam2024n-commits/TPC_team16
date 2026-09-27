extends Node2D

const MAZE_SCENE := "res://scenes/maze_backrooms.tscn"
const NEXT_STAGE := "res://scenes/stage_1.tscn"

@onready var _goal: Area2D = $Goal
@onready var _goal_label: Label = $GoalLabel
@onready var _next_area: Area2D = $NextArea
@onready var _triple_gate: Area2D = $TripleClipWall/Gate
@onready var _player: Node2D = $Player


func _ready() -> void:
	_goal_label.visible = false
	_goal.reached.connect(_on_goal_reached)
	_next_area.interacted.connect(ViewSwitcher.go_to.bind(NEXT_STAGE))
	_triple_gate.completed.connect(_on_triple_clip_completed)


func _on_goal_reached() -> void:
	_goal_label.visible = true
	var route := "bug" if BugRegistry.is_triggered("wall_clip") else "normal"
	print("stage_tutorial: goal reached (route: %s)" % route)


func _on_triple_clip_completed() -> void:
	BugRegistry.trigger("triple_clip")
	ViewSwitcher.enter(MAZE_SCENE, _player.global_position)
