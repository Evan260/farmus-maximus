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
| `tools/translate_strings.py` | Fills the empty language columns of `strings.csv` with Azure AI Translator (key `AZURE_TRANSLATOR_KEY` in `.env`); `--dry-run` shows what is missing. The game loads every column that has translations and offers it under Settings > Gameplay; Cyrillic, Polish and Turkish switch the interface to a 10 px font, Chinese, Japanese and Korean fall back to Fusion Pixel 8 px. `--locale=ja` tries a language without saving it. Azure gets short interface words wrong without context (Settings as scenery, Resume as a CV), so every language was then reviewed line by line against the code that shows it; new strings need the same review |
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
| `tools/art/make_room_pets.py` | Paint each dog and cat breed asleep at the farmhouse room's own detail and style (`game/assets/sprites/room_pets/`), with PixelLab |
| `tools/audio/compose_sounds.py` | Make sounds out of ones already cut, such as `built` (the last hammer blows and a mallet set down) and `flourish` (a harp chord from the soundtrack, for deeds and achievements) |
| `tools/art/make_interior.py` | Make the farmhouse interior (`game/assets/backgrounds/interior/`) from the two paintings in `tools/art/sources/interior/`: the ruin, the empty restored room, and each buyable furnishing cut out as its own layer. Repaints with PixelLab are cached in `steps/`, so a rebuild is free unless `--redo NAME` |
| `tools/art/make_town_trees.py` | Lift the market town's cypresses into their own pictures so they sway in the wind; rerun after `split_town_sky.py` |
| `tools/art/make_stork_poses.py` | Make the stork's look-back, blink and nod poses from its picture on the nest |
| `tools/art/paint_land_fields.py` | Paint the vineyards, fields and farmhouses onto the distant hills, from the plain layer in `tools/art/sources/` |
| `tools/art/make_mill_ruin.py` | Make the ruined mill from the working one, front on like the other ruins |
| `tools/art/make_storehouse_levels.py` | Draw the storehouse as it grows with each enlargement, from its first picture |
| `tools/art/make_clouds.py` | Paint the estate sky's drifting cumulus clouds, lumpy and lit from the upper left |
| `tools/art/make_cart_levels.py` | Draw the trader's cart at each upgrade: stakes, a wicker rail, then a four-wheeled wagon |
| `tools/art/scale_breeds.py` | Size freshly generated dog and cat breeds to one another, and make the half-size cats |
| `tools/audio/cut_recordings.py` | Cut the animal calls and other recorded sounds out of their Freesound recordings; sources and licences are in `design/Sound-list.md` |
| `tools/steam/publish.py` | Build the game for Windows, Mac and Linux and upload it to Steam, live on the test branch; ids in `tools/steam/steam.json`, setup in `design/Steam-publishing.md`. The Mac and Linux half runs in WSL (`wsl_build.sh`): a Mac app copied through Windows loses its file permissions, and the Mac app is signed and notarized there with rcodesign |
| `.env` | `PIXELLAB_TOKEN` (git-ignored) |

Godot executable: `C:\Users\evand\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

## Fixed decisions

- Base scene 480 x 270 pixels. The estate is drawn in its own viewport (`main.gd`, class `Estate`), scaled by the largest whole number that shows the full height (a tall narrow window crops the sides instead, down to 300 pixels across), and sized to fill the window, so there are never black bars. `main.gd` builds the scene and handles input; its parts live in `scripts/estate/`: `cart_rig.gd` (the donkey and cart), `road_works.gd` (paving, kerb, milestones, footpath, stone cart), `villa_view.gd` (the farmhouse, its scaffold, lit windows and wreath), `scenery.gd` (grass, weeds, flowers, overgrowth) and `debug_tools.gd` (demo farms, screenshots, bursts). Each is a child node with `m`, the estate scene, to work on. The sky is drawn behind it at screen resolution so clouds and the moon glide; the interface is drawn over it at its own whole-number scale (`Windowing.scale`, `Windowing.ui_scale`).
- All game data (crops, prices, timings, upgrades) lives in data files, never hard-coded.
- Art: one cohesive background painting per land; nothing that moves inside a background; everything that moves or changes is a separate sprite; buildings sit on fixed anchor spots with one sprite per stage.
- Characters are generated outline-free with natural proportions to match the backgrounds.
- No punishment for being away: crops never die; the only offline limit is a full storehouse.
- Saves: a player keeps up to three farms, each in `user://farm_<n>.json` with three rolling backups; `user://farms.json` remembers the one played last (`save_service.gd`). The farm's name and whether its opening letter was read are part of each save.
- Sounds are found by file name: `Sfx.play("rain")` plays `assets/audio/sfx/rain.wav` if it exists and is silent otherwise; any file in `assets/audio/music/` joins the playlist, as does any in the player's own `user://music/` folder, which Settings > Sound opens. `design/Sound-list.md` lists the names the game asks for.
- The demo is the same project exported with the `demo` feature (presets in `game/export_presets.cfg`); `Game.is_demo()` caps it at villa stage 3 and the first two zones.

