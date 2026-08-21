extends Node
## Каталог глав одной локации. Данные — ChapterData.

var _by_id: Dictionary = {}


func _ready() -> void:
	_by_id.clear()
	for def in ChapterData.all_chapters():
		_by_id[int(def["id"])] = def


func all_chapters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids: Array = _by_id.keys()
	ids.sort()
	for id in ids:
		out.append(_by_id[id])
	return out


func get_chapter(chapter_id: int) -> Dictionary:
	return _by_id.get(chapter_id, {})


func has_chapter(chapter_id: int) -> bool:
	return _by_id.has(chapter_id)


func is_unlocked(chapter_id: int) -> bool:
	return Relay.progress().is_chapter_unlocked(chapter_id)


## Совместимость со старым API уровней.
func all_levels() -> Array[Dictionary]:
	return all_chapters()


func get_level(level_id: int) -> Dictionary:
	return get_chapter(level_id)
