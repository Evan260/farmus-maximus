"""Make the Steam store page's pictures: the capsules, the library art, the page background, the icons and the
screenshots, all rendered by the game itself so the pixel art stays exact.

Scenes are rendered at one screen pixel to the game pixel and enlarged a whole number of times, with the logo laid
over the sky at the same pixel size; screenshots are taken at 1920x1080 as the game draws them. Every render plays a
demo farm, so the real save is never touched.

Usage: python tools/steam/make_store_art.py
The screenshots are taken straight into store/steam_page/screenshots, and the pieces the layout crops or combines (the
scenes, the strip and the desktop) into a folder of their own that is deleted afterwards, so store/steam_page is the
only place the store pictures are kept. Writes store/steam_page/ (see README.txt there for which file goes in which
Steamworks slot).
"""
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "store" / "steam_page"
# The pieces the layout is made from, in a folder of their own for the length of the run.
RENDERS = Path()
GODOT = (Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
         / "Godot_v4.7.2-stable_win64_console.exe")
LOGO = ROOT / "game" / "tools" / "trailer" / "logo.png"
# The name without its laurel, for pictures too narrow for the laurel or too small to read the name beside it.
PLAIN_LOGO = LOGO.with_name("logo_plain.png")
# The square profile picture; the one in marketing/ has rounded corners, which a square store icon would show black.
PROFILE = ROOT / "tools" / "art" / "profile_square.png"
# The game's road runs along y 286 at the foot of every render, and the villa's doorway is at x 851.
VILLA_X = 851
VINEYARD_X = 1680
QUIET = ["--demo", "--quiet-start", "--no-music"]
# A farm some weeks in: a believable purse, and a few of the rare gold coins rather than the demo farm's thousand.
EARNED = ["--coins=48250", "--aureus=12"]
# name: (window size, extra flags). Scenes are taken at one screen pixel to the game pixel, without the interface.
SCENES = {
    "vineyard_gold": ((1600, 450), ["--maxed", "--zone=vineyard", "--hour=18.2"]),
    "home_gold": ((1400, 700), ["--maxed", "--zone=home", "--hour=18.2"]),
    "hero": ((960, 310), ["--maxed", "--zone=home", "--hour=18.2"]),
    "night": ((719, 405), ["--maxed", "--zone=home", "--hour=22", "--aurora=horizontal"]),
}
# name: flags. Screenshots are taken at 1920x1080 as the game draws them, most with the interface showing.
SCREENSHOTS = {
    "01_estate_golden_hour": ["--maxed", "--zone=home", "--hour=17.6", *EARNED],
    "03_workshop_window": ["--maxed", "--zone=yard", "--hour=10.5", *EARNED, "--panel=bakery"],
    "04_vineyard": ["--maxed", "--zone=vineyard", "--hour=15", *EARNED],
    "05_pasture": ["--maxed", "--zone=pasture", "--hour=9", "--no-hud"],
    "06_olive_grove_in_rain": ["--maxed", "--zone=grove", "--hour=13", "--weather=rain", "--no-hud"],
    "07_market_town": ["--maxed", "--town", "--hour=11", *EARNED],
    "08_farmhouse_at_night": ["--maxed", "--furnish=all", "--inside", "--hour=21", *EARNED],
    "09_northern_lights": ["--maxed", "--zone=home", "--hour=22", "--aurora=horizontal", "--no-hud"],
    "10_where_it_begins": ["--villa=1", "--zone=home", "--hour=9", "--coins=240", "--aureus=0", "--trailer-shot=ruin"],
    "11_helpers": ["--maxed", "--zone=home", "--hour=10", *EARNED, "--panel=helpers"],
}
# The second screenshot is the farm as a strip along the bottom of a real desktop, marketing/desktop.png, the game's
# way of being played; without that screenshot it is left out.
sys.path.insert(0, str(ROOT / "tools" / "trailer"))
from make_trailer import desktop_frame  # noqa: E402
DESKTOP_SHOT = "02_on_your_desktop"


def shoot(path, size, flags, scale=None):
    """Takes one picture with the game, once its scene has settled, at the given window size."""
    args = [str(GODOT), "--path", str(ROOT / "game"), "--", *QUIET, f"--window={size[0]}x{size[1]}", *flags,
            f"--shot={path}"]
    if scale:
        args.insert(-1, f"--scale={scale}")
    subprocess.run(args, check=True, capture_output=True)
    print("rendered", path.name)


def render_all():
    for name, (size, flags) in SCENES.items():
        shoot(RENDERS / f"{name}.png", size, flags + ["--no-hud"], scale=1)
    (OUT / "screenshots").mkdir(parents=True, exist_ok=True)
    for name, flags in SCREENSHOTS.items():
        path = OUT / "screenshots" / f"{name}.png"
        shoot(path, (1920, 1080), flags)
        Image.open(path).convert("RGB").save(path)
    # The strip comes out on a see-through background at three screen pixels to the game pixel.
    shoot(RENDERS / "strip.png", (1920, 332), ["--maxed", "--strip", "--strip-width=1920", "--hour=10", *EARNED,
                                                "--trailer-shot=profile"], scale=2)


