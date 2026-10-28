# Farmus Maximus: Game Design

*A play on the Circus Maximus, ancient Rome's grandest stage, given to a humble farm.*

The complete design of the game, kept high level. Art details are in `Asset-list.md`.

## Pitch

A cozy, semi-idle farming game on a Roman country estate. Grow rolling fields of lavender and wheat, restore ruined farm buildings to turn your harvest into oil, flour, bread, honey and wine, and take your goods to the market town to sell. Slowly bring a whole estate back to life. Play actively, or let it run along the bottom of your screen while you work.

**Hook:** Rusty's Retirement meets Cast n Chill, on a Roman villa.

## Pillars

Every feature supports at least one of these.

1. **Peaceful.** Nothing dies, nothing spoils, no timers to dread.
2. **Beautiful.** The landscape is the reward. Every purchase changes what you see.
3. **Growth you can see.** Ruins become working buildings; bare land becomes fields.
4. **Works in the background.** Everything can run idle; playing actively is faster and more fun.
5. **Simple to read.** A glance shows what is ready, what is working and what needs you.
6. **Always something to watch.** Animals, insects, water, weather, people on the road.
7. **Every good has a purpose.** Selling is one choice among several, so deciding what to keep is part of the fun.

---

## 1. The estate

### A scrolling landscape

The estate is one long side view, about **four screens wide**, that you scroll through left and right. The background is a wide painted panorama in parallax layers (sky, mountains, hills, trees), so scrolling feels like walking through the countryside.

Scroll by dragging, the mouse wheel, the arrow keys or a gamepad. A small map bar jumps straight to any zone.

### Zones, from left to right

| Zone | What is there | Starts as |
|---|---|---|
| **Olive grove** | Olive trees, herbs, beehives, a ruined olive press | Overgrown, locked |
| **Home farm** | Lavender and wheat fields, the villa, the storehouse | Where you start |
| **Workshop yard** | Drying shed, mill, bakery oven, unguent workshop | Ruined buildings |
| **Vineyard slope** | Grapevines, wine press, cellar | Overgrown, locked |
| **Pasture** | Barn, chickens, goats | Empty meadow, locked |
| **The road** | Leads off the right edge to the market town | Always open |

Unlock a zone by buying its **land deed** at the market. The weeds and rubble clear away, and its plots and ruins become available.

### Display modes

- **Full window:** the whole estate, for active play.
- **Desktop strip:** a borderless, always-on-top strip along the bottom of the screen showing one zone, either floating over the desktop (transparent) or with the painted landscape behind it (solid). You choose the zone, or let it follow whatever is busiest.

---

## 2. Crops

| Crop | Type | Zone | Main uses |
|---|---|---|---|
| **Lavender** | Perennial: regrows after harvest | Home farm | Sell, dry, lavender oil, bees |
| **Wheat** | Annual: replant after harvest | Home farm | Flour, animal feed, straw |
| **Olives** | Tree: plant once, harvest each season | Olive grove | Olive oil |
| **Grapes** | Vine: plant once, harvest each season | Vineyard | Wine |
| **Herbs** (rosemary, thyme) | Perennial | Olive grove | Bees, recipes |

### Lavender, the signature crop

The most common crop and the game's visual identity: rows of purple against cream stone, terracotta roofs and dark cypresses. It sways in waves in the wind, bees and butterflies gather on it, and it changes through the seasons (green mounds in spring, full bloom in summer, silver after harvest, grey-green in winter). Varieties include common purple, deep violet, blue-grey and a rare white found through orders, the dog or the journal.

### Growing

- Every crop shows its growth stages, with a gentle cue when it is ready.
- **Quality:** Common, Fine or Excellent. Quality rises with manure, watering, blessings and a well-timed harvest, and sells for more.
- **Water:** plots near the aqueduct channels are watered automatically; rain waters everything. Dry plots grow slower but never die.

---

## 3. Buildings

### Buy, repair, upgrade

Every building starts as a **ruin** on the estate:

1. **Buy** the ruin with coins.
2. **Repair** it with coins, **materials** (stone, timber, roof tiles) and **provisions** for the builders (bread or wine). Repairs take real time under scaffolding and finish even while the game is closed.
3. **Upgrade** it, up to 3 levels: faster, bigger batches, better quality. Each level visibly changes the building.

