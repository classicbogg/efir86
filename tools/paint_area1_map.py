# -*- coding: utf-8 -*-
"""Карта первой территории без Figma: PNG на рабочий стол."""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(r"C:\Users\UZER\Projects\efir86")
JSON_PATH = ROOT / "assets" / "map" / "area1.json"
OUT_MAP = ROOT / "assets" / "map" / "area1_painted.png"
OUT_DESK = Path(r"C:\Users\UZER\Desktop\Efir86-karta.png")

SCALE = 3
W, H = 1024 * SCALE, 441 * SCALE

NAMES = {
    "city": "Город",
    "reshetka": "Решётка",
    "gas": "Пустырь",
    "quarry": "Карьер",
    "industry": "Промка",
    "tower14": "Горы",
}

FILLS = {
    "city": (176, 118, 64),
    "reshetka": (122, 138, 108),
    "gas": (168, 148, 112),
    "quarry": (122, 86, 58),
    "industry": (92, 96, 98),
    "tower14": (72, 78, 82),
}


def font(size: int):
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def sc(pts):
    return [(int(x * SCALE), int(y * SCALE)) for x, y in pts]


def hatch(draw: ImageDraw.ImageDraw, box, color, step=18, angle=0):
    x0, y0, x1, y1 = box
    if angle == 0:
        for y in range(y0, y1, step):
            draw.line((x0, y, x1, y), fill=color, width=1)
    else:
        for x in range(x0 - (y1 - y0), x1, step):
            draw.line((x, y1, x + (y1 - y0), y0), fill=color, width=1)


