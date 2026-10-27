# Farmus Maximus: Steam Setup

What has to happen on Steam's side before launch. The game already does its part: it records achievements in the save, and sends them to Steam whenever Steam is present.

## 1. Connect the game to Steam

1. Create the app in Steamworks and note its App ID.
2. Add GodotSteam (the GDExtension build for Godot 4.7) to `game/addons/`. The game looks for its `Steam` object and uses it when it is there (`game/scripts/autoload/platform.gd`); without it, nothing breaks.
3. While testing outside Steam, put a file named `steam_appid.txt` holding the App ID next to the game's executable.

## 2. Achievements

Enter each of these in Steamworks under Stats and Achievements, with exactly this API name. The list comes from `game/data/balance.json`; regenerate this table if that list changes. Achievements earned before Steam was connected are sent the next time the game starts.

| API name | Name | Description |
|---|---|---|
| `first_harvest` | First bloom | Harvest your first crop |
| `harvest_100` | Green fingers | Harvest 100 crops |
| `harvest_1000` | Bountiful | Harvest 1,000 crops |
| `harvest_10000` | Breadbasket of Rome | Harvest 10,000 crops |
| `earn_1000` | A tidy sum | Earn 1,000 sestertii |
| `earn_10000` | Prosperous | Earn 10,000 sestertii |
| `earn_100000` | Equestrian fortune | Earn 100,000 sestertii |
| `cart_10` | Steady donkey | Send the cart 10 times |
| `cart_100` | Well-worn road | Send the cart 100 times |
| `market_visit` | To market, to market | Visit the market town |
| `sell_100` | Stallholder | Sell 100 goods at the market yourself |
| `order_1` | At your service | Fill an order |
| `order_25` | Trusted supplier | Fill 25 orders |
| `aureus` | Gold! | Earn an aureus |
| `villa_2` | A roof again | Restore the villa to stage 2 |
| `villa_3` | Villa rustica | Restore the villa to stage 3 |
| `villa_4` | A fine portico | Restore the villa to stage 4 |
| `villa_5` | The peristyle | Restore the villa to stage 5 |
| `villa_6` | Hot baths | Restore the villa to stage 6 |
| `villa_7` | Farmus Maximus | Restore the villa to stage 7 |
| `first_deed` | Landowner | Buy your first land deed |
| `all_zones` | The whole estate | Own every zone |
| `first_building` | Back to work | Restore a building |
| `all_buildings` | Nothing left in ruins | Restore every building |
| `first_helper` | An extra pair of hands | Hire a helper |
| `all_helpers` | The household | Hire every helper |
| `fine` | Fine work | Harvest something of fine quality |
| `excellent` | Excellent! | Harvest something of excellent quality |
| `lavender_oil` | Essence of summer | Make lavender oil |
| `bath_oil` | Fit for a senator | Make bath oil |
| `cheese` | Say cheese | Make cheese |
| `excellent_wine` | Falernian quality | Draw an excellent aged wine |
| `white_lavender` | Snow in summer | Grow white lavender |
| `truffle` | Good nose | The dog finds a truffle |
| `pets_50` | Best friends | Pet the dog 50 times |
| `rainbow` | After the rain | See a rainbow |
| `shooting_star` | Make a wish | See a shooting star |
| `fox` | Sly visitor | Spot the fox |
| `cat_and_dog` | Unlikely friends | Find the cat and dog asleep together |
| `blessing` | Pious | Receive a blessing at the lararium |
| `all_festivals` | A year of feasts | Celebrate every festival |
| `decorations_5` | House proud | Own 5 decorations |
| `journal_half` | Keen observer | Fill half of the farmer's journal |
| `journal_full` | Naturalist | Fill the whole farmer's journal |
| `homely` | A home again | Furnish every corner of the farmhouse |
| `triumph` | Triumph | Earn every other achievement. Rome honours you with a triumph and a golden laurel wreath for the villa door |

## 3. Steam Cloud

Use Auto-Cloud; the game needs no code for it. Each farm slot is saved as `farm_1.json`, `farm_2.json` and `farm_3.json`, each with up to three rolling backups (`farm_1.json.bak1` and so on), and `farms.json` remembers which farm was played last. Add two root paths per platform, one for the saves and one for their backups:

| Platform | Root | Subdirectory | Pattern |
|---|---|---|---|
| Windows | `WinAppDataRoaming` | `Godot/app_userdata/Farmus Maximus` | `farm*.json` |
| Windows | `WinAppDataRoaming` | `Godot/app_userdata/Farmus Maximus` | `farm_*.json.bak*` |
| macOS | `MacAppSupport` | `Godot/app_userdata/Farmus Maximus` | `farm*.json` |
| macOS | `MacAppSupport` | `Godot/app_userdata/Farmus Maximus` | `farm_*.json.bak*` |
| Linux | `LinuxXdgDataHome` | `godot/app_userdata/Farmus Maximus` | `farm*.json` |
| Linux | `LinuxXdgDataHome` | `godot/app_userdata/Farmus Maximus` | `farm_*.json.bak*` |

`farm*.json` covers both `farms.json` and every `farm_N.json`. The patterns leave out `farm_N.json.tmp`, which only exists for the moment a save is being written. If the save files are ever renamed, these patterns must change with them in `game/scripts/autoload/save_service.gd`, or cloud saves quietly stop syncing.

`prefs.json`, `settings.json` and `window.json` are per-computer settings (key bindings, volume, where the strip sits), so they stay out of the cloud.

## 4. Demo

The demo is the same project exported with the `demo` export presets in `game/export_presets.cfg`. It stops at the villa rustica and the first two zones. Its save sits in the same folder as the full game's, so progress carries over on the same computer. Give the demo its own App ID in Steamworks, linked to the main game.
