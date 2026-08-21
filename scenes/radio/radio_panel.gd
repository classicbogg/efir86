extends Control
## Рация: ноды рычагов/волны/текста/кнопок. Скрипт биндит Game.

@onready var _btn_a: Button = $Levers/FreqA
@onready var _btn_b: Button = $Levers/FreqB
@onready var _btn_c: Button = $Levers/FreqC
@onready var _wave_tag: Label = $Wave/Tag
@onready var _call_meta: Label = $CallMeta
@onready var _call_text: Label = $CallText
@onready var _answer0: Button = $Answers/Btn0
@onready var _answer1: Button = $Answers/Btn1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Game.changed.connect(_refresh)
	Game.call_changed.connect(_refresh)
	_btn_a.pressed.connect(func(): Game.set_frequency("A"))
	_btn_b.pressed.connect(func(): Game.set_frequency("B"))
	_btn_c.pressed.connect(func(): Game.set_frequency("C"))
	_answer0.pressed.connect(func(): _answer(0))
	_answer1.pressed.connect(func(): _answer(1))
	_refresh()


func _answer(i: int) -> void:
	Game.answer_call(i)
	var director = get_tree().root.find_child("TutorialDirector", true, false)
	if director and director.has_method("notify_answer"):
		director.notify_answer(i)


func _refresh() -> void:
	_style_lever(_btn_a, Game.frequency == "A", "A СВОИ")
	_style_lever(_btn_b, Game.frequency == "B", "B ЗЕМЛЯ")
	_btn_c.text = "В"
	_btn_c.add_theme_stylebox_override("normal", Palette.flat_style(Palette.INK_RAISED, Palette.JAM, 2))
	_btn_c.add_theme_color_override("font_color", Palette.JAM)
	if Game.active_call.is_empty():
		_answer0.visible = false
		_answer1.visible = false
		if Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY:
			_call_meta.text = ""
			_call_text.text = "мембрана открыта"
			_call_text.add_theme_color_override("font_color", Palette.CRT_DIM)
		else:
			_call_meta.text = ""
			_call_text.text = "тишина на мембране"
			_call_text.add_theme_color_override("font_color", Palette.JAM)
		if _wave_tag:
			if Game.phase == Game.Phase.STOP:
				_wave_tag.text = "ветер · металл"
				_wave_tag.add_theme_color_override("font_color", Palette.JAM)
			else:
				_wave_tag.text = ""
	else:
		_answer0.visible = true
		_answer1.visible = true
		_answer0.text = str(Game.active_call.get("btn_a", ""))
		_answer1.text = str(Game.active_call.get("btn_b", ""))
		_style_answer(_answer0)
		_style_answer(_answer1)
		var tag := "частота %s  ·  %d с" % [Game.active_call.get("band", "?"), int(Game.call_timer)]
		if bool(Game.active_call.get("epilogue", false)):
			tag = "под мачтой  ·  слова целые  ·  %d с" % int(Game.call_timer)
		_call_meta.text = tag
		_call_meta.add_theme_color_override("font_color", Palette.AMBER)
		_call_text.text = str(Game.active_call.get("text", ""))
		_call_text.add_theme_color_override("font_color", Palette.PAPER)
		var talking: bool = Game.frequency == str(Game.active_call.get("band", ""))
		var at_epi: bool = Game.phase == Game.Phase.EPILOGUE or Game.phase == Game.Phase.SUMMARY
		if _wave_tag and talking:
			_wave_tag.text = "ON AIR" if not at_epi else "ЧИСТО"
			_wave_tag.add_theme_color_override("font_color", Palette.CRT)


func _style_lever(btn: Button, on: bool, label: String) -> void:
	btn.text = label
	btn.add_theme_stylebox_override("normal", Palette.flat_style(Palette.INK_RAISED, Palette.CRT if on else Palette.STEEL, 2))
	btn.add_theme_color_override("font_color", Palette.CRT if on else Palette.PAPER_DIM)


func _style_answer(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", Palette.flat_style(Palette.INK_RAISED, Palette.PAPER_DIM, 2))
	btn.add_theme_color_override("font_color", Palette.PAPER)
