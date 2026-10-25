import math, random
import numpy as np
from PIL import Image

A = "game/assets"
W, H = 480, 272
L = lambda p: Image.open(f"{A}/{p}").convert("RGBA")
far = L("backgrounds/home_farm/far.png")
villa = L("sprites/villa/stage7.png"); villa = villa.crop(villa.getchannel("A").getbbox())
pine = L("sprites/trees/umbrella_pine_1.png"); pine = pine.crop(pine.getchannel("A").getbbox())
dog = L("sprites/dog/east.png"); dog = dog.crop(dog.getchannel("A").getbbox())
bushes = [L(f"sprites/lavender/bloom_{i}.png") for i in (1, 2, 3)] + [L("sprites/lavender/bloom_test.png")]
bushes += [b.transpose(Image.FLIP_LEFT_RIGHT) for b in bushes]

def shadow(w, h, alpha=80):
    s = Image.new("RGBA", (w, h), (0, 0, 0, 0)); p = s.load()
    for x in range(w):
        for y in range(h):
            if ((x - w / 2 + .5) / (w / 2)) ** 2 + ((y - h / 2 + .5) / (h / 2)) ** 2 <= 1:
                p[x, y] = (50, 34, 40, alpha)
    return s

rng = random.Random(5)
SOIL = 230
plan = []
for r, base in enumerate([SOIL + 16, SOIL + 30, SOIL + 44]):
    x = -60 + (r % 2) * 10
    while x < W + 60:
        if not (300 <= x <= 330):
            plan.append((x, base, rng.randrange(len(bushes))))
        x += 20
noise = np.random.default_rng(2).random((H, W + 160))

def frame(cam):
    f = Image.new("RGBA", (W, H))
    off = round(cam * 3)
    bg = np.asarray(far)
    bg = np.pad(bg, ((0, 0), (8, 8), (0, 0)), mode="edge")[:, 8 - off:8 - off + W]
    f.alpha_composite(Image.fromarray(bg))
    vx = 252 + round(cam * 8)
    f.alpha_composite(shadow(villa.width + 10, 8, 70), (vx - 5, SOIL - 6))
    f.alpha_composite(villa, (vx, SOIL - villa.height + 1))
    px_ = -14 + round(cam * 14)
    f.alpha_composite(shadow(70, 7, 80), (px_ + pine.width // 2 - 35, SOIL - 4))
    f.alpha_composite(pine, (px_, SOIL + 2 - pine.height))
    fo = round(cam * 18)
    soil = np.zeros((H - SOIL, W, 4), np.uint8)
    for y in range(H - SOIL):
        base = np.array([118, 84, 56]) if y % 7 not in (0, 1) else np.array([100, 70, 46])
        n = noise[SOIL + y, 80 - fo:80 - fo + W]
        row = np.tile(base, (W, 1)).astype(int)
        row[n < .05] += 10; row[(n >= .05) & (n < .1)] -= 12
        soil[y, :, :3] = np.clip(row, 0, 255); soil[y, :, 3] = 255
    f.alpha_composite(Image.fromarray(soil), (0, SOIL))
    sh = shadow(24, 5, 90)
    for x, base, i in plan:
        f.alpha_composite(sh, (x + 4 + fo, base - 4))
        f.alpha_composite(bushes[i], (x + fo, base - 31))
    dx = 302 + fo
    f.alpha_composite(shadow(dog.width, 5, 90), (dx, SOIL + 26))
    f.alpha_composite(dog, (dx, SOIL + 29 - dog.height))
    return f.convert("RGB")

still = frame(0)
still.save("design/Art tests/phase1/phase1_scene.png")
still.resize((W * 4, H * 4), Image.NEAREST).save("design/Art tests/phase1/phase1_scene_x4.png")
frames = [frame(math.sin(i / 32 * 2 * math.pi)).resize((W * 2, H * 2), Image.NEAREST) for i in range(32)]
frames[0].save("design/Art tests/phase1/phase1_parallax.gif", save_all=True, append_images=frames[1:], duration=90, loop=0)
print("done")
