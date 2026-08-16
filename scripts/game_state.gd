extends Node
## Состояние ночи / обучения. Сценарий грузится через Relay.catalog().

signal changed
signal call_changed
signal phase_changed
signal arrived(node_id: String)
signal demo_finished
signal summary_ready
signal level_loaded(level_id: int)

enum Phase { STOP, HAUL, TOWER, EPILOGUE, SUMMARY }

var NODES: Dictionary = {}
var EDGES: Array = []

var level_id: int = -1
var level_kind: String = "night"
var finish_node: String = "tower14"
var cards: Array = []
var route_calls: Dictionary = {}
var force_dests: Array = []
var skip_second_call: bool = false
var epilogue_max: int = 3

## Пустой массив = все действия разрешены. Иначе только перечисленные.
## Примеры: pick_card, pick_card:wet_rag, choose_dest, choose_dest:reshetka,
## set_freq_A, set_freq_B, answer_0, answer_1, dispatch, dispatch:medic,
## toggle_plomb, shift_truck, ack_summary, advance
var allowed_actions: Array[String] = []
var tutorial_soft_fail: bool = false

var phase: Phase = Phase.STOP
var frequency: String = "A"
var trust: float = 0.58
var authority: float = 0.72
var haze: float = 0.18
var dust: float = 0.06
var hour: float = 0.14
var antenna_alive: bool = true
var plomb_locked: bool = true
var breath_left: float = 8.0
var breath_total: float = 8.0

var current_node: String = "quarry"
var dest_node: String = ""
var travel: float = 0.0
var haul_speed: float = 0.085
var chosen_road: String = ""
var fork_choice: String = ""

var trucks: Array[String] = []
var tokens: Array[Dictionary] = []
var svyaznoy_onboard: bool = false

var active_call: Dictionary = {}
var call_timer: float = 0.0
var call_fired: bool = false
var last_choice: String = ""
var picked_card: String = ""
var status_line: String = ""
var log_lines: PackedStringArray = PackedStringArray()

var node_heat: Dictionary = {}
var visited: Array[String] = []
var calls_heard: Array[String] = []
var calls_helped: int = 0
var calls_failed: int = 0
var epilogue_ignored: bool = false
var epilogue_queue: Array[Dictionary] = []
var rust_notches: int = 0
var demo_over: bool = false
var summary_lines: PackedStringArray = PackedStringArray()
var level_ready: bool = false
var pending_level_id: int = -1


func _ready() -> void:
	pass


func load_level(id: int) -> bool:
	var def: Dictionary = Relay.catalog().get_level(id)
	if def.is_empty():
		push_error("Unknown level %s" % id)
		return false
	reset_from_scenario(def)
	return true


func reset_from_scenario(def: Dictionary) -> void:
	level_id = int(def.get("id", -1))
	level_kind = str(def.get("kind", "night"))
	var sc: Dictionary = def.get("scenario", {})

	NODES = (sc.get("nodes", {}) as Dictionary).duplicate(true)
	EDGES = (sc.get("edges", []) as Array).duplicate(true)
	finish_node = str(sc.get("finish_node", "tower14"))
	cards = (sc.get("cards", []) as Array).duplicate(true)
	route_calls = (sc.get("route_calls", {}) as Dictionary).duplicate(true)
	force_dests = (sc.get("force_dests", []) as Array).duplicate()
	skip_second_call = bool(sc.get("skip_second_call", false))
	epilogue_max = int(sc.get("epilogue_max", 3))

	phase = Phase.STOP
	frequency = "A"
	trust = 0.58
	authority = 0.72
	haze = 0.18
	dust = 0.0 if str(def.get("kind", "night")) == "tutorial" else 0.06
	hour = 0.14
	antenna_alive = true
	plomb_locked = true
	breath_total = float(sc.get("breath_total", 8.0))
	breath_left = breath_total

	current_node = str(sc.get("start_node", "quarry"))
	dest_node = ""
	travel = 0.0
	chosen_road = ""
	fork_choice = ""

	trucks.clear()
	for t in sc.get("trucks", []):
		trucks.append(str(t))
	tokens.clear()
	for tok in sc.get("tokens", []):
		tokens.append((tok as Dictionary).duplicate(true))
	svyaznoy_onboard = false

	active_call = {}
	call_timer = 0.0
	call_fired = false
	last_choice = ""
	picked_card = ""
	status_line = str(sc.get("status_line", "Смена открыта."))
	log_lines = PackedStringArray()

	node_heat.clear()
	for nid in NODES.keys():
		node_heat[nid] = float(NODES[nid].get("heat", 0.0))
	visited = [current_node] as Array[String]
	calls_heard.clear()
	calls_helped = 0
	calls_failed = 0
	epilogue_ignored = false
	epilogue_queue.clear()
	rust_notches = 0
	demo_over = false
	summary_lines = PackedStringArray()
	allowed_actions.clear()
	tutorial_soft_fail = level_kind == "tutorial"
	level_ready = true

	_log("Смена открыта. Позывная общая. Лица нет.")
	Relay.progress().set_last_played(level_id)
	emit_signal("level_loaded", level_id)
	emit_signal("phase_changed")
	emit_signal("changed")


