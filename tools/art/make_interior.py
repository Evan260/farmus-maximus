"""Make the farmhouse interior from its painting of the restored room with every furnishing.

The painting is cropped to the game's 480 x 270 and its colours reduced, so it sits on the same crisp pixel grid as
the estate. The painted dog and cat are repainted away (the player's own animals nap there instead), the old pool and
rug are repainted into plain floor, and then each furnishing that can be bought is repainted away in turn with
PixelLab's inpainting, leaving the empty room. The rug is drawn in code. Each furnishing is saved as its own picture,
cut from the furnished room along its mask, so the game can lay the bought ones over the empty room.

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
from scipy import ndimage

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


def shapes(polys=(), rects=(), ellipses=(), size=(W, H)):
    m = Image.new("L", size, 0)
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


# Each step: a name, how to find its mask in the furnished room, and how to take it away: what PixelLab should paint
# there instead, or for something as small as a flame, the pixels around it closing over it. A fourth part names an
# earlier repaint to reuse, where two furnishings were taken away together.
ANIMALS = ("animals", lambda room: shapes(ellipses=[(252, 90, 306, 121)]), "a red cushioned couch, empty, no animals")
# The rug the painted dog lay on is painted again whole, without the dog, before it and the pool become plain floor.
OLD_RUG = [(14, 230), (56, 198), (148, 194), (196, 236), (174, 264), (48, 264)]
RUG_WORDS = "one flat rectangular woven wool rug with orange, brown and cream stripes and a short fringe, lying on the stone floor, seen at an angle"
FURNISHINGS = [
    ("fire", lambda room: shapes(rects=[(77, 88, 137, 155)]),
     "the inside of a cold dark stone fireplace, sooty bricks and a heap of grey ash, no fire, no flames, no logs"),
    ("lamps", lambda room: flames(room, [(62, 40, 79, 58), (125, 45, 139, 61), (12, 108, 29, 131), (299, 95, 312, 110)]), heal),
    # The bottom left pot's area stops at the rug's fringed left edge, so taking the plant away never cuts the rug.
    ("plants", lambda room: shapes(polys=[[(0, 220), (30, 220), (33, 230), (45, 262), (46, 269), (0, 269)]], rects=[(434, 110, 479, 178), (426, 206, 479, 269)]),
     "the flagstone floor and the lower stone wall, no plants, no pots"),
    ("scrolls", lambda room: shapes(rects=[(204, 2, 292, 37)]),
     "an empty wooden shelf against a worn red plaster wall, nothing on the shelves", "amphorae"),
    ("amphorae", lambda room: shapes(rects=[(208, 43, 293, 77)]),
     "an empty wooden shelf against a worn red plaster wall, nothing on the shelves", "amphorae"),
    ("panel", lambda room: shapes(rects=[(144, 13, 196, 85)]),
     "a plain worn red plaster wall with faded patches, no painting"),
]

# The old rain pool and rug become plain flagstones; the plant pot that overlaps the rug's corner is kept.
POOL_AREA = [(150, 200), (254, 164), (418, 192), (264, 256)]
POT = [(0, 220), (30, 220), (33, 230), (45, 262), (46, 269), (0, 269)]
FLOOR_WORDS = ("the same worn flagstone floor of irregular cream, grey and rust coloured stones, flat and unbroken, "
               "no rug, no pool, no basin, no water")


def floor_mask():
    rug = grow(shapes(polys=[OLD_RUG, [(8, 238), (18, 222), (40, 218), (44, 232)]]), 3)
    return (grow(shapes(polys=[POOL_AREA]), 4) | rug) & ~shapes(polys=[POT])


# The rug's corners on the half-detail grid (back left, back right, front right, front left), and its stripes from
# back to front as shares of its depth. It lies where the pool was, near the hearth, its sides running towards the
# room's vanishing point, which is near (125, 32) on this grid.
RUG_CORNERS = [(75, 98), (150, 98), (160, 125), (55, 125)]
CREAM, ORANGE, RUST, BROWN, BINDING = (218, 163, 102), (190, 98, 40), (150, 72, 37), (112, 57, 27), (86, 50, 30)
RUG_BANDS = [(0.05, BINDING), (0.06, RUST), (0.12, ORANGE), (0.04, CREAM), (0.09, BROWN), (0.06, ORANGE), (0.04, CREAM),
             (0.08, RUST), (0.04, CREAM), (0.06, ORANGE), (0.09, BROWN), (0.04, CREAM), (0.12, ORANGE), (0.06, RUST),
             (0.05, BINDING)]


def rug_outline():
    """The rug's outline in the painting's pixels."""
    return [(x * 2, y * 2) for x, y in RUG_CORNERS]


def lay_rug(a):
    """Draws the striped wool rug on a room picture, a half-detail pixel at a time: its stripes follow the floor's
    perspective, its sides are bound in a darker edge, a fringe of cream threads hangs off its back and front, and its
    front edge casts a thin shadow on the stones."""
    import cv2
    square = np.float32([(0, 0), (1, 0), (1, 1), (0, 1)])
    back = cv2.getPerspectiveTransform(np.float32(RUG_CORNERS), square)
    h, w = a.shape[0] // 2, a.shape[1] // 2
    ys, xs = np.mgrid[0:h, 0:w]
    pts = cv2.perspectiveTransform(np.dstack([xs + 0.5, ys + 0.5]).astype(np.float32).reshape(-1, 1, 2), back).reshape(h, w, 2)
    u, v = pts[..., 0], pts[..., 1]
    inside = (u >= 0) & (u < 1) & (v >= 0) & (v < 1)
    # Past the horizon the perspective wraps round, so only pixels within the rug's own corners can be on it.
    cx, cy = zip(*RUG_CORNERS)
    inside &= (xs >= min(cx) - 1) & (xs <= max(cx)) & (ys >= min(cy) - 1) & (ys <= max(cy))
    ends = np.cumsum([b[0] for b in RUG_BANDS])
    band = np.minimum(np.searchsorted(ends, v, side="right"), len(RUG_BANDS) - 1)
    colours = np.array([b[1] for b in RUG_BANDS], float)[band]
    edge = (u < 0.035) | (u > 0.965)
    colours[edge] = BINDING
    colours *= (0.9 + 0.1 * v)[..., None]
    # A soft grain of wool, and a little shade towards its sides, where it dips to the floor.
    grain = np.random.default_rng(7).normal(0, 0.035, (h, w))
    colours *= (1.0 + grain - 0.08 * np.clip(1.0 - np.minimum(u, 1 - u) / 0.12, 0, 1))[..., None]
    top = np.full(w, -1)
    bottom = np.full(w, -1)
    for x in range(w):
        rows = np.nonzero(inside[:, x])[0]
        if len(rows):
            top[x], bottom[x] = rows[0], rows[-1]
            # The front edge is the rug's thickness, a shade darker.
            colours[rows[-1], x] *= 0.8
    rgb = a[..., :3]
    for y, x in zip(*np.nonzero(inside)):
        rgb[y * 2:y * 2 + 2, x * 2:x * 2 + 2] = colours[y, x]

    def put(x, y, colour=None, dim=1.0):
        if 0 <= x < w and 0 <= y < h and not inside[y, x]:
            block = rgb[y * 2:y * 2 + 2, x * 2:x * 2 + 2]
            block[:] = np.array(colour) if colour is not None else block * dim

    for x in range(w):
        if bottom[x] < 0 or edge[top[x], x]:
            continue
        # Threads every other pixel, longer at the front, which is nearer; between them the floor lies in shadow.
        if x % 2 == 0:
            put(x, top[x] - 1, np.array(CREAM) * 0.85)
            put(x, bottom[x] + 1, CREAM)
            put(x, bottom[x] + 2, np.array(CREAM) * 0.9)
            put(x, bottom[x] + 3, dim=0.75)
        else:
            put(x, bottom[x] + 1, dim=0.7)
    return a


# The doorway's opening, where the estate's own sky and far hills show through; the game draws them. Its foot follows
# the stone sill, which slopes down to the right.
DOOR = [(366, 20), (430, 20), (430, 140), (366, 133)]
# The wooden beam across the top of the doorway's stone frame, which the finished room does without.
BEAM = (332, 2, 454, 22)
BEAM_WORDS = ("the top of a pale cut limestone door frame: a lintel of cream stone blocks over the doorway joining the "
              "two stone door posts, smooth red plaster wall above it, no wooden beam")
# The dark wooden post inside the doorway's left jamb, which the stone of the jamb covers instead.
POST = (354, 14, 368, 134)


def stone_post(a):
    """The doorway's left jamb carried on over the wooden post beside it, its stone copied from the jamb just left."""
    x0, y0, x1, y1 = POST
    a[y0:y1, x0:x1] = a[y0:y1, x0 - (x1 - x0):x0]
    return a


