@tool
extends Control
## Ребро схемы в редакторе. from_id / to_id — id маркера.

@export var from_id: String = ""
@export var to_id: String = ""
@export var road_label: String = ""

@onready var _line: Line2D = $Line
@onready var _label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _line:
		_line.width = 2.0
		_line.default_color = Color(Palette.STEEL, 0.45)
	if _label:
		_label.add_theme_color_override("font_color", Palette.PAPER_DIM)
		_label.add_theme_font_size_override("font_size", 12)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.text = road_label
	if not Engine.is_editor_hint():
		Game.changed.connect(refresh)
	var p := get_parent()
	if p and p.get_parent() and p.get_parent() is Control:
		var map := p.get_parent() as Control
		if not map.resized.is_connected(refresh):
			map.resized.connect(refresh)
	refresh()


func refresh() -> void:
	var map := _map_root()
	if map == null:
		return
	var a: Vector2 = _marker_center(from_id)
	var b: Vector2 = _marker_center(to_id)
	if a.x < 0.0 or b.x < 0.0:
		visible = false
		return
	visible = true
	if _line:
		_line.clear_points()
		_line.add_point(a)
		_line.add_point(b)
	if _label:
		_label.text = road_label
		_label.position = a.lerp(b, 0.5) + Vector2(-18, -14)
	if Engine.is_editor_hint():
		if _line:
			_line.default_color = Color(Palette.STEEL, 0.45)
		return
	var both := Game.territory_visible(from_id) and Game.territory_visible(to_id)
	var one := Game.territory_visible(from_id) != Game.territory_visible(to_id)
	if both:
		modulate = Color.WHITE
		if _line:
			_line.default_color = Color(Palette.STEEL, 0.45)
	elif one:
		modulate = Color.WHITE
		if _line:
			_line.default_color = Color(Palette.STEEL, 0.14)
	else:
		visible = false


func _map_root() -> Control:
	var p := get_parent()
	if p == null:
		return null
	return p.get_parent() as Control


func _marker_center(id: String) -> Vector2:
	var map := _map_root()
	if map == null:
		return Vector2(-1, -1)
	var folder := map.get_node_or_null("Markers")
	if folder != null:
		for c in folder.get_children():
			if str(c.get("node_id")) == id:
				var ctrl := c as Control
				if ctrl != null:
					return ctrl.position + Vector2(16, 16)
	if not Engine.is_editor_hint() and Game.NODES.has(id):
		var pos: Vector2 = Game.NODES[id]["pos"]
		return Vector2(pos.x * map.size.x, pos.y * map.size.y)
	return Vector2(-1, -1)
