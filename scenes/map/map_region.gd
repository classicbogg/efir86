@tool
extends Control
## Земля на схеме. Полигон в инспекторе, клик без спавна.

@export var region_id: String = ""
@export var title: String = ""
@export var polygon_uv: PackedVector2Array = PackedVector2Array()
@export var label_uv: Vector2 = Vector2(0.5, 0.5)

@onready var _fill: Polygon2D = $Fill
@onready var _title: Label = $Title

var _hover := false
var _local_poly: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _title:
		_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_title.text = title if title != "" else region_id
		_title.add_theme_color_override("font_color", Palette.PAPER)
		_title.add_theme_font_size_override("font_size", 13)
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fill:
		_fill.z_index = -1
	if not Engine.is_editor_hint():
		Game.changed.connect(_apply_fill)
		gui_input.connect(_on_gui_input)
		set_process(true)
	else:
		set_process(false)
	var map := _map_root()
	if map != null and not map.resized.is_connected(_apply_layout):
		map.resized.connect(_apply_layout)
	_apply_layout()
	_apply_fill()


func _has_point(point: Vector2) -> bool:
	if _local_poly.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, _local_poly)


func _map_root() -> Control:
	var folder := get_parent()
	if folder == null:
		return null
	return folder.get_parent() as Control


func _scheme_rect() -> Rect2:
	var map := _map_root()
	if map == null or map.size.x <= 1.0 or map.size.y <= 1.0:
		return Rect2(Vector2.ZERO, size)
	var city := map.get_node_or_null("CityMap") as TextureRect
	if city == null or city.texture == null:
		return Rect2(Vector2.ZERO, map.size)
	var ts: Vector2 = city.texture.get_size()
	var cs: Vector2 = map.size
	if ts.x <= 1.0 or ts.y <= 1.0:
		return Rect2(Vector2.ZERO, cs)
	var s: float = minf(cs.x / ts.x, cs.y / ts.y)
	var disp := ts * s
	return Rect2((cs - disp) * 0.5, disp)


func _apply_layout() -> void:
	var rect := _scheme_rect()
	_local_poly = PackedVector2Array()
	for uv in polygon_uv:
		_local_poly.append(rect.position + Vector2(uv.x * rect.size.x, uv.y * rect.size.y))
	if _fill:
		_fill.polygon = _local_poly
	if _title:
		var p: Vector2 = rect.position + Vector2(label_uv.x * rect.size.x, label_uv.y * rect.size.y)
		_title.size = Vector2(120, 20)
		_title.position = p - Vector2(60, 10)
		_title.text = title if title != "" else region_id
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var over := get_viewport().gui_get_hovered_control() == self
	if over != _hover:
		_hover = over
		_apply_fill()


func _land_color() -> Color:
	match region_id:
		"city":
			return Palette.DUST
		"reshetka":
			return Palette.CRT_DIM
		"waste":
			return Palette.PAPER_DIM
		"quarry":
			return Palette.DUST_DIM
		"mountain":
			return Palette.STEEL
		"industry":
			return Palette.JAM
		_:
			return Palette.STEEL


func _apply_fill() -> void:
	if _fill == null:
		return
	var a := 0.10
	if not Engine.is_editor_hint() and Game.level_ready and Game.selected_region == region_id:
		a = 0.38
	elif _hover:
		a = 0.24
	_fill.color = Color(_land_color(), a)
	if _title:
		var picked := not Engine.is_editor_hint() and Game.level_ready and Game.selected_region == region_id
		_title.add_theme_color_override("font_color", Palette.AMBER if picked else Palette.PAPER)


func _on_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Game.select_region(region_id)
		accept_event()
