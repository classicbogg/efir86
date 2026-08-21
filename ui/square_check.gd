@tool
class_name SquareCheck
extends Button

signal check_changed(on: bool)

@export var box_size := 36.0
@export var ink_color := Color("9F9881")
@export var checked := false:
	set(value):
		checked = value
		set_pressed_no_signal(value)
		queue_redraw()


func _ready() -> void:
	flat = true
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(box_size + 4.0, box_size + 4.0)
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("hover_pressed", empty)
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)


func _on_toggled(on: bool) -> void:
	checked = on
	check_changed.emit(on)


func _draw() -> void:
	var sq := minf(size.x, size.y) - 4.0
	var r := Rect2(Vector2((size.x - sq) * 0.5, (size.y - sq) * 0.5), Vector2(sq, sq))
	UiStyle.draw_dashed_rect(self, r, ink_color, sq * 0.16, sq * 0.11, maxf(1.85, sq * 0.055))
	if checked:
		draw_rect(r.grow(-sq * 0.22), ink_color, true)
