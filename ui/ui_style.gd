class_name UiStyle
extends Object

const PAPER := Color("F4EEDB")
const CONTINUE := Color("524327")
const MUTED := Color("9F9881")


static func draw_dashed_rect(ci: CanvasItem, rect: Rect2, color: Color, dash := 3.2, gap := 2.4, width := 1.55) -> void:
	var p := rect.position
	var e := rect.end
	_dash_line(ci, p, Vector2(e.x, p.y), color, dash, gap, width)
	_dash_line(ci, Vector2(e.x, p.y), e, color, dash, gap, width)
	_dash_line(ci, e, Vector2(p.x, e.y), color, dash, gap, width)
	_dash_line(ci, Vector2(p.x, e.y), p, color, dash, gap, width)


static func _dash_line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, dash: float, gap: float, width: float) -> void:
	var delta := b - a
	var length := delta.length()
	if length <= 0.001:
		return
	var dir := delta / length
	var pos := 0.0
	var draw_dash := true
	while pos < length:
		var seg := dash if draw_dash else gap
		var next := minf(pos + seg, length)
		if draw_dash:
			ci.draw_line(a + dir * pos, a + dir * next, color, width, true)
		pos = next
		draw_dash = not draw_dash
