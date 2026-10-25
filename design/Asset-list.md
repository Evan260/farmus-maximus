# Otium: Asset List

Every art, audio and store asset the game needs, based on `Game-mechanics.md`. Counts are estimates to help plan the work.

## Conventions

These are proposals; lock them in before making final art, because changing them later means redoing everything.

| Setting | Proposal |
|---|---|
| Base resolution | 480 x 270, scaled up by whole numbers (x4 = 1920 x 1080) |
| Plot size | 32 x 32 pixels (one lavender bush fills one plot, as in the PixelLab tests) |
| Crop sprites | Up to 32 x 48 (tall crops overlap the plot above) |
| Characters and animals | 48 x 48 canvas for the dog and farmhands (animations get a larger canvas automatically) |
| Trees | Up to 64 x 96 |
| Buildings | Up to about 192 x 112 (the villa) |
| Palette | One fixed palette for the whole game (`palette.hex` from the art tests is the starting point), with a range of lavender purples added as the signature accent colour |
| Lighting | Light comes from the upper left in all art |
| Day, night and seasons | Done in the engine with colour tinting where possible, so most art needs only one version |

**Source column key:**

- **PixelLab:** generated with PixelLab (see the workflow below), with small fixes in a pixel editor where needed.
- **Code:** generated or drawn by the engine (particles, tints, simple shapes).
- **License:** bought or licensed (music, sound effects, fonts).
- **Placeholder:** programmer art used only while a system is being built; replaced by the real asset.

---

## PixelLab workflow

PixelLab produces true pixel art (a clean grid, a limited colour count, transparent backgrounds) and allows commercial use of everything it generates. Tests so far: lavender, a background layer, the villa and the dog with a walk animation all passed.

### Which tool for which asset

| Asset type | PixelLab tool | Settings |
|---|---|---|
| Crops and plants | Create image, Pro model | 32 x 32 gives 64 variations in one generation; use a random one per plot so fields never look copy-pasted |
| Single objects (cart, amphora, storeroom, presses) | Create image, Pixen model | Exact size, View: Side, Remove background on |
| Buildings and villa stages | Pixen, then the Edit tool for each further stage | View: Side, Direction: south (facing the viewer); describe a flat, front-on view so it does not drift isometric |
| Landscape layers | Pixen | Up to 484 x 132 with transparency (65,536 pixels of area); generate wider layers without transparency and remove the background afterwards |
| Characters and animals | Create character (v3) | Template: dog, cat, horse, bear or lion for animals, mannequin for people; View: Side |
| Character animations | Animate character | One direction at a time (east, then mirror for west); 8 frames is enough for a walk |
| Object animations (water, lavender sway, presses) | Object animations, or animate with text | Short loops |
| Ground and wall strips | Side-scroller tileset | Tileable pieces |
| UI pieces | UI asset tool | Panels, buttons, frames |

### Keeping everything consistent

- **One palette:** pass the game's palette colours to every generation that accepts a palette, so all assets share the same colours.
- **One style reference:** once a few assets look right, use them as the style reference for new ones.
- **Nothing that moves in a background:** every background prompt ends with *"no birds, no animals, no people, no smoke, no buildings"*. Birds, animals, smoke, flowing water and buildings are separate sprites so they can animate or change.
- **Characters match the backgrounds:** generate characters and animals with a background painting as the style reference, outline-free, with natural proportions rather than a cute big-headed look.
- **One prompt ending:** finish every prompt with the same style words, for example *"cozy pixel art game sprite, warm golden light from the upper left, earthy Mediterranean colours, lavender purple accents"*.
- **Avoid words that cause a glowing icon look** at small sizes, such as "sunlight" on its own; add "no glow, plain background" if it happens.
- **Name files by asset and stage**, for example `lavender_bloom_03.png`, so the game can load them by name.

### Cleanup

Small scripts handle bulk fixes so hand editing is rare:

- cutting 64-variation sheets into separate files,
- removing stray fragments left by background removal,
- remapping colours onto the palette,
- fading far landscape layers toward the sky colour (also done in the engine).

A pixel editor (Aseprite, about \$20, or the free Pixelorama) covers the rest: a stray pixel, trimming an animation loop, a small colour tweak.

### Cost

