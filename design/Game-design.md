# Otium: Game Design

*Working title.* This is the complete design of the game. It replaces `Game-mechanics.md`, adding a scrolling estate, buildings that refine crops, a market town, and reasons to keep goods instead of selling everything.

## Pitch

A cozy, semi-idle farming game on a Roman country estate. Grow lavender and wheat, restore ruined farm buildings to turn your harvest into oil, flour, bread, honey and wine, and take your goods to the market town to sell. Slowly bring a whole estate back to life. Play actively, or let it run along the bottom of your screen.

## Pillars

1. **Peaceful.** Nothing dies, nothing is lost, no timers to dread.
2. **Beautiful.** The landscape is the reward. Every purchase changes what you see.
3. **Growth you can see.** Ruins become working buildings; bare land becomes fields.
4. **Works in the background.** Everything can run idle; playing actively is faster and more fun.
5. **Simple to read.** A glance shows what is ready, what is working and what needs you.
6. **Always something to watch.** Animals, insects, weather, people on the road.
7. **Every good has a purpose.** Selling is one choice among several, so deciding what to keep is part of the fun.

---

## 1. The estate

### A scrolling landscape

The estate is one long, continuous side view, about **four screens wide**, that you scroll through left and right. The background is a wide painted panorama with parallax layers (sky, mountains, hills, trees), so scrolling feels like walking through the countryside.

**Scrolling:** drag with the mouse, the mouse wheel, the arrow keys or the gamepad. Clicking a building or zone name in a small map bar jumps there.

### Zones, from left to right

| Zone | What is there | Starts as |
|---|---|---|
| **Olive grove** | Olive trees, beehives, a ruined olive press | Overgrown, locked |
| **Home farm** | Lavender and wheat fields, the villa, the storehouse | Where you start |
| **Workshop yard** | Drying shed, mill, bakery oven, unguent workshop | Ruined buildings |
| **Vineyard slope** | Grapevines, wine press, cellar | Overgrown, locked |
| **Pasture** | Barn, chickens, goats | Empty meadow, locked |
| **The road** | Leads off the right edge to the market town | Always open |

**Unlocking a zone:** buy its land deed at the market. The zone clears (weeds and rubble animate away), and its plots and ruined buildings become available.

### The desktop strip

The strip shows one part of the estate at a time. You choose which part, or let it follow whatever is busiest.

---

## 2. Crops

| Crop | Type | Where | Main use |
|---|---|---|---|
| **Lavender** (signature) | Perennial: regrows after harvest | Home farm | Sell, dry, make lavender oil, feed bees |
| **Wheat** | Annual: replant after harvest | Home farm | Flour, animal feed, straw |
| **Olives** | Tree: plant once, harvest each season | Olive grove | Olive oil |
| **Grapes** | Vine: plant once, harvest each season | Vineyard | Wine |
| **Herbs** (rosemary, thyme) | Perennial | Olive grove | Bees, recipes |

Each crop shows its growth stages. Lavender stays the most common crop and the visual identity of the game.

---

## 3. Buildings

### Buy, repair, upgrade

Every building starts as a **ruin** on the estate. Each one goes through three steps:

1. **Buy** the ruin (coins). It becomes yours, but it does nothing yet.
2. **Repair** it: coins plus **materials** (stone, timber, roof tiles), plus **provisions** for the builders (bread or wine). Repairs take real time under scaffolding, and finish even while the game is closed.
3. **Upgrade** it, up to 3 levels: faster, bigger batches, better quality. Each level visibly changes the building.

### The buildings

