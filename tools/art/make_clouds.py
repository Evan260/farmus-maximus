"""Paint the drifting clouds of the estate's sky as real cumulus: a cauliflower heap of many lumps of different sizes,
large and low in the middle and smaller towards the edges and the top, each lump a little out of round, over a flat
base. The heap is shaded as a surface lit from the upper left, so the billows read as rounded and bright on top with
grey undersides and folds, and brightness is kept to a few steps like the rest of the pixel art. The sky shader
colours the grey for the hour.

Usage: python tools/art/make_clouds.py game/assets/backgrounds/sky_clouds
Writes cloud_0.png to cloud_5.png in the sizes the sky lays out.
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SIZES = [(128, 64), (128, 64), (128, 64), (96, 48), (96, 48), (64, 32)]
# How tall each heap rises for its width, and how many lumps it is made of.
HEAPS = [(0.72, 46), (0.55, 40), (0.8, 52), (0.45, 26), (0.58, 30), (0.6, 16)]
STEPS = [0.5, 0.62, 0.74, 0.86, 0.97]
LIGHT = np.array([-0.55, -0.65, 0.52])


def cloud(w, h, heap, count, rng):
    height = np.zeros((h, w))
    base = h * 0.86
    cx = w / 2
    span = w * 0.36
    for _ in range(count):
        # Lumps sit inside a dome: wide at the base, and the higher they are the smaller and more central.
        u = rng.uniform(-1, 1)
        rise = rng.uniform(0, 1) ** 1.3 * (1 - abs(u) ** 1.6)
        r = (h * 0.16 + rng.uniform(0, h * 0.18)) * (1.15 - rise * 0.55) * (1.1 - abs(u) * 0.5)
        x = cx + u * span * (1 - rise * 0.3)
        # No lump reaches past the picture's sides, so no cloud is cut off straight.
        r = min(r, x - 2, w - 2 - x)
        y = base - r * 0.55 - rise * h * heap * 0.85
        wobble = [rng.uniform(-0.12, 0.12) for _ in range(4)]
        ys, xs = np.mgrid[0:h, 0:w].astype(float)
        dx, dy = (xs - x) / r, (ys - y) / (r * 0.9)
        ang = np.arctan2(dy, dx)
        rr = 1 + wobble[0] * np.sin(3 * ang + wobble[1] * 20) + wobble[2] * np.sin(5 * ang + wobble[3] * 20)
        d2 = (dx * dx + dy * dy) / (rr * rr)
        cap = np.sqrt(np.clip(1 - d2, 0, 1)) * r
        height = np.maximum(height, np.where(cap > 0, cap + (base - y) * 0.15, 0))
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    # The base is level but not ruled: it rises and dips a pixel along its length.
    floor = base - np.round(np.abs(np.sin(xs * 0.21) + np.sin(xs * 0.53 + 1.7)) * 0.8)
    inside = (height > 0.5) & (ys < floor)
    # The surface's slope gives how each spot faces the light.
    gy, gx = np.gradient(height)
    normal = np.stack([-gx, -gy, np.ones_like(height)], -1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    light = np.clip(normal @ (LIGHT / np.linalg.norm(LIGHT)), 0, 1)
    under = np.clip((ys - (base - h * 0.18)) / (h * 0.18), 0, 1)
    level = np.clip(0.35 + 0.75 * light - 0.35 * under, 0, 1)
    tone = np.array(STEPS)[np.clip((level * (len(STEPS) - 0.01)).astype(int), 0, len(STEPS) - 1)]
    img = np.zeros((h, w, 4), np.uint8)
    grey = (tone * 255).astype(np.uint8)
    for c in range(3):
        img[..., c] = grey
    img[..., 3] = np.where(inside, 255, 0).astype(np.uint8)
    # The rim of the heap is a touch see-through, so it softens into the sky.
    rim = inside & ~np.pad(inside, 1)[2:, 1:-1] | inside & ~np.pad(inside, 1)[1:-1, 2:]
    img[rim & (ys < base - 2), 3] = 200
    return img


def main():
    out = Path(sys.argv[1])
    rng = np.random.default_rng(21)
    for i, (w, h) in enumerate(SIZES):
        heap, count = HEAPS[i]
        Image.fromarray(cloud(w, h, heap, count, rng)).save(out / f"cloud_{i}.png")
    print("clouds")


if __name__ == "__main__":
    main()
