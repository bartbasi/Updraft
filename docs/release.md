# Releasing Updraft

Everything needed to put Updraft on Google Play, or to hand the APK to friends directly.

| | |
|---|---|
| App name | Updraft |
| Package (app ID) | `io.github.bartbasi.updraft`. It can never change once the app is on Play. |
| Version | `version/code=1`, `version/name="0.1.0"` (in **both** presets in `export_presets.cfg`) |
| Android | 7.0 and newer (min SDK 24, target SDK 36), 64-bit ARM phones (arm64-v8a) |
| Permissions | none |
| Network, ads, analytics, accounts | none; the game never goes online |
| Data stored | two small files on the phone: best score and settings. They are not backed up and are deleted on uninstall. |

## 1. Back up the signing key first

The release key lives outside the repo, in `%APPDATA%\Godot\keystores\`:

- `updraft-release.keystore`
- `updraft-release-password.txt`

Copy **both** somewhere safe and private, such as a password manager or private cloud storage
(not the repo, not email). Every update on Play has to be signed with this key, and so does
every APK you send to friends; a phone refuses an update signed with a different key. With Play
App Signing (below), Google can reset a lost upload key, but only after a support request. A
lost key for directly shared APKs can't be recovered: everyone would have to uninstall and lose
their best score.

Certificate: `CN=Bart Basi, O=bartbasi`, SHA-256
`8b:80:b4:f4:a5:5d:ff:4d:5f:59:77:46:11:6c:04:31:4d:36:67:a8:19:16:55:47:a8:b2:ff:58:46:51:e5:86`.

## 2. Build

```bash
bash tools/build_release.sh
```

This writes:

- `build/updraft.aab`, the Android App Bundle you upload to Play. It is built with Gradle from
  the Android build template in `android/build`, which is gitignored. If that folder is missing,
  unzip `%APPDATA%\Godot\export_templates\4.7.2.stable\android_source.zip` into `android/build`,
  then write `4.7.2.stable` into `android/.build_version`.
- `build/updraft.apk`, a signed APK to share directly.

The script reads the key and password from the files above through environment variables for
that one build. Nothing secret is written into the project.

It needs a few GB free on C: while it runs. "Could not unzip temporary unaligned APK" means the
disk filled up.

**For every new release**, raise `version/code` by 1 (and `version/name` as you like) in both
`[preset.0.options]` and `[preset.1.options]`. Play rejects an upload whose version code it has
already seen.

To check a build:

```bash
C:/Android/Sdk/build-tools/36.1.0/aapt.exe dump badging build/updraft.apk | head -3
C:/Android/Sdk/build-tools/36.1.0/apksigner.bat verify --print-certs build/updraft.apk
"C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/jarsigner.exe" -verify build/updraft.aab
```

## 3. Share the APK directly

Send `build/updraft.apk` (about 27 MB). On the phone: open it, then allow installing from that
app (Files, Chrome, Gmail and so on) when asked. Play Protect may warn that it doesn't know the
app; "Install anyway" is fine for your own build.

- Updraft installs as its own app, next to the old "Paper Plane" test build
  (`com.example.paperplane`). That one can be uninstalled.
- A **debug** build of Updraft installed with `adb` is signed with the debug key, so the release
  APK won't install over it. Uninstall the debug one first. Only the best score and settings
  are lost.

## 4. Google Play

### One-time setup

1. Make a developer account at <https://play.google.com/console/signup>: a personal account and
   a one-time $25 fee. Google checks your identity, which can take a few days.
2. **New personal accounts have to run a closed test before going public.** At the time of
   writing, that means at least 12 testers opted in for 14 days in a row. Check the current
   rule in the Console. Friends and family count: add their Google accounts as testers and send
   them the opt-in link.
3. Create the app: name **Updraft**, default language English (US), **Game**, **Free**
   (free can't be changed to paid later), then accept the declarations.

### Play App Signing

Play holds the key that signs what phones actually download, and your `updraft-release.keystore`
becomes the **upload key**. Accept the default ("Let Google manage and protect your app signing
key") on the first upload. Nothing else needs doing; the `.aab` is already signed with the upload
key.

### Upload

Testing > Closed testing > Create track (or Internal testing for a quick check first) > Create
release > upload `build/updraft.aab` > release notes, for example "First release." > Review >
Start rollout.

When the closed test has run long enough, Production > Create release, then upload the same or a
newer `.aab`.

### Store listing (Grow > Store presence > Main store listing)

All images are in `docs/store/`:

| Asset | File | Play's rule |
|---|---|---|
| App icon | `icon_512.png` | 512×512 PNG |
| Feature graphic | `feature_graphic_1024x500.jpg` | 1024×500 |
| Phone screenshots | `screenshot_1` to `screenshot_6` (1920×1080) | 2 to 8, 16:9 |

The screenshots were taken from the test pilot's flight with `tools/capture.gd` at
`--resolution 1920x1080`. Retake them the same way when the world changes.

**App name** (30 characters max): `Updraft`

**Short description** (80 characters max):

> Tilt your phone to fly a paper plane out of the house and up on the warm air.

**Full description**:

> A kid throws a paper plane across the bedroom, and you take it from there. Or swap it for a
> little red balloon.
>
> Tilt your phone to bank out of the door and ride a sunbeam down the long gallery. Dive the
> stairwell, catch warm air off the radiator and steam from the kettle, swoop under the
> lamp over the dining table, then burst out of the kitchen window into the valley.
>
> Outside, circle in the warm air to climb. Go from thermal to thermal over the hay field, the
> barn roof, the ploughed field and the bonfire smoke, or soar the wind up the ridge. A soft beep
> tells you when you're rising.
>
> Every flight scores distance, style, time in the air and where you land. Touch down in the
> lavender or on the picnic blanket for a bonus, then fly again for a new best.
>
> • Tilt to fly: one to two minutes a flight
> • A paper plane and a balloon, with the same physics
> • No ads, no in-app purchases, no internet, no account
> • Adjustable tilt sensitivity, sound on or off, swap climb and dive

**Category**: Game > Casual. **Tags**: flying, relaxing, simulation (pick from Play's list).
**Contact email**: required, and shown publicly. Use one you don't mind being public.

### App content (Policy > App content)

- **Privacy policy**: Play asks for a URL. Host this text somewhere public, for example a
  public GitHub gist or a GitHub Pages page:

  > **Updraft privacy policy.** Updraft does not collect, store remotely, or share any personal
  > data. It has no ads, analytics, accounts or internet access, and asks for no permissions.
  > It keeps your best score and settings in two small files on your phone only; uninstalling the
  > app deletes them. Contact: <your email>.

- **Ads**: No.
- **App access**: all functionality is available without special access.
- **Content rating**: fill in the IARC questionnaire. Category: Game. Answer **No** to violence,
  fear, sexuality, language, controlled substances, gambling, user interaction/chat, sharing
  location, and digital purchases. Expect Everyone / PEGI 3.
- **Target audience**: an owner decision. "13 and over" is the simplest. Including under-13
  brings in the Families policy (the privacy policy must cover children; ads and SDK rules).
  Updraft already meets those, since it has none, but it means more forms and a stricter
  review.
- **Data safety**: "Does your app collect or share any of the required user data types?" **No.**
  Data is encrypted in transit: not applicable (nothing is sent). No account creation. The
  result shows as "No data collected, no data shared".
- **Government app**, **financial features**, **health**, **news**: No.

### Countries

Production > Countries/regions: add all, or just where you want.
