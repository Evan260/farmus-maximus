"""Bring the dog and cat breeds to their sizes beside each other, from PixelLab's output: a small lapdog, a big mastiff,
and cats at half size like the tabby the game was made with. Each frame is shrunk with a box filter and every pixel
snapped back to the sprite's own colours, so the art stays crisp and no new colours appear.

Usage: python tools/art/scale_breeds.py
Dogs are scaled in place in game/assets/sprites/dog_breeds/<breed>; cats are written to animals/cat_breeds/<breed>/small.
Run it once on fresh PixelLab output; running it again would shrink the dogs again.
"""
import glob
import os
from pathlib import Path

import numpy as np
from PIL import Image

SPRITES = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites"
DOGS = {"lapdog": 0.62, "molossian": 0.97, "sheepdog": 0.9, "sighthound": 0.81}
CATS = ["longhair", "spotted", "stocky"]


def shrink(src, dst, factor, canvas=None):
    a = np.array(Image.open(src).convert("RGBA"))
    h, w = a.shape[:2]
    pal = np.unique(a[a[..., 3] > 0][:, :3], axis=0).astype(int)
    nw, nh = round(w * factor), round(h * factor)
    pre = a.astype(float)
    pre[..., :3] *= pre[..., 3:4] / 255
    small = np.stack([np.array(Image.fromarray(pre[..., c].astype(np.float32), "F").resize((nw, nh), Image.BOX)) for c in range(4)], -1)
    cw, ch = canvas or (w, h)
    out = np.zeros((ch, cw, 4), np.uint8)
    ox, oy = (cw - nw) // 2, ch - nh
    for y in range(nh):
        for x in range(nw):
            al = small[y, x, 3]
            if al < 110:
                continue
            col = small[y, x, :3] / (al / 255)
            out[oy + y, ox + x, :3] = pal[np.argmin(((pal - col) ** 2).sum(1))]
            out[oy + y, ox + x, 3] = 255
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    Image.fromarray(out).save(dst)


def frames(folder):
    return [folder / "east.png"] + [Path(p) for p in glob.glob(str(folder / "*_east" / "frame_*.png"))]


def main():
    for breed, factor in DOGS.items():
        for f in frames(SPRITES / "dog_breeds" / breed):
            shrink(f, f, factor)
    for breed in CATS:
        folder = SPRITES / "animals" / "cat_breeds" / breed
        for f in frames(folder):
            size = Image.open(f).size
            dst = folder / "small" / f.relative_to(folder)
            shrink(f, dst, 0.5, (round(size[0] / 2), round(size[1] / 2)))
    print("breeds scaled")


if __name__ == "__main__":
    main()
