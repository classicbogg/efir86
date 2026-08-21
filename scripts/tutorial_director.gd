extends Control
## Ведомое обучение на живой панели. Только для level_kind == tutorial.

signal step_changed(step_id: String)

enum Step {
	INTRO,
	ROSTER,
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
var _waybills: Control = null
@onready var _bar: Panel = $Bar
@onready var _step_label: Label = $Bar/Step
@onready var _hint_label: Label = $Bar/Hint
@onready var _advance_label: Label = $Bar/Advance


func _set_waybills_mouse_enabled(enabled: bool) -> void:
	if _waybills == null:
		return
	_waybills.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_waybills = get_tree().root.find_child("Waybills", true, false)
	Game.level_loaded.connect(_on_level_loaded)
	Game.changed.connect(_on_game_changed)
	Game.call_changed.connect(_on_game_changed)
	Game.phase_changed.connect(_on_game_changed)
	Game.summary_ready.connect(_on_summary)
	_refresh_bar()


func _on_level_loaded(_id: int) -> void:
	if Game.level_kind != "tutorial":
		visible = false
		if _bar:
			_bar.visible = false
		Game.clear_allowed_actions()
		Game.clear_card_override()
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
	_refresh_bar()


func _enter(s: Step) -> void:
	step = s
	show_advance = false
	# На шагах, где нужен клик по карте, панель накладных не должна перехватывать mouse_button.
	_set_waybills_mouse_enabled(step == Step.CARD or step == Step.DONE)
	match step:
		Step.INTRO:
			hint = "Одна схема — карьерный перегон. Сначала только карьер. Территории откроются по главам."
			show_advance = true
			Game.clear_card_override()
			Game.set_allowed_actions(["advance"])
		Step.ROSTER:
			hint = "Лента, люди, будущие роли. Прочитай три карточки — это не накладные, а памятка."
			show_advance = true
			Game.set_card_override(Game.roster_cards)
			Game.set_allowed_actions(["advance"])
		Step.CARD:
			hint = "Теперь настоящие накладные. Возьми ВЕЩЬ — ломает одно правило до утра."
			Game.clear_card_override()
			Game.set_allowed_actions(["pick_card:wet_rag"])
		Step.PLOMB:
			hint = "Лента под пломбой. P или клик по пломбе — сорви, сдвинь коробку. Или Space — дальше. (Пыль на обучении выключена.)"
			show_advance = true
			Game.set_allowed_actions(["toggle_plomb", "shift_truck", "advance"])
		Step.FORK:
			hint = "На схеме открылся посёлок Кольца (дворы). Соль = плешь (быстро, глухо). Кликни Кольца."
			Game.reveal_territory("reshetka")
			Game.set_allowed_actions(["choose_dest:reshetka"])
			if not Game.plomb_locked:
				Game.plomb_locked = true
				Game.emit_signal("changed")
		Step.WAIT_CALL:
			hint = "Едем. Жди вызов — пин на схеме. Пыль появится с первой настоящей ночью."
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
			hint = "Кликни МЕДИК на рации справа. Или М на лазарете внизу."
			Game.set_allowed_actions(["dispatch:medic"])
		Step.EPILOGUE:
			hint = "Мачта. Связной сел. Слова целые — Слушаю или Молчу."
			Game.set_allowed_actions(["answer_0", "answer_1"])
		Step.DONE:
			hint = "Обучение закрыто. Кликни накладную итога — откроется глава 1."
			Game.clear_card_override()
			Game.set_allowed_actions(["ack_summary"])
	Game.status_line = hint
	emit_signal("step_changed", str(step))
	_refresh_bar()


func _refresh_bar() -> void:
	if _bar == null:
		return
	_bar.visible = visible and Game.level_kind == "tutorial"
	if not _bar.visible:
		return
	_bar.add_theme_stylebox_override("panel", Palette.flat_style(Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.94), Palette.CRT_DIM, 2))
	if _step_label:
		_step_label.text = "ОБУЧЕНИЕ · шаг %d/10" % (_step_index() + 1)
		_step_label.add_theme_color_override("font_color", Palette.CRT)
	if _hint_label:
		_hint_label.text = hint
		_hint_label.add_theme_color_override("font_color", Palette.PAPER)
	if _advance_label:
		_advance_label.visible = show_advance
		_advance_label.text = "Space — дальше"
		_advance_label.add_theme_color_override("font_color", Palette.AMBER)


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
			_enter(Step.ROSTER)
		Step.ROSTER:
			_enter(Step.CARD)
		Step.PLOMB:
			_enter(Step.FORK)
		_:
			pass


func _process(_delta: float) -> void:
	pass


func notify_answer(button_i: int) -> void:
	if step == Step.SEND and button_i == 1:
		_send_clicked = true
		_check_transitions()


func _step_index() -> int:
	match step:
		Step.INTRO:
			return 0
		Step.ROSTER:
			return 1
		Step.CARD:
			return 2
		Step.PLOMB:
			return 3
		Step.FORK:
			return 4
		Step.WAIT_CALL, Step.FREQ:
			return 5
		Step.REASK:
			return 6
		Step.SEND, Step.DISPATCH:
			return 7
		Step.EPILOGUE:
			return 8
		Step.DONE:
			return 9
	return 0
