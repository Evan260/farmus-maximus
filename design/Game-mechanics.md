# Otium: Game Mechanics Plan

*Working title. Otium is Latin for leisure: peaceful time away from work.*

## Pitch

A cozy, semi-idle farming game set on a small estate in the Roman countryside. Grow rolling purple fields of lavender alongside olives, vines and wheat, sell your harvest at the town market, and slowly restore a humble farmhouse into a grand villa. Play actively, or let the farm run in a thin strip along the bottom of your screen while you work.

**One-line hook:** Rusty's Retirement meets Cast n Chill, on a Roman villa.

## Design pillars

Every feature should support at least one of these. If it fights one, cut it.

1. **Peaceful.** No fail states, no punishment, no timers that make you anxious. Crops never die.
2. **Beautiful.** The landscape is the reward. Every upgrade should be visible on screen.
3. **Growth you can see.** The villa, the farm and the land visibly change over hours, days and weeks.
4. **Works in the background.** Everything can run idle; playing actively is faster and more fun, never required.
5. **Simple to read.** A glance at the farm tells you what is ready, what is growing and what needs attention.
6. **Always something to watch.** While crops grow, the world is alive: animals, insects, water, wind and passers-by. Waiting should feel like sitting in a garden, not staring at a timer.

---

## 1. Screen and display modes

### Layout

The screen is split into two zones:

| Zone | View | Contents |
|---|---|---|
| Landscape (top) | Side view, parallax layers | Sky, mountains, hills, aqueduct, tree line, the villa |
| Farm band (bottom) | Shallow top-down strip, 2 to 3 rows of plots | Crops, trees, vines, the cart, presses, storage, the dog |
| UI (floating) | Overlay | Coins, storage, sell button and menus, floating over the field edge; the field runs to the bottom of the screen |

The camera pans left and right across the estate. Far layers move slower than near ones, which gives depth.

### Display modes

- **Full window:** the whole scene. Used for active play, trailers and screenshots.
- **Idle strip:** only the farm band and a slim UI, docked to the bottom (or top or side) of the desktop. Borderless, always on top, optional transparency.
- **Focus mode:** a smaller, quieter idle strip with slowed production, for when you want even less on screen.

---

## 2. Core loop

```
Plant  →  Grow  →  Harvest  →  Store  →  (Process)  →  Sell  →  Coins  →  Upgrade / Expand
  ↑                                                                              │
  └──────────────────────────────────────────────────────────────────────────────┘
```

1. **Plant** seeds or saplings in a plot.
2. **Grow** over real time. Each crop has visible growth stages.
3. **Harvest** when ready, by clicking (active) or by a farmhand (idle).
4. **Store** the harvest in the storeroom, which has limited capacity.
5. **Process** raw goods into higher value goods (optional, unlocked over time).
6. **Sell** by sending the cart to the town market.
7. **Spend** coins on upgrades, new land, villa stages and decorations.

The storeroom capacity is the main limit on idle play. When it is full, production pauses until you sell. That gives a natural reason to check in without punishing you for being away.

---

## 3. Crops

### Lavender, the signature crop

Lavender is the most common crop on the estate and the game's visual identity. Rows of purple against cream stone, terracotta roofs and dark green cypresses are the image people should remember.

- **Everywhere:** it is the starter crop, the cheapest to plant, and the crop most plots hold in a typical farm. Every land has room for it.
- **Perennial:** plant once; it blooms and is harvested every season after it matures, so fields stay purple instead of being replanted bare.
- **Alive in the wind:** lavender rows sway in gentle waves when the wind blows, and bees and butterflies gather on blooming fields.
- **Varieties:** common purple, deep violet, a pale blue-grey, and a rare white lavender found through orders, the dog, or the journal.
- **Uses:** sold as fresh bundles, dried in bundles, steeped in olive oil to make scented lavender oil, fed to bees for lavender honey, and used in the bathhouse.
- **Roman touch:** Romans scented their baths and laundry with fragrant herbs. The bathhouse wing (villa stage 6) uses lavender oil for its comfort bonus, tying the signature crop to the villa's growth.
- **Seasons:** green mounds in spring, full purple bloom in summer, silvery after harvest in autumn, soft grey-green in winter.

### Crop types

| Type | Behaviour | Examples |
|---|---|---|
| Field crops | Plant, grow, harvest once, replant | Emmer wheat, spelt, barley, millet |
| Garden crops | Fast growing, harvest once, replant | Cabbage, leeks, onions, garlic, lentils, chickpeas, fava beans |
| Vines | Plant once, grow for a while, then harvest every season | Grapes (several varieties) |
| Fruit and olive trees | Plant once, slow to mature, then harvest every season, never replant | Olives, figs, pomegranates, quinces, pears, cherries |
| Lavender | Plant once, bloom and harvest every season | Common purple, deep violet, blue-grey, rare white |
| Herbs and flowers | Small plots, feed bees and processing | Rosemary, thyme, roses |

