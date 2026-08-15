extends Control

var _wave_phase: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Game.changed.connect(queue_redraw)
	Game.call_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_wave_phase += delta * (9.0 if not Game.active_call.is_empty() else 2.2)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.INK)
	draw_rect(Rect2(Vector2.ZERO, size), Palette.STEEL, false, 1.0)
	_stamp("РАЦИЯ", Vector2(12, 10), Palette.PAPER_DIM)
	_draw_levers()
	_draw_wave()
	_draw_call_text()
	_draw_buttons()
	_draw_cage()


func _draw_levers() -> void:
	_lever("A СВОИ", Vector2(12, 36), Game.frequency == "A", "freq_a")
	_lever("B ЗЕМЛЯ", Vector2(100, 36), Game.frequency == "B", "freq_b")


func _lever(label: String, pos: Vector2, on: bool, icon_name: String) -> void:
	var rect := Rect2(pos, Vector2(80, 28))
	draw_rect(rect, Palette.INK_RAISED)
	draw_rect(rect, Palette.CRT if on else Palette.STEEL, false, 2.0)
	Icons.blit(self, Icons.ui(icon_name), Rect2(pos + Vector2(4, 2), Vector2(24, 24)))
	_stamp(label, pos + Vector2(30, 8), Palette.CRT if on else Palette.PAPER_DIM)


func _draw_wave() -> void:
	var rect := Rect2(12, 76, size.x - 24, 64)
	draw_rect(rect, Color(0.05, 0.07, 0.05))
	draw_rect(rect, Palette.CRT_DIM, false, 1.0)
	var talking: bool = not Game.active_call.is_empty() and Game.frequency == str(Game.active_call.get("band", ""))
	var col := Palette.CRT if talking else Palette.CRT_DIM
	var pts := PackedVector2Array()
	var n := 48
	for i in n:
		var t: float = float(i) / float(n - 1)
		var x: float = rect.position.x + t * rect.size.x
		var amp: float = 18.0 if talking else 4.0
		var y: float = rect.get_center().y + sin(_wave_phase + t * 14.0) * amp * (0.4 + Game.haze)
		if talking and int(i + int(_wave_phase * 3.0)) % 7 == 0:
			y += (1.0 if i % 2 == 0 else -1.0) * 10.0 * Game.haze
		pts.append(Vector2(x, y))
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], col, 1.6)
	if talking:
		_stamp("ON AIR", Vector2(rect.position.x + 6, rect.position.y + 4), Palette.CRT)


func _draw_call_text() -> void:
	var y := 152.0
	if Game.active_call.is_empty():
		_stamp("тишина на мембране", Vector2(14, y), Palette.JAM)
		return
	var txt: String = str(Game.active_call.get("text", ""))
	_stamp("частота %s  ·  %d с" % [Game.active_call.get("band", "?"), int(Game.call_timer)], Vector2(14, y), Palette.AMBER)
	_stamp(txt, Vector2(14, y + 22), Palette.PAPER)


func _draw_buttons() -> void:
	if Game.active_call.is_empty():
		return
	_btn(0, str(Game.active_call.get("btn_a", "")), Vector2(12, size.y - 84))
	_btn(1, str(Game.active_call.get("btn_b", "")), Vector2(12, size.y - 44))


func _btn(i: int, label: String, pos: Vector2) -> void:
	var rect := Rect2(pos, Vector2(size.x - 24, 34))
	draw_rect(rect, Palette.INK_RAISED)
	draw_rect(rect, Palette.PAPER_DIM, false, 1.5)
	_stamp(label, pos + Vector2(10, 10), Palette.PAPER)


func _draw_cage() -> void:
	var rect := Rect2(size.x - 92, 36, 80, 28)
	draw_rect(rect, Palette.INK_RAISED)
	draw_rect(rect, Palette.JAM, false, 2.0)
	if not Icons.blit(self, Icons.ui("freq_c"), Rect2(rect.position + Vector2(4, 2), Vector2(24, 24))):
		draw_line(rect.position, rect.position + rect.size, Palette.JAM, 1.0)
		draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Palette.JAM, 1.0)
	_stamp("В", rect.position + Vector2(32, 8), Palette.JAM)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if Rect2(12, 36, 80, 28).has_point(event.position):
		Game.set_frequency("A")
	elif Rect2(100, 36, 80, 28).has_point(event.position):
		Game.set_frequency("B")
	elif not Game.active_call.is_empty():
		if Rect2(12, size.y - 84, size.x - 24, 34).has_point(event.position):
			Game.answer_call(0)
		elif Rect2(12, size.y - 44, size.x - 24, 34).has_point(event.position):
			Game.answer_call(1)


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
