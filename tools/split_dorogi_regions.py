# -*- coding: utf-8 -*-
"""Снять с dorogi.svg шесть земель по жирным швам и реке."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "assets" / "map" / "dorogi.svg"
WORK = ROOT / "tools" / "_map_cache"
RASTER = WORK / "dorogi_raster.png"
OUT_JSON = ROOT / "assets" / "map" / "dorogi_regions.json"
OUT_PREVIEW = ROOT / "assets" / "map" / "dorogi_regions_preview.png"
OUT_SVG = ROOT / "assets" / "map" / "dorogi_regions.svg"

INKSCAPE = Path(r"E:\Inkscape\bin\inkscape.com")
SVG_W, SVG_H = 3224, 1630
RASTER_W = 1612

# cv2 component ids at open-5, half-res export
ID_WASTE = 3
ID_WASTE_RIBBON = 4
ID_MOUNTAIN = 5
ID_INDUSTRY = 6
ID_LEFT_NORTH = 7
ID_QUARRY = 8
ID_LEFT_SOUTH = 10
ID_HULL_GUTTER = 11
ID_SLIVER = 2

# река: центры двух широких пустот в левом блоке (верх / низ)
RIVER_P1 = (429.0, 445.0)
RIVER_P2 = (328.0, 661.0)

REGIONS = [
    ("city", "Город", (176, 118, 64)),
    ("reshetka", "Решётка", (122, 138, 108)),
    ("waste", "Пустырь", (168, 148, 112)),
    ("quarry", "Карьер", (122, 86, 58)),
    ("mountain", "Горы", (72, 78, 82)),
    ("industry", "Промка", (92, 96, 98)),
]


def rasterize() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    if not INKSCAPE.exists():
        raise SystemExit(f"no inkscape: {INKSCAPE}")
    subprocess.run(
        [
            str(INKSCAPE),
            str(SVG),
            "--export-type=png",
            f"--export-filename={RASTER}",
            f"--export-width={RASTER_W}",
            "--export-background=#000000",
            "--export-background-opacity=1.0",
        ],
        check=True,
    )


def components(gray: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    ink = (gray > 12).astype(np.uint8) * 255
    filled = ink.copy()
    ff = np.zeros((gray.shape[0] + 2, gray.shape[1] + 2), np.uint8)
    cv2.floodFill(filled, ff, (0, 0), 64)
    land = (filled != 64).astype(np.uint8) * 255
    thick = cv2.morphologyEx(
        ink,
        cv2.MORPH_OPEN,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)),
    )
    body = ((land > 0) & (thick == 0)).astype(np.uint8)
    _n, labels = cv2.connectedComponents(body)
    return land, thick, labels


def river_x(y: np.ndarray) -> np.ndarray:
    x1, y1 = RIVER_P1
    x2, y2 = RIVER_P2
    t = (y.astype(np.float64) - y1) / (y2 - y1)
    return x1 + t * (x2 - x1)


def close_mask(mask: np.ndarray) -> np.ndarray:
    k = np.ones((7, 7), np.uint8)
    out = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, k)
    return cv2.morphologyEx(out, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))


def contour_of(mask: np.ndarray, eps: float) -> list[list[int]]:
    contours, _ = cv2.findContours(
        mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE
    )
    if not contours:
        return []
    cnt = max(contours, key=cv2.contourArea)
    approx = cv2.approxPolyDP(cnt, eps, True)
    return [[int(p[0][0]), int(p[0][1])] for p in approx]


def svg_path(points: list[list[int]]) -> str:
    if len(points) < 3:
        return ""
    parts = [f"M{points[0][0]} {points[0][1]}"]
    for x, y in points[1:]:
        parts.append(f"L{x} {y}")
    parts.append("Z")
    return " ".join(parts)


def _check_layout(regions: list[dict]) -> None:
    """Падаем, если жирные швы съехали и куски перепутались."""
    by_id = {r["id"]: r["centroid"] for r in regions}
    city, reshetka = by_id["city"], by_id["reshetka"]
    waste, quarry = by_id["waste"], by_id["quarry"]
    mountain, industry = by_id["mountain"], by_id["industry"]
    if not (city[0] < reshetka[0] < waste[0] < mountain[0]):
        raise SystemExit(f"x order broken: {by_id}")
    if not (waste[1] < quarry[1] and mountain[1] < industry[1]):
        raise SystemExit(f"y order broken: {by_id}")
    if city[1] < waste[1]:
        raise SystemExit(f"city should sit lower than waste: {by_id}")


def main() -> None:
    if not RASTER.exists():
        rasterize()
    gray = np.array(Image.open(RASTER).convert("L"))
    h, w = gray.shape
    scale = SVG_W / float(w)
    land, _thick, labels = components(gray)

    left = (labels == ID_LEFT_NORTH) | (labels == ID_LEFT_SOUTH)
    yy, xx = np.indices((h, w))
    cut = river_x(yy)
    city = land.copy() * 0
    reshetka = land.copy() * 0
    city[left & (xx < cut)] = 255
    reshetka[left & (xx >= cut)] = 255

    masks = {
        "city": close_mask(city),
        "reshetka": close_mask(reshetka),
        "waste": close_mask((labels == ID_WASTE) | (labels == ID_WASTE_RIBBON)),
        "quarry": close_mask(labels == ID_QUARRY),
        "mountain": close_mask((labels == ID_MOUNTAIN) | (labels == ID_SLIVER)),
        "industry": close_mask(labels == ID_INDUSTRY),
    }

    # не отдаём нижнюю кромку корпуса; дырки швов тянем к ближайшей земле
    grow = np.zeros((h, w), np.uint8)
    for m in masks.values():
        grow |= (m > 0).astype(np.uint8)
    leftover = ((land > 0) & (grow == 0) & (labels != ID_HULL_GUTTER)).astype(np.uint8)
    if leftover.any():
        dt_stack = []
        order = [r[0] for r in REGIONS]
        for rid in order:
            inv = np.where(masks[rid] > 0, 0, 255).astype(np.uint8)
            dt_stack.append(cv2.distanceTransform(inv, cv2.DIST_L2, 3))
        nearest = np.argmin(np.stack(dt_stack, axis=0), axis=0)
        for i, rid in enumerate(order):
            masks[rid][leftover.astype(bool) & (nearest == i)] = 255

    boost = np.clip(gray.astype(np.int16) * 6, 0, 255).astype(np.uint8)
    preview = np.dstack([boost, boost, boost])
    overlay = np.zeros((h, w, 4), np.uint8)
    payload_regions = []
    for rid, title, color in REGIONS:
        mask = masks[rid]
        overlay[mask > 0, 0] = color[0]
        overlay[mask > 0, 1] = color[1]
        overlay[mask > 0, 2] = color[2]
        overlay[mask > 0, 3] = 155
        ys, xs = np.where(mask > 0)
        pts_r = contour_of(mask, 2.2)
        pts = [[int(round(x * scale)), int(round(y * scale))] for x, y in pts_r]
        cx = float(xs.mean()) if len(xs) else 0.0
        cy = float(ys.mean()) if len(ys) else 0.0
        payload_regions.append(
            {
                "id": rid,
                "title": title,
                "points": pts,
                "centroid": [round(cx * scale, 1), round(cy * scale, 1)],
                "area": int(len(xs) * scale * scale),
            }
        )
        print(rid, "pts", len(pts), "area", int(len(xs) * scale * scale), "c", payload_regions[-1]["centroid"])

    _check_layout(payload_regions)

    base = Image.fromarray(preview, "RGB").convert("RGBA")
    out = Image.alpha_composite(base, Image.fromarray(overlay, "RGBA"))
    lines = Image.fromarray(np.dstack([boost, boost, boost, np.clip(boost * 2, 0, 180)]), "RGBA")
    out = Image.alpha_composite(out, lines)
    draw = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype("arial.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    for region, (_rid, title, _c) in zip(payload_regions, REGIONS):
        cx, cy = region["centroid"][0] / scale, region["centroid"][1] / scale
        draw.text((cx - 48, cy - 14), title, fill=(232, 224, 212, 255), font=font)

    outline = contour_of(land, 1.6)
    outline = [[int(round(x * scale)), int(round(y * scale))] for x, y in outline]
    payload = {
        "source": "dorogi.svg",
        "size": [SVG_W, SVG_H],
        "outline": outline,
        "regions": payload_regions,
        "note": "Шесть земель по жирным швам. Город и решётка разрезаны рекой. Тонкая сетка не клик. Нижняя кромка корпуса не земля.",
    }
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    out.convert("RGB").save(OUT_PREVIEW)

    fills = {rid: color for rid, _title, color in REGIONS}
    svg_parts = [
        f'<svg width="{SVG_W}" height="{SVG_H}" viewBox="0 0 {SVG_W} {SVG_H}" fill="none" xmlns="http://www.w3.org/2000/svg">',
        "  <!-- шесть земель; линии схемы остаются в dorogi.svg -->",
    ]
    for region, (rid, title, _c) in zip(payload_regions, REGIONS):
        d = svg_path(region["points"])
        r, g, b = fills[rid]
        svg_parts.append(
            f'  <path id="{rid}" data-title="{title}" d="{d}" fill="rgb({r},{g},{b})" fill-opacity="0.7"/>'
        )
    svg_parts.append("</svg>")
    OUT_SVG.write_text("\n".join(svg_parts) + "\n", encoding="utf-8")
    print("wrote", OUT_JSON)
    print("wrote", OUT_PREVIEW)
    print("wrote", OUT_SVG)


if __name__ == "__main__":
    main()
