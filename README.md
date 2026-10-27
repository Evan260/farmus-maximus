# Farmus Maximus

A cozy, semi-idle farming game on a Roman country estate, made for Steam (Windows, Mac, Linux and Steam Deck).

Grow lavender, wheat, olives and vines, restore ruined workshops to turn the harvest into flour, bread, oil, honey, cheese and wine, ride the cart to the market town to sell, and bring a crumbling farmhouse back to a grand villa. Nothing dies and nothing spoils: the estate keeps working while the game is closed, and it can run as a strip along the edge of the desktop while you do something else.

*Rusty's Retirement meets Cast n Chill, on a Roman villa.*

## Playing it

The game is made with Godot 4.7.2. With Godot installed through winget (the path the launchers expect), double-click one of the launchers in this folder:

| Launcher | What it opens |
|---|---|
| `Play Farmus Maximus.bat` | The title screen, then your farms (up to three), saved as you play |
| `Play Farmus Maximus (new farm).bat` | A fresh farm from the first day, which is never saved |
| `Play Farmus Maximus (demo farm).bat` | A farm with plenty planted and lots of coins, for trying things out; never saved |
| `Play Farmus Maximus (maxed farm).bat` | Everything finished and at its top level; never saved |

The launchers start Godot on the project; they are not the game itself. To run it on a computer without Godot, export a build (below).

In development builds, F1 opens a debug panel with time speed-ups, free coins and a farm reset.

## The project

| Folder | What is in it |
|---|---|
| `game/` | The Godot project: scenes, GDScript, art, sound and the data files |
| `game/data/balance.json` | Every number and name in the game: crops, goods, buildings, helpers, prices, timings, achievements |
| `game/tests/` | Automated checks and the bots that measure pacing |
| `design/` | Design documents, plans and research |
| `tools/` | Scripts for making art and sound, collecting translatable text, and publishing to Steam |
| `builds/` | Exported builds (not kept in git) |

## Design documents

| Document | What it covers |
|---|---|
| [Game design](design/Game-design.md) | The whole game, from the estate to the market town |
| [Asset list](design/Asset-list.md) | Every picture the game needs |
| [Sound list](design/Sound-list.md) | Every sound the game plays, by file name, with the sources and licences of the recordings |
| [Business plan](design/Business-plan.md) | Who the game is for, where it sells, costs and the plan to launch |
| [Website plan](design/Website-plan.md) | The game's website |
| [Steam setup](design/Steam-setup.md) | Connecting the game to Steam: achievements, cloud saves and the demo |
| [Steam publishing](design/Steam-publishing.md) | Uploading builds to Steam and giving testers access |

## Checking changes

Run from the project folder, with `GODOT` standing for the Godot console executable:

```
GODOT --headless --path game --script res://tests/test_simulation.gd
GODOT --headless --path game --script res://tests/test_scene.gd
```

After changing anything in `balance.json`, the pacing bot shows when each milestone arrives for a keen player, and the completion bot plays on towards 100%:

```
GODOT --headless --path game --script res://tests/pacing_bot.gd -- --hours=20
GODOT --headless --path game --script res://tests/completion_bot.gd -- --hours=40
```

After adding or changing any picture or sound, run `GODOT --headless --path game --import`, or the game keeps using the old file.

## Builds

A play-test build is one self-contained `.exe`:

```
GODOT --headless --path game --export-release "Windows" "../builds/windows/Farmus Maximus.exe"
```

Write the credits file beside it, since the licences of Godot and the stork recording ask to ship with the game:

```
GODOT --headless --path game --script res://tools/write_credits.gd -- --out="../builds/windows/Credits and licences.txt"
```

Zip both with `tools/playtest/How to play test.txt` to send to a tester. Steam builds go up with `python tools/steam/publish.py playtest`; see [Steam publishing](design/Steam-publishing.md) for the one-time setup.

## Art and sound

The art is pixel art, generated with PixelLab (`tools/art/pixellab.py`, every paid call logged in `tools/art/ledger.csv`) and drawn or finished with the Python scripts in `tools/art/`. Each script says at the top what it makes and how to run it again.

Every sound is a real recording: from Freesound, cut to length by `tools/audio/cut_recordings.py`, and from Kenney's free sound packs. All are CC0 except the stork's, which needs a credit; `Credits and licences.txt`, shipped beside the game, names them all, as listed in the [sound list](design/Sound-list.md). The music is the Bard's Tales harp pack by Mythago Music. Only the "Salve!" greetings are still missing.

The font is Silkscreen, under the SIL Open Font License (`game/assets/fonts/OFL.txt`).