### Growth

- Each crop has 4 to 6 visible stages: seed, sprout, young, mature, ready, harvested.
- Growth runs on real time, with different speeds per crop (minutes for garden crops, hours for field crops, days to mature for trees).
- Perennials (vines and trees) change with the seasons: blossom in spring, fruit in summer and autumn, bare in winter.
- A plot that is ready shows a gentle, readable cue (a slight sway, a sparkle, a small icon) so you can tell at a glance.

### Quality

- Harvests have a quality tier: Common, Fine, Excellent.
- Quality rises with soil care, watering, blessings, and an active "perfect harvest" (see section 6).
- Higher quality sells for more and counts toward collections.

### Soil and water

- **Watering:** plots near an aqueduct channel are watered automatically. Others rely on rain or a manual watering click. Unwatered crops grow slower but never die.
- **Fertility:** manure from animals boosts growth speed and quality.
- **Crop rotation (light touch):** planting a legume (lentils, beans) before wheat gives a small bonus. Optional, never required.

---

## 4. Processing

Processing turns raw goods into more valuable goods. Each processor is a building on the farm band.

| Building | Input | Output | Notes |
|---|---|---|---|
| Drying racks | Lavender | Dried lavender bundles | First processor; cheap and quick |
| Olive press | Olives | Olive oil | The signature Roman product |
| Unguent workshop | Lavender (or roses) plus olive oil | Scented oil | Flowers steeped in oil, the Roman way of making perfume and bath oil |
| Wine press / treading vat | Grapes | Must, then wine | Wine ages in amphorae |
| Wine cellar | Young wine | Aged wine | Value rises with real time aged; very idle friendly |
| Mill | Grain | Flour | |
| Bread oven | Flour | Bread | |
| Beehives | Nearby herbs and flowers | Honey, wax | Honey type depends on the flowers; hives next to lavender make lavender honey |
| Dairy | Goat milk | Cheese | Requires goats |
| Garum works | Fish (coastal land) | Garum (fish sauce) | Late game, high value |

- Processing takes time and runs idle.
- Each processor can be upgraded for speed and capacity.
- Active play: an optional quick interaction (turning the press, treading grapes) speeds up the current batch.

---

## 5. Selling and the market

### The cart

- Load the cart from the storeroom and send it to town. It leaves the screen and returns after a delay with coins.
- The donkey pulls the cart. The dog sometimes rides along.
- Upgrades: cart capacity, travel speed, a second cart.
- Optional auto-sell: when storage is nearly full, the cart goes automatically.

### Prices

- Each good has a base price that shifts with the season and demand (cheaper at harvest time when everyone sells grain, more valuable in winter).
- Price changes are gentle and readable, never a stock market.

### Orders

- Townspeople and visitors post orders on a notice board at the market: "a merchant wants 10 amphorae of fine oil", "the baker needs 30 flour", "a senator's banquet needs 5 aged wines".
- Orders pay a bonus over market price and sometimes give special rewards (rare seeds, decorations, villa materials).
- No deadlines that punish you. Orders stay until filled or swapped.
- Orders act as gentle goals that guide you toward new crops and processors.

### Currency

- Coins: **sestertii** for everyday trade. A rarer **aureus** (gold coin) from special orders and festivals, used for prestige purchases.

---

## 6. Active and idle play

| | Active | Idle |
|---|---|---|
| Harvest | Click plots; a well-timed click gives a "perfect harvest" quality bonus | Farmhands harvest automatically at normal quality |
| Processing | Optional quick interaction speeds up a batch | Runs at normal speed |
| Selling | Choose what to load and when to send the cart | Auto-sell when storage is nearly full (unlockable) |
| Speed | Faster overall | Slower but steady |

### Offline progress

- When the game is closed, it records the time. On reopening, it calculates what grew, was harvested and processed while you were away.
- Offline progress stops when the storeroom fills up.
- A short "while you were away" summary greets you on return.

### Farmhands

- Hire farmhands to automate harvesting, replanting and loading the cart.
- Each has a name, appearance and one simple trait (faster at vines, better with olives, sings while working).
- Workers are your family, hired help and free neighbours from the village. **Design note:** Roman estates relied heavily on enslaved labour. The game deliberately depicts a free, family-run farm.

---

## 7. Villa progression

