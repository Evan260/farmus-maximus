# Rusty's Retirement (Mister Morris Games / Jordan Morris, Steam app 2666510): complete feature research

Research date: 2026-10-24. Newest developer post on Steam is Build 1.1.6 (6 Oct 2025). The Steam News API returned no announcements dated after that, so as far as I can tell no content has shipped from Oct 2025 to Oct 2026. Main sources: the Steam store page, the full Steam announcement feed (via the Steam News API, which mirrors every developer post), Wikipedia, GameDiscoverCo, AUTOMATON (JP), Siliconera, a Japanese achievement guide, Vaporlens (an aggregator that summarizes Steam reviews), and Steam community threads. The Fandom wiki (rustys-retirement.fandom.com) returned HTTP 402 and could not be read.

Main links:
- Steam store: https://store.steampowered.com/app/2666510/Rustys_Retirement/
- Steam news feed (API): https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements
- Wikipedia: https://en.wikipedia.org/wiki/Rusty%27s_Retirement
- GameDiscoverCo (28 Aug 2024): https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed

## 1. Core loop: what the player does moment to moment

### Takeaway
The player plants crops on a thin farm strip. Rusty (a retired robot) and helper robots water and harvest them. Harvested crops go into biofuel converters, and biofuel becomes "spare parts" (the money). Spare parts pay for more land, buildings, robots, upgrades and decorations. The design boils the player's input down to two actions, planting seeds and placing automation, and the early game is manual until robots take over.

