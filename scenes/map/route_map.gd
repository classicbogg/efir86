extends Control

var _hover: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Game.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if Game.NODES.is_empty():
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Palette.INK)
	if Game.level_kind != "tutorial":
		_draw_dust(r)
	_draw_edges()
	_draw_nodes()
	_draw_convoy()
	_draw_pin()
	_draw_frame(r)


func _draw_dust(r: Rect2) -> void:
	var dust_vis: float = Game.dust
	if Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY:
		dust_vis = minf(dust_vis, 0.35)
	var w: float = r.size.x * (0.10 + dust_vis * 0.42)
	var pts := PackedVector2Array()
	pts.append(Vector2(0, 0))
	var steps := 14
	for i in steps + 1:
		var y: float = r.size.y * float(i) / float(steps)
		var jag: float = sin(y * 0.04 + dust_vis * 8.0) * 10.0
		pts.append(Vector2(w + jag, y))
	pts.append(Vector2(0, r.size.y))
	draw_colored_polygon(pts, Color(Palette.DUST_DIM, 0.35 + dust_vis * 0.25))
	draw_line(Vector2(w, 0), Vector2(w - 6, r.size.y), Color(Palette.DUST, 0.45), 2.0)


func _draw_edges() -> void:
	for e in Game.EDGES:
		var a: Vector2 = _pt(str(e[0]))
		var b: Vector2 = _pt(str(e[1]))
		draw_line(a, b, Color(Palette.STEEL, 0.45), 2.0)
		var mid: Vector2 = a.lerp(b, 0.5)
		var to_id: String = str(e[1])
		if to_id == "gas":
			_stamp("плешь", mid + Vector2(-18, -12), Palette.PAPER_DIM)
		elif to_id == "reshetka":
			_stamp("дворы", mid + Vector2(-18, -12), Palette.PAPER_DIM)


func _draw_nodes() -> void:
	for id in Game.NODES.keys():
		var p: Vector2 = _pt(id)
		var heat: float = Game.heat_of(id)
		var show_heat: bool = Game.antenna_alive
		if show_heat and heat > 0.35:
			draw_circle(p, 22.0 + heat * 10.0, Color(Palette.DUST, 0.16 + heat * 0.12))
		elif show_heat and heat < 0.12:
			draw_circle(p, 20.0, Color(Palette.JAM, 0.22))
		var fill := Palette.INK_RAISED
		if id == Game.current_node:
			fill = Palette.INK_RAISED.lightened(0.08)
		if id == _hover:
			fill = fill.lightened(0.1)
		var icon := Icons.node_icon(id)
		if not Icons.blit(self, icon, Rect2(p - Vector2(16, 16), Vector2(32, 32))):
			draw_circle(p, 11.0, fill)
			var ring := Palette.PAPER_DIM
			if id == "tower14":
				ring = Palette.CRT
			elif id == Game.dest_node:
				ring = Palette.AMBER
			draw_arc(p, 11.0, 0.0, TAU, 28, ring, 2.0)
		if id == "tower14":
			draw_circle(p + Vector2(0, -18), 4.0, Palette.CRT)
		if id == Game.dest_node:
			draw_arc(p, 20.0, 0.0, TAU, 28, Palette.AMBER, 2.0)
		if Game.phase == Game.Phase.STOP and not Game.force_dests.is_empty():
			if Game.force_dests.has(id):
				draw_arc(p, 24.0, 0.0, TAU, 28, Palette.CRT, 2.0)
			elif id in ["gas", "reshetka"]:
				draw_circle(p, 14.0, Color(Palette.JAM, 0.35))
		var title: String = str(Game.NODES[id]["title"])
		_stamp(title, p + Vector2(20, -6), Palette.PAPER)


func _draw_convoy() -> void:
	var p: Vector2 = _map(Game.convoy_pos())
	draw_rect(Rect2(p - Vector2(9, 5), Vector2(18, 10)), Palette.AMBER)
	draw_rect(Rect2(p - Vector2(9, 5), Vector2(18, 10)), Palette.INK, false, 1.0)


func _draw_pin() -> void:
	if Game.active_call.is_empty():
		return
	var nid := str(Game.active_call.get("node", ""))
	if nid == "" or not Game.NODES.has(nid):
		return
	var false_id := Game.false_pin_id()
	if false_id != "" and Game.NODES.has(false_id):
		var fp: Vector2 = _pt(false_id) + Vector2(0, -30)
		draw_circle(fp, 6.0, Color(Palette.JAM, 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.01)))
		_stamp("?", fp + Vector2(10, -4), Palette.JAM)
	var p: Vector2 = _pt(nid) + Vector2(0, -30)
	var pulse: float = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
	var pin_col := Palette.CRT if bool(Game.active_call.get("epilogue", false)) else Palette.AMBER
	var pin := Icons.ui("pin")
	if not Icons.blit(self, pin, Rect2(p - Vector2(10, 10), Vector2(20, 20))):
		draw_circle(p, 6.0, Color(pin_col, pulse))
	else:
		draw_circle(p, 3.0, Color(pin_col, pulse * 0.5))


func _draw_frame(r: Rect2) -> void:
	draw_rect(r, Palette.STEEL, false, 1.0)
	_stamp("СХЕМА ТРАССЫ", Vector2(12, 10), Palette.PAPER_DIM)
	if not Game.antenna_alive:
		_stamp("АНТЕННА МОЛЧИТ — КАРТА ВРЁТ", Vector2(12, 28), Palette.RUST)
	elif Game.phase == Game.Phase.STOP:
		_stamp("развилка: Соль = плешь · Кольца = дворы", Vector2(12, 28), Palette.PAPER_DIM)
	elif Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY:
		_stamp("МАЧТА ЖИВА — ПЫЛЬ СТОИТ", Vector2(12, 28), Palette.CRT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = _hit(event.position)
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Game.phase != Game.Phase.STOP:
			return
		var id := _hit(event.position)
		if id != "":
			Game.choose_dest(id)


func _hit(mouse: Vector2) -> String:
	for id in Game.NODES.keys():
		if mouse.distance_to(_pt(id)) <= 22.0:
			return id
	return ""


func _pt(id: String) -> Vector2:
	return _map(Game.NODES[id]["pos"])


func _map(n: Vector2) -> Vector2:
	return Vector2(n.x * size.x, n.y * size.y)


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
