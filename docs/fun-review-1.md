# Fun review 1: the whole flight (Phase B, step 5)

**Verdict: SEND BACK.** Three must-fix items: the plane is hard to see, a well-flown run lasts 52 s instead of
at least 60, and the lamp moment is a cliff. Two smaller items follow. Both deviations are signed off (end of
this doc).

Sources:
- The lead's screenshots (`scratchpad/phaseB/shots`) and logs.
- My own runs in a scratch copy of the repo (`scratchpad/designer/pp`, with a probe script
  `tools/dz_probe.gd`). Nothing in the repo was touched except this file.
- Before/after crops for item 1: `scratchpad/designer/compare_stripe.png`.
- The trial meadow thermal seen through the window (item 2): `scratchpad/designer/shots_meadow`.

---

## Ranked fixes

### 1. MUST: You can barely see your own plane (readable)
- **Evidence.** The plane is white paper flying over cream, peach and white surfaces, under a soft watercolour
  pass:
  - **First frame** (`scratchpad/designer/shots_base/00_t000.0.png`): the plane covers the door and is nearly invisible against the
    cream door frame. It is the hero of the shot.
  - **Gallery, t 7.6:** edge-on, a faint line.
  - **Arch, t 24.6:** white on the white coffee table and pink rug (the lead's open item).
  - **Kitchen, t 36:** white over cream tiles.
  - **Window, t 39.5:** faint against the pale window.
  - It reads well only outdoors, against green.
- **Fix (the plane's look).** The kid coloured the wing tips with a felt pen:
  - In `build_paper_mesh()`, add one triangle on each wing over its back 30%:
    `(tip, fold, tip.lerp(nose, 0.3))`, raised 0.004, colour **`e88b7d`** (coral).
  - Change the keel colour `e0d9cd` → **`b8acc9`** (lilac grey).
  - I tried exactly this in the copy: the plane now pops in every one of those shots (see the crops), and
    the first frame clearly shows a plane gliding toward the door.
- **No camera or furniture change.** If the phone shows the plane too small in the stair dive, the fallback
  is `camera_follow_speed` 3.5 → 4.5. That cuts the trail at 9 u/s from about 6.0 to 5.4 units.

### 2. MUST: A good run is 52 s, and the last 10 s outdoors is dead air (60 s target, no dead air, window payoff)
- **Evidence.**
  - The skilled run lasts 52.4 s. The brief asks for at least 60.
  - The 9.7 s "longest dead air" is the end of the run: the window at 42.8 s, then a glide into the grass at
    52.4 s. Screens t 45 and t 49 are almost the same picture.
  - The window reveal itself is lovely (t 42). What comes after it gives the player nothing to do.
- **Fix (layout): a sun-warmed meadow thermal past the garden fence.** This adds time where the dead air
  already is, and turns it into a decision: "turn for the lift, then stretch the glide."
  - Add a cylinder thermal `MeadowHeat`:
    - base at **(-6, ground ≈ 1.1, -118)**: 29 units past the window, 6 units left of the centre line
    - **radius 6, height 12, strength 1.0** (5 u/s, the radiator's strength)
    - warm-air look, chime pitch 0.9
  - Under it, a golden hay-field patch about 12 × 12 (`f4dc9b` / `e9c98a`), so the heat has a visible cause.
  - **Keep |x| < 16 clear of trees for z > -240.** A tree stands at (-6.2, -206), on the line a pilot takes
    after circling in the thermal.
  - Extend the spine's last point from z -220 to about -280, so distance never stops counting on a long
    glide.
  - Optional beat for the glide after the thermal: one landmark near z -150, about 5 s later. For example, a
    small stream with a low footbridge, everything under 1.5 above the grass.
- **Measured (thermal added in the copy):**

| Pilot | Now | With the meadow thermal |
|---|---|---|
| Skilled test pilot | 52.4 s, 79 m | **60.4 s, 91 m** |
| 10 novices | 51.7-53.0 s | **60.2-61.9 s**, 0 crashes |
| Flies straight past it (x 0) | | 50.0 s, no lift. It is a choice, not a free ride. |

  - These runs use the test-pilot line changes below.
  - The thermal is visible through the kitchen window from about 40 s, slightly left of centre: a warm glowing
    column over the valley. It shows about 5 s before the player has to turn.
  - Radius 6 is wide enough to circle in: a full bank at 5-6 u/s turns on a radius of 4.4-5.3. A skilled player
    can climb to about y 13 and fly much further, which is the classic glider skill.
- **Test pilot:**
  - Outdoor line (replace the two points after the window):
    (-2, 6.5, -100) → (-5.5, 6.5, -112) → (-6, 11, -123) → (-5.5, 11, -133) → (-5, 6, -200).
  - Living room: change (-4.5, **9.0**, -18) to (-4.5, **6.8**, -18). Today that point climbs and the pilot
    reaches the radiator at **4.1 u/s, a hair above stall (4.0)**. That is also why the log shows 6.4 s of
    "dead air" from the arch to the radiator. A natural glide takes 5.6 s and passes the armchair and floor
    lamp halfway, so that stretch needs no change. The 60.4 s above already includes this faster line.
- **Don't** use the levers from my plan:
  - Gravity 7 gives only +2.8 s. It drops the stair dive's top speed from 9.2 to 8.6 u/s, and every
    Phase A measurement shifts with it. Keep it only as the owner's lever if the plane feels quick on the
    phone.
  - Gallery +15 adds 3 s to the gallery's straight, which is already the longest stretch.
- **Owner note.** This adds to the old outdoor ending (the brief kept the old demo "unchanged"). Please list it
  in the hand-back.

### 3. MUST: The lamp moment is a cliff, not a slope (style earned, fair failure)
- **Evidence.** The plane has to drop from the radiator's top (y ≈ 10 at z -27) into a 1.9-unit gap 16 units
  later. With the plane's 0.3 radius, its centre has only 1.3 units of room there (y 3.4 to 4.7). Test pilots
  on the lamp line, varying how firmly they pitch (`pitch_gain`):

| Pitch firmness | Now | Shade 5.5, table 2.8, shade radius 1.7 |
|---|---|---|
| 0.30 (gentle) | crash at the shade's front edge (0.1, 5.6, -43.1) | still crashes (correct: you must commit to the dive) |
| 0.45 (moderate), novices | **7/10 crash** | **20/20 survive, 19/20 earn it** (average 64) |
| 0.38, novices | | 9/10 earn it; 2 later crash on the kitchen counter, too low for the steam (fair) |
| 0.6 (firm) | 10/10 earn it, average 111 | unchanged (111-122) |

  Those runs show the cliff: one notch less firm on the pitch goes from earning the lamp every time to
  crashing most of the time. A crash there costs the kettle, the window and the outdoors, so real players will
  try it once and give up.
- **Fix (layout; small changes to the old demo, so note them for the owner):**
  - `LAMP` y **5.0 → 5.5**.
  - Shade bottom radius **2.0 → 1.7** (top 0.7 and height 1.6 unchanged).
  - Dining table top **3.1 → 2.8**: slab y 2.5-2.8, legs 2.5. That is still a normal table height (0.70 m).
  - The gap becomes 2.7 units, with 2.1 units of room for the plane's centre. The path (y 4.05-4.2) sits in
    its middle. **Keep the path, the 150 points and radius 1.5.**
  - The narrower shade starts 0.3 units later, which gives the dive more time.
  - The old line beside the lamp (x -2.9, y 6) still clears the shade by 1.2 units. The skilled pilot and
    10 novices on the course line were unchanged, with 0 crashes.
- **Test:** add one: "a moderately firm pilot (`pitch_gain` 0.45) on the lamp line earns the lamp and does not
  crash."

### 4. SHOULD: The stair dive and the window burst don't sound or feel bigger (feel, reward moments)
- **Evidence.**
  - My Phase A item 4 is still open. The wind curve makes cruise (6 u/s) → the dive's peak (9.2 u/s) only
    **+3.7 dB**, with pitch 1.02 → 1.20.
  - Bursting out of the window gets the style pop-up and nothing else: no sound, no camera move.
- **Fix (sound, all in `Tuning`):**
  - `wind_quiet` 0.12 → **0.14**
  - `wind_loud` 0.70 → **0.80**
  - `wind_quiet_speed` 2 → **5**
  - `wind_loud_speed` 12 → **11**
  - `wind_pitch_low` 0.80 → **0.85**
  - `wind_pitch_high` 1.35 → **1.45**
  - `wind_swell_rate` 4 → **6**
  - Result: cruise at 6 u/s is -12 dB, the dive's peak -4.4 dB (**+7.6 dB**), pitch 0.95 → 1.27. Slow flight
    in thermals goes quieter (-17 dB), so the chimes stand out more.
- **Fix (window burst, sound and camera):** the first time the plane is outside (`reached_outside`):
  - a wind gust of **+6 dB that fades over 1.5 s**
  - the camera's field of view easing **70 → 76 over 1.5 s** and staying there outdoors: the world opens up
  - New tuning values: `window_gust_db` 6, `window_gust_fade` 1.5, `camera_fov_outside` 76,
    `camera_fov_ease` 1.5.

### 5. NICE (lead's call): Close calls give no feedback (reward moments)
- **Evidence.** The brief names close calls as a reward moment. Today a near miss gives nothing. Only an actual
  touch gives a tap and a shake.
- **Fix (sound):**
  - When the plane passes within **1.0 unit** of a solid surface at **≥ 7.5 u/s** without touching it, give a
    short wind swell: **+5 dB, fading over 0.5 s**, at most once per **1.5 s**.
  - At 6 u/s cruise in the gallery it never fires. It fires when skimming the stairs in the dive, past the
    newel post, and through the arch or door posts at speed.
- It needs a small proximity check each tick. If the lead or code-reviewer counts that as a new system, move it
  to Later ideas.

---

## Sign-offs on the two deviations

- **Sunbeam at about 18° from vertical (plan: 40°): SIGNED OFF.**
  - The lift must follow the light (what you see is what you get). At 40° the lift would hug the south wall,
    away from the line after the turn.
  - What the 40° was for is still there. Seen from the bedroom, the sunny floor patch fills the left side of
    the doorway (t 2.5) and tells the player which way to turn.
  - The lift is as planned: +5 units in 2 s (18.8 → 23.7).
  - Reading as a high window suits a 3.5 m ceiling.
- **Arch header at rise 6 over 8.6 (plan: 4 over 5.7): SIGNED OFF.**
  - It is the same 35° slope, so a floater still glances off it.
  - It catches floaters arriving up to y 17.5: 0 of 18 crash with it, against 17 of 18 without.
  - The good line passes under it with room to spare: the plane at y 8.3-8.5, the camera 1 above, the arch top
    11.5.
  - In t 23.4 it reads as the arch's deep curved top, not as a wall.
- **Hall table props (FYI):** fine. They are visible, against the north wall, below the flight height.

## The open items from the build notes

| Item | Judgement |
|---|---|
| 60 s target | Item 2. |
| Lamp moment | Item 3. |
| Late first-timers weaving | **No layout change.** Height is not the cause. The planes hit the angled wall at 50° or more because they swing 35° or more off the gallery axis; the sunbeam's 24.5 top is irrelevant. I re-ran seeds 300-319: 15 of 20 crash, spread over several surfaces (door posts 2, north wall 3, angled wall 6, later spots 4), so no single surface to soften. The pilot reacts 0.3-0.9 s late and looks only 1-2.5 units ahead. That makes it weave by construction, and real players look down the long gallery. Phone check below; if testers do weave, lower the gain first: `full_tilt_deg` 25 → 30. |
| Banister handrail crash | **Fair, no action.** It needs a full-strength dive plus a turn started early (x 12), cutting the corner across the well. The rail and balusters are clearly visible on that side (t 19.0, t 20.5). The good line and moderate dives clear it. |
| Plane hard to see through the arch | Item 1. Colour, not camera or furniture. |
| Phone checks (retry, frame rate) | Not a design change. Hand-test list below. Rebuilding the house takes 60 ms on PC (headless), so retry should make 2 s on a phone. |

## Hand-test on the phone (pass marks and fallbacks)

1. **Opening.** The first frame shows the plane with its coral tips over the door, and the ease into the
   follow camera is visible, not a jump.
2. **Weaving after the door turn.** If testers swing into the walls, set `full_tilt_deg` 25 → 30.
3. **Retry.** Crash to flying again takes 2 s or less with a prompt tap. If not, set `card_delay_crash`
   0.45 → 0.30.
4. **Frame rate.** At least 55 fps in the sunbeam (5-9 s) and the stair dive (19-25 s). If not, apply the
   build notes' fallbacks: narrow the downdraft column to x 5-13, then drop it and keep the wisps.
5. **Lamp.** Do testers try it, and do they thread it within 2-3 tries?
6. **Meadow thermal.** Do testers spot it through the window and turn for it?
7. **Plane size in the stair dive.** If it is too small, set `camera_follow_speed` 3.5 → 4.5.

## Later ideas (new systems, for the owner)

- **A ninth style moment:** "ride the meadow thermal to the top", or a "longest glide" line on the end card.
- **Thermal-hopping outdoors** (a second, weaker thermal on a sunny rock) as part of the 90-120 s phase.
- **The close-call whoosh** (item 5), if it counts as a new system.
- **Carried over from earlier reviews:** a "moments hit" strip of eight icons on the end card, and a best-run
  ghost plane.
