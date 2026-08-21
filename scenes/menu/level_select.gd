extends Control
## Тонкий экран выборки уровней (не финальное меню).


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.INK)
	_stamp("RELAY", Vector2(48, 48), Palette.PAPER)
	_stamp("ночное радио колонны  ·  выборка глав", Vector2(48, 78), Palette.PAPER_DIM)
	_stamp("меню позже — сейчас список срезов", Vector2(48, 100), Palette.JAM)

	var catalog = Relay.catalog()
	var progress = Relay.progress()
	var y := 150.0
	for def in catalog.all_chapters():
		var id: int = int(def["id"])
		var unlocked: bool = bool(catalog.is_unlocked(id))
		var rect := Rect2(48, y, size.x - 96, 88)
		draw_rect(rect, Palette.INK_RAISED)
		var border := Palette.CRT if unlocked else Palette.JAM
		if progress.current_chapter == id:
			border = Palette.AMBER
		draw_rect(rect, border, false, 2.0)
		var title := str(def.get("title", id))
		if not unlocked:
			title = "[закрыт]  " + title
		_stamp(title, rect.position + Vector2(20, 18), Palette.PAPER if unlocked else Palette.PAPER_DIM)
		_stamp(str(def.get("blurb", "")), rect.position + Vector2(20, 46), Palette.PAPER_DIM)
		y += 104.0

	_stamp("клик по открытой главе  ·  R сброс прогресса (dev)", Vector2(48, size.y - 40), Palette.PAPER_DIM)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			Relay.progress().reset_all()
			queue_redraw()
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var catalog = Relay.catalog()
	var y := 150.0
	for def in catalog.all_chapters():
		var rect := Rect2(48, y, size.x - 96, 88)
		if rect.has_point(event.position):
			var id: int = int(def["id"])
			if catalog.is_unlocked(id):
				_start_level(id)
			else:
				queue_redraw()
			return
		y += 104.0


func _start_level(id: int) -> void:
	Relay.game().pending_chapter_id = id
	Relay.game().pending_level_id = id
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
