# Updraft: decisions for anyone working on it

Updraft is a Godot 4.7.2 tilt-flying game, Android first. How to run, test and build it is in
README.md and docs/release.md. These are the owner's fixed decisions. Ask before changing any of
them, or anything in LICENSE, NOTICE or other public material.

## Studio decisions (Play, Inc., 17 October 2026)

These apply to every game the studio makes.

- **Copyright holder: Play, Inc.** Bart Basi assigned his game copyrights to the company in
  writing. Every copyright line reads exactly `Copyright 2026 Play, Inc.` (that comma and period,
  never in capitals, no "(C)" or ©). It appears in NOTICE, README, About (`AboutPanel.COPYRIGHT`)
  and the two-line header on every source file (`Updraft. Copyright 2026 Play, Inc.`, checked by
  tests/test_about.gd). "Made by Bart Basi" stays on About.
- **GPL v3 section 7(b) attribution** (NOTICE term 1): "Based on Updraft, designed and written by
  Bart Basi, with assistance from Claude. Copyright 2026 Play, Inc." It credits Bart Basi as the
  creator and Play, Inc. as the copyright holder. NOTICE term 2 bars using the names Play, Inc.
  and Bart Basi to promote or endorse modified versions. Never edit LICENSE (the GPL text).
- **Buy me a coffee**: `Links.COFFEE_URL` = https://buymeacoffee.com/playinc, one constant,
  never built from input and never shown on screen. The button is only on the title screen
  (small, quiet, below everything) and in About's "Supporting Updraft" section, whose wording is
  fixed. A tap only hands the address to the phone's browser (`OS.shell_open`, no permission
  needed); if nothing opens it, nothing is shown. Tests replace `Links.opener` so no browser
  opens. Known and accepted risk: Google Play's payments policy may flag the button (see
  docs/store/listing.md).
- **Store material** lives in docs/store/: listing.md, privacy-policy.md, and graphics/ made
  only by the game's own code (`bash tools/make_store_graphics.sh`, checked by
  `python tools/check_store.py`). Updraft is landscape, so its screenshots are 1920x1080.
  Target audience 13 and over. Never use another game's name in the listing.
- **Public repo**: github.com/bartbasi/Updraft is public. The privacy policy is published from
  docs/store by GitHub Pages (.github/workflows/pages.yml) at
  https://bartbasi.github.io/Updraft/privacy-policy/. Ask before making anything else public.
- **Contact** for feedback, privacy, store listings and everything else: bartbasi@gmail.com.
- **Waiting on**: a DUNS number for Play, Inc. (no Play Console work until then). Release
  signing and publishing need the owner's go-ahead every time. The release signing certificate
  stays `CN=Bart Basi`.
- **Writing style**: plain, like a person, in docs, UI text, code comments and commits. No em
  dashes and no double hyphens in prose.

## Project decisions

- App name Updraft, package `io.github.bartbasi.updraft` (permanent once on Play).
- No ads, no analytics, no accounts, no internet, no Android permissions, no real-money
  purchases. Stars are only earned by flying.
- Every model, texture, shader and sound is made in code in this repo; no third-party assets.
