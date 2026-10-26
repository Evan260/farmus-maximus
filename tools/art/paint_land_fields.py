"""Paint farmland onto the distant hills of the estate's land layer: a vineyard with a small farmhouse on the hill
behind the olive grove, and wheat and vines on the slopes beside the hill town. Only open grass is painted, so trees,
cypresses and the aqueduct in front stay as they are.

Usage: python tools/art/paint_land_fields.py game/assets/backgrounds/estate/layer_land.png
Run it again after re-splitting the estate painting with split_layers.py, which would otherwise lose the fields.
"""
import colorsys
import sys

from PIL import Image, ImageDraw

VINE = [(66, 92, 42), (84, 112, 50)]
EARTH = (176, 160, 92)
WHEAT = [(222, 192, 98), (198, 166, 78)]
HEDGE = (88, 104, 52)
WALL, WALL_SHADE, ROOF, ROOF_SHADE, DOOR = (232, 214, 172), (196, 172, 132), (184, 88, 56), (146, 64, 42), (92, 64, 48)

# Fields as (kind, polygon on the land layer, how much the rows tilt with the slope).
FIELDS = [
    ("vines", [(118, 186), (150, 168), (200, 166), (214, 178), (196, 192), (128, 193)], -0.28),
    ("wheat", [(578, 186), (604, 174), (640, 174), (630, 188), (590, 192)], 0.2),
    ("vines", [(640, 178), (668, 170), (690, 176), (676, 190), (636, 190)], 0.25),
    ("wheat", [(600, 196), (640, 192), (650, 200), (606, 204)], 0.1),
]
HOUSE = (204, 168)


def is_grass(px):
    r, g, b, a = px
    if a < 200:
        return False
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 0.11 < h < 0.3 and s > 0.3 and v > 0.42


def inside(poly):
    mask = Image.new("L", (800, 300), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    return mask


def main():
    path = sys.argv[1]
    im = Image.open(path).convert("RGBA")
    px = im.load()
    for kind, poly, tilt in FIELDS:
        mask = inside(poly)
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        top = min(ys)
        for y in range(min(ys), max(ys) + 1):
            for x in range(min(xs), max(xs) + 1):
                if not mask.getpixel((x, y)) or not is_grass(px[x, y]):
                    continue
                # Rows run along the slope: every other line of pixels is a row of plants, the line between is earth.
                row = int(y - top + x * tilt)
                if kind == "vines":
                    if row % 3 == 0:
                        px[x, y] = VINE[(x // 2) % 2] + (255,)
                    elif row % 3 == 1:
                        px[x, y] = EARTH + (255,)
                else:
                    px[x, y] = WHEAT[row % 2] + (255,)
        # A darker hedge along the lower edge holds the field in place on the hill.
        for (x0, y0), (x1, y1) in zip(poly, poly[1:] + poly[:1]):
            if y1 >= y0 and abs(x1 - x0) > 4:
                for k in range(abs(x1 - x0) + 1):
                    x = x0 + (k if x1 > x0 else -k)
                    y = round(y0 + (y1 - y0) * k / max(1, abs(x1 - x0)))
                    if 0 <= x < im.width and 0 <= y < im.height and is_grass(px[x, y]):
                        px[x, y] = HEDGE + (255,)
    # The farmhouse among its vines: a cream cottage with a tiled roof, its shaded end to the right.
    hx, hy = HOUSE
    for y in range(4):
        for x in range(-1 + (3 - y), 10 - (3 - y) + 1):
            px[hx + x, hy + y] = (ROOF if x < 6 else ROOF_SHADE) + (255,)
    for y in range(4, 9):
        for x in range(0, 9):
            px[hx + x, hy + y] = (WALL if x < 6 else WALL_SHADE) + (255,)
    for y in range(6, 9):
        px[hx + 2, hy + y] = DOOR + (255,)
    px[hx + 5, hy + 5] = DOOR + (255,)
    im.save(path)
    print("fields painted")


if __name__ == "__main__":
    main()
