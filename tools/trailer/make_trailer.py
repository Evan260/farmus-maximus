"""Make the Steam trailer, or with --short the vertical cut for YouTube Shorts, Reels and TikTok: record each scripted
shot in movie mode, then cut them together with the captions, the end card and the music, all in Godot.

Usage:
  python tools/trailer/make_trailer.py              records any shot not yet recorded, then renders the trailer
  python tools/trailer/make_trailer.py shots hook   records just those shots again
  python tools/trailer/make_trailer.py render       renders from the shots already recorded
  python tools/trailer/make_trailer.py render 70    renders a preview from 70 seconds in, into preview.avi
  Add --short to any of these for the vertical cut, which is recorded close up at 1080x1920 into recordings/short/.

The trailer goes to recordings/trailer/trailer.avi and the short to recordings/short/short.avi. The shots are scripted
in game/tools/trailer/shots.gd and both edits, with their captions and music, in game/tools/trailer/edit.gd. Every
shot plays a demo farm, so the real save is never touched.
"""
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

FPS = 30
GODOT = (Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
         / "Godot_v4.7.2-stable_win64_console.exe")
HUD_OFF = ["--no-hud"]
# name: (seconds to record, game flags). The edit takes its part of each from edit.gd; a shot starts a moment early
# so pets and helpers have walked into place before the part that is used.
SHOTS = {
    "hook": (10, ["--maxed", "--zone=home", "--hour=18.2", *HUD_OFF]),
    "ruin": (7, ["--villa=1", "--zone=home", "--hour=8.5", *HUD_OFF]),
    "plant": (7, ["--villa=2", "--zone=home", "--hour=9.5", "--coins=240"]),
    "cart": (6, ["--villa=3", "--zone=home", "--hour=10", "--coins=1840"]),
    "coins": (19, ["--villa=3", "--zone=home", "--hour=10", "--coins=1840"]),
    "helper": (6, ["--maxed", "--zone=home", "--hour=9", *HUD_OFF]),
    "bakery": (6, ["--estate", "--zone=yard", "--hour=19.3", *HUD_OFF]),
    "villa": (7, ["--villa=3", "--zone=home", "--hour=11", *HUD_OFF]),
    "pasture": (6, ["--maxed", "--zone=pasture", "--hour=10", *HUD_OFF]),
    "vineyard": (6, ["--maxed", "--zone=vineyard", "--hour=16.5", *HUD_OFF]),
    "grove": (6, ["--maxed", "--zone=grove", "--hour=14", "--weather=rain", *HUD_OFF]),
    "pet": (6, ["--maxed", "--zone=home", "--hour=11", *HUD_OFF]),
    "hoopoe": (7, ["--maxed", "--zone=home", "--hour=10", *HUD_OFF]),
    "inside": (6, ["--maxed", "--furnish=all", "--inside=pet", "--hour=21"]),
    "town": (6, ["--maxed", "--town", "--hour=11", *HUD_OFF]),
    "timelapse": (8, ["--maxed", "--zone=home", "--hour=1.2", *HUD_OFF]),
    "night": (9, ["--maxed", "--zone=home", "--hour=22", "--aurora", *HUD_OFF]),
    "endcard": (9, ["--maxed", "--zone=vineyard", "--hour=19.6", *HUD_OFF]),
}
# The short uses fewer shots, all without the interface, since its panels are laid out for a wide screen.
SHORT_SHOTS = ["ruin", "villa", "plant", "helper", "bakery", "pasture", "vineyard", "pet", "hoopoe", "timelapse", "night",
               "endcard"]
# Each cut's frame, and the estate's pixel scale in it: the short's narrow frame shows the estate close up.
FORMATS = {
    "trailer": {"out": ROOT / "recordings" / "trailer", "size": (1920, 1080), "scale": 4, "file": "trailer.avi"},
    "short": {"out": ROOT / "recordings" / "short", "size": (1080, 1920), "scale": 6, "file": "short.avi"},
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
    folder = fmt["out"] / "shots" / name
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    # A .png movie is written as numbered frames with the sound beside them in a .wav of the same name.
    godot(["--write-movie", str(folder / "f.png"), "--fixed-fps", str(FPS), "--quit-after", str(seconds * FPS),
           "--", "--demo", "--no-music", *window(fmt), f"--trailer-shot={name}", *flags, "--quiet-start"], fmt["size"])


def render(fmt, cut, start=0.0):
    """Renders the cut, or with a start time a preview from that moment on into preview.avi."""
    out = fmt["out"] / ("preview.avi" if start else fmt["file"])
    # The edit quits when it ends; the frame limit only stops a run whose script failed to load from going on forever.
    godot(["--write-movie", str(out), "--fixed-fps", str(FPS), "--quit-after", str(200 * FPS), "res://tools/trailer/edit.tscn",
           "--", "--readonly", *window(fmt), f"--shots={fmt['out'] / 'shots'}", f"--cut={cut}", f"--from={start}"],
          fmt["size"])
    print(f"ready: {out}")


def main():
    args = sys.argv[1:]
    cut = "short" if "--short" in args else "trailer"
    args = [a for a in args if a != "--short"]
    fmt = FORMATS[cut]
    names = SHORT_SHOTS if cut == "short" else list(SHOTS)
    if args[:1] == ["shots"]:
        for name in args[1:] or names:
            record(name, fmt)
        return
    if args[:1] != ["render"]:
        for name in names:
            if not (fmt["out"] / "shots" / name / "f.wav").exists():
                record(name, fmt)
    render(fmt, cut, float(args[1]) if args[:1] == ["render"] and len(args) > 1 else 0.0)


if __name__ == "__main__":
    main()
