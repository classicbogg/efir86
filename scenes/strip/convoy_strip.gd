extends Control

var _drag_from: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Game.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.INK_RAISED)
	draw_rect(Rect2(Vector2.ZERO, size), Palette.STEEL, false, 1.0)
	_stamp("ЛЕНТА", Vector2(10, 8), Palette.PAPER_DIM)
	_draw_plomb()
	var n: int = Game.trucks.size()
	if n == 0:
		return
	var box_w: float = minf(150.0, (size.x - 160.0) / float(n) - 8.0)
	var x0: float = 120.0
	for i in n:
		var kind: String = Game.trucks[i]
		var x: float = x0 + float(i) * (box_w + 10.0)
		var rect := Rect2(x, 28, box_w, size.y - 40)
		var col := Palette.truck_color(kind)
		if kind == "antenna" and not Game.antenna_alive:
			col = Palette.JAM
		draw_rect(rect, col.darkened(0.45))
		draw_rect(rect, Palette.PAPER_DIM if i != _drag_from else Palette.AMBER, false, 2.0)
		var icon_size := minf(56.0, rect.size.y - 28.0)
		var icon_rect := Rect2(rect.position + Vector2(8, 22), Vector2(icon_size, icon_size))
		if not Icons.blit(self, Icons.truck(kind), icon_rect):
			_stamp(Palette.truck_label(kind), rect.position + Vector2(8, 8), Palette.PAPER)
		else:
			_stamp(Palette.truck_label(kind), rect.position + Vector2(8, 6), Palette.PAPER)
		_draw_tokens_on(kind, rect)


func _draw_tokens_on(kind: String, rect: Rect2) -> void:
	var home := {
		"medic": "clinic",
		"tech": "antenna",
		"radio": "antenna",
	}
	var slot := 0
	for tok in Game.tokens:
		var hid: String = str(home.get(str(tok["id"]), "housing"))
		if hid != kind:
			continue
		var cx: float = rect.position.x + 18 + slot * 26
		var cy: float = rect.position.y + rect.size.y - 18
		if bool(tok["busy"]):
			cx += float(tok["progress"]) * 40.0
		var tok_tex := Icons.token(str(tok["id"]))
		if not Icons.blit(self, tok_tex, Rect2(cx - 12, cy - 12, 24, 24)):
			draw_circle(Vector2(cx, cy), 10.0, Palette.INK)
			draw_arc(Vector2(cx, cy), 10.0, 0, TAU, 16, Palette.AMBER if bool(tok["busy"]) else Palette.PAPER, 2.0)
			_stamp(str(tok["glyph"]), Vector2(cx - 5, cy - 6), Palette.PAPER)
		slot += 1


func _draw_plomb() -> void:
	var rect := Rect2(10, size.y * 0.28, 88, 56)
	var tex := Icons.ui("plomb" if Game.plomb_locked else "plomb_open")
	if not Icons.blit(self, tex, Rect2(rect.position, Vector2(40, 40))):
		var col := Palette.STEEL if Game.plomb_locked else Palette.RUST
		draw_rect(rect, Palette.INK)
		draw_rect(rect, col, false, 2.0)
	_stamp("ПЛОМБА" if Game.plomb_locked else "СОРВАНА", rect.position + Vector2(4, 40), Palette.STEEL if Game.plomb_locked else Palette.RUST)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _plomb_rect().has_point(event.position):
				Game.toggle_plomb()
				return
			var tok := _hit_token(event.position)
			if tok != "":
				Game.dispatch(tok)
				return
			_drag_from = _hit_truck(event.position)
		else:
			if _drag_from >= 0:
				var to_i := _hit_truck(event.position)
				if to_i >= 0:
					Game.shift_truck(_drag_from, to_i)
			_drag_from = -1
			queue_redraw()


func _plomb_rect() -> Rect2:
	return Rect2(10, size.y * 0.28, 88, 56)


func _hit_truck(mouse: Vector2) -> int:
	var n: int = Game.trucks.size()
	var box_w: float = minf(150.0, (size.x - 160.0) / float(max(n, 1)) - 8.0)
	for i in n:
		var x: float = 120.0 + float(i) * (box_w + 10.0)
		if Rect2(x, 28, box_w, size.y - 40).has_point(mouse):
			return i
	return -1


func _hit_token(mouse: Vector2) -> String:
	# проще: клик по глифу в нижней трети коробки своего дома
	var n: int = Game.trucks.size()
	var box_w: float = minf(150.0, (size.x - 160.0) / float(max(n, 1)) - 8.0)
	var home := {"medic": "clinic", "tech": "antenna", "radio": "antenna"}
	for i in n:
		var kind: String = Game.trucks[i]
		var x: float = 120.0 + float(i) * (box_w + 10.0)
		var rect := Rect2(x, 28, box_w, size.y - 40)
		for tok in Game.tokens:
			if str(home.get(str(tok["id"]), "")) != kind:
				continue
			if rect.has_point(mouse) and mouse.y > rect.position.y + rect.size.y * 0.55:
				return str(tok["id"])
	return ""


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
