"""Build the game and upload it to Steam, so everyone on the chosen branch gets the update automatically.

Usage:
  python tools/steam/publish.py playtest            upload to the Playtest app, live on its test branch
  python tools/steam/publish.py game                upload to the main game, live on its test branch
  python tools/steam/publish.py playtest --note "Faster cart trips"
  python tools/steam/publish.py demo               upload the free demo, live on its test branch
  python tools/steam/publish.py game --dry-run      build, sign and lay out every platform, but do not upload

The Steam account, app and depot ids are in tools/steam/steam.json; a depot left at 0 is skipped. Godot exports every
platform here on Windows, then tools/steam/wsl_build.sh takes over inside WSL: a Mac app copied through Windows loses
its file permissions and will not open, so the builds are laid out, the Mac app signed and notarized, and the upload
made with Valve's Linux steamcmd there. docs/Steam-publishing.md has the one-time setup.
Steam only lets a script make a build live on a branch other than the default one, so testers choose that branch
once in the game's Properties, Betas; builds for the default branch are set live on the Steamworks site.
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = Path(__file__).with_name("steam.json")
GODOT = os.environ.get("GODOT", str(Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"))
# The Godot export preset and the file it writes, for each platform a depot can hold.
PRESETS = {
    "windows": ("Windows", "Farmus Maximus.exe"),
    "macos": ("macOS", "Farmus Maximus.zip"),
    "linux": ("Linux", "Farmus Maximus.x86_64"),
}
# The demo is the same project exported with its own presets, which stop at the villa rustica and the first two zones.
DEMO_PRESETS = {
    "windows": ("Windows demo", "Farmus Maximus Demo.exe"),
    "macos": ("macOS demo", "Farmus Maximus Demo.zip"),
    "linux": ("Linux demo", "Farmus Maximus Demo.x86_64"),
}


CREDITS_FILE = "Credits and licences.txt"
LAUNCHER = "Farmus Maximus - everything unlocked.bat"


def fail(text):
    sys.exit("publish: " + text)


def wsl_path(path):
    return "/mnt/" + path.drive[0].lower() + path.as_posix()[2:]


def wsl(*args):
    return subprocess.run(["wsl.exe", "--", *args], capture_output=True, text=True, encoding="utf-8", errors="replace")


def export(platform, folder, demo, launcher=True):
    preset, name = (DEMO_PRESETS if demo else PRESETS)[platform]
    folder.mkdir(parents=True)
    result = subprocess.run([str(GODOT), "--headless", "--path", str(ROOT / "game"), "--export-release", preset, str(folder / name)],
                            capture_output=True, text=True)
    if not (folder / name).exists():
        fail(f"the {platform} export failed:\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}")
    # The licences of Godot and of the stork recording ask for their notice to ship with the game, so it goes beside it.
    credits = folder / CREDITS_FILE
    subprocess.run([str(GODOT), "--headless", "--path", str(ROOT / "game"), "--script", "res://tools/write_credits.gd", "--", f"--out={credits}"],
                   capture_output=True, text=True)
    if not credits.exists():
        fail(f"could not write {CREDITS_FILE} for {platform}")
    if platform == "windows" and not demo and launcher:
        write_launcher(folder, name)
    print(f"built {platform}: {folder / name}")


def write_launcher(folder, exe):
    """A launcher beside the game that opens the maxed farm, with everything built and unlocked, which saves nothing.
    It is for local and GitHub release builds only: Steam builds leave it out, and every depot excludes it too."""
    (folder / LAUNCHER).write_bytes((
        "@echo off\r\n"
        "rem Opens the farm with everything built, bought and unlocked, to look around; nothing is saved.\r\n"
        f'start "" "%~dp0{exe}" -- --max-state\r\n').encode("ascii"))


def vdf(target, note, content, output):
    depots = "\n".join(
        f'''\t\t"{depot}"
\t\t{{
\t\t\t"FileMapping"
\t\t\t{{
\t\t\t\t"LocalPath" "{platform}/*"
\t\t\t\t"DepotPath" "."
\t\t\t\t"recursive" "1"
\t\t\t}}
\t\t\t"FileExclusion" "*{LAUNCHER}"
\t\t}}''' for platform, depot in target["depots"].items() if depot)
    return f'''"AppBuild"
{{
\t"AppID" "{target["app_id"]}"
\t"Desc" "{note}"
\t"ContentRoot" "{content}"
\t"BuildOutput" "{output}"
\t"SetLive" "{target["branch"]}"
\t"Depots"
\t{{
{depots}
\t}}
}}
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("target", choices=["playtest", "game", "demo"])
    parser.add_argument("--note", default="")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text())
    target = config["targets"][args.target]
    if not args.dry_run:
        if not target["app_id"] or not any(target["depots"].values()):
            fail(f"set the {args.target} app id and depot ids in {CONFIG} first (see docs/Steam-publishing.md)")
        if not config["account"]:
            fail(f"set the Steam account that uploads builds in {CONFIG} first")
    home = wsl("sh", "-c", "echo $HOME").stdout.strip()
    if not home:
        fail("WSL did not answer; check that Ubuntu is installed (wsl --list)")
    if not args.dry_run and wsl("test", "-x", f"{home}/farmus-steam/steamcmd/steamcmd.sh").returncode != 0:
        fail("WSL is not set up for uploads yet; run tools/steam/wsl_setup.sh once (see docs/Steam-publishing.md)")
    stage = ROOT / "builds" / "steam" / args.target
    if stage.exists():
        shutil.rmtree(stage)
    for platform, depot in target["depots"].items():
        # A dry run builds every platform, so the whole layout can be checked before Steam has given any ids.
        if depot or args.dry_run:
            export(platform, stage / platform, args.target == "demo", launcher=False)
    work = f"{home}/farmus-steam/{args.target}"
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    note = f"{datetime.date.today()} {commit} {args.note}".strip().replace('"', "'")
    (stage / "app_build.vdf").write_text(vdf(target, note, f"{work}/content", f"{work}/output"), newline="\n")
    command = ["bash", wsl_path(Path(__file__).with_name("wsl_build.sh")), wsl_path(stage), work, config["account"]]
    if args.dry_run:
        command.append("--dry-run")
    result = wsl(*command)
    print(result.stdout[-3000:], result.stderr[-2000:], sep="\n")
    if result.returncode != 0:
        fail("the WSL half stopped; the lines above say why")
    if args.dry_run:
        return
    if "Successfully finished AppID" not in result.stdout:
        fail("the upload did not finish; if steamcmd asked for a password or a Steam Guard code, log in by hand once "
             "(see docs/Steam-publishing.md) and run this again")
    print(f"uploaded and live on the '{target['branch']}' branch of app {target['app_id']}")


if __name__ == "__main__":
    main()
