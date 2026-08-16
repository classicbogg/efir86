extends Node
## Реестр уровней. Данные — LevelData.

var _by_id: Dictionary = {}


func _ready() -> void:
	_by_id.clear()
	for def in LevelData.all_defs():
		_by_id[int(def["id"])] = def


func all_levels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids: Array = _by_id.keys()
	ids.sort()
	for id in ids:
		out.append(_by_id[id])
	return out


func get_level(level_id: int) -> Dictionary:
	return _by_id.get(level_id, {})


func has_level(level_id: int) -> bool:
	return _by_id.has(level_id)


func is_unlocked(level_id: int) -> bool:
	var def: Dictionary = get_level(level_id)
	if def.is_empty():
		return false
	if str(def.get("unlock_rule", "always")) == "always":
		return true
	return Relay.progress().is_unlocked(level_id)