### The buildings

| Building | Takes | Makes | Zone |
|---|---|---|---|
| **Storehouse** | | Holds your goods | Home farm |
| **Drying shed** | Lavender | Dried lavender | Workshop yard |
| **Mill** | Wheat | Flour and straw | Workshop yard |
| **Bakery oven** | Flour | Bread | Workshop yard |
| **Olive press** | Olives | Olive oil | Olive grove |
| **Unguent workshop** | Lavender and olive oil | Lavender oil, and bath oil once the bathhouse wing is built | Vineyard slope |
| **Beehives** | Nothing; bees visit nearby flowers | Honey and wax (lavender honey near lavender) | Olive grove |
| **Wine press** | Grapes | Young wine | Vineyard |
| **Cellar** | Young wine | Aged wine, worth more the longer it rests | Vineyard |
| **Barn** | Wheat and straw as feed | Eggs, milk, manure | Pasture |
| **Dairy** | Milk | Cheese | Pasture |
| **Lararium** (household shrine) | Offerings | Temporary blessings | Home farm |
| **Villa** | | The heart of the estate (section 7) | Home farm |

Click a building to open its panel: what it makes, what it needs, its queue and its next upgrade. Load it from the storehouse and it works on its own, putting the result back in the storehouse. With a helper assigned, it loads itself.

---

## 4. The market town

The road at the right edge leads to the **market town**: a small Roman forum with stalls, an awning-covered market, townspeople and a fountain.

### Two ways to sell

| | Sell yourself | Send the cart |
|---|---|---|
| How | Go to the market and sell at the stalls | Load the cart; the donkey goes alone |
| Price | **Full price**, plus special buyers | **Lower price** (the trader takes a cut) |
| Play | Active | Idle; keeps working while you are away |

### At the market

- **Sell** goods at today's prices.
- **Buy** seeds, saplings, animals, materials, decorations and land deeds.
- **Fill orders** from the notice board: "a merchant wants 10 lavender oil", "the baker needs 30 flour", "a senator's banquet needs 5 aged wines". Orders pay a bonus and sometimes a rare reward, and never expire.
- **Meet the regulars:** a few traders with small requests and stories.

### Prices

- Every good has a base price.
- **Demand:** selling a lot of one good in a day lowers its price until the next day, so a mix of goods pays best.
- **Daily favourites:** one or two goods are in high demand each day, shown on a board at the gate.
- **Seasons and festivals** shift prices: bread sells best in winter, flowers during Floralia.
- Prices stay gentle and readable, never a stock market.
- Coins are **sestertii**; a rare gold **aureus** comes from special orders and festivals.

---

## 5. Why keep goods

Every good has more than one use, so a full storehouse is full of choices.

| Reason | Example |
|---|---|
| **Make something worth more** | Lavender plus olive oil becomes lavender oil, worth far more than either |
| **Feed animals** | Wheat and straw feed chickens and goats |
| **Fertilise fields** | Manure makes crops grow faster and better |
| **Feed the builders** | Repairs and villa stages need bread or wine |
| **Fill orders** | Hold 10 lavender oil for a merchant's bonus |
| **Wait for a better price** | Keep bread for winter, flowers for a festival |
| **Age it** | Wine in the cellar gains value over time |
| **Offerings** | Honey at the lararium earns a blessing |
| **Collect** | The first of each good and quality fills a page in the journal |

Nothing spoils. Keeping goods is always safe; it only uses storehouse space, which can be upgraded. The trader sells only the extras: they leave at home the provisions for the villa's next stage, one of each offering once the lararium stands, what the open market orders ask for and what the workshops need next, and a good marked Keep stays home entirely. While the cart is parked at the farm, goods waiting for market are loaded on it, so its space adds to the storehouse's; a bigger cart holds more as well as carrying more.

---

## 6. Helpers and idle play

### Named helpers

Each helper automates one part of the estate and walks around doing their job:

