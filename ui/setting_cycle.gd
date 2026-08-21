class_name SettingCycle
extends HBoxContainer

signal changed(index: int)

@export var caption := "":
	set(value):
		caption = value
		if is_node_ready() and has_node("Caption"):
			$Caption.text = value

@export var options: PackedStringArray = []:
	set(value):
		options = value
		_refresh()

@export var index := 0:
	set(value):
		index = value
		_refresh()

@onready var _caption: Label = $Caption
@onready var _value: Label = $Value
@onready var _prev: Button = $Prev
@onready var _next: Button = $Next


func _ready() -> void:
	custom_minimum_size.y = 88
	_caption.text = caption
	_prev.pressed.connect(func() -> void: _step(-1))
	_next.pressed.connect(func() -> void: _step(1))
	_refresh()


func set_index_silent(value: int) -> void:
	index = clampi(value, 0, max(options.size() - 1, 0))
	_refresh()


func _step(dir: int) -> void:
	if options.is_empty():
		return
	index = posmod(index + dir, options.size())
	_refresh()
	changed.emit(index)


func _refresh() -> void:
	if not is_node_ready():
		return
	if index >= 0 and index < options.size():
		_value.text = options[index]
	elif caption != "":
		pass
