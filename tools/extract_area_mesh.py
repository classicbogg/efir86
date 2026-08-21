# -*- coding: utf-8 -*-
"""Снять с PNG контуров внешний силуэт и играбельные куски."""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "map" / "area1_regions.png"
MESH = ROOT / "assets" / "map" / "area1_mesh.png"
OUT_JSON = ROOT / "assets" / "map" / "area1.json"
OUT_PREVIEW = ROOT / "assets" / "map" / "area1_preview.png"

REGION_COUNT = 6
CLOSE_PX = 3
MIN_CELL_AREA = 40
SIMPLIFY_EPS = 1.6
OUTLINE_EPS = 1.2
SLIVER_FRAC = 0.06

COLORS = [
    (232, 162, 58),
    (124, 255, 178),
    (163, 58, 42),
    (106, 138, 170),
    (196, 160, 106),
    (74, 90, 98),
]


class UnionFind:
    def __init__(self, ids: list[int]) -> None:
        self.parent = {i: i for i in ids}
        self.rank = {i: 0 for i in ids}

    def find(self, x: int) -> int:
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a: int, b: int) -> bool:
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return False
        if self.rank[ra] < self.rank[rb]:
            ra, rb = rb, ra
        self.parent[rb] = ra
        if self.rank[ra] == self.rank[rb]:
            self.rank[ra] += 1
        return True

    def components(self) -> dict[int, list[int]]:
        groups: dict[int, list[int]] = {}
        for i in self.parent:
            groups.setdefault(self.find(i), []).append(i)
        return groups


def close_lines(gray: np.ndarray) -> np.ndarray:
    _, binary = cv2.threshold(gray, 20, 255, cv2.THRESH_BINARY)
    lines = cv2.HoughLinesP(binary, 1, np.pi / 180, threshold=30, minLineLength=40, maxLineGap=20)
    if lines is not None:
        arr = lines if lines.ndim == 2 else lines[:, 0]
        for x1, y1, x2, y2 in arr:
            cv2.line(binary, (int(x1), int(y1)), (int(x2), int(y2)), 255, 3)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (CLOSE_PX, CLOSE_PX))
    return cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel, iterations=1)


def land_and_cells(closed: np.ndarray) -> tuple[np.ndarray, np.ndarray, int]:
    filled = closed.copy()
    h, w = filled.shape
    flood_mask = np.zeros((h + 2, w + 2), np.uint8)
    cv2.floodFill(filled, flood_mask, (0, 0), 128)
    land = (filled != 128).astype(np.uint8) * 255
    cells = ((filled == 0) & (land > 0)).astype(np.uint8)
    count, labels = cv2.connectedComponents(cells)
    return land, labels, count


def keep_big_cells(labels: np.ndarray, count: int) -> list[int]:
    keep = []
    for i in range(1, count):
        if int(np.count_nonzero(labels == i)) >= MIN_CELL_AREA:
            keep.append(i)
    return keep


def shared_lengths(labels: np.ndarray, ids: list[int]) -> list[tuple[int, int, int]]:
    kernel = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]], np.uint8)
    edges: list[tuple[int, int, int]] = []
    for i, a in enumerate(ids):
        mask = (labels == a).astype(np.uint8)
        dil = cv2.dilate(mask, kernel)
        touch = labels.copy()
        touch[mask == 1] = 0
        touch[dil == 0] = 0
        for b in ids[i + 1 :]:
            n = int(np.count_nonzero(touch == b))
            if n > 0:
                edges.append((n, a, b))
    return edges


def merge_to_regions(labels: np.ndarray, ids: list[int], target: int) -> dict[int, list[int]]:
    uf = UnionFind(ids)
    edges = sorted(shared_lengths(labels, ids), key=lambda e: e[0])
    components = len(ids)
    for _weight, a, b in edges:
        if components <= target:
            break
        if uf.union(a, b):
            components -= 1
    groups = uf.components()
    while len(groups) > target:
        areas = {
            root: sum(int(np.count_nonzero(labels == i)) for i in members)
            for root, members in groups.items()
        }
        tiny = min(areas, key=areas.get)
        tiny_ids = groups[tiny]
        others = {r: m for r, m in groups.items() if r != tiny}
        kernel = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]], np.uint8)
        tiny_mask = np.isin(labels, tiny_ids).astype(np.uint8)
        dil = cv2.dilate(tiny_mask, kernel)
        border = labels.copy()
        border[tiny_mask == 1] = 0
        border[dil == 0] = 0
        best = None
        best_n = 0
        for root, members in others.items():
            n = int(sum(np.count_nonzero(border == i) for i in members))
            if n > best_n:
                best_n = n
                best = root
        if best is None:
            break
        for i in tiny_ids:
            uf.union(i, groups[best][0])
        groups = uf.components()
    return groups