def floor_only(clean, mask, out):
    """Repaints the old pool and rug as flagstones, sending PixelLab only the floor as the picture to match, so its
    stones carry on in the same sizes and colours without it painting copies of the room into the gap."""
    top = int(np.nonzero(mask.any(axis=1))[0].min()) - 24
    crop = Image.open(clean).convert("RGB").crop((0, top, W, H))
    crop.save(STEPS / "floor_crop.png")
    inpaint(STEPS / "floor_crop.png", mask[top:], FLOOR_WORDS, STEPS / "floor_crop_done.png", context=True)
    # A second pass over the area's edges and the tiles' joins blends the new stones into the old ones, and takes the
    # old rug's fringe from beside the plant pot, picked out by its orange so the leaves stay.
    first = np.array(Image.open(STEPS / "floor_crop_done.png").convert("RGB"))
    inner = ~grow(~mask, 6)
    band = (grow(mask, 6) & ~inner) | (mask & (np.abs(np.mgrid[0:H, 0:W][1] - 276) < 10))
    r, g, b = (np.array(Image.open(clean).convert("RGB"))[..., c].astype(int) for c in range(3))
    fringe = grow(shapes(polys=[POT]), 2) & (r > g + 30) & (g > b) & (np.mgrid[0:H, 0:W][0] > 215)
    band |= grow(fringe, 1) | shapes(rects=[(270, 150, 312, 172)])
    Image.fromarray(first).save(STEPS / "floor_crop_first.png")
    inpaint(STEPS / "floor_crop_first.png", band[top:], FLOOR_WORDS, STEPS / "floor_crop_done.png", context=True)
    full = Image.open(clean).convert("RGB")
    full.paste(Image.open(STEPS / "floor_crop_done.png").convert("RGB"), (0, top))
    a = np.array(full)
    # The last rows of the painting take the colours a few rows up, where the repaint left them blank.
    every = mask | band
    for y in range(H - 6, H):
        a[y][every[y]] = a[y - 6][every[y]]
    Image.fromarray(a).save(out)


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
    # PixelLab paints in steps of four pixels, so rows below the last whole step take the row above's colours.
    a = np.array(Image.open(out))
    for y in range(a.shape[0] // 4 * 4, a.shape[0]):
        a[y][mask[y]] = a[y - 1][mask[y]]
    Image.fromarray(a).save(out)


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


def cut_door(img, ox=0, oy=0):
    """The picture with the doorway's opening made see-through, so the game's own sky and far hills show there."""
    a = np.array(img.convert("RGBA"))
    a[shapes(polys=[[(x + ox, y + oy) for x, y in DOOR]], size=(a.shape[1], a.shape[0])), 3] = 0
    return Image.fromarray(a)


# The ruin is the restored room fallen into disrepair, drawn over the bare restored room so the hearth, the doorway
# and the walls stand exactly where they do once it is mended.
ROOF_HOLE = (272, 0, 48, 10)
STONE = np.array([168, 150, 120])
LEAVES = [np.array(c) for c in ([46, 74, 38], [72, 108, 48], [102, 138, 62])]
TILE = [np.array(c) for c in ([176, 92, 54], [140, 70, 44], [112, 56, 38])]


def _noise(rng, scale, h=H, w=W):
    """Smooth random blobs over the room, from coarse random values scaled up."""
    small = rng.random((h // scale + 2, w // scale + 2))
    big = np.array(Image.fromarray((small * 255).astype(np.uint8)).resize(((w // scale + 2) * scale, (h // scale + 2) * scale), Image.BICUBIC))
    return big[:h, :w] / 255.0


def ruin_room(empty, ox=0, oy=0):
    """The restored room as a ruin: plaster fallen from the red walls, cracks, ivy climbing and hanging, cobwebs,
    fallen roof tiles and rubble on the floor, a hole torn in the roof, and dust over it all. The painting's own part
    of the picture starts `ox` pixels in and `oy` down."""
    rng = np.random.default_rng(31)
    a = np.array(empty.convert("RGBA")).astype(float)
    rgb = a[..., :3]
    H, W = a.shape[:2]
    ys, xs = np.mgrid[0:H, 0:W]
    plaster = (rgb[..., 0] > rgb[..., 1] * 1.35) & (rgb[..., 0] > 90) & (ys < oy + 100) & (a[..., 3] > 0)
    # Plaster gone in patches, showing the stone behind with a dark broken edge.
    fallen = plaster & ((_noise(rng, 14, H, W) * 0.7 + _noise(rng, 5, H, W) * 0.3) > 0.64)
    edge = grow(fallen, 1) & ~fallen & plaster
    shade = (_noise(rng, 3, H, W) - 0.5) * 30
    rgb[fallen] = np.clip(STONE + shade[fallen][:, None], 0, 255)
    rgb[edge] = rgb[edge] * 0.55
    # Cracks wander down the walls, now and then splitting.
    walls = plaster | fallen
    for _ in range(16):
        cand = np.argwhere(walls)
        y, x = cand[rng.integers(len(cand))]
        for _ in range(rng.integers(12, 40)):
            if 0 <= y < H and 0 <= x < W and walls[y, x]:
                rgb[y, x] = [58, 40, 34]
            y += 1 if rng.random() < 0.7 else 0
            x += rng.choice([-1, 0, 1])
    # Ivy climbs from the foot of the walls and hangs from the broken roof.
    for x0, y0, up in [(6, 100, True), (128, 92, True), (338, 138, True), (440, 140, True), (300, 82, True),
                       (160, 0, False), (250, 0, False), (318, 0, False), (420, 0, False)]:
        x, y = float(ox + x0), float(oy + y0 if up else 0)
        for k in range(rng.integers(40, 80)):
            y += -1 if up else 1
            x += rng.normal(0, 0.6)
            xi, yi = int(round(x)), int(y)
            if not (0 <= xi < W and 0 <= yi < H) or a[yi, xi, 3] == 0:
                break
            rgb[yi, xi] = [54, 66, 34]
            if k % 3 == 0:
                c = LEAVES[rng.integers(3)]
                for dx, dy in [(0, 0), (1, 0), (0, 1), (1, 1)][: rng.integers(2, 5)]:
                    px, py = xi + dx * rng.choice([-1, 1]), yi + dy
                    if 0 <= px < W and 0 <= py < H and a[py, px, 3] > 0:
                        rgb[py, px] = c
    # Cobwebs hang in the top corners.
    for cx, cy, flip in [(0, 0, 1), (W - 1, 0, -1), (ox + 140, 0, 1)]:
        for r in range(4, 22, 5):
            for t in np.linspace(0, np.pi / 2, r * 2):
                px, py = int(cx + flip * r * np.cos(t)), int(cy + r * np.sin(t))
                if 0 <= px < W and 0 <= py < H:
                    rgb[py, px] = rgb[py, px] * 0.5 + np.array([210, 205, 195]) * 0.5
        for t in np.linspace(0, np.pi / 2, 5):
            for r in range(0, 22):
                px, py = int(cx + flip * r * np.cos(t)), int(cy + r * np.sin(t))
                if 0 <= px < W and 0 <= py < H:
                    rgb[py, px] = rgb[py, px] * 0.6 + np.array([210, 205, 195]) * 0.4
    # The rug left behind is worn thin and grey with dust.
    rug = shapes(polys=[[(ox + x, oy + y) for x, y in rug_outline()]], size=(W, H))
    rgb[rug] = rgb[rug] * 0.75 + (rgb[rug] @ [0.3, 0.59, 0.11])[:, None] * 0.25 * np.array([1.0, 0.95, 0.85])
    # Fallen roof tiles and rubble across the floor, kept off the rug.
    floor = np.argwhere((ys > oy + 158) & (a[..., 3] > 0) & ~grow(rug, 3))
    for _ in range(140):
        y, x = floor[rng.integers(len(floor))]
        if rng.random() < 0.55:
            w, h, c = rng.integers(3, 7), rng.integers(2, 3), TILE[rng.integers(3)]
            for dy in range(h):
                for dx in range(w):
                    px, py = x + dx + dy, y + dy
                    if 0 <= px < W and 0 <= py < H:
                        rgb[py, px] = c * (0.85 if dy == h - 1 else 1.0)
            if y + h < H:
                rgb[y + h, x:x + w] *= 0.6
        else:
            g = 110 + rng.integers(0, 50)
            rgb[y, x] = [g + 10, g, g - 12]
            if x + 1 < W:
                rgb[y, x + 1] = [g - 20, g - 26, g - 34]
    # The roof is torn open at the top: the sky shows through a ragged gap edged with broken beams, running down from
    # the top of the picture to just inside the painting's own top edge.
    hx, hy, rx, ry = ROOF_HOLE
    reach = (oy + ry) / 2.0
    hole = ((xs - ox - hx) / rx) ** 2 + ((ys - (oy + ry) / 2.0) / reach) ** 2 + (_noise(rng, 4, H, W) - 0.5) * 0.5 < 1.0
    rim = grow(hole, 2) & ~hole
    rgb[rim] = np.array([84, 56, 40]) + (_noise(rng, 2, H, W)[rim][:, None] - 0.5) * 40
    a[hole, 3] = 0
    # Everything faded and dusty: colours drained towards a dusty grey, and the light dimmed.
    grey = (rgb @ [0.3, 0.59, 0.11])[..., None] * np.array([1.04, 1.0, 0.93])
    a[..., :3] = (rgb * 0.68 + grey * 0.32) * 0.9
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


# The red walls as freshly repainted once the villa is improved: each worn patch is covered with plaster copied from
# nearby sound wall, a small square at a time, so the texture carries on rather than being smeared.
WALLS = [(0, 0, 42, 62), (130, 0, 202, 60), (154, 60, 202, 86), (202, 0, 306, 36), (303, 0, 338, 100), (446, 0, 480, 96)]


def repaint_walls(img):
    from scipy import ndimage
    a = np.array(img.convert("RGBA"))
    rgb = a[..., :3].astype(float)
    red = (rgb[..., 0] > rgb[..., 1] * 1.75) & (rgb[..., 0] > 50)
    wall = shapes(rects=WALLS) & (a[..., 3] > 0)
    worn = ndimage.binary_closing(wall & ~red, np.ones((3, 3))) & wall
    worn = ndimage.binary_dilation(worn, iterations=1) & wall
    ys, xs = np.mgrid[0:H, 0:W]
    squares = np.where(worn, (ys // 10) * 100 + xs // 10 + 1, 0)
    out = rgb.copy()
    offsets = [(dx, dy) for r in range(4, 90, 2) for dx, dy in [(r, 0), (-r, 0), (0, r), (0, -r), (r, r), (-r, -r), (r, -r), (-r, r)]]
    for k in np.unique(squares[squares > 0]):
        py, px = np.nonzero(squares == k)
        best = None
        for dx, dy in offsets:
            sy, sx = py + dy, px + dx
            if sy.min() < 0 or sx.min() < 0 or sy.max() >= H or sx.max() >= W:
                continue
            score = red[sy, sx].mean()
            if best is None or score > best[0]:
                best = (score, dx, dy)
            if score > 0.97:
                break
        if best:
            out[py, px] = rgb[py + best[2], px + best[1]]
    a[..., :3] = out.astype(np.uint8)
    return Image.fromarray(a)


def smooth_plaster(img):
    """The finished room's red plaster made smooth and even: each plaster pixel takes most of the average colour of
    the plaster around it and keeps a little of its own, so the wall reads as fresh paint with a soft grain. Stone,
    wood and everything else is left as it is."""
    from scipy import ndimage
    a = np.array(img.convert("RGBA")).astype(float)
    rgb = a[..., :3]
    red = (rgb[..., 0] > rgb[..., 1] * 1.6) & (rgb[..., 0] > 60) & (a[..., 3] > 0)
    red = ndimage.binary_opening(red, np.ones((2, 2)))
    # Worn patches are small areas ringed by plaster; they are painted over too.
    labels, count = ndimage.label(~red)
    worn = np.zeros_like(red)
    for k, box in enumerate(ndimage.find_objects(labels), 1):
        y0, y1 = max(0, box[0].start - 3), box[0].stop + 3
        x0, x1 = max(0, box[1].start - 3), box[1].stop + 3
        spot = labels[y0:y1, x0:x1] == k
        if spot.sum() > 700:
            continue
        ring = ndimage.binary_dilation(spot, iterations=2) & ~spot
        if red[y0:y1, x0:x1][ring].mean() > 0.85:
            worn[y0:y1, x0:x1] |= spot
    weight = ndimage.gaussian_filter(red.astype(float), 3.0)
    mean = np.dstack([ndimage.gaussian_filter(rgb[..., c] * red, 3.0) for c in range(3)]) / np.maximum(weight, 1e-6)[..., None]
    wide_weight = ndimage.gaussian_filter(red.astype(float), 9.0)
    wide_mean = np.dstack([ndimage.gaussian_filter(rgb[..., c] * red, 9.0) for c in range(3)]) / np.maximum(wide_weight, 1e-6)[..., None]
    rgb[worn] = wide_mean[worn]
    rgb[red] = mean[red] * 0.8 + rgb[red] * 0.2
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "build"
    room = load("room", 70)
    if mode == "masks":
        preview_masks(room, Path(sys.argv[2]))
        return
    redo = set(sys.argv[sys.argv.index("--redo") + 1].split(",")) if "--redo" in sys.argv else set()
    STEPS.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    room.save(STEPS / "room.png")
    # The furnished room without the painted animals, then the room losing one furnishing after another.
    name, find, words = ANIMALS
    no_cat = STEPS / "no_cat.png"
    if name in redo or not no_cat.exists():
        inpaint(STEPS / "room.png", find(room), words, no_cat)
    clean = STEPS / "clean.png"
    if "rug" in redo or not clean.exists():
        # The room is not sent along, as PixelLab then paints a small copy of the whole room on the floor.
        inpaint(no_cat, shapes(polys=[OLD_RUG]), RUG_WORDS, clean, blank=True)
    bare = STEPS / "bare_floor.png"
    if "floor" in redo or not bare.exists():
        floor_only(clean, floor_mask(), bare)
    furnished = stone_post(np.array(soften_outlines(Image.open(bare))))
    # Each furnishing is repainted away from the furnished room on its own, and the empty room gathers every repaint,
    # so one can be redone without the others.
    empty = furnished.copy()
    masks = [find(room) for _, find, *_ in FURNISHINGS]
    for k, (name, find, how, *shared) in enumerate(FURNISHINGS):
        mask = masks[k]
        if callable(how):
            alone = furnished.astype(float)
            how(alone, mask)
            empty[mask] = alone[mask].astype(np.uint8)
        else:
            step = STEPS / f"without_{shared[0] if shared else name}.png"
            if name in redo or not step.exists():
                inpaint(clean, mask if not shared else _shared_mask(room, shared[0]), how, step)
            empty[mask] = stone_post(np.array(soften_outlines(Image.open(step))))[mask]
    lay_rug(furnished)
    lay_rug(empty)
    owns = {}
    for k, (name, *_rest) in enumerate(FURNISHINGS):
        # Where two furnishings' areas overlap, the pixels belong to the later one, so neither draws over the other.
        own = masks[k].copy()
        for later in masks[k + 1:]:
            own &= ~later
        # Only the furnishing itself, not the wall or floor around it, so it sits on the walls however they are painted.
        changed = own & (np.abs(furnished.astype(int) - empty.astype(int)).sum(axis=2) > 30)
        # Solid shapes: specks of changed wall dropped, and the holes left where a colour happened to match filled in.
        owns[name] = own & ndimage.binary_fill_holes(ndimage.binary_opening(changed, np.ones((2, 2))))
    # The finished room has a stone lintel over its doorway in place of the wooden beam.
    lintel = STEPS / "without_beam.png"
    if "beam" in redo or not lintel.exists():
        inpaint(bare, shapes(rects=[BEAM]), BEAM_WORDS, lintel, blank=True)
    finished = empty.copy()
    beam = shapes(rects=[BEAM])
    finished[beam] = np.array(soften_outlines(Image.open(lintel)))[beam]
    finished = np.array(repaint_walls(Image.fromarray(finished)).convert("RGB"))
    rooms = {
        "empty": cut_door(Image.fromarray(empty)),
        "painted": smooth_plaster(cut_door(Image.fromarray(finished))),
        "ruin": ruin_room(cut_door(Image.fromarray(empty))),
        "furnished": Image.fromarray(furnished).convert("RGBA"),
    }
    write_half(rooms, owns)
    print("wrote", OUT)


def halve(img):
    """The picture at half its size: each square of four pixels becomes one, their colour averaged, and a pixel is
    see-through only where most of its four were."""
    a = np.array(img.convert("RGBA")).astype(float)
    h, w = a.shape[0] // 2 * 2, a.shape[1] // 2 * 2
    blocks = a[:h, :w].reshape(h // 2, 2, w // 2, 2, 4)
    alpha = blocks[..., 3].mean(axis=(1, 3))
    weight = blocks[..., 3:4] / 255.0
    rgb = (blocks[..., :3] * weight).sum(axis=(1, 3)) / np.maximum(weight.sum(axis=(1, 3)), 1e-6)
    out = np.zeros((h // 2, w // 2, 4))
    out[..., :3] = rgb
    out[..., 3] = np.where(alpha >= 128, 255, 0)
    return out


def write_half(rooms, owns):
    """The farm is drawn with far fewer pixels to an object than the paintings, so the room is kept at half their
    detail: every picture is halved and shares one palette of colours. Each furnishing is cut from the halved
    furnished room, and its place is given in the halved room's pixels."""
    halves = {name: halve(img) for name, img in rooms.items()}
    together = np.concatenate([h[..., :3].reshape(-1, 1, 3) for h in halves.values()], axis=0).astype(np.uint8)
    palette = Image.fromarray(together).quantize(colors=96, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)

    def flat(a):
        rgb = np.array(Image.fromarray(a[..., :3].astype(np.uint8)).quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB"))
        return np.dstack([rgb, a[..., 3]]).astype(np.uint8)

    for name in ("empty", "painted", "ruin"):
        Image.fromarray(flat(halves[name])).save(OUT / f"{name}.png")
    furnished = flat(halves["furnished"])
    spots = {}
    h, w = furnished.shape[:2]
    for name, own in owns.items():
        small = own[: h * 2, : w * 2].reshape(h, 2, w, 2).mean(axis=(1, 3)) >= 0.5
        layer = np.zeros(furnished.shape, np.uint8)
        layer[small] = furnished[small]
        ys, xs = np.nonzero(small)
        box = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
        Image.fromarray(layer[box[1]:box[3], box[0]:box[2]]).save(OUT / f"{name}.png")
        spots[name] = box
    (OUT / "furnished.png").unlink(missing_ok=True)
    (OUT / "furnishings.json").write_text(json.dumps(spots, indent="\t") + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
