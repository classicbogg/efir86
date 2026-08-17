extends Control
@onready var logo = $Panel/TextureRect

func _ready():
	logo.pivot_offset = logo.size / 2
	logo.modulate = Color(1, 1, 1, 0)
	logo.scale = Vector2(0.5, 0.5)
	animate_logo()
func animate_logo():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(logo, "modulate", Color(1, 1, 1, 1), 3.0)
	tween.tween_property(logo, "scale", Vector2(1.0, 1.0), 8.0).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(4.0).timeout
	var tween2 = create_tween()
	tween2.tween_property(logo, "modulate", Color(1, 1, 1, 0), 3.0)
	await tween2.finished
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://main-menu.tscn")
