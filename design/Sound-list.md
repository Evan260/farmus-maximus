# Farmus Maximus: Sound List

Every sound the game asks for, by file name. Drop a `.wav` or `.ogg` with exactly this name into the folder shown and the game plays it on its own: no code change is needed. A missing file is simply silent.

Several takes of one sound can sit side by side as `name_1`, `name_2` and so on, and the game picks one at random each time, so a hen clicked twice does not cluck the same way twice. The animal calls are cut from real field recordings by `tools/audio/cut_recordings.py`; their sources are listed under Recordings below.

## Effects (`game/assets/audio/sfx/`)

| File | When it plays | Have it |
|---|---|---|
| `click` | Any button | Yes |
| `plant` | Planting a plot; the dog digging | Yes |
| `harvest` | Harvesting a plant | Yes |
| `unlock` | Digging a new bed; a new animal in the barn | Yes |
| `coins` | Buying, selling, the cart's return | Yes |
| `cart` | The cart leaving or coming home | Yes |
| `dog` | Petting the dog: one friendly woof | Yes |
| `cat` | Petting the cat: a purr, or now and then a contented chirp (3 takes) | Yes |
| `cluck` | Clicking a hen (3 takes) | Yes |
| `stork` | Clicking the stork on the villa roof: its bill clattering | Yes |
| `donkey` | Clicking the donkey: a bray | Yes |
| `cart_dirt` | Riding the cart to market along the dirt road: hooves, gravel and creaking wood | Yes |
| `cart_stone` | Riding the cart to market along the paved road: hooves and wheels knocking over the stones | Yes |
| `tab` | Turning to a tab in a window or a bookmark in the journal | Yes |
| `rustle` | Someone greeting the player when clicked: their clothes as they wave or bow (3 takes) | Yes |
| `salve_woman` | A woman greeting the player when clicked: a warm "Salve!" | No |
| `salve_man` | A man greeting the player when clicked: a friendly "Salve!" | No |
| `hammer` | Repairs and villa building | Yes |
| `villa_complete` | A building or villa stage finished, a deed bought, an achievement | Yes |
| `triumph` | Earning the Triumph, the achievement for all the others: a brass fanfare | Placeholder |
| `nope` | Something cannot be done (not enough coins, no room) | Yes |
| `made` | A workshop finishes a batch | No |
| `oven` | The bakery takes out bread | No |
| `cork` | Wine drawn from the cellar | No |
| `rain_start` | Rain begins | No |
| `rooster` | Dawn, once there are hens (2 takes) | Yes |
| `goat` | Now and then once there are goats, and clicking a goat (3 takes) | Yes |
| `market_bell` | Arriving in the market town | No |
| `page_turn` | Opening the journal | No |
| `shrine_bell` | A blessing at the lararium | No |

## Ambience (`game/assets/audio/ambience/`)

Each loops without a gap, so the end must join the start smoothly.

| File | When it plays | Have it |
|---|---|---|
| `day.wav` | Daytime: breeze, distant birds | Yes |
| `night.wav` | Night: crickets | Yes |
| `rain.wav` | While it rains, over the day or night loop | No |

## Recordings

The animal calls come from these Freesound recordings. All are CC0 (free for any use, no credit needed) except the stork, which is CC BY 4.0 and must be credited in the game's credits as shown.

| Sound | Recording | Licence |
|---|---|---|
| `cluck` | [Chicken clucking](https://freesound.org/people/Breviceps/sounds/456803/) by Breviceps | CC0 |
| `goat` | [Bleating Goat](https://freesound.org/people/aisselles/sounds/722658/) by aisselles | CC0 |
| `donkey` | [Donkey braying in the early morning in South of France](https://freesound.org/people/felix.blume/sounds/170483/) by felix.blume | CC0 |
| `stork` | [20200624.stork.nest.01.wav](https://freesound.org/people/dobroide/sounds/525217/) by dobroide | CC BY 4.0: credit "Stork bill clattering by dobroide (freesound.org), CC BY 4.0" |
| `cat` | [Cat purr.wav](https://freesound.org/people/Trautwein/sounds/260881/) by Trautwein, [cat chirp.wav](https://freesound.org/people/dreamstobecome/sounds/451250/) by dreamstobecome | CC0 |
| `rooster` | [Chickens clucking and rooster](https://freesound.org/people/evsecrets/sounds/346961/) by evsecrets | CC0 |
| `dog` | [Single Dog Bark](https://freesound.org/people/kwahmah_02/sounds/277058/) by kwahmah_02 | CC0 |
| `rustle` | [Foley: Cotton clothes rustling](https://freesound.org/people/khenshom/sounds/481075/) by khenshom | CC0 |

## Music (`game/assets/audio/music/`)

Any number of tracks, any names. The game plays one, then leaves two to five minutes of plain ambience before the next, so the music never wears thin. Aim for 30 to 60 minutes in total: calm, acoustic, Roman flavoured (lyre, flute, strings).
