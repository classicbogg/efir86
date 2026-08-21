extends Control


func _ready() -> void:
	Game.changed.connect(_refresh_status)
	Game.demo_finished.connect(_on_finished)
	add_to_group("relay_main")
	if Game.pending_chapter_id >= 0:
		var id := Game.pending_chapter_id
		Game.pending_chapter_id = -1
		Game.pending_level_id = -1
		Game.load_chapter(id)
	elif Game.pending_level_id >= 0:
		var id := Game.pending_level_id
		Game.pending_level_id = -1
		Game.load_chapter(id)
	elif not Game.level_ready:
		Game.load_chapter(0)
	## После load: карта уже в дереве — подтянуть маркеры ещё раз (на случай порядка _ready).
	var map := $Root/Body/MapCol/RouteMap
	if map.has_method("collect_marker_defs"):
		Game.apply_editor_markers(map.collect_marker_defs())
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				Game.set_frequency("A")
			KEY_2:
				Game.set_frequency("B")
			KEY_P:
				Game.toggle_plomb()
			KEY_M:
				if Relay.progress().has_mechanic:
					Game.begin_mechanic_send()
				else:
					Game.grant_mechanic_dev()
			KEY_N:
				if Game.can_configure_tower(Game.current_node):
					Game.configure_tower(Game.current_node)
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://main-menu.tscn")


func _on_finished() -> void:
	get_tree().change_scene_to_file("res://main-menu.tscn")


func _refresh_status() -> void:
	var status: Label = $Root/Status
	status.text = Game.status_line
	var log_label: Label = $Root/Log
	log_label.text = "\n".join(Game.log_lines)
