"""Snap a group of sprites onto one small shared palette and lift near-black pixels.

Usage: python tools/art/unify_palette.py OUT_DIR --colors 10 --min-lightness 70 SPRITE [SPRITE ...]
"""
import argparse
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("out_dir")
    p.add_argument("sprites", nargs="+")
    p.add_argument("--colors", type=int, default=10)
    p.add_argument("--min-lightness", type=int, default=70, help="Lab lightness floor, 0 to 255")
    a = p.parse_args()
    ims = [np.asarray(Image.open(s).convert("RGBA")) for s in a.sprites]
    px = np.concatenate([im[im[..., 3] > 0][:, :3] for im in ims]).astype(np.uint8)
    lab = cv2.cvtColor(px.reshape(1, -1, 3), cv2.COLOR_RGB2LAB).reshape(-1, 3).astype(np.float32)
    crit = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 60, 0.5)
    _, _, centers = cv2.kmeans(lab, a.colors, None, crit, 8, cv2.KMEANS_PP_CENTERS)
    # Near-black shadows read as stray black specks at game size, so the darkest colours are lifted.
    centers[:, 0] = np.maximum(centers[:, 0], a.min_lightness)
    pal_rgb = cv2.cvtColor(centers.reshape(1, -1, 3).clip(0, 255).astype(np.uint8), cv2.COLOR_LAB2RGB).reshape(-1, 3)
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for path, im in zip(a.sprites, ims):
        vis = im[..., 3] > 0
        q = cv2.cvtColor(im[..., :3][vis].reshape(1, -1, 3), cv2.COLOR_RGB2LAB).reshape(-1, 3).astype(np.float32)
        idx = np.argmin(((q[:, None] - centers[None]) ** 2).sum(-1), axis=1)
        res = im.copy()
        res[..., :3][vis] = pal_rgb[idx]
        res[..., 3] = np.where(vis, 255, 0)
        Image.fromarray(res).save(out / Path(path).name)
    print("palette:", " ".join("#%02x%02x%02x" % tuple(c) for c in pal_rgb))


if __name__ == "__main__":
    main()
