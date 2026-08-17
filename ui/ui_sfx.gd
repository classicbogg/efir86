extends Node

const NAV_PATH := "res://assets/sounds/nav.MP3"
const CLICK_PATH := "res://assets/sounds/click.MP3"

var _nav: AudioStreamPlayer
var _click: AudioStreamPlayer
var _hooked: Dictionary = {}


func _ready() -> void:
	SettingsOverlay.ensure_buses()
	_nav = AudioStreamPlayer.new()
	_nav.bus = "UI"
	add_child(_nav)
	_click = AudioStreamPlayer.new()
	_click.bus = "UI"
	add_child(_click)
	_nav.stream = _load_stream(NAV_PATH)
	_click.stream = _load_stream(CLICK_PATH)


func hook(btn: BaseButton, hover_sound := true) -> void:
	if Engine.is_editor_hint() or btn == null or _hooked.has(btn):
		return
	_hooked[btn] = true
	if hover_sound:
		btn.mouse_entered.connect(func() -> void: hover(btn))
	btn.pressed.connect(click)
	btn.tree_exiting.connect(func() -> void: _hooked.erase(btn))


func hover(who: Object = null) -> void:
	if who is BaseButton and (who as BaseButton).disabled:
		return
	_play(_nav, NAV_PATH)


func click() -> void:
	_play(_click, CLICK_PATH)


func _play(player: AudioStreamPlayer, path: String) -> void:
	if player == null:
		return
	if player.stream == null:
		player.stream = _load_stream(path)
	if player.stream == null:
		return
	if player.playing:
		player.stop()
	player.play()


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null
