@tool
extends Control
## Точка схемы — нода в редакторе. Визуал: Icon + Title + Sub. Клик → Game.choose_dest.

@export var node_id: String = ""
@export var title: String = ""
@export var subtitle: String = ""
@export_enum("hub", "settlement", "tower", "station") var kind: String = "settlement"
@export var road: String = ""
@export var heat: float = 0.0
@export var needs_repair: bool = false
@export var repair_duration: float = 8.0
@export var unlocks_on_config: PackedStringArray = PackedStringArray()
@export var icon_size: Vector2 = Vector2(32, 32)
@export var map_pos: Vector2 = Vector2(0.5, 0.5):
	set(value):
		map_pos = value.clamp(Vector2.ZERO, Vector2.ONE)
		_apply_layout()

@onready var _icon: TextureRect = $Icon
@onready var _title: Label = $Title
@onready var _sub: Label = $Sub
@onready var _ring: Panel = $Ring


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(120, 48)
	if not Engine.is_editor_hint():
		Game.changed.connect(_refresh_visual)
	_setup_static_visual()
	_apply_layout()
	var p := get_parent() as Control
	if p != null and not p.resized.is_connected(_apply_layout):
		p.resized.connect(_apply_layout)
	gui_input.connect(_on_gui_input)
	_refresh_visual()


func _setup_static_visual() -> void:
	if _icon:
		_icon.texture = Icons.node_icon(node_id)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.custom_minimum_size = icon_size
		_icon.size = icon_size
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _title:
		_title.text = title if title != "" else node_id
		_title.add_theme_color_override("font_color", Palette.PAPER)
		_title.add_theme_font_size_override("font_size", 13)
		_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _sub:
		_sub.text = subtitle
		_sub.add_theme_color_override("font_color", Palette.PAPER_DIM)
		_sub.add_theme_font_size_override("font_size", 11)
		_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _ring:
		_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ring.add_theme_stylebox_override("panel", Palette.flat_style(Color(0, 0, 0, 0), Palette.STEEL, 2))


func _refresh_visual() -> void:
	if Engine.is_editor_hint():
		if _title:
			_title.text = title if title != "" else node_id
		if _sub:
			_sub.text = subtitle
		if _icon and _icon.texture == null:
			_icon.texture = Icons.node_icon(node_id)
		return
	if not Game.level_ready:
		return
	var open := Game.territory_visible(node_id)
	modulate = Color(1, 1, 1, 1) if open else Color(1, 1, 1, 0.45)
	if _icon:
		_icon.modulate = Color.WHITE if open else Color(0.5, 0.5, 0.55, 0.7)
	var tower_st := Game.tower_status_label(node_id) if open else "закрыто"
	if _sub:
		if tower_st != "":
			_sub.text = tower_st
			var col := Palette.AMBER
			if tower_st == "настроена" or tower_st == "закрыто":
				col = Palette.CRT if tower_st == "настроена" else Palette.STEEL
			elif tower_st.begins_with("чинит"):
				col = Palette.DUST
			_sub.add_theme_color_override("font_color", col)
		else:
			_sub.text = subtitle
			_sub.add_theme_color_override("font_color", Palette.PAPER_DIM)
	if _ring:
		var border := Palette.STEEL
		if open and node_id == Game.current_node:
			border = Palette.AMBER
		elif open and node_id == Game.dest_node:
			border = Palette.AMBER
		elif open and Game.pending_mechanic_send and Game.tower_needs_repair(node_id):
			border = Palette.CRT
		elif open and Game.can_configure_tower(node_id) and node_id == Game.current_node:
			border = Palette.AMBER
		elif open and Game.phase == Game.Phase.STOP and Game.force_dests.has(node_id):
			border = Palette.CRT
		elif not open:
			border = Color(Palette.STEEL, 0.35)
		_ring.add_theme_stylebox_override("panel", Palette.flat_style(Color(0, 0, 0, 0), border, 2))
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE


func _apply_layout() -> void:
	var p := get_parent() as Control
	if p == null or p.size.x <= 1.0 or p.size.y <= 1.0:
		return
	position = Vector2(map_pos.x * p.size.x - 16.0, map_pos.y * p.size.y - 16.0)
	size = Vector2(140, 48)
	if _icon:
		_icon.position = Vector2(0, 8)
		_icon.size = icon_size
	if _ring:
		_ring.position = Vector2(-4, 4)
		_ring.size = icon_size + Vector2(8, 8)
	if _title:
		_title.position = Vector2(40, 4)
		_title.size = Vector2(100, 18)
	if _sub:
		_sub.position = Vector2(40, 24)
		_sub.size = Vector2(100, 18)


func _on_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Game.phase == Game.Phase.STOP:
			Game.choose_dest(node_id)
			accept_event()


func to_node_def() -> Dictionary:
	return {
		"title": title if title != "" else node_id,
		"subtitle": subtitle,
		"kind": kind,
		"pos": map_pos,
		"heat": heat,
		"road": road,
		"needs_repair": needs_repair,
		"repair_duration": repair_duration,
		"unlocks_on_config": Array(unlocks_on_config),
	}
