# Otium: Claude Code Guide

A cozy semi-idle Roman lavender-farming game for Steam (Windows, Mac, Linux, Steam Deck), with a full-window mode and a desktop idle strip. Claude writes the code and generates the art; the user tests, gives feedback, adds music and sound effects, and handles marketing.

## Where things are

| Path | What |
|---|---|
| `game/` | Godot 4.7 project (GDScript, Compatibility renderer) |
| `design/` | Design docs: `Game-design.md` (the whole game), `Game-plan.md` (build phases), `Asset-list.md`, `Business-plan.md`, competitor research in `reports/` |
| `design/Art tests/` | Early art experiments and the reference scene |
| `tools/art/pixellab.py` | Art pipeline: generate with PixelLab, slice sheets, clean stray pixels; every paid call is logged in `tools/art/ledger.csv` |
| `.env` | `PIXELLAB_TOKEN` (git-ignored) |

Godot executable: `C:\Users\evand\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

## Fixed decisions

- Base resolution 480 x 270, whole-number scaling, extra scene shown instead of black bars (`stretch/aspect = expand`, `scale_mode = integer`), nearest filtering.
- All game data (crops, prices, timings, upgrades) lives in data files, never hard-coded.
- Art: one cohesive background painting per land; nothing that moves inside a background; everything that moves or changes is a separate sprite; buildings sit on fixed anchor spots with one sprite per stage.
- Characters are generated outline-free with natural proportions to match the backgrounds.
- No punishment for being away: crops never die; the only offline limit is a full storeroom.

## Conventions

- Markdown docs: no em dashes, and write dollar signs as `\$`.
- Comments: only for a non-obvious reason, one line.
- Commit to `main`.

## Running and checking the game

- Tests: `Godot_..._console.exe --headless --path game --script res://tests/test_simulation.gd` (and `test_scene.gd`).
- Exact screenshots: `Godot_..._console.exe --path game --quit-after 300 -- --demo --shot=OUT.png`, plus `--strip`, `--strip --solid`, `--hour=22.5`, `--villa=2`, `--send-cart`. `--demo` never touches the real save.
- Always wrap capture runs in `timeout 60` and pass `--quit-after`: a script error stops the scene before it can quit, and the window then waits forever.
- The movie writer (`--write-movie`) always records at 480x270, so it cannot show the desktop strip's real shape; use `--shot` for that.
