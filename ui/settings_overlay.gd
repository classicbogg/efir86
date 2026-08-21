class_name SettingsOverlay
extends Control

signal closed

const SETTINGS_PATH := "user://settings.cfg"

const BINDS := [
	{ "action": "frequency_switch", "key": KEY_Q },
	{ "action": "ask_again", "key": KEY_R },
	{ "action": "send", "key": KEY_SPACE },
	{ "action": "seal", "key": KEY_F },
]

@onready var _title_right: Label = %Title
@onready var _nav := {
	"video": $Margin/Window/Body/Left/Pad/VBox/Cats/Video,
	"audio": $Margin/Window/Body/Left/Pad/VBox/Cats/Audio,
	"ui": $Margin/Window/Body/Left/Pad/VBox/Cats/Interface,
	"gameplay": $Margin/Window/Body/Left/Pad/VBox/Cats/Gameplay,
	"controls": $Margin/Window/Body/Left/Pad/VBox/Cats/Controls,
}
@onready var _pages := {
	"video": %PageVideo,
	"audio": %PageAudio,
	"ui": %PageUi,
	"gameplay": %PageGameplay,
	"controls": %PageControls,
	"binds": %PageBinds,
}
@onready var _back: Button = $Margin/Window/Body/Left/Pad/VBox/Back
@onready var _window_mode: SettingCycle = %WindowMode
@onready var _aa: SettingCycle = %AntiAlias
@onready var _vsync: SettingCheck = %VSync
@onready var _music: SettingSlider = %MusicVol
@onready var _voice: SettingSlider = %VoiceVol
@onready var _noise: SettingSlider = %NoiseVol
@onready var _ui_vol: SettingSlider = %UiVol
@onready var _range: SettingCycle = %RangeMode
@onready var _ui_scale: SettingSlider = %UiScale
@onready var _colorblind: SettingCycle = %ColorBlind
@onready var _font_size: SettingCycle = %FontSize
@onready var _ui_anim: SettingCheck = %UiAnim
@onready var _difficulty: SettingCycle = %Difficulty
@onready var _hints: SettingCheck = %Hints
@onready var _language: SettingCycle = %Language
@onready var _mouse: SettingSlider = %MouseSens
@onready var _invert: SettingCheck = %InvertWheel
@onready var _keybinds_entry: SettingBind = %KeybindsEntry
@onready var _bind_rows: Array[SettingBind] = [%BindFreq, %BindAsk, %BindSend, %BindSeal]

var _data := {
	"window_mode": 0,
	"aa": 1,
	"vsync": false,
	"music": 0.8,
	"voice": 1.0,
	"noise": 0.7,
	"ui_vol": 0.6,
	"range": 0,
	"ui_scale": 1.0,
	"colorblind": 0,
	"font_size": 1,
	"ui_anim": true,
	"difficulty": 1,
	"hints": true,
	"language": 0,
	"mouse_sens": 0.5,
	"invert_wheel": false,
}

var _listening_action := ""
var _current := "video"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	ensure_buses()
	_ensure_actions()
	_load()
	_apply_to_widgets()
	_wire()
	_nav["video"].pressed.connect(func() -> void: _select("video"))
	_nav["audio"].pressed.connect(func() -> void: _select("audio"))
	_nav["ui"].pressed.connect(func() -> void: _select("ui"))
	_nav["gameplay"].pressed.connect(func() -> void: _select("gameplay"))
	_nav["controls"].pressed.connect(func() -> void: _select("controls"))
	_back.pressed.connect(_on_back)
	_select("video")
	_apply_all()


func open() -> void:
	_listening_action = ""
	show()
	_select("video")
	_nav["video"].grab_focus()


func close() -> void:
	_listening_action = ""
	_save()
	hide()
	closed.emit()


func _on_back() -> void:
	if _listening_action != "":
		_stop_listen()
		return
	if _current == "binds":
		_select("controls")
		return
	close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not visible or _listening_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_stop_listen()
		else:
			_rebind(_listening_action, event)
		get_viewport().set_input_as_handled()


func _select(id: String) -> void:
	_stop_listen()
	_current = id
	var titles := {
		"video": "Видео",
		"audio": "Аудио",
		"ui": "Интерфейс",
		"gameplay": "Геймплей",
		"controls": "Управление",
	}
	_title_right.text = titles[id]
	for key in _nav:
		_nav[key].selected = key == id
	for key in _pages:
		_pages[key].visible = key == id


func _open_keybinds() -> void:
	_stop_listen()
	_current = "binds"
	_title_right.text = "Назначение клавиш"
	for key in _nav:
		_nav[key].selected = key == "controls"
	for key in _pages:
		_pages[key].visible = key == "binds"


