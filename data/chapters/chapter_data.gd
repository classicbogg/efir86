class_name ChapterData
extends Object
## Одна локация «карьерный перегон». Главы открывают территории на той же схеме.


static func world_nodes() -> Dictionary:
	return {
		"quarry": {
			"title": "Карьер",
			"subtitle": "старт колонны",
			"kind": "hub",
			"pos": Vector2(0.16, 0.52),
			"heat": 0.7,
			"road": "",
		},
		"reshetka": {
			"title": "Кольца",
			"subtitle": "посёлок · дворы",
			"kind": "settlement",
			"pos": Vector2(0.50, 0.78),
			"heat": 0.05,
			"road": "yards",
		},
		"gas": {
			"title": "Соль",
			"subtitle": "плешь · быстрая дорога",
			"kind": "settlement",
			"pos": Vector2(0.46, 0.28),
			"heat": 0.15,
			"road": "plesh",
		},
		"tower14": {
			"title": "Вышка 14",
			"subtitle": "живая мачта",
			"kind": "tower",
			"needs_repair": true,
			"repair_duration": 8.0,
			"unlocks_on_config": [],
			"pos": Vector2(0.84, 0.50),
			"heat": 0.35,
			"road": "mast",
		},
	}


static func world_edges() -> Array:
	return [
		["quarry", "gas"],
		["quarry", "reshetka"],
		["gas", "tower14"],
		["reshetka", "tower14"],
	]


static func default_cards() -> Array:
	return [
		{
			"id": "workshop",
			"title": "ФУРА",
			"body": "Мастерская в ленту.\nЕдет с тобой до утра.\nСоседство с антенной\nпоможет вышке.",
		},
		{
			"id": "water",
			"title": "ДОГОВОР",
			"body": "Вода Кольцам.\nПосёлок теплее.\nСлед на густой дороге.",
		},
		{
			"id": "wet_rag",
			"title": "ВЕЩЬ",
			"body": "На раму рации.\nМгла тише.\nКолонна ползёт\nдо утра.",
		},
	]


static func roster_cards() -> Array:
	return [
		{
			"id": "trucks",
			"title": "ЛЕНТА",
			"body": "Жильё · Лазарет · Цистерна · Антенна.\nКоробки едут с тобой.\nМастерскую можно взять\nнакладной ФУРА.",
		},
		{
			"id": "people",
			"title": "ЛЮДИ",
			"body": "М — медик (лазарет).\nТ — техник (антенна).\nМх — механик (после станции).\nКружок = кого послать.",
		},
		{
			"id": "later",
			"title": "ПОТОМ",
			"body": "Механик чинит вышку сам.\nНастройку делает игрок.\nDev: M — выдать механика.",
		},
	]


static func default_route_calls() -> Dictionary:
	return {
		"reshetka": {
			"band": "B",
			"node": "reshetka",
			"need": "medic",
			"located": false,
			"text": "нужна в-да  ..ольца  трет.. столб",
			"clear_text": "Нужна вода. Кольца, третий столб после ямы.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
			"status": "Земля на Б. Посёлок орёт. Рычаг 2.",
		},
		"tower14": {
			"band": "A",
			"node": "tower14",
			"need": "tech",
			"located": false,
			"text": "антенна св-стит  14  ..бель",
			"clear_text": "Антенна свистит. Вышка 14, кабель живой.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
			"status": "Свои на А. Вышка орёт. Рычаг 1.",
		},
		"gas": {
			"band": "A",
			"node": "gas",
			"need": "tech",
			"located": false,
			"text": "дым в р-фе  фильтр  ..сок",
			"clear_text": "Дым в рефе. Песок в фильтре, нужен техник.",
			"btn_a": "Повторите место",
			"btn_b": "Шлю кого есть",
			"status": "Свои на А. Плешь глухая. Рычаг 1.",
		},
	}


static func all_chapters() -> Array[Dictionary]:
	return [chapter_tutorial(), chapter_rings(), chapter_salt(), chapter_mast()]


