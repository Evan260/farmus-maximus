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
ANIMALS = ("animals", lambda room: shapes(ellipses=[(252, 90, 306, 121)]), "a red cushioned couch, empty, no animals")
# The rug the painted dog lay on is painted again whole, without the dog; it is part of the room, the dog's own spot.
RUG = [(14, 230), (56, 198), (148, 194), (196, 236), (174, 264), (48, 264)]
RUG_WORDS = "one flat rectangular woven wool rug with orange, brown and cream stripes and a short fringe, lying on the stone floor, seen at an angle"
FURNISHINGS = [
    ("fire", lambda room: shapes(rects=[(77, 88, 137, 155)]),
     "the inside of a cold dark stone fireplace, sooty bricks and a heap of grey ash, no fire, no flames, no logs"),
    ("lamps", lambda room: flames(room, [(62, 40, 79, 58), (125, 45, 139, 61), (12, 108, 29, 131), (299, 95, 312, 110)]), heal),
    ("plants", lambda room: shapes(rects=[(0, 220, 44, 269), (434, 110, 479, 178), (426, 206, 479, 269)]),
     "the flagstone floor and the lower stone wall, no plants, no pots"),
    ("scrolls", lambda room: shapes(rects=[(204, 2, 292, 37)]),
     "an empty wooden shelf against a worn red plaster wall, nothing on the shelves", "amphorae"),
    ("amphorae", lambda room: shapes(rects=[(208, 43, 293, 77)]),
     "an empty wooden shelf against a worn red plaster wall, nothing on the shelves", "amphorae"),
    ("panel", lambda room: shapes(rects=[(141, 11, 198, 87)]),
     "a plain worn red plaster wall with faded patches, no painting"),
    ("water", water,
     "an empty dry stone basin sunk in the floor, dusty grey flagstones, no water"),
]


def inpaint(before, mask, description, out, context=False, blank=False):
    tmp_mask = STEPS / f"{out.stem}_mask.png"
    Image.fromarray((mask * 255).astype(np.uint8)).save(tmp_mask)
    flags = [] if context else ["--no-context"]
    if context or blank:
        # What is being replaced is first blanked to the colour around it, or PixelLab paints it straight back.
        a = np.array(Image.open(before).convert("RGB"))
        ring = grow(mask, 2) & ~mask
        a[mask] = a[ring].mean(axis=0).astype(np.uint8)
        before = STEPS / f"{out.stem}_blank.png"
        Image.fromarray(a).save(before)
    subprocess.run([sys.executable, str(ROOT / "tools" / "art" / "pixellab.py"), "inpaint",
                    str(before.relative_to(ROOT)), str(tmp_mask.relative_to(ROOT)),
                    description + ", cozy pixel art, warm lamplit Roman room", "--out", str(out.relative_to(ROOT)), *flags], check=True)


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


def tidy_rug(img):
    """The repainted rug leaves a sliver of stripes past its fringed left edge; the floor just above covers it."""
    a = np.array(img.convert("RGB"))
    sliver = shapes(polys=[[(14, 204), (48, 204), (48, 206), (33, 230), (28, 236), (14, 236)]]) & (lum(a.astype(int)) > 0)
    for y, x in zip(*np.nonzero(sliver)):
        a[y, x] = a[y - 18, x]
    return Image.fromarray(a)


def soften_outlines(img):
    """The paintings outline everything in near black, which the estate's art does not; each thin dark line becomes a
    darker shade of the colours beside it instead. Wide dark areas, such as the firebox and deep shadows, stay."""
    from scipy import ndimage
    a = np.array(img.convert("RGB")).astype(float)
    dark = lum(a) < 50
    thin = dark & ~ndimage.binary_opening(dark, np.ones((3, 3)))
    total = np.zeros_like(a)
    count = np.zeros(dark.shape)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            ok = np.roll(np.roll(~dark, dy, 0), dx, 1)
            total += np.roll(np.roll(a, dy, 0), dx, 1) * ok[..., None]
            count += ok
    fix = thin & (count > 0)
    a[fix] = total[fix] / count[fix][:, None] * 0.62
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def open_sky(img, rects, blue):
    """The picture with its painted sky cut out where the outdoors shows, so the game's own sky can show through: the
    pale sunset sky in the restored room's doorway, or the blue sky in the ruin's doorway and broken roof. Trees, vines
    and hills stay."""
    a = np.array(img.convert("RGBA")).astype(int)
    for x0, y0, x1, y1 in rects:
        r = a[y0:y1, x0:x1]
        light = lum(r) > 95
        # The painted clouds go too, as the game's own clouds drift past instead.
        sky = light & ((r[..., 2] > r[..., 0] + 20) | (lum(r) > 200) if blue else (r[..., 1] > 70))
        r[..., 3][sky] = 0
    return Image.fromarray(a.astype(np.uint8))


# Where the outdoors shows, as rectangles in which painted sky is cut out.
ROOM_SKY = [(366, 18, 432, 58)]
RUIN_SKY = [(398, 62, 460, 116), (268, 0, 342, 26)]


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "build"
    room = load("room", 70)
    if mode == "masks":
        preview_masks(room, Path(sys.argv[2]))
        return
    redo = set(sys.argv[sys.argv.index("--redo") + 1].split(",")) if "--redo" in sys.argv else set()
    STEPS.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    open_sky(soften_outlines(load("ruin", 30)), RUIN_SKY, True).save(OUT / "ruin.png")
    room.save(STEPS / "room.png")
    # The furnished room without the painted animals, then the room losing one furnishing after another.
    name, find, words = ANIMALS
    no_cat = STEPS / "no_cat.png"
    if name in redo or not no_cat.exists():
        inpaint(STEPS / "room.png", find(room), words, no_cat)
    clean = STEPS / "clean.png"
    if "rug" in redo or not clean.exists():
        # The room is not sent along, as PixelLab then paints a small copy of the whole room on the floor.
        inpaint(no_cat, shapes(polys=[RUG]), RUG_WORDS, clean, blank=True)
    furnished = soften_outlines(tidy_rug(Image.open(clean)))
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
            empty[mask] = np.array(soften_outlines(tidy_rug(Image.open(step))))[mask]
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
    open_sky(Image.fromarray(empty), ROOM_SKY, False).save(OUT / "empty.png")
    (OUT / "furnishings.json").write_text(json.dumps(spots, indent="\t") + "\n", encoding="utf-8")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
