# Farmus Maximus: Sound List

Every sound the game asks for, by file name. Drop a `.wav` or `.ogg` with exactly this name into the folder shown and the game plays it on its own: no code change is needed. A missing file is simply silent.

Several takes of one sound can sit side by side as `name_1`, `name_2` and so on, and the game picks one at random each time, so a hen clicked twice does not cluck the same way twice. The animal calls are cut from real field recordings by `tools/audio/cut_recordings.py`; their sources are listed under Recordings below.

## Effects (`game/assets/audio/sfx/`)

| File | When it plays | Have it |
|---|---|---|
| `click` | Any button (3 takes) | Yes |
| `plant` | Planting a plot; the dog digging | Yes |
| `harvest` | Harvesting a plant | Yes |
| `unlock` | Digging a new bed; a new animal in the barn other than a hen or a goat, which cluck and bleat instead | Yes |
| `coins` | Buying, selling, the cart's return (2 takes) | Yes |
| `cart` | The cart leaving or coming home | Yes |
| `dog` | Petting the dog while it is awake: one friendly woof | Yes |
| `thump` | A rabbit clicked, stamping a hind foot before it bolts; the fox startled; a sleeping dog stroked, its tail beating the ground (2 takes) | Yes |
| `cat` | Petting the cat: a purr, or now and then a contented chirp (3 takes) | Yes |
| `cluck` | Clicking a hen, and a new hen arriving (3 takes) | Yes |
| `stork` | Clicking the stork on the villa roof: its bill clattering | Yes |
| `donkey` | Clicking the donkey: a bray | Yes |
| `cart_dirt` | Riding the cart to market along the dirt road: hooves, gravel and creaking wood | Yes |
| `cart_stone` | Riding the cart to market along the paved road: hooves and wheels knocking over the stones | Yes |
| `tab` | Turning to a tab in a window or a bookmark in the journal (2 takes) | Yes |
| `rustle` | Someone greeting the player when clicked, or a helper joining: their clothes as they wave or bow; the fox dashing off; the loom's shuttle passing (3 takes) | Yes |
| `salve_woman` | A woman greeting the player when clicked, or a woman helper joining: a warm "Salve!" | No |
| `salve_man` | A man greeting the player when clicked, or a man helper joining: a friendly "Salve!" | No |
| `hammer` | Repairs and villa building | Yes |
| `built` | Building work finished: a building repaired or improved, a villa stage, a farm improvement. Made from `hammer` and `made` by `tools/audio/compose_sounds.py` | Yes |
| `flourish` | A deed bought, an achievement: one harp chord from the soundtrack, made by `tools/audio/compose_sounds.py` | Yes |
| `triumph` | Earning the Triumph, the achievement for all the others: a brass fanfare | Yes |
| `nope` | Something cannot be done (not enough coins, no room) | Yes |
| `made` | A workshop finishes a batch; a decoration bought; the loom's beater packing each row | Yes |
| `oven` | The bakery takes out bread | Yes |
| `cork` | Wine drawn from the cellar | Yes |
| `rain_start` | Rain begins | Yes |
| `rooster` | Dawn, once there are hens (2 takes) | Yes |
| `goat` | Now and then once there are goats, clicking a goat, and a new goat arriving (3 takes) | Yes |
| `market_bell` | Arriving in the market town | Yes |
| `page_turn` | Opening the journal | Yes |
| `shrine_bell` | A blessing at the lararium | Yes |
| `water_fill` | Filling the rain pool in the farmhouse | Yes |
| `fire_light` | Lighting the hearth or the lamps in the farmhouse | Yes |
| `clay` | Amphorae set on the farmhouse shelves | Yes |

## Ambience (`game/assets/audio/ambience/`)

Each loops without a gap, so the end must join the start smoothly.

| File | When it plays | Have it |
|---|---|---|
| `day` | Daytime: breeze, distant birds | Yes |
| `night` | Night: crickets | Yes |
| `rain` | While it rains, over the day or night loop | Yes |

## Recordings

The animal calls and the other recorded effects come from these Freesound recordings. All are CC0 (free for any use, no credit needed) except the stork, which is CC BY 4.0 and must be credited in the game's credits as shown.