### Cited Findings
- Store description: "An idle-farming simulator that sits at the bottom of your screen while you do other things." Plant crops and unlock new ones "from crispy carrots to ripe tomatoes"; crops produce biofuel, which you sell to other machine inhabitants to reinvest in the farm; deploy and upgrade helper robots that plant, water and harvest. — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/)
- Crops convert to biofuel, then to spare parts, which build structures or decorations. — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement), citing [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Player input is mostly ordering Rusty to plant or clear crops. Rusty and the workers handle sales and farm management. — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement), citing [Gamereactor](https://www.gamereactor.eu/rustys-retirement-1381053/)
- Morris says core actions were simplified to two, "planting seeds and placing automation," to serve both casual farming fans and min/max idler fans. — [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed); also [AUTOMATON](https://automaton-media.com/articles/newsjp/rustys-retirement-20240828-308175/)
- Morris designed planting and building to take only seconds, so players return quickly to their main work. Rusty acts automatically, and players set task priorities for building and harvesting. — [AUTOMATON interview, 5 Feb 2024](https://automaton-media.com/articles/interviewsjp/20240205-281336/)
- Starting crops are wheat, radishes and cabbage; more unlock as you harvest. Giant crops sometimes spawn and are clicked repeatedly for multiples of that vegetable. Rusty's home and the main storehouse can be "spun" (a cog) to generate spare parts. — [Siliconera review](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- There is a "spin the cog" achievement ("This is nice!", 88.1% of players). — [Steam global achievements](https://steamcommunity.com/stats/2666510/achievements)
- Launch features (26 Apr 2024): random giant crops harvested by clicking; buildings can be moved (they turn into boxes Rusty carries); Splunk the seed planter; priority list for helper bots; fertilizer-producing animals; beekeeping; unlockable maps; farm statistics. — [Steam news, "Rusty's Retirement is OUT NOW!"](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Giant golden pumpkins take 36 clicks to pop (Build 1.0.15, Jun 2024). Pre-launch, giant crops were "permanently on your farm unless you pop them by clicking on them 10 times." — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements); [developer TikTok](https://www.tiktok.com/@mister.morris.games/video/7355169234638392608)
- The early game needs manual harvesting, so idle play is not possible at first. — [soysoy55 JP achievement guide](https://soysoy55.com/rustysretirement-achievement)
- Twitch integration: viewers direct robots with chat commands !plant, !water, !harvest. — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/); GameDiscoverCo says Twitch viewers "could spawn on the farm to help out." — [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed)

### Inferences
- The moment-to-moment experience is "glance, click a few things, go back to work": plant, place or upgrade a bot, buy land or a decoration, occasionally pop a giant crop or spin the cog. The click targets (giant crops, cog) act as optional "active play" rewards on top of the idle base.

### Gaps
- Exact conversion ratios (crop to biofuel to spare parts) and per-crop yields: not found.

## 2. Progression and upgrades: robots, buildings, crops, maps, automation

### Takeaway
Progression is driven by building homes for named robot "friends," each of which unlocks a system: Haiku (construction helper), Echo (bot upgrades), Splunk (auto-seeding), Pinion (statistics), Forbic (bees/butterflies), Slate (animals/fossils), Sonnet (decoration shop), and later Reaper (crop-modifying "chips"). There are also several tiers of generic task bots, and you buy land tiles to expand the strip. There are five base maps, unlocked in sequence by fully expanding the previous one, plus four maps added after launch. Each map is its own save.

### Cited Findings
**Named characters and buildings**
- Rusty: the main robot, who grows vegetables, converts them to biofuel and earns spare parts to build homes for friends. Haiku: from the developer's previous game (Haiku, the Robot); helps build homes, plots and machines. Pinion: a "gentlemanly robot" who shows farm statistics. A beekeeping friend unlocks beekeeping for extra biofuel; a farm-animal friend provides fertilizer; a repair robot upgrades helpers. — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Achievement names confirm the building/character roster: Haiku's house, Sonnet's shop, Echo's workshop, Forbic's house ("Bulbs and Butterflies"), Pinion's house ("Counting Crops"), Slate's Biodynamic Barn, Splunk's house ("Planting Seeds"). "Automatization" = one of each robot on a single farm (45.0% unlock). — [Steam global achievements](https://steamcommunity.com/stats/2666510/achievements)
- Echo's workshop upgrades robots and is recommended early. Slate's Barn provides fossils, which buy animals. Splunk auto-plants seeds; its signs can be placed on plots. Forbic pairs with beehives and butterfly houses. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)
- Splunk got a "Do not seed" sign (QoL update, 14 Jun 2024). Auto-planters only plant the last 8 unlocked crops unless the plots have signs (player report, 30 Apr 2024). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements); [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4357871935586416241)
- Reaper's Outpost (Winter update, 10 Dec 2024): travelling Reapers sell crop "chips" that modify crops, with rerolls. — [Steam news, Winter update](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Workers have different abilities, e.g. building, showing production statistics, upgrading other robots. — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement)

**Generic task bots** (from bot stations)
- Water bot, harvest bot, biofuel bot (carries crops to converters), feeder bot (feeds animals), waste bot (collects manure), fertilizer bot, berry bot. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)
- Bot stations can be disabled, and bot biofuel use drops after upgrades (14 Jun 2024). Bots consume biofuel, and on Snowy Fields they use more. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- There are "maxed-bot" achievements (fixed in Build 1.0.3). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

**Currencies and resources**
- Biofuel and spare parts (spare parts also expand farms), fossils (from Slate, buy animals), fertilizer (from animals and the fertilizer facility). — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)
- Other buildings: central building (storage and well), storage, wells, feeding area, fertilizer facility, chicken coop (limited range), dog/cat house, butterfly house, beehives, biofuel processing units. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)

**Animals**
- Pigs and cows (cost fossils), chickens, cats and dogs. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)
- Winter update: cats and dogs with pet houses follow Rusty and help harvest; chickens remove pests for +1 harvest; deer roam Snowy Fields and Blossom Forest. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

