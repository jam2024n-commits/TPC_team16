class_name LadybugIcon
extends Control

const CELL := 2
const PATTERN := [
	"..K......K..",
	"...K....K...",
	"....KKKK....",
	"..KRRRRRRK..",
	".KRRKRRKRRK.",
	".KRKKRRKKRK.",
	".KRRRKKRRRK.",
	".KRKKRRKKRK.",
	".KRRKRRKRRK.",
	"..KRRRRRRK..",
	"...KKKKKK...",
]
const COLORS := {
	"R": Color(0.85, 0.15, 0.12),
	"K": Color(0.08, 0.08, 0.1),
}
const SILHOUETTE_COLOR := Color(0.3, 0.3, 0.36)

@export var silhouette := false


func _ready() -> void:
	size = Vector2(PATTERN[0].length(), PATTERN.size()) * CELL
	pivot_offset = size / 2.0


func _draw() -> void:
	for y in PATTERN.size():
		var row: String = PATTERN[y]
		for x in row.length():
			var c := row[x]
			if COLORS.has(c):
				var color: Color = SILHOUETTE_COLOR if silhouette else COLORS[c]
				draw_rect(Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL)), color)
