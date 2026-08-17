# -*- coding: utf-8 -*-
from pathlib import Path

PAPER = "Color(0.956863, 0.933333, 0.858824, 1)"
MUTED = "Color(0.623529, 0.596078, 0.505882, 1)"
FRAME = "Color(0.956863, 0.933333, 0.858824, 0.82)"
OUT = Path(r"C:\Users\fima-\Desktop\chastota86\ui\settings_overlay.tscn")

ROW_H = 88
NAV_H = 96
FONT = 52
FONT_SMALL = 48
ARROW = 40
CHECK = 36
VALUE_W = 420
SLIDER_W = 420
MARKER = 34.0
MARKER_GAP = 32.0
PAGE_SEP = 28


def cycle(parent, name, caption, options, extra_props="", index=0):
    opts = ", ".join(f'"{o}"' for o in options)
    value = options[index] if options else ""
    idx_line = f"index = {index}\n" if index else extra_props
    if extra_props and index:
        idx_line = extra_props
    return f'''
[node name="{name}" type="HBoxContainer" parent="{parent}"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, {ROW_H})
layout_mode = 2
theme_override_constants/separation = 16
script = ExtResource("5_cycle")
caption = "{caption}"
options = PackedStringArray({opts})
{idx_line}
[node name="Caption" type="Label" parent="{parent}/{name}"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = {MUTED}
theme_override_font_sizes/font_size = {FONT}
text = "{caption}"
vertical_alignment = 1

[node name="Prev" type="Button" parent="{parent}/{name}"]
custom_minimum_size = Vector2({ARROW}, {ARROW})
layout_mode = 2
script = ExtResource("8_arrow")

[node name="Value" type="Label" parent="{parent}/{name}"]
custom_minimum_size = Vector2({VALUE_W}, 0)
layout_mode = 2
theme_override_colors/font_color = {MUTED}
theme_override_font_sizes/font_size = {FONT}
text = "{value}"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Next" type="Button" parent="{parent}/{name}"]
custom_minimum_size = Vector2({ARROW}, {ARROW})
layout_mode = 2
script = ExtResource("8_arrow")
pointing_left = false
'''


def slider(parent, name, caption, min_v, max_v, value, step="0.01"):
    return f'''
[node name="{name}" type="HBoxContainer" parent="{parent}"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, {ROW_H})
layout_mode = 2
theme_override_constants/separation = 32
script = ExtResource("6_slider")
caption = "{caption}"

[node name="Caption" type="Label" parent="{parent}/{name}"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = {MUTED}
theme_override_font_sizes/font_size = {FONT}
text = "{caption}"
vertical_alignment = 1

[node name="Slider" type="HSlider" parent="{parent}/{name}"]
custom_minimum_size = Vector2({SLIDER_W}, 22)
layout_mode = 2
size_flags_vertical = 4
min_value = {min_v}
max_value = {max_v}
step = {step}
value = {value}
'''


def check(parent, name, caption, checked="false"):
    return f'''
[node name="{name}" type="HBoxContainer" parent="{parent}"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, {ROW_H})
layout_mode = 2
script = ExtResource("7_check")
caption = "{caption}"

[node name="Caption" type="Label" parent="{parent}/{name}"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = {MUTED}
theme_override_font_sizes/font_size = {FONT}
text = "{caption}"
vertical_alignment = 1

[node name="Check" type="Button" parent="{parent}/{name}"]
custom_minimum_size = Vector2({CHECK + 4}, {CHECK + 4})
layout_mode = 2
size_flags_vertical = 4
toggle_mode = true
button_pressed = {checked}
script = ExtResource("9_sq")
box_size = {CHECK}.0
checked = {checked}
'''


def bind(parent, name, caption, action):
    return f'''
[node name="{name}" type="HBoxContainer" parent="{parent}"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, {ROW_H})
layout_mode = 2
theme_override_constants/separation = 24
script = ExtResource("10_bind")
caption = "{caption}"
action_name = "{action}"

[node name="Caption" type="Label" parent="{parent}/{name}"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = {MUTED}
theme_override_font_sizes/font_size = {FONT}
text = "{caption}"
vertical_alignment = 1

[node name="Change" type="Button" parent="{parent}/{name}"]
layout_mode = 2
theme_override_colors/font_color = {MUTED}
theme_override_font_sizes/font_size = {FONT_SMALL}
text = "Изменить →"
flat = true
'''


def page(name, visible="true"):
    vis = "" if visible == "true" else "visible = false\n"
    return f'''
[node name="{name}" type="VBoxContainer" parent="Margin/Window/Body/Right/Pad/VBox/Pages"]
unique_name_in_owner = true
{vis}layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = {PAGE_SEP}
'''


def nav_btn(name, text, selected=False):
    sel = "selected = true\n" if selected else ""
    return f'''
[node name="{name}" type="Button" parent="Margin/Window/Body/Left/Pad/VBox/Cats"]
layout_mode = 2
size_flags_horizontal = 0
text = "{text}"
script = ExtResource("4_row")
marker_size = {MARKER}
marker_gap = {MARKER_GAP}
fill_on_hover = false
ink_color = {MUTED}
selected_color = {PAPER}
{sel}'''


