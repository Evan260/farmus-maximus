# Farmus Maximus: Publishing to Steam

How builds get onto Steam and to players. Once the steps below are done, every update is one command, and everyone with the game on Steam receives it automatically the next time their Steam client updates.

## What is already set up

- `tools/steam/steamcmd/` holds steamcmd, Valve's upload tool. It is kept out of git because it stores the saved Steam login.
- `tools/steam/publish.py` builds the game, writes Valve's upload instructions and uploads the build.
- `tools/steam/steam.json` holds the Steam account name and the app and depot numbers. It is empty until the steps below give you those numbers.

## One-time setup on Steamworks

These steps need you, because they involve your Steam account, payment and tax details.

1. **Join Steamworks.** Sign up at partner.steamgames.com, pay the Steam Direct fee (\$100 per game, paid back once the game earns \$1,000), and fill in the tax and bank forms. Valve checks these, which can take from a few days to a couple of weeks.
2. **Create the app.** Steamworks gives the game an **App ID**, for example 3456780. Under App Admin, SteamPipe, Depots, it also creates a **depot**, usually numbered one higher, for example 3456781. This holds the Windows files. Depots for Mac and Linux can be added later.
3. **Tell Steam how to start the game.** Under Installation, General, add a launch option: executable `Farmus Maximus.exe`, operating system Windows.
4. **Add a test branch.** Under SteamPipe, Builds, create a branch named `testing`. No password is needed.
5. **Publish the settings.** Steamworks changes only apply after you press Publish on the Publish tab.
6. **Create the Playtest.** On the game's Steamworks page, open Playtest and create one. This makes a separate app, "Farmus Maximus Playtest", with its own App ID and depot. Repeat steps 3 to 5 for it.
7. **Fill in the numbers.** Put the account name and the numbers into `tools/steam/steam.json`:
   - `account`: the Steam account that uploads builds. Valve recommends a separate Steam account that has only the permission to upload builds, so your own account is never used by a script.
   - `targets.playtest.app_id` and `depots.windows`: the Playtest's App ID and depot.
   - `targets.game.app_id` and `depots.windows`: the main game's App ID and depot.
8. **Log in to steamcmd once.** Open a terminal in the project folder and run:

   ```
   tools\steam\steamcmd\steamcmd.exe +login YOUR_ACCOUNT +quit
   ```

   Type the password, then the Steam Guard code from the email or the Steam phone app. steamcmd remembers the login, so the publish script never needs the password.

## Giving a tester access

1. In Steamworks, open the Playtest app and request Steam keys (a handful is plenty).
2. Send one key to the tester. They redeem it in Steam under Games, Activate a Product on Steam, and the Playtest appears in their library.
3. They right-click it, choose Properties, Betas, and pick `testing`. They only do this once; from then on Steam keeps them on the newest test build.

Later, the Playtest can also be opened to sign-ups from the store page, with you deciding how many people get in.

## Sending an update

Ask Claude to "push an update to the playtest", or run:

```
python tools/steam/publish.py playtest --note "Faster cart trips"
```

The script builds the game, uploads it and makes it live on the `testing` branch. Testers get it the next time Steam updates, usually within minutes when Steam is open. The note and the git commit appear next to the build in Steamworks, under SteamPipe, Builds.

`--dry-run` builds the game and writes the upload instructions without uploading, to check that everything is in order.

## The default branch and release

Steam only lets a script make a build live on a branch such as `testing`. For the default branch, the one every buyer gets, go to SteamPipe, Builds in Steamworks and set the build live there yourself. This is Valve's safeguard against a script releasing a broken build to everyone. When the game launches, the same command uploads with `game` instead of `playtest`, and you set each release live on the default branch by hand.