**Crops**
- Achievements exist for unlocking 1, 10 and 25 crops ("Horticulturist", 49.0%), and for growing giant tomatoes, pumpkins and cucumbers. — [Steam global achievements](https://steamcommunity.com/stats/2666510/achievements); [soysoy55](https://soysoy55.com/rustysretirement-achievement)
- Winter update added 8 new crops and 3 new giant crops. The Autumn update (1 Oct 2025) added 10 berry bushes. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

**Maps (each is a separate save file)**
- Base maps: Plains (start, most efficient), then Flower Swamp, then Desert, then Blossom Forest and Desert Oasis. Fully expanding one map unlocks the next. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)
- New terrains (swamp, desert, forest) each have their own crop-production modifiers. "Each farm has its own enhancements and restrictions." — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement); [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Added after launch: Snowy Fields (Dec 2024; bots use more biofuel); "Poe's Retirement" Vampire Survivors crossover (1 Apr 2025; garlic damages crop-stealing bats, which drop gems; can be toggled off; needs a new save); "Jimbo's Retirement" Balatro crossover (7 Aug 2025; harvests spawn poker cards played for spare parts with joker effects; needs a new save); Autumn map (1 Oct 2025; mushrooms spawn on unused tiles and harvest bots collect them for biofuel). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

**Pacing**
- About 150 to 200 hours to complete all achievements, including idle time. Focus mode doubles production time. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)
- The first full map yields "around 25-35k harvest" (player). The harvest achievement was lowered from 1 million to 250,000 in Build 1.0.9 after complaints. — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4357871935586416241); [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Player-reported playtime ranges from 10 to 200 hours. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md)
- "Expanding too fast can cause crops to die": upgrade bot stations before expanding. — [soysoy55 guide](https://soysoy55.com/rustysretirement-achievement)

### Inferences
- The "unlock a named friend, who unlocks a system" structure is the main pacing device and gives each step personality. It maps well onto Roman roles (e.g. a vilicus, a beekeeper, a distiller).
- Robot range limits and crops dying when coverage is short mean layout matters. That light optimization layer is what keeps min-maxers engaged.

### Gaps
- Exact total crop count (base game appears to be 25 or more, plus 8 in Winter; not confirmed), the full crop list, map modifier values and robot upgrade tier counts: not found (the Fandom wiki was inaccessible).
- Whether currency carries between maps: Vaporlens says progress and currency do not carry over to new farms; achievement counters are cumulative "across all farms."

## 3. Idle mechanics and offline progress

### Takeaway
There is no offline progress. The farm only advances while the game is running. This is one of the most-cited complaints, and no patch note through Oct 2025 adds it.

### Cited Findings
- April 2024 players: "if offline progress was a thing, it would be okay but right now none of these things exist"; "I think offline progression is the only way to get around the crazy amount of hours." — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4357871935586416241)
- A May 2024 Steam review (on version 1.0.9) states the game does not support offline progression. — [Steam review by ItsMikul](https://steamcommunity.com/id/ItsMikul/recommended/2666510) (as summarized in search results; not fetched directly)
- AUTOMATON's pre-launch interview describes leaving the game running for about an hour and checking back, with no mention of offline gains. — [AUTOMATON interview](https://automaton-media.com/articles/interviewsjp/20240205-281336/)
- Autosave: added in demo 0.2.9 every 15 minutes; every minute from Build 1.0.13 (15 May 2024). Automatic `.bac` backup saves added in 1.0.4 after antivirus software wiped saves. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- The game can be paused with the spacebar; clicking the pause icon unpauses (1.0.19). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Only one farm runs at a time; players asked to run multiple farms at once. — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4357871935586416241)

### Inferences
- Because it runs only while open, players leave it on for hundreds of hours. That inflates playtime but also produces the CPU/GPU complaints. Offline catch-up (even capped) is a clear chance to do better.

### Gaps
- No official developer statement on why offline progress was left out.

## 4. Window and display modes

### Takeaway
By default the game runs as a borderless, transparent strip along the bottom of the screen above the taskbar. A vertical "side" mode is also available (left or right). Zoom, Focus Mode, an always-on-top toggle, three transparency rendering modes (Colorkey / Alpha / Green screen) and resolution-reset hotkeys exist. Click-through, monitor-selection and full-screen options were not found.

