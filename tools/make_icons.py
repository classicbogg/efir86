# -*- coding: utf-8 -*-
"""Штампы 64px строго из палитры Эфир86. Без градиентов и лиц."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "assets" / "icons"

INK = (26, 22, 18, 255)
INK2 = (42, 36, 28, 255)
DUST = (196, 165, 116, 255)
DUST_DIM = (138, 112, 72, 255)
CRT = (124, 255, 178, 255)
CRT_DIM = (42, 106, 72, 255)
AMBER = (232, 162, 58, 255)
RUST = (163, 58, 42, 255)
STEEL = (138, 143, 138, 255)
JAM = (74, 90, 98, 255)
PAPER = (232, 224, 212, 255)
PAPER_DIM = (184, 176, 164, 255)
CLEAR = (0, 0, 0, 0)

TRUCK_FILL = {
    "housing": (196, 160, 106, 255),
    "clinic": (122, 154, 122, 255),
    "tank": (106, 138, 170, 255),
    "antenna": (58, 122, 88, 255),
    "workshop": (154, 122, 90, 255),
    "guard": (138, 74, 58, 255),
}


def canvas(size=64) -> Image.Image:
    return Image.new("RGBA", (size, size), CLEAR)


def box(im: Image.Image, fill, border=STEEL, pad=4) -> ImageDraw.ImageDraw:
    d = ImageDraw.Draw(im)
    s = im.size[0]
    d.rectangle((pad, pad, s - pad - 1, s - pad - 1), fill=fill, outline=border, width=2)
    return d


def save(im: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    im = im.resize((64, 64), Image.Resampling.NEAREST)
    im.save(path)
    print(path.relative_to(ROOT.parent.parent))


def truck_housing():
    im = canvas()
    d = box(im, TRUCK_FILL["housing"])
    d.polygon([(16, 34), (32, 16), (48, 34)], fill=PAPER, outline=INK)
    d.rectangle((20, 34, 44, 50), fill=INK2, outline=INK)
    d.rectangle((28, 38, 36, 50), fill=AMBER)
    save(im, "trucks/housing.png")


def truck_clinic():
    im = canvas()
    d = box(im, TRUCK_FILL["clinic"])
    d.rectangle((28, 16, 36, 48), fill=PAPER)
    d.rectangle((16, 28, 48, 36), fill=PAPER)
    save(im, "trucks/clinic.png")


def truck_tank():
    im = canvas()
    d = box(im, TRUCK_FILL["tank"])
    d.ellipse((16, 18, 48, 48), fill=PAPER_DIM, outline=INK, width=2)
    d.polygon([(32, 22), (28, 34), (34, 34), (30, 44), (40, 30), (33, 30)], fill=DUST)
    save(im, "trucks/tank.png")


def truck_antenna():
    im = canvas()
    d = box(im, TRUCK_FILL["antenna"])
    d.line((32, 16, 32, 48), fill=CRT, width=3)
    d.ellipse((28, 12, 36, 20), fill=CRT)
    d.arc((20, 20, 44, 40), 200, 340, fill=CRT, width=2)
    d.arc((14, 24, 50, 48), 200, 340, fill=DUST, width=2)
    save(im, "trucks/antenna.png")


def truck_workshop():
    im = canvas()
    d = box(im, TRUCK_FILL["workshop"])
    d.rectangle((18, 30, 46, 36), fill=PAPER)
    d.polygon([(40, 18), (48, 26), (44, 30), (36, 22)], fill=AMBER)
    d.rectangle((22, 36, 30, 48), fill=INK2)
    save(im, "trucks/workshop.png")


def truck_guard():
    im = canvas()
    d = box(im, TRUCK_FILL["guard"])
    d.polygon([(32, 14), (48, 22), (44, 46), (32, 52), (20, 46), (16, 22)], fill=PAPER_DIM, outline=INK)
    d.rectangle((28, 26, 36, 40), fill=RUST)
    save(im, "trucks/guard.png")


def token(name: str, glyph_fn, ring):
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((8, 8, 55, 55), fill=INK, outline=ring, width=3)
    glyph_fn(d)
    save(im, f"tokens/{name}.png")


def token_medic():
    def g(d):
        d.rectangle((29, 18, 35, 46), fill=PAPER)
        d.rectangle((18, 29, 46, 35), fill=PAPER)
    token("medic", g, AMBER)


def token_tech():
    def g(d):
        d.rectangle((18, 30, 46, 36), fill=PAPER)
        d.polygon([(38, 18), (48, 28), (42, 32), (32, 22)], fill=AMBER)
    token("tech", g, STEEL)


def token_radio():
    def g(d):
        d.line((32, 18, 32, 46), fill=CRT, width=3)
        d.arc((20, 22, 44, 42), 210, 330, fill=CRT, width=2)
    token("radio", g, CRT)


def token_guard():
    def g(d):
        d.polygon([(32, 16), (46, 24), (42, 44), (32, 48), (22, 44), (18, 24)], fill=PAPER_DIM)
    token("guard", g, RUST)


def node(name: str, draw_fn, ring=STEEL):
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((6, 6, 57, 57), fill=INK2, outline=ring, width=3)
    draw_fn(d)
    save(im, f"nodes/{name}.png")


def node_quarry():
    def g(d):
        d.polygon([(14, 44), (24, 24), (34, 40), (42, 22), (52, 44)], fill=DUST_DIM)
        d.rectangle((28, 40, 36, 50), fill=AMBER)
    node("quarry", g, DUST)


def node_gas():
    def g(d):
        d.rectangle((22, 20, 42, 48), fill=PAPER_DIM, outline=INK)
        d.rectangle((26, 24, 32, 32), fill=AMBER)
        d.line((42, 22, 50, 16), fill=STEEL, width=2)
    node("gas", g, STEEL)


def node_reshetka():
    def g(d):
        for x in range(20, 48, 8):
            d.line((x, 18, x, 48), fill=PAPER_DIM, width=2)
        for y in range(20, 48, 8):
            d.line((18, y, 48, y), fill=PAPER_DIM, width=2)
    node("reshetka", g, JAM)


def node_tower14():
    def g(d):
        d.line((32, 14, 32, 50), fill=CRT, width=3)
        d.ellipse((28, 10, 36, 18), fill=CRT)
        d.polygon([(32, 22), (18, 50), (46, 50)], outline=STEEL)
    node("tower14", g, CRT)


def ui_pin():
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((18, 10, 46, 38), fill=AMBER, outline=INK, width=2)
    d.polygon([(32, 54), (20, 32), (44, 32)], fill=AMBER)
    save(im, "ui/pin.png")


def ui_plomb():
    im = canvas()
    d = box(im, INK2, STEEL)
    d.rectangle((20, 22, 44, 42), fill=STEEL)
    d.ellipse((26, 16, 38, 28), outline=PAPER_DIM, width=2)
    save(im, "ui/plomb.png")


def ui_plomb_open():
    im = canvas()
    d = box(im, INK2, RUST)
    d.rectangle((20, 26, 44, 46), fill=RUST)
    d.arc((24, 10, 40, 30), 200, 20, fill=AMBER, width=2)
    save(im, "ui/plomb_open.png")


def ui_freq(name, label_color, caged=False):
    im = canvas()
    d = box(im, INK2, label_color)
    d.rectangle((14, 28, 50, 36), fill=label_color)
    if caged:
        d.line((12, 12, 52, 52), fill=JAM, width=2)
        d.line((52, 12, 12, 52), fill=JAM, width=2)
    save(im, f"ui/{name}.png")


def incident(name, fn):
    im = canvas()
    d = ImageDraw.Draw(im)
    d.rectangle((6, 6, 57, 57), fill=INK2, outline=AMBER, width=2)
    fn(d)
    save(im, f"incidents/{name}.png")


def sheet():
    files = sorted(ROOT.rglob("*.png"))
    files = [f for f in files if f.name != "sheet.png"]
    cols = 8
    rows = (len(files) + cols - 1) // cols
    sheet_im = Image.new("RGBA", (cols * 72 + 8, rows * 72 + 8), INK)
    d = ImageDraw.Draw(sheet_im)
    for i, f in enumerate(files):
        x = 8 + (i % cols) * 72
        y = 8 + (i // cols) * 72
        d.rectangle((x - 2, y - 2, x + 65, y + 65), outline=STEEL)
        icon = Image.open(f).convert("RGBA")
        sheet_im.paste(icon, (x, y), icon)
    out = ROOT / "sheet.png"
    sheet_im.save(out)
    print("sheet", out)


def main():
    truck_housing()
    truck_clinic()
    truck_tank()
    truck_antenna()
    truck_workshop()
    truck_guard()
    token_medic()
    token_tech()
    token_radio()
    token_guard()
    node_quarry()
    node_gas()
    node_reshetka()
    node_tower14()
    ui_pin()
    ui_plomb()
    ui_plomb_open()
    ui_freq("freq_a", CRT)
    ui_freq("freq_b", DUST)
    ui_freq("freq_c", JAM, caged=True)
    incident("water", lambda d: d.polygon([(32, 16), (20, 36), (28, 36), (24, 50), (44, 30), (34, 30)], fill=DUST))
    incident("smoke", lambda d: (d.ellipse((18, 28, 36, 48), fill=JAM), d.ellipse((28, 16, 48, 36), fill=PAPER_DIM)))
    incident("whistle", lambda d: (d.line((20, 40, 44, 20), fill=CRT, width=3), d.line((20, 40, 20, 50), fill=STEEL, width=3)))
    sheet()


if __name__ == "__main__":
    main()