func set_allowed_actions(actions: Array) -> void:
	allowed_actions.clear()
	for a in actions:
		allowed_actions.append(str(a))
	emit_signal("changed")


func clear_allowed_actions() -> void:
	allowed_actions.clear()
	emit_signal("changed")


func action_allowed(action: String) -> bool:
	if allowed_actions.is_empty():
		return true
	if allowed_actions.has(action):
		return true
	# pick_card:wet_rag разрешает общий pick_card? нет — только точное или префикс
	var base := action.get_slice(":", 0)
	if allowed_actions.has(base) and action != base:
		return true
	# наоборот: разрешено pick_card:wet_rag — общий pick_card нет
	for a in allowed_actions:
		if str(a).begins_with(action + ":"):
			return true
	return false


func action_allowed_param(base: String, param: String) -> bool:
	if allowed_actions.is_empty():
		return true
	var specific := "%s:%s" % [base, param]
	if allowed_actions.has(specific):
		return true
	if allowed_actions.has(base) and not _has_specific_prefix(base):
		return true
	return false


func _has_specific_prefix(base: String) -> bool:
	for a in allowed_actions:
		if str(a).begins_with(base + ":"):
			return true
	return false


func _process(delta: float) -> void:
	if not level_ready:
		return
	if demo_over and phase == Phase.SUMMARY:
		emit_signal("changed")
		return
	if phase == Phase.EPILOGUE:
		_tick_epilogue(delta)
		emit_signal("changed")
		return
	if phase == Phase.STOP:
		if breath_left > 0.0:
			breath_left = maxf(0.0, breath_left - delta)
		elif level_kind != "tutorial":
			dust = minf(0.92, dust + delta * 0.012)
			hour = minf(0.95, hour + delta * 0.004)
		emit_signal("changed")
		return

	if phase == Phase.HAUL:
		hour = minf(0.95, hour + delta * 0.01)
		if level_kind != "tutorial":
			var dust_rate := 0.010 if picked_card == "wet_rag" else 0.018
			if chosen_road == "yards":
				dust_rate *= 1.15
			dust = minf(0.88, dust + delta * dust_rate)
		if not call_fired and travel > 0.22:
			_start_route_call()
		if not active_call.is_empty():
			call_timer = maxf(0.0, call_timer - delta)
			if call_timer <= 0.0:
				_fail_call_timeout()
		_tick_tokens(delta)
		if dest_node != "":
			var speed := haul_speed * (0.78 if picked_card == "wet_rag" else 1.0)
			if chosen_road == "yards":
				speed *= 0.82
			elif chosen_road == "plesh":
				speed *= 1.12
			travel = minf(1.0, travel + delta * speed)
			if travel >= 1.0:
				_arrive()
		emit_signal("changed")


func set_frequency(band: String) -> void:
	if band == "C":
		status_line = "Клетка В закрыта. Не на эту смену."
		emit_signal("changed")
		return
	var act := "set_freq_%s" % band
	if not action_allowed(act) and not action_allowed("set_freq"):
		status_line = "Сейчас другой шаг обучения."
		emit_signal("changed")
		return
	if band == frequency:
		return
	frequency = band
	status_line = "Рычаг на %s. Секунда слепоты." % band
	_log("Частота %s." % band)
	emit_signal("changed")


