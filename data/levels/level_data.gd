class_name LevelData
extends Object
## Определения уровней 0 (обучение) и 1 (демо-срез).


static func all_defs() -> Array[Dictionary]:
	return [tutorial(), quarry_slice()]


static func quarry_nodes() -> Dictionary:
	return {
		"quarry": {"title": "Карьер", "pos": Vector2(0.16, 0.52), "heat": 0.7, "road": ""},
		"gas": {"title": "Соль", "pos": Vector2(0.46, 0.28), "heat": 0.15, "road": "plesh"},
		"reshetka": {"title": "Кольца", "pos": Vector2(0.50, 0.78), "heat": 0.05, "road": "yards"},
		"tower14": {"title": "Вышка 14", "pos": Vector2(0.84, 0.50), "heat": 0.35, "road": "mast"},
	}


static func quarry_edges() -> Array:
	return [
		["quarry", "gas"],
		["quarry", "reshetka"],
		["gas", "tower14"],
		["reshetka", "tower14"],
	]


static func default_cards() -> Array:
	return [
		{"id": "workshop", "title": "ФУРА", "body": "Мастерская в ленту.\nЕдет с тобой до утра.\nСоседство с антенной\nпоможет вышке."},
		{"id": "water", "title": "ДОГОВОР", "body": "Вода Кольцам.\nДвор теплее.\nСлед на густой дороге."},
		{"id": "wet_rag", "title": "ВЕЩЬ", "body": "На раму рации.\nМгла тише.\nЛомает одно правило\nдо утра: колонна ползёт."},
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
			"status": "Земля на Б. Рычаг 2.",
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
			"status": "Свои на А. Рычаг 1.",
		},
	}


static func tutorial() -> Dictionary:
	return {
		"id": 0,
		"title": "0 · Обучение",
		"blurb": "Смена, накладная, развилка, рычаг, вызов, фишка, пломба, мачта.",
		"kind": "tutorial",
		"unlock_rule": "always",
		"scenario": {
			"nodes": quarry_nodes(),
			"edges": quarry_edges(),
			"start_node": "quarry",
			"finish_node": "tower14",
			"trucks": ["housing", "clinic", "tank", "antenna"],
			"tokens": [
				{"id": "medic", "title": "Медик", "glyph": "М", "busy": false, "progress": 0.0, "target": ""},
				{"id": "tech", "title": "Техник", "glyph": "Т", "busy": false, "progress": 0.0, "target": ""},
			],
			"cards": default_cards(),
			"route_calls": default_route_calls(),
			"force_dests": ["reshetka"],
			"skip_second_call": true,
			"epilogue_max": 1,
			"status_line": "Обучение. Сначала послушай смену.",
			"breath_total": 12.0,
		},
	}


static func quarry_slice() -> Dictionary:
	return {
		"id": 1,
		"title": "1 · Карьер → 14",
		"blurb": "Демо-срез: Соль или Кольца, вызов, вышка, итог.",
		"kind": "night",
		"unlock_rule": "after:0",
		"scenario": {
			"nodes": quarry_nodes(),
			"edges": quarry_edges(),
			"start_node": "quarry",
			"finish_node": "tower14",
			"trucks": ["housing", "clinic", "tank", "antenna"],
			"tokens": [
				{"id": "medic", "title": "Медик", "glyph": "М", "busy": false, "progress": 0.0, "target": ""},
				{"id": "tech", "title": "Техник", "glyph": "Т", "busy": false, "progress": 0.0, "target": ""},
			],
			"cards": default_cards(),
			"route_calls": default_route_calls(),
			"force_dests": [],
			"skip_second_call": false,
			"epilogue_max": 3,
			"status_line": "Вдох. Одна накладная, потом дорога: Соль (плешь) или Кольца (дворы).",
			"breath_total": 8.0,
		},
	}
