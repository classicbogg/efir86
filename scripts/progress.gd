extends Node
## Прогресс по главам одной локации + мета (механик, состояния вышек).
## Файл: user://relay_progress.cfg

const PATH := "user://relay_progress.cfg"
const START_TERRITORIES: Array[String] = ["quarry"]

var map_territories: Array[String] = ["quarry"]
var completed_chapters: Array[int] = []
var current_chapter: int = 0
var has_save: bool = false

## Мета: механик открывается на станции (фаза 2). Пока — grant_mechanic / M.
var has_mechanic: bool = false
## id вышки → { "repair_done": bool, "config_done": bool }
var tower_states: Dictionary = {}


func _ready() -> void:
	load_progress()


func is_chapter_unlocked(chapter_id: int) -> bool:
	if chapter_id == 0:
		return true
	return completed_chapters.has(chapter_id - 1)


func is_chapter_done(chapter_id: int) -> bool:
	return completed_chapters.has(chapter_id)


func territory_visible(node_id: String) -> bool:
	return map_territories.has(node_id)


func mark_chapter_cleared(chapter_id: int) -> void:
	if not completed_chapters.has(chapter_id):
		completed_chapters.append(chapter_id)
		completed_chapters.sort()
	var def: Dictionary = ChapterData.get_chapter(chapter_id)
	for tid in def.get("reveals_territories", []):
		unlock_territory(str(tid))
	if chapter_id + 1 <= 3:
		current_chapter = chapter_id + 1
	else:
		current_chapter = chapter_id
	has_save = true
	save_progress()


func unlock_territory(node_id: String) -> void:
	if map_territories.has(node_id):
		return
	map_territories.append(node_id)
	map_territories.sort_custom(func(a, b): return _territory_order(a) < _territory_order(b))
	save_progress()


func set_current_chapter(chapter_id: int) -> void:
	current_chapter = chapter_id
	has_save = true
	save_progress()


func grant_mechanic() -> bool:
	if has_mechanic:
		return false
	has_mechanic = true
	has_save = true
	save_progress()
	return true


func tower_state(node_id: String) -> Dictionary:
	if not tower_states.has(node_id):
		tower_states[node_id] = {"repair_done": false, "config_done": false}
	return tower_states[node_id]


func is_tower_repair_done(node_id: String) -> bool:
	return bool(tower_state(node_id).get("repair_done", false))


func is_tower_config_done(node_id: String) -> bool:
	return bool(tower_state(node_id).get("config_done", false))


func set_tower_repair_done(node_id: String, done: bool = true) -> void:
	var st: Dictionary = tower_state(node_id)
	st["repair_done"] = done
	tower_states[node_id] = st
	has_save = true
	save_progress()


func set_tower_config_done(node_id: String, done: bool = true) -> void:
	var st: Dictionary = tower_state(node_id)
	st["config_done"] = done
	tower_states[node_id] = st
	has_save = true
	save_progress()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		_reset_runtime()
		return
	has_save = bool(cfg.get_value("progress", "has_save", false))
	current_chapter = int(cfg.get_value("progress", "current_chapter", 0))
	has_mechanic = bool(cfg.get_value("progress", "has_mechanic", false))
	var done_raw: Variant = cfg.get_value("progress", "completed_chapters", [])
	completed_chapters.clear()
	if done_raw is Array:
		for v in done_raw:
			completed_chapters.append(int(v))
	var terr_raw: Variant = cfg.get_value("progress", "map_territories", START_TERRITORIES.duplicate())
	map_territories.clear()
	if terr_raw is Array:
		for v in terr_raw:
			map_territories.append(str(v))
	if map_territories.is_empty():
		map_territories = START_TERRITORIES.duplicate()
	tower_states.clear()
	var towers_raw: Variant = cfg.get_value("progress", "tower_states", {})
	if towers_raw is Dictionary:
		for k in towers_raw.keys():
			var raw: Variant = towers_raw[k]
			if raw is Dictionary:
				tower_states[str(k)] = {
					"repair_done": bool(raw.get("repair_done", false)),
					"config_done": bool(raw.get("config_done", false)),
				}
	_apply_chapter_unlocks()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "has_save", has_save)
	cfg.set_value("progress", "current_chapter", current_chapter)
	cfg.set_value("progress", "completed_chapters", completed_chapters.duplicate())
	cfg.set_value("progress", "map_territories", map_territories.duplicate())
	cfg.set_value("progress", "has_mechanic", has_mechanic)
	cfg.set_value("progress", "tower_states", tower_states.duplicate(true))
	cfg.save(PATH)


func reset_all() -> void:
	_reset_runtime()
	save_progress()


func _reset_runtime() -> void:
	map_territories = START_TERRITORIES.duplicate()
	completed_chapters.clear()
	current_chapter = 0
	has_save = false
	has_mechanic = false
	tower_states.clear()


func _apply_chapter_unlocks() -> void:
	for ch in completed_chapters:
		var def: Dictionary = ChapterData.get_chapter(int(ch))
		for tid in def.get("reveals_territories", []):
			if not map_territories.has(str(tid)):
				map_territories.append(str(tid))
	map_territories.sort_custom(func(a, b): return _territory_order(a) < _territory_order(b))


func _territory_order(node_id: String) -> int:
	match node_id:
		"quarry":
			return 0
		"reshetka":
			return 1
		"gas":
			return 2
		"tower14":
			return 3
		_:
			return 99
