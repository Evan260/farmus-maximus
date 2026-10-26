"""Split a painted sky into a clean sky, one sprite per cloud, and (at night) the moon, so they can move on their own.

Each row of a pixel-art sky is mostly one colour; anything that differs from its row's most common colour is cloud.
Usage: python tools/art/split_sky.py SKY.png OUT_DIR [--above 150] [--moon X0,Y0,X1,Y1]
Writes OUT_DIR/base.png, OUT_DIR/cloud_NN.png, OUT_DIR/clouds.json (each cloud's position), and OUT_DIR/moon.png.
"""
import argparse
import json
from collections import Counter
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sky")
    p.add_argument("out")
    p.add_argument("--above", type=int, default=150, help="only rows above this can hold moving clouds")
    p.add_argument("--moon", help="x0,y0,x1,y1 box around the moon")
    p.add_argument("--min-area", type=int, default=30, help="smaller specks stay in the sky")
    p.add_argument("--clean", action="store_true", help="paint leftover specks over with the sky (for skies without stars)")
    p.add_argument("--stars", action="store_true", help="scatter stars where clouds were taken out (for night skies)")
    a = p.parse_args()
    rgb = np.asarray(Image.open(a.sky).convert("RGB")).copy()
    H, W = rgb.shape[:2]
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    base = rgb.copy()

    if a.moon:
        x0, y0, x1, y1 = map(int, a.moon.split(","))
        moon = rgb[y0:y1, x0:x1].copy()
        row_bg = [Counter(map(tuple, rgb[y])).most_common(1)[0][0] for y in range(y0, y1)]
        alpha = np.zeros(moon.shape[:2], np.uint8)
        for y in range(moon.shape[0]):
            bg = np.array(row_bg[y])
            # The moon and its glow differ from the night sky; stars inside the box are kept too, which is harmless.
            alpha[y] = (np.abs(moon[y].astype(int) - bg).sum(axis=1) > 18) * 255
            base[y0 + y, x0:x1] = bg
        Image.fromarray(np.dstack([moon, alpha])).save(out / "moon.png")

    mask = np.zeros((H, W), bool)
    for y in range(min(a.above, H)):
        bg = np.array(Counter(map(tuple, base[y])).most_common(1)[0][0])
        diff = np.abs(base[y].astype(int) - bg).sum(axis=1)
        mask[y] = diff > 10
    # The sky is painted in thin horizontal bands that touch every cloud; opening with a tall kernel keeps only
    # shapes several rows high, so each cloud has its own core.
    cores = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_OPEN, np.ones((5, 3), np.uint8))
    n, lab, stats, _ = cv2.connectedComponentsWithStats(cores, connectivity=8)
    seeds = np.zeros((H, W), np.int32)
    for i in range(1, n):
        if stats[i][4] >= a.min_area:
            seeds[lab == i] = i
    # Every cloud pixel then joins its nearest core, so edges and wisps travel with their cloud instead of staying behind.
    dist, near = cv2.distanceTransformWithLabels((seeds == 0).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
    owner_of = np.zeros(near.max() + 1, np.int32)
    zy, zx = np.nonzero(seeds)
    owner_of[near[zy, zx]] = seeds[zy, zx]
    owner = owner_of[near]
    taken = np.zeros((H, W), bool)
    clouds = []
    for i in np.unique(seeds[seeds > 0]):
        grown = mask & (owner == i) & (dist <= 40)
        # Some pixels inside a cloud match the sky band behind them; closing the gaps up and down takes them along too,
        # which is invisible because clouds only ever move sideways, along their own band.
        grown = cv2.morphologyEx(grown.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((9, 1), np.uint8)).astype(bool)
        grown = cv2.morphologyEx(grown.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((1, 5), np.uint8)).astype(bool)
        grown[a.above:] = False
        grown &= ~taken
        if not grown.any():
            continue
        taken |= grown
        ys, xs = np.nonzero(grown)
        # A cloud the painting cuts off at its edge would show that straight cut once it drifts, so it is painted out.
        if ys.min() == 0 or xs.min() == 0 or xs.max() == W - 1:
            for yy, xx in zip(ys, xs):
                base[yy, xx] = np.array(Counter(map(tuple, base[yy][~mask[yy]] if (~mask[yy]).any() else base[yy])).most_common(1)[0][0])
            continue
        ys, xs = np.nonzero(grown)
        x, y, w, h = xs.min(), ys.min(), xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
        piece = grown[y:y + h, x:x + w]
        sprite = np.zeros((h, w, 4), np.uint8)
        sprite[..., :3] = base[y:y + h, x:x + w]
        sprite[..., 3] = piece * 255
        name = f"cloud_{len(clouds):02d}.png"
        Image.fromarray(sprite).save(out / name)
        clouds.append({"file": name, "x": int(x), "y": int(y), "w": int(w), "h": int(h)})
        for yy in range(y, y + h):
            row = piece[yy - y]
            bg = np.array(Counter(map(tuple, base[yy][~mask[yy]] if (~mask[yy]).any() else base[yy])).most_common(1)[0][0])
            base[yy, x:x + w][row] = bg
    rng = np.random.default_rng(5)
    for y in range(min(a.above, H)):
        bg = np.array(Counter(map(tuple, base[y])).most_common(1)[0][0])
        if a.clean:
            left = np.abs(base[y].astype(int) - bg).sum(axis=1) > 10
            base[y][left & ~taken[y]] = bg
        if a.stars:
            # A night sky is painted with dithered haze that looks like a checkerboard when enlarged; each row keeps its stars
            # on a plain colour instead.
            dim = base[y].astype(int).sum(axis=1) < 330
            base[y][dim] = bg
            # Clouds hid part of the starfield; the gaps get stars at the same density as the open sky.
            star_px = [tuple(c) for c in rgb[y][(rgb[y].astype(int).sum(axis=1) > 450)]]
            for x in np.nonzero(taken[y])[0]:
                if rng.random() < 0.012:
                    base[y, x] = (235, 235, 245) if rng.random() < 0.7 else (150, 150, 220)
    Image.fromarray(base).save(out / "base.png")
    (out / "clouds.json").write_text(json.dumps(clouds, indent=1))
    print(f"{len(clouds)} clouds from {a.sky}")


if __name__ == "__main__":
    main()
