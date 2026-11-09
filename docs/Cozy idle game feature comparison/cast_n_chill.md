# Cast n Chill (Wombat Brawler): complete feature research

Research date: 24 October 2026. Steam announcements show years only for 2025 posts. The 2026 posts (26 Feb, 3 Mar, 28 May, 7 Aug, 19 Oct) are dated 2026 by context, because they follow the December 2025 posts in the newest-first list.

Source reliability note: two fan wikis turned up. castnchill.unpack.wiki shows internal config values (it looks datamined, but it is unofficial and unverified). castnchillwiki.com calls itself a "dated" tracker and marks many items "to be confirmed". Claims that rest only on these wikis are labelled as such.

## 1. Core loop: fishing (active vs idle), selling, storage, moment-to-moment play

### Takeaway
You start with a basic rod, a bobber, a boat and a dog. You row to a spot, cast, and reel with two buttons, watching a screen split between above and below the water. When the cooler (fish storage) is full, you go back to Rusty's bait shop, where the catch sells automatically, and buy upgrades and licenses. Idle/Passive Mode runs this whole loop by itself (row, cast, catch, sell) at a reduced payout. There is also offline progression.

### Cited Findings
- Starting kit: "a basic rod and reel, a bobber, a boat, and a dog that you can pet any time you want." — [Shacknews review](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- "When your fish storage is full you head back to Rusty's bait shop." Catches sell automatically for cash. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Caught fish go into a cooler. A logbook records each fish's size and weight. — [WellPlayed review](https://www.well-played.com.au/cast-n-chill-review/)
- Controls: hold left mouse to reel in and right mouse to let line out. Move the boat with A/D or a single mouse click. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- "Two buttons, that's it" is listed as a strength. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/). Nintendo Life also says the controls use only two buttons. — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)
- The view is "split about fifty-fifty above and below the water", so you can see fish approach the lure. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Fighting fish: you can't overpower a strong fish. You stop reeling and let it tire, and a fish that runs too much line can mean settling for a smaller catch. — [Vice review](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/). A fish too big for your rod "won't snap your line" but may "get off the hook" and bite again. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Some fish respond only to specific lures. — [Vice](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/)
- Active mode: "Casting and reeling in quickly speeds up production." Passive mode: the game fishes for you and you return later to see the day's catches, "offline progression is included". — [Press release, 3 Feb 2025, Games Press](https://www.gamespress.com/Announcing-Cast-n-Chill---Cozy-Idle-Fishing---Coming-June-2025)
- In idle mode the angler rows out, casts, catches and sells. "Entirely optional, but brilliant." — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Idle mode starts when the game is left untouched, keeps fishing and selling at a "slightly decreased payout per catch", and any input hands control back. Settings let you adjust "how active you want the idle mode to be", including when it starts and which fish it can catch. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- Developer (29 May 2025, during the demo): "Yes I think we'll tone back the profits or frequency fish are caught in idle to counter that a bit." Also: "Character can move anywhere on there own in idle!" Players note that idle mode hides the underwater view. — [Steam discussion "Idle mode"](https://steamcommunity.com/app/3483740/discussions/0/603031542017596599/)
- Idle mode can hide the underwater view: "you CANT see under the water or any of the fish while in idle mode???" Another player: "There is no auto mode to go back unless you switch into idle." — [Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)
- The game "saves constantly", so you can stop at almost any time (player, Aug 2025). — [Steam discussion "Is there an endgame"](https://steamcommunity.com/app/3483740/discussions/0/807952395548162442/)
- Datamined config (unofficial): normal fish respawn after 600 s and legendary fish after 72,000 s (20 h). The catch sells at 1 fish per second. Up to 5 fish markers. Rarity value multipliers: Common 5x, Uncommon 8x, Rare 10x, Epic 15x. Fish stats are Speed, Stamina, Vision (how easily spooked) and Hearing. Fights have fight, chase and flee phases. Stamina system for rowing, walking and breaking ice. — [castnchill.unpack.wiki mechanics](https://castnchill.unpack.wiki/docs/mechanics/) (unofficial)

### Inferences
- Moment to moment, the game is "position boat, cast, watch the underwater half, reel or let line out, repeat until the cooler fills, then go back to sell." Cooler size and boat speed set the length of a trip, and a player review (below) singles them out as the upgrades that matter.
- The idle trade-offs are reduced payout and no underwater view. They keep active play worthwhile without forcing it, which is useful as a model for a semi-idle game.

### Gaps
- The exact idle payout penalty (percentage) was not found.
- Offline progression details were not found: whether it simulates catches after the game is closed, any cap on offline hours, and whether a full cooler stops progress or idle keeps selling. The press release confirms only that offline progression "is included".
- Whether fishing continues while the game is minimized was not found.
- Starting and maximum cooler capacity were not found.

## 2. Progression and upgrades (rods, lures, hooks, line, boats, licenses, locations)

### Takeaway
Coins from fish buy hooks, lures, rods, reels, line strength and length, cooler and boat upgrades, new boats, and licenses for new locations, all at Rusty's bait shop. You tip Rusty to get rumours about legendary fish. Location count: 13 at launch (Jun 2025) and 16 on the store now, or 17 with the Old Moose Cabin hub (unofficial wiki). Players report that money comes quickly and everything can be bought in a few days.

### Cited Findings
- At the bait shop you "buy new hooks and lures, rods, boats, licenses for new locations, and upgrade your existing gear". Tipping Rusty "now and then" reveals secrets. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Legendary "sea beasties" need rumours from the shopkeeper, which you buy with tips. — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)
- Buyable items include lures, rods, line strength and line length. "No forced grind", money comes in quickly. — [Vice](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/)
- Rods, reels, lures, hooks, and "a faster boat with more catch capacity". Licenses unlock new areas: "Each of the 13 bodies of water" (at launch). — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- The store now lists "16 fishing spots, each with its own wildlife". — [Steam store page](https://store.steampowered.com/app/3483740/Cast_n_Chill/). The press kit also says 16 fishing spots. — [Wombat Brawler press kit](https://www.wombatbrawler.com/cnc-press-kit)
- Unofficial list of 17 locations by area. Goldenfork River: The Fork, Beaver Dam, The Mistwood. Grizzlyridge River: The Rapids, Eagles Nest. Fawnmirror Lake: Underwater Meadow, Picnic Point, Fisherman's Rest. Autumnwood Lake: Shallows Edge, Otter Cove. Icewater Sea: Watchers Point, Craggy Reef, Safety Cove. Old Wreck Bay: Divers Drop, Seals Rest. Lake Hunkerdown: Frostbite Flats (ice). Old Moose Valley: Old Moose Cabin. — [castnchill.unpack.wiki locations](https://castnchill.unpack.wiki/docs/locations/) (unofficial). This matches 13 at launch, plus 2 Autumnwood spots, plus Frostbite Flats (16), plus the cabin.
- Boats named on the unofficial wiki: Pond Paddler and Coastal Rambler. — [castnchill.unpack.wiki](https://castnchill.unpack.wiki/)
- Autumnwood Lake update (article dated 15 Sep 2025): a new lake unlocked by a special license from Rusty's Bait n' Tackle, with 2 spots, 8 new fish (2 legendary), a dachshund companion, 3 new lures (Bluegill Swimbait, Heavy Drop Shot, Minnow Swimbait), and a new rod, Copperleaf 86, which uses fluorocarbon line. — [NostalPix](https://nostal-pix.com/?p=2180&lang=en)
- Lake Hunkerdown Winter Update (30 Nov 2025): the Frostbite Flats ice-fishing spot, the Snow Wolf XT1 snowmobile, two rods (Frost Stick as an all-rounder and Hardwater Howler for harsh cold), and a St. Bernard companion. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)
- Achievement "Rusty's No.1 Customer": buy and upgrade everything in the shop (7.7% of players). — [Steam global achievements](https://steamcommunity.com/stats/3483740/achievements)
- Player review: upgrades "feel almost cosmetic when put into use". Only Fish Storage and Boat Speed made a real difference. — [Steam negative reviews (Alexx, 7.8 h)](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)
- Reader comment: earning money is too fast, and upgrades and boats unlock within a few days. — [Nintendo Life comments](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition) (reader opinion)
- Time to beat (How Long to Beat via search snippet): main about 16h 44m, completionist about 24h 47m. TrueSteamAchievements: 10 to 12 h for all base achievements. One player: about 9 h for a focused 100%. — [search summary citing HLTB / TSA](https://truesteamachievements.com/game/Cast-n-Chill/achievements); [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/807952395548162442/)

### Inferences
- The pacing is short. One cycle of buying everything in the shop takes roughly 10 to 25 hours, and free location updates extend it.
- Of the many upgrade tiers, only storage and speed noticeably change the loop. A designer could make each upgrade tier visibly change what the player does.

### Gaps
- Exact counts of rods, lures, hooks and reels were not found from a reliable source.
- License and upgrade prices were not found. One unofficial guide mentions restoring the cabin Fishfinder for 3000g (search snippet only, not verified).

## 3. Idle mechanics and offline progress

### Takeaway
Passive/Idle Mode starts after a configurable period of no input and does the full loop at reduced profit. Offline progression is officially "included", but no source documents how it works or whether it has a cap. Idle has been buggy at times: it used one bait only, got stuck on rocks and on ice, and failed to start from menus. These were patched repeatedly through Oct 2026.

### Cited Findings
- Official: "let passive mode take over and return when ready", with offline progression included. — [Press release](https://www.gamespress.com/Announcing-Cast-n-Chill---Cozy-Idle-Fishing---Coming-June-2025)
- Official store wording: Passive Mode lets the game fish while you're away. — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- Configurable start delay and which fish idle can target. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- Idle mode was added in a demo update in late May 2025 after a player request ("We're releasing it in a demo update in a day or two :)"). — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/603031542017596599/)
- Early criticism: idle "will only use one bait, and rarely catches fish" (since patched, per the summary of the review). — [Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated). Another review: auto mode "decapitates the fishing experience entirely". — same source
- v1.2.4 (3 Mar 2026): idle uses the topwater lure correctly, idle ice fishing works better (less getting stuck or timing out), and idle no longer drives the snowmobile away without the companion. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/); [Perfectly Nintendo](https://www.perfectly-nintendo.com/cast-n-chill-switch-switch-2-all-the-updates/)
- v1.3.1 (19 Oct 2026): fixes idle failing to start from the lure and rod menus and failing to cast and reel on the Old Moose Cabin dock. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/)
- One reviewer found the idle fisher often gets stuck on simple geometry and rocks (search snippet). Whether idle catches legendary fish is unresolved in community reports. — [castnchillwiki idle guide](https://castnchillwiki.com/guide/idle-mode/) (unofficial)

### Inferences
- The game gates idle by giving it less value (reduced payout, no underwater view) rather than locking it, which keeps idle a free choice.

### Gaps
- Offline mechanics (simulated time, cap, cooler-full behavior) were not found. The idle penalty value was not found. Whether idle affects achievements is unverified.

## 4. Window and display modes

### Takeaway
On PC the game officially supports "a second monitor or a resizable window for single-monitor setups." Windowed mode resizes freely to any size. A fullscreen option exists (it had a stretching bug), but there is no dedicated borderless option. Pre-launch, windowed mode appeared to launch always-on-top, which was reported as a bug, not a feature. No official desktop strip, transparency or always-on-top toggle was found.

### Cited Findings
- "Play on a second monitor, or use the resizable window on a single monitor." — [Press release](https://www.gamespress.com/Announcing-Cast-n-Chill---Cozy-Idle-Fishing---Coming-June-2025); [Press kit](https://www.wombatbrawler.com/cnc-press-kit)
- Store: Passive Mode "can run on a second monitor or in a corner of the screen". — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- Negative review: "Resizable: Windowed mode is truly windowed, you can resize the game to whatever you'd like", and it lists no borderless option among its complaints. — [search summary of Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)
- Developer reply on the borderless thread: "there is a bug with that fullscreen option in settings where it stretches the current windowed resolution. We'll fix that in a patch, but in the meantime alt+enter or the maximise button on windows/mac will fullscreen correctly at the native resolution." — [Steam discussion "borderless fullscreen windowed"](https://steamcommunity.com/app/3483740/discussions/0/603029962779271706/) (via search snippet)
- Player suggestions (5 May 2025, demo): an option to reset or lock window size, and a frame rate cap (the game ran at 144 fps on a 60 Hz screen). The game seemed to start always-on-top in windowed mode, fixed by toggling fullscreen. Developer: "Nice suggestions, thanks!" — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/603029525548241085/)
- Complaint: "FPS limiter stops at 144". — [Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)
- Steam store tags include "Desktop Companion" and "Idler". — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- v1.2.4 fixed a macOS input issue in laptop full-screen. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)

### Inferences
- The "desktop" use is just a freely resizable normal window, not a special overlay mode. That leaves room for a competing game to offer a true strip, always-on-top or transparency mode.

### Gaps
- Not found: always-on-top as a setting, transparency, a bottom-strip or taskbar mode, size presets, click-through, or a multi-monitor picker. Whether the window-size reset and frame cap suggestions were implemented was not found.

## 5. Collection and codex (fish, spots, legendaries, journal, trophies)

### Takeaway
The fish book (logbook/encyclopaedia) tracks species, catch counts, size classes, location, bait and personal bests, and since v1.2.4 also the time of day of the best catch. Launch had 50 species, 13 spots and 13 legendaries. The store now says 50+ fish, 16 spots and 16 legendary fish. Each spot has a legendary that appears at specific places and times, and every species has a hidden trophy size.

### Cited Findings
- "50 species of fish". Each record tracks catch counts, growth size, location, bait and personal best. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- At launch: 50 species and 13 legendary fish that appear at certain times of day. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- Now: "50+ fish", "16 legendary fish", 16 spots. — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/). The press kit says "50 fish" and 16 legendaries. — [Press kit](https://www.wombatbrawler.com/cnc-press-kit)
- Conflict: the pre-launch press release (Feb 2025) promised "100+ common, rare, and legendary fish species". — [Press release](https://www.gamespress.com/Announcing-Cast-n-Chill---Cozy-Idle-Fishing---Coming-June-2025). The game shipped with 50.
- Autumnwood added 8 species (2 legendary). — [NostalPix](https://nostal-pix.com/?p=2180&lang=en). This would put the total near 58, but the press kit still says 50. Not reconciled.
- Endgame per a player: legendary fish at specific spots and times, trophy-size versions of regular fish (heavier and faster, not identifiable until caught), and completing every size class in the encyclopedia. — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/807952395548162442/)
- v1.2.4 added an achievement for catching every size of every species. Biggest-catch entries now show dawn, day, dusk or night. Tips for unlocking spots appear on the map. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/)
- Legendary trophy fish go on Rusty's shop wall (achievement "Legendary White Tip: land a Walleye big enough for Rusty's shop wall"). — [Steam achievements](https://steamcommunity.com/stats/3483740/achievements)
- Old Moose Cabin (28 May 2026, free) adds replica trophies of your catches displayed in the cabin, "from your first fish to your biggest". — [Perfectly Nintendo](https://www.perfectly-nintendo.com/cast-n-chill-switch-switch-2-all-the-updates/)
- Fish named on the unofficial wiki include brook trout, rainbow trout, largemouth bass, channel catfish, chinook salmon, northern pike, muskie, bluegill, white sturgeon and pacific halibut. — [castnchill.unpack.wiki](https://castnchill.unpack.wiki/)
- Nintendo Life: "Pixel fish encyclopaedia is a joy to fill out". — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)

### Gaps
- Exact current species total was not found. The full species list was not verified.

## 6. Companions and NPCs

### Takeaway
A pettable dog rides in the boat and barks or helps you spot fish. The breed is chosen at the start. More companions arrived in updates (dachshund, St. Bernard) and in a paid Supporter Pack (Bernese Mountain dog or Maine Coon cat). The main NPC is Rusty at Rusty's Bait n' Tackle, who buys fish, sells gear, and trades rumours for tips. "Ol' Hank" is referenced in an achievement.

### Cited Findings
- The dog helps you spot fish. — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/). It stays beside you and can be petted. The reviewer believes petting makes it bark more readily near good fish, but admits this may be their own interpretation. — [Vice](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/)
- You choose a breed. The reviewer picked a corgi. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- Achievement "Good Friends": pet your companion 10 times in one session (56.8%). — [Steam achievements](https://steamcommunity.com/stats/3483740/achievements)
- Dachshund ("hops into your boat") came with Autumnwood (Sep 2025). — [NostalPix](https://nostal-pix.com/?p=2180&lang=en). St. Bernard came with the Winter Update (Nov 2025). — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)
- Supporter Pack: a Bernese Mountain dog or a Maine Coon cat. — [search summary of stmstat/Steam DLC listing](https://stmstat.com/app/3817870). Golden retriever, corgi, dachshund and Maine Coon are named on the unofficial wiki. — [castnchill.unpack.wiki](https://castnchill.unpack.wiki/)
- NPC Rusty (bait shop, tips reveal secrets). — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score). "Ol' Hanks's lost trophy King Salmon" appears in an achievement. — [Steam achievements](https://steamcommunity.com/stats/3483740/achievements)
- Shacknews lists "You can pet the dog" among its pros. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)

### Gaps
- The dog's full set of behaviours (idle animations, reactions) was not documented. No other NPCs were found.

## 7. Ambient life, animation, environment

### Takeaway
Each spot has its own wildlife: grizzly bears, otters, an owl, seals by name, and eagles by name. There are waterfalls, drifting leaves and snowy mountains. The water rendering gets heavy praise. Time of day (dawn, day, dusk, night) exists and can be changed by the player. A winter or ice biome exists, but as a separate location rather than a season.

### Cited Findings
- 16 spots "each with its own wildlife". — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- Grizzly bears are listed as a pro. — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Shallows Edge has drifting leaves, an owl and snow-capped mountains. Otter Cove has rocks, driftwood, a small waterfall and a family of otters. — [NostalPix](https://nostal-pix.com/?p=2180&lang=en)
- Frostbite Flats has waterfalls and wildlife. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)
- Water effects "hold up under long inspection". "It's like a painting, the longer I look at it, the better it looks." — [Vice](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/)
- "the most striking pixel art I've ever seen". "Excellent visual variety". — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- Time of day: dawn, day, dusk and night are recorded in the fish book. — [Steam announcements v1.2.4](https://steamcommunity.com/app/3483740/announcements/). Achievement "Nap Time: change the time of day" (64.7%) shows the player can change the time. — [Steam achievements](https://steamcommunity.com/stats/3483740/achievements)
- Legendaries appear at certain times of day. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)

### Gaps
- Not found: weather (rain or storms), a seasonal cycle, deer or ducks specifically, or whether time passes in real time or on a game clock.

## 8. Audio

### Takeaway
Banjo, lo-fi bluegrass music, praised alongside the water and reel sounds. Audio options were thin at launch (no sliders), and a master volume slider was added later. 5.1 surround is supported (a bug was fixed in v1.2.4).

### Cited Findings
- "lo-fi bluegrass soundtrack", "a subtle and soothing southern-tinged score". — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- "More games need banjo music." — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Sound design is "the game's strongest element": water sounds as the boat moves, quiet stretches, reel sounds. — [Vice](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/)
- Complaint: "No audio sliders". A later patch added a master volume slider (per the review summary). — [Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)
- v1.2.4 fixed 5.1 surround sound. — [Perfectly Nintendo](https://www.perfectly-nintendo.com/cast-n-chill-switch-switch-2-all-the-updates/)
- On Switch, floats and spinners give rumble feedback. — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)

### Gaps
- Composer, track count, a radio or music player, and separate music and SFX sliders were not found.

## 9. Customization and cosmetics

### Takeaway
At launch the angler's look was randomised. A character customiser came in Nov 2025, with new outfits in Dec 2025. Companions are chosen. The Old Moose Cabin (May 2026) adds a restorable and customizable home base with a pond you stock yourself.

### Cited Findings
- The angler was randomised at the start (launch). — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
- Winter Update (30 Nov 2025): the customiser lets you choose your look instead of randomising it. Co-op update (18 Dec 2025): new outfits. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)
- Old Moose Cabin: restore and customize the cabin, fish from the dock, choose which species live in the pond, display replica trophies. — [Perfectly Nintendo](https://www.perfectly-nintendo.com/cast-n-chill-switch-switch-2-all-the-updates/); [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/). An unofficial guide says the pond must be fully cleaned before use (v1.3.1 fixed debris not spawning, which had blocked full cleaning). — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/)
- The cabin idea had been suggested by a player (Aug 2025): "a cosmetic fisher's cabin for displaying legendary catches". — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/807952395548162442/)

### Gaps
- Boat colours, hats or a cosmetic shop were not found.

## 10. Achievements, Steam features, platforms

### Takeaway
38 Steam achievements as of Oct 2026 (24 reported earlier, with more added by updates). Steam Cloud, full controller support, Steam Deck Verified, local and split-screen co-op with Remote Play Together, Family Sharing. Runs on Windows and macOS. Nintendo Switch and Switch 2 (Switch 2 Edition is a free upgrade with 120 fps) since 18 or 19 Dec 2025. 12 languages.

### Cited Findings
- The Steam global achievements page reports 38 achievements (23 rare). — [Steam stats](https://steamcommunity.com/stats/3483740/achievements). Earlier count of 24. — [WeMod via search](https://www.wemod.com/ko/cheats/cast-n-chill-trainers/achievements). The count grew with updates.
- Sample achievements: Gone Fishin', Nap Time, Good Friends, Feeding Frenzy (lure 5 fish at once), It's You Again (catch a released fish), The One That Got Away (lose a fish after a 2-minute fight), Above Board and Over Achiever (catch L or XL fish without looking below the surface), Ice Breaker, Fish Finder (all species, 8.9%), Live Bait (catch a fish using another fish), plus about 13 "Legendary ..." achievements. — [Steam stats](https://steamcommunity.com/stats/3483740/achievements)
- Steam features: single-player, shared/split-screen co-op, achievements, Steam Cloud, Remote Play on TV and Remote Play Together, Family Sharing, controller support. Windows 10 64-bit / macOS 10.9+. 4 GB RAM, 256 MB storage. — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- Steam Deck Verified. Full controller support, DualShock and DualSense. — [Steambase](https://steambase.io/games/cast-n-chill/info). A player played 90% of it on Deck, "pretty perfect for that". — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/807952395548162442/). Battery drain was reported on Deck (about 2 h from 80% to 15%). — [search summary of Steam Deck thread](https://steamcommunity.com/app/3483740/discussions/0/838346321940271033/)
- Languages (12): English, French, Italian, German, Spanish, Japanese, Korean, Simplified and Traditional Chinese, Brazilian Portuguese, Russian, Turkish. — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- Switch and Switch 2: the press kit says 19 Dec 2025. — [Press kit](https://www.wombatbrawler.com/cnc-press-kit). Nintendo Life says 18 Dec 2025 at \$14.99 / £12.79, 2-player local co-op, 120 fps and better resolution on Switch 2 as a "welcome (and free)" upgrade. — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition). The one-day gap is probably a time-zone difference.
- Co-op ("Boat Buddy"): a friend fishes with you, side by side or in competition. — [Press kit](https://www.wombatbrawler.com/cnc-press-kit). It was added 18 Dec 2025. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)

### Gaps
- Switch 2 mouse controls and GameChat were not found. Whether Switch has idle or offline progress was not found.

## 11. Settings and quality of life

### Cited Findings
- Idle settings: the start delay and which fish idle targets. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/). An auto-lure option exists. — [castnchillwiki](https://castnchillwiki.com/guide/idle-mode/) (unofficial)
- Launch complaints: no audio sliders (master slider added later), FPS limiter stops at 144, "Lots of wasted screen space" in menus. — [Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)
- v1.2.4 QoL: open the map while on the water, map tips for unlocking spots, camera returns to the angler after a long cast in "above water" mode, better controls screen for keyboard and gamepad, gamepad B closes the tackle changer, and you can no longer cast when storage is full. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/)
- "Above water" mode (only the surface view) exists as an option, and achievements reward catching big fish without looking below. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/); [Steam achievements](https://steamcommunity.com/stats/3483740/achievements)
- Fullscreen toggle (alt+enter). — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/603029962779271706/)

### Gaps
- A full settings menu list was not found.

## 12. Price, DLC, updates, demo

### Takeaway
\$14.99 USD / CDN\$19.49. A Supporter Pack (about US\$2.99, extra companions) launched with the game. A paid DLC, Eastern Winds (East Asian theme), still shows "To be announced" on Steam as of Oct 2026, although trackers list June 2026. There was a steady run of free updates. A demo existed before launch, and idle mode was added to it in May 2025.

### Cited Findings
- Price \$14.99. — [Press kit](https://www.wombatbrawler.com/cnc-press-kit). CDN\$19.49 base, 33% off during the current promo ending 28 Oct. Bundles with DREDGE and "over the hill". — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
- Supporter Pack CDN\$3.89 (US\$2.99 per a Nintendo Life reader). — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/); [Nintendo Life comments](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)
- Eastern Winds: "To be announced", no price. Contents: 8 handcrafted spots, "a couple dozen new fish species", new boat companions, new rods, lures and gear. Shrines, misty lakes, bamboo. — [Steam DLC page](https://store.steampowered.com/app/4001650/Cast_n_Chill__Eastern_Winds/). Conflict: Steambase lists it as released 16 Jun 2026. — [Steambase](https://steambase.io/games/cast-n-chill/info). Director Mark White in Sep 2025: it "will lean even further into a calm, zen meditative experience", targeted at June 2026. — [NostalPix](https://nostal-pix.com/?p=2180&lang=en)
- Update timeline:
  - Launch, 16 Jun 2025 (WellPlayed says 17 Jun, probably Australian time). — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/)
  - Autumnwood Lake, about Sep 2025. — [NostalPix](https://nostal-pix.com/?p=2180&lang=en)
  - Lake Hunkerdown Winter Update, 30 Nov 2025.
  - Co-op + Outfits, 18 Dec 2025.
  - Switch/Switch 2 release, 18 or 19 Dec 2025.
  - v1.2.4, 3 Mar 2026.
  - Old Moose Cabin, 28 May 2026.
  - v1.3.0 hotfix (translations, a cabin achievement).
  - v1.3.1, 19 Oct 2026.
  - Sources for the above: [Steam announcements](https://steamcommunity.com/app/3483740/announcements/); [Perfectly Nintendo](https://www.perfectly-nintendo.com/cast-n-chill-switch-switch-2-all-the-updates/) (Perfectly Nintendo dates the cabin 28/29 Jun 2026 for Switch).
- Demo: idle mode came in a demo update about 29 May 2025. — [Steam discussion](https://steamcommunity.com/app/3483740/discussions/0/603031542017596599/). Announced at Steam Idler Fest, 3 Feb 2025. — [Press release](https://www.gamespress.com/Announcing-Cast-n-Chill---Cozy-Idle-Fishing---Coming-June-2025)
- Follow-up game: Wild n Chill (a wilderness survival game with hunting, fishing, crafting, cabin building and up to 4-player co-op) was announced 28 May 2026, and its demo came out 7 Aug 2026. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/)
- Steam Awards 2025: campaigned in the "Sit Back and Relax" category. The result was not found. — [Steam announcements](https://steamcommunity.com/app/3483740/announcements/?p=2)

## 13. Reception: scores, praise, complaints

### Takeaway
Steam reviews are Overwhelmingly Positive at 95% of 5,283 English reviews, or about 95% of roughly 7,400 to 7,900 across all languages. Critics give 8 to 9 out of 10. People praise the pixel art, water, sound, two-button simplicity, optional idle mode and the dog. They complain about thin content and short length for the price, shallow upgrades, repetitiveness, blurry fish that are hard to identify, tedious boat movement, and sparse settings.

### Cited Findings
- Steam: Overwhelmingly Positive, 95% of 5,283 English reviews. Recent: 93% of 182. — [Steam store](https://store.steampowered.com/app/3483740/Cast_n_Chill/). A tracker counts 7,934 total reviews (7,535 positive / 399 negative). — [search summary of stmstat](https://stmstat.com/app/3483740/reviews). Vaporlens (9 May 2026): 7,406 reviews, 4.8% negative. Negative themes: "Limited game content", "High price concerns", "Repetitive gameplay". — [Vaporlens](https://vaporlens.app/app/3483740/cast_n_chill/stats/details)
- Critics: Shacknews 9/10, WellPlayed 9, Nintendo Life 9/10 (Switch 2), Noobfeed 82, Peapod Girl Gaming 5/5. Metacritic user score 7.2 (32 ratings). — [search summary](https://www.metacritic.com/game/cast-n-chill/); [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score); [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition). Vice verdict: "Best In Its Class". — [Vice](https://www.vice.com/en/article/cast-n-chill-is-an-idle-and-active-fishing-game-that-has-become-my-new-go-to-when-i-want-to-relax-review/)
- Praise quotes:
  - "Looks and sounds perfect, nails the vibe", "Very addictive upgrade and unlock loop". — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)
  - "Sensational in its simplicity", "Well-implemented idle mode". — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
  - "Cast n Chill knows what it's trying to do, and it doesn't waver from that path." — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Critic complaints:
  - "Repetitive and fairly simplistic by its very nature, so YMMV". — [Nintendo Life](https://www.nintendolife.com/reviews/nintendo-switch-2/cast-n-chill-nintendo-switch-2-edition)
  - "There's little to do after completing the logbook". — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/)
  - "Some pixel art is a tad blurry". "couldn't tell which kind of fish I was looking at under the water". Boat repositioning: "It's as exhausting as it sounds." — [Shacknews](https://www.shacknews.com/article/144913/cast-n-chill-review-score)
- Player complaints:
  - Alexx (7.8 h): "Not a great price value".
  - Jasta (7.0 h): about 6 h of content.
  - thorny: "Fishing manually doesn't feel satisfying".
  - Ol Jackie Boy: "There is no retrieval at all", meaning no lure retrieve technique.
  - Phenomenological: fish lack distinguishing features.
  - Call Me Oreo: "Not really worth the money".
  - Source for all of the above: [Steam negative reviews](https://steamcommunity.com/app/3483740/negativereviews/?browsefilter=toprated)

## 14. Sales and revenue estimates

### Takeaway
No official figures were found. Third-party estimates disagree widely: roughly 170K to 500K Steam units and US\$1.7M to \$4.9M gross.

### Cited Findings
- Raijin.gg (26 Jun 2026): 172.2K copies, \$1.7M. Datahumble: about 252K, \$3.8M. Sensor Tower: about 496K units, about \$4.9M. Vorythic: 333K (range 266.6K to 400K). Games-stats: about \$2.2M. — [Raijin](https://raijin.gg/app/3483740/Cast_n_Chill); [Datahumble](https://datahumble.com/cast-n-chill-3483740); [Sensor Tower](https://app.sensortower.com/vgi/game/cast-n-chill); [Vorythic](https://vorythic.com/games/2647/cast-n-chill); [Games-stats](https://games-stats.com/steam/game/cast-n-chill/)
- Studio: an "Aussie-based, two-person studio", and this is its debut title. — [WellPlayed](https://www.well-played.com.au/cast-n-chill-review/). Director: Mark White. — [NostalPix](https://nostal-pix.com/?p=2180&lang=en)

### Inferences
- About 8,000 Steam reviews, at common review-to-sales multipliers of 30 to 60x, suggests roughly 240K to 480K units. That fits the middle of the estimates. This is a rough heuristic, not data.

### Gaps
- Developer-stated sales milestones were not found. A Wikipedia article was not checked or found.