func toggle_plomb() -> void:
	if not action_allowed("toggle_plomb"):
		status_line = "Сейчас не про пломбу."
		emit_signal("changed")
		return
	if phase != Phase.STOP:
		status_line = "На перегоне пломба святая. Срыв — позже."
		emit_signal("changed")
		return
	plomb_locked = not plomb_locked
	if not plomb_locked:
		if level_kind != "tutorial":
			dust = minf(0.95, dust + 0.035)
		status_line = "Пломба сорвана. Сдвиг ленты жрёт пыль." if level_kind != "tutorial" else "Пломба сорвана. На обучении пыль спит."
	else:
		status_line = "Пломба села."
	emit_signal("changed")


func shift_truck(from_i: int, to_i: int) -> void:
	if not action_allowed("shift_truck"):
		return
	if plomb_locked or phase != Phase.STOP:
		return
	if from_i < 0 or to_i < 0 or from_i >= trucks.size() or to_i >= trucks.size():
		return
	var item: String = trucks[from_i]
	trucks.remove_at(from_i)
	trucks.insert(to_i, item)
	if level_kind != "tutorial":
		dust = minf(0.95, dust + 0.05)
		_log("Сдвиг ленты. Пыль капнула.")
	else:
		_log("Сдвиг ленты.")
	emit_signal("changed")


func pick_card(card_id: String) -> void:
	if phase != Phase.STOP or picked_card != "":
		return
	if not action_allowed_param("pick_card", card_id):
		status_line = "Возьми ту накладную, на которую указывает обучение."
		emit_signal("changed")
		return
	picked_card = card_id
	match card_id:
		"workshop":
			if not trucks.has("workshop"):
				trucks.append("workshop")
			status_line = "Мастерская в ленте. Теперь выбери дорогу: Соль или Кольца."
		"water":
			trust = minf(1.0, trust + 0.12)
			if node_heat.has("reshetka"):
				node_heat["reshetka"] = 0.55
			status_line = "Вода дворам. Кольца теплее. Выбери дорогу."
		"wet_rag":
			haze = maxf(0.05, haze - 0.08)
			status_line = "Вещь на раму: мгла тише, колонна медленнее. Выбери дорогу."
	_log("Накладная: %s." % card_id)
	emit_signal("changed")


func choose_dest(node_id: String) -> void:
	if phase != Phase.STOP:
		return
	if not action_allowed_param("choose_dest", node_id):
		status_line = "Сейчас учим другой шаг / другую дорогу."
		emit_signal("changed")
		return
	if not force_dests.is_empty() and not force_dests.has(node_id):
		status_line = "В этом срезе едем через %s." % _title_of(str(force_dests[0]))
		emit_signal("changed")
		return
	if current_node == "quarry" and node_id not in ["gas", "reshetka"]:
		status_line = "С карьера только Соль (плешь) или Кольца (дворы)."
		emit_signal("changed")
		return
	if picked_card == "":
		status_line = "Сначала одна накладная, потом дорога."
		emit_signal("changed")
		return
	if not NODES.has(node_id):
		return
	dest_node = node_id
	chosen_road = str(NODES[node_id].get("road", ""))
	if fork_choice == "" and chosen_road in ["plesh", "yards"]:
		fork_choice = chosen_road
	travel = 0.0
	call_fired = false
	phase = Phase.HAUL
	plomb_locked = true
	var road_hint := "плешь — колёса и глухота" if chosen_road == "plesh" else "дворы — люди и эфир"
	status_line = "Поехали на %s (%s). Рычаг А/Б — 1 и 2." % [NODES[node_id]["title"], road_hint]
	_log("Выехали на %s." % NODES[node_id]["title"])
	emit_signal("phase_changed")
	emit_signal("changed")


