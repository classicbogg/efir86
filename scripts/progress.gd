extends Node
## Прогресс unlock уровней. Файл: user://relay_progress.cfg

const PATH := "user://relay_progress.cfg"

var unlocked_ids: Array[int] = [0]
var tutorial_done: bool = false
var last_played: int = -1


func _ready() -> void:
	load_progress()


func is_unlocked(level_id: int) -> bool:
	return unlocked_ids.has(level_id)


func unlock(level_id: int) -> void:
	if unlocked_ids.has(level_id):
		return
	unlocked_ids.append(level_id)
	unlocked_ids.sort()
	save_progress()


func mark_cleared(level_id: int) -> void:
	last_played = level_id
	if level_id == 0:
		tutorial_done = true
		unlock(1)
	save_progress()


func set_last_played(level_id: int) -> void:
	last_played = level_id
	save_progress()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		unlocked_ids = [0]
		tutorial_done = false
		last_played = -1
		return
	tutorial_done = bool(cfg.get_value("progress", "tutorial_done", false))
	last_played = int(cfg.get_value("progress", "last_played", -1))
	var raw: Variant = cfg.get_value("progress", "unlocked_ids", [0])
	unlocked_ids.clear()
	if raw is Array:
		for v in raw:
			unlocked_ids.append(int(v))
	if unlocked_ids.is_empty():
		unlocked_ids = [0]
	if tutorial_done and not unlocked_ids.has(1):
		unlocked_ids.append(1)
		unlocked_ids.sort()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "tutorial_done", tutorial_done)
	cfg.set_value("progress", "last_played", last_played)
	cfg.set_value("progress", "unlocked_ids", unlocked_ids.duplicate())
	cfg.save(PATH)


func reset_all() -> void:
	unlocked_ids = [0]
	tutorial_done = false
	last_played = -1
	save_progress()
