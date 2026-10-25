# Otium: Game Plan

How the game gets built, in what order, and how we know each step is done. The design itself lives in `Game-mechanics.md`, the art in `Asset-list.md`, the money in `Business-plan.md`, and the competitor research in `reports/Cozy idle game feature comparison.md`.

---

## 1. Decisions already made

| Area | Decision |
|---|---|
| Genre | Cozy semi-idle farming, active or idle, with a desktop strip mode |
| Setting | A Roman countryside estate; lavender is the signature crop |
| Engine | Godot 4, GDScript |
| Platforms | Steam: Windows, Mac (Apple Developer account in place), Linux, Steam Deck |
| Resolution | 480 x 270 base, scaled by whole numbers; extra scene is shown instead of black bars on other screen shapes |
| Art | PixelLab. One cohesive background painting per land, nothing that moves inside it; everything that moves or changes is a separate sprite |
| Buildings | Separate sprites on fixed anchor spots, each stage made from the next with the Edit tool |
| Store | Steam only; no website or own payments unless the game sells very well |
| Marketing | Prototype, footage, Steam page, short clips, wishlist checkpoint, then the full build |
| Price | \$10 to \$15, decided once content size is clear |

---

## 2. What the game must have, and where it stands out

### The floor: every competitor has these

From the competitor research, a cozy idle game missing any of these is judged incomplete:

