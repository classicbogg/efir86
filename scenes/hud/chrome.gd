extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.INK)
	draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Palette.STEEL, 1.0)
	_stamp("ЭФИР 86", Vector2(16, 14), Palette.PAPER)
	_stamp("демо-срез  ·  карьер → вышка 14", Vector2(16, 34), Palette.PAPER_DIM)
	_hour_bar()
	_needle("ЗЕМЛЯ", Game.trust, Palette.DUST, Vector2(size.x - 360, 10))
	_needle("СВОИ", Game.authority, Palette.CRT, Vector2(size.x - 180, 10))


func _hour_bar() -> void:
	var rect := Rect2(280, 18, 220, 10)
	draw_rect(rect, Palette.INK_RAISED)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * Game.hour, rect.size.y)), Palette.DUST_DIM)
	draw_rect(rect, Palette.STEEL, false, 1.0)
	var label := "РАННЯЯ"
	if Game.hour > 0.66:
		label = "ПРЕДРАССВЕТ"
	elif Game.hour > 0.33:
		label = "ГЛУХАЯ"
	_stamp(label, Vector2(280, 32), Palette.PAPER_DIM)


func _needle(title: String, value: float, col: Color, pos: Vector2) -> void:
	_stamp(title, pos, Palette.PAPER_DIM)
	var rect := Rect2(pos + Vector2(0, 16), Vector2(150, 8))
	draw_rect(rect, Palette.INK_RAISED)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(value, 0, 1), rect.size.y)), col)
	draw_rect(rect, Palette.STEEL, false, 1.0)


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
