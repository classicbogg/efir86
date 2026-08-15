# -*- coding: utf-8 -*-
"""Кадры для документа — та же палитра и те же штампы, что в игре."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT / "assets" / "icons"
OUT = ROOT / "docs" / "concept"
OUT.mkdir(parents=True, exist_ok=True)

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

W, H = 1600, 900


def font(size: int):
    for name in ("C:/Windows/Fonts/consola.ttf", "C:/Windows/Fonts/lucon.ttf", "C:/Windows/Fonts/arial.ttf"):
        p = Path(name)
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


F14 = font(16)
F18 = font(20)
F22 = font(24)
F28 = font(32)


def icon(rel: str, size: int) -> Image.Image:
    im = Image.open(ICONS / rel).convert("RGBA")
    return im.resize((size, size), Image.Resampling.NEAREST)


def panel(d: ImageDraw.ImageDraw, box, fill=INK2, border=STEEL):
    d.rectangle(box, fill=fill, outline=border, width=2)


def stamp(d, text, xy, fill=PAPER, fnt=F14):
    d.text(xy, text, font=fnt, fill=fill)


def paste(base: Image.Image, rel: str, xy, size: int):
    im = icon(rel, size)
    base.alpha_composite(im, dest=xy)


def dust_wall(im: Image.Image, width: int):
    d = ImageDraw.Draw(im)
    pts = [(0, 0)]
    for i in range(16):
        y = int(H * i / 15)
        jag = int(10 * (1 if i % 2 == 0 else -1))
        pts.append((width + jag, y))
    pts += [(0, H)]
    d.polygon(pts, fill=(138, 112, 72, 70))
    d.line([(width, 0), (width - 8, H)], fill=DUST, width=2)


def chrome(im: Image.Image, hour=0.2, trust=0.58, auth=0.72, title="ЭФИР 86"):
    d = ImageDraw.Draw(im)
    panel(d, (0, 0, W - 1, 58), INK)
    stamp(d, title, (20, 10), PAPER, F22)
    stamp(d, "демо-срез  ·  карьер → вышка 14", (20, 36), PAPER_DIM, F14)
    # hour
    d.rectangle((420, 18, 640, 30), outline=STEEL, fill=INK2)
    d.rectangle((420, 18, 420 + int(220 * hour), 30), fill=DUST_DIM)
    stamp(d, "РАННЯЯ" if hour < 0.4 else ("ГЛУХАЯ" if hour < 0.7 else "ПРЕДРАССВЕТ"), (420, 34), PAPER_DIM)
    # needles
    def needle(x, label, val, col):
        stamp(d, label, (x, 8), PAPER_DIM)
        d.rectangle((x, 28, x + 150, 38), outline=STEEL, fill=INK2)
        d.rectangle((x, 28, x + int(150 * val), 38), fill=col)
    needle(1180, "ЗЕМЛЯ", trust, DUST)
    needle(1380, "СВОИ", auth, CRT_DIM)


def strip(im: Image.Image, y0=H - 150, trucks=None, plomb=True):
    trucks = trucks or ["housing", "clinic", "tank", "antenna"]
    d = ImageDraw.Draw(im)
    panel(d, (0, y0, W - 1, H - 1), INK2)
    stamp(d, "ЛЕНТА", (16, y0 + 8), PAPER_DIM)
    paste(im, "ui/plomb.png" if plomb else "ui/plomb_open.png", (16, y0 + 36), 48)
    stamp(d, "ПЛОМБА" if plomb else "СОРВАНА", (16, y0 + 88), STEEL if plomb else RUST)
    labels = {
        "housing": "ЖИЛЬЁ",
        "clinic": "ЛАЗАРЕТ",
        "tank": "ЦИСТЕРНА",
        "antenna": "АНТЕННА",
        "workshop": "МАСТЕР",
        "guard": "КУНГ",
    }
    homes = {"medic": 1, "tech": 3}
    x = 140
    for i, kind in enumerate(trucks):
        panel(d, (x, y0 + 20, x + 150, H - 16), (40, 34, 28, 255))
        paste(im, f"trucks/{kind}.png", (x + 8, y0 + 40), 56)
        stamp(d, labels[kind], (x + 70, y0 + 28), PAPER)
        x += 162
    paste(im, "tokens/medic.png", (140 + 162 + 100, y0 + 88), 28)
    paste(im, "tokens/tech.png", (140 + 162 * 3 + 100, y0 + 88), 28)


def radio(im: Image.Image, x0=1240, talking=False, band="A", text="", cage=True):
    d = ImageDraw.Draw(im)
    panel(d, (x0, 58, W - 1, H - 150), INK)
    stamp(d, "РАЦИЯ", (x0 + 16, 70), PAPER_DIM)
    paste(im, "ui/freq_a.png", (x0 + 16, 100), 40)
    stamp(d, "A СВОИ", (x0 + 60, 110), CRT if band == "A" else PAPER_DIM)
    paste(im, "ui/freq_b.png", (x0 + 16, 148), 40)
    stamp(d, "B ЗЕМЛЯ", (x0 + 60, 158), CRT if band == "B" else PAPER_DIM)
    if cage:
        paste(im, "ui/freq_c.png", (x0 + 200, 100), 40)
        stamp(d, "В", (x0 + 246, 110), JAM)
    # wave
    d.rectangle((x0 + 16, 200, W - 20, 280), fill=(12, 16, 12, 255), outline=CRT_DIM)
    import math
    pts = []
    for i in range(80):
        t = i / 79
        amp = 28 if talking else 5
        y = 240 + int(math.sin(t * 14) * amp)
        pts.append((x0 + 16 + int(t * (W - 36 - x0)), y))
    d.line(pts, fill=CRT if talking else CRT_DIM, width=2)
    if talking:
        stamp(d, "ON AIR", (x0 + 24, 206), CRT)
    if text:
        stamp(d, text, (x0 + 16, 300), PAPER, F14)
        panel(d, (x0 + 16, 360, W - 20, 400), INK2, PAPER_DIM)
        stamp(d, "Повторите место", (x0 + 28, 370), PAPER)
        panel(d, (x0 + 16, 412, W - 20, 452), INK2, PAPER_DIM)
        stamp(d, "Шлю кого есть", (x0 + 28, 422), PAPER)


def map_nodes(im: Image.Image, highlight=None, pin=None, dest=None):
    nodes = {
        "quarry": ((220, 420), "Карьер", "nodes/quarry.png"),
        "gas": ((560, 260), "Заправка", "nodes/gas.png"),
        "reshetka": ((600, 560), "Решётка", "nodes/reshetka.png"),
        "tower14": ((980, 400), "Вышка 14", "nodes/tower14.png"),
    }
    d = ImageDraw.Draw(im)
    edges = [("quarry", "gas"), ("quarry", "reshetka"), ("gas", "tower14"), ("reshetka", "tower14")]
    for a, b in edges:
        d.line([nodes[a][0], nodes[b][0]], fill=STEEL, width=2)
    for key, (xy, title, rel) in nodes.items():
        if highlight == key:
            d.ellipse((xy[0] - 28, xy[1] - 28, xy[0] + 28, xy[1] + 28), outline=AMBER, width=2)
        paste(im, rel, (xy[0] - 24, xy[1] - 24), 48)
        stamp(d, title, (xy[0] + 28, xy[1] - 8), PAPER)
    if pin and pin in nodes:
        p = nodes[pin][0]
        paste(im, "ui/pin.png", (p[0] - 12, p[1] - 64), 32)
    if dest and dest in nodes:
        p = nodes[dest][0]
        d.ellipse((p[0] - 30, p[1] - 30, p[0] + 30, p[1] + 30), outline=AMBER, width=2)
    # convoy
    d.rectangle((210, 412, 232, 426), fill=AMBER, outline=INK)


def frame_screen():
    im = Image.new("RGBA", (W, H), INK)
    d = ImageDraw.Draw(im)
    chrome(im)
    dust_wall(im, 130)
    stamp(d, "СХЕМА ТРАССЫ", (150, 72), PAPER_DIM)
    map_nodes(im)
    radio(im, talking=False)
    strip(im)
    stamp(d, "Вдох. Выбери дорогу на карте и одну накладную.", (16, H - 178), PAPER, F14)
    im.convert("RGB").save(OUT / "01-screen.jpg", quality=86, optimize=True)


def frame_call():
    im = Image.new("RGBA", (W, H), INK)
    d = ImageDraw.Draw(im)
    chrome(im, hour=0.28, trust=0.5)
    dust_wall(im, 200)
    stamp(d, "СХЕМА ТРАССЫ", (150, 72), PAPER_DIM)
    map_nodes(im, dest="reshetka", pin="reshetka")
    radio(im, talking=True, band="B", text="нужна в-да  ..еш-тка  трет.. столб")
    strip(im)
    stamp(d, "Земля на Б. Рычаг 2. Потом клик по кружку на ленте.", (16, H - 178), AMBER, F14)
    im.convert("RGB").save(OUT / "02-call.jpg", quality=86, optimize=True)


def frame_stop():
    im = Image.new("RGBA", (W, H), INK)
    d = ImageDraw.Draw(im)
    chrome(im)
    dust_wall(im, 110)
    stamp(d, "СХЕМА ТРАССЫ", (150, 72), PAPER_DIM)
    map_nodes(im)
    radio(im, talking=False)
    # waybills over map bottom
    cards = [
        ("ФУРА", "Мастерская в ленту.\nСоседство с антенной\nпотом поможет вышке."),
        ("ПРОТОКОЛ", "Вода Решётке.\nЗемля теплее.\nСлед на густой дороге."),
        ("РЕЛИКВИЯ", "Мокрая тряпка.\nМгла тише.\nКолонна ползёт."),
    ]
    x = 180
    stamp(d, "ВДОХ", (180, 620), CRT, F18)
    for title, body in cards:
        panel(d, (x, 650, x + 240, 820), INK2, PAPER_DIM)
        stamp(d, title, (x + 12, 660), AMBER, F18)
        stamp(d, body, (x + 12, 694), PAPER, F14)
        x += 260
    strip(im)
    im.convert("RGB").save(OUT / "03-stop.jpg", quality=86, optimize=True)


def frame_forks():
    im = Image.new("RGBA", (W, H), INK)
    d = ImageDraw.Draw(im)
    chrome(im, hour=0.45)
    dust_wall(im, 160)
    stamp(d, "НОЧЬ ИЗ ТРЁХ ВИЛОК", (160, 80), PAPER, F22)
    pairs = [
        (300, "Соль / Кольца", "ранняя"),
        (700, "Провод / Ямы", "глухая"),
        (1100, "Плешь / Дворы", "предрассвет"),
    ]
    for x, title, hour_n in pairs:
        d.line([(x, 220), (x - 80, 360)], fill=STEEL, width=2)
        d.line([(x, 220), (x + 80, 360)], fill=STEEL, width=2)
        d.ellipse((x - 10, 210, x + 10, 230), outline=DUST, width=2)
        stamp(d, title, (x - 70, 380), PAPER, F18)
        stamp(d, hour_n, (x - 40, 408), PAPER_DIM)
        stamp(d, "пусто", (x - 120, 340), JAM)
        stamp(d, "густо", (x + 50, 340), DUST)
    stamp(d, "Закон один: быстрая глухота или медленные люди.", (160, 480), PAPER_DIM, F18)
    radio(im, talking=False)
    strip(im)
    im.convert("RGB").save(OUT / "04-forks.jpg", quality=86, optimize=True)


def frame_tower():
    im = Image.new("RGBA", (W, H), INK)
    d = ImageDraw.Draw(im)
    chrome(im, hour=0.82, trust=0.62, auth=0.6)
    dust_wall(im, 340)
    stamp(d, "СХЕМА ТРАССЫ", (360, 72), PAPER_DIM)
    map_nodes(im, highlight="tower14", dest="tower14")
    radio(im, talking=False, band="A")
    strip(im, trucks=["housing", "clinic", "tank", "antenna", "workshop"])
    paste(im, "tokens/radio.png", (140 + 162 * 3 + 128, H - 62), 28)
    stamp(d, "Вышка 14. Связной сел. Демо-срез закрыт.", (16, H - 178), CRT, F18)
    im.convert("RGB").save(OUT / "05-tower.jpg", quality=86, optimize=True)


def frame_result():
    im = Image.new("RGBA", (W, H), INK)
    d = ImageDraw.Draw(im)
    chrome(im, hour=0.9, trust=0.64, auth=0.58)
    panel(d, (180, 120, 1180, 720), (36, 30, 24, 255), DUST_DIM)
    stamp(d, "НАКЛАДНАЯ НОЧИ", (210, 150), AMBER, F28)
    stamp(d, "не проценты  ·  не звёзды", (210, 196), PAPER_DIM, F18)
    chain = "Карьер  →  Решётка  →  Вышка 14"
    stamp(d, chain, (210, 260), PAPER, F22)
    stamp(d, "насечки: нет", (210, 320), RUST, F18)
    stamp(d, "земля жива     свои слушаются", (210, 370), PAPER, F18)
    stamp(d, "услышал: вода Решётки, свист 14", (210, 430), PAPER_DIM, F18)
    stamp(d, "связной сел", (210, 480), CRT, F18)
    paste(im, "nodes/tower14.png", (980, 200), 96)
    paste(im, "tokens/radio.png", (980, 320), 64)
    radio(im, talking=False)
    stamp(d, "Новая ночь. Между заездами пока ничего не копим.", (200, 760), PAPER_DIM, F18)
    im.convert("RGB").save(OUT / "06-result.jpg", quality=86, optimize=True)


def main():
    frame_screen()
    frame_call()
    frame_stop()
    frame_forks()
    frame_tower()
    frame_result()
    print("wrote", OUT)


if __name__ == "__main__":
    main()
