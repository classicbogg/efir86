@tool
class_name MenuRow
extends Button

@export var marker_size := 34.0
@export var marker_gap := 32.0
@export var fill_on_hover := true
@export var ink_color := Color("F4EEDB")
@export var selected_color := Color("F4EEDB")
@export var disabled_color := Color("524327")
@export var selected := false:
	set(value):
		selected = value
		_refresh()

var _fill_tween: Tween
var _fill_alpha := 0.0:
	set(value):
		_fill_alpha = value
		queue_redraw()


func _ready() -> void:
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	custom_minimum_size = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	_apply_padding()
	_refresh()
	reset_size()
	if not Engine.is_editor_hint():
		UiSfx.hook(self)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_tween_fill(not disabled)
			_refresh()
		NOTIFICATION_MOUSE_EXIT:
			_tween_fill(false)
			_refresh()
		NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT, NOTIFICATION_RESIZED:
			_refresh()


func _draw() -> void:
	var sq := marker_size
	var y := (size.y - sq) * 0.5
	var rect := Rect2(Vector2(0.0, y), Vector2(sq, sq))
	var col := _ink()
	var dash := marker_size * 0.16
	var gap := marker_size * 0.11
	var width := maxf(1.85, marker_size * 0.055)
	UiStyle.draw_dashed_rect(self, rect, col, dash, gap, width)
	if _fill_alpha > 0.01:
		var fill_col := col
		fill_col.a *= _fill_alpha
		draw_rect(rect.grow(-marker_size * 0.22), fill_col, true)


func _tween_fill(on: bool) -> void:
	var target := 1.0 if on else 0.0
	if Engine.is_editor_hint():
		_fill_alpha = target
		return
	if _fill_tween:
		_fill_tween.kill()
	_fill_tween = create_tween()
	_fill_tween.set_ease(Tween.EASE_OUT)
	_fill_tween.set_trans(Tween.TRANS_QUAD)
	_fill_tween.tween_property(self, "_fill_alpha", target, 0.14)


func _ink() -> Color:
	if disabled:
		return disabled_color
	if selected:
		return selected_color
	return ink_color


func _refresh() -> void:
	var col := _ink()
	add_theme_color_override("font_color", col)
	add_theme_color_override("font_hover_color", col)
	add_theme_color_override("font_focus_color", col)
	add_theme_color_override("font_pressed_color", col)
	add_theme_color_override("font_disabled_color", disabled_color)
	_apply_padding()
	queue_redraw()


func _apply_padding() -> void:
	var box := StyleBoxEmpty.new()
	box.content_margin_left = marker_size + marker_gap
	box.content_margin_top = 10.0
	box.content_margin_right = 8.0
	box.content_margin_bottom = 10.0
	add_theme_stylebox_override("normal", box)
	add_theme_stylebox_override("hover", box)
	add_theme_stylebox_override("pressed", box)
	add_theme_stylebox_override("focus", box)
	add_theme_stylebox_override("disabled", box)
