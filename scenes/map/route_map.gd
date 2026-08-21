extends Control
## Схема: маркеры/рёбра/пин/колонна — ноды. Скрипт только биндит и раскладку.

@onready var _bg: ColorRect = $Bg
@onready var _city: TextureRect = $CityMap
@onready var _dust: ColorRect = $Dust
@onready var _title: Label = $Frame/Title
@onready var _open: Label = $Frame/Open
@onready var _sub: Label = $Frame/Sub
@onready var _convoy: ColorRect = $Convoy
@onready var _pin: TextureRect = $Pin
@onready var _pin_false: ColorRect = $PinFalse


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Game.changed.connect(_refresh)
	resized.connect(_refresh)
	if _pin:
		_pin.texture = Icons.ui("pin")
		_pin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _pin_false:
		_pin_false.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh()


func collect_marker_defs() -> Dictionary:
	var out: Dictionary = {}
	var folder := get_node_or_null("Markers")
	if folder == null:
		return out
	for child in folder.get_children():
		if not child.has_method("to_node_def"):
			continue
		var nid := str(child.get("node_id"))
		if nid == "":
			continue
		out[nid] = child.to_node_def()
	return out


func _refresh() -> void:
	if _bg:
		_bg.color = Palette.INK
	if _dust:
		var dust_vis: float = Game.dust
		if Game.level_kind == "tutorial":
			_dust.visible = false
		else:
			_dust.visible = true
			if Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY:
				dust_vis = minf(dust_vis, 0.35)
			_dust.color = Color(Palette.DUST_DIM, 0.35 + dust_vis * 0.25)
			_dust.offset_right = -size.x * (1.0 - (0.10 + dust_vis * 0.42))
	if _title:
		_title.text = "СХЕМА ТРАССЫ"
		_title.add_theme_color_override("font_color", Palette.PAPER_DIM)
	if _open:
		_open.text = "открыто %d/%d" % [Game.map_territories.size(), Game.NODES.size() if not Game.NODES.is_empty() else 4]
		_open.add_theme_color_override("font_color", Palette.PAPER_DIM)
	if _sub:
		if not Game.antenna_alive:
			_sub.text = "АНТЕННА МОЛЧИТ — КАРТА ВРЁТ"
			_sub.add_theme_color_override("font_color", Palette.RUST)
		elif Game.chapter_title != "":
			_sub.text = Game.chapter_title
			_sub.add_theme_color_override("font_color", Palette.PAPER_DIM)
		elif Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY:
			_sub.text = "МАЧТА ЖИВА — ПЫЛЬ СТОИТ"
			_sub.add_theme_color_override("font_color", Palette.CRT)
		else:
			_sub.text = "развилка: Соль = плешь · Кольца = дворы"
			_sub.add_theme_color_override("font_color", Palette.PAPER_DIM)
	_layout_convoy()
	_layout_pins()
	var regions := get_node_or_null("Regions")
	if regions:
		for r in regions.get_children():
			if r.has_method("_apply_layout"):
				r._apply_layout()
				r._apply_fill()
	var edges := get_node_or_null("Edges")
	if edges:
		for e in edges.get_children():
			if e.has_method("refresh"):
				e.refresh()


func _layout_convoy() -> void:
	if _convoy == null or Game.NODES.is_empty():
		return
	var p: Vector2 = _map(Game.convoy_pos())
	_convoy.position = p - Vector2(9, 5)
	_convoy.size = Vector2(18, 10)
	_convoy.color = Palette.AMBER


func _layout_pins() -> void:
	if _pin == null:
		return
	if Game.active_call.is_empty() or Game.NODES.is_empty():
		_pin.visible = false
		if _pin_false:
			_pin_false.visible = false
		return
	var nid := str(Game.active_call.get("node", ""))
	if nid == "" or not Game.NODES.has(nid) or not Game.territory_visible(nid):
		_pin.visible = false
		return
	_pin.visible = true
	var p: Vector2 = _pt(nid) + Vector2(-10, -40)
	_pin.position = p
	_pin.size = Vector2(20, 20)
	_pin.modulate = Palette.CRT if bool(Game.active_call.get("epilogue", false)) else Palette.AMBER
	if _pin_false:
		var false_id := Game.false_pin_id()
		if false_id != "" and Game.NODES.has(false_id) and Game.territory_visible(false_id):
			_pin_false.visible = true
			_pin_false.position = _pt(false_id) + Vector2(-8, -40)
			_pin_false.size = Vector2(16, 16)
			_pin_false.modulate = Palette.JAM
		else:
			_pin_false.visible = false


func _pt(id: String) -> Vector2:
	return _map(Game.NODES[id]["pos"])


func _map(n: Vector2) -> Vector2:
	return Vector2(n.x * size.x, n.y * size.y)