func _wire() -> void:
	_connect_cycle(_window_mode, "window_mode", _apply_window)
	_connect_cycle(_aa, "aa", _apply_aa)
	_connect_check(_vsync, "vsync", _apply_vsync)
	_connect_slider(_music, "music", _apply_audio)
	_connect_slider(_voice, "voice", _apply_audio)
	_connect_slider(_noise, "noise", _apply_audio)
	_connect_slider(_ui_vol, "ui_vol", _apply_audio)
	_connect_cycle(_range, "range")
	_connect_slider(_ui_scale, "ui_scale")
	_connect_cycle(_colorblind, "colorblind")
	_connect_cycle(_font_size, "font_size")
	_connect_check(_ui_anim, "ui_anim")
	_connect_cycle(_difficulty, "difficulty")
	_connect_check(_hints, "hints")
	_connect_cycle(_language, "language")
	_connect_slider(_mouse, "mouse_sens")
	_connect_check(_invert, "invert_wheel")
	_keybinds_entry.change_pressed.connect(_open_keybinds)
	for row in _bind_rows:
		var action := row.action_name
		row.change_pressed.connect(func() -> void: _start_listen(action))


func _connect_cycle(row: SettingCycle, key: String, apply: Callable = Callable()) -> void:
	row.changed.connect(func(i: int) -> void:
		_data[key] = i
		if apply.is_valid():
			apply.call()
		_save()
	)


func _connect_slider(row: SettingSlider, key: String, apply: Callable = Callable()) -> void:
	row.changed.connect(func(v: float) -> void:
		_data[key] = v
		if apply.is_valid():
			apply.call()
		_save()
	)


func _connect_check(row: SettingCheck, key: String, apply: Callable = Callable()) -> void:
	row.changed.connect(func(on: bool) -> void:
		_data[key] = on
		if apply.is_valid():
			apply.call()
		_save()
	)


func _apply_to_widgets() -> void:
	_window_mode.set_index_silent(int(_data["window_mode"]))
	_aa.set_index_silent(int(_data["aa"]))
	_vsync.set_checked_silent(bool(_data["vsync"]))
	_music.set_value_silent(float(_data["music"]))
	_voice.set_value_silent(float(_data["voice"]))
	_noise.set_value_silent(float(_data["noise"]))
	_ui_vol.set_value_silent(float(_data["ui_vol"]))
	_range.set_index_silent(int(_data["range"]))
	_ui_scale.set_value_silent(float(_data["ui_scale"]))
	_colorblind.set_index_silent(int(_data["colorblind"]))
	_font_size.set_index_silent(int(_data["font_size"]))
	_ui_anim.set_checked_silent(bool(_data["ui_anim"]))
	_difficulty.set_index_silent(int(_data["difficulty"]))
	_hints.set_checked_silent(bool(_data["hints"]))
	_language.set_index_silent(int(_data["language"]))
	_mouse.set_value_silent(float(_data["mouse_sens"]))
	_invert.set_checked_silent(bool(_data["invert_wheel"]))
	for row in _bind_rows:
		row.refresh_key()


func _start_listen(action: String) -> void:
	_listening_action = action
	for row in _bind_rows:
		row.set_listening(row.action_name == action)


func _stop_listen() -> void:
	_listening_action = ""
	for row in _bind_rows:
		row.set_listening(false)


func _rebind(action: String, event: InputEventKey) -> void:
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = event.physical_keycode
	ev.keycode = event.keycode
	InputMap.action_add_event(action, ev)
	_stop_listen()
	_save()


func _apply_all() -> void:
	_apply_window()
	_apply_aa()
	_apply_vsync()
	_apply_audio()


func _apply_window() -> void:
	match int(_data["window_mode"]):
		0:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)


func _apply_aa() -> void:
	var vp := get_viewport()
	if int(_data["aa"]) == 0:
		vp.msaa_2d = Viewport.MSAA_DISABLED
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	else:
		vp.msaa_2d = Viewport.MSAA_2X
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR


func _apply_vsync() -> void:
	if bool(_data["vsync"]):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _apply_audio() -> void:
	_set_bus("Music", float(_data["music"]))
	_set_bus("Voice", float(_data["voice"]))
	_set_bus("Noise", float(_data["noise"]))
	_set_bus("UI", float(_data["ui_vol"]))


static func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.001, 1.0)))


static func ensure_buses() -> void:
	for bus_name in ["Music", "Voice", "Noise", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _ensure_actions() -> void:
	for bind in BINDS:
		var action := String(bind["action"])
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var ev := InputEventKey.new()
			ev.physical_keycode = bind["key"] as int
			InputMap.action_add_event(action, ev)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for key in _data:
		_data[key] = cfg.get_value("game", key, _data[key])
	for bind in BINDS:
		var action := String(bind["action"])
		var code := int(cfg.get_value("binds", action, bind["key"]))
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = code as Key
		InputMap.action_add_event(action, ev)


func _save() -> void:
	var cfg := ConfigFile.new()
	for key in _data:
		cfg.set_value("game", key, _data[key])
	for bind in BINDS:
		var action := String(bind["action"])
		cfg.set_value("binds", action, _first_keycode(action, bind["key"] as int))
	cfg.save(SETTINGS_PATH)


static func _first_keycode(action: String, fallback: int) -> int:
	if not InputMap.has_action(action):
		return fallback
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return (ev as InputEventKey).physical_keycode
	return fallback