func answer_call(button_i: int) -> void:
	if active_call.is_empty():
		return
	var act := "answer_%d" % button_i
	if not action_allowed(act) and not action_allowed("answer"):
		status_line = "Сначала сделай шаг, который просит обучение."
		emit_signal("changed")
		return
	if bool(active_call.get("epilogue", false)):
		_answer_epilogue(button_i)
		return
	var need_band: String = str(active_call.get("band", "A"))
	if frequency != need_band:
		status_line = "Не та частота. Слышишь дырки. Рычаг на %s." % need_band
		emit_signal("changed")
		return
	if button_i == 0:
		active_call["text"] = str(active_call.get("clear_text", active_call.get("text", "")))
		active_call["located"] = true
		call_timer = minf(call_timer + 4.0, 14.0)
		status_line = "Повторили. Место чуть яснее. Шли человека."
		_log("Переспрос. Координата чуть жива.")
	else:
		status_line = "Шли фишку: клик по кружку на ленте."
	emit_signal("call_changed")
	emit_signal("changed")


func refuse_epilogue() -> void:
	if phase != Phase.EPILOGUE:
		return
	epilogue_ignored = true
	active_call = {}
	epilogue_queue.clear()
	trust = maxf(0.05, trust - 0.08)
	status_line = "Отказ слушать. Итог холоднее."
	_log("Мембрана закрыта молчанием.")
	_build_summary()


func dispatch(token_id: String) -> void:
	if not action_allowed_param("dispatch", token_id):
		status_line = "Не те руки. Обучение ждёт другую фишку."
		emit_signal("changed")
		return
	if active_call.is_empty():
		status_line = "Сейчас некого слать."
		emit_signal("changed")
		return
	if bool(active_call.get("epilogue", false)):
		status_line = "Под мачтой руки не нужны — только слух."
		emit_signal("changed")
		return
	var tok := _token(token_id)
	if tok.is_empty() or bool(tok["busy"]):
		return
	var need: String = str(active_call.get("need", "tech"))
	tok["busy"] = true
	tok["progress"] = 0.0
	tok["target"] = str(active_call.get("node", dest_node))
	_token_set(token_id, tok)
	status_line = "%s пошёл." % tok["title"]
	_log("%s выехал." % tok["title"])
	if token_id != need:
		authority = maxf(0.05, authority - 0.06)
		haze = minf(0.9, haze + 0.07)
		rust_notches += 1
		_log("Не та фишка. Мгла гуще.")
	emit_signal("changed")


func acknowledge_summary() -> void:
	if phase != Phase.SUMMARY:
		return
	if not action_allowed("ack_summary"):
		# в обычной ночи allowed пустой — ок; в туторе ждём явного разрешения
		if not allowed_actions.is_empty():
			status_line = "Дочитай лист, потом клик."
			emit_signal("changed")
			return
	demo_over = true
	status_line = "Ночь закрыта. Между ночами пока ничего не копим."
	Relay.progress().mark_cleared(level_id)
	emit_signal("demo_finished")
	emit_signal("changed")


func false_pin_id() -> String:
	if active_call.is_empty() or bool(active_call.get("epilogue", false)):
		return ""
	var need_band: String = str(active_call.get("band", "A"))
	if frequency == need_band and haze < 0.45:
		return ""
	var real: String = str(active_call.get("node", ""))
	for id in NODES.keys():
		if id != real and id != current_node:
			return id
	return ""


func _tick_tokens(delta: float) -> void:
	for i in tokens.size():
		var tok: Dictionary = tokens[i]
		if not bool(tok["busy"]):
			continue
		tok["progress"] = minf(1.0, float(tok["progress"]) + delta * 0.35)
		tokens[i] = tok
		if float(tok["progress"]) >= 1.0:
			_resolve_dispatch(str(tok["id"]))


func _resolve_dispatch(token_id: String) -> void:
	var tok := _token(token_id)
	tok["busy"] = false
	tok["progress"] = 0.0
	_token_set(token_id, tok)
	if active_call.is_empty():
		return
	var ok: bool = token_id == str(active_call.get("need", "")) or bool(active_call.get("located", false))
	if ok:
		trust = minf(1.0, trust + 0.08)
		authority = minf(1.0, authority + 0.04)
		haze = maxf(0.04, haze - 0.06)
		var nid := str(active_call.get("node", ""))
		if node_heat.has(nid):
			node_heat[nid] = minf(1.0, float(node_heat[nid]) + 0.25)
		calls_helped += 1
		status_line = "Доехали. Пин гаснет."
		_log("Вызов закрыт.")
	else:
		trust = maxf(0.05, trust - 0.08)
		haze = minf(0.95, haze + 0.1)
		calls_failed += 1
		rust_notches += 1
		status_line = "Не туда / не тот. Пин ржавеет."
		_log("Вызов сорван.")
	active_call = {}
	emit_signal("call_changed")
	emit_signal("changed")


