# Updraft

Fly a little red balloon (or a folded paper plane) through a pastel house and out over the hills
by tilting your phone. A kid lets it go in a bedroom; bank out of the door, ride a sunbeam down a long gallery,
dive the stairwell, then ride warm air from a radiator and steam from a kettle, dive under the
dining-room lamp, burst out of the kitchen window, and explore the valley outside: circle up
the warm air over a hay field, a barn, a ploughed field and a bonfire's smoke, soar the ridge,
and come down in the lavender or on the picnic blanket. Or climb the chalk pit's warm air at the
valley's end and cross the Gap in the hills to a lake with an island, a beach and a windy bluff.
Soft beeps tell you when you're in lift, a sigh when you've flown out of it; thermals drift with
the breeze and their clouds thin once climbed, and a gull joins you on the ridges. A run lasts
one to two and a half minutes. Prefer the paper plane? Pick it on the end card.

**Endless.** Land outdoors once and Endless opens: a country beyond the lake that never ends,
built ahead of you from pieces (a cloud street, a barley field with a thermal, a long ridge, a
hamlet's chimney smoke, a meadow of ring kites, a viaduct to dive under). A breeze carries you on;
stay up as long as you can, collecting stars. The run ends at the first touch of the ground. See
[docs/endless-plan.md](docs/endless-plan.md); this is its first step, a prototype.

Updraft is free and open source: Copyright 2026 Play, Inc., under the GNU GPL v3 with a few
additional terms (see [License](#license)). It was designed and written by Bart Basi, with
assistance from Claude. Feedback is welcome at bartbasi@gmail.com, or with the Send feedback
button in About, on the title screen.

## Scoring

- **Distance** (top right, in metres): how far along the course you got. 10 points a metre.
- **Style** at 8 moments (the door turn, the sunbeam, the downdraft dive, the landing turn, the
  radiator, under the lamp, the kettle steam, out of the window): the closer you stay to the
  best line through each, the more points; a gold "Perfect!" for a really close pass.
- **Outdoors:** 5 points a second in the air (up to 90 s); landing on the lavender +200, on the
  picnic blanket up on the plateau +400, on the beach +250 or on the island +500 (not if you
  crash; coming down in the lake is a "Splashdown!", no bonus), and two more moments, the Ridge
  run and Through the Gap.
- **End card:** distance, style, airtime, landing, total and your best, which is kept on the phone.

Built with Godot 4.7.2 (GDScript, Mobile renderer), Android first. Every model, texture,
shader and sound is made in code in this repo; there are no third-party assets.

## Controls

| Phone (landscape) | Keyboard | Does |
|---|---|---|
| Tilt the top edge away from you | Up / W | Nose down (dive, gain speed) |
| Tilt the top edge toward you | Down / S | Nose up (climb, lose speed, then stall) |
| Tilt left / right | Left / A, Right / D | Bank and turn |
| Back | Escape | Step back out of About or Settings; otherwise (phone only) close the game |

However you are holding the phone when the plane is thrown counts as "level".
Tilt sensitivity is `sensitivity` in `scripts/tuning.gd`.

## Changing how it feels

Every game-feel number (gravity, lift, drag, stall speed, thermal strength, turn rate,
sensitivity, crash thresholds...) lives in **`scripts/tuning.gd`**, with a short recipe list at
the top ("floatier", "faster", ...). Change numbers there, not code.

The course layout (room sizes, thermal and lamp positions) is the constants block at the top of
`scripts/course.gd`.

## Running and testing on a PC

Godot is installed at `C:\Tools\Godot` (the winget copy lives under a path with a space, which
Godot's console launcher cannot handle). From the project folder:

```powershell
# Play (arrow keys / WASD)
C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe --path .

# Open in the editor
C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe --path . --editor

# Headless tests (flight model, controls, collisions, whole-course autopilot flights)
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd

# Screenshots along an autopilot flight (--times=seconds into the flight)
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --path . -s res://tools/capture.gd -- --out=screens

# A readable log of test-pilot flights: thermals, bumps, style points, close calls, dead air
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s res://tools/flight_log.gd -- --pilot=novice --runs=10
# ...or a skilled pilot on an outdoor route: lavender, chain, ridge or picnic
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s res://tools/flight_log.gd -- --route=chain

# Endless: test pilots (skilled, shaky or novice) with a timeline, summaries and stars by arc
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s res://tools/endless_log.gd -- --pilot=shaky --runs=20 --max=200 --quiet
# ...each piece flown alone, against the generator's table (exit height, clearances, stars)
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s res://tools/endless_log.gd -- --calibrate --piece=viaduct
# ...and screenshots from the look back on
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --path . -s res://tools/endless_capture.gd -- --out=screens --seed=1

# Rebuild the sound effects (Python 3, standard library only)
python tools/gen_sounds.py
```

## Building the Android APK

Needs the Android export templates, JDK 17 and the Android SDK (`C:\Android\Sdk`) set in
Godot's editor settings, plus a debug keystore; all of this is already set up on this PC.

```powershell
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" build/updraft-debug.apk
```

Install on a phone with USB debugging on:

```powershell
C:\Android\Sdk\platform-tools\adb.exe install -r build\updraft-debug.apk
```

Without USB debugging: plug the phone in, copy `build\updraft-debug.apk` into its
`Download` folder from File Explorer, then on the phone open Files > Downloads, tap the APK and
allow installing from that app when asked. Installing a newer build over the old one keeps the
best score.

In a debug build, F3 (or a tap on the fps counter) shows the style moments' best lines and
corridors. Release builds have no debug tools.

The app is **Updraft**, package `io.github.bartbasi.updraft`. The signed release (`.aab` for Google
Play, `.apk` to share) is built with `bash tools/build_release.sh`. See
[docs/release.md](docs/release.md) for the signing key, the Play upload steps and the store
listing.

## Layout

```
scenes/main.tscn          the one scene: course, plane, camera
scripts/tuning.gd         all tuning numbers
scripts/flight_model.gd   glider physics (pure, testable)
scripts/controls.gd       tilt calibration + keyboard
scripts/flyer.gd          what you fly (balloon or paper plane): physics, collisions, looks
scripts/thermal.gd        rising and sinking air zones and their visuals
scripts/course.gd         builds the house, furniture and hills in code; course layout
scripts/course_upstairs.gd the bedroom, gallery and stair hall
scripts/scoring.gd        distance and style points
scripts/best_score.gd     the saved best score (validated on load)
scripts/debug_overlay.gd  debug-build view of the style paths
scripts/follow_camera.gd  smoothed chase camera
scripts/game.gd           run flow, lighting, sound, end card, settings
scripts/about_panel.gd    About: Send feedback, Supporting Updraft, the License and Credits pages
scripts/links.gd          the addresses handed to the phone, and the Buy me a coffee button
scripts/how_to_fly.gd     the player's guide (About > How to fly)
scripts/flight_game.gd    what every flight shares: sounds, settings, About, the end card's frame
scripts/progress.gd       Endless's save: unlocked, the star bank, bests, the mode flown last
scripts/boot.gd           opens the mode flown last
scripts/endless/          Endless: the game, the world (streaming pieces), the generator,
                          the pieces, stars, clouds and birds
scenes/endless.tscn       the Endless scene
scripts/art.gd            materials and the low-poly mesh builder
shaders/                  watercolor screen pass, thermal shimmer
audio/                    synthesized WAVs (from tools/gen_sounds.py)
tests/                    headless test runner, suites, autopilot
tools/                    screenshots, flight log, sound generator, icons, release build
docs/                     the brief, design plans and reviews, build notes, release guide
docs/store/               Play store listing, privacy policy (published on GitHub Pages) and
                          graphics (made by tools/make_store_graphics.sh)
```

## License

Copyright 2026 Play, Inc.

Updraft is free software: you can redistribute it and/or modify it under the terms of the
[GNU General Public License, version 3](LICENSE), with the additional terms in [NOTICE](NOTICE)
(allowed by the GPL's section 7). In short:

- **Keep the credit.** Anything built from Updraft, in whole or in part, must keep the line
  "Based on Updraft, designed and written by Bart Basi, with assistance from Claude. Copyright
  2026 Play, Inc." in its source (the NOTICE file) and, if it has a screen, in its About,
  Credits or License screen.
- **Mark your changes.** A modified version must say it has been changed and must not pass
  itself off as the original Updraft or as made or endorsed by Play, Inc. or Bart Basi.
- **Use your own name and icon.** The license gives no rights to the name "Updraft" or its icon.

Every source file starts with a two-line notice pointing to LICENSE and NOTICE; please keep it.
Updraft is built with the [Godot Engine](https://godotengine.org) (MIT license); the game's
Credits screen shows Godot's notices and those of its third-party parts.