The villa is the visible heart of progress. Each stage replaces the building on screen.

| Stage | Name | Unlocks |
|---|---|---|
| 1 | Ruined farmhouse | Starting point: one room, a hearth, a small storeroom |
| 2 | Restored farmhouse | Bigger storeroom, first farmhand |
| 3 | Villa rustica (working farm villa) | Wine cellar, kitchen and bread oven |
| 4 | Villa with portico (columned porch) | Lararium (household shrine), decorations |
| 5 | Villa with peristyle (inner colonnaded garden) | Garden plots for herbs and flowers, fountain |
| 6 | Bathhouse wing | Comfort bonus to farmhand speed |
| 7 | Grand estate | Final form; cosmetic flourishes, statues, mosaics |

- Each stage costs coins plus materials (stone, timber, roof tiles) bought or earned from orders.
- Upgrading plays a short, satisfying transformation moment. This is a key trailer and clip moment.

### Decorations

A cosmetic coin sink for long term play: mosaics, frescoes, statues, fountains, potted plants, garden paths, lanterns. Some are earned only from festivals or rare orders.

---

## 8. Lands

Each land is a new scene along the estate, with its own landscape layers and best crops.

| Land | Landscape | Specialty |
|---|---|---|
| Home farm (hillside) | Rolling hills, cypresses, aqueduct on the horizon | Lavender fields, olives, mixed starter crops |
| Vineyard slopes | Terraced hillside, distant villa | Grapes, wine |
| River valley | A river, a watermill, poplars | Grain, mill, flour |
| Mountain pasture | Higher ground, pines, distant snow | Goats, cheese, honey |
| Coastal estate | The sea, a small harbour, fishing boats | Fish, garum, salt, trade bonus |

- Unlock a land by buying its deed.
- All lands keep producing while you are elsewhere.
- In the idle strip, you choose which land is shown.

---

## 9. Time, seasons and weather

### Day and night

- A full day cycle runs every set number of real minutes (to be tuned; 20 to 30 minutes is a starting point).
- Lighting shifts from dawn to golden hour to night. Lanterns glow at night, and fireflies appear in summer.
- Optional setting: sync the in-game time of day to your real clock.

### Seasons

- Spring, summer, autumn and winter rotate every few in-game days (to be tuned).
- Seasons change what grows, how trees and vines look, prices and festivals.
- Winter is quiet but not dead: processing, wine aging, villa building and pruning.

### Weather

- Sunny, cloudy, light rain (waters all crops for free), mist in the mornings, a rare summer storm (visual only, never harmful).

### Festivals

Real Roman festivals give seasonal events, special orders, decorations and price bonuses.

| Festival | Season | Theme |
|---|---|---|
| Cerealia | Spring | Grain, Ceres |
| Floralia | Spring | Flowers, garlands |
| Vinalia | Late summer | The grape harvest, wine |
| Meditrinalia | Autumn | Tasting the new wine |
| Saturnalia | Winter | Gifts, feasting, lanterns |

---

## 10. The lararium (household shrine)

Unlocked with villa stage 4. Leave an offering to receive a temporary blessing.

| Deity | Blessing |
|---|---|
| Ceres | Faster grain growth |
| Bacchus (Liber) | Better wine quality |
| Minerva | Bigger olive harvests |
| Pomona | Better fruit harvests |
| Mercury | Better market prices |
| Lares (household spirits) | Faster processing |

- One blessing active at a time, lasting a set number of hours.
- Offerings are small amounts of your own produce, so the shrine also acts as a gentle resource sink.

---

## 11. The living world

While crops grow, there is always something gentle to watch. None of this is required for play; it is the reason people leave the game open.

### The farm dog

- Your companion from the start. Name it on day one.
- Wanders the farm, naps in the sun, chases birds, rides the cart, greets you when you return.
- Can be petted (a small joy moment, no gameplay effect, or a tiny luck bonus).
- Sometimes digs up small finds: an old coin, a rare seed, a truffle.
- Cosmetic collars and spots to nap in.

### Farm animals

| Animal | Purpose | What you see |
|---|---|---|
| Donkey | Pulls the cart | Grazes, flicks its ears, naps standing up, brays when the cart returns |
| Chickens | Eggs, manure | Peck around plots, chase bugs, roost at dusk |
| Goats | Milk for cheese, manure | Climb on walls and rocks, headbutt each other playfully, nibble hedges |
| Bees | Honey and wax, pollination bonus to nearby trees | Drift between the hives and blooming lavender |
| Cat | Lives in the storeroom; a small storage bonus (keeps the mice away) | Suns itself on the storeroom roof, stalks butterflies, ignores the dog |