| Helper | Does | Unlocked by |
|---|---|---|
| **Farmhand** | Harvests and replants the fields | Villa stage 2 |
| **Miller** | Runs the mill and the bakery | Repairing the mill |
| **Beekeeper** | Tends the hives and herbs | Repairing the beehives |
| **Presser** | Runs the olive and wine presses | Repairing the olive press |
| **Stable hand** | Feeds the animals, collects eggs and milk, runs the dairy | Repairing the barn |
| **Perfumer** | Runs the drying shed and the unguent workshop | Repairing the unguent workshop |
| **Trader** | Takes the cart to market and sells the right goods | Buying a second cart |

Each has a name, a small portrait and a little personality. The estate is run by a free family and hired neighbours; Roman estates relied on enslaved labour, and the game deliberately shows a free, family-run farm.

### Active and idle

| | Active | Idle |
|---|---|---|
| Fields | Click to harvest; good timing gives better quality | Farmhand harvests at normal quality |
| Buildings | Load what you choose | Helpers load what is available |
| Selling | Full price at the market | Cart sells at a lower price |
| Pace | Faster | Slower but steady |

### While you are away

Everything keeps going: crops grow, helpers work, buildings process, the cart makes trips, repairs finish and wine ages. A "while you were away" summary greets you. Up to 12 hours away count, so a night's sleep pays in full but a long absence is no better than a day's. Progress pauses only when the storehouse and the parked cart are both full. An option turns offline progress off.

---

## 7. The villa

| Stage | Look | Unlocks |
|---|---|---|
| 1 | Ruined farmhouse | Starting point |
| 2 | Restored farmhouse | The farmhand; land deeds at the market |
| 3 | Villa rustica | Workshop yard deed, cellar plans |
| 4 | Villa with portico | The lararium, decorations |
| 5 | Villa with peristyle garden | Herb garden, fountain |
| 6 | Bathhouse wing | Lavender oil becomes a valuable bath oil |
| 7 | Grand estate | The final look: statues and mosaics |

Each stage costs coins, materials and provisions, and is built under scaffolding over time.

**Decorations** (mosaics, frescoes, statues, fountains, planters, lanterns) are a cosmetic use for coins; some come only from festivals and rare orders.

### The lararium

Leave an offering of your own goods for one blessing at a time, lasting a few hours:

| God | Blessing |
|---|---|
| Ceres | Faster grain |
| Bacchus | Better wine |
| Minerva | Bigger olive harvests |
| Pomona | Better fruit |
| Mercury | Better market prices |
| Lares (household spirits) | Faster processing |

---

## 8. The living world

None of this is needed to play; it is why people leave the game open.

- **The dog:** your companion from the start. Wanders, sits, naps (more at night), can be petted, and sometimes digs up a find: an old coin, a rare seed, a truffle.
- **Farm animals:** chickens and goats in the pasture, bees between the hives and the lavender, the donkey hauling the cart along the road, a cat in the storehouse that ignores the dog.
- **Insects:** butterflies and bees by day, dragonflies near water, fireflies at night, snails after rain.
- **Birds and wildlife:** flocks crossing the sky, swallows over the fields, storks nesting on the villa roof later on, lizards on walls, rabbits at dusk, a fox and a hoopoe as rare visitors.
- **Water:** flowing aqueduct channels, a fountain, rain puddles, morning dew.
- **Wind and light:** waves through the lavender and wheat, swaying trees, drifting cloud shadows, golden hour, lamplit windows at night.
- **People:** helpers at work, townspeople at the market, shepherds and travellers on the road.
- **Rare sightings:** a rainbow, a shooting star, the fox, the white butterfly, the cat and dog asleep together. Each is recorded in the journal the first time you see it.

---

## 9. Time, seasons and weather

- **Day and night:** a full day every 20 minutes or so; golden hour, dusk, a moonlit night with stars.
- **Seasons:** spring, summer, autumn and winter change how plants look, what grows best and prices. Lavender blooms in summer, olives are harvested in autumn, and winter is for processing, building and selling stored goods.
- **Weather:** sun, clouds, gentle rain that waters the crops, morning mist. Never harmful.
- **Festivals:** special orders, market decorations and price bonuses.

| Festival | Season | Theme |
|---|---|---|
| Cerealia | Spring | Grain |
| Floralia | Spring | Flowers and garlands |
| Vinalia | Late summer | The grape harvest |
| Saturnalia | Winter | Gifts, feasting, lanterns |

