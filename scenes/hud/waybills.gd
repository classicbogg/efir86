extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Game.changed.connect(queue_redraw)
	Game.phase_changed.connect(queue_redraw)
	Game.summary_ready.connect(queue_redraw)


func _process(_delta: float) -> void:
	visible = Game.phase == Game.Phase.STOP or Game.phase == Game.Phase.SUMMARY
	queue_redraw()


func _cards() -> Array:
	if Game.cards.is_empty():
		return LevelData.default_cards()
	return Game.cards


func _draw() -> void:
	if Game.phase == Game.Phase.SUMMARY:
		_draw_summary()
		return
	if Game.phase != Game.Phase.STOP:
		return
	var cards: Array = _cards()
	var w := 210.0
	var gap := 16.0
	var total := w * float(cards.size()) + gap * float(maxi(cards.size() - 1, 0))
	var x0 := (size.x - total) * 0.5
	var y := 8.0
	if Game.breath_left > 0.0:
		_stamp("ВДОХ  %.0f  ·  пыль на секунды замирает" % Game.breath_left, Vector2(x0, y), Palette.CRT)
	elif Game.level_kind == "tutorial":
		_stamp("ОБУЧЕНИЕ  ·  пыль выключена", Vector2(x0, y), Palette.CRT_DIM)
	else:
		_stamp("ПЫЛЬ ИДЁТ  ·  жадность стоит метров", Vector2(x0, y), Palette.RUST)
	for i in cards.size():
		var card: Dictionary = cards[i]
		var cid := str(card["id"])
		var rect := Rect2(x0 + float(i) * (w + gap), 28, w, size.y - 36)
		var picked: bool = Game.picked_card == cid
		var allowed: bool = Game.action_allowed_param("pick_card", cid)
		draw_rect(rect, Palette.INK_RAISED)
		var border := Palette.AMBER if picked else Palette.PAPER_DIM
		if not allowed and Game.picked_card == "":
			border = Palette.JAM
		draw_rect(rect, border, false, 2.0)
		var title_col := Palette.AMBER if picked else Palette.DUST
		var body_col := Palette.PAPER
		if not allowed and Game.picked_card == "":
			title_col = Palette.JAM
			body_col = Palette.PAPER_DIM
		_stamp(str(card["title"]), rect.position + Vector2(12, 10), title_col)
		_stamp(str(card["body"]), rect.position + Vector2(12, 36), body_col)


func _draw_summary() -> void:
	var rect := Rect2(24, 8, size.x - 48, size.y - 16)
	draw_rect(rect, Palette.INK_RAISED)
	draw_rect(rect, Palette.DUST, false, 2.0)
	var y := rect.position.y + 14.0
	for line in Game.summary_lines:
		var col := Palette.AMBER if str(line).begins_with("НАКЛАДНАЯ") or str(line).begins_with("ОБУЧЕНИЕ") else Palette.PAPER
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16, y), str(line), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		y += 18.0
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16, rect.end.y - 22), "клик — закрыть смену", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.PAPER_DIM)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if Game.phase == Game.Phase.SUMMARY:
		Game.acknowledge_summary()
		return
	if Game.phase != Game.Phase.STOP:
		return
	var cards: Array = _cards()
	var w := 210.0
	var gap := 16.0
	var total := w * float(cards.size()) + gap * float(maxi(cards.size() - 1, 0))
	var x0 := (size.x - total) * 0.5
	for i in cards.size():
		var rect := Rect2(x0 + float(i) * (w + gap), 28, w, size.y - 36)
		if rect.has_point(event.position):
			Game.pick_card(str(cards[i]["id"]))


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_multiline_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, 190, 14, -1, color)
