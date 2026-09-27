extends Control

signal closed

const ENTRIES := [
	{"id": "wall_clip", "label": "壁抜け"},
	{"id": "triple_clip", "label": "鍵のありか"},
	{"id": "password_debug", "label": "合言葉"},
	{"id": "loop_return", "label": "return;"},
	{"id": "loop_break", "label": "break;"},
]
const SLOTS_PER_PAGE := 8
const SLOT_SIZE := Vector2(30, 28)
const UNKNOWN_LABEL := "？？？"
const FOUND_COLOR := Color(0.22, 0.22, 0.3)
const UNKNOWN_COLOR := Color(0.12, 0.12, 0.16)

@onready var _title: Label = $Content/Title
@onready var _grid: GridContainer = $Content/Grid
@onready var _detail: Label = $Content/Detail
@onready var _prev: Button = $Content/Nav/PrevButton
@onready var _next: Button = $Content/Nav/NextButton
@onready var _back: Button = $Content/Nav/BackButton

var _page := 0


func _ready() -> void:
	_prev.pressed.connect(_turn.bind(-1))
	_next.pressed.connect(_turn.bind(1))
	_back.pressed.connect(closed.emit)


func open() -> void:
	_page = 0
	_refresh()
	visible = true
	_back.grab_focus()


func _page_count() -> int:
	return maxi(1, ceili(ENTRIES.size() / float(SLOTS_PER_PAGE)))


func _turn(step: int) -> void:
	_page = clampi(_page + step, 0, _page_count() - 1)
	_refresh()


func _refresh() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()

	var found := 0
	for entry in ENTRIES:
		if BugRegistry.is_discovered(entry.id):
			found += 1
	_title.text = "BUG  %d/%d" % [found, ENTRIES.size()]

	var start := _page * SLOTS_PER_PAGE
	for i in range(start, mini(start + SLOTS_PER_PAGE, ENTRIES.size())):
		_grid.add_child(_make_slot(ENTRIES[i]))

	var paged := _page_count() > 1
	_prev.visible = paged
	_next.visible = paged
	_prev.disabled = _page == 0
	_next.disabled = _page == _page_count() - 1
	_detail.text = ""


func _make_slot(entry: Dictionary) -> Control:
	var found: bool = BugRegistry.is_discovered(entry.id)
	var slot := ColorRect.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.color = FOUND_COLOR if found else UNKNOWN_COLOR
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon := LadybugIcon.new()
	icon.silhouette = not found
	icon.position = Vector2(3, 3)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var text: String = entry.label if found else UNKNOWN_LABEL
	slot.mouse_entered.connect(func() -> void: _detail.text = text)
	slot.mouse_exited.connect(func() -> void: _detail.text = "")
	return slot
