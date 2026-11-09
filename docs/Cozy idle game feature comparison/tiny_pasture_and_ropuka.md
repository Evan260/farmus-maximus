# Tiny Pasture and Ropuka's Idle Island: complete feature research (as of 24 Oct 2026)

Research notes for a cozy semi-idle Roman lavender-farming desktop game. Primary sources are the Steam store pages and the full Steam announcement feed for each game (pulled through the public Steam news API on 24 Oct 2026), plus the public Steam global achievement API, Steam community reviews, and third-party trackers.

Source shorthand used below:
- TP store: https://store.steampowered.com/app/3167550/
- TP news (all announcements, Aug 2024 to Jun 2026): https://store.steampowered.com/news/app/3167550 (raw feed: https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=3167550&count=60&maxlength=0&feeds=steam_community_announcements)
- RP store: https://store.steampowered.com/app/3416070/
- RP news (all announcements, Jan 2025 to Aug 2026): https://store.steampowered.com/news/app/3416070 (raw feed: https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=3416070&count=60&maxlength=0&feeds=steam_community_announcements)

## Identity of the two games (name disambiguation)

### Takeaway
"Idle Tiny Pasture" is not a separate product: the Steam title is simply **Tiny Pasture** (App 3167550, CaveLiquid, published by Gamersky Games). **Ropuka's Idle Island** (App 3416070, Moczan and Little Chmura) is unambiguous.

