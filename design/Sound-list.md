# Farmus Maximus: Sound List

Every sound the game asks for, by file name. Drop a `.wav` or `.ogg` with exactly this name into the folder shown and the game plays it on its own: no code change is needed. A missing file is simply silent.

## Effects (`game/assets/audio/sfx/`)

| File | When it plays | Have it |
|---|---|---|
| `click` | Any button | Yes |
| `plant` | Planting a plot; the dog digging | Yes |
| `harvest` | Harvesting a plant | Yes |
| `unlock` | Digging a new bed; a new animal in the barn | Yes |
| `coins` | Buying, selling, the cart's return | Yes |
| `cart` | The cart leaving or coming home | Yes |
| `pet` | Petting the dog | Yes |
| `hammer` | Repairs and villa building | Yes |
| `villa_complete` | A building or villa stage finished, a deed bought, an achievement | Yes |
| `nope` | Something cannot be done (not enough coins, no room) | Yes |
| `made` | A workshop finishes a batch | No |
| `oven` | The bakery takes out bread | No |
| `cork` | Wine drawn from the cellar | No |
| `rain_start` | Rain begins | No |
| `rooster` | Dawn, once there are hens | No |
| `goat` | Now and then, once there are goats | No |
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

## Music (`game/assets/audio/music/`)

Any number of tracks, any names. The game plays one, then leaves two to five minutes of plain ambience before the next, so the music never wears thin. Aim for 30 to 60 minutes in total: calm, acoustic, Roman flavoured (lyre, flute, strings).
