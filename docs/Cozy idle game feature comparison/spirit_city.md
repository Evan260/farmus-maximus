# Spirit City: Lofi Sessions: complete feature set (researched 24 Oct 2026)

Source shorthand used below:
- STORE = [Steam store page](https://store.steampowered.com/app/2113850/Spirit_City_Lofi_Sessions/)
- APPDETAILS = [Steam appdetails API, US region](https://store.steampowered.com/api/appdetails?appids=2113850&cc=us) (fetched 24 Oct 2026)
- NEWS = [Steam news feed for app 2113850](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2113850&count=100&format=json) (91 posts, Aug 2023 to Aug 2026). Individual posts are cited by date and title.
- ACH = [Steam global achievement percentages API](https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=2113850)
- NEG = [Steam community negative reviews, English, top rated](https://steamcommunity.com/app/2113850/negativereviews/?browsefilter=toprated&filterLanguage=english)
- POS = [Steam community positive reviews, English, top rated](https://steamcommunity.com/app/2113850/positivereviews/?browsefilter=toprated&filterLanguage=english)

## 1. Core loop: productivity features, spirit collecting, how progression is earned

### Takeaway
The game is a "gamified focus tool": you set up an avatar in a cozy room, run built-in productivity widgets (to-do list, session timer, habit tracker, journal, and since 2026 reminders), and the game pays you XP and a soft currency (Spirit Credits). The collectible "Spirits" are lured by matching a specific combination of room spot, activity, time of day (lighting) and soundscape, then waiting. Daily XP comes mainly from one-per-day bonuses (login, first task, first timer), not from volume of work, which is a recurring criticism.

### Cited Findings
**Pitch and tools**
- Store pitch: a gamified focus tool with a lofi soundtrack. Built-in productivity tools: to-do list, session timer, habit tracker and journal. "Earn XP and level up for practicing good habits," which unlocks cosmetics and hints for finding Spirits. — STORE
- The demo (3 Nov 2023) already had lofi beats, avatar creation, Spirit companions, a Pomodoro timer and a to-do list. — NEWS, "Demo Now Available!" (2023-11-03)
- Timer at launch defaulted to 15-minute sessions with 5-minute breaks; durations adjustable; sessions can be skipped or paused. Journal supports free writing or prompts (things to look forward to, mental and physical health steps). Habit tracker tracks unlimited habits by day. — [LadiesGamers review, 11 Apr 2024](https://ladiesgamers.com/spirit-city-lofi-sessions-review/)
- Launch-era timer limits: "it cannot run indefinitely, max 5 repeats"; no projects, no per-task time tracking, no activity history. — NEG, 73.0 hrs, 29 Apr 2024
- Timers can be linked to tasks; "tasks give you that juicy serotonin with sound FX." — POS, 83.9 hrs, 4 Jun 2024
- Session timer redesigned in v1.9 (12 May 2025): clearer display of how sessions are split, new Stopwatch mode, new Timer mode, new "Timer tools" settings tab; ring audio fading adjusted so it stays audible over other sounds. Hotfix 1.9.1 (21 May 2025) added further requested timer features after player feedback. — NEWS, "Spring Update and MacOS support now available!" (2025-05-12); "Hotfix 1.9.1" (2025-05-21)
- v2.1.0 Halloween (29 Sep 2025) productivity upgrades: tracker graph of total playtime and total focus time with week/month/year filters; habits save automatically and no longer need weekly wiping; clock widget moved into productivity section and toggleable; Journal and Habits widgets are resizable and movable; to-do lists gained a progress bar, "reset all" button, sorting by due date or state; hold-to-delete for journal entries. — NEWS, "Halloween update is now LIVE!" (2025-09-29)
- Winter update (17 Nov 2025): timer can use different sound sets; with "prompt before continuing" on, the timer ring loops until you press the timer; most delete actions in productivity tools require holding. — NEWS, "Winter Update now live!" (2025-11-17)
- Lofi Girl update (25 May 2026) added "Reminders" in timer tools: custom on-screen messages at set times, daily. Hotfix 2.4.1 added a setting to auto-dismiss reminders and controller input for reminder pop-ups. — NEWS, "The Lofi Girl Update is available now for FREE!" (2026-05-25); "Hotfix 2.4.1" (2026-06-01/04)

**Spirits and how they appear**
- Spirits are lured by "different combinations of room activities, soundscapes, and decor"; hints help; Spirits can be petted. — STORE
- Luring requires a specific combination of Activity, Sound and Lighting (some need only one); the Spiritdex glows when the combination is right; you then wait for the Spirit to appear; clicking a Spirit plays an animation and shows its history and quirks. Higher levels unlock hints. — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/)
- Spiritographer level unlocks one-line riddle hints; a Spirit appears only when spot, activity, time of day and soundscape all match. — [EarlyGuides](https://earlyguides.com/spirit-city-lofi-sessions) (low reliability: the site also mentions weapons, combat and bosses, which do not exist in this game)
- "About once an hour a new spirit shows up." Only one Spirit companion can be out at a time, "entirely aesthetic." — NEG, 34.0 hrs, 29 Dec 2025
- Spirits "are essentially furniture with eyes. You can pet them... there is no feeding, playing, nothing." — NEG, 5.2 hrs, 2 Aug 2026
- Winter 2025 added a "Playing by the Fireplace" activity where the avatar plays with the Spirit, with a unique animation per Spirit. — NEWS (2025-11-17)

**XP and currency**
- XP from daily goals: login, task done, timer done; each daily goal gives 100 XP (launch-era). — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/)
- "You get XP from your first log-in of the day, from the first task you complete off your to-do list per day, and from your first pomodoro timer use per day. I am disappointed that checking more things off your to-do list doesn't get you XP." — NEG, 34.0 hrs, 29 Dec 2025
- Spirit Credits (SC) buy furniture, clothing and Spirit skins. Each level-up gives 500 SC; you earn 1 SC per minute played; discovering Spirits gives a lot of XP; players can now level past 50. — [GameGrin, 3 May 2026](https://www.gamegrin.com/articles/how-do-you-get-spirit-credits-in-spirit-city-lofi-session/). Partly contradicted by LadiesGamers, which said credits are earned by completing tasks.
- Since v2.0, discovering a DLC Spirit grants 500 SC (not retroactive). — NEWS, "Spirit City: All Aboard! Now Available!" (2025-08-25)
- A friend "sat the game idling for days (refreshing each day to get the bonus exp) in order to get the level 50 achievement (approximately 245 hours)." — NEG, 289.7 hrs, 10 May 2024
- v1.4 (Aug 2024) added a "preview items before purchasing" feature. — NEWS, "Major Update Coming August 26th!" (2024-08-05)

### Inferences
- The progression economy is mostly time-gated: passive SC per minute plus once-per-day XP bonuses. This rewards keeping the app open, not doing more work, which several reviewers call a mismatch with the productivity framing.
- Spirit discovery is a light puzzle (combination plus wait), essentially a "set the scene and leave it running" mechanic. That maps well to a lavender-farm idle game, e.g. visitors or creatures attracted by a combination of crop, weather and time.

### Gaps
- Exact XP curve per level, current level cap (if any), and current XP values after 2025 to 2026 changes: not found in official sources.
- Whether time-of-day for luring uses the real clock or only the in-app lighting selector: LadiesGamers implies an in-app selector; no official statement found.

## 2. Progression and unlocks: spirit counts, decorations, rooms, cosmetics, pacing

### Takeaway
Base game has 24 Spirits with Steam achievements (plus later additions such as Pocky from the Lofi Girl update). Four paid room DLCs each add a new scene and 3 to 13 Spirits or variants. More than 1,000 bedroom items existed by the first anniversary. Players report finding all base Spirits in roughly 15 to 30 hours; the long tail is level achievements and unlocking every item (270+ hours).

### Cited Findings
- 34 Steam achievements total. — APPDETAILS
- Achievement list (global unlock %): Complete tutorial 98.7%, Level 2 90.8%, Pet a Spirit 83.6%, first To-do 68.8%, first Pomodoro 63.8%, Level 10 59.5%, Level 20 40.4%, Level 30 25.9%, Level 40 15.7%, Level 50 10.3%, plus 24 "Find Spirit" achievements from Goopii (83.6%) and Dustbunny (67.9%) down to Catsudon (20.1%) and Deermuff (14.9%). The 24 base Spirits with achievements: Goopii, Dustbunny, Chapterpillar, Hedgelog, Arachknit, Earlybirb, Moonpaw, Drizzlefin, Kettlebrew, Inkster, Vootodoo, Bulbee, Trashnuki, Sunquill, Bobapole, Waxolotl, APE-Bit, Hamstereo, Flutterfrog, Hexwing, Twintail, Bloomscale, Catsudon, Deermuff. — ACH
- A 2024 review counted 15 spirits at that time. — [search summary of a 2024 review](https://checkpointgaming.net/news/2024/04/spirit-city-lofi-sessions-brings-gamification-to-your-lofi-beats/) (count from search snippet, not verified on page)
- First anniversary (8 Apr 2025): 8 updates, 10 new Spirits, 9 Spirit variants, over 1,000 bedroom items added since launch. — NEWS, "1 Year Anniversary" (2025-04-08)
- Free Spirit additions over time: v1.2.0 (30 May 2024) three new Spirits with colour variants and achievements; Halloween 1.5.0 (Oct 2024) a new Spirit; Winter Wonderland (Nov 2024) a new Spirit; v1.9 Spring 2025 a new Spirit; v1.11 Summer 2025 a "secret" new Spirit; Winter 2025 one winter Spirit with an achievement; Lofi Girl update (May 2026) Pocky, Lofi Girl's cat. — NEWS posts of those dates
- Spirit skins: 22 Spring cherry-blossom skins for all base-game Spirits plus 2 Kitsune Twintail skins (v1.9); Halloween skins for 7 Spirits (v2.1.0); paid Winter Spirit Cosmetics Pack (Nov 2024). — NEWS (2025-05-12, 2025-09-29, 2024-11-27)
- DLC Spirits: Cozy Kitchen 3 new Spirits plus 9 variants (e.g. Capybun, Squire Sprout, Bentobunny, Toast-mate); All Aboard! 11 new companions (e.g. Coorier, Aviotter); Enchanted Garden 13 new companions (e.g. Garden Guardian, Bellblossom); Magical Library 13 new Spirits (e.g. Mantapedia, Kindlestar, two dragons, owls, mice). — [Game Developer press release](https://www.gamedeveloper.com/press-release/spirit-city-lofi-sessions-cozy-kitchen-expansion-now-available-); NEWS (2025-08-25, 2026-03-23, 2026-08-24)
- Room decoration categories added in v1.4 (Aug 2024): ceiling, wall decor, side table, outside-window scenery, hundreds of items. — NEWS, "Update 1.4 Now Available!" (2024-08-26)
- Scenes and rooms: base bedroom (with many swappable outside-window backgrounds, e.g. cherry blossom in v1.9, 8 new bedroom backgrounds in Winter 2025, Lyon cityscape in May 2026, static train scenery as a bedroom background for base owners), plus DLC Kitchen, Train cabin (with observation deck and moving backgrounds: countryside, cloudscapes, underwater, outer space), Garden and greenhouse, Magical Library (fireplace, arcane study, reading nook; styles: dark academia, academy, witch's lair). — NEWS (2025-05-12, 2025-11-17, 2026-05-25, 2025-08-25, 2026-03-23, 2026-08-24)
- Pacing reports: "it took me 30hrs until I got all the spirits (level 24)" (NEG, 34.0 hrs, Dec 2025); "the last spirit was found... about 15-20 hours in"; after 270+ hours "I've only unlocked the furniture and about half the spirit colours" (NEG, 289.7 hrs, May 2024); "You'll find all the little pets super quick, get bored with the clothes/decor super quick" (POS, 13.6 hrs, Jul 2024); achievements completion "around 300+ hours" (POS, 9,212 hrs, May 2024).

### Inferences
- Pacing is front-loaded: the "collect them all" goal ends in a day or two of open-app time, then only cosmetics and level grind remain. Paid room DLCs are the main way new collection goals are delivered.
- A design takeaway: the Level-50 achievement at 10.3% unlock shows a meaningful minority leave it running for hundreds of hours.

### Gaps
- Exact current total of base-game Spirits including secret and seasonal ones (the 24 achievement Spirits exclude some later additions such as Pocky): not found.
- Exact current item counts per category: not found beyond "over 1,000 bedroom items" (Apr 2025).

## 3. Idle and offline mechanics

### Takeaway
It is an "Idler"-tagged app that rewards being open (SC per minute, Spirits appear after waiting, daily login XP). There is no evidence of offline progress; reviewers say the Pomodoro does not resume after closing.

### Cited Findings
- Steam tags include Idler, Desktop Companion, Utilities, Organizing, Creature Collector. — STORE
- 1 Spirit Credit per minute played. — [GameGrin](https://www.gamegrin.com/articles/how-do-you-get-spirit-credits-in-spirit-city-lofi-session/)
- "I can't resume an ongoing pomodoro if I close the game"; "I still have to reopen all the widgets I need every time I start the game." — NEG, 529.3 hrs, 25 Apr 2026
- "The spirit feature rewards you by spending more time with the game open." — POS, 83.9 hrs, Jun 2024
- Hotfix 1.1.2 (Apr 2024): the game automatically drops FPS to a minimum when fully minimized; v1.1.0 added an FPS cap for when the game is unfocused. — NEWS (2024-04-28, 2024-04-22)
- Winter 2025 added an option to auto-start the last selected activity (off by default). — NEWS (2025-11-17)

### Inferences
- No offline accrual was found; progress depends on the app actually running.

### Gaps
- No official statement on offline progress found.

## 4. Window and display modes

### Takeaway
Windowed (freely resizable) and borderless/windowed fullscreen are available, plus an "Always on top" mode added in March 2025 (Windows only). A UI-hide hotkey turns it into a clean lofi scene. A dedicated mini-player or transparent desktop overlay was not found.

### Cited Findings
- Window modes at launch: windowed and windowed fullscreen, both resizable and minimizable; graphics options for resolution, sync and frame rate. — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/)
- "Always on top mode" added free alongside the Cozy Kitchen DLC (26 Mar 2025): "locks the game window on top of other windows." — [Game Developer press release](https://www.gamedeveloper.com/press-release/spirit-city-lofi-sessions-cozy-kitchen-expansion-now-available-)
- macOS gets all features except "Always on top," which is Windows-only; in Borderless fullscreen the window controls are hidden and reappear on hovering the top of the screen. — NEWS (2025-05-12)
- Hotfix 1.5.1 fixed window maximizing in windowed mode. — NEWS (2024-10-11)
- A user reported windowed mode capped at 1080 px height on a 4K screen at 200% scaling; the developer said you can double-click the bar to maximize or drag a corner to resize. — [Steam discussion (via search summary)](https://steamcommunity.com/app/2113850/discussions/0/4326348922707908207)
- UI Visibility toggle (default F1) hides nearly all menus except the timer; rebinding added in hotfix 1.1.2. — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/); NEWS (2024-04-28)
- Productivity widgets are movable and resizable (Journal and Habits since v2.1.0; hotfix 2.1.1 adjusted widget max resize values). — NEWS (2025-09-29, 2025-09-30)
- "Burn-in screen reduction feature" added in Settings (Mar 2026). — NEWS, "Enchanted Garden DLC Is Out Now!" (2026-03-23)
- Camera: "I can't even position the camera differently." Activities show close-up shots; "Full View" zooms out to the whole room. — NEG, 529.3 hrs; [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/)

### Inferences
- Burn-in reduction plus always-on-top indicate the developer treats "screen left on for hours" as a primary use case.

### Gaps
- Mini-player, transparent window, click-through, or taskbar-docked modes: not found (search hits for these belonged to other games such as Lofi Cozy Room).
- Explicit multi-monitor support statement: not found.

## 5. Customization: avatar, room, furniture

### Takeaway
Deep cosmetic customization of avatar (body sliders, head shapes, ears, hair, outfits, accessories, colour slots) and room (wallpaper, flooring, furniture, decor, ceiling, window scenery), with presets. Male and facial-hair options are criticized as thin.

### Cited Findings
- You design your character's look and room, including wallpaper, flooring, furniture and decor. — STORE
- Avatar presets: 5 save slots originally, 5 more added in the Magical Library update for up to 10 avatars. Character and room each have five presets; soundscapes have only one preset. — NEWS (2026-08-24); NEG, 5.2 hrs, Aug 2026
- Winter 2025: ears separate from head shape (8 ear styles), 6 new head shapes, new "Outfits" category overriding top and bottom (6 dresses), 4 tops, 3 shoes. Lofi Girl update: skin and eye colours moved to the standard 3-slot colour system. Garden update: hand accessory category, full-body outfits, antennae. — NEWS (2025-11-17, 2026-05-25, 2026-03-23)
- Colour customization on many items, with "reset to default colour" (v1.9). — NEWS (2025-05-12)
- Body: "only one androgynous body type, which can be adjusted for hip/waist and body fat"; "only 8 beards"; character customization "female oriented." — NEG, 5.2 hrs, Aug 2026
- "My skinny character just got a pot belly and widened slightly" with larger sizes. — NEG, 289.7 hrs, May 2024
- Collab cosmetics: Among Us items (free, Jun 2025); Lofi Girl playable character look and room set (free, May 2026). — NEWS (2025-06-26, 2026-05-25)
- Merch tie-ins: Youtooz plushes of Lenny (2024) and Dustbunny (2026); 3D-printable Lenny statue. — NEWS (2024-08-12, 2026-01-13, 2026-08-24)

### Gaps
- Exact current counts of hairstyles, outfits, furniture per category: not found.

## 6. Ambient life, animations, day/night, weather, scenes and activities

### Takeaway
The avatar performs looping activities at fixed spots (desk, bed, fireplace, bay window, plus DLC-specific ones), a Spirit sits nearby, lighting is selectable (morning, afternoon, evening, night), and soundscapes like rain or thunder can carry matching visual effects. Weather is a sound-plus-visual toggle, not a simulated system.

### Cited Findings
- Launch activities: fireplace (writing, knitting), bay window seat (reading, knitting), desk (drawing, writing, laptop), bed (relaxing, browsing). Lighting is an in-app choice of morning, afternoon, evening or night; in Full View the sun's effect moves across the floor. Some sounds have matching visuals toggled by a sparkle icon with a slider for intensity. Visual effects do not auto-update with time of day (e.g. fireflies keep glowing in Morning). — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/)
- Activities added later: Gaming and Meditating (v1.4, Aug 2024); Sweeping at the bay window (v1.9); Painting at desk and Reading by the fireplace (v2.1.0); Playing by the Fireplace with your Spirit (Winter 2025); guitar at the bay window (Lofi Girl, May 2026); DLC activities: chopping vegetables, cooking, washing dishes (Kitchen); exterior looking and observation deck (Train); planting, watering, brewing potions, guitar under the gazebo (Garden); elemental magic, wand spellcasting, cauldron potion brewing, typewriting (Library). — NEWS (2024-08-26, 2025-05-12, 2025-09-29, 2025-11-17, 2026-05-25, 2026-03-23, 2026-08-24); [Game Developer](https://www.gamedeveloper.com/press-release/spirit-city-lofi-sessions-cozy-kitchen-expansion-now-available-)
- Rain and thunderstorm soundscapes affect background visuals (e.g. a train background bug "with rain or thunderstorm soundscapes on"); snow falls in winter scenes (fix for "snow falling inside the train cabin"). — NEWS (2025-08-25, 2026-08-24)
- Train speed control and moving backgrounds in the train DLC. — NEWS (2025-08-25, 2025-08-27)
- Hair physics (Lofi Girl ponytail). — NEWS (2026-06-04)

### Gaps
- Real-time clock syncing of day/night: not found.
- Any autonomous NPC life beyond the avatar and one Spirit: not found.

## 7. Audio: music, soundscapes, integrations

### Takeaway
Curated lofi playlists (Homework Radio at launch, then 140+ Lofi Girl tracks in 7 playlists from Aug 2025, plus seasonal playlists), an in-game web browser for YouTube, a local music importer (Sep 2025), song favoriting and disabling, a stackable ambient soundscape mixer with per-sound volume, and since Mar 2026 the ability to open external playlists in Spotify.

### Cited Findings
- Curated lofi catalog with themed playlists; ambient sounds like rain and crackling fire; music is stream-friendly; built-in web player for more songs; Homework Radio music available until August 2028. — STORE
- Launch: 4 lofi playlists ("each with a few hours of music"); YouTube search inside the app; change, pause, shuffle. — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/); POS, 13.6 hrs, Jul 2024
- v1.2.0 introduced rotational playlists; v1.3 added "a permanent in-game music option instead of rotating playlists." — NEWS (2024-05-30, 2024-06-27)
- v2.0 (25 Aug 2025): 140+ new tracks from Lofi Girl in 7 playlists; favourite songs into a "liked songs" playlist; disable individual songs. — NEWS (2025-08-25)
- Homework Radio partnership was announced as ending 25 Aug 2025, then a new 3-year contract kept the tracks; Lofi Girl took shares in Mooncube Games and any Lofi Girl music added is permanent. — NEWS, "Music partnership update" (2025-08-10) and "Music Partnership Update - part 2" (2025-08-19)
- Seasonal and new playlists: Halloween (Odem Medo, Homework Radio, 2024), holiday (2024), spring 2025 playlist with 20+ songs, Lofi Girl Halloween 2025, Lofi Girl holiday 2025, Spring 2026 Lofi Girl, Medieval playlist (Aug 2026). — NEWS (2024-10-02, 2024-11-04, 2025-05-12, 2025-09-29, 2025-11-17, 2026-03-23, 2026-08-24)
- Local music importer (v2.1.0): choose a root folder, subfolders become albums; .mp3, .wav, .ogg (announcement also says .flac, inconsistent). — NEWS (2025-09-29)
- Music spectrum visualizer on the player, adjustable in settings (Winter 2025). — NEWS (2025-11-17)
- Spotify: "Ability to open external playlists in Spotify web or desktop app directly" (Mar 2026). Earlier, "no you can't use [the browser] to flip to Spotify." — NEWS (2026-03-23); POS, 13.6 hrs, Jul 2024
- Soundscapes at launch: rain, wind, thunder, fire, birds, nighttime forest, soft vinyl noise, sizzling, plus white, pink and brown noise. Added later: bird chirping (demo, Jan 2024), Kitchen Ambience, Tasty Bubbling, Dishwasher (Mar 2025), Bustling farm, Rustling leaves, Meditation (Mar 2026), clicky typewriting (Aug 2026); reviewers also mention waves, train, seagulls and background chatter. Any number can play at once. — [LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/); NEWS (2024-01-23, 2026-03-23, 2026-08-24); [Game Developer](https://www.gamedeveloper.com/press-release/spirit-city-lofi-sessions-cozy-kitchen-expansion-now-available-); NEG, 34.0 hrs and 5.2 hrs
- Fix: "Too many active soundscapes no longer cause songs to skip." — NEWS (2025-11-17)

### Inferences
- The music strategy moved from licensed rotating playlists to bring-your-own (YouTube browser, local files, Spotify hand-off), which answers the most common early complaint of too few songs.

### Gaps
- Exact current total track count across all playlists: not found (140+ Lofi Girl plus Homework Radio plus seasonal).
- Whether music is sold as a standalone soundtrack DLC: none found among the six DLCs.

## 8. Achievements, Steam features, platforms, settings and quality of life

### Takeaway
Windows and macOS (Apple Silicon only now), Steam Achievements (34), Trading Cards, Cloud, Family Sharing, Steam Deck "Playable." Official controller support arrived in March 2026. Settings cover graphics, FPS caps, UI colour and style, text scaling, save backups, burn-in reduction, and 10 languages.

### Cited Findings
- Platforms Windows and Mac, no Linux; categories: Single-player, Steam Achievements, Trading Cards, Steam Cloud, Stats, Family Sharing. — APPDETAILS
- Steam Deck compatibility: category 2 ("Playable"); notes say default controller config not fully functional and some interface text not legible; performant by default. — [Steam Deck compatibility report API](https://store.steampowered.com/saleaction/ajaxgetdeckappcompatibilityreport?nAppID=2113850&l=english)
- ProtonDB: Gold tier, trending Platinum, 50 reports. — [ProtonDB summary](https://www.protondb.com/api/v1/reports/summaries/2113850.json)
- Controller support "started but is not fully functional yet" (Nov 2025); "Officially supported controller support" plus a "Controller disable" setting (Mar 2026). — NEWS (2025-11-17, 2026-03-23)
- macOS support added 12 May 2025 (Unreal Engine 5; Mac and Windows saves cross-compatible). Intel Macs paused at v2.3.0 via a "macos" beta branch after the 2026 engine upgrade; Apple Silicon now runs natively. — NEWS (2025-05-12, 2026-06-04, 2026-08-24)
- Steam Community items (6 cards, 6 emoticons, 4 backgrounds) from 6 May 2024. — NEWS (2024-05-06)
- Languages: English, French, Italian, German, Spanish (Spain), Simplified Chinese, Japanese, Korean, Portuguese (Brazil), Russian (Russian added Nov 2025). — STORE; NEWS (2025-11-17)
- Settings and QoL: graphics menu and unfocused FPS cap (v1.1.0); minimized FPS drop and rebindable UI-hide key (1.1.2); additional graphics quality settings (v2.0); daily save backup (1.6.2) and progression backup (1.4.3); "Save" settings tab to locate local saves and backups (v1.9); Help section with FAQ, troubleshooting guide, Creators Guide (v2.1.0); UI rebuilt with colour customization, gradient or flat style, tooltip text scaling, buttons moved to bottom (Winter 2025); auto-start last activity; burn-in reduction (Mar 2026); auto-dismiss reminders (Jun 2026). — NEWS posts of those dates
- System requirements: Win 10/11, i5-8600 or Ryzen 5 3600, 8 GB RAM, GTX 960, 6 GB storage; macOS 14 and Apple M1 minimum. — STORE
- Known issues as of 28 Aug 2026: Windows 11 Smart App Control launch failure (error 11c7); Apple Silicon Macs may make other apps unusable while open. — NEWS, "Hotfix 2.5.1" (2026-08-28)
- Concurrent players at time of research: 1,265 (24 Oct 2026). — [Steam current players API](https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=2113850)

### Gaps
- Mobile or console versions: none found.

## 9. Developer, dates, price, DLC, post-launch updates

### Takeaway
Made by Mooncube Games (Montreal-area indie, three co-founders, grown to seven; now renamed Lofi Gaming after Lofi Girl took a stake). Full release 8 Apr 2024 with no Early Access. US price \$11.99; four \$7.99 room DLCs plus two cosmetic packs. A steady cadence of free seasonal updates and two paid expansions per year.

### Cited Findings
- Developer and publisher Mooncube Games; released 8 Apr 2024; US price \$11.99 (CDN\$14.99). — APPDETAILS; STORE
- No Early Access: a Summer Playtest launched 21 Aug 2023, a demo 3 Nov 2023 (Next Fest Feb 2024), and the full game on 8 Apr 2024. Launch post promised a year of free updates. — NEWS (2023-08-21, 2023-11-03, 2024-04-08)
- DLC (US prices): Supporter Pack \$5.99 (27 Jun 2024); Winter Spirit Cosmetics Pack \$4.99 (27 Nov 2024); Cozy Kitchen \$7.99 (26 Mar 2025); All Aboard! \$7.99 (25 Aug 2025); Enchanted Garden \$7.99 (23 Mar 2026); Magical Library \$7.99 (24 Aug 2026). — APPDETAILS for DLC app IDs 2374850, 3349330, 3210380, 3815280, 4242210, 4734690
- Store: "Expect new features and content throughout 2026!" — STORE
- Studio: team grew from three to seven; Lofi Girl owns shares, co-founders still hold shares (Aug 2025); Mooncube joined Lofi Gaming, Lofi Girl's games division (11 Aug 2025); developer "is now named Lofi Gaming" (Aug 2026). — NEWS (2025-08-19, 2025-08-11, 2026-08-24)
- Update timeline (versions): 1.1.0 Apr 2024; 1.2.0 May 2024; 1.3 Jun 2024; 1.4 Aug 2024; 1.5.0 Halloween Oct 2024; Winter Wonderland Nov 2024; 1.7 Lunar New Year Jan 2025; 1.8 with Cozy Kitchen Mar 2025; 1.9 Spring and macOS May 2025; Among Us collab Jun 2025; 1.11 Summer Jul 2025; 2.0 with All Aboard! Aug 2025; 2.1.0 Halloween Sep 2025; 2.2.0 Winter Nov 2025; 2.3 Enchanted Garden Mar 2026; 2.4 Lofi Girl update May 2026; 2.5 Magical Library Aug 2026; last hotfix 2.5.1 on 28 Aug 2026. — NEWS
- Magical Library was the most requested theme in a player survey; the studio runs annual surveys and Discord community challenges. — NEWS (2026-07-13, 2024-12-09, 2026-01-13)
- "Features and QOL are always free for everyone!" — NEWS (2026-03-23)

### Gaps
- No news posts after 28 Aug 2026 were found in the feed as of 24 Oct 2026, so any Halloween 2026 update was not found.

## 10. Reviews: score, praise, complaints

### Takeaway
"Overwhelmingly Positive," 97% of about 9,200 English reviews (15,429 total recommendations across languages), Metacritic 80. Praise centres on cozy art, music and soundscapes, all-in-one productivity, and real-life habit benefits. Complaints centre on shallow productivity tools, too few songs (early), XP not scaling with work, content running out after the Spirits are found, cosmetic DLC focus, resource use, and the in-game browser.

### Cited Findings
- English reviews: Overwhelmingly Positive, 97% of 9,183; last 30 days 97% of 205. — STORE
- Total recommendations (all languages): 15,429; Metacritic 80. — APPDETAILS
- 1,000+ reviews and "Overwhelmingly Positive" three days after launch. — NEWS (2024-04-11)

**Praise (quotes)**
- "This game has legitimately helped me start taking better care of myself." — POS, 2,783.8 hrs, May 2025
- "this helped me finish my ADHD assessment." — POS, 194.7 hrs, May 2024
- "I no longer have to have 4 tabs open in the browser"; "it's like creating your own lofi video to have in the background." — POS, 16.0 hrs, Nov 2024
- "A perfect relaxing idle game... to play in the background while working." — POS, 9,212.1 hrs, May 2024
- "I am dev. Most of the time, when working on this game, I use the game." — POS, 821.7 hrs, Apr 2024
- Feature request in praise: "Please add cat purring sound." — POS, 92.5 hrs, Apr 2024

**Complaints (quotes)**
- Content drop-off: "don't just give up on content after approximately 20 hours of useage and plonk a few level achievements at the end." — NEG, 289.7 hrs, May 2024
- Music repetition: "I heard the same song about 3 or 4 times in the space of an hour because it limits to one playlist." — NEG, 289.7 hrs, May 2024
- Performance: "it just drains all CPU+GPU power" (NEG, 0.8 hrs, Apr 2024); music "still skips whenever I launch something new" (NEG, 34.0 hrs, Dec 2025); laptop ran hot until frame rate lowered ([LadiesGamers](https://ladiesgamers.com/spirit-city-lofi-sessions-review/))
- XP design: "checking more things off your to-do list doesn't get you XP"; the game "motivates you to keep it on, and keep checking it to see if the next spirit has showed up, but not to actually be productive." — NEG, 34.0 hrs, Dec 2025
- Shallow tools: no calendar or alarm (NEG, 0.8 hrs, Apr 2024; reminders later added May 2026); to-do list "extremely basic... no archiving, ability to move to a different list"; browser livestreams fail and has no back/forward (NEG, 11.4 hrs, Apr 2025)
- In-app browser shows YouTube ads because "your ad-blocker isn't there." — POS, 13.6 hrs, Jul 2024
- Monetization: "It is closer to a bare bones dress up/decorating game"; DLCs called "lackluster." Developer reply quoted: "We have released 9 major free updates in the past year." — NEG, 346.7 hrs, May 2025
- Persistence and UI: must reopen widgets each launch; cannot resume a pomodoro after closing; only one pet out; cannot link a soundscape or spirit to a decor preset; "development focus is more of the superficial aspects." — NEG, 529.3 hrs, Apr 2026
- Player music not remembered on restart; only one soundscape preset versus five for character and room. — NEG, 5.2 hrs, Aug 2026
- Wanted more scenes: "different background options, such as a cafe or a picnic." — [GameSkinny review](https://www.gameskinny.com/reviews/spirt-city-lofi-sessions-review-an-interactive-wellness-journey-that-inspires/) (via search summary)

### Inferences
- Even negative reviewers have very high playtimes (289, 346, 529 hours), so the leave-it-running habit sticks even when people dislike the depth.

### Gaps
- A full statistical breakdown of complaint themes across all negative reviews was not possible. The Steam review JSON endpoint redirected, so only the top 10 positive and top 10 negative English reviews were read.

## 11. Revenue and sales estimates

### Takeaway
The developer reported over 300,000 copies sold by April 2025. AppMagic (Apr 2026) says it is "past \$5.3M" in its 2025 Idle ranking. The 450K-copies figure could not be firmly attributed.

### Cited Findings
- Over 300,000 copies sold and over 10,000 Steam reviews at the first anniversary (8 Apr 2025). — NEWS, "1 Year Anniversary" (2025-04-08)
- AppMagic, 28 Apr 2026: "Spirit City: Lofi Sessions, a cozy productivity companion, and Cast n Chill, a relaxed fishing Idle, are both past \$5.3M." Method: top-50 Idle-tagged Steam games by revenue, 2024 to 2026. — [AppMagic idle Steam games 2026](https://appmagic.rocks/research/idle-steam-games-2026)
- A fetch summary of the same AppMagic page also said Spirit City "has sold over 450K copies," but a second pass quoted only the \$5.3M sentence. Treat 450K as unverified. — [AppMagic](https://appmagic.rocks/research/idle-steam-games-2026)
- Comparable figures from the same article: IdleOn over \$22M in 2025; Cast n Chill close to \$6.8M total; The Farmer Was Replaced over \$4.5M in 2025; Rusty's Retirement over \$4.5M since Apr 2024; Bongo Cat over \$670K. — [AppMagic](https://appmagic.rocks/research/idle-steam-games-2026)

### Inferences
- AppMagic does not say whether \$5.3M is gross or net, includes DLC, or covers 2025 only versus lifetime; it is placed in the 2025 ranking section.

### Gaps
- Exact lifetime revenue, DLC attach rate, and wishlist numbers: not found.
