# Fun review 2: the whole flight (Phase B, step 7)

**Verdict: SEND BACK (small).** Make four cheap changes (the steam's height, effects and camera, one
scoring number, one painted field), then stop and hand it to the owner. Every open item marked "for review 2" is judged below. None of
them needs a change before the phone test.

Sources:
- The lead's screenshots and logs (`scratchpad/phaseB2`).
- My own runs in a scratch copy (`scratchpad/designer2/pp`). Its probe `tools/d2_probe.gd` adds:
  - a skill knob: a smooth random offset of the test pilot's line, called `--amp` below
  - a thermal-circling pilot and a free-glide pilot
  - camera-angle and per-moment offset traces
- The trial code for items 1, 2 and 4 is in `scratchpad/designer2/trial.diff`. Before/after pictures are in
  `scratchpad/designer2`: `steam_grid.png`, `final_cmp.png`, `cols2_cmp.png`, `lavender_grid.png` and
  `lamp_grid.png`.
- Nothing in the repo was touched except this file.

How I modelled skill: `--amp=A` pushes a novice's line off the optimal one by up to A units sideways and
0.7·A units up or down. The offset changes slowly (over about 55 and 145 units), like a player who roughly
knows where to go. I read A = 0 as a player who knows the line, 1-1.5 as getting there, and 2-3 as a
first-timer.

---

## Do now (ranked)

### 1. MUST: The kitchen steam misses low planes, so imperfect players crash just before the window (fair failure, window reveal)
- **Evidence.** For imperfect pilots, the counter under the window is the most common crash site. It costs
  the window reveal and the whole outdoors, at 43-48 s.

| Line offset (20 novices each) | 1 | 1.5 | 2 | 3 |
|---|---|---|---|---|
| Crashes at the window counter or sill | 2 of 2 crashes | 3 of 3 | 1 of 3 | 7 of 10 |

  - Traced: these planes reach the steam (z -65 to -70) at y 3.4-4.7 and 4-6 u/s. The steam zone starts
    at y 4.2 and needs another unit to reach full strength, so they get little or no lift.
  - A plane gliding down the middle of the kitchen from the door (y ≈ 5.5) loses about 3.5 units by the
    window. It meets the counter (top 3.7) below the window (bottom 4.5).
- **Fix (layout).** Let the warm air from the stove reach down to below the counter top. Keep the top where it is:
  - `KETTLE_THERMAL` y **4.2 → 3.0**
  - KettleSteam height **7.0 → 8.2** (the top stays at 11.2)
  - KettleSteam `source_offset` y **0.45 → 1.65**, so the puffs still leave the spout
- **Measured in the copy:**

| Line offset | 1 | 1.5 | 2 | 3 |
|---|---|---|---|---|
| Reach outside, before → after | 18 → **20** | 17 → **20** | 17 → **18** | 9 → **14** |
| Kitchen crashes, before → after | 2 → **0** | 3 → **0** | 1 → **0** | 7 → **3** |

  - Across those 80 runs, kitchen crashes fall from 13 to 3.
  - Unchanged: the skilled run (60.4 s, 719, steam entered at y 5.8) and 20 on-line novices (identical numbers).
  - The lamp line is unchanged too (firmness 0.45: 0/20 crash).
- **Owner note.** This is a small change to the old demo, like the lamp. Please list it in "Decisions for the owner".