func _start_route_call() -> void:
	call_fired = true
	var template: Dictionary = {}
	if route_calls.has(dest_node):
		template = (route_calls[dest_node] as Dictionary).duplicate(true)
	elif route_calls.has("gas"):
		template = (route_calls["gas"] as Dictionary).duplicate(true)
	else:
		template = {
			"band": "A",
			"node": dest_node,
			"need": "tech",
			"text": "…вызов…",
			"clear_text": "Вызов без шаблона.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
			"status": "Вызов.",
		}
	template["located"] = false
	active_call = template
	status_line = str(template.get("status", "Вызов."))
	call_timer = 16.0
	calls_heard.append(str(active_call.get("clear_text", "")))
	_log("Вызов. Частота %s." % active_call["band"])
	emit_signal("call_changed")
	emit_signal("changed")


func _fail_call_timeout() -> void:
	if active_call.is_empty():
		return
	if tutorial_soft_fail:
		call_timer = 16.0
		status_line = "Не сгорело — обучение ждёт. Ещё раз: частота и кнопки."
		_log("Таймер сброшен (обучение).")
		emit_signal("call_changed")
		emit_signal("changed")
		return
	authority = maxf(0.05, authority - 0.1)
	haze = minf(0.95, haze + 0.12)
	calls_failed += 1
	rust_notches += 1
	_log("Вызов сгорел по времени.")
	status_line = "Молчание. Вызов сгорел."
	active_call = {}
	emit_signal("call_changed")
	emit_signal("changed")


func _arrive() -> void:
	current_node = dest_node
	dest_node = ""
	travel = 0.0
	active_call = {}
	if not visited.has(current_node):
		visited.append(current_node)
	emit_signal("arrived", current_node)
	if current_node == finish_node:
		_enter_tower()
		return
	dest_node = finish_node
	chosen_road = "mast"
	travel = 0.0
	call_fired = skip_second_call
	status_line = "Проехали %s. На штампе мачта — %s." % [
		_title_of(current_node),
		_title_of(finish_node),
	]
	_log("Промежуточная. Курс на %s." % finish_node)
	emit_signal("changed")


func _enter_tower() -> void:
	phase = Phase.TOWER
	svyaznoy_onboard = true
	if _token("radio").is_empty():
		tokens.append({"id": "radio", "title": "Связной", "glyph": "С", "busy": false, "progress": 0.0, "target": ""})
	dust = minf(dust, 0.42)
	haze = maxf(0.02, haze * 0.35)
	status_line = "%s. Связной сел. Пыль встаёт…" % _title_of(finish_node)
	_log("Связной в ленте. Мембрана открывается.")
	emit_signal("phase_changed")
	emit_signal("changed")
	_start_epilogue()


func _start_epilogue() -> void:
	phase = Phase.EPILOGUE
	var pool: Array[Dictionary] = [
		{
			"band": "A",
			"node": finish_node,
			"epilogue": true,
			"text": "Слышите? Мы всю ночь орали в никуда. Спасибо, что довезли антенну.",
			"clear_text": "Слышите? Мы всю ночь орали в никуда. Спасибо, что довезли антенну.",
			"btn_a": "Слушаю",
			"btn_b": "Молчу",
		},
		{
			"band": "A",
			"node": finish_node,
			"epilogue": true,
			"text": "У двора цепь ещё лежит. Не геройство — просто голос. Утро уже режет эфир.",
			"clear_text": "У двора цепь ещё лежит. Не геройство — просто голос. Утро уже режет эфир.",
			"btn_a": "Слушаю",
			"btn_b": "Молчу",
		},
	]
	if fork_choice == "yards" or picked_card == "water":
		pool.append({
			"band": "A",
			"node": "reshetka",
			"epilogue": true,
			"text": "Кольца помнят воду. Завтрашний эфир будет чуть честнее.",
			"clear_text": "Кольца помнят воду. Завтрашний эфир будет чуть честнее.",
			"btn_a": "Слушаю",
			"btn_b": "Молчу",
		})
	epilogue_queue.clear()
	var n: int = mini(epilogue_max, pool.size())
	for i in n:
		epilogue_queue.append(pool[i])
	_next_epilogue_call()
	emit_signal("phase_changed")