def main() -> None:
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    field = (118, 132, 88)
    img = Image.new("RGB", (W, H), field)
    draw = ImageDraw.Draw(img)

    # dust noise
    noise = Image.new("L", (W, H), 0)
    nd = ImageDraw.Draw(noise)
    for i in range(0, W, 9):
        for j in range(0, H, 11):
            if (i * 13 + j * 7) % 17 < 3:
                nd.point((i, j), fill=40)
    noise = noise.filter(ImageFilter.GaussianBlur(1.2))
    tint = Image.new("RGB", (W, H), (90, 80, 50))
    img = Image.composite(tint, img, noise)
    draw = ImageDraw.Draw(img)

    img = img.convert("RGBA")

    for reg in data["regions"]:
        rid = reg["id"]
        pts_raw = list(reg["points"])
        if rid == "industry":
            pts_raw = [p for p in pts_raw if p[0] >= 560]
            pts_raw += [[1023, 440], [1023, 109]]
        pts = sc(pts_raw)
        fill = FILLS[rid]
        base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(base).polygon(pts, fill=(*fill, 255))
        mask = base.split()[-1]
        pat = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        pd = ImageDraw.Draw(pat)
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        box = (min(xs), min(ys), max(xs), max(ys))
        if rid == "city":
            for i in range(box[0], box[2], 16):
                for j in range(box[1], box[3], 13):
                    if (i // 16 + j // 13) % 7 == 0:
                        continue
                    col = (214, 148, 86, 210) if (i + j) % 2 == 0 else (148, 88, 52, 210)
                    pd.rectangle((i, j, i + 10, j + 7), fill=col)
        elif rid == "reshetka":
            for i in range(box[0], box[2], 20):
                pd.line((i, box[1], i, box[3]), fill=(42, 50, 42, 170), width=2)
            for j in range(box[1], box[3], 20):
                pd.line((box[0], j, box[2], j), fill=(42, 50, 42, 170), width=2)
        elif rid == "gas":
            for k in range(8):
                y = box[1] + 16 + k * 32
                pd.arc((box[0] + 8, y, box[2] - 8, y + 36), 200, 340, fill=(120, 100, 72, 120), width=3)
        elif rid == "quarry":
            cx, cy = int(reg["centroid"][0] * SCALE), int(reg["centroid"][1] * SCALE)
            for r in (140, 95, 55, 28):
                pd.ellipse((cx - r * 2, cy - r, cx + r * 2, cy + r), outline=(78, 52, 32, 230), width=5)
        elif rid == "industry":
            for i, (ww, hgt) in enumerate(((90, 32), (120, 40), (76, 26), (100, 44), (84, 30))):
                x = box[0] + 50 + i * 85
                y = box[1] + 50 + (i % 2) * 55
                pd.rectangle((x, y, x + ww, y + hgt), fill=(58, 62, 66, 230), outline=(28, 30, 32, 255))
            pd.rectangle((box[0] + 220, box[1] + 24, box[0] + 232, box[1] + 130), fill=(36, 38, 40, 240))
        elif rid == "tower14":
            cx, cy = int(reg["centroid"][0] * SCALE), int(reg["centroid"][1] * SCALE)
            pd.polygon([(cx - 20, cy + 40), (cx + 130, cy + 20), (cx + 40, cy - 80)], fill=(100, 102, 96, 100))
            for dx in (-36, 0, 40):
                pd.ellipse((cx + dx - 16, cy - 22, cx + dx + 16, cy - 6), outline=(230, 230, 220, 240), width=3)
        stamped = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        stamped.paste(pat, mask=mask)
        piece = Image.alpha_composite(base, stamped)
        img = Image.alpha_composite(img, piece)
        draw = ImageDraw.Draw(img)
        draw.line(pts + [pts[0]], fill=(28, 24, 20, 255), width=5)

    img = img.convert("RGB")
    draw = ImageDraw.Draw(img)

    # river seam
    river = [
        (80 * SCALE, -20 * SCALE),
        (220 * SCALE, 40 * SCALE),
        (280 * SCALE, 160 * SCALE),
        (340 * SCALE, 280 * SCALE),
        (520 * SCALE, 390 * SCALE),
        (780 * SCALE, 460 * SCALE),
        (1100 * SCALE, 500 * SCALE),
    ]
    draw.line(river, fill=(28, 42, 110), width=22 * SCALE // 3)
    draw.line(river, fill=(36, 58, 140), width=14 * SCALE // 3)

    # landmarks
    # base 14 in city
    bx, by = 180 * SCALE, 390 * SCALE
    for i, dx in enumerate((-36, -8, 20, 48)):
        draw.rectangle((bx + dx, by, bx + dx + 22, by + 14), fill=(42, 36, 28), outline=(20, 16, 12))
    mast = (bx + 70, by - 8)
    draw.line((mast[0], mast[1] + 40, mast[0], mast[1] - 70), fill=(30, 28, 24), width=3)
    draw.line((mast[0] - 28, mast[1] + 30, mast[0], mast[1] - 70), fill=(30, 28, 24), width=2)
    draw.line((mast[0] + 28, mast[1] + 30, mast[0], mast[1] - 70), fill=(30, 28, 24), width=2)
    draw.ellipse((mast[0] - 5, mast[1] - 78, mast[0] + 5, mast[1] - 68), fill=(90, 220, 140))

    # gas on wasteland/city edge
    gx, gy = 530 * SCALE, 300 * SCALE
    draw.rectangle((gx, gy, gx + 70, gy + 18), fill=(50, 48, 40), outline=(20, 18, 14))
    draw.polygon([(gx - 6, gy), (gx + 76, gy), (gx + 64, gy - 16), (gx + 8, gy - 16)], fill=(70, 62, 48))
    draw.ellipse((gx + 78, gy - 4, gx + 96, gy + 22), outline=(60, 70, 80), width=3)
    draw.ellipse((gx + 100, gy - 4, gx + 118, gy + 22), outline=(60, 70, 80), width=3)

    # fence tick on reshetka-city edge
    for t in range(8):
        x = (120 + t * 40) * SCALE
        y = (300 + t * 4) * SCALE
        draw.line((x, y - 8, x, y + 8), fill=(40, 44, 38), width=2)

    # labels
    f = font(28)
    f2 = font(16)
    placements = [
        ("city", 240, 378, "Город"),
        ("reshetka", 305, 250, "Решётка"),
        ("gas", 575, 330, "Пустырь"),
        ("quarry", 660, 110, "Карьер"),
        ("industry", 820, 355, "Промка"),
        ("tower14", 910, 125, "Горы"),
    ]
    for _rid, x, y, title in placements:
        x, y = x * SCALE, y * SCALE
        tw = draw.textlength(title, font=f)
        draw.rounded_rectangle((x - 8, y - 18, x + tw + 8, y + 18), radius=4, fill=(18, 16, 12))
        draw.text((x, y - 14), title, font=f, fill=(236, 228, 214))
    draw.text((165 * SCALE, 412 * SCALE), "14", font=f2, fill=(124, 255, 178))
    draw.text((508 * SCALE, 385 * SCALE), "заправка", font=f2, fill=(232, 162, 58))

    draw.text((24, 20), "Эфир86  ·  территория 1", font=font(22), fill=(30, 28, 22))

    img.save(OUT_MAP)
    img.save(OUT_DESK)
    print(OUT_DESK, img.size)


if __name__ == "__main__":
    main()
