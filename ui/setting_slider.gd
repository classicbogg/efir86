class_name SettingSlider
extends HBoxContainer

signal changed(value: float)

@export var caption := "":
	set(value):
		caption = value
		if is_node_ready() and has_node("Caption"):
			$Caption.text = value

@onready var _caption: Label = $Caption
@onready var _slider: HSlider = $Slider


func _ready() -> void:
	custom_minimum_size.y = 88
	_caption.text = caption
	_slider.value_changed.connect(func(v: float) -> void: changed.emit(v))


func set_value_silent(v: float) -> void:
	_slider.set_value_no_signal(v)
