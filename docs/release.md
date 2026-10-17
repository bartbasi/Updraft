# Releasing Updraft

Everything needed to put Updraft on Google Play, or to hand the APK to friends directly.

| | |
|---|---|
| App name | Updraft |
| Package (app ID) | `io.github.bartbasi.updraft`. It can never change once the app is on Play. |
| Version | `version/code=1`, `version/name="0.1.0"` (in **both** presets in `export_presets.cfg`) |
| Android | 7.0 and newer (min SDK 24, target SDK 36), 64-bit ARM phones (arm64-v8a) |
| Permissions | none |
| Network, ads, analytics, accounts | none; the game never goes online (Send feedback, Source code and Buy me a coffee only hand an address to the phone's email app or browser) |
| Data stored | three small files on the phone: settings, the best Course score and Endless progress. They are not backed up and are deleted on uninstall. |

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

- A **debug** build of Updraft installed with `adb` is signed with the debug key, so the release
  APK won't install over it. Uninstall the debug one first. Only the best score and settings
  are lost.

## 4. Google Play

### One-time setup

1. Updraft goes on **Play, Inc.'s organization account**
   (<https://play.google.com/console/signup>, a one-time $25 fee). An organization account needs
   the company's **DUNS number**, which is still on its way: no Play Console work until it
   arrives. Google checks the organization, which can take a few days.
2. New *personal* accounts have to run a closed test (at the time of writing, 12 testers for 14
   days) before going public; organization accounts don't. Check the current rule in the
   Console.
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

### Store listing, App content and countries

Everything to paste in (the listing text, the contact and privacy policy URL, the Data safety,
Ads, App access, content rating and target audience answers) is in
[store/listing.md](store/listing.md). The privacy policy is
[store/privacy-policy.md](store/privacy-policy.md), published at
https://bartbasi.github.io/Updraft/privacy-policy/. The images are in
[store/graphics/](store/graphics/), made with `bash tools/make_store_graphics.sh`.
