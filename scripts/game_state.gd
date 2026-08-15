extends Node
## Состояние демо-среза. Без меты, без частоты В.

signal changed
signal call_changed
signal phase_changed
signal arrived(node_id: String)
signal demo_finished

enum Phase { STOP, HAUL, TOWER }

const NODES := {
	"quarry": {"title": "Карьер", "pos": Vector2(0.16, 0.52), "heat": 0.7},
	"gas": {"title": "Заправка", "pos": Vector2(0.46, 0.28), "heat": 0.15},
	"reshetka": {"title": "Решётка", "pos": Vector2(0.50, 0.78), "heat": 0.05},
	"tower14": {"title": "Вышка 14", "pos": Vector2(0.84, 0.50), "heat": 0.35},
}

const EDGES := [
	["quarry", "gas"],
	["quarry", "reshetka"],
	["gas", "tower14"],
	["reshetka", "tower14"],
]

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

var trucks: Array[String] = ["housing", "clinic", "tank", "antenna"]
var tokens: Array[Dictionary] = [
	{"id": "medic", "title": "Медик", "glyph": "М", "busy": false, "progress": 0.0, "target": ""},
	{"id": "tech", "title": "Техник", "glyph": "Т", "busy": false, "progress": 0.0, "target": ""},
]
var svyaznoy_onboard: bool = false

var active_call: Dictionary = {}
var call_timer: float = 0.0
var call_fired: bool = false
var last_choice: String = ""
var picked_card: String = ""
var status_line: String = "Вдох. Выбери дорогу на карте и одну накладную."
var log_lines: PackedStringArray = PackedStringArray()

var node_heat: Dictionary = {}
var demo_over: bool = false


func _ready() -> void:
	for id in NODES.keys():
		node_heat[id] = NODES[id]["heat"]
	_log("Смена открыта. Частота общая. Лица нет.")


func _process(delta: float) -> void:
	if demo_over:
		return
	if phase == Phase.STOP:
		if breath_left > 0.0:
			breath_left = maxf(0.0, breath_left - delta)
		else:
			dust = minf(0.92, dust + delta * 0.012)
			hour = minf(0.95, hour + delta * 0.004)
		emit_signal("changed")
		return

	if phase == Phase.HAUL:
		hour = minf(0.95, hour + delta * 0.01)
		var dust_rate := 0.010 if picked_card == "wet_rag" else 0.018
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
			travel = minf(1.0, travel + delta * speed)
			if travel >= 1.0:
				_arrive()
		emit_signal("changed")


func set_frequency(band: String) -> void:
	if band == frequency:
		return
	frequency = band
	status_line = "Рычаг на %s. Секунда слепоты." % band
	_log("Частота %s." % band)
	emit_signal("changed")


func toggle_plomb() -> void:
	if phase != Phase.STOP:
		status_line = "На перегоне пломба святая. Срыв — позже."
		emit_signal("changed")
		return
	plomb_locked = not plomb_locked
	if not plomb_locked:
		dust = minf(0.95, dust + 0.035)
		status_line = "Пломба сорвана. Сдвиг ленты жрёт пыль."
	else:
		status_line = "Пломба села."
	emit_signal("changed")


func shift_truck(from_i: int, to_i: int) -> void:
	if plomb_locked or phase != Phase.STOP:
		return
	if from_i < 0 or to_i < 0 or from_i >= trucks.size() or to_i >= trucks.size():
		return
	var item: String = trucks[from_i]
	trucks.remove_at(from_i)
	trucks.insert(to_i, item)
	dust = minf(0.95, dust + 0.05)
	_log("Сдвиг ленты. Пыль капнула.")
	emit_signal("changed")


func pick_card(card_id: String) -> void:
	if phase != Phase.STOP or picked_card != "":
		return
	picked_card = card_id
	match card_id:
		"workshop":
			if not trucks.has("workshop"):
				trucks.append("workshop")
			status_line = "Мастерская в ленте. Теперь выбери дорогу."
		"water":
			trust = minf(1.0, trust + 0.12)
			node_heat["reshetka"] = 0.55
			status_line = "Вода земле. Решётка теплее. Выбери дорогу."
		"wet_rag":
			haze = maxf(0.05, haze - 0.08)
			status_line = "Мокрая тряпка: мгла тише, колонна медленнее. Выбери дорогу."
	_log("Накладная: %s." % card_id)
	emit_signal("changed")