| Building | Turns | Into | Zone |
|---|---|---|---|
| **Storehouse** | | Holds your goods | Home farm |
| **Drying shed** | Lavender | Dried lavender | Workshop yard |
| **Mill** | Wheat | Flour, plus straw | Workshop yard |
| **Bakery oven** | Flour | Bread | Workshop yard |
| **Olive press** | Olives | Olive oil | Olive grove |
| **Unguent workshop** | Lavender + olive oil | Lavender oil (perfume and bath oil) | Workshop yard |
| **Beehives** | Nothing: bees visit nearby flowers | Honey, wax | Olive grove |
| **Wine press** | Grapes | Young wine | Vineyard |
| **Cellar** | Young wine | Aged wine (gains value over time) | Vineyard |
| **Barn** | Wheat and straw as feed | Eggs, milk, manure | Pasture |
| **Lararium** (household shrine) | Offerings | Temporary blessings | Home farm |
| **Villa** | | The heart of the estate; each stage unlocks new things | Home farm |

### How a building works

- Click a building to open its panel: what it makes, what it needs, its queue, its upgrade.
- Load ingredients from the storehouse; the building works on its own and puts the result back in the storehouse.
- With a **helper** assigned (see section 6), it loads itself and keeps going while you are away.

---

## 4. The market town

### Going to market

The road at the right edge of the estate leads to the **market town**, a separate scene: a small Roman forum with stalls, an awning-covered market, townspeople and a fountain.

You can sell in two ways:

| | Sell yourself | Send the cart |
|---|---|---|
| How | Walk to the market and sell at the stalls | Load the cart; the donkey goes alone |
| Price | **Full price**, plus special buyers | **Lower price** (the trader takes a cut) |
| Effort | Active play | Idle; works while you are away |

Both are useful: the cart for steady idle income, the market for the best prices and the things only the market offers.

### What you do at the market

- **Sell** goods at today's prices.
- **Buy** seeds, saplings, animals, building materials, decorations and land deeds.
- **Fill orders** on the notice board.
- **Talk to traders**: a few regulars with small requests and stories.

### Prices

- Every good has a base price.
- **Demand:** selling a lot of the same good on one day lowers its price for that day. It recovers overnight. This rewards selling a mix of goods instead of flooding the market with one.
- **Daily favourites:** each day one or two goods are in high demand, shown on a board at the market gate.
- **Seasons and festivals** shift prices; for example bread sells best in winter and flowers during Floralia.
- Price changes stay gentle and readable, never a stock market.

---

## 5. Why keep goods instead of selling them

Every good has more than one use, so the storehouse is full of choices.

| Reason to keep | Example |
|---|---|
| **Make something worth more** | Lavender alone sells for little; lavender plus olive oil becomes lavender oil, worth far more |
| **Feed animals** | Wheat and straw feed chickens and goats, which give eggs, milk and manure |
| **Fertilise fields** | Manure makes crops grow faster and better |
| **Feed the builders** | Repairs need bread or wine as provisions |
| **Fill orders** | A merchant wants 10 lavender oil by the end of the season, for a bonus and a rare reward |
| **Wait for a better price** | Hold bread for winter, or flowers for a festival |
| **Age it** | Wine in the cellar is worth more the longer it rests |
| **Offerings** | Leave honey at the lararium for a blessing |
| **Collect** | The first of each good and each quality fills a page in the farmer's journal |

Nothing spoils. Keeping goods is always safe; it only costs storehouse space, which can be upgraded.

---

## 6. Helpers and idle play

### Named helpers

Rather than nameless farmhands, the estate gains a small cast of **named helpers**, each one unlocking a part of the game when you hire them:

| Helper | Does | Unlocked by |
|---|---|---|
| **Farmhand** | Harvests and replants the fields | Restored farmhouse (villa stage 2) |
| **Miller** | Runs the mill and the bakery | Repairing the mill |
| **Beekeeper** | Tends the hives and the herbs | Repairing the beehives |
| **Presser** | Runs the olive and wine presses | Repairing the olive press |
| **Stable hand** | Feeds the animals, collects eggs and milk | Repairing the barn |
| **Trader** | Takes the cart to market and sells the right goods | Buying a second cart |

Helpers have names, small portraits, a line or two of personality, and walk around the estate doing their jobs, which adds life.

### Active versus idle

