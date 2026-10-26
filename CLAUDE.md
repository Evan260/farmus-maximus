# Farmus Maximus: Claude Code Guide

A cozy semi-idle Roman lavender-farming game for Steam (Windows, Mac, Linux, Steam Deck), with a full-window mode and a desktop idle strip. Claude writes the code and generates the art; the user tests, gives feedback, adds music and sound effects, and handles marketing.

## Where things are

| Path | What |
|---|---|
| `game/` | Godot 4.7 project (GDScript, Compatibility renderer) |
| `game/scripts/autoload/game_state.gd` | The estate's rules (`Game`); `scripts/game/` holds its calendar, market and journal modules |
| `game/scripts/ui/` | The interface: `hud.gd`, one script per window, `market_view.gd` for the market town, `kit.gd` for shared widgets |
| `game/scripts/world/` | Scene life: walkers (people and animals), weather, wildlife, the pasture, decorations |
| `game/data/balance.json` | Every number and name: crops, goods, buildings, helpers, market, calendar, achievements, tutorial |
| `game/translations/strings.csv` | Every player-facing string, one column per language; regenerate with `python tools/extract_strings.py` |
| `design/` | Design docs: `Game-design.md` (the whole game), `Game-plan.md` (build phases), `Asset-list.md`, `Business-plan.md`, competitor research in `reports/` |
| `design/Art tests/` | Early art experiments and the reference scene |
| `tools/art/pixellab.py` | Art pipeline: generate with PixelLab, slice sheets, clean stray pixels; every paid call is logged in `tools/art/ledger.csv` |
| `design/Art tests/content/gen_content.sh` | The script that generated the full game's buildings, people, animals, decorations and icons; it skips finished files |
| `tools/art/split_layers.py`, `make_estate_ground.py` | Split the estate painting into parallax layers; paint the ground strip |
| `tools/art/split_sky.py`, `make_icons.py` | Cut a sky into a clean base, moving clouds and the moon; make the 16-pixel list icons from the 32-pixel ones |
| `tools/art/split_town_sky.py` | Cut the market town painting into its sky, drifting clouds and the town in front |
| `tools/art/make_paved_road.py` | Paint the Roman road laid over the dirt road by the paved road upgrade |
| `tools/art/make_working_frames.py` | Make the loops that play while the mill and the presses work, from their working pictures |
| `tools/art/make_laurel.py` | Draw the golden laurel wreath given for the Triumph achievement |
| `tools/audio/cut_recordings.py` | Cut the animal calls and other recorded sounds out of their Freesound recordings; sources and licences are in `design/Sound-list.md` |
| `.env` | `PIXELLAB_TOKEN` (git-ignored) |

Godot executable: `C:\Users\evand\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

## Fixed decisions

- Base scene 480 x 270 pixels. The estate is drawn in its own viewport (`main.gd`), scaled by the largest whole number that shows the full height, and sized to fill the window, so there are never black bars. The sky is drawn behind it at screen resolution so clouds and the moon glide; the interface is drawn over it at its own whole-number scale (`Windowing.scale`, `Windowing.ui_scale`).
- All game data (crops, prices, timings, upgrades) lives in data files, never hard-coded.
- Art: one cohesive background painting per land; nothing that moves inside a background; everything that moves or changes is a separate sprite; buildings sit on fixed anchor spots with one sprite per stage.
- Characters are generated outline-free with natural proportions to match the backgrounds.
- No punishment for being away: crops never die; the only offline limit is a full storehouse.
- Sounds are found by file name: `Sfx.play("rain")` plays `assets/audio/sfx/rain.wav` if it exists and is silent otherwise; any file in `assets/audio/music/` joins the playlist. `design/Sound-list.md` lists the names the game asks for.
- The demo is the same project exported with the `demo` feature (presets in `game/export_presets.cfg`); `Game.is_demo()` caps it at villa stage 3 and the first two zones.

## Conventions

- Markdown docs: no em dashes, and write dollar signs as `\$`.
- Comments: only for a non-obvious reason, one line.
- Commit to `main`.

## Running and checking the game

- Tests: `Godot_..._console.exe --headless --path game --script res://tests/test_simulation.gd` (and `test_scene.gd`).
- Pacing: `--headless --path game --script res://tests/pacing_bot.gd -- --hours=40` plays the estate as a keen player and prints when each milestone arrives; run it after any balance change. `tests/check_real_save.gd` loads the real save into the current rules without writing anything.
- Exact screenshots: `Godot_..._console.exe --path game --quit-after 300 -- --demo --shot=OUT.png`, plus `--strip`, `--strip --solid`, `--hour=22.5`, `--villa=2`, `--send-cart`, `--estate` (every zone, building, helper and decoration in use), `--zone=pasture`, `--weather=rain`, `--day=12` (winter), `--town` (the market screen), `--window=1420x710` (any window size), `--panel=journal` (or `helpers`, `store`, `settings`, `upgrades`, or a building id such as `cellar`). `--town=Shop` opens a place in the market, `--burst=PREFIX` (with `--burst-gap=SECONDS`) saves eight frames over time for checking motion and flicker, `--readonly` loads the real save without ever writing it, and `--new-farm` starts a fresh farm with the first-day welcome and saves nothing. `--cart=3` shows the cart at that upgrade level, `--road=2` paves the road that far, `--start=channels` (or `storage`, `cart_speed`) starts that farm improvement,, `--build-villa` starts the next farmhouse stage, and `--rainbow` puts a rainbow in the sky. `--demo --maxed` (the "maxed farm" launcher) has everything finished and at its top level. `--demo` never touches the real save. `--triumph` grants every achievement but the last so the Triumph celebration plays, `--greet` makes every person on screen greet at once, and `--panel=settings:Display` opens a settings tab.
- After adding or changing any picture or sound, run `Godot_..._console.exe --headless --path game --import`. The game only reads its imported copies, so without this it keeps showing the old file.
- Always wrap capture runs in `timeout 60` and pass `--quit-after`: a script error stops the scene before it can quit, and the window then waits forever.
- The movie writer (`--write-movie`) always records at 480x270, so it cannot show the desktop strip's real shape; use `--shot` for that.
