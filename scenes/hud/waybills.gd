extends Control

const CARDS := [
	{"id": "workshop", "title": "ФУРА", "body": "Мастерская в ленту.\nСоседство с антенной\nпотом поможет вышке."},
	{"id": "water", "title": "ПРОТОКОЛ", "body": "Вода Решётке.\nЗемля теплее.\nСлед на густой дороге."},
	{"id": "wet_rag", "title": "РЕЛИКВИЯ", "body": "Мокрая тряпка.\nМгла тише.\nКолонна ползёт."},
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Game.changed.connect(queue_redraw)
	Game.phase_changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	visible = Game.phase == Game.Phase.STOP
	queue_redraw()


func _draw() -> void:
	if Game.phase != Game.Phase.STOP:
		return
	var w := 210.0
	var gap := 16.0
	var total := w * 3.0 + gap * 2.0
	var x0 := (size.x - total) * 0.5
	var y := 8.0
	if Game.breath_left > 0.0:
		_stamp("ВДОХ  %.0f" % Game.breath_left, Vector2(x0, y), Palette.CRT)
	else:
		_stamp("ПЫЛЬ ИДЁТ", Vector2(x0, y), Palette.RUST)
	for i in CARDS.size():
		var card: Dictionary = CARDS[i]
		var rect := Rect2(x0 + float(i) * (w + gap), 28, w, size.y - 36)
		var picked: bool = Game.picked_card == str(card["id"])
		draw_rect(rect, Palette.INK_RAISED)
		draw_rect(rect, Palette.AMBER if picked else Palette.PAPER_DIM, false, 2.0)
		_stamp(str(card["title"]), rect.position + Vector2(12, 10), Palette.AMBER if picked else Palette.DUST)
		_stamp(str(card["body"]), rect.position + Vector2(12, 36), Palette.PAPER)


func _gui_input(event: InputEvent) -> void:
	if Game.phase != Game.Phase.STOP:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var w := 210.0
	var gap := 16.0
	var total := w * 3.0 + gap * 2.0
	var x0 := (size.x - total) * 0.5
	for i in CARDS.size():
		var rect := Rect2(x0 + float(i) * (w + gap), 28, w, size.y - 36)
		if rect.has_point(event.position):
			Game.pick_card(str(CARDS[i]["id"]))


func _stamp(text: String, pos: Vector2, color: Color) -> void:
	draw_multiline_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, 190, 14, -1, color)
