import math
import numpy as np
from PIL import Image

A = "game/assets"
W, H = 480, 272
L = lambda p: Image.open(f"{A}/{p}").convert("RGBA")
trim = lambda im: im.crop(im.getchannel("A").getbbox())
sky, mtn, land = L("backgrounds/home_farm/layer_sky.png"), L("backgrounds/home_farm/layer_mountains.png"), L("backgrounds/home_farm/layer_land.png")
BW = sky.width
villa = trim(L("sprites/villa/stage7.png"))
pine = trim(L("sprites/trees/umbrella_pine_1.png"))
dog = trim(L("sprites/dog/east.png"))
base = [L("sprites/lavender/clean/bloom_1.png"), L("sprites/lavender/clean/bloom_2.png")]
bushes = base + [b.transpose(Image.FLIP_LEFT_RIGHT) for b in base]

def ellipse(w, h, color):
    s = Image.new("RGBA", (w, h), (0, 0, 0, 0)); p = s.load()
    for x in range(w):
        for y in range(h):
            if ((x - w / 2 + .5) / (w / 2)) ** 2 + ((y - h / 2 + .5) / (h / 2)) ** 2 <= 1:
                p[x, y] = color
    return s

def bed():
    # A flat tilled patch flush with the grass, so plots read as soil and not as pots.
    b = Image.new("RGBA", (30, 7), (0, 0, 0, 0)); p = b.load()
    for x in range(30):
        for y in range(7):
            if ((x - 14.5) / 15) ** 2 + ((y - 3) / 3.6) ** 2 <= 1:
                p[x, y] = (94, 64, 42, 255)
                if y == 0 or (y == 1 and (x < 3 or x > 26)): p[x, y] = (128, 92, 62, 255)
                if (x + 2 * y) % 5 == 0: p[x, y] = (84, 57, 38, 255)
    return b

BED = bed()


def field():
    # The tilled field is drawn wider than the screen so it can slide with the camera.
    rng = np.random.default_rng(7)
    fw, top, right = W + 80, 232, 352  # field x = screen x + 40
    f = np.zeros((H, fw, 4), np.uint8)
    edge = top + np.cumsum(rng.integers(-1, 2, fw)).clip(-3, 3)
    redge = right + np.cumsum(rng.integers(-1, 2, H)).clip(-3, 3)
    for y in range(top - 4, H):
        for x in range(fw):
            if y < edge[x] or x > redge[y]:
                continue
            furrow = (y - top) % 6 in (0, 1)
            c = (100, 70, 47) if furrow else (118, 84, 56)
            n = rng.random()
            if n < .06: c = (c[0] + 12, c[1] + 9, c[2] + 6)
            elif n < .11: c = (c[0] - 12, c[1] - 9, c[2] - 6)
            f[y, x] = (*c, 255)
    # Grass tufts overhang the top and right edges of the field.
    for x in range(fw):
        for k in range(rng.integers(0, 3)):
            y = edge[x] + k
            if y < H: f[y, x] = (104, 128, 60, 255) if rng.random() < .6 else (86, 110, 50, 255)
    for y in range(top, H):
        x = redge[y]
        if 0 <= x < fw: f[y, x - rng.integers(0, 2)] = (104, 128, 60, 255)
    # A dirt path runs from the field to the villa steps.
    villa_door = villa_x + villa.width // 2 + 40
    for y in range(233, H):
        cx = villa_door - (y - 233) * 0.3
        half = 13 + (y - 233) * 0.3
        for x in range(int(cx - half - 1), int(cx + half + 2)):
            edge_px = x < cx - half or x > cx + half
            if 0 <= x < fw and (not edge_px or rng.random() < .5):
                r = rng.random()
                f[y, x] = (176, 142, 98, 255) if r > .2 else ((154, 122, 82, 255) if r > .06 else (192, 160, 114, 255))
    return Image.fromarray(f)

villa_x = 268
FIELD = field()
SHADOW = ellipse(26, 5, (40, 30, 30, 70))
COLS = [8 + i * 36 for i in range(9)]
ROWS = [(250, 18), (268, 0)]
PLOTS = [(x + dx, y, (i * 3 + j) % 4) for j, (y, dx) in enumerate(ROWS) for i, x in enumerate(COLS) if x + dx < 300]

def layer(im, cam, rate):
    # Background layers are wider than the screen, so the camera reveals more of them instead of an edge.
    off = (im.width - W) // 2 - round(cam * rate)
    return im.crop((off, 0, off + W, H))

def frame(cam):
    f = layer(sky, cam, .06).copy()
    f.alpha_composite(layer(mtn, cam, .18))
    f.alpha_composite(layer(land, cam, .42))
    vx = villa_x + round(cam * .5)
    f.alpha_composite(ellipse(villa.width + 12, 9, (40, 30, 30, 60)), (vx - 6, 234 - 5))
    f.alpha_composite(villa, (vx, 234 - villa.height + 1))
    px_ = -16 + round(cam * .7)
    f.alpha_composite(ellipse(64, 7, (40, 30, 30, 70)), (px_ + pine.width // 2 - 32, 238 - 4))
    f.alpha_composite(pine, (px_, 240 - pine.height))
    fo = round(cam)
    f.alpha_composite(FIELD.crop((40 - fo, 0, 40 - fo + W, H)))
    for x, y, v in PLOTS:
        f.alpha_composite(BED, (x + fo, y - 4))
    for x, y, v in PLOTS:
        f.alpha_composite(SHADOW, (x + 2 + fo, y - 2))
        f.alpha_composite(bushes[v], (x - 1 + fo, y - 29))
    dx = villa_x + villa.width // 2 + 22 + fo
    f.alpha_composite(ellipse(dog.width, 5, (40, 30, 30, 80)), (dx, 266))
    f.alpha_composite(dog, (dx, 269 - dog.height))
    return f.convert("RGB")

out = "design/Art tests/phase1b/"
still = frame(0)
still.save(out + "scene.png")
still.resize((W * 4, H * 4), Image.NEAREST).save(out + "scene_x4.png")
frames = [frame(24 * math.sin(i / 40 * 2 * math.pi)).resize((W * 2, H * 2), Image.NEAREST) for i in range(40)]
frames[0].save(out + "parallax.gif", save_all=True, append_images=frames[1:], duration=80, loop=0)
left, right = frame(-24), frame(24)
cmp = Image.new("RGB", (W, H * 2 + 4), (255, 255, 255)); cmp.paste(left, (0, 0)); cmp.paste(right, (0, H + 4))
cmp.resize((W * 2, cmp.height * 2), Image.NEAREST).save(out + "parallax_extremes.png")
print("ok")
