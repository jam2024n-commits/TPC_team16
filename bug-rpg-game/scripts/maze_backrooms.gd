extends Node3D

const CELL := 3.0
const HEIGHT := 3.0
const SLAB_THICKNESS := 0.3
const START_YAW := -PI / 2.0
const LIGHT_ENERGY := 0.6
const FLICKER_RATE := 8.0
const ITEM_ID := "castle_door_key"

# '#': 壁  'S': 開始  'W': ゴール前の壁抜けできる壁  'c': しゃがめる範囲  'G': ゴール
const LAYOUT := [
	"#############",
	"#S..........#",
	"###########.#",
	"#...........#",
	"#.###########",
	"#...........#",
	"###########.#",
	"#GWcc.......#",
	"#############",
]

@onready var _player: CharacterBody3D = $Player
@onready var _crouch_hint: Control = $HintLayer/CrouchHint

var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _ceiling_mat: StandardMaterial3D
var _slab_mat: StandardMaterial3D
var _fixture_mat: StandardMaterial3D
var _item_mat: StandardMaterial3D
var _flickering: Array[OmniLight3D] = []
var _crouch_zones := 0
var _leaving := false


func _ready() -> void:
	_crouch_hint.visible = false
	_wall_mat = _material(Color(0.78, 0.74, 0.55))
	_floor_mat = _material(Color(0.42, 0.39, 0.28))
	_ceiling_mat = _material(Color(0.7, 0.68, 0.6))
	_slab_mat = _material(Color(0.78, 0.74, 0.55), Color(1.0, 0.95, 0.75), 0.4)
	_fixture_mat = _material(Color(1, 1, 1), Color(1.0, 0.98, 0.9), 1.5)
	_item_mat = _material(Color(1.0, 0.9, 0.5), Color(1.0, 0.9, 0.5), 3.0)
	_build()


func _process(delta: float) -> void:
	for light in _flickering:
		if randf() < FLICKER_RATE * delta:
			light.light_energy = LIGHT_ENERGY * randf_range(0.05, 1.0)


func _build() -> void:
	var size := Vector3(LAYOUT[0].length() * CELL, 0.1, LAYOUT.size() * CELL)
	_add_body(Vector3(size.x / 2.0, -0.05, size.z / 2.0), size, 1)

	for row in LAYOUT.size():
		var line: String = LAYOUT[row]
		for col in line.length():
			var c := line[col]
			var center := Vector3((col + 0.5) * CELL, HEIGHT / 2.0, (row + 0.5) * CELL)
			if c == "#":
				_add_body(center, Vector3(CELL, HEIGHT, CELL), 1, _wall_mat)
				continue
			_add_mesh(Vector3(center.x, -0.05, center.z), Vector3(CELL, 0.1, CELL), _floor_mat)
			_add_mesh(Vector3(center.x, HEIGHT + 0.05, center.z), Vector3(CELL, 0.1, CELL), _ceiling_mat)
			match c:
				"S":
					_player.position = Vector3(center.x, 0.05, center.z)
					_player.rotation.y = START_YAW
				"W":
					_add_body(center, Vector3(SLAB_THICKNESS, HEIGHT, CELL), 2, _slab_mat)
					_add_crouch_zone(center)
				"c":
					_add_crouch_zone(center)
				"G":
					_add_goal(center)
			if c == "." and (row + col) % 3 == 0:
				_add_ceiling_light(center)


func _add_body(pos: Vector3, size: Vector3, layer: int, mat: Material = null) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	if mat:
		body.add_child(_box_mesh(size, mat))
	add_child(body)


func _add_mesh(pos: Vector3, size: Vector3, mat: Material) -> void:
	var inst := _box_mesh(size, mat)
	inst.position = pos
	add_child(inst)


func _box_mesh(size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	return inst


func _add_area(center: Vector3) -> Area3D:
	var area := Area3D.new()
	area.position = center
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CELL, HEIGHT, CELL)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	return area


func _add_crouch_zone(center: Vector3) -> void:
	var area := _add_area(center)
	area.body_entered.connect(_on_crouch_zone.bind(1))
	area.body_exited.connect(_on_crouch_zone.bind(-1))


func _add_goal(center: Vector3) -> void:
	var area := _add_area(center)
	area.body_entered.connect(_on_goal_entered)
	var light := OmniLight3D.new()
	light.position = Vector3(center.x, 2.0, center.z)
	light.light_color = Color(1.0, 0.9, 0.6)
	light.light_energy = 2.0
	light.omni_range = 4.5
	add_child(light)
	_add_mesh(Vector3(center.x, 1.0, center.z), Vector3(0.25, 0.25, 0.25), _item_mat)


func _add_ceiling_light(center: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(center.x, HEIGHT - 0.3, center.z)
	light.light_color = Color(1.0, 0.97, 0.85)
	light.light_energy = LIGHT_ENERGY
	light.omni_range = 5.0
	add_child(light)
	_add_mesh(Vector3(center.x, HEIGHT - 0.03, center.z), Vector3(0.6, 0.05, 1.2), _fixture_mat)
	if randi() % 4 == 0:
		_flickering.append(light)


func _material(albedo: Color, emission := Color.BLACK, emission_energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 1.0
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


func _on_crouch_zone(body: Node3D, change: int) -> void:
	if body != _player:
		return
	_crouch_zones += change
	var inside := _crouch_zones > 0
	_player.can_crouch = inside
	_crouch_hint.visible = inside and not _leaving


func _on_goal_entered(body: Node3D) -> void:
	if body != _player or _leaving:
		return
	_leaving = true
	_crouch_hint.visible = false
	if not Inventory.has_item(ITEM_ID):
		# FAKE_BUG: maze_goal_clip
		BugRegistry.trigger("maze_goal_clip")
		Inventory.add_item(ITEM_ID)
		await GameUI.item_toast_finished
	ViewSwitcher.return_to_field()
