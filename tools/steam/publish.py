"""Build the game and upload it to Steam, so everyone on the chosen branch gets the update automatically.

Usage:
  python tools/steam/publish.py playtest            upload to the Playtest app, live on its test branch
  python tools/steam/publish.py game                upload to the main game, live on its test branch
  python tools/steam/publish.py playtest --note "Faster cart trips"
  python tools/steam/publish.py game --dry-run      build, sign and lay out every platform, but do not upload

The Steam account, app and depot ids are in tools/steam/steam.json; a depot left at 0 is skipped. Godot exports every
platform here on Windows, then tools/steam/wsl_build.sh takes over inside WSL: a Mac app copied through Windows loses
its file permissions and will not open, so the builds are laid out, the Mac app signed and notarized, and the upload
made with Valve's Linux steamcmd there. design/Steam-publishing.md has the one-time setup.
Steam only lets a script make a build live on a branch other than the default one, so testers choose that branch
once in the game's Properties, Betas; builds for the default branch are set live on the Steamworks site.
"""
import argparse
import datetime
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = Path(__file__).with_name("steam.json")
GODOT = Path.home() / "AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
# The Godot export preset and the file it writes, for each platform a depot can hold.
PRESETS = {
    "windows": ("Windows", "Farmus Maximus.exe"),
    "macos": ("macOS", "Farmus Maximus.zip"),
    "linux": ("Linux", "Farmus Maximus.x86_64"),
}


def fail(text):
    sys.exit("publish: " + text)


def wsl_path(path):
    return "/mnt/" + path.drive[0].lower() + path.as_posix()[2:]


def wsl(*args):
    return subprocess.run(["wsl.exe", "--", *args], capture_output=True, text=True, encoding="utf-8", errors="replace")


def export(platform, folder):
    preset, name = PRESETS[platform]
    folder.mkdir(parents=True)
    result = subprocess.run([str(GODOT), "--headless", "--path", str(ROOT / "game"), "--export-release", preset, str(folder / name)],
                            capture_output=True, text=True)
    if not (folder / name).exists():
        fail(f"the {platform} export failed:\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}")
    print(f"built {platform}: {folder / name}")


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
    parser.add_argument("target", choices=["playtest", "game"])
    parser.add_argument("--note", default="")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text())
    target = config["targets"][args.target]
    if not target["app_id"] or not any(target["depots"].values()):
        fail(f"set the {args.target} app id and depot ids in {CONFIG} first (see design/Steam-publishing.md)")
    if not config["account"] and not args.dry_run:
        fail(f"set the Steam account that uploads builds in {CONFIG} first")
    home = wsl("sh", "-c", "echo $HOME").stdout.strip()
    if not home or wsl("test", "-x", f"{home}/farmus-steam/steamcmd/steamcmd.sh").returncode != 0:
        fail("WSL is not set up for uploads yet; run tools/steam/wsl_setup.sh once (see design/Steam-publishing.md)")
    stage = ROOT / "builds" / "steam" / args.target
    if stage.exists():
        shutil.rmtree(stage)
    for platform, depot in target["depots"].items():
        if depot:
            export(platform, stage / platform)
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
             "(see design/Steam-publishing.md) and run this again")
    print(f"uploaded and live on the '{target['branch']}' branch of app {target['app_id']}")


if __name__ == "__main__":
    main()
