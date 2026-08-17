extends Control

const SHAKE_PAD := 56.0
const SHAKE_AMP := Vector2(28.0, 20.0)
const SHAKE_SPEED := Vector2(0.34, 0.25)
const SHAKE_SMOOTH := 2.4

@onready var music: AudioStreamPlayer = $Music
@onready var background: TextureRect = $Background
@onready var frame: Panel = $Frame
@onready var left_ui: Control = $Left
@onready var page_main: Control = $Left/Pages/Main
@onready var new_game: Button = $Left/Pages/Main/NewGame
@onready var continue_btn: Button = $Left/Pages/Main/Continue
@onready var settings_btn: Button = $Left/Pages/Main/Settings
@onready var credits_btn: Button = $Left/Pages/Main/Credits
@onready var quit_btn: Button = $Left/Pages/Main/Quit
@onready var settings_overlay: SettingsOverlay = $SettingsOverlay
@onready var credits_overlay: CreditsOverlay = $CreditsOverlay

var _shake_t := 0.0
var _shake_pos := Vector2.ZERO


func _ready() -> void:
	SettingsOverlay.ensure_buses()
	_setup_music()
	_connect_buttons()
	page_main.visible = true
	settings_overlay.closed.connect(_on_settings_closed)
	credits_overlay.closed.connect(_on_credits_closed)
	new_game.grab_focus()


func _process(delta: float) -> void:
	if not background.visible:
		return
	_shake_t += delta
	var target := Vector2(
		sin(_shake_t * SHAKE_SPEED.x) * SHAKE_AMP.x + sin(_shake_t * SHAKE_SPEED.x * 0.45) * SHAKE_AMP.x * 0.32,
		cos(_shake_t * SHAKE_SPEED.y) * SHAKE_AMP.y + sin(_shake_t * SHAKE_SPEED.y * 0.58) * SHAKE_AMP.y * 0.28
	)
	_shake_pos = _shake_pos.lerp(target, 1.0 - exp(-SHAKE_SMOOTH * delta))
	background.offset_left = -SHAKE_PAD + _shake_pos.x
	background.offset_top = -SHAKE_PAD + _shake_pos.y
	background.offset_right = SHAKE_PAD + _shake_pos.x
	background.offset_bottom = SHAKE_PAD + _shake_pos.y


func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay.visible or credits_overlay.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _setup_music() -> void:
	music.bus = "Music"
	if music.stream != null:
		music.stream.loop = true
	if not music.playing:
		music.play()


func _connect_buttons() -> void:
	new_game.pressed.connect(_on_new_game)
	continue_btn.disabled = true
	continue_btn.focus_mode = Control.FOCUS_NONE
	settings_btn.pressed.connect(_open_settings)
	credits_btn.pressed.connect(_open_credits)
	quit_btn.pressed.connect(_on_quit)


func _open_credits() -> void:
	background.visible = false
	frame.visible = false
	left_ui.visible = false
	credits_overlay.open()


func _on_credits_closed() -> void:
	background.visible = true
	frame.visible = true
	left_ui.visible = true
	credits_btn.grab_focus()


func _open_settings() -> void:
	background.visible = false
	frame.visible = false
	left_ui.visible = false
	settings_overlay.open()


func _on_settings_closed() -> void:
	background.visible = true
	frame.visible = true
	left_ui.visible = true
	_show_main()
	settings_btn.grab_focus()


func _show_main() -> void:
	page_main.visible = true


func _on_new_game() -> void:
	print("Новая игра")


func _on_quit() -> void:
	get_tree().quit()
