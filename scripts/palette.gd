class_name Palette
extends Object
## Единственный источник цвета. Не подбирать краски в сценах руками.

const INK := Color("1a1612")
const INK_RAISED := Color("2a241c")
const DUST := Color("c4a574")
const DUST_DIM := Color("8a7048")
const CRT := Color("7cffb2")
const CRT_DIM := Color("2a6a48")
const AMBER := Color("e8a23a")
const RUST := Color("a33a2a")
const STEEL := Color("8a8f8a")
const JAM := Color("4a5a62")
const PAPER := Color("e8e0d4")
const PAPER_DIM := Color("b8b0a4")

static func truck_color(kind: String) -> Color:
	match kind:
		"housing":
			return Color("c4a06a")
		"clinic":
			return Color("7a9a7a")
		"tank":
			return Color("6a8aaa")
		"antenna":
			return CRT_DIM.lightened(0.15)
		"workshop":
			return Color("9a7a5a")
		"guard":
			return Color("8a4a3a")
		_:
			return STEEL

static func truck_label(kind: String) -> String:
	match kind:
		"housing":
			return "ЖИЛЬЁ"
		"clinic":
			return "ЛАЗАРЕТ"
		"tank":
			return "ЦИСТЕРНА"
		"antenna":
			return "АНТЕННА"
		"workshop":
			return "МАСТЕР"
		"guard":
			return "КУНГ"
		_:
			return kind.to_upper()


static func flat_style(bg: Color, border: Color = Color(0, 0, 0, 0), border_w: float = 0.0, radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(int(border_w))
	s.border_color = border
	if radius > 0:
		s.set_corner_radius_all(radius)
		s.content_margin_left = 2
		s.content_margin_top = 2
		s.content_margin_right = 2
		s.content_margin_bottom = 2
	return s