| | Active | Idle |
|---|---|---|
| Fields | Click to harvest; a well-timed click gives better quality | Farmhand harvests at normal quality |
| Buildings | Load what you choose | Helpers load what is available |
| Selling | Full price at the market | Cart sells at a lower price |
| Pace | Faster | Slower but steady |

### Offline progress

When the game is closed, everything keeps going: crops grow, helpers work, buildings process, the cart makes trips, repairs finish, wine ages. A "while you were away" summary greets you. Progress stops only when the storehouse is full, and nothing ever spoils or dies.

---

## 7. The villa

The villa grows in stages, and each stage unlocks something:

| Stage | Look | Unlocks |
|---|---|---|
| 1 | Ruined farmhouse | Starting point |
| 2 | Restored farmhouse | First helper (farmhand), the market deed office |
| 3 | Villa rustica | Workshop yard deed, cellar plans |
| 4 | Villa with portico | Lararium, decorations |
| 5 | Villa with peristyle garden | Herb garden, fountain |
| 6 | Bathhouse wing | Lavender oil becomes a high-value bath oil |
| 7 | Grand estate | Final look, statues and mosaics |

Each stage costs coins, materials and provisions, and is built under scaffolding over time.

---

## 8. Animals and the living world

- **The dog** stays your companion: wanders, naps, can be petted, and sometimes digs up a find.
- **Farm animals** (barn): chickens and goats wander their pen, eat feed and produce goods.
- **Bees** fly between the hives and flowering lavender.
- **The donkey** pulls the cart along the road to town and back, visibly travelling across the estate.
- **Wildlife:** butterflies, birds, fireflies and more, as now.
- **People:** helpers at work on the estate; townspeople in the market; travellers on the road.

---

## 9. Time, seasons and weather

- **Day and night:** as now, with lamplight in windows at night.
- **Seasons:** spring, summer, autumn, winter. They change how plants look, what grows best, prices and festivals. Lavender blooms in summer; olives are harvested in autumn; winter is for processing, building and selling stored goods.
- **Weather:** sun, clouds, gentle rain (waters crops), morning mist. Never harmful.
- **Festivals:** Cerealia, Floralia, Vinalia and Saturnalia bring special orders, market decorations and higher prices for certain goods.

---

## 10. Goals and collections

- **The farmer's journal:** every crop, good, quality, building, helper, animal and rare sighting.
- **Orders** from the notice board give short-term goals.
- **Milestones:** restore every building, fill every zone, finish the villa.
- **Achievements** on Steam.

---

## 11. Screens

| Screen | What it shows |
|---|---|
| **The estate** | The scrolling landscape, with a slim bar for coins, storehouse and the zone map |
| **Building panel** | Opens over the estate: what it makes, its queue, upgrades, the assigned helper |
| **Storehouse panel** | Every good you hold and how much |
| **Market town** | Stalls to sell and buy, the price board, the notice board |
| **Journal** | Collections and milestones |
| **Settings** | Volume, window and strip options |
| **Desktop strip** | One zone of the estate along the bottom of the screen |

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
| First building repaired | First session |
| First refined good (dried lavender) | First session |
| First visit to the market | First session |
| Second zone unlocked | A few days of casual play |
| Every building restored | A few weeks |
| Grand estate | Several weeks to a couple of months |

---

## 14. Art this adds

High level only; details go in `Asset-list.md` later.

- A wide panorama background for the whole estate, in parallax layers, painted in the current style.
- Each building in three looks: ruin, repaired, and upgraded levels, plus scaffolding.
- New crops: olives, grapes, herbs, each with growth stages.
- Animals: chickens and goats with simple animations.
- Helpers: six characters with walk and work animations, and small portraits.
- The market town scene: forum background, stalls, townspeople.
- Goods icons for every item.

## 15. Open questions

- Should the market town be a separate screen, or the far right end of the scroll?
- How many zones at launch (all five, or fewer and bigger)?
- Should goods have quality tiers everywhere, or only for crops?
- Can the player walk as a character, or stay as an unseen hand clicking on things?
- Final name.