### 2. MUST: Inside warm air you lose the plane (readable)
- **Evidence** (the lead's `15_t031.0.png`, my traces):
  1. **Motes near the camera fill the screen.** Warm-air motes are about 0.5 units across. One that passes
     within a unit of the camera fills 40-70% of the screen height.
  2. **The column's inside washes the view.** Inside the column, its far wall puts an orange wash at
     30-60% opacity over everything. At t 31 the lamp, which the player must choose to go under or beside,
     is hazy.
  3. **The plane is seen edge-on.** In the radiator's climb (+4 u/s) the camera lags and ends up level with
     the plane. It looks down only **1-2°** at t 30.7-31.0, against 11-12° in normal flight.
     - The meadow thermal shows the same at t 47: the plane is a dotted line.
- **Fix (effects and camera):**
  - Motes and steam puffs fade out near the camera. In `Thermal._build_wisps()`, set
    `distance_fade_mode = DISTANCE_FADE_PIXEL_ALPHA`, min **1.2**, max **3.5**.
  - Columns fade near the camera. In `thermal_column.gdshader`:
    `ALPHA *= mix(0.35, 1.0, smoothstep(2.0, 8.0, length(VERTEX)))`.
    - Seen from the arch or the kitchen window, the columns look the same as now (`cols2_cmp.png`).
  - The camera rises with the plane in rising air. Add a new tuning value `camera_lift_lead` = **0.25 s**:
    in `_resting_spot()`, add `UP * max(velocity.y, 0) * camera_lift_lead`.
    - Measured: the camera looks down **9-12°** through the radiator and meadow climbs (was 1-2°).
    - Dives are unchanged, because it only acts on upward speed.
- **Result** (`final_cmp.png`):
  - The big blobs and most of the wash are gone. The lamp and the kitchen door read at t 31.
  - At t 47 the plane is visible over the stream.
- **What remains.** At the exact moment the pilot pushes the nose down over the top of the lift, the plane
  is still seen from slightly below for about 0.2 s. I accept that. Raising `camera_height` would fix it,
  but it pushes the camera into the lamp shade and the door headers.

### 3. SHOULD: "Perfect!" is the normal result (style points feel earned)
- **Why the logs show novices (654-787) level with the skilled pilot (719).**
  - Both fly the course's own optimal paths. The "novice" is an expert who knows the line and has wobbly
    hands.
  - A moment is graded on the average distance from its path. Wobble averages out: it moves the plane a few
    tenths of a unit, while full marks reach out to 25% of the corridor radius (0.4-0.75 units).
  - The "skilled" pilot is not more accurate. Its long look-ahead (3 units + 0.4 s × speed) cuts the door
    and landing corners:
    - average offset 0.47 and 0.49 of the radius on the sunbeam and landing turn
    - novice medians 0.30 and 0.47
  - Its lower climb limit is not the cause: with `max_climb` 0.5 it scores 708.
- **What actually separates players** is how close they fly to the path:

| Line offset (20 novices each) | 0 | 1 | 1.5 | 2 | 3 |
|---|---|---|---|---|---|
| Style, median (range) | 743 (517-790) | 608 (328-742) | 491 (234-666) | 402 (126-585) | 148 (40-432) |
| Crashes | 0 | 2 | 3 | 3 | 10 |
| Passes shown "Perfect!" now (quality ≥ 0.85) | **81%** | 48% | 40% | 34% | 17% |
| ... with `style_perfect_quality` 0.95 | 62% | 34% | 25% | 16% | 6% |

  - **Points:** they already do what the brief asks. First-timers earn a few (150-400). Players who know
    the line earn 600-790 and still have the lamp (150) to chase.
  - **Gold pop-up:** too common. Quality 0.85 only needs an average offset within 43% of the radius
    (about 1.1 units on a 2.5 corridor). Four of five passes on the line turn gold, and so does one in
    three passes from a player 2 units off.
- **Fix (scoring, one number):** `style_perfect_quality` **0.85 → 0.95**.
  - Points stay the same. A gold pass then means an average offset within 35% of the radius.
  - The landing turn stays the hardest gold (20% on the line). The kettle and the window stay easy golds,
    which suits the payoff.
  - I tried a tighter points curve (`style_full_fraction` 0.25 → 0.15). It makes the radiator gold
    impossible for the test line, so I don't recommend it.

### 4. SHOULD: The last glide has nothing to aim at (no dead air)
- **Evidence.** The stream (52.4 s) is followed by 7.0 s of glide to touchdown (59.4 s), then a 1 s slide:
  8.0 s with nothing new. Screens t 52.5-59 are almost the same picture.
- **Fix (layout, paint only):** a lavender field where a good glide comes down.
  - `_ground_patch(-12, 2, -170, -194, 1.0, [b9a6dc, d3c6ea, aed092])`: rows of lilac and pale lilac with
    grass between, painted like the hay field. It does not collide.
  - Seen from the thermal's top and from the stream, it reads as a target: "land in the lavender".
    Coral wing tips stand out on lilac. I tried pink first; the tips vanished on it.
  - The skilled run crosses its edge at about t 56.0 and touches down inside it (z -187).
  - The gaps become: thermal top → stream 4.4 s, stream → lavender 3.6 s, lavender → touchdown 3.4 s.
  - A pilot who skips the thermal lands at about z -141, short of the stream, with the stream and the
    lavender ahead: a visible reason to take the lift next time.
- **Flight log (lead's call):** add "passes over the lavender" as a landmark, like the stream.

---

## Open items judged: no change now

| Item | Judgement |
|---|---|
| **A steady circle in the meadow thermal never ends** | **Fine; keep.** (1) The circle holds at y 12.7 and earns nothing. (2) Circling to the top before gliding on adds only **0.6 m (6 points)** over flying straight through (y 11.4): free glides land at z -191.5 against -188.9. (3) It is a harmless place to play, and the player leaves whenever they like. (4) The decision that matters is turning into the thermal at all: +12 m and +10 s (review 1). (5) A taller thermal (18) adds only 3-5 m for a 12-25 s circle, because the valley floor rises to meet the glide, so it is not worth it. (6) Fading the thermal over time would be a new mechanic, so it is under Later ideas. |
| **Window whoosh** (lead's addition) | **Signed off.** The gust and whoosh come as the plane crosses the wall (41.5 s), the view widens 70° → 76° by 43 s, and the style pop-up follows at 42.2 s. The order (rush, then reward) is right, and the whoosh (0.8 s) has ended by the time the pop-up sounds. Optional, can wait: play it at `pitch_scale` 0.85 so it sounds deeper than a close call. |
| **Camera just under the lamp shade's rim** | **Keep.** At t 34.8-35.0 the shade's underside fills the top ~45% of the view for about 0.3 s, and the bulb shows (`lamp_grid.png`). The plane and the doorway stay visible below, and a close call fires there (8.0 u/s). It is the best near miss indoors. |
| **Shade top at y 7.1** | **Fair; keep.** The plane visibly overlaps the shade when it catches it. The course line beside the lamp passes 1.2 units clear. |
| **Gentle divers under the lamp, too low for the steam** | **Fair; keep.** At pitch firmness 0.38, 17/20 earn the lamp and 2 crash in the kitchen. Both scraped the shade's front edge (a tap and shake at (0.7, 5.3, -43.2)), slowed to 4.1-4.4 u/s, stalled at z -62 to -66 (the nose drops to -31°) and reached the steam at y 2.6-2.9. The chain is visible, and item 1 does not save these two. At firmness 0.45: 0/20 crash. |
| **Close calls** | **Working as intended.** Clean lines never trigger one, which is why the logs show none. Sloppier pilots do: offset 1 gives 3 in 20 runs and offset 2 gives 13 in 20, at the stair-hall wall beside the second flight, beside the lamp and at the kitchen door. |
| **Other gaps in the log** (gallery 5.9 s, skylight to stairs 5.1 s, arch to radiator 5.5 s) | **Keep.** As in review 1, the next cue is in view each time: the skylight shaft, the stairwell wisps, the radiator motes. |

## Wait for the phone test (watch for this; fallback if it happens)

1. **Gold pop-ups.** A decent run should show 1-3. If testers never see gold in five runs, set
   `style_perfect_quality` 0.95 → 0.92.
2. **Kitchen.** If testers still crash into the window counter, widen the steam: radius 3.4 → 4.0.
3. **Lamp.** Do testers try it, and thread it within 2-3 tries?
4. **Reading the plane in the radiator heat (t 30-32).** If it is still hard to follow, set `camera_lift_lead` 0.25 → 0.35.
5. **Lavender.** Do testers aim for it? Do they turn for the meadow thermal?
6. **Frame rate** in the sunbeam, the stair dive, the arch and the meadow column: the PC captures dip to
   about 40 fps there. Use the build notes' fallbacks.
7. **Unchanged from review 1:**
   - Weaving after the door turn: `full_tilt_deg` 25 → 30.
   - Plane too small in the stair dive: `camera_follow_speed` 3.5 → 4.5.
   - Retry in 2 s or less: `card_delay_crash` 0.45 → 0.30.
   - Crackle on a fast close call: lower `wind_max_db`.

## Correction to fun review 1

Item 2 said a skilled player "can climb to about y 13 and fly much further". That is wrong. Measured, circling to
the top adds about 0.6 m. The meadow thermal's value is the turn into it, not the climb.

## Later ideas (new systems, for the owner)

- **A fading or "topped-out" meadow thermal, or thermal-hopping:** a second, weaker thermal on a sunny rock
  and a flatter far valley, so that circling higher pays. Fits the 90-120 s phase.
- **"Landed in the lavender"** as a ninth style moment or an end-card line.
- **A skill knob for the test pilot** (line offset, as in my probe) in `tools/flight_log.gd`, so future
  reviews compare players by accuracy, not by look-ahead. Tooling, so it is the lead's call.
- **Carried over:** a "moments hit" strip on the end card, and a best-run ghost plane.