func choose_dest(node_id: String) -> void:
	if phase != Phase.STOP:
		return
	if current_node == "quarry" and node_id not in ["gas", "reshetka"]:
		status_line = "С карьера только Заправка или Решётка."
		emit_signal("changed")
		return
	if picked_card == "":
		status_line = "Сначала одна накладная, потом дорога."
		emit_signal("changed")
		return
	dest_node = node_id
	travel = 0.0
	call_fired = false
	phase = Phase.HAUL
	plomb_locked = true
	status_line = "Поехали на %s. Рычаг А/Б — клавиши 1 и 2." % NODES[node_id]["title"]
	_log("Выехали на %s." % NODES[node_id]["title"])
	emit_signal("phase_changed")
	emit_signal("changed")


func answer_call(button_i: int) -> void:
	if active_call.is_empty():
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


func dispatch(token_id: String) -> void:
	if active_call.is_empty():
		status_line = "Сейчас некого слать."
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
		_log("Не та фишка. Мгла гуще.")
	emit_signal("changed")


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
		status_line = "Доехали. Пин гаснет."
		_log("Вызов закрыт.")
	else:
		trust = maxf(0.05, trust - 0.08)
		haze = minf(0.95, haze + 0.1)
		status_line = "Не туда / не тот. Пин ржавеет."
		_log("Вызов сорван.")
	active_call = {}
	emit_signal("call_changed")
	emit_signal("changed")


func _start_route_call() -> void:
	call_fired = true
	if dest_node == "reshetka":
		active_call = {
			"band": "B",
			"node": "reshetka",
			"need": "medic",
			"located": false,
			"text": "нужна в-да  ..еш-тка  трет.. столб",
			"clear_text": "Нужна вода. Решётка, третий столб после ямы.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
		}
		status_line = "Земля на Б. Рычаг 2."
	elif dest_node == "tower14":
		active_call = {
			"band": "A",
			"node": "tower14",
			"need": "tech",
			"located": false,
			"text": "антенна св-стит  14  ..бель",
			"clear_text": "Антенна свистит. Вышка 14, кабель живой.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
		}
		status_line = "Свои на А. Вышка орёт. Рычаг 1."
	else:
		active_call = {
			"band": "A",
			"node": "gas",
			"need": "tech",
			"located": false,
			"text": "дым в р-фе  фильтр  ..сок",
			"clear_text": "Дым в рефе. Песок в фильтре, нужен техник.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
		}
		status_line = "Свои на А. Рычаг 1."
	call_timer = 16.0
	_log("Вызов. Частота %s." % active_call["band"])
	emit_signal("call_changed")
	emit_signal("changed")


func _fail_call_timeout() -> void:
	if active_call.is_empty():
		return
	authority = maxf(0.05, authority - 0.1)
	haze = minf(0.95, haze + 0.12)
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
	emit_signal("arrived", current_node)
	if current_node == "tower14":
		_finish_demo()
		return
	# второй перегон — на вышку
	dest_node = "tower14"
	travel = 0.0
	call_fired = false
	status_line = "Проехали %s. Дальше вышка 14." % NODES[current_node]["title"]
	_log("Промежуточная. Курс на 14.")
	emit_signal("changed")


func _finish_demo() -> void:
	phase = Phase.TOWER
	svyaznoy_onboard = true
	tokens.append({"id": "radio", "title": "Связной", "glyph": "С", "busy": false, "progress": 0.0, "target": ""})
	demo_over = true
	status_line = "Вышка 14. Связной сел. Демо-срез закрыт."
	_log("Связной в ленте. Срез карьера закрыт.")
	emit_signal("phase_changed")
	emit_signal("demo_finished")
	emit_signal("changed")


func convoy_pos() -> Vector2:
	var a: Vector2 = NODES[current_node]["pos"]
	if dest_node == "" or not NODES.has(dest_node):
		return a
	var b: Vector2 = NODES[dest_node]["pos"]
	return a.lerp(b, travel)


func heat_of(id: String) -> float:
	return float(node_heat.get(id, 0.0))


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
