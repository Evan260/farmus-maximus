"""Paint farmland onto the distant hills of the estate's land layer: vineyards, wheat, green crops and ploughed earth
on the open slopes, with a farmhouse or two among them. Each field has a soft, uneven edge with a few bushes along
it, its rows follow the slope, and it is lit like the grass it replaces, so fields on shaded slopes are darker.
Only open grass is painted, so trees, cypresses and the aqueduct in front stay as they are.

Usage: python tools/art/paint_land_fields.py tools/art/sources/layer_land_plain.png game/assets/backgrounds/estate/layer_land.png
The plain land layer, as split from the painting before any fields, is kept in tools/art/sources so the fields can be
repainted from scratch. After re-splitting the estate painting with split_layers.py, copy the new layer there first.
"""
import colorsys
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

# Each field: what grows there, its outline on the land layer, and how much its rows tilt with the slope.
FIELDS = [
    ("vines", [(118, 186), (148, 168), (198, 165), (214, 178), (196, 192), (126, 193)], -0.28),
    ("wheat", [(14, 184), (40, 172), (84, 170), (92, 184), (60, 194), (20, 194)], -0.2),
    ("green", [(206, 182), (236, 172), (276, 174), (284, 186), (232, 191)], 0.15),
    ("ploughed", [(252, 168), (282, 160), (318, 162), (300, 174), (262, 176)], 0.2),
    ("vines", [(330, 166), (356, 152), (392, 154), (384, 170), (344, 174)], 0.3),
    ("wheat", [(512, 176), (540, 164), (586, 164), (596, 178), (548, 186)], 0.1),
    ("vines", [(586, 186), (604, 174), (640, 174), (630, 190), (592, 193)], 0.2),
    ("green", [(640, 178), (668, 170), (690, 176), (676, 190), (636, 190)], 0.25),
    ("wheat", [(600, 196), (640, 192), (652, 200), (608, 205)], 0.1),
]
HOUSES = [(204, 168), (624, 166)]

VINE = np.array([(62, 88, 40), (74, 100, 46), (56, 80, 38)], float)
WHEAT = np.array([(220, 190, 96), (206, 174, 82), (230, 202, 112)], float)
GREEN = np.array([(118, 140, 58), (104, 126, 52)], float)
PLOUGH = np.array([(150, 112, 72), (128, 94, 62)], float)
HEDGE = (70, 88, 46)
# Taken from the village houses, so the farmhouses look built from the same stone and tile.
WALL, WALL_SHADE, ROOF, ROOF_SHADE, DOOR = (249, 210, 141), (137, 99, 73), (198, 109, 54), (108, 55, 38), (74, 52, 48)
SHRUBS = [(46, 63, 37), (66, 81, 45), (91, 96, 46)]


def grassy(px):
    r, g, b, a = (int(v) for v in px)
    if a < 200:
        return False
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 0.11 < h < 0.32 and s > 0.25 and v > 0.3


def smooth_noise(shape, scale, rng):
    return ndimage.gaussian_filter(rng.normal(0, 1, shape), scale) * scale


def main():
    src, dst = sys.argv[1], sys.argv[2]
    im = Image.open(src).convert("RGBA")
    a = np.array(im).astype(float)
    out = a.copy()
    rng = np.random.default_rng(11)
    h, w = a.shape[:2]
    edge_noise = smooth_noise((h, w), 2.0, rng)
    grain = smooth_noise((h, w), 0.8, rng)
    lum = a[..., :3].mean(-1)
    for kind, poly, tilt in FIELDS:
        shape = Image.new("L", (w, h), 0)
        ImageDraw.Draw(shape).polygon(poly, fill=255)
        mask = np.array(shape) > 0
        # A soft, uneven outline: the edge wanders in and out by a pixel or two.
        signed = ndimage.distance_transform_edt(mask) - ndimage.distance_transform_edt(~mask)
        field = (signed + edge_noise * 1.6) > 0
        ys, xs = np.nonzero(field)
        ref = np.median([lum[y, x] for y, x in zip(ys, xs) if grassy(a[y, x])] or [150])
        top = ys.min() if len(ys) else 0
        for y, x in zip(ys, xs):
            if not grassy(a[y, x]):
                continue
            # The field takes the light of the slope it lies on.
            light = np.clip(lum[y, x] / ref, 0.72, 1.12)
            row = (y - top + x * tilt + grain[y, x] * 0.4) / 3.0
            phase = row - np.floor(row)
            if kind == "vines":
                if phase < 0.34:
                    c = VINE[int(x // 3 + y) % len(VINE)]
                else:
                    c = a[y, x, :3] * (0.9 if phase < 0.67 else 1.0)
            elif kind == "wheat":
                c = WHEAT[0] * (1 + grain[y, x] * 0.06)
                if phase < 0.2:
                    c = WHEAT[1]
            elif kind == "green":
                c = GREEN[0] if phase < 0.5 else GREEN[1]
            else:
                c = PLOUGH[0] if phase < 0.5 else PLOUGH[1]
            out[y, x, :3] = np.clip(c * light, 0, 255)
        # Bushes here and there along the field's edge.
        rim = field & ~ndimage.binary_erosion(field)
        for y, x in zip(*np.nonzero(rim)):
            if grassy(a[y, x]) and rng.random() < 0.3:
                out[y, x, :3] = HEDGE
    img = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).copy()
    px = img.load()
    # Farmhouses among the fields: cream cottages with tiled roofs, the shaded end to the right.
    for hx, hy in HOUSES:
        for y in range(4):
            for x in range(-1 + (3 - y), 10 - (3 - y) + 1):
                px[hx + x, hy + y] = (ROOF if x < 6 else ROOF_SHADE) + (255,)
        for y in range(4, 9):
            for x in range(9):
                px[hx + x, hy + y] = (WALL if x < 6 else WALL_SHADE) + (255,)
        for y in range(6, 9):
            px[hx + 2, hy + y] = DOOR + (255,)
        px[hx + 5, hy + 5] = DOOR + (255,)
        # A shadow along the foot and a few shrubs at the corners settle the house into the hillside.
        for x in range(0, 10):
            r, g, b, al = px[hx + x, hy + 9]
            px[hx + x, hy + 9] = (int(r * 0.82), int(g * 0.82), int(b * 0.82), al)
        for i, (x, y) in enumerate([(-2, 8), (-1, 8), (-1, 7), (0, 8), (8, 8), (9, 8), (10, 8), (10, 7), (11, 9), (-2, 9)]):
            px[hx + x, hy + y] = SHRUBS[i % len(SHRUBS)] + (255,)
    img.save(dst)
    print("fields painted")


if __name__ == "__main__":
    main()
