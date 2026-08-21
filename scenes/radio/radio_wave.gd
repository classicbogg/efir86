extends Control
## Осциллограф рации — единственный _draw для волны (нода Wave в сцене).

var phase: float = 0.0


func _process(delta: float) -> void:
	if not Game.level_ready:
		return
	phase += delta * (9.0 if not Game.active_call.is_empty() else 2.2)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.05, 0.07, 0.05))
	draw_rect(rect, Palette.CRT_DIM, false, 1.0)
	var at_stop: bool = Game.phase == Game.Phase.STOP
	var at_epi: bool = Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY
	var talking: bool = not Game.active_call.is_empty() and Game.frequency == str(Game.active_call.get("band", ""))
	var col := Palette.CRT if talking else Palette.CRT_DIM
	var pts := PackedVector2Array()
	var n := 48
	for i in n:
		var t: float = float(i) / float(n - 1)
		var x: float = t * rect.size.x
		var amp: float = 18.0 if talking else 4.0
		if at_stop:
			amp = 1.6
		elif at_epi and talking:
			amp = 14.0
		elif at_epi:
			amp = 2.0
		var haze_factor: float = 0.15 if at_epi else (0.4 + Game.haze)
		var y: float = rect.size.y * 0.5 + sin(phase + t * 14.0) * amp * haze_factor
		pts.append(Vector2(x, y))
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], col, 1.6)
