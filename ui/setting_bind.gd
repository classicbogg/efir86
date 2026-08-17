class_name SettingBind
extends HBoxContainer

signal change_pressed

@export var caption := "":
	set(value):
		caption = value
		if is_node_ready() and has_node("Caption"):
			$Caption.text = value

@export var action_name := ""

@onready var _caption: Label = $Caption
@onready var _button: Button = $Change


func _ready() -> void:
	custom_minimum_size.y = 88
	_caption.text = caption
	_button.flat = true
	_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.pressed.connect(func() -> void: change_pressed.emit())
	set_listening(false)


func set_listening(on: bool) -> void:
	_button.text = "нажмите клавишу" if on else "Изменить →"


func refresh_key() -> void:
	set_listening(false)