nav = "".join([
    nav_btn("Video", "Видео", True),
    nav_btn("Audio", "Аудио"),
    nav_btn("Interface", "Интерфейс"),
    nav_btn("Gameplay", "Геймплей"),
    nav_btn("Controls", "Управление"),
])

head = f'''[gd_scene load_steps=18 format=3 uid="uid://bdujv5j1uj0ig"]

[ext_resource type="Script" path="res://ui/settings_overlay.gd" id="1_script"]
[ext_resource type="Texture2D" uid="uid://crkp0wt0as38h" path="res://assets/image/bg-other.png" id="2_bg"]
[ext_resource type="FontFile" uid="uid://cgkasppnm4rad" path="res://assets/fonts/seenonim.ttf" id="3_font"]
[ext_resource type="Script" uid="uid://c8h3menurow86" path="res://ui/menu_row.gd" id="4_row"]
[ext_resource type="Script" path="res://ui/setting_cycle.gd" id="5_cycle"]
[ext_resource type="Script" path="res://ui/setting_slider.gd" id="6_slider"]
[ext_resource type="Script" path="res://ui/setting_check.gd" id="7_check"]
[ext_resource type="Script" path="res://ui/arrow_button.gd" id="8_arrow"]
[ext_resource type="Script" path="res://ui/square_check.gd" id="9_sq"]
[ext_resource type="Script" path="res://ui/setting_bind.gd" id="10_bind"]
[ext_resource type="Texture2D" path="res://assets/image/slider-grabber-muted.png" id="11_grab"]

[sub_resource type="FontVariation" id="FontVariation_set"]
base_font = ExtResource("3_font")
spacing_glyph = 4

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_btn"]
content_margin_left = 66.0
content_margin_top = 10.0
content_margin_right = 8.0
content_margin_bottom = 10.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_window"]
bg_color = Color(0, 0, 0, 0)
draw_center = false
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = {FRAME}

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_left"]
bg_color = Color(0.07, 0.07, 0.07, 0.4)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_right"]
bg_color = Color(0, 0, 0, 0.66)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_slider"]
bg_color = Color(0.623529, 0.596078, 0.505882, 0.35)
content_margin_top = 4.0
content_margin_bottom = 4.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_slider_fill"]
bg_color = Color(0.623529, 0.596078, 0.505882, 0.95)

[sub_resource type="Theme" id="Theme_set"]
default_font = SubResource("FontVariation_set")
Button/colors/font_color = {MUTED}
Button/colors/font_focus_color = {MUTED}
Button/colors/font_hover_color = {MUTED}
Button/colors/font_pressed_color = {MUTED}
Button/font_sizes/font_size = 56
Button/fonts/font = SubResource("FontVariation_set")
Button/styles/focus = SubResource("StyleBoxEmpty_btn")
Button/styles/hover = SubResource("StyleBoxEmpty_btn")
Button/styles/normal = SubResource("StyleBoxEmpty_btn")
Button/styles/pressed = SubResource("StyleBoxEmpty_btn")
HSlider/icons/grabber = ExtResource("11_grab")
HSlider/icons/grabber_highlight = ExtResource("11_grab")
HSlider/styles/slider = SubResource("StyleBoxFlat_slider")
HSlider/styles/grabber_area = SubResource("StyleBoxFlat_slider_fill")
HSlider/styles/grabber_area_highlight = SubResource("StyleBoxFlat_slider_fill")
Label/colors/font_color = {PAPER}
Label/font_sizes/font_size = 72
Label/fonts/font = SubResource("FontVariation_set")

[node name="SettingsOverlay" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme = SubResource("Theme_set")
script = ExtResource("1_script")

[node name="Bg" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("2_bg")
expand_mode = 1
stretch_mode = 6

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 72
theme_override_constants/margin_top = 40
theme_override_constants/margin_right = 72
theme_override_constants/margin_bottom = 40

[node name="Window" type="Panel" parent="Margin"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_window")

[node name="Body" type="HBoxContainer" parent="Margin/Window"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0

[node name="Left" type="Panel" parent="Margin/Window/Body"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.0
theme_override_styles/panel = SubResource("StyleBoxFlat_left")

[node name="Pad" type="MarginContainer" parent="Margin/Window/Body/Left"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 64
theme_override_constants/margin_top = 56
theme_override_constants/margin_right = 40
theme_override_constants/margin_bottom = 48

[node name="VBox" type="VBoxContainer" parent="Margin/Window/Body/Left/Pad"]
layout_mode = 2
theme_override_constants/separation = 48

[node name="Title" type="Label" parent="Margin/Window/Body/Left/Pad/VBox"]
layout_mode = 2
theme_override_colors/font_color = {PAPER}
text = "Настройки"

[node name="TitleGap" type="Control" parent="Margin/Window/Body/Left/Pad/VBox"]
custom_minimum_size = Vector2(0, 56)
layout_mode = 2
mouse_filter = 2

[node name="Cats" type="VBoxContainer" parent="Margin/Window/Body/Left/Pad/VBox"]
layout_mode = 2
theme_override_constants/separation = 28
'''

