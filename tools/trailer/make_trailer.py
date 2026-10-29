"""Make the Steam trailer and the vertical shorts for YouTube Shorts, Reels and TikTok: record each scripted shot in
movie mode, then cut them together with the captions, the end card and the music, all in Godot.

Usage:
  python tools/trailer/make_trailer.py              records any shot not yet recorded, then renders the trailer
  python tools/trailer/make_trailer.py shots ruin   records just those shots again
  python tools/trailer/make_trailer.py render       renders from the shots already recorded
  python tools/trailer/make_trailer.py render 70    renders a preview from 70 seconds in, into recordings/work/
  Add --cut=NAME to any of these for one of the shorts: ruin_to_life, day_1_vs_day_120, pet_the_dog or cozy_sounds.
  The shorts share their shots, recorded close up at 1080x1920.

Finished videos go to recordings/videos/, named in VIDEOS below; the shot frames they are cut from are kept in
recordings/work/ so a change to the edit renders again in a minute or two. The shots are scripted in
game/tools/trailer/shots.gd and the edits, with their captions and music, in game/tools/trailer/edit.gd. Every shot
plays a demo farm, so the real save is never touched.
"""
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VIDEOS = ROOT / "recordings" / "videos"
WORK = ROOT / "recordings" / "work"
# Each cut's finished file.
NAMES = {
    "trailer": "steam_trailer.avi",
    "ruin_to_life": "short_ruin_to_life.avi",
    "day_1_vs_day_120": "short_day_1_vs_day_120.avi",
    "pet_the_dog": "short_you_can_pet_the_dog.avi",
    "cozy_sounds": "short_cozy_sounds.avi",
}

FPS = 30
GODOT = (Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
         / "Godot_v4.7.2-stable_win64_console.exe")
HUD_OFF = ["--no-hud"]
# name: (seconds to record, game flags). The edit takes its part of each from edit.gd; a shot starts a moment early
# so pets and helpers have walked into place before the part that is used. A --villa= stage comes after --maxed, which
# builds the villa to the top. Shots are recorded without ambience, which the edit plays unbroken under the cuts.
SHOTS = {
    "ruin": (7, ["--villa=1", "--zone=home", "--hour=8.5", *HUD_OFF]),
    "plant": (7, ["--villa=2", "--zone=home", "--hour=9.5", "--coins=240"]),
    "cart": (6, ["--villa=3", "--zone=home", "--hour=10", "--coins=1840"]),
    # The cart comes home after the trip to town, so its purse starts where the market's selling left it.
    "coins": (19, ["--villa=3", "--zone=home", "--hour=10", "--coins=2036"]),
    "helper": (6, ["--maxed", "--villa=4", "--zone=home", "--hour=9", *HUD_OFF]),
    "bakery": (6, ["--estate", "--zone=yard", "--hour=19.3", *HUD_OFF]),
    "restore": (7, ["--villa=1", "--zone=home", "--hour=9", *HUD_OFF]),
    "villa": (7, ["--villa=3", "--zone=home", "--hour=11", *HUD_OFF]),
    "grand": (7, ["--maxed", "--villa=6", "--zone=home", "--hour=16", *HUD_OFF]),
    "bakery_ui": (8, ["--estate", "--zone=yard", "--hour=10", "--coins=2400", "--aureus=0"]),
    "market_ui": (8, ["--villa=3", "--town", "--hour=11", "--coins=1840", "--aureus=0"]),
    "shrine_ui": (7, ["--maxed", "--zone=home", "--hour=16", "--coins=48250", "--aureus=12"]),
    "stages": (16, ["--villa=1", "--zone=home", "--hour=10", "--scale=5", *HUD_OFF]),
    "cat": (5, ["--maxed", "--zone=home", "--hour=11", *HUD_OFF]),
    "donkey": (5, ["--maxed", "--zone=home", "--hour=11", *HUD_OFF]),
    "goat": (5, ["--maxed", "--zone=pasture", "--hour=10", *HUD_OFF]),
    "stork": (5, ["--maxed", "--zone=home", "--hour=11", *HUD_OFF]),
    "pasture": (6, ["--maxed", "--zone=pasture", "--hour=10", *HUD_OFF]),
    "vineyard": (6, ["--maxed", "--zone=vineyard", "--hour=16.5", *HUD_OFF]),
    "grove": (6, ["--maxed", "--zone=grove", "--hour=14", "--weather=rain", *HUD_OFF]),
    "pet": (6, ["--maxed", "--zone=home", "--hour=11", *HUD_OFF]),
    "hoopoe": (7, ["--maxed", "--zone=home", "--hour=10", *HUD_OFF]),
    "inside": (6, ["--maxed", "--furnish=all", "--inside=pet", "--hour=21"]),
    "timelapse": (8, ["--maxed", "--zone=home", "--hour=1.2", *HUD_OFF]),
    "night": (9, ["--maxed", "--zone=home", "--hour=22", "--aurora", *HUD_OFF]),
    "endcard": (9, ["--maxed", "--zone=vineyard", "--hour=19.6", *HUD_OFF]),
}
# The trailer's shots, and each vertical cut's. Vertical shots are all without the interface, since its panels are laid
# out for a wide screen.
CUT_SHOTS = {
    "trailer": ["ruin", "restore", "plant", "cart", "market_ui", "coins", "villa", "bakery_ui", "pasture", "vineyard", "grove",
                "grand", "shrine_ui", "pet", "timelapse", "inside", "night", "endcard"],
    "ruin_to_life": ["ruin", "villa", "plant", "helper", "bakery", "pasture", "vineyard", "pet", "hoopoe", "timelapse",
                     "night", "endcard"],
    "day_1_vs_day_120": ["stages", "endcard"],
    "pet_the_dog": ["pet", "cat", "donkey", "goat", "stork", "hoopoe", "endcard"],
    "cozy_sounds": ["grove", "bakery", "plant", "pasture", "night", "endcard"],
}
# Each format's frame, the estate's pixel scale in it, and where its shots are kept: the shorts' narrow frame shows the
# estate close up.
FORMATS = {
    "trailer": {"shots": WORK / "trailer_shots", "size": (1920, 1080), "scale": 4},
    "short": {"shots": WORK / "short_shots", "size": (1080, 1920), "scale": 6},
}