### Cited Findings
- Tiny Pasture: developer CaveLiquid, publisher Gamersky Games, Steam release date listed 17 Feb 2025; Windows and macOS — [TP store](https://store.steampowered.com/app/3167550/)
- Launch announcement says it launched 18 Feb 2025 at 10:00 AM UTC+8 (that is 17 Feb in Western time zones, which explains the store date) — [TP news, 17 Jan 2025 "Tiny Pasture set to release on February 18!"](https://store.steampowered.com/news/app/3167550)
- CaveLiquid describes itself as "a small studio run by an introverted couple and a bunny"; their previous game is Garlic Builder (the store-screenshot wallpaper comes from it) — [TP news, 31 Dec 2025 and 27 Feb 2025 Developer Q&A](https://store.steampowered.com/news/app/3167550)
- Ropuka's Idle Island: developers "Moczan and Little Chmura, Begoña Pereda", publisher Moczan and Little Chmura, released 29 Jan 2025, franchise "Ropuka" — [RP store](https://store.steampowered.com/app/3416070/)
- No game titled "Idle Tiny Pasture" was found on Steam in searches; all trackers and press use "Tiny Pasture" — [CogConnected](https://cogconnected.com/2025/02/tiny-pasture-is-launching-today-on-steam/), [Raijin](https://raijin.gg/app/3167550/Tiny_Pasture)
- The two games are cross-promoted: Steam bundle "Frog & Animals" (bundle 50361), and Ropuka is an unlockable companion in Tiny Pasture — [TP news, 26 Jun 2025](https://store.steampowered.com/news/app/3167550); [RP news, 27 Jun 2025](https://store.steampowered.com/news/app/3416070)

### Inferences
- When AppMagic or others say "Idle Tiny Pasture" they almost certainly mean App 3167550.

### Gaps
- None material.

## Core loop, moment-to-moment play, and progression/upgrades

### Takeaway
Tiny Pasture is a gacha-driven animal-collection farm: buy (draw) baby animals, feed and clean them until adult, collect coins they drop, spend coins on slots, facilities, decorations and more draws, with breeding and rarity-hunting as the long tail. Ropuka is a far simpler "watch the frog" loop: the frog auto-cuts grass (currency), you spend grass on stat upgrades and tokens, and tokens go into a sticker lottery whose collection bonuses feed back into grass income.

### Cited Findings

**Tiny Pasture: loop**
- "Charming little farm simulator that cozies up at the bottom of your screen." Buy baby animals, raise them, collect coins from adults to expand the pasture — [TP store](https://store.steampowered.com/app/3167550/)
- Interaction: "Feed them, click on them, and watch them grow happily!"; middle-click makes animals follow the cursor — [TP store](https://store.steampowered.com/app/3167550/)
- Feeding: select a carrot, long-press to drop carrots continuously (added so "your colleagues" don't see "frantic clicking in the office"); coins collected by hovering the mouse over them; drag animals to make them run; right-click opens animal info — [TP news, Build 0.6.4, 20 Oct 2024](https://store.steampowered.com/news/app/3167550)
- Animal acquisition is a draw system: choose a target quality and do ten-draws or automatic continuous draws that can run in the background; if coins run out before the target quality, the best animal obtained is shown — [TP news, 12 Feb 2025 and Ver1.0.3, 19 Feb 2025](https://store.steampowered.com/news/app/3167550)
- Rarity tiers include five-star and "rainbow" animals; "You can only get rainbow animals through lucky draws!" (not breeding) — [TP news, Ver1.0.10, 28 Feb 2025](https://store.steampowered.com/news/app/3167550)
- Breeding: place the Mystery (Grass) Curtain and pair two adults of the same species to get newborns; breeding has a cooldown; breeding consumes the parents (reviewer: "It really needs to warn you that breeding gets rid of the animals you select") — [TP store](https://store.steampowered.com/app/3167550/); [TP news, Ver1.0.7 and Ver1.0.8](https://store.steampowered.com/news/app/3167550); [Steam reviews, RitheGuardian](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- Health: animals get sick if neglected; healing potions exist (unlock threshold and price lowered in Ver1.0.3; cooldown removed in Jun 2025) — [TP news](https://store.steampowered.com/news/app/3167550); [Steam reviews](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- Selling animals, warehouse storage for animals, favorites/pinning to prevent accidental sale, confirmation pop-up when selling high-rarity animals — [TP news, 12 Feb 2025, Ver1.0.8, Ver1.1.2](https://store.steampowered.com/news/app/3167550)
- Harvestable decorations: plants that drop fruit (e.g. "Red Heart Fruit" seedlings), with an optional reminder icon when they mature — [TP news, Ver1.0.2 and Ver1.0.8](https://store.steampowered.com/news/app/3167550)

**Tiny Pasture: progression counts**
- Launch: 15 animal species, magical facilities, decorations and backgrounds — [TP news, 18 Feb 2025 launch post](https://store.steampowered.com/news/app/3167550)
- Base roster examples: rabbits, foxes, alpacas, birds, red pandas, pandas, deer, "Ghostie", slimes, zombies — [TP store](https://store.steampowered.com/app/3167550/); [TP news](https://store.steampowered.com/news/app/3167550); [Steam reviews (deer antlers)](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- The achievement list has 15 "all colors" and 15 "all rainbow colors" achievements (indices 0 to 14), consistent with 15 base species each having colour variants plus rainbow variants — [Steam global achievement API](https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=3167550)
- Added species since launch: sheep and cow (free DLC, 3 Apr 2025, plus extra colours in Ver1.1.2), frog and duck (free DLC, 18 Jun 2025), horse with a hidden "Fire Horse" variant (Feb 2026), 30+ fish (paid Azure Waters DLC), and collab guests: Rainbow Goobert (Backpack Battles), Lady Becky (Sultan's Game), the Guide (Bugtopia), Ropuka (unlock by raising 10 Red Pandas to adulthood) — [TP news](https://store.steampowered.com/news/app/3167550)
- Pasture slots raised from 21 to 36 (Jun 2025) — [TP news, 18 Jun 2025](https://store.steampowered.com/news/app/3167550)
- Facilities: auto-feeding, cleaning (Magic Broom), coin collection; max level raised from 5 to 9 (Jun 2025). Also Cuckoo House (drops food), "money-collecting bees" that collect earnings, Little Brick House — [TP news, 12 Feb 2025, Ver1.0.3, Ver1.0.12, 18 Jun 2025](https://store.steampowered.com/news/app/3167550)
- Multiple pastures: switch between them in the management interface; each has its own background, decorations and facility positions (Ver1.0.11, Mar 2025). Only the active pasture runs: "There is no passive time/income for all other pastures" — [TP news, Ver1.0.11](https://store.steampowered.com/news/app/3167550); [Steam review, RitheGuardian](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- 4 new droppable currency types added Ver1.1.1 (Apr 2025), with drop-quantity limits to prevent stutter — [TP news, Ver1.1.1](https://store.steampowered.com/news/app/3167550)
- Completion time: about 150 to 200 hours (aggregated review summary; one reviewer 233.4 h) — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)

**Ropuka: loop**
- "A playable sticker for your desktop." "While not sleeping, Ropuka is always cutting grass." "Unlock new buildings and plants to create your own unique island." — [RP store](https://store.steampowered.com/app/3416070/)
- The frog runs around cutting grass, naps in his chair (about 10 seconds) to regain stamina, waves and gives speech-bubble encouragement — [PCWorld, Ashley Biancuzzo, 8 Feb 2025](https://www.pcworld.com/article/2601025/this-cozy-4-game-is-helping-me-move-through-grief.html)
- Frog stats: Stamina (cuts before resting), Resting (stamina regained per second), Cutting (grass per cut), Running (speed). Grass stats: Quality (durability and value of each clump; e.g. Quality 20 with Cutting 2 = 10 swings for 20 grass), Growth (regrow rate) — [TreyEx Gaming beginner guide, 24 Jul 2025](https://www.treyexgaming.com/ropukas-idle-island-beginner-guide/)
- Tokens: free tokens from cutting a set amount of grass (orange bar); grass can also buy tokens at a rising price. Lottery (red notebook tab) spends tokens for a random sticker; duplicates possible. Individual stickers can be bought with tokens on the collection pages — [TreyEx guide](https://www.treyexgaming.com/ropukas-idle-island-beginner-guide/)
- Duplicates fill "dots" under an item; "Each dot gives you bonus stats"; once an item is fully dotted it leaves the lottery pool (developer replies) — [Steam discussion, 3 to 5 Feb 2025](https://steamcommunity.com/app/3416070/discussions/0/595140012858680154)
- Collection bonuses (yellow tab): unique stickers boost grass growth, total sticker level boosts grass quality, pages filled raise max stamina, pages maxed raise resting — [TreyEx guide](https://www.treyexgaming.com/ropukas-idle-island-beginner-guide/)
- Equip slots: Hat, Tree, Chair, Grass, House, Fence — [TreyEx guide](https://www.treyexgaming.com/ropukas-idle-island-beginner-guide/)
- 14 collections as of Jul 2025 — [TreyEx guide](https://www.treyexgaming.com/ropukas-idle-island-beginner-guide/)
- Patch 1.0.12 (2 Feb 2025) added more levels to most upgrades but made them cheaper "so there should be less waiting periods"; Patch 1.0.10 fixed grass growth being "over 10 times higher than the displayed value" — [RP news](https://store.steampowered.com/news/app/3416070)
- Reviewer: "It takes around 275 hours or so to 100%" — [Steam review, emipsx](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)

### Inferences
- Tiny Pasture leans on care needs (hunger, cleanliness, sickness) and gacha rarity for engagement; Ropuka leans entirely on slow passive accrual plus a cosmetic-collection lottery whose duplicates double as stat boosts. Ropuka's design (cosmetics are the progression) is the closer fit for a low-attention desktop game.

### Gaps
- Exact Tiny Pasture draw odds, pity rules, and slot/facility price curves: not found in official sources.
- A full list of Ropuka upgrade names, level caps, and cost curves: not found.

## Idle mechanics and offline progress

### Takeaway
Neither game has confirmed offline earnings. Tiny Pasture only progresses while running, and long absences while running can leave animals sick and hungry; its "no offline earnings" is a frequent complaint. Ropuka progresses while running and players describe returning after hours to large grass totals, but no source confirms progress while the game is closed.

### Cited Findings
- Tiny Pasture: "No offline earnings" is a major complaint; players must keep the game running; early game needs manual feeding and cleaning; automation (auto-feeder, auto-cleaner, auto-coin collector) typically unlocks within the first few hours (aggregated review summary) — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)
- Tiny Pasture negative review: "punishing you for being idle is a very strange choice." "If you leave for too long, everyone gets sick" (Not Recommended, 37.5 h, developer replied) — [Steam reviews, Darkvoid](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- Tiny Pasture: a reviewer returned after about five hours to "very sick and hungry animals that had generated very little coin" despite auto-helpers (search-result snippet of a Steam review) — [Steam discussion](https://steamcommunity.com/app/3167550/discussions/0/599644966903354718)
- Tiny Pasture: "at first the game requires a couple of hours to become a true idle sim" — [Steam review, snapphy](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- Tiny Pasture: auto continuous draws "can keep running in the background" — [TP news, 12 Feb 2025](https://store.steampowered.com/news/app/3167550)
- Ropuka: "leaving him for a few hours and coming back to see millions of grass trimmings" — [Steam review, artichao, 1,148 h](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)
- Ropuka: "It is a true idle game"; "The more I work, the more grass he gets to cut" — [Steam reviews](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)
- Ropuka: progress is "very slow going indeed"; after "several weeks of leaving it running" you can buy new features — [Professional Moron, 16 Nov 2025](https://professionalmoron.com/2025/11/16/ropukas-idle-island-game/)
- Ropuka sleep modes: Relaxed makes naps twice as long and Sleepy four times as long, and after those naps Ropuka collects 2x or 4x grass "to make sure you progress at a similar rate" — [RP news, Update 1.8, 31 May 2025](https://store.steampowered.com/news/app/3416070)

### Inferences
- Both games are designed around the app being open on the desktop, so "time with the app open" is the idle clock. A lavender game that adds real offline growth (with a cap) would differentiate, and Tiny Pasture's sickness-while-away complaint is a direct lesson: avoid punishing absence.

### Gaps
- Whether Ropuka accrues anything while closed: not found (Steam discussion search was rate-limited). Treat as unconfirmed.
- Any official offline cap for either game: not found.

## Window and display modes

### Takeaway
Both are transparent, borderless desktop overlays. Tiny Pasture is a resizable-length horizontal strip at the bottom of the screen, draggable anywhere, with an always-on-top toggle. Ropuka is a free-floating, scalable island "sticker" placeable anywhere, with transparent or windowed modes, always-on-top, UI scale 50 to 300%, FPS cap and hide-UI options.

### Cited Findings

**Tiny Pasture**
- Sits at the bottom of the screen and stays "out of your workspace"; "You can drag the pasture, adjust its length, and place it anywhere on screen" — [TP store](https://store.steampowered.com/app/3167550/)
- Settings: optional pin-to-top (always on top), move the ranch window up or down, minimize button at top-left of the ranch window, right-click to drag the ranch — [TP news, Build 0.6.4, 20 Oct 2024](https://store.steampowered.com/news/app/3167550)
- Interface size adjustable (bug fixes reference "adjusting the interface size" with settings and store open) — [TP news, Ver1.0.2](https://store.steampowered.com/news/app/3167550)
- Multi-monitor: fixes for multiple screens with different resolutions (Build 0.6.5, Ver1.0.1, Ver1.0.3 Mac dual-screen unclickable windows, Ver1.1.2) — [TP news](https://store.steampowered.com/news/app/3167550)
- Transparency problems: a "black background" issue on some systems drove multiple patches (Ver1.0.9 needed reinstall) and an opaque "Starry Night" background / dynamic sky decoration so the black area could be covered — [TP news, Ver1.0.9 and Ver1.1.2](https://store.steampowered.com/news/app/3167550)
- Linux users report black backgrounds; Steam overlay tearing fix is to disable the in-game overlay — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)

**Ropuka**
- Island can be placed "anywhere on your screen", resized, and moved to another monitor — [Professional Moron](https://professionalmoron.com/2025/11/16/ropukas-idle-island-game/)
- "you can make the background of the game transparent and resize it so it can fit anywhere on your PC" — [Steam review, emipsx](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)
- UI scale 50% to 300%; Always on Top setting; move island with Left Shift plus arrow keys; launch from install folder; wallpapers shipped in a Wallpapers folder — [RP news, Patch 1.0.10, 31 Jan 2025](https://store.steampowered.com/news/app/3416070)
- Windowed (non-transparent) mode showing one of the game's wallpapers; FPS limit 30/60/75/120/144/165/240; mute button next to the "Move Island" handle — [RP news, Update 1.4, 28 Feb 2025](https://store.steampowered.com/news/app/3416070)
- Option to turn off auto-hiding of the UI (Settings, Display); "Exit to Desktop" always in Settings — [RP news, Update 1.3, 22 Feb 2025](https://store.steampowered.com/news/app/3416070)
- Screen position and island scale now save between sessions (experimental) — [RP news, Update 1.18, 22 Apr 2026](https://store.steampowered.com/news/app/3416070)
- Transparency/black-screen bug required a reinstall to fix (Update 1.7.0, Apr 2025) — [RP news](https://store.steampowered.com/news/app/3416070)
- Known issue: "if you shift-tab to bring up the overlay in another game, it will break Ropukas and require a restart" — [Steam review, emipsx](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)

### Inferences
- Transparent-window rendering is the single biggest technical risk in this genre: both games shipped multiple patches for black backgrounds, and both added an opaque fallback (TP's Starry Night background, RP's windowed wallpaper mode). Plan an opaque fallback from day one.

### Gaps
- Explicit click-through (mouse passes through the empty transparent area) is not stated in official notes for either game. Not found.
- Tiny Pasture opacity slider or animal scale setting: not found.

## Collection, customization, decoration, companions

### Takeaway
Tiny Pasture: collect species, colour variants and rainbow rarities in an encyclopedia; name animals; keep babies small; decorate with seasonal decor and backgrounds; Steam Workshop for user-made critters and decorations. Ropuka: collect sticker decorations (houses, trees, chairs, grass, fences) in themed sets, dress the frog (hats, accessories, clothes), and add up to two "friends".

### Cited Findings

**Tiny Pasture**
- Name animals; sort by quality, acquisition time, or earnings rate; favourite and pin; encyclopedia; toggle to keep animals in juvenile form "without affecting adult benefits" — [TP news, 12 Feb 2025 and Ver1.0.9](https://store.steampowered.com/news/app/3167550)
- Decorations stackable (placement restrictions "greatly reduced", Ver1.1.2); continuous move and delete modes (Jun 2025) — [TP news](https://store.steampowered.com/news/app/3167550)
- Steam Workshop live 18 Apr 2025: "Design unique critters and decorations", upload and download; modding tutorial provided; mod check removes data of unsubscribed mod animals — [TP news, 18 Apr 2025 and 22 May 2025](https://store.steampowered.com/news/app/3167550)
- Seasonal/holiday decor (all free updates): Mid-Autumn and autumn set plus autumn background (29 Sep 2025); 8 Halloween decorations (31 Oct 2025, e.g. Candy Jar, Ghost Hat, Evil Pumpkin, Small Gravestone, Dark Fence); 12 Christmas items plus "Winter Wonderland" background (18 Dec 2025); 8 Spring Festival decorations (Feb 2026); 4 crowdfunding-reward decorations plus new BGM, free to all (19 Mar 2026) — [TP news](https://store.steampowered.com/news/app/3167550)
- Supporter Pack DLC "includes an adorable skin" — [TP news, launch post](https://store.steampowered.com/news/app/3167550)
- Ropuka as a companion in Tiny Pasture "will leisurely accompany you as you relax and sunbathe" — [TP news, 26 Jun 2025](https://store.steampowered.com/news/app/3167550)
- Review complaints: many animals hide decorations; facility skins missing; decorations feel dull (low-weight themes) — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)

**Ropuka**
- Small house variant of every house (12 stickers), ground colour matches selected grass — [RP news, Update 1.3](https://store.steampowered.com/news/app/3416070)
- Idler Fest set (6 stickers, 2 tokens each) — [RP news, Patch 1.1.3](https://store.steampowered.com/news/app/3416070)
- Catalogue rework with collection index page, sets grouped under "'92 Collection" — [RP news, Update 1.5](https://store.steampowered.com/news/app/3416070)
- Content drops: Spring set in two colour variants, 12 items (Mar 2025); summer items (8, Aug 2025); 6 Halloween items in Lottery (Oct 2025); winter set plus snow (Dec 2025); city-life set with Nano Neighbors (Dec 2025); 4 winter hats (Dec 2025) — [RP news](https://store.steampowered.com/news/app/3416070)
- Frog customization: two accessory slots (e.g. hat plus glasses, or headphones plus humming notes), 6 new hats (Update 1.8); 7 clothes variants (Update 1.9) — [RP news](https://store.steampowered.com/news/app/3416070)
- Friends tab: any combination of 2 friends can join Ropuka (Update 1.17, Dec 2025); Onion friend for 10 coins (Update 1.19, Aug 2026) — [RP news](https://store.steampowered.com/news/app/3416070)
- Behaviour tab: Cutting mode (even lawn vs closest to home), Sleep mode, Talking mode (greet and talk or stay silent), Running speed — [RP news, Update 1.8](https://store.steampowered.com/news/app/3416070)

### Inferences
- Both games treat holiday/seasonal decoration drops as their main live-ops lever, delivered free. For a Roman lavender game, a calendar of Roman festivals (Saturnalia, Floralia, etc.) maps naturally onto this.

### Gaps
- Total decoration counts for either game: not found.

## Ambient life, animation, day/night, weather, seasons

### Takeaway
Tiny Pasture's ambience is the animals themselves (sleeping, scratching, wandering, speech bubbles, petting reactions). Ropuka added dynamic weather (Nov 2025), snow (Dec 2025), user-selectable weather, and swaying grass; seasons are expressed through decoration sets. Neither has a confirmed day/night cycle.

### Cited Findings
- TP animals "snooze, scratch, and scamper" at the bottom of the screen — [TP store](https://store.steampowered.com/app/3167550/)
- TP: varied petting, hugging and poking reactions and lively idle movement are a top praise theme — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)
- TP: animal speech bubbles (frequency reduced Jun 2025); "dynamic sky" decoration that overlays backgrounds; Starry Night background — [TP news](https://store.steampowered.com/news/app/3167550)
- RP: dynamic weather, changes "every few minutes" by chance; ambient track syncs to weather (Update 1.14, 10 Nov 2025); snowy weather and Settings > Graphics > Weather selection (Update 1.15); weather choice persists (Update 1.18) — [RP news](https://store.steampowered.com/news/app/3416070)
- RP: "the grass dances to the wind"; earlier player wish: "I just wish it could rain sometimes :)" (predates the weather update) — [Steam review, Dhartarius](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)
- RP roadmap (4 Mar 2025) promised new activities: drinking a hot beverage, eating, dancing to music, sleeping under a tree, and a returning guest friend — [RP news, "What's next"](https://store.steampowered.com/news/app/3416070)

### Inferences
- Weather synced to ambient audio was one of Ropuka's most requested additions; worth including early.

### Gaps
- Day/night cycle tied to real clock: not found for either game.
- Whether Ropuka's roadmap activities (beverage, dancing) shipped: not confirmed in patch notes found.

## Audio

### Takeaway
Ropuka invests heavily in audio: a lofi soundtrack (at least 12 tracks added over time), many ambient loops, a mixer for music versus ambience, playlists, weather-synced ambience, a mute button, and a paid soundtrack DLC. Tiny Pasture has BGM (one new track added Mar 2026) but its audio options are thinly documented.

### Cited Findings
- RP: custom lofi track and ambient nature sounds, option to mix sources or play in silence — [RP store](https://store.steampowered.com/app/3416070/)
- RP: 2 new tracks and 5 new seamless ambient loops; choose ambient loop and which songs play in sequence or loop one (Patch 1.2, Feb 2025); 6 new songs with personal playlist (Update 1.14); 2 new songs (Update 1.15) — [RP news](https://store.steampowered.com/news/app/3416070)
- RP: music volume and ambient volume settings persist (Patch 1.0.10) — [RP news](https://store.steampowered.com/news/app/3416070)
- RP: Soundtrack DLC released 29 Jan 2026 (CDN\$2.59) — [RP news](https://store.steampowered.com/news/app/3416070); [RP store](https://store.steampowered.com/app/3416070/)
- RP review: "The lo-fi music is relaxing, but I'm more into the ambient noise"; wish for "a more mythical/eerie track" — [Steam reviews](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)
- TP: new BGM by the composer of Maltese's Fluffy Onsen (Mar 2026) — [TP news, 19 Mar 2026](https://store.steampowered.com/news/app/3167550)

### Gaps
- Tiny Pasture volume controls and number of BGM tracks: not found.

## Achievements, Steam features, platforms

### Takeaway
Tiny Pasture: 55 achievements, Steam Cloud, Workshop, Windows and macOS. Ropuka: 31 achievements, Steam Cloud, trading cards and points-shop items, Windows only (Mac port planned, no date). Neither lists controller support; neither has an official Steam Deck rating found.

### Cited Findings
- TP: 55 achievements (rarest about 12%) — [Steam achievement API](https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=3167550)
- RP: 31 achievements; "ACH_100" (full completion) held by 15.0% — [Steam achievement API](https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=3416070)
- RP: 20 achievements added in Patch 1.0.12; achievements scoped to the "'92 Collection" so new sets don't break progress (Update 1.5) — [RP news](https://store.steampowered.com/news/app/3416070)
- TP features: Single-player, Steam Achievements, Steam Cloud, Family Sharing; Windows 10 and macOS 10.9+ — [TP store](https://store.steampowered.com/app/3167550/)
- TP: cloud saves sync progress only, settings stay local; up to 10 local backups (Ver1.0.3); backups kept hourly for 7 days (Ver1.0.13); manual save button — [TP news](https://store.steampowered.com/news/app/3167550)
- TP: DLC achievements missing is a complaint — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)
- TP Steam Deck/Linux: frequent crashes, black background, missing auto-save; rated "Broken" by an aggregated scan — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md)
- RP features: Single-player, Steam Achievements, Steam Cloud, Family Sharing; Windows only, 250 MB — [RP store](https://store.steampowered.com/app/3416070/)
- RP: Steam Trading Cards and profile backgrounds (29 Jan 2026) — [RP news](https://store.steampowered.com/news/app/3416070)
- RP Mac: developer says "we have plans to port it to other platforms but no release dates yet" — [Steam discussion](https://steamcommunity.com/app/3416070/discussions/0/727997387701821988)
- RP: a Humble bundle listing marks it "Playable" on Steam Deck (secondary source, unverified on Steam) — [Notebookcheck](https://www.notebookcheck.net/Humble-s-latest-bundle-goes-live-with-13-Steam-Deck-friendly-games-for-just-10.1351968.0.html)
- Languages: TP 14 on store (plus Thai announced Sep 2025, not shown in store list); RP 10 (JP/zh-Hans/KO added Jun 2025; PL/FR/DE/ES/pt-BR added Oct 2025) — [TP store](https://store.steampowered.com/app/3167550/); [RP news](https://store.steampowered.com/news/app/3416070)

### Gaps
- Controller support: not listed for either game. Official Steam Deck compatibility rating: not found for either.

## Settings and quality of life

### Takeaway
Both games added most of their QoL settings in the first two months after launch in response to feedback; see lists below.

### Cited Findings
- TP: always show food slot toggle; mature-harvest reminder toggle; manual save; save backups; interface size; pin to top; window up/down; sort and favourites; DLC enable/disable panel; confirmation for new game and rare sales — [TP news](https://store.steampowered.com/news/app/3167550)
- RP: UI scale, always on top, keyboard island move, windowed mode, FPS cap, mute button, disable UI auto-hide, frog behaviour controls (cut pattern, nap length, talking on/off, run speed), weather selection, playlist, language selector — [RP news](https://store.steampowered.com/news/app/3416070)
- RP savefile safety checks against crash/power-loss corruption (Patch 1.1.6) — [RP news](https://store.steampowered.com/news/app/3416070)

## Developer, release, price, DLC, post-launch updates

### Cited Findings
- TP price: CDN\$7.79 (store, 24 Oct 2026); US\$5.99 — [TP store](https://store.steampowered.com/app/3167550/); [Raijin](https://raijin.gg/app/3167550/Tiny_Pasture). Launch discount 10% (\$5.39) — [CogConnected](https://cogconnected.com/2025/02/tiny-pasture-is-launching-today-on-steam/). "Lowest price ever" sale 22 Apr 2026 — [TP news](https://store.steampowered.com/news/app/3167550)
- TP DLC: Azure Waters (paid, CDN\$3.89, 30+ fish, water backgrounds, dynamic decorations, 18 Jun 2025); Baabaa and Moomoo (free, 3 Apr 2025); Ribbitribbit and Quackquack (free, 18 Jun 2025); Supporter Pack (CDN\$2.59); Deluxe Edition bundle — [TP store](https://store.steampowered.com/app/3167550/); [TP news](https://store.steampowered.com/news/app/3167550)
- TP timeline: announced 28 Aug 2024; demo 14 Oct 2024 (Steam Next Fest); launch 18 Feb 2025; 10 hotfixes in first 10 days; Workshop Apr 2025; seasonal updates Sep 2025 to Mar 2026; latest news 10 Jun 2026 (bundle) — [TP news](https://store.steampowered.com/news/app/3167550)
- TP marketing: many cross-promotional bundles and in-game collabs (Sultan's Game, Bugtopia, Backpack Battles, Ropuka, Sanfu, Monster Farm, Lakeside Bar, Tingus Goose, Birdwatching Notebook, etc.); "Sit Back and Relax" Steam Award nomination campaign (Nov 2025); Modian merch crowdfunding with 654 backers (ended Mar 2026); BitSummit and WePlay Expo 2025 — [TP news](https://store.steampowered.com/news/app/3167550)
- RP price: CDN\$4.49 base — [RP store](https://store.steampowered.com/app/3416070/); US\$3.99 per SteamSpy — [SteamSpy](https://steamspy.com/app/3416070); PCWorld cited \$3.59 at launch (likely discounted) — [PCWorld](https://www.pcworld.com/article/2601025/this-cozy-4-game-is-helping-me-move-through-grief.html)
- RP DLC: Soundtrack only — [RP store](https://store.steampowered.com/app/3416070/)
- RP timeline: launch 29 Jan 2025; weekly patches Feb to Apr 2025; regular content updates through 1.19 (12 Aug 2026); Ropuka guest appearances in Fish to Dish: Idle Sushi, Nano Neighbors, Boil Cabbage Make Soup — [RP news](https://store.steampowered.com/news/app/3416070)

## Steam reviews: score, counts, praise and complaints

### Takeaway
Both are strongly reviewed. Ropuka is Overwhelmingly Positive (95%); Tiny Pasture is Very Positive (92 to 93%). Ropuka is praised for being a genuine low-demand idle companion and for its audio; Tiny Pasture is praised for cute, reactive animals but criticised for gacha odds, care demands that punish idling, and stability.

### Cited Findings
- TP: Very Positive, 93% of 1,205 English reviews; recent 86% of 60 — [TP store](https://store.steampowered.com/app/3167550/). Total across languages about 8,683, 92% — [Raijin, 24 Oct 2026](https://raijin.gg/app/3167550/Tiny_Pasture)
- RP: Overwhelmingly Positive, 95% of 2,396 English reviews; recent 85% of 40 — [RP store](https://store.steampowered.com/app/3416070/). Total about 4,344, 95% — [Raijin, 24 Oct 2026](https://raijin.gg/app/3416070/Ropukas_Idle_Island)
- TP praise: "unlocking all the creatures was oddly satisfying"; "One of the best idle desktop companion games available!!"; "the option to keep the pets looking like babies even after they grow up"; "The progression feels really well-balanced"; "You can even pet your animals" — [Steam reviews](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- TP complaints: "you can only get a five-star animal by continuously buying it from the shop. You must gamble & breed a lot."; "There is no passive time/income for all other pastures"; "I've have the game crash multiple times when transferring animals"; "All adult deer having antlers feels too inaccurate" — [Steam reviews](https://steamcommunity.com/app/3167550/reviews/?browsefilter=toprated&filterLanguage=english)
- TP aggregated negatives: punishing gacha with no pity (reports of hundreds to over a thousand pulls for one 5-star), boring late game, "distracting, not relaxing", multiple pastures pointless, money loses value late, one-minute breeding cooldown, screen clutter, slow slot unlocks, laptop fan/battery drain — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture.md) (note: Vaporlens also mentions "\$20+ price", which does not match the US\$5.99 list price; likely refers to the Deluxe bundle or is an error)
- RP praise: "perfect game to have running in the corner while you're doing the daily grind at work"; "this game is very low-demand so you can easily run a different game"; "it uses pretty much no resources so you can have it running on a potato"; "The music is chill AF"; "you're doing great, bud" (the frog's encouragement) — [Steam reviews](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english)
- RP complaints/wishes: "there isn't much you can do with Ropuka other than customise him and his island"; shift-tab overlay bug; more ambient sounds; more music styles; slow pace ("very slow going indeed") — [Steam reviews](https://steamcommunity.com/app/3416070/reviews/?browsefilter=toprated&filterLanguage=english); [Professional Moron](https://professionalmoron.com/2025/11/16/ropukas-idle-island-game/)
- RP early complaint: Grass Quality price change was reverted after feedback (Patch 1.0.17) — [RP news](https://store.steampowered.com/news/app/3416070)

### Gaps
- A quantified sample of Ropuka negative reviews: not retrieved (Steam review API blocked, community search rate-limited).

## Sales and revenue estimates

### Takeaway
Estimates disagree widely. Raijin puts Tiny Pasture at about 162K copies / US\$776K gross and Ropuka at about 93K copies / US\$297K gross. Vaporlens puts Tiny Pasture near 608K sales, which matches the "around 600K" figure attributed to AppMagic; that figure could not be verified on AppMagic itself.

### Cited Findings
- TP (Raijin, 24 Oct 2026): ~162,001 copies, ~\$776.3K gross, medium confidence; all-time peak CCU 2,546; ~148K wishlists; 21,401 followers; Oct 2026 avg daily players 501 — [Raijin](https://raijin.gg/app/3167550/Tiny_Pasture). A July 2026 snapshot said 161.3K copies / \$821K — [Raijin via search](https://raijin.gg/app/3167550/Tiny_Pasture)
- TP (Vaporlens, Jun 2026): 607,624 estimated sales, \$3,639,668 at \$6 — [Vaporlens](https://vaporlens.app/app/3167550/tiny_pasture/stats/details)
- TP (SteamSpy): 200,000 to 500,000 owners — [SteamSpy](https://www.steamspy.com/dev/CaveLiquid)
- RP (Raijin, 24 Oct 2026): ~93,130 copies, ~\$297K gross, medium confidence; all-time peak CCU 1,623; ~57K wishlists; 6,663 followers; Oct 2026 avg daily players 307 — [Raijin](https://raijin.gg/app/3416070/Ropukas_Idle_Island)
- AppMagic launched Steam analytics in 2025, but the 2026 idle-games article was not retrieved — [GamesMarket](https://www.gamesmarket.global/new-analytics-module-appmagic-expands-into-pc-with-steam-analytics-728ae65bf304bbd73fa9a249a24ecf7a/)

### Inferences
- The roughly 4x gap between Raijin and Vaporlens comes from different review-multiplier assumptions (Chinese-market titles often have more owners per review). A range of about 160K to 600K for Tiny Pasture is the honest statement.

### Gaps
- AppMagic and Gamalytic figures for either game: not directly verified.
