# Farmus Maximus: Phone services

Prices are in CAD.

What the Android version's native plugin has to offer for notifications and Google Play Games achievements. The game's side is built: `game/scripts/autoload/phone_services.gd` (`PhoneServices`) talks to a plugin singleton named `SlowSundayPhone` whenever `Engine.has_singleton("SlowSundayPhone")` finds one, and does nothing otherwise. A build without the plugin, and every computer, plays exactly as before.

## The plugin

A Godot 4 Android plugin (version 2: an `.aar` whose `GodotPlugin` subclass returns `SlowSundayPhone` from `getPluginName()`), with these methods marked `@UsedByGodot`:

| Method | What it does |
|---|---|
| `scheduleNotification(id: String, seconds: Int, title: String, text: String)` | Shows a notification in `seconds` seconds, even if the phone has closed the game meanwhile. One already waiting with the same `id` is replaced. Tapping it opens the game. |
| `cancelAllNotifications()` | Removes every notification the game has scheduled or shown. |
| `areNotificationsAllowed(): Boolean` | Whether the phone lets the game post notifications (`NotificationManagerCompat.areNotificationsEnabled()`). |
| `requestNotificationPermission()` | Asks for `POST_NOTIFICATIONS` on Android 13 and later. Older phones allow notifications without asking. |
| `openNotificationSettings()` | Opens the phone's notification settings for the game (`Settings.ACTION_APP_NOTIFICATION_SETTINGS`). |
| `unlockAchievement(id: String)` | Unlocks a Play Games achievement by its Play Console id. One asked for before sign-in has finished is kept and sent once it has. |
| `signIn()` | Signs the player in to Play Games if they are not already. The game calls it once at every start, so it must not ask a player again who has turned it down. |

Building it:

- The plugin's manifest declares `android.permission.POST_NOTIFICATIONS`, one notification channel for the farm, and `com.google.android.gms.games.APP_ID` holding the game's Play Games project id.
- WorkManager's `enqueueUniqueWork(id, REPLACE, ...)` with an initial delay keeps a notification through the game closing and the phone restarting. The time does not need to be exact.
- Android shows a notification's small icon as a white silhouette, so it needs its own one-colour drawable.
- Play Games Services v2: `PlayGamesSdk.initialize()` at start, `PlayGames.getGamesSignInClient()` for `isAuthenticated()` and `signIn()`, and `PlayGames.getAchievementsClient().unlock()`.
- An Android plugin needs the Gradle build: Project > Install Android Build Template, then Use Gradle Build in the Android preset, which downloads Gradle and Google's libraries on the first export.

## When the farm sends notifications

`PhoneServices` works them out when the phone puts the game away (`NOTIFICATION_APPLICATION_PAUSED` or `NOTIFICATION_APPLICATION_FOCUS_OUT`, when `save_service.gd` also saves), and cancels them all when the game comes back or starts again. `game/scripts/game/phone_notices.gd` plans them:

| Id | Title | When |
|---|---|---|
| `cart` | The cart is home | The cart is on the road: when its trip ends, with the sestertii it brings. Trips last 7 to 20 seconds, so this only comes for a game put away just after sending the cart. |
| `full` | The storehouse is full | The storehouse and the parked cart fill up, counted as full once fewer than 3 places are left (or a twentieth of all they hold, if that is more), since a plant or batch that does not fit whole waits. A copy of the farm is played the way the catch-up plays it for one in-game day (20 minutes of farm time at most), and a farm that fills later is reckoned from how fast it filled meanwhile. A farm already full when put away is not announced. |
| `build_villa`, `build_<upgrade>`, `build_<building>` | The farmhouse stage, improvement or building | The builders finish a farmhouse stage, a farm improvement (storeroom, aqueduct channels, paved road) or a building's repair or upgrade. Builders rest at night, so the nights are counted in. |

Nothing is scheduled past `offline.max_hours` (12 hours), after which the farm stops counting time away, and nothing at all while Progress while the game is closed is off. Settings > Notifications, shown only on phones (`--phone` shows it on a computer), turns each kind on or off and offers to ask the phone for permission, or opens the phone's settings once it has been asked. The numbers are under `notifications` in `game/data/balance.json`.

## Google Play Games

1. A Google Play Console developer account: about \$35 (US\$25), paid once.
2. Add the game in the Play Console and set up Play Games Services for it, which gives the project id the plugin's manifest needs.
3. Create each achievement there with the names and descriptions in `docs/Steam-setup.md`. Play Games wants 512 by 512 icons, so the 64 by 64 Steam icons in `store/achievements` need larger copies. Play Games will not publish with fewer than five achievements; the game has 46.
4. The Play Console gives each achievement an id such as `CgkI...`. Put each in `play_games.achievements` in `game/data/balance.json`, beside the game's own id. Blank ids are skipped, so they can be filled in as they come, and a test checks that every achievement has an entry.

Achievements earned before then are sent the next time the game starts, as they are on Steam.