### Cited Findings
- Bottom-of-screen is the default; "Vertical mode: create a farm that sits at the side of the screen"; zoom in or out "for a less distracting view"; Focus Mode slows crop production. — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/)
- The interface is a narrow horizontal bar overlaid on the desktop. — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement)
- Works with any display size; larger monitors show more of the farm. Zoom in and out. Before launch a vertical mode was "under consideration" and full-screen "may be added"; a "Pomodoro Mode" with short timed breaks was planned. — [AUTOMATON interview, Feb 2024](https://automaton-media.com/articles/interviewsjp/20240205-281336/)
- Vertical farm mode shipped at launch with separate save files that sync to Steam Cloud. Information panels shift when the vertical farm is on the left (1.0.7), so both sides are supported. Trackpad scrolling on vertical farms was fixed in 1.0.15. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- "Always on top" option: fixed on Mac (0.2.9); it was inverted on Windows and fixed in 0.2.10. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements). Players report Firefox sometimes ignores the setting. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md)
- Transparency: a Settings dropdown (14 Jun 2024) offers Colorkey, Alpha ("faster, poor with overlays") and Green screen (for streamers). A "windowed mode" was planned. Build 1.0.13 opened a performance beta that keeps transparent pixels transparent instead of using a color key; known issue: overlays make the game translucent. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- The default Colorkey mode causes frame-rate problems, and players recommend switching to Alpha. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md)
- The R and T keys reset the resolution (1.0.6). On restart the game detects the monitor resolution automatically (1.0.9). A very tall taskbar launched the game off-screen until 1.0.19, which suggests the strip is positioned relative to the taskbar or work area. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Camera: middle-mouse drag (1.0.6), arrow keys and trackpad scrolling (14 Jun 2024), fixed zoom increments (1.0.15). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Hover window shows crop growth times, adjusted for focus mode (1.0.12). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Multi-monitor: a player reports lag when the game sits on a monitor adjacent to the main one (May 2024). Another suggests "Low Power Mode and change it to 30FPS," which implies an in-game low-power or FPS-cap setting. — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4355620764344185883). The developer noted high-resolution and high-refresh monitors use lots of resources, and that lowering frame rate and "on-demand rendering" helped (1.0.6). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Seeing the whole farm needs zooming out, and the game is "nearly unplayable" when zoomed out. — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Black screen on Windows (transparent background rendered black) was widespread at launch. It was fixed by a script that disables fullscreen optimizations (1.0.11) and by asking players to install .NET 4.7.2. A black background also appears on Mac on first launch. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements); [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)

### Inferences
- The transparency and black-screen saga is the biggest technical lesson. Transparent always-on-top Unity windows were fragile across Windows versions, GPU overlays, Mac and Linux. The user's Avalonia stack should test layered or transparent windows early on multiple GPUs and with Discord/NVIDIA overlays.
- Taskbar-height handling and resolution reset hotkeys are must-haves for a bottom-strip game.

### Gaps
- Click-through (mouse passing through transparent pixels): not documented anywhere I found.
- Monitor selection option, adjustable strip height/size, opacity slider, full-screen mode, whether "windowed mode" ever shipped, whether the Pomodoro mode shipped: not found.

## 5. Collection, unlockables, decorations, cosmetics, pets, characters

### Takeaway
Decorations bought from Sonnet's shop are the main cosmetic sink, with seasonal sets (Christmas, Halloween). Cats, dogs, chickens, deer, bees, butterflies and birds add life. The only paid cosmetic is the Supporter Pack (a golden, sparkling Rusty skin). Pinion's statistics tab acts as a light codex.