func _tick_epilogue(delta: float) -> void:
	hour = minf(0.98, hour + delta * 0.002)
	if active_call.is_empty():
		return
	call_timer = maxf(0.0, call_timer - delta)
	if call_timer <= 0.0:
		epilogue_ignored = true
		_log("Бытовой голос ушёл без ответа.")
		_next_epilogue_call()


func _next_epilogue_call() -> void:
	active_call = {}
	if epilogue_queue.is_empty():
		_build_summary()
		return
	active_call = epilogue_queue.pop_front()
	call_timer = 18.0
	frequency = "A"
	calls_heard.append(str(active_call.get("clear_text", "")))
	status_line = "Пыль встала. Первый раз за ночь — слова без дырок."
	_log("Чистый эфир под мачтой.")
	emit_signal("call_changed")
	emit_signal("changed")


func _answer_epilogue(button_i: int) -> void:
	if button_i == 1:
		epilogue_ignored = true
		trust = maxf(0.05, trust - 0.04)
		_log("Отказ слушать.")
	else:
		trust = minf(1.0, trust + 0.03)
		_log("Услышал под мачтой.")
	_next_epilogue_call()


func _build_summary() -> void:
	phase = Phase.SUMMARY
	active_call = {}
	summary_lines = PackedStringArray()
	if level_kind == "tutorial":
		summary_lines.append("ОБУЧЕНИЕ ЗАКРЫТО")
		summary_lines.append("Ты услышал: накладная, развилка, рычаг, вызов, фишка, мачта.")
		summary_lines.append("Уровень 1 открыт — Карьер → 14.")
		summary_lines.append("Кликни лист — к выборке уровней.")
	else:
		var places: PackedStringArray = PackedStringArray()
		for id in visited:
			places.append(_title_of(id))
		summary_lines.append("НАКЛАДНАЯ НОЧИ")
		summary_lines.append("Проехал: %s" % ", ".join(places))
		var road_label := "—"
		if fork_choice == "plesh":
			road_label = "плешь (Соль)"
		elif fork_choice == "yards":
			road_label = "дворы (Кольца)"
		summary_lines.append("Дорога: %s" % road_label)
		summary_lines.append("Стрелки: земля %.0f%% · свои %.0f%%" % [trust * 100.0, authority * 100.0])
		summary_lines.append("Ржавые насечки: %d" % rust_notches)
		summary_lines.append("Вызовы: закрыто %d · сорвано %d" % [calls_helped, calls_failed])
		if epilogue_ignored:
			summary_lines.append("Под мачтой: часть голосов осталась без ответа.")
		else:
			summary_lines.append("Под мачтой: услышал бытовые голоса.")
		if svyaznoy_onboard:
			summary_lines.append("Связной в ленте. Слух живой.")
		summary_lines.append("Между ночами пока ничего не копим.")
	status_line = "Лист итога. Кликни накладную, чтобы закрыть смену."
	if level_kind == "tutorial":
		set_allowed_actions(["ack_summary"])
	_log("Итог — накладная, не проценты.")
	emit_signal("summary_ready")
	emit_signal("phase_changed")
	emit_signal("changed")


func convoy_pos() -> Vector2:
	if not NODES.has(current_node):
		return Vector2(0.5, 0.5)
	var a: Vector2 = NODES[current_node]["pos"]
	if dest_node == "" or not NODES.has(dest_node):
		return a
	var b: Vector2 = NODES[dest_node]["pos"]
	return a.lerp(b, travel)


func heat_of(id: String) -> float:
	return float(node_heat.get(id, 0.0))


func _title_of(id: String) -> String:
	if NODES.has(id):
		return str(NODES[id].get("title", id))
	return id


func _token(id: String) -> Dictionary:
	for tok in tokens:
		if str(tok["id"]) == id:
			return tok
	return {}


func _token_set(id: String, data: Dictionary) -> void:
	for i in tokens.size():
		if str(tokens[i]["id"]) == id:
			tokens[i] = data
			return


func _log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 8:
		log_lines.remove_at(0)
