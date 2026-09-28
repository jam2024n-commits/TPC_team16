extends Node2D

# 壊れたブロックの破片。いくつかの小さな四角が飛び散って落ち、消える（見た目だけ。当たり判定なし）

const LIFETIME := 0.7
const GRAVITY := 900.0
const PIECE_SIZE := 4.0
const PIECES_PER_WIDTH := 12.0  # 何ピクセルごとに破片を1つ出すか

var _pieces: Array[Dictionary] = []  # {pos, vel}
var _color := Color.WHITE
var _time := 0.0


func setup(rect: Rect2, color: Color) -> void:
	_color = color
	var count := clampi(int(rect.size.x / PIECES_PER_WIDTH), 3, 40)
	for i in count:
		var pos := rect.position + Vector2(randf() * rect.size.x, randf() * rect.size.y)
		_pieces.append({"pos": pos, "vel": Vector2(randf_range(-60, 60), randf_range(-160, -40))})


func _process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return
	for p in _pieces:
		p.vel.y += GRAVITY * delta
		p.pos += p.vel * delta
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _time / LIFETIME
	for p in _pieces:
		draw_rect(Rect2(p.pos, Vector2(PIECE_SIZE, PIECE_SIZE)), Color(_color, alpha))