### Cited Findings
- Decorations can be bought; benches let characters rest. — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Decoration achievements: place one decoration (92.7%), 25 on one farm (51.7%), and 100 decorations. — [Steam achievements](https://steamcommunity.com/stats/2666510/achievements); [soysoy55](https://soysoy55.com/rustysretirement-achievement)
- Week 1: players spent about 21.5 billion on decorations. — [Steam news, Week 1 recap](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Christmas decorations; Rusty wears a Christmas hat in December (Winter update). Sonnet sells Halloween decorations; pumpkins become Jack-o'-lanterns in October; Rusty wears a ghost costume on Halloween; spooky decorations appear on Rusty's House in October (1.1.6). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- The starting computer became a demolishable decoration (1.0.12). Buildings, bushes and decorations can be moved one tile (14 Jun 2024). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Supporter Pack DLC: golden, sparkling Rusty skin, CDN\$4.99 (about US\$4). It sold 36,000 units (about 11% attach rate) for \$111k by Aug 2024. — [Steam news, launch](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements); [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/); [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed)
- Pinion's statistics cover crops, berry bushes (1.0.12), chickens, cats and dogs (1.0.18). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Slate digs fossils, which buy animals; the fossil cap was raised in the Winter update. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Pre-launch decoration competition on social media (Feb 2024). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Steam Trading Cards (8 standard and 8 foil), badges, emoticons, backgrounds, animated avatars and frames (31 Jan 2025). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

### Inferences
- A cheap cosmetic "supporter" DLC sold to about 11% of buyers, a useful benchmark for a lavender game.

### Gaps
- Decoration count and a full decoration list: not found. No formal codex or collection book found beyond statistics.

## 6. Ambient life, animations, day/night, weather, seasons

### Takeaway
There is plenty of small ambient motion: bees, butterflies, birds, falling leaves, chimney smoke, idle animations, characters chatting, pets following Rusty, deer. Seasonal flavour comes from real-calendar events (December, October) and seasonal maps (Snowy Fields, Autumn). I found no evidence of a day/night cycle or dynamic weather.

### Cited Findings
- Ambient details: floating robots, falling leaves, idle animations, chimney smoke, beehives, bees and butterflies. — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Winter update: characters chat with each other; Pinion's Goldcrests (birds) fly around the farm; deer on Snowy Fields and Blossom Forest; cats and dogs follow Rusty. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Bee and butterfly rework: bees spread across hives and migrate to new ones; berry bushes have a bee cap (Jun 2024), raised from 2 to 3 per bush in Oct 2025. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Real-calendar events: Christmas hat in December; Halloween decorations, Jack-o'-lanterns and a ghost costume in October. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Animals eat less and roam more (1.0.10). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

### Inferences
- Seasons are tied to the real calendar and to separate maps, not to an in-game season cycle.

### Gaps
- Day/night cycle and weather (rain etc.): not found in any source. Treat as likely absent but unconfirmed.

## 7. Audio

### Takeaway
"Chill, ambient" music, with the soundtrack released officially on YouTube and Bandcamp. A recurring complaint is that the playlist is short and repetitive over long sessions.

### Cited Findings
- "Chill, ambient music." — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- Official soundtrack released on YouTube and Bandcamp (Week 1 recap, 4 May 2024). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Players praise the "soothing music," but there is also a "Repetitive soundtrack" complaint: limited music becomes monotonous. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md)

### Gaps
- Volume sliders (music/SFX split), ambience tracks, track count and composer: not found.

## 8. Achievements, Steam features, platforms

### Takeaway
71 achievements, with Steam Cloud, Trading Cards and Family Sharing. Windows and macOS only: no native Linux, and no Steam Deck or controller support listed. The game is in 11 languages, built in Unity, and needs very little hardware.

### Cited Findings
- 71 achievements (8 rare). Examples: Play for 1hr (83.8%), Play for 24hrs (43.5%), Automatization (45.0%), Horticulturist (49.0%). — [Steam global achievements](https://steamcommunity.com/stats/2666510/achievements)
- The Winter update added new achievements; the Autumn update added none, and the developer planned two in a "larger future update" (not delivered as of the latest post, 6 Oct 2025). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Steam features: Single-player, Steam Cloud, Family Sharing, Achievements, Trading Cards. Steam Deck and controller support not listed. Windows 10 and macOS 10.9+ only; 4 GB RAM; 256 MB storage. — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/)
- 11 languages: English, French, Italian, German, Spanish (Spain), Japanese, Korean, Portuguese (Brazil), Simplified Chinese, Traditional Chinese, Estonian (Estonian added in 1.0.15). — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/); [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Built in Unity (Unity 2022 LTS upgrade attempted in 1.0.8, then reverted). — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement); [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Linux: no native support. Proton users report a black background instead of transparency; Hyprland users need window rules. — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4355620586423976485); [ProtonDB](https://www.protondb.com/app/2666510)
- Players report resolution problems on Steam Deck. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md). TouchArcade covered it in its "Steam Deck Weekly" column (4/5). — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement)
- Morris has Switch and touch porting experience but said PC is the best fit; multiplayer not planned. — [AUTOMATON interview](https://automaton-media.com/articles/interviewsjp/20240205-281336/)

### Gaps
- Official Steam Deck compatibility rating (Verified/Playable/Unsupported/Unknown): not found. Controller support: not found (assumed none).

## 9. Settings and quality-of-life options

### Takeaway
Settings documented in patch notes: always on top, transparency mode (Colorkey/Alpha/Green screen), auto-save, Focus Mode, game pace, apparently a low-power/FPS option, Twitch connection, save management (Clear Save, backups), an in-game feedback form and Help section. QoL includes the bot priority list, moving buildings, notification dots and inspect info.

### Cited Findings
- In-game feedback form in Settings (demo). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Auto-save toggle ("unless disabled"), Save button, Clear Save (demo builds 0.2.9 and 0.2.10). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Players can adjust game pace in settings; Focus Mode slows production. — [AUTOMATON interview](https://automaton-media.com/articles/interviewsjp/20240205-281336/)
- QoL update (14 Jun 2024): move items one tile; move animals between feeder slots; destroy empty feeders; disable bot stations; Inspect shows remaining waterings and harvests; notification icons on tabs; new remove-crops icon. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Chip overwrite confirmation, crop info on chip hover, and visual feedback for insufficient biofuel, spare parts or fossils (1.0.18). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Right-click and middle-click no longer upgrade, demolish or move buildings, which prevents accidents (1.0.12). — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- There is a Help section. — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)
- The Vampire Survivors map's bat mechanic can be toggled off for a casual experience. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

### Gaps
- A full settings menu listing (audio, UI scale, monitor choice, FPS cap labels): not found from an authoritative source.

## 10. Price, DLC, post-launch update timeline

### Takeaway
The game costs US\$6.99 ("\$7"; CDN\$8.99; 750 yen). The only DLC is the cosmetic Supporter Pack. About six content updates came in the first 18 months (QoL, Winter, Trading Cards, Vampire Survivors, Balatro, Autumn), and no developer posts have appeared since Oct 2025.

### Cited Findings
- Price \$7, chosen between the typical idler (\$0 to \$5) and farming sim (\$10 to \$15) price ranges: "more content than a regular idler, but not enough to be a fully fledged farming sim." — [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed); 750 yen — [AUTOMATON](https://automaton-media.com/articles/newsjp/rustys-retirement-20240828-308175/); CDN\$8.99 — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/)
- Bundles: Supporter Pack bundle, a "Winmon" bundle, and a 17-item "Bottom-Of-Your-Screen" bundle; cross-bundles with My Little Life (20% off) and Balatro (10% off). — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/); [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Timeline (all from the [Steam news feed](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)):
  - 27 Nov 2023: Steam page and announcement.
  - 2 Feb 2024: public demo for Next Fest (PC and Mac). Top demo feedback: moving houses, worker priorities, vertical farms. Release delayed to Q2.
  - 26 Apr 2024: launch, with 1.0.3 to 1.0.13 fixes through 15 May (saves, black screen, performance, achievement rebalance).
  - 14 Jun 2024: Quality of Life update; 16 Jun: 1.0.15 (zoom fixes, Estonian).
  - 10 Dec 2024: Winter update (Snowy Fields map, Reaper chips, cats/dogs/chickens/deer, 8 crops, 3 giant crops, chatter, goldcrests, new achievements); 1.0.17 and 1.0.18 fixes.
  - 31 Jan 2025: Steam Trading Cards. 4 Feb 2025: 1.0.19.
  - 1 Apr 2025: Vampire Survivors crossover map "Poe's Retirement" (1.1.x).
  - 7 Aug 2025: Balatro crossover map "Jimbo's Retirement."
  - 1 Oct 2025: Autumn mini-update (autumn map, mushrooms, 10 berry bushes, Halloween). 6 Oct 2025: Build 1.1.6 (latest post found).
- The developer said in Oct 2025 that "more mechanics are planned for a bigger update." — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)

### Gaps
- Whether the promised "bigger update" shipped in 2026: no Steam announcement found through 24 Oct 2026.

## 11. Reviews: score, praise, complaints

### Takeaway
Steam: Overwhelmingly Positive (97% of 6,616 English reviews; recent 96% of 64). Metacritic: 81. Players praise how relaxing it is, its fit for working or studying, satisfying automation, and the charming robots. They complain it is repetitive and shallow at endgame, not truly idle early, has no tutorial, resets progress on new maps, uses too much CPU/GPU, has limited robot range or poor robot AI, and has short music.

### Cited Findings
- Steam: Overwhelmingly Positive, 97% of 6,616 English reviews; recent 96% of 64 (fetched 24 Oct 2026). — [Steam store](https://store.steampowered.com/app/2666510/Rustys_Retirement/). In Aug 2024 it was 96% of 7,300 (all languages). — [AUTOMATON](https://automaton-media.com/articles/newsjp/rustys-retirement-20240828-308175/). The developer cited 96% positive in Nov 2024. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements)
- Metacritic 81 ("generally favorable"); TouchArcade 4/5; Gamereactor 8/10; Siliconera 8/10. GamesRadar called it a "genre renaissance" for idle games. — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement)
- Praise (from the Vaporlens review summary): cozy atmosphere compared to a "zen garden or a warm blanket"; a "desktop toy" for work or study; satisfying automation; cute robots; good value with no microtransactions; light on low-end PCs; good for ADHD; subtle storytelling about aging. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md)
- Complaints (Vaporlens): repetitive and lacking depth; "Not truly an 'idle' game" early on; no tutorial; progress resets on new farms; "high CPU and GPU usage" even in the background (heat, fans); limited robot range and erratic AI; too distracting; black screens, no Linux, Steam Deck resolution problems; no refunds when demolishing and no placement grid; buildings cannot rotate; repetitive soundtrack; grindy fossil-gated animal achievements. — [Vaporlens](https://vaporlens.app/app/2666510/rustys_retirement.md)
- Achievement grind quotes: "if you do everything else in 200 hours and have to wait 800 hours just for the last one"; "The time needed to get 1 million harvests is insane and very unbalanced!"; a defender: "This is an idle game; it is intended to have long-term goals." — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4357871935586416241)
- Performance quote: "When the game is running it causes lag... Nothing in the game settings affects it." — [Steam discussion](https://steamcommunity.com/app/2666510/discussions/0/4355620764344185883)
- Siliconera: full farm only visible zoomed out, where it is "nearly unplayable"; got bored after unlocking everything. — [Siliconera](https://www.siliconera.com/review-rustys-retirement-offers-a-calming-and-simplistic-respite/)

### Gaps
- Direct verbatim quotes from individual Steam reviews could not be fetched (the review JSON endpoint redirected). The Vaporlens quotes are aggregated snippets.

## 12. Sales and how it went viral

### Takeaway
It sold 100k copies in 5 days, 200k by about 14 May 2024, about 330k by late Aug 2024, and 550k by July 2025. It launched with about 140k wishlists, built mostly from short videos on X/Twitter and Instagram Reels (cross-posted to TikTok) showing the "farm at the bottom of your desktop" concept. Streamers (including Pirate Software) amplified it. The game is credited with spawning the "bottom-of-screen" genre and Steam's 2025 Idler Fest.

### Cited Findings
- More than 100,000 copies in five days and 200,000 within two weeks. — [Steam news, Week 1 recap](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements); 200k announced 14 May 2024 — [AUTOMATON](https://automaton-media.com/articles/newsjp/20240514-293317/)
- "Almost 330,000" Steam copies by 28 Aug 2024; about \$5 net per unit; about 20k sales per day for the first 5 days; about 300 units per day at four months. Launched with about 140k wishlists, timed just before Steam Farming Fest (29 Apr) for a "double peak." — [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed)
- 300k+ by August 2024 (JP coverage, "buzzed on SNS"). Buyers by region: China 26%, US 22%, Japan 10%, Korea 6%, Taiwan 4%. — [AUTOMATON](https://automaton-media.com/articles/newsjp/rustys-retirement-20240828-308175/)
- 550,000 copies by July 2025. — [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement), citing [GamesRadar, 25 Jul 2025](https://www.gamesradar.com/games/simulation/the-farming-sim-responsible-for-steams-latest-obsession-was-so-heavily-inspired-by-stardew-valley-that-its-internal-file-name-is-idle-valley-literally-stardew-valley-at-the-bottom-of-your-screen/); the GamesRadar headline of 31 Jul 2025 says "half a million copies" — [GamesRadar](https://www.gamesradar.com/games/simulation/where-eric-barone-used-his-indie-bucks-to-buy-a-proper-pc-creator-of-stardew-valley-inspired-hit-rustys-retirement-says-hes-got-the-same-usd1-000-rig-after-selling-half-a-million-copies-weve-literally-done-nothing-else-differently/)
- Virality: Morris had "a lot of success posting about the game on Twitter and Instagram Reels (which I then used to cross promote on TikTok)." Pirate Software praised it; many streams were filed under "Just Chatting." — [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed)
- The Steam page announcement on X (27 Nov 2023) drew strong responses, and several large European streamers shared it. — [AUTOMATON interview](https://automaton-media.com/articles/interviewsjp/20240205-281336/)
- Origin: a two-week prototype made while unwinding after Haiku, the Robot; internal name "Idle Valley" ("Stardew Valley at the bottom of your screen"). Influences: Stardew Valley and the strip-UI incremental game Microcivilization. Solo developer. — [GameDiscoverCo](https://newsletter.gamediscover.co/p/how-rustys-retirement-idle-farmed); [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement)
- Genre effect: the developer cited the bottom-of-screen genre it spawned (My Little Life, Whimside, Desktop Cat Cafe) when nominating it for the Steam Awards (Nov 2024). GamesRadar says its success prompted Steam's 2025 Idler Fest. — [Steam news](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2666510&count=60&maxlength=0&feeds=steam_community_announcements); [Wikipedia](https://en.wikipedia.org/wiki/Rusty%27s_Retirement)
- The developer's TikTok has promoted horizontal vs vertical layouts and map "aesthetics." — [TikTok](https://www.tiktok.com/@mister.morris.games/video/7528381828168764694)

### Inferences
- The concept itself is the hook: a 5-second clip of a farm living above the taskbar explains the whole game. A lavender strip game should plan short vertical videos of exactly that from day one.
- Asian markets bought 40% or more of copies, so localization (especially Simplified Chinese and Japanese) is high-value.

### Gaps
- View counts of the viral posts: not found. Sales figures after July 2025 (e.g. a 2026 total): not found.
