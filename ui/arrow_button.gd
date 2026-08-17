@tool
class_name ArrowButton
extends Button

@export var pointing_left := true
@export var ink_color := Color("9F9881")


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(40, 40)
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)


func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var s := 12.0
	var pts: PackedVector2Array
	if pointing_left:
		pts = PackedVector2Array([
			Vector2(cx + s * 0.55, cy - s),
			Vector2(cx + s * 0.55, cy + s),
			Vector2(cx - s, cy),
		])
	else:
		pts = PackedVector2Array([
			Vector2(cx - s * 0.55, cy - s),
			Vector2(cx + s, cy),
			Vector2(cx - s * 0.55, cy + s),
		])
	var col := ink_color
	if is_hovered():
		col = col.lightened(0.12)
	draw_colored_polygon(pts, col)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()
