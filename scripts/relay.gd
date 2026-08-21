class_name Relay
extends Object
## Доступ к autoload без глобальных идентификаторов (чтобы парсер Godot не сыпал помидорами).


static func progress() -> Node:
	return _root().get_node("Progress")


static func catalog() -> Node:
	return _root().get_node("LevelCatalog")


static func game() -> Node:
	return _root().get_node("Game")


static func ui_sfx() -> Node:
	return _root().get_node_or_null("UiSfx")


static func _root() -> Node:
	return Engine.get_main_loop().root
