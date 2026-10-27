"""Make the farmhouse interior from its two paintings: the ruined room, and the restored room with every furnishing.

The restored painting is cropped to the game's 480 x 270 and its colours reduced, so it sits on the same crisp pixel
grid as the estate. The painted dog and cat are repainted away (the player's own animals nap there instead), and then
each furnishing that can be bought is repainted away in turn with PixelLab's inpainting, leaving the empty room. Each
furnishing is saved as its own picture, cut from the furnished room along its mask, so the game can lay the bought
ones over the empty room.

Usage:
    python tools/art/make_interior.py masks PREVIEW_DIR    draw every mask over the room to check them, spending nothing
    python tools/art/make_interior.py build [--redo NAME]   repaint what is not yet cached, then write the game's files
The repainted rooms are cached in tools/art/sources/interior/steps/, so a rebuild costs nothing unless --redo is given.
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools" / "art" / "sources" / "interior"
STEPS = SRC / "steps"
OUT = ROOT / "game" / "assets" / "backgrounds" / "interior"
W, H = 480, 270


def load(name, top):
    im = Image.open(SRC / f"{name}.webp").convert("RGB")
    # The paintings are 3:2; a band is trimmed from the top and bottom for the game's 16:9.
    im = im.crop((0, top, 1248, top + 702)).resize((W, H), Image.LANCZOS)
    return im.quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGB")


def lum(a):
    return a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11


def shapes(polys=(), rects=(), ellipses=()):
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    for p in polys:
        d.polygon(p, fill=255)
    for r in rects:
        d.rectangle(r, fill=255)
    for e in ellipses:
        d.ellipse(e, fill=255)
    return np.array(m) > 0


def grow(mask, n=1):
    out = mask.copy()
    for _ in range(n):
        g = out.copy()
        g[1:] |= out[:-1]
        g[:-1] |= out[1:]
        g[:, 1:] |= out[:, :-1]
        g[:, :-1] |= out[:, 1:]
        out = g
    return out


def flames(room, rects):
    """The bright flame pixels inside some rectangles, grown a pixel so their glow goes with them."""
    a = np.array(room).astype(int)
    m = np.zeros((H, W), bool)
    for x0, y0, x1, y1 in rects:
        r = a[y0:y1, x0:x1]
        m[y0:y1, x0:x1] = (lum(r) > 115) & (r[..., 0] > r[..., 2] + 50)
    return grow(m, 1) & shapes(rects=rects)


def heal(a, mask):
    """Fills a small masked area from the pixels around it, working inwards, as when a flame is snuffed out."""
    todo = mask.copy()
    while todo.any():
        done = []
        for y, x in zip(*np.nonzero(todo)):
            around = [a[yy, xx] for yy in range(y - 1, y + 2) for xx in range(x - 1, x + 2)
                      if 0 <= yy < H and 0 <= xx < W and not todo[yy, xx]]
            if around:
                done.append((y, x, np.median(around, axis=0)))
        if not done:
            break
        for y, x, c in done:
            a[y, x] = c
            todo[y, x] = False


def water(room):
    a = np.array(room).astype(int)
    inside = shapes(polys=[[(186, 196), (226, 178), (322, 178), (350, 200), (300, 232), (206, 232)]])
    return inside


# Each step: a name, how to find its mask in the furnished room, and how to take it away: what PixelLab should paint
# there instead, or for something as small as a flame, the pixels around it closing over it. A fourth part names an
# earlier repaint to reuse, where two furnishings were taken away together.
ANIMALS = ("animals", lambda room: shapes(ellipses=[(56, 199, 148, 248), (252, 90, 306, 121)]),
           "an orange and brown striped woven rug on a stone floor, and a red cushioned couch, empty, no animals")
FURNISHINGS = [
    ("fire", lambda room: shapes(rects=[(81, 96, 121, 155)]),
     "the inside of a cold dark stone fireplace, sooty bricks and a heap of grey ash, no fire, no flames, no logs"),
    ("lamps", lambda room: flames(room, [(62, 40, 79, 58), (125, 45, 139, 61), (12, 108, 29, 131), (299, 95, 312, 110)]), heal),
    ("plants", lambda room: shapes(rects=[(0, 220, 44, 269), (434, 110, 479, 178), (426, 206, 479, 269)]),
     "the flagstone floor and the lower stone wall, no plants, no pots"),
    ("rug", lambda room: shapes(polys=[[(14, 230), (56, 198), (148, 194), (196, 236), (174, 264), (48, 264)]]),
     "irregular cream, tan and brown flagstone floor tiles, no rug"),
    ("scrolls", lambda room: shapes(rects=[(204, 2, 292, 37)]),
     "an empty wooden shelf against a worn red plaster wall, nothing on the shelves", "amphorae"),
    ("amphorae", lambda room: shapes(rects=[(208, 43, 293, 77)]),
     "an empty wooden shelf against a worn red plaster wall, nothing on the shelves", "amphorae"),
    ("panel", lambda room: shapes(rects=[(141, 11, 198, 87)]),
     "a plain worn red plaster wall with faded patches, no painting"),
    ("water", water,
     "an empty dry stone basin sunk in the floor, dusty grey flagstones, no water"),
]


def inpaint(before, mask, description, out):
    tmp_mask = STEPS / f"{out.stem}_mask.png"
    Image.fromarray((mask * 255).astype(np.uint8)).save(tmp_mask)
    # The whole room is not sent along: it still shows the thing being removed, and PixelLab paints it straight back.
    subprocess.run([sys.executable, str(ROOT / "tools" / "art" / "pixellab.py"), "inpaint",
                    str(before.relative_to(ROOT)), str(tmp_mask.relative_to(ROOT)),
                    description + ", cozy pixel art, warm lamplit Roman room", "--out", str(out.relative_to(ROOT)), "--no-context"], check=True)


def preview_masks(room, folder):
    folder.mkdir(parents=True, exist_ok=True)
    a = np.array(room).astype(float)
    colours = [(255, 0, 0), (0, 255, 0), (0, 128, 255), (255, 255, 0), (255, 0, 255), (0, 255, 255), (255, 128, 0), (128, 0, 255), (255, 255, 255)]
    for (name, find, *_), c in zip([ANIMALS] + FURNISHINGS, colours):
        m = find(room)
        a[m] = a[m] * 0.4 + np.array(c) * 0.6
        print(name, int(m.sum()), "px")
    Image.fromarray(a.astype(np.uint8)).resize((W * 3, H * 3), Image.NEAREST).save(folder / "masks.png")


def _shared_mask(room, step):
    """The mask of every furnishing taken away in one shared repaint."""
    m = np.zeros((H, W), bool)
    for name, find, how, *shared in FURNISHINGS:
        if shared and shared[0] == step:
            m |= find(room)
    return m


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "build"
    room = load("room", 70)
    if mode == "masks":
        preview_masks(room, Path(sys.argv[2]))
        return
    redo = set(sys.argv[sys.argv.index("--redo") + 1].split(",")) if "--redo" in sys.argv else set()
    STEPS.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    load("ruin", 30).save(OUT / "ruin.png")
    room.save(STEPS / "room.png")
    # The furnished room without the painted animals, then the room losing one furnishing after another.
    name, find, words = ANIMALS
    clean = STEPS / "clean.png"
    if name in redo or not clean.exists():
        inpaint(STEPS / "room.png", find(room), words, clean)
    furnished = Image.open(clean).convert("RGB")
    furnished.save(OUT / "furnished.png")
    # Each furnishing is repainted away from the furnished room on its own, and the empty room gathers every repaint,
    # so one can be redone without the others.
    empty = np.array(furnished).copy()
    spots = {}
    masks = [find(room) for _, find, *_ in FURNISHINGS]
    for k, (name, find, how, *shared) in enumerate(FURNISHINGS):
        mask = masks[k]
        if callable(how):
            alone = np.array(furnished).astype(float)
            how(alone, mask)
            empty[mask] = alone[mask].astype(np.uint8)
        else:
            step = STEPS / f"without_{shared[0] if shared else name}.png"
            if name in redo or not step.exists():
                inpaint(clean, mask if not shared else _shared_mask(room, shared[0]), how, step)
            empty[mask] = np.array(Image.open(step).convert("RGB"))[mask]
        a = np.array(furnished)
        # Where two furnishings' areas overlap, the pixels belong to the later one, so neither draws over the other.
        own = mask.copy()
        for later in masks[k + 1:]:
            own &= ~later
        layer = np.zeros((H, W, 4), np.uint8)
        layer[own, :3] = a[own]
        layer[own, 3] = 255
        ys, xs = np.nonzero(own)
        box = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
        Image.fromarray(layer[box[1]:box[3], box[0]:box[2]]).save(OUT / f"{name}.png")
        spots[name] = box
    Image.fromarray(empty).save(OUT / "empty.png")
    (OUT / "furnishings.json").write_text(json.dumps(spots, indent="\t") + "\n", encoding="utf-8")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
