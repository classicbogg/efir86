extends Control
## Накладные / итог — ноды Card0..2 и Summary. Скрипт только биндит Game.

@onready var _hint: Label = $Hint
@onready var _row: HBoxContainer = $Row
@onready var _summary: Panel = $Summary
@onready var _summary_text: Label = $Summary/Text
@onready var _summary_hint: Label = $Summary/Hint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Game.changed.connect(_refresh)
	Game.phase_changed.connect(_refresh)
	Game.summary_ready.connect(_refresh)
	for i in 3:
		var card: Panel = _row.get_node("Card%d" % i)
		card.gui_input.connect(_on_card_gui.bind(i))
	_summary.gui_input.connect(_on_summary_gui)
	_refresh()


func _cards() -> Array:
	if not Game.card_override.is_empty():
		return Game.card_override
	if Game.cards.is_empty():
		return ChapterData.default_cards()
	return Game.cards


func _refresh() -> void:
	visible = Game.phase == Game.Phase.STOP or Game.phase == Game.Phase.SUMMARY
	if not visible:
		return
	if Game.phase == Game.Phase.SUMMARY:
		_row.visible = false
		_hint.visible = false
		_summary.visible = true
		var lines: PackedStringArray = PackedStringArray()
		for line in Game.summary_lines:
			lines.append(str(line))
		_summary_text.text = "\n".join(lines)
		_summary_text.add_theme_color_override("font_color", Palette.PAPER)
		_summary.add_theme_stylebox_override("panel", Palette.flat_style(Palette.INK_RAISED, Palette.DUST, 2))
		return
	_summary.visible = false
	_row.visible = true
	_hint.visible = true
	if Game.breath_left > 0.0:
		_hint.text = "ВДОХ  %.0f  ·  пыль на секунды замирает" % Game.breath_left
		_hint.add_theme_color_override("font_color", Palette.CRT)
	elif not Game.card_override.is_empty():
		_hint.text = "ПАМЯТКА  ·  лента и люди"
		_hint.add_theme_color_override("font_color", Palette.CRT_DIM)
	elif Game.level_kind == "tutorial":
		_hint.text = "ОБУЧЕНИЕ  ·  пыль выключена"
		_hint.add_theme_color_override("font_color", Palette.CRT_DIM)
	else:
		_hint.text = "ПЫЛЬ ИДЁТ  ·  жадность стоит метров"
		_hint.add_theme_color_override("font_color", Palette.RUST)
	var cards := _cards()
	var roster: bool = not Game.card_override.is_empty()
	for i in 3:
		var card: Panel = _row.get_node("Card%d" % i)
		var title_l: Label = card.get_node("Title")
		var body_l: Label = card.get_node("Body")
		if i >= cards.size():
			card.visible = false
			continue
		card.visible = true
		var data: Dictionary = cards[i]
		var cid := str(data["id"])
		title_l.text = str(data["title"])
		body_l.text = str(data["body"])
		var picked: bool = Game.picked_card == cid
		var allowed: bool = not roster and Game.action_allowed_param("pick_card", cid)
		var border := Palette.AMBER if picked else Palette.PAPER_DIM
		if not allowed and Game.picked_card == "" and not roster:
			border = Palette.JAM
		card.add_theme_stylebox_override("panel", Palette.flat_style(Palette.INK_RAISED, border, 2))
		var title_col := Palette.AMBER if picked else Palette.DUST
		var body_col := Palette.PAPER
		if not allowed and Game.picked_card == "" and not roster:
			title_col = Palette.JAM
			body_col = Palette.PAPER_DIM
		title_l.add_theme_color_override("font_color", title_col)
		body_l.add_theme_color_override("font_color", body_col)


func _on_card_gui(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if Game.phase != Game.Phase.STOP or not Game.card_override.is_empty():
		return
	var cards := _cards()
	if index < cards.size():
		Game.pick_card(str(cards[index]["id"]))


func _on_summary_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Game.phase == Game.Phase.SUMMARY:
			Game.acknowledge_summary()