static func get_chapter(chapter_id: int) -> Dictionary:
	for ch in all_chapters():
		if int(ch["id"]) == chapter_id:
			return ch
	return {}


static func base_scenario() -> Dictionary:
	return {
		"nodes": world_nodes(),
		"edges": world_edges(),
		"start_node": "quarry",
		"trucks": ["housing", "clinic", "tank", "antenna"],
		"tokens": [
			{
				"id": "medic",
				"title": "Медик",
				"glyph": "М",
				"busy": false,
				"progress": 0.0,
				"target": "",
				"job": "none",
				"job_target": "",
				"job_progress": 0.0,
			},
			{
				"id": "tech",
				"title": "Техник",
				"glyph": "Т",
				"busy": false,
				"progress": 0.0,
				"target": "",
				"job": "none",
				"job_target": "",
				"job_progress": 0.0,
			},
		],
		"cards": default_cards(),
		"route_calls": default_route_calls(),
		"breath_total": 8.0,
	}


static func chapter_tutorial() -> Dictionary:
	var sc: Dictionary = base_scenario().duplicate(true)
	sc["finish_node"] = "tower14"
	sc["force_dests"] = ["reshetka"]
	sc["skip_second_call"] = true
	sc["epilogue_max"] = 1
	sc["playable_from_quarry"] = ["reshetka"]
	sc["status_line"] = "Глава 0 · Обучение. Одна схема — карьерный перегон."
	sc["breath_total"] = 12.0
	return {
		"id": 0,
		"title": "Глава 0 · Обучение",
		"blurb": "Смена, лента, накладные, рация, посёлок Кольца.",
		"kind": "tutorial",
		"reveals_territories": ["reshetka"],
		"scenario": sc,
	}


static func chapter_rings() -> Dictionary:
	var sc: Dictionary = base_scenario().duplicate(true)
	sc["finish_node"] = "reshetka"
	sc["force_dests"] = ["reshetka"]
	sc["skip_second_call"] = true
	sc["epilogue_max"] = 0
	sc["playable_from_quarry"] = ["reshetka"]
	sc["status_line"] = "Глава 1 · Посёлок. Кольца — это дворы, не решётка на дороге."
	return {
		"id": 1,
		"title": "Глава 1 · Кольца",
		"blurb": "Посёлок на объезде. Земля на Б, медик, тепло на карте.",
		"kind": "story",
		"reveals_territories": ["gas"],
		"scenario": sc,
	}


static func chapter_salt() -> Dictionary:
	var sc: Dictionary = base_scenario().duplicate(true)
	sc["finish_node"] = "gas"
	sc["force_dests"] = ["gas"]
	sc["skip_second_call"] = true
	sc["epilogue_max"] = 0
	sc["playable_from_quarry"] = ["gas"]
	sc["status_line"] = "Глава 2 · Плешь. Соль — прямая дорога, мало людей, быстрее."
	return {
		"id": 2,
		"title": "Глава 2 · Соль",
		"blurb": "Плешь и свои на А. Техник, глухота, пыль давит сильнее.",
		"kind": "story",
		"reveals_territories": ["tower14"],
		"scenario": sc,
	}


static func chapter_mast() -> Dictionary:
	var sc: Dictionary = base_scenario().duplicate(true)
	sc["finish_node"] = "tower14"
	sc["force_dests"] = []
	sc["skip_second_call"] = false
	sc["epilogue_max"] = 3
	sc["playable_from_quarry"] = ["gas", "reshetka"]
	sc["status_line"] = "Глава 3 · Мачта. Вся схема открыта. Соль или Кольца — потом 14."
	return {
		"id": 3,
		"title": "Глава 3 · Вышка 14",
		"blurb": "Финиш демо. Связной, чистый эфир, накладная ночи.",
		"kind": "story",
		"reveals_territories": [],
		"scenario": sc,
	}
