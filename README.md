# Paper Plane

A short playable demo: fly a folded paper plane through a pastel house by tilting your phone.
A kid throws it across a bedroom; bank out of the door, ride a sunbeam down a long gallery,
dive the stairwell, then ride warm air from a radiator and steam from a kettle, dive under the
dining-room lamp, burst out of the kitchen window, and explore the valley outside: circle up
the warm air over a hay field, a barn, a ploughed field and a bonfire's smoke, soar the ridge,
and come down in the lavender or on the picnic blanket. Soft beeps tell you when you're in lift.
A well-flown run lasts one to two minutes. Prefer a red balloon? Pick it on the end card.

## Scoring

- **Distance** (top right, in metres): how far along the course you got. 10 points a metre.
- **Style** at 8 moments (the door turn, the sunbeam, the downdraft dive, the landing turn, the
  radiator, under the lamp, the kettle steam, out of the window): the closer you stay to the
  best line through each, the more points; a gold "Perfect!" for a really close pass.
- **Outdoors:** 5 points a second in the air (up to a minute); landing on the lavender +200, on
  the picnic blanket up on the plateau +400 (not if you crash), and a ninth moment, the Ridge run.
- **End card:** distance, style, airtime, landing, total and your best, which is kept on the phone.

Built with Godot 4.7.2 (GDScript, Mobile renderer), Android first. Every model, texture,
shader and sound is made in code in this repo; there are no third-party assets.

## Controls

| Phone (landscape) | Keyboard | Does |
|---|---|---|
| Tilt the top edge away from you | Up / W | Nose down (dive, gain speed) |
| Tilt the top edge toward you | Down / S | Nose up (climb, lose speed, then stall) |
| Tilt left / right | Left / A, Right / D | Bank and turn |

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

# Rebuild the sound effects (Python 3, standard library only)
python tools/gen_sounds.py
```

## Building the Android APK

Needs the Android export templates, JDK 17 and the Android SDK (`C:\Android\Sdk`) set in
Godot's editor settings, plus a debug keystore; all of this is already set up on this PC.

```powershell
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" build/paper-plane-debug.apk
```

Install on a phone with USB debugging on:

```powershell
C:\Android\Sdk\platform-tools\adb.exe install -r build\paper-plane-debug.apk
```

Without USB debugging: plug the phone in, copy `build\paper-plane-debug.apk` into its
`Download` folder from File Explorer, then on the phone open Files > Downloads, tap the APK and
allow installing from that app when asked. Installing a newer build over the old one keeps the
best score.

In a debug build, F3 (or a tap on the fps counter) shows the style moments' best lines and
corridors. Release builds have no debug tools.

The package id is the placeholder `com.example.paperplane`; pick a real one before publishing.

## Layout

```
scenes/main.tscn          the one scene: course, plane, camera
scripts/tuning.gd         all tuning numbers
scripts/flight_model.gd   glider physics (pure, testable)
scripts/controls.gd       tilt calibration + keyboard
scripts/paper_plane.gd    the plane node: physics, collisions, looks
scripts/thermal.gd        rising and sinking air zones and their visuals
scripts/course.gd         builds the house, furniture and hills in code; course layout
scripts/course_upstairs.gd the bedroom, gallery and stair hall
scripts/scoring.gd        distance and style points
scripts/best_score.gd     the saved best score (validated on load)
scripts/debug_overlay.gd  debug-build view of the style paths
scripts/follow_camera.gd  smoothed chase camera
scripts/game.gd           run flow, lighting, sound, end card
scripts/art.gd            materials and the low-poly mesh builder
shaders/                  watercolor screen pass, thermal shimmer
audio/                    synthesized WAVs (from tools/gen_sounds.py)
tests/                    headless test runner, suites, autopilot
tools/                    screenshots, flight log, sound generator
docs/                     the brief, design plans and reviews, build notes
```
