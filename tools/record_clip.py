"""Record a clip of the game at 1920x1080 for the trailer or social posts, using Godot's movie mode.

Movie mode renders every frame in full, however long that takes, so the clip never stutters, and writes picture and
sound together into one .avi file that video editors (DaVinci Resolve, Shotcut, Premiere) import directly.
The clip always plays a demo farm, so the real save is never touched.

Usage: python tools/record_clip.py NAME SECONDS [game flags ...]
  python tools/record_clip.py lavender 8 --estate --zone=home --hour=18 --no-hud
  python tools/record_clip.py hoopoe 6 --estate --zone=home --hour=10 --no-hud --hoopoe
Writes marketing/recordings/clips/NAME.avi (kept out of git). Useful flags: --estate, --maxed, --zone=, --hour=, --weather=,
--no-hud, --galaxy, --rainbow, --hoopoe, --greet, --panel=, --inside (see game/scripts/autoload/dev.gd for all).
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = (Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
         / "Godot_v4.7.2-stable_win64_console.exe")
FPS = 30
# Movie mode takes its size from the project's window setting when the game starts, so 1080p is asked for there.
OVERRIDE = """[display]

window/size/window_width_override=1920
window/size/window_height_override=1080

[editor]

movie_writer/mjpeg_quality=0.95
"""


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    name, seconds, flags = sys.argv[1], float(sys.argv[2]), sys.argv[3:]
    override = ROOT / "game" / "override.cfg"
    if override.exists():
        sys.exit(f"{override} already exists; move it aside first")
    out = ROOT / "marketing" / "recordings" / "clips" / f"{name}.avi"
    out.parent.mkdir(parents=True, exist_ok=True)
    if "--demo" not in flags:
        flags = ["--demo"] + flags
    override.write_text(OVERRIDE)
    try:
        subprocess.run([str(GODOT), "--path", str(ROOT / "game"), "--write-movie", str(out), "--fixed-fps", str(FPS),
                        "--quit-after", str(int(seconds * FPS)), "--", "--window=1920x1080", *flags], check=True)
    finally:
        override.unlink()
    print(f"clip ready: {out}")


if __name__ == "__main__":
    main()