### Insects

| Creature | When and where |
|---|---|
| Butterflies (several colours) | Daytime, gathering on lavender and flowers |
| Bees and bumblebees | Daytime, on blooming crops |
| Dragonflies | Near water: the river, the fountain, aqueduct channels |
| Ladybirds | Crawling on leaves; occasionally one lands on the UI |
| Crickets and cicadas | Heard more than seen; cicadas hum on summer afternoons |
| Fireflies | Summer nights, over the lavender |
| Snails | Appear after rain, slowly crossing paths |
| Moths | At night, around lanterns |

### Wild animals and birds

| Creature | When and where |
|---|---|
| Swallows | Swoop low over the fields in summer evenings |
| Sparrows | Hop around plots, scattered by the dog |
| Storks | Nest on the villa roof from a later stage onward |
| Hoopoe | A rare, colourful bird visitor |
| Lizards | Sunbathe on walls, dart away when disturbed |
| Rabbits | Peek out at the field edges at dawn and dusk |
| Hedgehog | Wanders through at night |
| Fox | A rare dusk visitor at the edge of the farm |
| Deer | Graze far away in the hills (background layer) |
| Owl | Perches on a cypress at night |

### Water

Water should always feel alive, because it is one of the most satisfying things to watch.

- **Aqueduct channels:** water flows and glints along the channels that irrigate the plots.
- **Fountain:** splashes and ripples, with birds bathing in it now and then.
- **Well:** the bucket rises and falls when a farmhand draws water.
- **River (river valley):** shimmering current, reflections of the sky, a turning watermill.
- **Sea (coastal estate):** rolling waves, sparkles of sunlight, boats bobbing in the harbour.
- **Rain:** drops ripple in puddles that form on paths and dry slowly afterwards.
- **Morning dew:** a soft sparkle on leaves at dawn.

### Wind and light

- Wind passes through the lavender and wheat in visible waves.
- Cypresses and olive trees sway gently.
- Cloud shadows drift slowly across the fields.
- Petals and leaves blow across the screen in spring and autumn.
- Golden hour light warms everything; lanterns and windows glow at night.

### Passers-by

Small figures travel along a road on a background layer, giving a sense of a wider world.

- A shepherd with a flock of sheep.
- A merchant's cart, or a traveller on a mule.
- Pilgrims or villagers heading to a festival.
- A column of soldiers marching in the far distance (rare).
- Children chasing each other past the fields during festivals.

### Rare sightings

Some moments are rare on purpose, so watching pays off.

- A rainbow after rain.
- A shooting star on a clear night.
- The fox, the hoopoe, the white butterfly.
- The cat and the dog asleep together.

Each rare sighting is recorded in the farmer's journal the first time you see it, so there is a reason to keep the game open and an easy screenshot or clip moment for players to share.

---

## 12. Collections and goals

- **The farmer's journal:** a codex of every crop variety, product, quality tier, rare vintage, decoration, dog find and rare sighting. Filling pages gives small rewards.
- **Achievements** (Steam): first harvest, first villa upgrade, first aged wine, every land unlocked, every festival celebrated, and so on.
- **Milestones** shown in the journal give a sense of direction without forcing it.

### Long-term goal

- Reach the grand estate and complete the journal.
- **Open question:** a "legacy" option where you pass the estate to an heir and begin a new estate elsewhere with permanent bonuses (a prestige system). It adds long-term replay but must stay optional and gentle.

---

## 13. Settings and quality of life

- Idle strip position (bottom, top, left, right), height and transparency.
- Always on top toggle.
- Separate volume sliders: music, ambience, effects.
- Notifications (optional): cart returned, storage full, order complete, festival started.
- Autosave and Steam Cloud saves.
- Pause offline progress (for players who do not want it).
- Controller and Steam Deck support for full window mode.
- Language support planned from the start (all text in data files, not code).

---

## 14. Pacing targets

To be tuned through playtesting.

| Moment | Target |
|---|---|
| First harvest | Under 1 minute |
| First cart sale | Under 3 minutes |
| First villa upgrade | Within the first session (about 30 minutes) |
| Second land unlocked | A few days of casual play |
| Grand estate | Several weeks of mixed active and idle play |
| Journal complete | A long term goal for dedicated players |

---

## 15. Open questions

- Price point: roughly \$10 to \$15, to be decided once content size is clear.
- Length of the day cycle and seasons in real time.
- Whether to include the legacy (prestige) system.
- How much story, if any: a light framing (inheriting your uncle's ruined farm) versus no story at all.
- Whether townspeople appear on screen or only through orders on the notice board.
- Full name and trademark check for "Otium".
