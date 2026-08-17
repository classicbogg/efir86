class_name SettingCheck
extends HBoxContainer

signal changed(on: bool)

@export var caption := "":
	set(value):
		caption = value
		if is_node_ready() and has_node("Caption"):
			$Caption.text = value

@onready var _caption: Label = $Caption
@onready var _check: SquareCheck = $Check


func _ready() -> void:
	custom_minimum_size.y = 88
	_caption.text = caption
	_check.check_changed.connect(func(on: bool) -> void: changed.emit(on))


func set_checked_silent(on: bool) -> void:
	_check.checked = on