## Conventions

- Markdown docs: no em dashes, and write dollar signs as `\$`.
- Comments: only for a non-obvious reason, one line.
- Commit to `main`.

## Running and checking the game

- Tests: `Godot_..._console.exe --headless --path game --script res://tests/test_simulation.gd` (and `test_scene.gd`).
- Pacing: `--headless --path game --script res://tests/pacing_bot.gd -- --hours=40` plays the estate as a keen player and prints when each milestone arrives; run it after any balance change. `tests/completion_bot.gd` (same arguments) plays on towards 100%, buying every building level and decoration, and prints when each achievement unlocks and what is still missing. `tests/check_real_save.gd` loads the real save into the current rules without writing anything.
- Exact screenshots: `Godot_..._console.exe --path game --quit-after 300 -- --demo --shot=OUT.png`, plus `--strip`, `--strip --solid`, `--hour=22.5`, `--villa=2`, `--send-cart`, `--estate` (every zone, building, helper and decoration in use), `--zone=pasture`, `--weather=rain`, `--day=12` (winter), `--town` (the market screen), `--window=1420x710` (any window size), `--panel=journal` (or `helpers`, `store`, `settings`, `upgrades`, or a building id such as `cellar`). `--town=Shop` opens a place in the market, `--burst=PREFIX` (with `--burst-gap=SECONDS`) saves eight frames over time for checking motion and flicker, `--readonly` loads the real save without ever writing it, and `--new-farm` starts a fresh farm with the first-day welcome and saves nothing. `--cart=3` shows the cart at that upgrade level, `--road=2` paves the road that far, `--start=channels` (or `storage`, `cart_speed`) starts that farm improvement,, `--build-villa` starts the next farmhouse stage, and `--rainbow` puts a rainbow in the sky. `--inside` opens the farmhouse interior (use `--villa=3` or more for the restored room; `--inside=list` or `--inside=lamps` also opens the furnishing window), `--furnish=all` (or `--furnish=fire,lamps`) has those furnishings bought, `--window=` always opens the full window even if the player left the game as the strip. `--debug-panel` opens the F1 debug panel, `--galaxy` shows the Milky Way tonight (with `--hour=0.5 --weather=sun`); it otherwise comes on about half of the clear nights near the new moon, never on a night of northern lights. `--demo --maxed` (the "maxed farm" launcher) has everything finished and at its top level. `--demo` never touches the real save. `--aurora` brings out the northern lights tonight (with `--hour=23 --weather=sun`; `--aurora=vertical` or `--aurora=horizontal` picks the night's shape, which is otherwise chosen at random each night), `--title` shows the title screen, which otherwise only opens on a launch with no flags, `--triumph` grants every achievement but the last so the Triumph celebration plays, `--achievement` slides in the cards for the next two achievements not yet earned (or `--achievement=excellent,sell_100` for those), `--greet` makes every person on screen greet at once (the first in view also says something in a speech bubble), `--guide` shows Uncle Marcus's advice from the first step (or `--guide=cart` from a later one), `--pets=lapdog,longhair` sets the dog's and cat's breeds, and `--panel=settings:Display` opens a settings tab.
- After adding or changing any picture or sound, run `Godot_..._console.exe --headless --path game --import`. The game only reads its imported copies, so without this it keeps showing the old file.
- Always wrap capture runs in `timeout 60` and pass `--quit-after`: a script error stops the scene before it can quit, and the window then waits forever.
- Play-test build: `Godot_..._console.exe --headless --path game --export-release "Windows" "../builds/windows/Farmus Maximus.exe"` makes one self-contained .exe (export templates for 4.7.2 are installed in `%APPDATA%\Godot\export_templates`). Zip it with `tools/playtest/How to play test.txt` to send to a tester; `builds/` is git-ignored. The F1 debug panel only opens in development builds.
- The movie writer (`--write-movie`) always records at 480x270, so it cannot show the desktop strip's real shape; use `--shot` for that.
