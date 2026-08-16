extends Control
## Ведомое обучение на живой панели. Только для level_kind == tutorial.

signal step_changed(step_id: String)

enum Step {
	INTRO,
	CARD,
	PLOMB,
	FORK,
	WAIT_CALL,
	FREQ,
	REASK,
	SEND,
	DISPATCH,
	EPILOGUE,
	DONE,
}

var step: Step = Step.INTRO
var hint: String = ""
var show_advance: bool = true
var _shifted_once: bool = false
var _send_clicked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	Game.level_loaded.connect(_on_level_loaded)
	Game.changed.connect(_on_game_changed)
	Game.call_changed.connect(_on_game_changed)
	Game.phase_changed.connect(_on_game_changed)
	Game.summary_ready.connect(_on_summary)


func _on_level_loaded(_id: int) -> void:
	if Game.level_kind != "tutorial":
		visible = false
		Game.clear_allowed_actions()
		return
	visible = true
	_shifted_once = false
	_send_clicked = false
	_enter(Step.INTRO)


func _on_summary() -> void:
	if Game.level_kind != "tutorial":
		return
	_enter(Step.DONE)


func _on_game_changed() -> void:
	if not visible or Game.level_kind != "tutorial":
		return
	_check_transitions()
	queue_redraw()


func _enter(s: Step) -> void:
	step = s
	show_advance = false
	match step:
		Step.INTRO:
			hint = "Ты смена на рации. Лица нет. Живое — только зелёная волна справа."
			show_advance = true
			Game.set_allowed_actions(["advance"])
		Step.CARD:
			hint = "На столе три накладные. Возьми ВЕЩЬ — ломает одно правило до утра."
			Game.set_allowed_actions(["pick_card:wet_rag"])
		Step.PLOMB:
			hint = "Лента под пломбой. P или клик по пломбе — сорви, сдвинь коробку. Или Space — дальше. (Пыль на обучении выключена.)"
			show_advance = true
			Game.set_allowed_actions(["toggle_plomb", "shift_truck", "advance"])
		Step.FORK:
			hint = "Соль = плешь (быстро, глухо). Кольца = дворы (люди и эфир). В обучении кликни Кольца."
			Game.set_allowed_actions(["choose_dest:reshetka"])
			if not Game.plomb_locked:
				Game.plomb_locked = true
				Game.emit_signal("changed")
		Step.WAIT_CALL:
			hint = "Едем. Жди вызов — пин на схеме. Пыль появится с первой настоящей ночи."
			Game.clear_allowed_actions()
		Step.FREQ:
			hint = "Земля на Б. Рычаг 2 или клик B. Пока на А — ложная точка на карте."
			Game.set_allowed_actions(["set_freq_B"])
		Step.REASK:
			hint = "Две кнопки, не дерево. Сначала «Повторите место»."
			Game.set_allowed_actions(["answer_0"])
		Step.SEND:
			hint = "Теперь «Шлю кого есть»."
			_send_clicked = false
			Game.set_allowed_actions(["answer_1"])
		Step.DISPATCH:
			hint = "Кликни медика (М) на лазарете внизу. Чужие руки обучение не примет."
			Game.set_allowed_actions(["dispatch:medic"])
		Step.EPILOGUE:
			hint = "Мачта. Связной сел. Слова целые — Слушаю или Молчу."
			Game.set_allowed_actions(["answer_0", "answer_1"])
		Step.DONE:
			hint = "Обучение закрыто. Кликни накладную итога — откроется уровень 1."
			Game.set_allowed_actions(["ack_summary"])
	Game.status_line = hint
	emit_signal("step_changed", str(step))
	queue_redraw()


func _check_transitions() -> void:
	match step:
		Step.CARD:
			if Game.picked_card == "wet_rag":
				_enter(Step.PLOMB)
		Step.PLOMB:
			if Game.log_lines.size() > 0 and str(Game.log_lines[Game.log_lines.size() - 1]).findn("Сдвиг") >= 0:
				_shifted_once = true
			if _shifted_once:
				_enter(Step.FORK)
		Step.FORK:
			if Game.phase == Game.Phase.HAUL:
				_enter(Step.WAIT_CALL)
		Step.WAIT_CALL:
			if not Game.active_call.is_empty() and not bool(Game.active_call.get("epilogue", false)):
				_enter(Step.FREQ)
		Step.FREQ:
			if Game.frequency == "B":
				_enter(Step.REASK)
		Step.REASK:
			if bool(Game.active_call.get("located", false)):
				_enter(Step.SEND)
		Step.SEND:
			if _send_clicked or Game.status_line.findn("фишку") >= 0 or Game.status_line.findn("Шли") >= 0:
				if not Game.active_call.is_empty():
					_enter(Step.DISPATCH)
		Step.DISPATCH:
			if Game.active_call.is_empty() and Game.calls_helped > 0:
				hint = "Вызов закрыт. Доезжаем до вышки 14."
				Game.clear_allowed_actions()
			if Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY:
				if Game.phase == Game.Phase.EPILOGUE:
					_enter(Step.EPILOGUE)
		Step.EPILOGUE:
			if Game.phase == Game.Phase.SUMMARY:
				_enter(Step.DONE)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			if show_advance and Game.action_allowed("advance"):
				_advance()
				get_viewport().set_input_as_handled()


func _advance() -> void:
	match step:
		Step.INTRO:
			_enter(Step.CARD)
		Step.PLOMB:
			_enter(Step.FORK)
		_:
			pass


func _process(_delta: float) -> void:
	if not visible:
		return
	queue_redraw()


func notify_answer(button_i: int) -> void:
	if step == Step.SEND and button_i == 1:
		_send_clicked = true
		_check_transitions()


func _draw() -> void:
	if not visible:
		return
	var bar := Rect2(0, 58, size.x, 72)
	draw_rect(bar, Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.94))
	draw_line(Vector2(0, bar.end.y), Vector2(size.x, bar.end.y), Palette.CRT_DIM, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(24, bar.position.y + 22), "ОБУЧЕНИЕ · шаг %d/9" % (_step_index() + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.CRT)
	draw_multiline_string(ThemeDB.fallback_font, Vector2(24, bar.position.y + 42), hint, HORIZONTAL_ALIGNMENT_LEFT, size.x - 48, 14, -1, Palette.PAPER)
	if show_advance:
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 200, bar.position.y + 22), "Space — дальше", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.AMBER)


func _step_index() -> int:
	match step:
		Step.INTRO:
			return 0
		Step.CARD:
			return 1
		Step.PLOMB:
			return 2
		Step.FORK:
			return 3
		Step.WAIT_CALL, Step.FREQ:
			return 4
		Step.REASK:
			return 5
		Step.SEND, Step.DISPATCH:
			return 6
		Step.EPILOGUE:
			return 7
		Step.DONE:
			return 8
	return 0