def godot(args, size):
    """Runs Godot at the cut's size, which movie mode takes from the project's window setting when the game starts."""
    override = ROOT / "game" / "override.cfg"
    if override.exists():
        sys.exit(f"{override} already exists; move it aside first")
    override.write_text(f"[display]\n\nwindow/size/window_width_override={size[0]}\nwindow/size/window_height_override={size[1]}\n\n"
                        "[editor]\n\nmovie_writer/mjpeg_quality=0.95\n")
    try:
        subprocess.run([str(GODOT), "--path", str(ROOT / "game"), *args], check=True)
    finally:
        override.unlink()


def window(fmt):
    return [f"--window={fmt['size'][0]}x{fmt['size'][1]}", f"--scale={fmt['scale']}"]


def record(name, fmt):
    seconds, flags = SHOTS[name]
    if fmt is FORMATS["short"] and "--no-hud" not in flags:
        flags = flags + HUD_OFF
    folder = fmt["shots"] / name
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    # A .png movie is written as numbered frames with the sound beside them in a .wav of the same name.
    godot(["--write-movie", str(folder / "f.png"), "--fixed-fps", str(FPS), "--quit-after", str(seconds * FPS),
           "--", "--demo", "--no-music", "--no-ambience", *window(fmt), f"--trailer-shot={name}", *flags, "--quiet-start"], fmt["size"])


def render(fmt, cut, start=0.0):
    """Renders the cut, or with a start time a preview from that moment on into the work folder."""
    out = WORK / "preview.avi" if start else VIDEOS / NAMES[cut]
    out.parent.mkdir(parents=True, exist_ok=True)
    # The edit quits when it ends; the frame limit only stops a run whose script failed to load from going on forever.
    godot(["--write-movie", str(out), "--fixed-fps", str(FPS), "--quit-after", str(200 * FPS), "res://tools/trailer/edit.tscn",
           "--", "--readonly", *window(fmt), f"--shots={fmt['shots']}", f"--cut={cut}", f"--from={start}"],
          fmt["size"])
    print(f"ready: {out}")


def main():
    args = sys.argv[1:]
    cut = "trailer"
    for a in args:
        if a.startswith("--cut="):
            cut = a.split("=", 1)[1]
            if cut not in NAMES:
                sys.exit(f"no cut named {cut}; the cuts are {', '.join(NAMES)}")
    args = [a for a in args if not a.startswith("--cut=")]
    fmt = FORMATS["trailer" if cut == "trailer" else "short"]
    names = CUT_SHOTS[cut]
    if args[:1] == ["shots"]:
        for name in args[1:] or names:
            record(name, fmt)
        return
    if args[:1] != ["render"]:
        for name in names:
            if not (fmt["shots"] / name / "f.wav").exists():
                record(name, fmt)
    render(fmt, cut, float(args[1]) if args[:1] == ["render"] and len(args) > 1 else 0.0)


if __name__ == "__main__":
    main()