Every recording below is also named on the game's Credits screen, which reads `game/data/credits.json`; add a line there whenever a recording is added. A CC BY recording must be credited there in the form its licence asks.

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
| `made` | [Wooden mallet on a stump](https://freesound.org/people/ldezem/sounds/386228/) by ldezem | CC0 |
| `oven` | [Stove door closing](https://freesound.org/people/fkurz/sounds/209460/) by fkurz | CC0 |
| `cork` | [Wine cork pop](https://freesound.org/people/ahill86/sounds/206152/) by ahill86 | CC0 |
| `rain_start` | [Distant thunder](https://freesound.org/people/xUMR/sounds/486557/) by xUMR | CC0 |
| `market_bell` | [Church bell strike](https://freesound.org/people/kgeshev/sounds/378799/) by kgeshev | CC0 |
| `page_turn` | [Turning a book page](https://freesound.org/people/SpaceJoe/sounds/484968/) by SpaceJoe | CC0 |
| `shrine_bell` | [Small metal bell](https://freesound.org/people/steffcaffrey/sounds/452379/) by steffcaffrey | CC0 |
| `triumph` | [Trumpet fanfare](https://freesound.org/people/joepayne/sounds/413201/) by joepayne | CC0 |
| `plant` | [Trowel digging in potting soil](https://freesound.org/people/dhallcomposer/sounds/696531/) by dhallcomposer | CC0 |
| `harvest` | [Plant harvest](https://freesound.org/people/Valenspire/sounds/699491/) by Valenspire | CC0 |
| `unlock` | [Shovel digging grass and dirt](https://freesound.org/people/dr19/sounds/353907/) by dr19 | CC0 |
| `cart` | [Small wooden cart rolling](https://freesound.org/people/Sonicquinn/sounds/518790/) by Sonicquinn | CC0 |
| `cart_dirt` | [Horse and carriage on a dirt road](https://freesound.org/people/thefilmbakery/sounds/137843/) by thefilmbakery | CC0 |
| `cart_stone` | [Horse and carriage on cobblestones](https://freesound.org/people/guynoland/sounds/549882/) by guynoland | CC0 |
| `hammer` | [Hammering a nail into wood](https://freesound.org/people/L.i.Z.e.L.l.E_+/sounds/707864/) by L.i.Z.e.L.l.E_+ | CC0 |
| `thump` | [Rabbit thumping](https://freesound.org/people/kessir/sounds/386007/) by kessir | CC0 |
| `day` | [Rural Umbria, birds and flies](https://freesound.org/people/MicheleFalleri/sounds/578431/) by MicheleFalleri | CC0 |
| `night` | [Summer night meadow, crickets and owl](https://freesound.org/people/raoul_slayer/sounds/203598/) by raoul_slayer | CC0 |
| `rain` | [Soft rain in the countryside](https://freesound.org/people/EduFigueres/sounds/688896/) by EduFigueres | CC0 |
| `water_fill` | [Water, pour above a puddle](https://freesound.org/people/Vrymaa/sounds/802711/) by Vrymaa | CC0 |
| `fire_light` | [Lighting a fire](https://freesound.org/people/Villen/sounds/149831/) by Villen | CC0 |
| `clay` | [Amphora, hitting jar and wooden lid](https://freesound.org/people/Vrymaa/sounds/770042/) by Vrymaa | CC0 |
| `click`, `tab`, `nope`, `coins` | [Interface Sounds](https://kenney.nl/assets/interface-sounds), [RPG Audio](https://kenney.nl/assets/rpg-audio) by Kenney | CC0 |

## Music (`game/assets/audio/music/`)

Any number of tracks, any names. The game plays one, then leaves two to five minutes of plain ambience before the next, so the music never wears thin. Aim for 30 to 60 minutes in total: calm, acoustic, Roman flavoured (lyre, flute, strings).

The six tracks there now (about 9 minutes) are the free LITE edition of [Bard's Tales: Peaceful Harp Music Pack](https://mythagomusic.itch.io/bards-tales-peaceful-harp-music-pack-lite) by Amos Cháb (Mythago Music). Its read-me asks for no credit but would like to hear about games that use it; the game credits it anyway. The full pack adds six more tracks for \$4.

Players can add their own music too: Settings > Sound > Your own music opens a `music` folder beside the saves (`%APPDATA%\Godot\app_userdata\Farmus Maximus\music`), and any `.ogg`, `.mp3` or `.wav` in it joins the game's tracks. The folder is looked at afresh before each track, so new files are picked up without restarting.