- [ ] Steam Cloud saves, plus rolling local backups (every competitor added them after players lost saves)
- [ ] 30 to 70 Steam achievements
- [ ] 10+ languages, including Simplified Chinese and Japanese (over 40% of Rusty's Retirement buyers were in Asia)
- [ ] A companion you can pet (the dog)
- [ ] A decorating layer (villa decorations, garden pieces)
- [ ] Calm music with separate music, ambience and effects sliders
- [ ] A collection book (the farmer's journal)
- [ ] A frame-rate cap and a low-power mode
- [ ] Free seasonal content after launch (the Roman festivals make this natural)
- [ ] A cheap supporter pack (about 1 in 10 Rusty's Retirement buyers bought one)

### Where Otium stands out: gaps none of the five competitors fill

| Opening | What we build |
|---|---|
| **Offline progress done well** | Crops grow, bees work and wine ages while the game is closed, up to a clear cap (the storeroom size). A "while you were away" summary shows what happened. Nothing ever wilts or gets sick. |
| **A strip that works everywhere** | Transparent desktop strip with a built-in solid-background option from day one, click-through on empty pixels, taskbar handling, a reset hotkey, and remembered position, size and monitor |
| **Linux and Steam Deck** | Native Linux build; a controller-first full-window mode aimed at Deck Verified |
| **A living calendar** | Day and night, seasons and weather together, with Roman festivals. No competitor combines all three. |
| **Upgrades you can see** | Every upgrade visibly changes the scene: a bigger villa, a new building, more animals |
| **Named helpers** | Rusty's Retirement's strongest idea, in Roman form: a farm manager, a beekeeper, a distiller and a merchant, each unlocking a system |
| **Light on the computer** | Runs at a low frame rate when not in focus and barely touches CPU, GPU or battery |

### Complaints we design against

| Complaint in competitor reviews | Our answer |
|---|---|
| Content runs out after 6 to 20 hours | Five lands, processing chains, villa stages, festivals and a journal; pacing tested so each session reveals something new |
| Upgrades that change nothing | Every upgrade is visible on screen or clearly changes the numbers |
| Punished for being away | No wilting, no sickness, no decay; the only limit is a full storeroom |
| Heavy CPU and battery use | Performance budget (section 5) enforced from the first build |
| Black transparent window bugs | Solid-background mode built in from the start; tested with Steam, Discord and GPU overlays |
| Settings missing or forgotten | Every setting saved; window position remembered; all sliders present at launch |
| Repetitive music | 30 to 60 minutes of music with long quiet gaps of ambience between tracks |
| Gambling-style rewards | No random draws for purchases; rare things come from the dog, orders, festivals and sightings |

---

## 3. Development phases

Each phase lists what gets built, what "done" means, and a rough time estimate. Claude writes all the code and batch-generates the art; your time goes to music, sound effects, testing, feedback and advertising. The build is fast; the calendar is set by wishlists and Steam's fixed dates.

### Phase 0: Setup (a day)

**Build:**
- Install Godot 4 (standard version).
- Create `C:\Users\evand\Desktop\Otium\` with `game\`, `design\` and later `website\`; move these docs and the art tests into `design\`.
- Set up Git and a private GitHub repo, with Git LFS for art and audio.
- Configure Godot for pixel art: 480 x 270 base, whole-number scaling, nearest-neighbour filtering, the "show more scene" stretch setting.
- Save a fresh PixelLab API key as an environment variable (`PIXELLAB_TOKEN`).
- Turn the art test scripts into a reusable art pipeline: generate, download, cut sheets, remove stray pixels, palette remap, name files.

**Done when:** the project opens, an empty scene runs at every target screen size without blurry pixels, and one PixelLab asset can be generated and dropped into the game with a single command.

### Phase 1: Lock the art direction (a few days, about \$5 to \$10 of credits)

**Build:**
- Regenerate the home farm background painting with no buildings, birds or animals, and a flat field edge at the bottom.
- Test splitting it into parallax layers and inpainting the gaps behind them.
- Test one seamless seam.
- Generate the grand villa in the painting's style, then one earlier stage with the Edit tool.
- Regenerate the dog outline-free, with natural proportions, matching the painting.
- Generate the lavender 64-variation sheet with the painting as the style reference.

**Done when:** one screen made from these pieces looks as good as the single painting test, and the approach is chosen: layered parallax, or one painting per land with subtle motion.

**Result (done, about \$0.37 of credits):** the layered approach is chosen. A background painting with nothing in it, plus separately generated sprites that use crops of a painting as their style reference (villa, umbrella pine, lavender, dog), reads as one cohesive scene and supports parallax. Lessons:

- Reroll a background for about 1 cent rather than erase things from it. Inpainting works, but rectangular masks leave straight seams in skies; when it is needed, masks should follow natural edges.
- The Edit tool turns a finished building into its earlier stages with the same footprint, so villa stages line up.
- A Pro Flash style reference must fit inside the output canvas (crop it to size).
- Full inpaint-v3 needs a paid subscription tier; the Pro Flash inpaint works on credits in tiles up to 256 pixels.

### Phase 2: Gray-box core loop (2 to 4 days)

**Build** (with colored boxes, no final art):
- Plots that can be planted, grow through stages over real time, and be harvested by click.
- Storeroom with capacity, the cart trip to sell, and coins.
- Upgrades: more plots, bigger storeroom, faster cart.
- Villa stage 1 to 2 upgrade.
- Saving: autosave every minute, rolling backups, Steam Cloud ready.
- Offline progress with the storeroom cap and the "while you were away" summary.
- All game data (crops, prices, upgrades, times) in data files, so balancing never needs code changes.
- A debug panel to speed up time for testing.

**Done when** the pacing targets hold in a real play session:

| Moment | Target |
|---|---|
| First harvest | Under 1 minute |
| First cart sale | Under 3 minutes |
| First villa upgrade | About 30 minutes |

### Phase 3: Home farm vertical slice (1 to 2 weeks)

The first version that looks like the real game. Everything in it should be good enough to film.

**Build:**
- The home farm background and its layers, with subtle parallax.
- Lavender (all stages and varieties), wheat, plots, storeroom, cart and donkey.
- The dog: wandering, walking, sitting, sleeping, being petted.
- Butterflies, bees, birds and clouds as animated sprites.
- Day and night lighting, soft shadows that follow the sun, and one shared color grade over the whole screen.
- Juice: harvest particles, coin pops, gentle sounds, the "ready" cue on plots.
- The villa upgrade moment: scaffolding, dust puff, chime, the new stage.
- Placeholder music and ambience (cicadas, breeze).

**Done when:** a 30-second recording of normal play is something you would post. That clip is the input for Phase 5.

### Phase 4: Idle strip and platform hardening (about a week, alongside Phase 3)

**Build:**
- Idle strip mode: borderless, always on top, docked bottom, top or side, adjustable height.
- Transparency with click-through on empty pixels, and a solid-background option (a painted sky band) as a first-class choice.
- Taskbar detection, a reset-position hotkey, remembered position, size and monitor.
- Focus mode: smaller, quieter, slower.
- Low-power behaviour: 30 fps or less when unfocused, nothing redrawn when nothing changes.
- Controller support for the full-window mode.

**Test matrix** (the strip must pass on each):

| System | Checks |
|---|---|
| Windows 10 and 11 | Transparency, always on top, click-through, taskbar at bottom and side, high-DPI scaling |
| macOS (Apple Silicon) | Same, plus full-screen apps and multiple desktops |
| Linux X11 | Same |
| Linux Wayland | Expect limits on always-on-top and positioning; the solid mode must still work |
| Steam Deck | Full-window mode only, controller, readable text, battery use |
| With overlays | Steam overlay, Discord, NVIDIA and AMD overlays running |

**Done when:** the strip runs for a full workday on Windows and Mac without a black background, stuck window or noticeable battery drain, and every other platform at least runs cleanly in solid mode.

### Phase 5: Steam page and clips (starts as soon as Phase 3 is filmable)

**Build:**
- Capture footage with Godot's movie mode (smooth, full quality).
- A 30 to 60 second trailer; the first 5 seconds show lavender, the villa and the dog.
- Steam capsule images; the single-painting style test is a strong starting point for the main capsule.
- At least 5 in-game screenshots.
- Store description, tags (Cozy, Idler, Farming Sim, Relaxing, Pixel Graphics, Simulation, Casual), and the "Coming soon" page.
- Accounts on TikTok, YouTube Shorts and Reddit; Discord server.

**Clip ideas** (aim for 3 to 5 a week):
- Wind rolling through the lavender at golden hour.
- The villa upgrading from ruin to the next stage.
- The game running as a strip at the bottom of a real work desktop.
- Petting the dog.
- A full day passing in 15 seconds.
- A rare sighting: the fox, the hoopoe, a shooting star.
- Before and after: day 1 versus day 30 of the estate.

**Checkpoint after 3 months of clips:**

| Wishlists | Decision |
|---|---|
| Under 1,000 | Change the hook or the art, or stop |
| 1,000 to 7,000 | Keep going, keep posting |
| On track for 7,000 to 10,000+ by launch | Full build |

### Phase 6: Full game build (6 to 10 weeks, alongside the clips)

**Systems:**
- Processing chains: drying racks, olive press, unguent workshop, wine press and cellar, mill and oven, beehives, dairy, garum works.
- Orders on the market notice board.
- Named helpers who unlock systems, and farmhands who automate tasks.
- All seven villa stages, plus the other buildings and their levels.
- The lararium and blessings.
- Seasons, weather and the five Roman festivals.
- The farmer's journal, rare sightings, dog finds.
- Decorations.
- Achievements, Steam Cloud, Steam Deck checks.
- Localization: every string in translation files; a pixel font with Chinese and Japanese coverage.

**Content:**
- The other four lands: vineyard slopes, river valley, mountain pasture, coastal estate. Each needs its background painting, crops, buildings, animals and ambience.
- All crops, items, animals and creatures in the asset list.
- Final music (30 to 60 minutes) and the full sound effect list.

**Done when:** a new player can go from the ruined farmhouse to the grand estate across all five lands, every pacing target holds, and nothing in the asset list is still a placeholder.

### Phase 7: Demo and Steam Next Fest

**Build:**
- A free demo: the home farm up to villa stage 2 or 3, with progress that carries into the full game.
- Release the demo a few months before Next Fest; games that did this got about 2.5 times the median wishlists from the festival.
- Enter the next Next Fest.
- Email keys to small and mid-sized cozy and idle game creators.

**Done when:** the demo is live and Next Fest is booked.

### Phase 8: Polish and launch (2 to 4 weeks)

**Build:**
- Playtest with 10 to 20 outside players; fix confusion points and pacing.
- Short in-game tutorial (a complaint against Rusty's Retirement was the lack of one).
- Accessibility: text size, colorblind-friendly ready cues, reduced motion, remappable keys.
- Performance pass on low-end laptops and the Deck.
- Final price, launch discount, supporter pack, press kit (a Google Drive folder is enough).
- Steam Deck Verified submission.

**Done when:** launch day is set, wishlisters are emailed by Steam, and creators have keys.

---

## 4. Rough timeline

Claude writes the code and generates the art, so the build itself is fast. The calendar is set by three things that do not speed up:

- **Wishlists:** clips need weeks to build an audience, and a launch with few wishlists wastes the one launch a game gets.
- **Steam's rules:** a new developer account has a waiting period after paying the fee before the first release, and the "Coming soon" page must be live at least two weeks before launch.
- **Next Fest:** it runs three times a year (February, June, October), and the demo should be out a few months before it.

| Phase | Duration | Running total |
|---|---|---|
| 0. Setup | A day | Week 1 |
| 1. Art direction | A few days | Week 1 |
| 2. Gray-box loop | 2 to 4 days | Week 2 |
| 3. Vertical slice | 1 to 2 weeks | Week 3 to 4 |
| 4. Idle strip and platforms | About a week, overlapping | Week 4 |
| 5. Steam page and clips | Page up around week 4, clips ongoing from then | |
| 6. Full build | 6 to 10 weeks, alongside the clips | Month 2 to 3 |
| 7. Demo | Out as soon as the full build is stable | Month 3 |
| Checkpoint | About 3 months of clips | Month 4 |
| Next Fest | The next festival after the demo has been out for a while | Month 4 to 5 |
| 8. Polish and launch | 2 to 4 weeks, ending at launch | Month 5 to 6 |

**Your time** goes to: choosing and licensing music, downloading sound effects, testing every build and saying exactly what to change, and posting 3 to 5 clips a week. Testing and feedback are the real limit on how fast the build goes.

---

## 5. Technical architecture

### Core pieces

| Piece | Job |
|---|---|
| Game state | Coins, inventory, plots, buildings, villa stage, helpers, journal; one place everything reads from |
| Time service | Real time, in-game day and season, and the offline catch-up |
| Simulation | Growth, harvesting, processing and cart trips, all driven by time so the same code handles live and offline play |
| Save service | Saves every minute and on exit, keeps rolling backups, syncs with Steam Cloud |
| Data files | Every crop, item, building, upgrade, price and timing |
| Window manager | Full window, idle strip, focus mode, transparency, click-through, position memory |
| Audio manager | Music with quiet gaps, ambience that follows the time, weather and land, effects |
| Steam layer | Achievements, cloud, overlay, Deck detection |

### Offline progress

- On close, the game saves the exact time.
- On open, it simulates the time away in steps (for example 10 minutes at a time), so crops grow, helpers harvest, processors run and the storeroom fills exactly as if the game had been open.
- It stops when the storeroom is full, which is the cap players understand.
- The "while you were away" summary lists what was grown, processed and earned.
- A setting turns offline progress off for players who prefer that.

### Performance budget

| Situation | Target |
|---|---|
| Full window, active | 60 fps, low CPU |
| Idle strip, unfocused | 30 fps or less |
| Nothing changing on screen | Close to idle CPU |
| Steam Deck | Several hours of battery |

---

## 6. Art production

- **Order:** home farm first (it is the demo and the trailer), then one land at a time.
- **Per land:** a background painting, its layers or animated elements, crops, buildings and their stages, animals and creatures, ambience.
- **Consistency:** the same palette, style reference and prompt ending for everything; nothing that moves inside a background.
- **Budget:** at the per-call prices seen so far, the full asset list is likely tens of dollars in PixelLab credits, not hundreds, including retries.
- **Touch-ups:** a pixel editor (Aseprite or Pixelorama) for stray pixels and loop fixes.

## 7. Audio production

- **Music:** 30 to 60 minutes, acoustic and calm (lyre, flute, strings), licensed or commissioned; long ambience-only gaps between tracks.
- **Ambience:** loops per land and time of day (cicadas, breeze, river, sea, night crickets, distant village).
- **Effects:** about 45, each with slight random pitch so repeats never sound identical.
- **Soundtrack:** a cheap soundtrack add-on later; competitors sell one.

---

## 8. Risks

| Risk | Plan |
|---|---|
| Separate art pieces look less unified than one painting | Phase 1 tests it; fallback is one painting per land with subtle motion |
| Transparent strip bugs on some systems | Solid-background mode built in from the start; test matrix in Phase 4 |
| Polish on a first game | Vertical slice must be clip-worthy before the full build starts |
| Content runs out too fast | Pacing targets tested every phase; five lands and processing chains |
| Not enough wishlists | Checkpoint decides early, before the expensive part |
| Time competing with Argo Books | Small, clear phases with a "done when" for each |
| Animations of farmhands using tools look poor | Test early in Phase 3; keep helpers simple or show results rather than motion |

---

## 9. Open decisions

- Price (\$10 to \$15).
- Length of the in-game day and season.
- Whether to add a legacy (prestige) system.
- How much story: a light "inherited the ruined farm" framing, or none.
- Whether townspeople appear on screen or only through orders.
- Final name and trademark check for "Otium".
- Layered parallax or one painting per land (settled in Phase 1).
