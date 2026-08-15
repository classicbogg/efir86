extends Control


func _ready() -> void:
	Game.changed.connect(_refresh_status)
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


func _refresh_status() -> void:
	var status: Label = $Root/Status
	status.text = Game.status_line
	var log: Label = $Root/Log
	log.text = "\n".join(Game.log_lines)
