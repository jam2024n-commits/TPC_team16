extends Node2D

# 3D迷路のゴールの先にある、見下ろし視点の正方形の迷路。
# 真ん中の区画から始まり、4辺それぞれに「へこんだ壁」（x）が1か所ずつある。
# 壁抜けすると外側の4区画（風車状に分かれていて、互いにつながっていない）に出られるが、ゴールがあるのは1区画だけ

const TILE := 8.0
const RECESS := 1.0
const HINT_TIME := 4.0
const SHOOTER := "res://scenes/shooter.tscn"

const FLOOR_COLOR := Color(0.1, 0.1, 0.12)
const WALL_COLOR := Color(0.5, 0.47, 0.4)
const GOAL_COLOR := Color(1.0, 0.9, 0.5)

# '#': 壁  'x': 壁抜けできる壁（周りより RECESS だけへこんでいる）  'S': 開始  'G': ゴール
const LAYOUT := [
	"###########################################",
	"#...#...........#.............#.#.....#...#",
	"###.###########.#.#####.#####.#.###.#.#.###",
	"#.#.......#...#.#.#...#.#.....#...#.#.#...#",
	"#.#######.#.#.#.#.#.#.#.#####.###.#.#.###.#",
	"#.#.....#.#.#.#...#.#.#.....#.#.#.#.#...#.#",
	"#.#.#.###.#.#.#####.#.#.###.#.#.#.#.###.#.#",
	"#...#.....#.#.......#.#...#.#.#.#.#.#.....#",
	"#.#########.#########.#####.#.#.#.#.#####.#",
	"#...#...#...#.......#.....#.#.#.#.#...#G#.#",
	"###.#.#.#.###.#.#########.#.#.#.#.#.#.#.#.#",
	"#.....#...#...#.............#.#.#.#.#.#.#.#",
	"#####################x#########.#.#.#.#.#.#",
	"#.......#...#.#.........#.....#...#.#.#...#",
	"#######.#.#.#.#.#######.###.#.#.###.#.###.#",
	"#...#...#.#.#...#.....#.....#.#...#.#...#.#",
	"#.###.###.#######.#.#.#######.###.#####.###",
	"#.....#.....#.....#.#...#...#.#...#...#...#",
	"#.#########.#.#####.###.###.#.#.###.#.###.#",
	"#.......#...#.#...#...#.....#.x.#...#...#.#",
	"#######.#.###.#.#.###.#####.#.#.#.#####.#.#",
	"#...#...#...#.#.#...#S....#.#.#...#.....#.#",
	"#.#.#.###.#.#.#.###.#####.#.#.#####.#####.#",
	"#.#.#...#.#.#.#...#...#...#.#.#.#...#.....#",
	"#.#.###.###.#.#######.#.#####.#.#.#######.#",
	"#.#...#...#.x.........#.#.....#.#.#.......#",
	"#.#.#####.#.#########.#.#.#####.#.#.#######",
	"#.#.......#.#.......#.#.#.#...#.#.#.......#",
	"#.#########.#.#######.#.#.###.#.#.#######.#",
	"#...#.......#.........#.......#...........#",
	"###.#.###.#######x#########################",
	"#...#.#.#...#.#.....#.............#...#...#",
	"#.###.#.###.#.#.###.#.#.#########.#.#.#.#.#",
	"#.#.#.#...#.#...#...#.#.#.....#.....#...#.#",
	"#.#.#.###.#.#####.###.#.#.###.###########.#",
	"#.#.......#.#.#...#...#.....#.....#...#...#",
	"#.#.#######.#.#.#################.#.#.#.###",
	"#.#...#.....#.#...#...........#...#.#...#.#",
	"#.###.#.#####.###.#.#########.#.###.#####.#",
	"#...#.#.....#...#.#.#.#.....#.#...#.#...#.#",
	"###.#######.#.#.#.#.#.#.###.#.###.#.#.#.#.#",
	"#...........#.#.....#.....#.......#...#...#",
	"###########################################",
]

@onready var _player: CharacterBody2D = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _controls_hint: Label = $HintLayer/ControlsHint

var _wall_rects: Array[Rect2] = []
var _clip_rects: Array[Rect2] = []
var _goal_rect := Rect2()
var _leaving := false


func _ready() -> void:
	_build()
	_camera.limit_right = int(LAYOUT[0].length() * TILE)
	_camera.limit_bottom = int(LAYOUT.size() * TILE)
	queue_redraw()
	# 操作の案内は迷路の下端に重なるので、しばらくしたら消す
	create_tween().tween_property(_controls_hint, "modulate:a", 0.0, 1.0).set_delay(HINT_TIME)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(LAYOUT[0].length(), LAYOUT.size()) * TILE), FLOOR_COLOR)
	for rect in _wall_rects:
		draw_rect(rect, WALL_COLOR)
	for rect in _clip_rects:
		draw_rect(rect, WALL_COLOR)
	draw_rect(_goal_rect.grow(-1.0), GOAL_COLOR)


func _build() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)

	var used := {}
	for row in LAYOUT.size():
		var line: String = LAYOUT[row]
		for col in line.length():
			var c := line[col]
			var tile_rect := Rect2(Vector2(col, row) * TILE, Vector2(TILE, TILE))
			match c:
				"#":
					if not used.has(Vector2i(col, row)):
						var rect := _merge_walls(col, row, used)
						_wall_rects.append(rect)
						_add_shape(walls, rect)
				"x":
					_add_clip_wall(col, row, tile_rect)
				"S":
					_player.position = tile_rect.get_center()
				"G":
					_goal_rect = tile_rect
					_add_goal(tile_rect)


# 横に続く壁をまとめ、同じ幅の行が下に続けば縦にもまとめる（当たり判定の継ぎ目を減らすため）
func _merge_walls(col: int, row: int, used: Dictionary) -> Rect2:
	var width := 0
	while col + width < LAYOUT[row].length() and LAYOUT[row][col + width] == "#" and not used.has(Vector2i(col + width, row)):
		width += 1
	var height := 1
	while row + height < LAYOUT.size() and _is_wall_run(col, row + height, width, used):
		height += 1
	for y in height:
		for x in width:
			used[Vector2i(col + x, row + y)] = true
	return Rect2(Vector2(col, row) * TILE, Vector2(width, height) * TILE)


func _is_wall_run(col: int, row: int, width: int, used: Dictionary) -> bool:
	for x in width:
		if LAYOUT[row][col + x] != "#" or used.has(Vector2i(col + x, row)):
			return false
	return true


func _add_clip_wall(col: int, row: int, tile_rect: Rect2) -> void:
	# 左右が通路なら縦向きの壁なので左右の面を、そうでなければ上下の面をへこませる
	var vertical: bool = LAYOUT[row][col - 1] != "#" and LAYOUT[row][col + 1] != "#"
	var rect := tile_rect.grow_individual(-RECESS, 0.0, -RECESS, 0.0) if vertical \
		else tile_rect.grow_individual(0.0, -RECESS, 0.0, -RECESS)
	_clip_rects.append(rect)
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	_add_shape(body, rect)


func _add_shape(body: CollisionObject2D, rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)


func _add_goal(tile_rect: Rect2) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = tile_rect.size
	shape.shape = box
	shape.position = tile_rect.get_center()
	area.add_child(shape)
	area.body_entered.connect(_on_goal_entered)
	add_child(area)


func _on_goal_entered(body: Node2D) -> void:
	if body != _player or _leaving:
		return
	_leaving = true
	# FAKE_BUG: topdown_maze_clip
	BugRegistry.trigger("topdown_maze_clip")
	ViewSwitcher.go_to(SHOOTER)
