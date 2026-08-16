extends Control


func _ready() -> void:
	Game.changed.connect(_refresh_status)
	Game.demo_finished.connect(_on_finished)
	add_to_group("relay_main")
	if Game.pending_level_id >= 0:
		var id := Game.pending_level_id
		Game.pending_level_id = -1
		Game.load_level(id)
	elif not Game.level_ready:
		Game.load_level(0)
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
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")


func _on_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")


func _refresh_status() -> void:
	var status: Label = $Root/Status
	status.text = Game.status_line
	var log: Label = $Root/Log
	log.text = "\n".join(Game.log_lines)
