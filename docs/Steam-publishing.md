# Farmus Maximus: Publishing to Steam

How builds get onto Steam and to players. Once the steps below are done, every update is one command, and everyone with the game on Steam receives it automatically the next time their Steam client updates.

## What is already set up

- `tools/steam/publish.py` exports the game for each platform with a depot, then hands over to WSL (the Linux that runs inside Windows), which lays out the builds, signs and notarizes the Mac app, and uploads everything.
- The upload runs in WSL because a Mac app copied through Windows loses its file permissions and will not open, and the Linux game needs its "executable" permission too. `tools/steam/wsl_build.sh` does that half.
- `tools/steam/wsl_setup.sh` installs Valve's Linux steamcmd and rcodesign (the tool that signs and notarizes a Mac app without a Mac) into `~/farmus-steam` inside WSL. WSL with Ubuntu is already installed on this computer.
- `tools/steam/apple_setup.sh` makes the Apple credentials; `tools/steam/macos_entitlements.plist` gives the Mac app the two permissions the Steam overlay needs.
- `tools/steam/steam.json` holds the Steam account name and the app and depot numbers. It is empty until the steps below give you those numbers; a depot left at 0 is skipped.
- GodotSteam is in `game/addons/godotsteam/` and ships with every export; `docs/Steam-setup.md` says how the game uses it and how to try it outside Steam.
- Godot exports the Mac app unsigned (`codesign/codesign=0` in the macOS presets). `wsl_build.sh` signs and notarizes it for Steam once the Apple credentials below exist; a Mac build sent by hand is signed, notarized and stapled on the Mac, where the Developer ID's private key is kept.

## One-time setup on this computer

Open PowerShell in the project folder and run:

```
wsl -u root -- bash tools/steam/wsl_setup.sh
```

It installs steamcmd and rcodesign inside WSL and prints the rcodesign version when it is done.

The Windows build uses a trimmed Godot engine, built once with `python tools/engine/build_template.py` (it needs the Godot source, SCons and Visual Studio, listed at the top of that script). It lands in `tools/engine/bin/`, which is not in git, so build it again on a new computer and after every Godot update.

## One-time setup on Steamworks

These steps need you, because they involve your Steam account, payment and tax details.

1. **Join Steamworks.** Sign up at partner.steamgames.com, pay the Steam Direct fee (\$100 per game, paid back once the game earns \$1,000), and fill in the tax and bank forms. Valve checks these, which can take from a few days to a couple of weeks.
2. **Create the app.** Steamworks gives the game an **App ID**, for example 3456780. Under App Admin, SteamPipe, Depots, it also creates a **depot**, usually numbered one higher, for example 3456781. Set that depot's operating system to Windows, then add two more depots, one set to macOS and one to Linux + SteamOS.
3. **Tell Steam how to start the game.** Under Installation, General, add three launch options:
   - executable `Farmus Maximus.exe`, operating system Windows
   - executable `Farmus Maximus.app`, operating system macOS
   - executable `Farmus Maximus.x86_64`, operating system Linux + SteamOS
4. **Say the Mac app is notarized.** Under Installation, General (or the store page's Platforms section), tick **App Bundles Are Notarized**. Steam has required notarized Mac games since 2019; the publish script notarizes every Mac build.
5. **Add a test branch.** Under SteamPipe, Builds, create a branch named `testing`. No password is needed.
6. **Publish the settings.** Steamworks changes only apply after you press Publish on the Publish tab.
7. **Create the Playtest.** On the game's Steamworks page, open Playtest and create one. This makes a separate app, "Farmus Maximus Playtest", with its own App ID. Repeat steps 2 to 6 for it, adding Mac and Linux depots only if Mac and Linux testers are wanted.
8. **Fill in the numbers.** Put the account name and the numbers into `tools/steam/steam.json`:
   - `account`: the Steam account that uploads builds. Valve recommends a separate Steam account that has only the permission to upload builds, so your own account is never used by a script.
   - `targets.playtest`: the Playtest's App ID and its depots (`windows`, and `macos` and `linux` if it has them).
   - `targets.game`: the main game's App ID and its three depots.
9. **Log in to steamcmd once.** In PowerShell, run:

   ```
   wsl ~/farmus-steam/steamcmd/steamcmd.sh +login YOUR_ACCOUNT +quit
   ```

   Type the password, then the Steam Guard code from the email or the Steam phone app. steamcmd remembers the login, so the publish script never needs the password.

## One-time setup with Apple

Only the Apple Developer account's **Account Holder** can make the certificate in step 2. Each command runs in PowerShell from the project folder.

1. **Make a certificate request.** This creates a private key that never leaves WSL, and puts the request in Downloads:

   ```
   wsl bash tools/steam/apple_setup.sh csr "C:\Users\evand\Downloads"
   ```

2. **Get the certificate.** At developer.apple.com, go to Certificates, IDs & Profiles, Certificates, press +, choose **Developer ID Application**, upload `developer_id.csr` from Downloads, and download the certificate it gives you (`developerID_application.cer`).
3. **Turn it into the signing file:**

   ```
   wsl bash tools/steam/apple_setup.sh p12 "C:\Users\evand\Downloads\developerID_application.cer"
   ```

4. **Make the notarization key.** At appstoreconnect.apple.com, go to Users and Access, Integrations, App Store Connect API, Team Keys, and generate a key with the **Developer** role. Note the **Issuer ID** at the top of the page and the key's **Key ID**, and download the `.p8` file (Apple only lets you download it once).
5. **Store the key:**

   ```
   wsl bash tools/steam/apple_setup.sh api-key ISSUER_ID KEY_ID "C:\Users\evand\Downloads\AuthKey_KEYID.p8"
   ```

   Then delete the `.p8`, `.csr` and `.cer` files from Downloads; WSL keeps what it needs in `~/farmus-steam/apple`.

The Developer ID certificate lasts five years; the Apple Developer membership it needs is renewed every year.

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

The script builds the game for every platform with a depot, signs and notarizes the Mac app (Apple's check usually takes a few minutes), uploads it and makes it live on the `testing` branch. Testers get it the next time Steam updates, usually within minutes when Steam is open. The note and the git commit appear next to the build in Steamworks, under SteamPipe, Builds.

`--dry-run` builds every platform, signs the Mac app if the Apple credentials exist, and lays everything out in `~/farmus-steam/<target>/content` inside WSL without notarizing or uploading, to check that everything is in order. It needs neither the ids in `steam.json` nor steamcmd, so it works before Steamworks is set up. Godot's exports are kept in `builds/steam/<target>/` on Windows too.

## The default branch and release

Steam only lets a script make a build live on a branch such as `testing`. For the default branch, the one every buyer gets, go to SteamPipe, Builds in Steamworks and set the build live there yourself. This is Valve's safeguard against a script releasing a broken build to everyone. When the game launches, the same command uploads with `game` instead of `playtest`, and you set each release live on the default branch by hand. The free demo works the same way with `demo`; its Steamworks setup is in `Steam-setup.md`.