mid = f'''
[node name="Spacer" type="Control" parent="Margin/Window/Body/Left/Pad/VBox"]
layout_mode = 2
size_flags_vertical = 3
mouse_filter = 2

[node name="Back" type="Button" parent="Margin/Window/Body/Left/Pad/VBox"]
layout_mode = 2
size_flags_horizontal = 0
text = "Назад"
script = ExtResource("4_row")
marker_size = {MARKER}
marker_gap = {MARKER_GAP}
ink_color = {MUTED}
selected_color = {PAPER}

[node name="Divider" type="ColorRect" parent="Margin/Window/Body"]
custom_minimum_size = Vector2(2, 0)
layout_mode = 2
mouse_filter = 2
color = {FRAME}

[node name="Right" type="Panel" parent="Margin/Window/Body"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 2.4
theme_override_styles/panel = SubResource("StyleBoxFlat_right")

[node name="Pad" type="MarginContainer" parent="Margin/Window/Body/Right"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 64
theme_override_constants/margin_top = 56
theme_override_constants/margin_right = 64
theme_override_constants/margin_bottom = 48

[node name="VBox" type="VBoxContainer" parent="Margin/Window/Body/Right/Pad"]
layout_mode = 2
theme_override_constants/separation = 48

[node name="Title" type="Label" parent="Margin/Window/Body/Right/Pad/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = {PAPER}
text = "Видео"

[node name="TitleGap" type="Control" parent="Margin/Window/Body/Right/Pad/VBox"]
custom_minimum_size = Vector2(0, 56)
layout_mode = 2
mouse_filter = 2

[node name="Pages" type="Control" parent="Margin/Window/Body/Right/Pad/VBox"]
layout_mode = 2
size_flags_vertical = 3
'''

pv = "Margin/Window/Body/Right/Pad/VBox/Pages/PageVideo"
pa = "Margin/Window/Body/Right/Pad/VBox/Pages/PageAudio"
pi = "Margin/Window/Body/Right/Pad/VBox/Pages/PageUi"
pg = "Margin/Window/Body/Right/Pad/VBox/Pages/PageGameplay"
pc = "Margin/Window/Body/Right/Pad/VBox/Pages/PageControls"
pb = "Margin/Window/Body/Right/Pad/VBox/Pages/PageBinds"

parts = [
    head,
    nav,
    mid,
    page("PageVideo", "true"),
    cycle(pv, "WindowMode", "Режим окна", ["Полный экран", "Окно", "Окно без рамки"]),
    cycle(pv, "AntiAlias", "Сглаживание", ["Выкл", "Вкл"], index=1),
    check(pv, "VSync", "Верт. синхронизация"),
    page("PageAudio", "false"),
    slider(pa, "MusicVol", "Музыка", 0.0, 1.0, 0.8),
    slider(pa, "VoiceVol", "Голос", 0.0, 1.0, 1.0),
    slider(pa, "NoiseVol", "Шум", 0.0, 1.0, 0.7),
    slider(pa, "UiVol", "Интерфейс", 0.0, 1.0, 0.6),
    cycle(pa, "RangeMode", "Диапазон", ["Широкий", "Сжатый (Ночной)"]),
    page("PageUi", "false"),
    slider(pi, "UiScale", "Масштаб", 0.8, 1.5, 1.0),
    cycle(pi, "ColorBlind", "Цветовая слепота", ["Обычный", "Протанопия", "Дейтеранопия", "Тританопия"]),
    cycle(pi, "FontSize", "Шрифт", ["Маленький", "Средний", "Большой"], index=1),
    check(pi, "UiAnim", "Анимация интерфейса", "true"),
    page("PageGameplay", "false"),
    cycle(pg, "Difficulty", "Сложность", ["Медленная пыль", "Стандарт", "Быстрая пыль"], index=1),
    check(pg, "Hints", "Подсказки", "true"),
    cycle(pg, "Language", "Язык", ["Русский", "Английский"]),
    page("PageControls", "false"),
    bind(pc, "KeybindsEntry", "Назначение клавиш", ""),
    slider(pc, "MouseSens", "Чувствительность мыши", 0.1, 2.0, 0.5),
    check(pc, "InvertWheel", "Инверсия колесика мыши"),
    page("PageBinds", "false"),
    bind(pb, "BindFreq", "Переключить частоту", "frequency_switch"),
    bind(pb, "BindAsk", "Переспросить", "ask_again"),
    bind(pb, "BindSend", "Послать", "send"),
    bind(pb, "BindSeal", "Пломба", "seal"),
]

text = "".join(parts)
while "\n\n\n" in text:
    text = text.replace("\n\n\n", "\n\n")
OUT.write_text(text, encoding="utf-8")
print("wrote", OUT, "chars", len(text))