def absorb_slivers(
    labels: np.ndarray,
    groups: dict[int, list[int]],
    land: np.ndarray,
    min_frac: float = 0.08,
) -> dict[int, list[int]]:
    land_area = max(int(np.count_nonzero(land)), 1)
    uf = UnionFind([i for members in groups.values() for i in members])
    for members in groups.values():
        for a, b in zip(members, members[1:]):
            uf.union(a, b)

    changed = True
    while changed:
        changed = False
        groups = uf.components()
        areas = {
            root: sum(int(np.count_nonzero(labels == i)) for i in members)
            for root, members in groups.items()
        }
        for root, area in areas.items():
            if area / land_area >= min_frac:
                continue
            tiny_ids = groups[root]
            tiny_mask = np.isin(labels, tiny_ids).astype(np.uint8)
            dil = cv2.dilate(tiny_mask, np.ones((9, 9), np.uint8), iterations=3)
            hit = labels[(dil == 1) & (tiny_mask == 0) & (labels != 0)]
            best = None
            best_n = 0
            for other_root, members in groups.items():
                if other_root == root:
                    continue
                n = int(np.isin(hit, members).sum())
                if n > best_n:
                    best_n = n
                    best = other_root
            if best is None:
                continue
            uf.union(tiny_ids[0], groups[best][0])
            changed = True
            break
    return uf.components()


def contour_of_mask(mask: np.ndarray, eps: float) -> list[list[int]]:
    contours, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not contours:
        return []
    cnt = max(contours, key=cv2.contourArea)
    approx = cv2.approxPolyDP(cnt, eps, True)
    return [[int(p[0][0]), int(p[0][1])] for p in approx]


def lines_overlay(path: Path, rgb: tuple[int, int, int], gain: int = 4) -> Image.Image:
    src = np.array(Image.open(path).convert("RGBA"))
    lum = src[:, :, :3].max(axis=2).astype(np.int16)
    alpha = np.clip((lum - 18) * gain, 0, 255).astype(np.uint8)
    layer = np.zeros_like(src)
    layer[:, :, 0] = rgb[0]
    layer[:, :, 1] = rgb[1]
    layer[:, :, 2] = rgb[2]
    layer[:, :, 3] = alpha
    return Image.fromarray(layer, "RGBA")


def main() -> None:
    rgba = np.array(Image.open(SRC).convert("RGBA"))
    gray = rgba[:, :, 0]
    closed = close_lines(gray)
    land, labels, count = land_and_cells(closed)
    ids = keep_big_cells(labels, count)
    groups = merge_to_regions(labels, ids, REGION_COUNT)
    groups = absorb_slivers(labels, groups, land, min_frac=SLIVER_FRAC)

    h, w = gray.shape
    outline = contour_of_mask(land, OUTLINE_EPS)

    regions = []
    preview = Image.new("RGBA", (w, h), (12, 10, 8, 255))
    color_layer = np.zeros((h, w, 4), np.uint8)

    ordered = sorted(
        groups.items(),
        key=lambda item: (
            float(np.mean(np.column_stack(np.where(np.isin(labels, item[1])))[:, 1]))
            if np.any(np.isin(labels, item[1]))
            else 0.0,
            float(np.mean(np.column_stack(np.where(np.isin(labels, item[1])))[:, 0]))
            if np.any(np.isin(labels, item[1]))
            else 0.0,
        ),
    )

    for idx, (_root, members) in enumerate(ordered):
        mask = np.isin(labels, members).astype(np.uint8) * 255
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
        pts = contour_of_mask(mask, SIMPLIFY_EPS)
        ys, xs = np.where(mask > 0)
        if len(xs) == 0 or len(pts) < 3:
            continue
        cx, cy = float(xs.mean()), float(ys.mean())
        rid = f"r{idx + 1}"
        regions.append(
            {
                "id": rid,
                "title": f"Кусок {idx + 1}",
                "points": pts,
                "centroid": [round(cx, 1), round(cy, 1)],
                "area": int(np.count_nonzero(mask)),
            }
        )
        color = COLORS[idx % len(COLORS)]
        color_layer[mask > 0] = (*color, 180)

    preview = Image.alpha_composite(preview, Image.fromarray(color_layer, "RGBA"))
    if MESH.exists():
        preview = Image.alpha_composite(preview, lines_overlay(MESH, (232, 224, 212), gain=3))
    preview = Image.alpha_composite(preview, lines_overlay(SRC, (26, 22, 18), gain=5))
    draw = ImageDraw.Draw(preview)
    try:
        font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    for region in regions:
        cx, cy = region["centroid"]
        draw.text((cx - 12, cy - 12), region["id"].upper(), fill=(26, 22, 18, 255), font=font)

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "source": "area1_regions.png",
        "size": [w, h],
        "outline": outline,
        "regions": regions,
        "note": "Одна территория, шесть регионов по контурам Group 9. Тип (город/промка/карьер) вешается отдельно.",
    }
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    preview.convert("RGB").save(OUT_PREVIEW)
    print(f"cells kept: {len(ids)}")
    print(f"regions: {len(regions)}")
    print(f"outline pts: {len(outline)}")
    print(f"wrote {OUT_JSON}")
    print(f"wrote {OUT_PREVIEW}")
    for r in regions:
        print(r["id"], "pts", len(r["points"]), "area", r["area"], "c", r["centroid"])


if __name__ == "__main__":
    main()
