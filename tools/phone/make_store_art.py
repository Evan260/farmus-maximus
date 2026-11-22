"""Make the phone app stores' pictures: the Google Play icon, feature graphic and phone and tablet screenshots, and
the App Store icon and iPhone and iPad screenshots, all rendered by the game itself so the pixel art stays exact.

Screenshots are taken with the phone interface (--phone) at each store's exact size, so the game picks its own whole
number scale for that screen's shape, as it would on the device. The feature graphic is the estate rendered at one
screen pixel to the game pixel and enlarged twice, with the logo laid over the sky at the same pixel size, as the Steam
capsules are. The icons are tools/art/icon_square.png enlarged a whole number of times. Every render plays the maxed
farm, so the real save is never touched.

Usage: python tools/phone/make_store_art.py
Writes store/google_play/ and store/app_store/ (see README.txt in each for which file goes where).
"""
import ctypes
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PLAY = ROOT / "store" / "google_play"
APPLE = ROOT / "store" / "app_store"
GODOT = (Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
         / "Godot_v4.7.2-stable_win64_console.exe")
LOGO = ROOT / "game" / "tools" / "trailer" / "logo.png"
ICON = ROOT / "tools" / "art" / "icon_square.png"
QUIET = ["--max-state", "--quiet-start", "--no-music", "--no-ambience"]
# A farm some weeks in: a believable purse, and a few of the rare gold coins.
EARNED = ["--coins=48250", "--aureus=12"]
# name: flags. Each is one scene, taken at every size that lists it.
SCENES = {
    "estate_golden_hour": ["--zone=home", "--hour=17.6", *EARNED],
    "grape_harvest": ["--zone=vineyard", "--hour=16.8", "--day=8", *EARNED],
    "market_town": ["--town", "--hour=11", *EARNED],
    "farmhouse_by_night": ["--furnish=all", "--inside", "--hour=21", *EARNED],
    # The night button and the money panel would sit over the northern lights, so this one scene leaves them out.
    "northern_lights": ["--zone=home", "--hour=23", "--weather=sun", "--aurora=horizontal", "--no-hud", "--shot-at=3"],
    "rainbow_over_the_pasture": ["--zone=pasture", "--hour=16", "--weather=cloudy", "--rainbow", "--shot-at=3", *EARNED],
    "bakery_window": ["--zone=yard", "--hour=10.5", "--panel=bakery", *EARNED],
    "journal": ["--zone=home", "--hour=10", "--panel=journal:animal:bees", *EARNED],
}
# An iPad's 4:3 screen crops the sides of the estate, so there the trailer's villa shot frames the farmhouse.
ON_VILLA = ["--trailer-shot=profile"]
# folder: (window size, scenes in upload order, extra flags per scene).
SETS = {
    PLAY / "phone_screenshots": ((1920, 1080), ["estate_golden_hour", "grape_harvest", "market_town", "farmhouse_by_night",
                                                "northern_lights", "rainbow_over_the_pasture", "bakery_window", "journal"], {}),
    PLAY / "tablet_7_inch_screenshots": ((1920, 1200), ["estate_golden_hour", "market_town", "farmhouse_by_night",
                                                        "northern_lights"], {}),
    PLAY / "tablet_10_inch_screenshots": ((2560, 1600), ["estate_golden_hour", "market_town", "farmhouse_by_night",
                                                         "northern_lights"], {}),
    # On the iPhone's wide screen the journal covers the money panel's words, so the rainbow takes its place.
    APPLE / "iphone_6.9_inch_screenshots": ((2868, 1320), ["estate_golden_hour", "grape_harvest", "market_town",
                                                           "farmhouse_by_night", "northern_lights",
                                                           "rainbow_over_the_pasture"],
                                            # The townsfolk walk under the iPhone's place buttons, so the town waits for a shopper.
                                            {"market_town": ["--shot-at=10.5"]}),
    APPLE / "ipad_13_inch_screenshots": ((2752, 2064), ["estate_golden_hour", "grape_harvest", "market_town",
                                                        "farmhouse_by_night", "northern_lights", "journal"],
                                         {"estate_golden_hour": ON_VILLA, "northern_lights": ON_VILLA}),
}
# The villa's doorway and the home zone's centre, in game x.
VILLA_X = 851
HOME_X = 720
# The feature graphic's foot sits this far above the road, which leaves the sky above the stork clear for the logo.
FEATURE_LIFT = 20
FEATURE_SCENE = ((1400, 700), ["--zone=home", "--hour=18.2", "--no-hud", "--scale=1"])


def shoot(path, size, flags, phone=True):
    """Takes one picture with the game, once its scene has settled, at the given window size."""
    args = [str(GODOT), "--path", str(ROOT / "game"), "--quit-after", "1500", "--", *QUIET, *(["--phone"] if phone else []),
            f"--window={size[0]}x{size[1]}", "--shot-at=2.5", *flags, f"--shot={path}", "--quit"]
    subprocess.run(args, check=True, capture_output=True, timeout=60)
    # The stores take no alpha channel in a screenshot.
    Image.open(path).convert("RGB").save(path)
    print("rendered", path.relative_to(ROOT) if ROOT in path.parents else path.name)


def screenshots():
    jobs = []
    for folder, (size, names, extra) in SETS.items():
        folder.mkdir(parents=True, exist_ok=True)
        for old in folder.glob("*.png"):
            old.unlink()
        for k, name in enumerate(names, 1):
            jobs.append((folder / f"{k:02d}_{name}.png", size, SCENES[name] + extra.get(name, [])))
    with ThreadPoolExecutor(3) as pool:
        list(pool.map(lambda job: shoot(*job), jobs))


def logo(scale):
    pic = Image.open(LOGO).convert("RGBA")
    pic = pic.crop(pic.getbbox())
    return pic.resize((pic.width * scale, pic.height * scale), Image.NEAREST)


def feature_graphic(tmp):
    """The estate at golden hour with the logo over its sky, 1024x500 at two screen pixels to the game pixel."""
    render_path = tmp / "feature_scene.png"
    shoot(render_path, *FEATURE_SCENE, phone=False)
    render = Image.open(render_path).convert("RGB")
    left = min(max(0, HOME_X - render.width // 2), 2400 - render.width)
    w, h = 512, 250
    x = VILLA_X - left - w // 2
    foot = render.height - FEATURE_LIFT
    art = render.crop((x, foot - h, x + w, foot)).resize((1024, 500), Image.NEAREST).convert("RGBA")
    mark = logo(2)
    art.alpha_composite(mark, ((art.width - mark.width) // 2, 12))
    art.convert("RGB").save(PLAY / "feature_graphic_1024x500.png")


def icons():
    icon = Image.open(ICON).convert("RGBA")
    icon.resize((512, 512), Image.NEAREST).save(PLAY / "icon_512.png")
    # Apple refuses an icon with an alpha channel, even a fully opaque one.
    icon.convert("RGB").resize((1024, 1024), Image.NEAREST).save(APPLE / "icon_1024.png")


def main():
    if sys.platform == "win32":
        # A pointer resting over a game window would light up a button, so it waits in the desktop's top corner.
        user32 = ctypes.windll.user32
        user32.SetCursorPos(user32.GetSystemMetrics(76), user32.GetSystemMetrics(77))
    PLAY.mkdir(parents=True, exist_ok=True)
    APPLE.mkdir(parents=True, exist_ok=True)
    icons()
    with tempfile.TemporaryDirectory() as tmp:
        feature_graphic(Path(tmp))
    screenshots()
    print("laid out", PLAY, "and", APPLE)


if __name__ == "__main__":
    main()
