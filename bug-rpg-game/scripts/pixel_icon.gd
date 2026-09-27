class_name PixelIcon
extends Control

const CELL := 2
const SILHOUETTE_COLOR := Color(0.3, 0.3, 0.36)

@export var silhouette := false

var pattern: Array = []
var colors: Dictionary = {}


func _ready() -> void:
	size = Vector2(pattern[0].length(), pattern.size()) * CELL
	pivot_offset = size / 2.0


func _draw() -> void:
	for y in pattern.size():
		var row: String = pattern[y]
		for x in row.length():
			var c := row[x]
			if colors.has(c):
				var color: Color = SILHOUETTE_COLOR if silhouette else colors[c]
				draw_rect(Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL)), color)