Generations are the unit of cost. From the tests: a 48 x 48 character in 8 directions costs 2 generations, an 8-frame walk animation in one direction costs 1, and a 64-variation crop sheet costs 1. The basic prototype set (home farm landscape, two villa stages, lavender, wheat, plots, storeroom, cart, donkey, dog animations, starter icons, UI strip, a butterfly and a bee) is roughly 25 to 35 generations. A paid plan is needed beyond the trial.

### Generating from Claude Code

PixelLab has an API and an MCP server, so Claude can generate, download and clean up assets directly from the asset list. Set it up in your own terminal (never paste the key into chat):

```
claude mcp add pixellab https://api.pixellab.ai/mcp -t http -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 1. Landscape layers (parallax backgrounds)

One set per land. Each layer is a wide, horizontally scrolling image.

| Layer | Per land | Notes | Source |
|---|---|---|---|
| Sky gradient | 1 | Tinted by the engine for dawn, day, golden hour and night | Code or PixelLab |
| Clouds | 4 to 6 cloud sprites, shared by all lands | Drift slowly across the sky | PixelLab |
| Sun and moon | 1 each, shared | Move across the sky over the day | PixelLab |
| Stars | 1 overlay, shared | Fade in at night | Code |
| Distant mountains | 1 | Slowest moving layer | PixelLab |
| Hills and landmarks | 1 | Aqueduct, river, sea or pines depending on the land | PixelLab |
| Tree line | 1 | Cypresses, olive trees, poplars | PixelLab |
| Near ground | 1 | Grass bank where the villa and buildings sit | PixelLab |

**Season overlays** (shared where possible): spring blossom accents, autumn colour shift, winter frost or light snow on mountains and roofs.

**Lands:** home farm (hillside), vineyard slopes, river valley, mountain pasture, coastal estate.

**Estimate:** about 5 layers x 5 lands = 25 large images, plus about 15 shared sky pieces and 10 season overlays.

---

## 2. The villa

| Asset | Count | Notes | Source |
|---|---|---|---|
| Villa stage 1: ruined farmhouse | 1 | | PixelLab |
| Villa stage 2: restored farmhouse | 1 | | PixelLab |
| Villa stage 3: villa rustica | 1 | | PixelLab |
| Villa stage 4: villa with portico | 1 | Columned porch | PixelLab |
| Villa stage 5: villa with peristyle | 1 | Inner colonnaded garden visible | PixelLab |
| Villa stage 6: bathhouse wing | 1 | Attached wing | PixelLab |
| Villa stage 7: grand estate | 1 | | PixelLab |
| Night window glow | 1 per stage | Overlay, lights in windows | PixelLab |
| Upgrade transformation effect | 1 | Dust, scaffolding or sparkle as the stage changes | PixelLab plus Code |
| Scaffolding | 1 to 2 | Shown while an upgrade builds | PixelLab |

**Estimate:** 7 villa stages, 7 night overlays, 3 effect pieces.

---

## 3. Farm buildings and structures

All sit in the farm band.

| Asset | Variants | Notes | Source |
|---|---|---|---|
| Storeroom | 3 upgrade levels | Fullness shown visually (crates and jars pile up) | PixelLab |
| Drying racks | 2 levels | Lavender bundles hanging upside down to dry | PixelLab |
| Unguent workshop | 2 levels | Jars of flowers steeping in oil | PixelLab |
| Olive press | 2 to 3 upgrade levels, plus a working animation | | PixelLab |
| Wine press / treading vat | 2 to 3 levels, plus animation | | PixelLab |
| Wine cellar entrance | 1 to 2 levels | Amphorae visible | PixelLab |
| Mill | 2 levels, plus turning animation | Watermill on river land | PixelLab |
| Bread oven | 1 to 2 levels, plus smoke and glow | | PixelLab |
| Beehives | 3 levels, plus bee animation | | PixelLab |
| Dairy shed | 1 to 2 levels | | PixelLab |
| Garum works | 1 to 2 levels | Coastal land | PixelLab |
| Lararium (shrine) | 1, plus glow when a blessing is active | | PixelLab |
| Notice board | 1 | For orders, if shown on the farm | PixelLab |
| Well | 1 | | PixelLab |
| Aqueduct channel | Straight, end, corner pieces | Waters adjacent plots | PixelLab |
| Fences and walls | 3 to 4 pieces | Plot borders | PixelLab |
| Trellises | 1 to 2 | For vines | PixelLab |
| Animal pens | Chicken coop, goat pen | | PixelLab |
| Dog bed / nap spots | 2 to 3 | | PixelLab |
| Market stall | 1 | Shown on the market screen or cart return | PixelLab |

**Estimate:** about 40 building sprites plus 8 animations.

---

## 4. Plots and soil

| Asset | Variants | Source |
|---|---|---|
| Plot: grass (unused) | 1 to 2 | PixelLab |
| Plot: tilled soil | 1 | PixelLab |
| Plot: watered soil | 1 | PixelLab |
| Plot: fertilised soil | 1 | PixelLab |
| Plot: locked or unpurchased | 1 | PixelLab |
| Plot: selection highlight | 1 | Code or PixelLab |
| Ready-to-harvest cue (sparkle or icon) | 1 | PixelLab |

---

## 5. Crops

Each crop needs its growth stages. Perennials also need seasonal looks.

### Lavender (signature crop, highest priority)

Lavender covers most of the farm, so it gets the most care and the most animation.

| Asset | Count | Notes | Source |
|---|---|---|---|
| Growth stages | 3 per variety: cutting, young mound, mature | | PixelLab |
| Seasonal looks (mature) | 4 per variety: spring green, summer bloom (ready), autumn silver after harvest, winter grey-green | | PixelLab |
| Wind sway animation | 3 to 4 frames for the bloom look, per variety | Or an engine shader; test both | PixelLab or Code |
| Field edge pieces | 2 to 3 | So neighbouring lavender plots merge into continuous rows | PixelLab |
| Harvested bundles on the ground | 1 | Shown briefly after harvest | PixelLab |

**Varieties:** common purple, deep violet, blue-grey, rare white. **Subtotal:** about 45 sprites and frames.

### Annual crops (4 to 5 stages each: seed, sprout, young, mature, ready, plus harvested stubble where relevant)

| Crop | Stages | Source |
|---|---|---|
| Emmer wheat | 5 | PixelLab |
| Spelt | 5 | PixelLab |
| Barley | 5 | PixelLab |
| Millet | 5 | PixelLab |
| Cabbage | 4 | PixelLab |
| Leeks | 4 | PixelLab |
| Onions | 4 | PixelLab |
| Garlic | 4 | PixelLab |
| Lentils | 4 | PixelLab |
| Chickpeas | 4 | PixelLab |
| Fava beans | 4 | PixelLab |
| Rosemary | 4 | PixelLab |
| Thyme | 4 | PixelLab |
| Roses | 4 | PixelLab |

**Subtotal:** 14 crops, about 60 sprites.

### Vines and trees (growth stages plus seasons)

Stages: sapling, young, mature. Mature seasonal looks: spring blossom, summer green, fruiting (ready), autumn, winter bare.

| Crop | Sprites | Source |
|---|---|---|
| Grapes (red) | about 7 | PixelLab |
| Grapes (white) | about 7 | PixelLab |
| Olive tree | about 7 | PixelLab |
| Fig tree | about 7 | PixelLab |
| Pomegranate tree | about 7 | PixelLab |
| Quince tree | about 7 | PixelLab |
| Pear tree | about 7 | PixelLab |
| Cherry tree | about 7 | PixelLab |

**Subtotal:** 8 perennials, about 56 sprites.

**Optional:** a gentle sway animation (2 to 3 frames) for ready crops and trees in wind. Can often be done in the engine with a shader instead.

---

## 6. Items and icons

Used in the storeroom, the cart, the market, orders and the journal. Small icons, about 16 x 16.

| Group | Items | Count |
|---|---|---|
| Seeds and saplings | One per crop | 23 |
| Raw produce | One per crop, plus eggs, milk, fish, wax | about 27 |
| Lavender goods | Fresh bundle and dried bundle (per variety), lavender oil, rose oil, lavender honey | about 12 |
| Processed goods | Olive oil, must, wine (red, white), aged wine, flour, bread, honey (other flower types, 2 to 3), cheese, garum, salt | about 14 |
| Quality badges | Common, Fine, Excellent | 3 |
| Building materials | Stone, timber, roof tiles | 3 |
| Currency | Sestertius coin, aureus coin, coin stack | 3 |
| Offerings | A few shrine offering icons | 3 to 4 |
| Dog finds | Old coin, rare seed, truffle, bone, lost ring | 5 |
| Decorations (shop icons) | One per decoration | see section 8 |

**Estimate:** about 95 item icons.

---

## 7. Characters and animals

### The dog (highest priority character)

| Animation | Frames (estimate) |
|---|---|
| Idle sit | 2 to 4 |
| Breathing / tail wag | 4 |
| Walk | 6 |
| Run | 6 |
| Sleep | 2 to 4 |
| Lie down / get up | 4 |
| Sniff and dig | 6 |
| Bark | 3 |
| Being petted (happy) | 4 |
| Ride in the cart | 2 |
| Chase a bird | uses run |

**Plus:** 4 to 6 collar cosmetics as small overlays. **Estimate:** about 45 frames.

### Other characters

| Character | Animations | Frames (estimate) |
|---|---|---|
| Farmhand (base body) | Walk, harvest, carry, plant, idle | about 25 |
| Farmhand variations | 4 to 6 looks (hair, tunic colour, hat) as palette swaps or overlays | 4 to 6 overlays |
| Donkey | Walk while pulling the cart, idle | about 10 |
| Cart | Static, loaded (2 to 3 fullness levels), wheel turning | about 6 |
| Chickens | Idle, peck, walk, roost | about 10 |
| Goats | Idle, graze, walk, climb, playful headbutt | about 16 |
| Cat | Sit, sleep, walk, stretch, stalk, pounce | about 16 |
| Donkey extras | Ear flick, nap standing, bray | about 6 |
| Townspeople portraits | For orders: merchant, baker, priest, soldier, senator's steward, neighbour, child | 7 to 10 portraits |

### Ambient creatures

Small sprites, mostly 2 to 6 frames each. Movement paths are done in code, so each creature only needs a few frames.

| Creature | Animations | Frames (estimate) |
|---|---|---|
| Butterflies (3 to 4 colours, plus rare white) | Flutter, rest with wings open and closed | 4 per colour |
| Bees and bumblebees | Fly | 2 to 3 each |
| Dragonflies | Hover, dart | 3 to 4 |
| Ladybird | Crawl, fly | 4 |
| Fireflies | Glow pulse (mostly code) | 2 |
| Snail | Crawl | 3 to 4 |
| Moths | Flutter | 2 to 3 |
| Swallows | Swoop | 4 |
| Sparrows | Hop, peck, fly away | 8 |
| Storks | Stand on nest, clatter, fly | 8 |
| Hoopoe (rare) | Hop, raise crest, fly | 6 |
| Lizards | Bask, dart | 4 |
| Rabbits | Sit, hop, ear twitch | 8 |
| Hedgehog | Walk, curl up | 6 |
| Fox (rare) | Walk, sit, look around | 8 |
| Deer (distant, tiny) | Graze, walk | 4 |
| Owl | Perch, blink, turn head | 4 |
| Bird in the fountain | Splash, shake | 4 |

### Passers-by (background road, small and distant)

| Figure | Frames (estimate) |
|---|---|
| Shepherd plus 3 to 4 sheep | about 12 |
| Merchant cart | about 6 |
| Traveller on a mule | about 6 |
| Villagers / pilgrims (2 to 3 looks) | about 12 |
| Marching soldiers (rare, one group sprite) | about 6 |
| Children running (festivals) | about 8 |

**Estimate:** about 165 character and animal frames, about 140 ambient creature frames, about 50 passer-by frames, plus 10 portraits.

---

## 8. Decorations

Cosmetic items placed around the villa and farm.

| Group | Examples | Count |
|---|---|---|
| Mosaics | Dog ("Cave canem"), fish, vines, geometric | 4 to 6 |
| Frescoes | Garden scene, birds | 2 to 3 |
| Statues | Ceres, Bacchus, a bust, a small fountain figure | 3 to 4 |
| Fountains | Small, large | 2 |
| Planters and pots | Potted plants, terracotta pots | 4 to 6 |
| Paths | Gravel, stone, mosaic path pieces | 3 |
| Lanterns and torches | With night glow | 2 to 3 |
| Benches and tables | | 2 to 3 |
| Festival decorations | Garlands (Floralia), lanterns (Saturnalia), vine wreaths (Vinalia) | 5 to 6 |

**Estimate:** about 35 decoration sprites, each with a shop icon.

---

## 9. Effects and particles

Mostly done in the engine with small sprite pieces.

### Water (high priority: one of the most satisfying things to watch)

| Animation | Notes | Source |
|---|---|---|
| Aqueduct channel flow | Looping flow plus glints of light, per channel piece | PixelLab plus Code |
| Fountain | Splash loop, ripples in the basin | PixelLab |
| Well bucket | Rise and fall | PixelLab |
| River | Shimmering surface loop, sky reflection, foam around rocks | PixelLab plus Code (shader) |
| Watermill wheel | Turning loop with dripping water | PixelLab |
| Sea | Rolling waves, sun sparkles, foam on the shore | PixelLab plus Code (shader) |
| Boats | Bobbing in the harbour | PixelLab |
| Puddles | Form during rain, ripple, dry slowly | PixelLab plus Code |
| Morning dew | Sparkle on leaves at dawn | Code |

### Light and atmosphere

| Animation | Notes | Source |
|---|---|---|
| Wind waves | Visible gusts through lavender and wheat | Code (shader) plus the sway frames |
| Tree sway | Cypresses and olive trees | Code (shader) |
| Cloud shadows | Drift across the fields | Code |
| God rays | Golden hour light shafts | PixelLab plus Code |
| Rainbow (rare) | After rain | PixelLab |
| Shooting star (rare) | Clear nights | Code |

### Particles and effects

| Effect | Notes | Source |
|---|---|---|
| Harvest burst | Leaves, grain or lavender petals flying | Code plus small sprites |
| Coin pop | When selling | PixelLab plus Code |
| Ready sparkle | | PixelLab |
| Water splash and droplets | Watering | Code |
| Rain | Light rain, heavier summer storm | Code |
| Mist | Morning mist band | PixelLab plus Code |
| Falling leaves | Autumn | Code plus sprites |
| Blossom petals | Spring | Code plus sprites |
| Snowflakes | Winter (light) | Code |
| Fireflies | Summer nights | Code |
| Oven smoke | | Code |
| Dust puffs | Cart wheels, dog running | Code |
| Blessing glow | Shrine and blessed crops | Code |
| Lantern light | Night glow around lights | Code |
| Villa upgrade effect | See section 2 | PixelLab plus Code |

---

## 10. User interface

| Asset | Notes | Source |
|---|---|---|
| Slim UI bar | A light bar or floating panels for coins, storage and buttons over the field edge | PixelLab |
| Panels and frames | Parchment and wood styles, 9-slice so they stretch | PixelLab |
| Buttons | Normal, hover, pressed, disabled | PixelLab |
| Tabs | For the journal and shop | PixelLab |
| Tooltips | | PixelLab |
| Progress bars | Growth, processing, cart trip | PixelLab |
| Storage meter | How full the storeroom is | PixelLab |
| Coin counter | | PixelLab |
| Notification toasts | Cart back, storage full, order done | PixelLab |
| Cursors | Normal, harvest (sickle), plant (seed), water (jug) | PixelLab |
| Menu icons | Shop, journal, orders, settings, lands, shrine | about 8 |
| Settings screen | Sliders, toggles, checkboxes | PixelLab |
| The farmer's journal | Book cover, page background, page corner, bookmarks | PixelLab |
| Notice board | Board background, order cards | PixelLab |
| "While you were away" summary panel | | PixelLab |
| Season and weather indicator | 4 seasons, 4 to 5 weather icons | about 9 |
| Time of day indicator | Sun or sundial | PixelLab |
| Title screen | Logo, background scene | PixelLab |
| Logo | "Otium" wordmark | PixelLab plus touch-up |
| Fonts | A readable pixel font, plus a display font with a Roman feel (licensed or free for commercial use) | License |

**Estimate:** about 60 UI pieces, 2 fonts.

---

## 11. Audio

### Music

Idle players listen for hours, so variety matters more than length of any one track.

| Item | Count | Notes | Source |
|---|---|---|---|
| Main theme | 1 | Title screen | License or commission |
| Day tracks | 6 to 8 | Calm, acoustic (lyre, flute, strings), 2 to 4 minutes each | License or commission |
| Night tracks | 2 to 3 | Even softer | License or commission |
| Season or land variations | 3 to 5 | Optional flavour | License or commission |
| Festival tracks | 2 to 3 | Slightly more festive | License or commission |

Music plays with long ambient-only gaps between tracks, so it never becomes repetitive.

**Total target:** 30 to 60 minutes of music.

### Ambience loops

| Loop | Notes |
|---|---|
| Daytime countryside | Birds, breeze |
| Summer cicadas | |
| Night | Crickets, an owl |
| Light rain | |
| Storm | Distant thunder |
| River | River valley land |
| Sea and gulls | Coastal land |
| Mountain wind and goat bells | Mountain pasture land |
| Distant village | Faint voices, a cart, a bell |

**Estimate:** 9 to 10 loops. Source: CC0 libraries or licensed packs.

### Sound effects

Each with 2 to 3 variations or random pitch, so repeats do not sound identical.

| Group | Sounds |
|---|---|
| Farming | Hoe the soil, plant a seed, water, harvest (grain, leafy, fruit), perfect harvest chime |
| Processing | Olive press creak, grape treading squish, mill turning, oven crackle, wine pour, bees buzzing |
| Selling | Cart loading, cart wheels, donkey bray, coins clink, sale complete |
| Villa | Construction (hammering), upgrade complete fanfare (soft) |
| Dog | Bark, happy whine, panting, digging, petting |
| Other animals | Chicken cluck, goat bleat, cat purr, bird chirps |
| Shrine | Offering placed, blessing chime |
| UI | Click, hover, open panel, close panel, tab switch, notification, journal page turn, order complete |
| Weather | Rain start, thunder (soft) |

**Estimate:** about 45 sound effects.

---

## 12. Steam store and marketing

The website has its own asset list in `Website-plan.md`. Check current Steam sizes in the Steamworks documentation before making these.

| Asset | Size (current Steam spec, verify) |
|---|---|
| Header capsule | 920 x 430 |
| Small capsule | 462 x 174 |
| Main capsule | 1232 x 706 |
| Vertical capsule | 748 x 896 |
| Library capsule | 600 x 900 |
| Library hero | 3840 x 1240 |
| Library logo | 1280 x 720 (transparent) |
| Page background | 1438 x 810 |
| Community icon | 184 x 184 |
| App icon (desktop shortcut) | 256 x 256, plus smaller sizes |
| Achievement icons | 64 x 64, one unlocked and one locked version each |
| Screenshots | At least 5, 1920 x 1080 |
| Trailer | 30 to 90 seconds; first 5 seconds show the hook |
| Short clips / GIFs | For TikTok, YouTube Shorts and Reddit (vertical 1080 x 1920 versions too) |
| Press kit | Logo, key art, screenshots, fact sheet |

**Estimate:** about 12 store images, about 30 achievement icons (x2), 5+ screenshots, 1 trailer, a steady stream of clips.

---

## Totals (rough)

| Category | Estimated count |
|---|---|
| Landscape layers and sky pieces | about 50 |
| Villa stages and overlays | about 17 |
| Farm buildings | about 40 sprites, 8 animations |
| Plots and soil | about 8 |
| Lavender (all varieties, stages and sway) | about 45 |
| Other crops (all stages) | about 115 |
| Item icons | about 95 |
| Character and animal frames | about 165, plus 10 portraits |
| Ambient creatures and passers-by | about 190 frames |
| Water and atmosphere animations | about 15 loops, mostly shader-assisted |
| Decorations | about 35, plus icons |
| UI pieces | about 60, plus 2 fonts |
| Music | 30 to 60 minutes |
| Ambience loops | 9 to 10 |
| Sound effects | about 45 |
| Store and marketing | about 20 images, about 60 achievement icons, trailer, clips |

## Suggested order of work

Make assets in the order the game needs them for testing, so art never blocks progress:

1. Palette, base resolution and lighting direction locked in.
2. Home farm landscape layers (the first full PixelLab scene).
3. Lavender (all stages and the wind sway), plots, 2 to 3 more starter crops, the storeroom, the cart and donkey.
4. The dog (idle, walk, sleep), butterflies and bees, the aqueduct channel water.
5. UI basics: slim UI bar, buttons, coin counter, storage meter.
6. Villa stages 1 to 3.
7. Starter sound effects and 2 to 3 ambience loops.
8. Everything else, land by land.
