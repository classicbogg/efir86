extends Control
## Лента: пломба + слоты фур (ноды в сцене). Скрипт биндит Game.

var _drag_from: int = -1

@onready var _bg: Panel = $Bg
@onready var _title: Label = $Title
@onready var _plomb_btn: TextureButton = $Plomb
@onready var _plomb_label: Label = $PlombLabel
@onready var _trucks: HBoxContainer = $Trucks


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Game.changed.connect(_refresh)
	_plomb_btn.pressed.connect(func(): Game.toggle_plomb())
	for i in _trucks.get_child_count():
		var slot: Panel = _trucks.get_child(i)
		slot.gui_input.connect(_on_truck_gui.bind(i))
		for tok_btn in slot.get_node("Tokens").get_children():
			if tok_btn is BaseButton:
				tok_btn.pressed.connect(_on_token_pressed.bind(tok_btn))
	_refresh()


func _refresh() -> void:
	if _bg:
		_bg.add_theme_stylebox_override("panel", Palette.flat_style(Palette.INK, Palette.STEEL, 2))
	if _title:
		_title.add_theme_color_override("font_color", Palette.PAPER_DIM)
	var locked := Game.plomb_locked
	_plomb_btn.texture_normal = Icons.ui("plomb" if locked else "plomb_open")
	_plomb_label.text = "ПЛОМБА" if locked else "СОРВАНА"
	_plomb_label.add_theme_color_override("font_color", Palette.STEEL if locked else Palette.RUST)
	var n: int = Game.trucks.size()
	for i in _trucks.get_child_count():
		var slot: Panel = _trucks.get_child(i)
		if i >= n:
			slot.visible = false
			continue
		slot.visible = true
		var kind: String = Game.trucks[i]
		var col := Palette.truck_color(kind)
		if kind == "antenna" and not Game.antenna_alive:
			col = Palette.JAM
		var border := Palette.AMBER if i == _drag_from else Palette.STEEL
		slot.add_theme_stylebox_override("panel", Palette.flat_style(col.darkened(0.5), border, 2, 4))
		var icon: TextureRect = slot.get_node("Icon")
		var label: Label = slot.get_node("Label")
		icon.texture = Icons.truck(kind)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		label.text = Palette.truck_label(kind)
		label.add_theme_color_override("font_color", Palette.PAPER_DIM)
		_refresh_tokens(slot, kind)


func _home_of(token_id: String) -> String:
	var home := {"medic": "clinic", "tech": "antenna", "radio": "antenna", "mechanic": "workshop"}
	var hid := str(home.get(token_id, "housing"))
	if hid == "workshop" and not Game.trucks.has("workshop"):
		return "housing"
	return hid


func _refresh_tokens(slot: Panel, truck_kind: String) -> void:
	var box: HBoxContainer = slot.get_node("Tokens")
	var buttons: Array = box.get_children()
	var matching: Array = []
	for tok in Game.tokens:
		if _home_of(str(tok["id"])) == truck_kind:
			matching.append(tok)
	for i in buttons.size():
		var btn: Button = buttons[i]
		if i >= matching.size():
			btn.visible = false
			continue
		btn.visible = true
		var tok: Dictionary = matching[i]
		btn.set_meta("token_id", str(tok["id"]))
		btn.tooltip_text = str(tok.get("title", tok["id"]))
		btn.custom_minimum_size = Vector2(32, 32)
		var stamp: Texture2D = Icons.token(str(tok["id"]))
		var on_job: bool = str(tok.get("job", "none")) != "none"
		var busy: bool = bool(tok.get("busy", false)) or on_job
		var border := Palette.PAPER
		if on_job:
			border = Palette.CRT
		elif busy:
			border = Palette.AMBER
		elif Game.pending_mechanic_send and str(tok["id"]) == "mechanic":
			border = Palette.CRT
		if stamp:
			btn.icon = stamp
			btn.expand_icon = true
			btn.text = "%d%%" % int(float(tok.get("job_progress", 0.0)) * 100.0) if on_job else ""
		else:
			btn.icon = null
			btn.text = str(tok.get("glyph", "?"))
			if on_job:
				btn.text = "%s %d%%" % [tok.get("glyph", "?"), int(float(tok.get("job_progress", 0.0)) * 100.0)]
		btn.add_theme_stylebox_override("normal", Palette.flat_style(Palette.INK, border, 2, 16))
		btn.add_theme_color_override("font_color", Palette.PAPER)


func _on_token_pressed(btn: BaseButton) -> void:
	if btn.has_meta("token_id"):
		Game.dispatch(str(btn.get_meta("token_id")))


func _on_truck_gui(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_from = index
			_refresh()
		else:
			if _drag_from >= 0 and _drag_from != index:
				Game.shift_truck(_drag_from, index)
			_drag_from = -1
			_refresh()
