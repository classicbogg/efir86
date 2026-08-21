extends Control
## Шапка: только биндинг Game → ноды. Визуал в сцене.

@onready var _bg: ColorRect = $Bg
@onready var _title: Label = $Title
@onready var _sub: Label = $Sub
@onready var _hour_fill: ColorRect = $HourBar/Fill
@onready var _hour_label: Label = $HourBar/Label
@onready var _trust_fill: ColorRect = $Trust/Fill
@onready var _auth_fill: ColorRect = $Auth/Fill


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _bg:
		_bg.color = Palette.INK
	if _title:
		_title.text = "RELAY"
		_title.add_theme_color_override("font_color", Palette.PAPER)
	var sub := "ночное радио колонны"
	if Game.chapter_id == 0:
		sub = "глава 0 · обучение"
	elif Game.chapter_id >= 0:
		sub = "%s  ·  %d/%d на схеме" % [
			Game.chapter_title if Game.chapter_title != "" else "глава %d" % Game.chapter_id,
			Game.map_territories.size(),
			Game.NODES.size() if not Game.NODES.is_empty() else 4,
		]
	if _sub:
		_sub.text = sub
		_sub.add_theme_color_override("font_color", Palette.PAPER_DIM)
	var hour_w := 220.0 * clampf(Game.hour, 0.0, 1.0)
	if _hour_fill:
		_hour_fill.custom_minimum_size.x = hour_w
		_hour_fill.size.x = hour_w
		_hour_fill.color = Palette.DUST_DIM
	if _hour_label:
		var label := "РАННЯЯ"
		if Game.hour > 0.66:
			label = "ПРЕДРАССВЕТ"
		elif Game.hour > 0.33:
			label = "ГЛУХАЯ"
		_hour_label.text = label
		_hour_label.add_theme_color_override("font_color", Palette.PAPER_DIM)
	if _trust_fill:
		_trust_fill.size.x = 150.0 * clampf(Game.trust, 0.0, 1.0)
		_trust_fill.color = Palette.DUST
	if _auth_fill:
		_auth_fill.size.x = 150.0 * clampf(Game.authority, 0.0, 1.0)
		_auth_fill.color = Palette.CRT
