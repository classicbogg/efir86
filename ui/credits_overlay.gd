class_name CreditsOverlay
extends Control

signal closed

@export var url_site := "https://sielom.ru/"
@export var url_max := "https://max.ru/"
@export var url_vk := "https://vk.ru/club238929749"

@onready var _back: Button = $Back
@onready var _site: TextureButton = $Center/Box/Icons/Site
@onready var _max: TextureButton = $Center/Box/Icons/Max
@onready var _vk: TextureButton = $Center/Box/Icons/Vk


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_back.pressed.connect(close)
	_site.pressed.connect(func() -> void: _open(url_site))
	_max.pressed.connect(func() -> void: _open(url_max))
	_vk.pressed.connect(func() -> void: _open(url_vk))
	for btn in [_site, _max, _vk]:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_entered.connect(_hover.bind(btn, true))
		btn.mouse_exited.connect(_hover.bind(btn, false))


func open() -> void:
	show()
	_back.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _open(url: String) -> void:
	if url.is_empty():
		return
	OS.shell_open(url)


func _hover(btn: TextureButton, on: bool) -> void:
	btn.modulate = Color(1.08, 1.06, 0.98, 1.0) if on else Color.WHITE
