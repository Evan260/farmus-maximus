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
                p[x, y] = (112, 80, 54, 255)
                if y == 0 or (y == 1 and (x < 3 or x > 26)): p[x, y] = (98, 70, 48, 255)
                if (x + 2 * y) % 5 == 0: p[x, y] = (96, 68, 46, 255)
    return b

BED = bed()
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
    vx = 268 + round(cam * .5)
    f.alpha_composite(ellipse(villa.width + 12, 9, (40, 30, 30, 60)), (vx - 6, 234 - 5))
    f.alpha_composite(villa, (vx, 234 - villa.height + 1))
    px_ = -16 + round(cam * .7)
    f.alpha_composite(ellipse(64, 7, (40, 30, 30, 70)), (px_ + pine.width // 2 - 32, 238 - 4))
    f.alpha_composite(pine, (px_, 240 - pine.height))
    fo = round(cam)
    for x, y, v in PLOTS:
        f.alpha_composite(BED, (x + fo, y - 4))
    for x, y, v in PLOTS:
        f.alpha_composite(SHADOW, (x + 2 + fo, y - 2))
        f.alpha_composite(bushes[v], (x - 1 + fo, y - 29))
    dx = 318 + fo
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
