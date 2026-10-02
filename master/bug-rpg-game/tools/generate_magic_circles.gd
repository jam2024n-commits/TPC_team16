extends SceneTree

# 魔法陣の仮のドット絵を、1ピクセル単位の線で描いて PNG に書き出す。
# 実行: godot --headless --path . --script res://tools/generate_magic_circles.gd
# 出力先: res://assets/battle/magic_circle/（big_red.png 128x128、yellow.png 128x128、small_red.png 16x16）
# 描く担当の人の画像ができたら、同じファイル名で置き換えればよい

const OUT_DIR := "res://assets/battle/magic_circle/"

const RED := Color(0.95, 0.25, 0.2)
const RED_LIGHT := Color(1.0, 0.62, 0.5)
const YELLOW := Color(1.0, 0.82, 0.2)
const YELLOW_LIGHT := Color(1.0, 0.97, 0.72)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save(_big_red(), "big_red.png")
	_save(_yellow(), "yellow.png")
	_save(_small_red(), "small_red.png")
	quit()


func _save(img: Image, file: String) -> void:
	var err := img.save_png(ProjectSettings.globalize_path(OUT_DIR + file))
	print(file, " ", img.get_size(), " -> ", "OK" if err == OK else "error %d" % err)


func _new(size: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


# ---- 大技の前（赤）：二重円・六芒星・ルーン風の目盛り ----
func _big_red() -> Image:
	var img := _new(128)
	var c := Vector2(63.5, 63.5)
	_circle(img, c, 62, RED)
	_circle(img, c, 59, RED_LIGHT)
	_circle(img, c, 49, RED)
	_circle(img, c, 20, RED_LIGHT)
	for start in [-90.0, 90.0]:
		var points: Array[Vector2] = []
		for i in 3:
			points.append(c + Vector2.from_angle(deg_to_rad(start + i * 120.0)) * 49.0)
		_polygon(img, points, RED)
	for i in 12:
		var a := deg_to_rad(i * 30.0 + 15.0)
		var dir := Vector2.from_angle(a)
		_line(img, c + dir * 51.0, c + dir * 57.0, RED_LIGHT)
		if i % 2 == 0:
			var tangent := dir.orthogonal()
			_line(img, c + dir * 54.0 - tangent * 2.0, c + dir * 54.0 + tangent * 2.0, RED_LIGHT)
	for i in 6:
		_dot(img, c + Vector2.from_angle(deg_to_rad(-90.0 + i * 60.0)) * 49.0, RED_LIGHT)
	return img


# ---- 一斉射撃の前（黄）：四角を重ねた模様・ひし形・角の点 ----
func _yellow() -> Image:
	var img := _new(128)
	var c := Vector2(63.5, 63.5)
	_circle(img, c, 62, YELLOW)
	_square(img, c, 44.0, 0.0, YELLOW)
	_square(img, c, 44.0, 45.0, YELLOW_LIGHT)
	_square(img, c, 22.0, 45.0, YELLOW)
	_square(img, c, 22.0, 0.0, YELLOW_LIGHT)
	_circle(img, c, 12, YELLOW_LIGHT)
	for i in 8:
		_dot(img, c + Vector2.from_angle(deg_to_rad(i * 45.0 + 22.5)) * 56.0, YELLOW_LIGHT)
	return img


# ---- 通常弾（小さい赤）：円と下向きの三角 ----
func _small_red() -> Image:
	var img := _new(16)
	var c := Vector2(7.5, 7.5)
	_circle(img, c, 7, RED)
	var points: Array[Vector2] = []
	for i in 3:
		points.append(c + Vector2.from_angle(deg_to_rad(90.0 + i * 120.0)) * 5.5)
	_polygon(img, points, RED_LIGHT)
	return img


# ---- 1ピクセル単位の描画 ----

func _plot(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


# 中点円アルゴリズム（アンチエイリアスなし）
func _circle(img: Image, center: Vector2, r: int, color: Color) -> void:
	var cx := int(floor(center.x))
	var cy := int(floor(center.y))
	var odd := 1 if center.x != floor(center.x) else 0  # 中心がピクセルの境目なら左右対称にずらす
	var x := r
	var y := 0
	var err := 1 - r
	while x >= y:
		for p in [Vector2i(x, y), Vector2i(y, x)]:
			_plot(img, cx + p.x + odd, cy + p.y + odd, color)
			_plot(img, cx - p.x, cy + p.y + odd, color)
			_plot(img, cx + p.x + odd, cy - p.y, color)
			_plot(img, cx - p.x, cy - p.y, color)
		y += 1
		if err < 0:
			err += 2 * y + 1
		else:
			x -= 1
			err += 2 * (y - x) + 1


# ブレゼンハムの線
func _line(img: Image, from: Vector2, to: Vector2, color: Color) -> void:
	var x0 := roundi(from.x)
	var y0 := roundi(from.y)
	var x1 := roundi(to.x)
	var y1 := roundi(to.y)
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		_plot(img, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func _polygon(img: Image, points: Array[Vector2], color: Color) -> void:
	for i in points.size():
		_line(img, points[i], points[(i + 1) % points.size()], color)


func _square(img: Image, center: Vector2, half: float, angle_deg: float, color: Color) -> void:
	var points: Array[Vector2] = []
	for i in 4:
		points.append(center + Vector2.from_angle(deg_to_rad(angle_deg + 45.0 + i * 90.0)) * half * sqrt(2.0))
	_polygon(img, points, color)


func _dot(img: Image, center: Vector2, color: Color) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			_plot(img, roundi(center.x) + dx, roundi(center.y) + dy, color)
