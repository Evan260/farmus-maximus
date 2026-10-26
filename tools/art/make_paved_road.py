"""Paint the Roman road that replaces the dirt road when it is paved, seen from the low angle of the rest of the estate:
the far kerb is a thin lit edge, and below it the road is laid like a real Roman way, with irregular rounded slabs of
basalt fitted together. Stones are small and flat towards the far kerb and larger near the viewer; each is lit from
the upper left and darker towards its rim, so it reads as a worn, rounded stone, with dark joints between them.

Usage: python tools/art/make_paved_road.py game/assets/backgrounds/estate/road_paved.png
The picture is as wide as the ground strip and covers its road rows, from ROAD_TOP to the bottom.
"""
import sys

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

W, TOP, H = 2480, 270, 290
STONES = [(124, 118, 112), (134, 127, 118), (116, 111, 108), (128, 124, 120), (140, 132, 122), (120, 114, 106), (110, 106, 102)]
JOINT = (78, 72, 70)


def size_at(y, h):
    """How wide and tall a stone is at this row: small and flat far away, larger near the viewer."""
    near = (y - 3) / max(1, h - 4)
    return 7.0 + 11.0 * near, 2.6 + 4.0 * near


def main():
    rng = np.random.default_rng(23)
    h = H - TOP
    img = np.zeros((h, W, 4), np.uint8)
    img[..., 3] = 255
    # The far kerb: a lit top, its face, and the shadow it throws on the first stones.
    img[0, :, :3] = (176, 168, 156)
    img[1, :, :3] = (150, 142, 132)
    img[2, :, :3] = (96, 90, 86)
    # Seeds for the stones, laid in rough courses that are not quite straight.
    seeds = []
    y = 3.5
    while y < h + 2:
        sw, sh = size_at(y, h)
        x = -rng.uniform(0, sw)
        while x < W + sw:
            seeds.append((x + rng.uniform(-0.3, 0.3) * sw, y + rng.uniform(-0.3, 0.3) * sh))
            x += sw * rng.uniform(0.8, 1.2)
        y += sh * 0.95
    seeds = np.array(seeds)
    colours = np.array([STONES[i] for i in rng.integers(len(STONES), size=len(seeds))], float) + rng.integers(-8, 9, size=(len(seeds), 1))
    tree = cKDTree(seeds * [1.0, 2.6])
    ys, xs = np.mgrid[3:h, 0:W]
    pts = np.stack([xs.ravel(), ys.ravel()], 1).astype(float)
    # Distances are measured with rows stretched, so stones come out wider than tall, as seen at a low angle.
    dist, idx = tree.query(pts * [1.0, 2.6], k=2)
    owner = idx[:, 0]
    d1, d2 = dist[:, 0], dist[:, 1]
    sw = np.array([size_at(yy, h)[0] for yy in pts[:, 1]])
    joint = (d2 - d1) < 0.7
    rim = np.clip(d1 / (sw * 0.6), 0, 1)
    rel = pts - seeds[owner]
    lit = (rel[:, 1] < -0.3) & (rel[:, 0] < sw * 0.15) & (rim < 0.6)
    shade = colours[owner] * (1.0 - 0.18 * rim ** 2)[:, None]
    shade[lit] += 14
    shade[joint] = JOINT
    out = np.clip(shade, 0, 255).astype(np.uint8).reshape(h - 3, W, 3)
    img[3:, :, :3] = out
    Image.fromarray(img).save(sys.argv[1])
    print("road", W, "x", h)


if __name__ == "__main__":
    main()
