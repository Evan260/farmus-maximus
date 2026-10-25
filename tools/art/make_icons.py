"""Make the 16-pixel item icons used in lists from the 32-pixel ones the generator draws more clearly.

Each 2x2 block is averaged and then snapped to the nearest colour already in that icon, so the result stays crisp pixel art.
Usage: python tools/art/make_icons.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites"


def shrink(path: Path) -> Image.Image:
    a = np.asarray(Image.open(path).convert("RGBA")).astype(float)
    ys, xs = np.nonzero(a[..., 3] > 0)
    # Crop to the drawing and centre it on the 32-pixel square, so every item sits in the middle of its icon.
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    side = 32
    sq = np.zeros((side, side, 4))
    oy, ox = (side - a.shape[0]) // 2, (side - a.shape[1]) // 2
    sq[oy:oy + a.shape[0], ox:ox + a.shape[1]] = a
    a = sq
    palette = np.unique(a[a[..., 3] > 0][:, :3].astype(np.uint8), axis=0).astype(float)
    out = np.zeros((16, 16, 4), np.uint8)
    for y in range(16):
        for x in range(16):
            block = a[y * 2:y * 2 + 2, x * 2:x * 2 + 2].reshape(4, 4)
            solid = block[block[:, 3] > 0]
            if len(solid) < 2:
                continue
            mean = solid[:, :3].mean(axis=0)
            out[y, x, :3] = palette[np.argmin(((palette - mean) ** 2).sum(axis=1))]
            out[y, x, 3] = 255
    return Image.fromarray(out)


def main():
    src = ROOT / "icons32"
    dst = ROOT / "icons"
    dst.mkdir(exist_ok=True)
    for f in sorted(src.glob("*.png")):
        shrink(f).save(dst / f.name)
    print("icons", len(list(src.glob("*.png"))))


if __name__ == "__main__":
    main()