---

## 10. Goals and collections

- **The farmer's journal:** every crop, good, quality, building, helper, animal, find and rare sighting.
- **Orders** give short-term goals.
- **Milestones:** restore every building, open every zone, finish the villa.
- **Steam achievements.**

---

## 11. Screens

| Screen | What it shows |
|---|---|
| **The estate** | The scrolling landscape, with a slim bar for coins, storehouse and the zone map |
| **Building panel** | What it makes, its queue, upgrades, its helper |
| **Storehouse panel** | Every good you hold |
| **Market town** | Stalls to sell and buy, the price board, the notice board |
| **Journal** | Collections and milestones |
| **Settings** | Music, ambience and effects volume; window and strip options; offline progress on or off; notifications |
| **Desktop strip** | One zone along the bottom of the screen, with a compact bar |

Controller and keyboard play work everywhere in the full window. All text lives in data files, ready for translation.

---

## 12. How it all connects

```
Fields ──harvest──▶ Storehouse ──▶ Buildings ──refined goods──▶ Storehouse
   ▲                    │   │                                      │
   │ manure             │   └──feed──▶ Animals ──eggs, milk────────┘
   │                    │
   └── Animals          ├──▶ Cart (idle, lower price) ──▶ coins
                        ├──▶ Market (you sell, full price, orders) ──▶ coins
                        └──▶ Repairs, offerings, journal

Coins ──▶ land deeds, ruins, repairs, upgrades, helpers, seeds, animals, decorations
```

---

## 13. Pacing (rough targets, tuned in playtesting)

| Moment | Target |
|---|---|
| First harvest | Under 1 minute |
| First sale | Under 3 minutes |
| First building repaired, first refined good, first market visit | First session |
| Second zone unlocked | A few days of casual play |
| Every building restored | A few weeks |
| Grand estate | Several weeks to a couple of months |

---

## 14. Platforms and performance

The desktop strip has only been tested on Windows so far. Before launch it must pass on each of these:

| System | Checks |
|---|---|
| Windows 10 and 11 | Transparency, always on top, click-through, taskbar at the bottom and the side, high-DPI scaling |
| macOS (Apple Silicon) | The same, plus full-screen apps and multiple desktops |
| Linux X11 | The same as Windows |
| Linux Wayland | Expect limits on always-on-top and positioning; the solid-background mode must still work |
| Steam Deck | Full window only: a controller, readable text, battery use |
| With overlays | Steam, Discord, NVIDIA and AMD overlays running |

The strip must run for a full workday on Windows and Mac without a black background, a stuck window or noticeable battery drain, and every other system must at least run cleanly in solid mode.

| Situation | Target |
|---|---|
| Full window, active | 60 fps, low CPU |
| Strip in the background | 30 fps or less |
| Nothing changing on screen | Close to idle CPU |
| Steam Deck | Several hours of battery |

---

## 15. Decisions made while building

These were open questions; the full build settled them as follows. Any of them can still change.

| Question | Decision |
|---|---|
| Market town: its own screen, or the end of the scroll? | Its own screen, reached by the Town button. The cart's road runs off the right edge towards it. |
| How many zones at launch? | All five: olive grove, home farm, workshop yard, vineyard slope, pasture. |
| Which goods have quality? | Every good except materials, straw, wax, manure and truffles. Workshops pass the quality of their ingredients on. |
| A walking character, or an unseen hand? | An unseen hand. The helpers, the dog and the townspeople are the people on screen. |
| How much story? | Light: your uncle Marcus, who left you the farm, welcomes you on the first day and guides your first steps, and the regulars have their lines on the notice board. |
| When do deeds go on sale? | The grove with the restored farmhouse, the workshop yard and vineyard with the villa rustica, the pasture with the portico. |

Also added during the build: a dairy (milk to cheese) and a perfumer to run the drying shed and unguent workshop, since no other helper covered them. The unguent workshop stands on the vineyard slope, because the workshop yard had no room for a fourth building.

## 16. Still open

- A "legacy" option to pass the estate to an heir and start again with bonuses?
- Trademark, domain and social handle checks for the name.