def camera_left(render, centre_x):
    """The game x of a render's left edge: its zone's centre, held back by the estate's ends."""
    return min(max(0, centre_x - render.width // 2), 2400 - render.width)


def view(name, centre_x, size, scale, zone_centre, lift=0):
    """The part of a scene render, size screen pixels when enlarged scale times, centred on a game x, its foot on the
    road or lift game pixels above it."""
    render = Image.open(RENDERS / f"{name}.png").convert("RGB")
    w, h = -(-size[0] // scale), -(-size[1] // scale)
    left = centre_x - camera_left(render, zone_centre) - w // 2
    foot = render.height - lift
    part = render.crop((left, foot - h, left + w, foot))
    big = part.resize((w * scale, h * scale), Image.NEAREST)
    return big.crop((0, big.height - size[1], size[0], big.height))


def logo(scale, plain=False):
    """The logo trimmed to its drawn pixels, enlarged scale times."""
    pic = Image.open(PLAIN_LOGO if plain else LOGO).convert("RGBA")
    pic = pic.crop(pic.getbbox())
    return pic.resize((pic.width * scale, pic.height * scale), Image.NEAREST)


def with_logo(base, mark, top):
    out = base.convert("RGBA")
    out.alpha_composite(mark, ((out.width - mark.width) // 2, top))
    return out.convert("RGB")


def layout():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "screenshots").mkdir(exist_ok=True)
    home = 720
    capsules = {
        # Wide pictures look over the vineyard, whose low buildings leave the sky clear for the logo.
        "header_capsule_920x430.png": (view("vineyard_gold", VINEYARD_X, (920, 430), 2, VINEYARD_X), logo(2), 22),
        # The small capsule is mostly the name, over the sky and hills so it reads at a glance.
        "small_capsule_462x174.png": (view("vineyard_gold", VINEYARD_X, (462, 174), 2, VINEYARD_X, lift=95), logo(2, True), 10),
        # Taller pictures stand the logo above the villa itself.
        "main_capsule_1232x706.png": (view("home_gold", VILLA_X, (1232, 706), 2, home), logo(2), 70),
        "vertical_capsule_748x896.png": (view("home_gold", VILLA_X, (748, 896), 2, home), logo(2), 150),
        "library_capsule_600x900.png": (view("home_gold", VILLA_X, (600, 900), 2, home), logo(2, True), 150),
    }
    for name, (base, mark, top) in capsules.items():
        with_logo(base, mark, top).save(OUT / name)
    # Steam's library header is the same picture as the store's header capsule.
    Image.open(OUT / "header_capsule_920x430.png").save(OUT / "library_header_920x430.png")
    # The library hero carries no logo: Steam lays the separate library logo over it.
    view("hero", home, (3840, 1240), 4, home).save(OUT / "library_hero_3840x1240.png")
    mark = logo(4)
    canvas = Image.new("RGBA", (1280, mark.height), (0, 0, 0, 0))
    canvas.alpha_composite(mark, ((1280 - mark.width) // 2, 0))
    canvas.save(OUT / "library_logo_1280_transparent.png")
    # The page background sits behind the store page's text, so it is the estate by night, darkened further.
    night = view("night", home, (1438, 810), 2, home)
    night.point(lambda v: int(v * 0.55)).save(OUT / "page_background_1438x810.png")
    icon = Image.open(PROFILE).convert("RGB")
    icon.resize((184, 184), Image.LANCZOS).save(OUT / "community_icon_184x184.jpg", quality=95)
    icon.save(OUT / "app_icon.ico", sizes=[(16, 16), (32, 32), (48, 48), (256, 256)])
    # A screenshot no longer in the list is taken off the page.
    for old in (OUT / "screenshots").glob("*.png"):
        if old.stem not in SCREENSHOTS and old.stem != DESKTOP_SHOT:
            old.unlink()
    frame = desktop_frame((1920, 1080), RENDERS / "desktop_1920x1080.png")
    if frame:
        desk = Image.open(frame[0]).convert("RGBA")
        strip = Image.open(RENDERS / "strip.png").convert("RGBA")
        desk.alpha_composite(strip, ((desk.width - strip.width) // 2, desk.height - frame[1] - strip.height))
        desk.convert("RGB").save(OUT / "screenshots" / f"{DESKTOP_SHOT}.png")
    print("laid out", OUT)


def main():
    global RENDERS
    with tempfile.TemporaryDirectory() as tmp:
        RENDERS = Path(tmp)
        render_all()
        layout()


if __name__ == "__main__":
    main()
