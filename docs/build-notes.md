# Build notes: deviations from the plan, and open items

Kept by the lead builder. Anything that departs from `docs/opening-plan.md`, or that needs a
decision from the designer or the owner, is written down here rather than settled silently.

## Deviations from the opening plan

| Where | Plan | Built | Why | Needs |
|---|---|---|---|---|
| Sunbeam angle | Sun about 40° from vertical; window x 85–93, y 15–24.5 | Sun about 18° from vertical (`SUNBEAM_SUN`); window x 83–93.5, y 14.7–24.9 | The lift follows the visible light exactly (code-review fix). At 40° the lift would hug the south wall, away from the centre line the player flies after the turn. The steeper light keeps lift and light on the line. Trade-off: the shaft reads as a high window/clerestory more than a low window. | Signed off (fun review 1) |
| Opening shot length | 0.9 s ease | 0.65 s ease (`camera_intro_duration`) | The brief asks for the follow camera "within the first second" counted from the first frame; the plane also waits a few frames for smooth drawing. The designer's Phase A review approved it. | None |
| Door posts | Square jambs | Rounded posts, radius 0.6, drawn as they collide | A sharp corner turns a light clip into a head-on crash; rounded posts turn it into a bump. | None |
| Cones and lamp shades | (not in plan) | Collide exactly as drawn (convex hull) | They used to collide as full cylinders, an invisible wall (code-review blocker). This also changes the existing living-room lamp shade and the outdoor trees slightly. | None |
| Mobile in the bedroom | (dressing) | No collision | Soft paper birds on strings; the plane brushes through. | None |
| Hall table props | Props below y 16 | Plant reaches y 18.5 and a photo frame 17.4, both solid | A plant on a hall table; solid so what you see is what you hit. Sticks out 1.9 from the north wall at x 26.5–33.5; the flying corridor stays clear. | Designer FYI |
| Arch header | Rise 4 over 5.7 (35°) | Rise 6 over 8.6 (still 35°), top drawn as a visible ledge, darker underside band | Catches floaters arriving up to y 17.5 as well as those the downdraft brings lower; the floater sweep (18 never-diving pilots) has 0 arch crashes with it and 17 without. | Signed off (fun review 1) |
| Newel posts | 0.5 x 0.5 box posts | Round posts with ball tops, all solid | Round posts make a clipped corner a glancing bump; the ball tops collide as drawn. | None |
| Meadow landmark (fun review 1, item 2) | Optional stream with a low footbridge near z -150 | Stream with flat stepping stones, no footbridge | Anything standing up where planes come down to land could turn a good run into a crash at the very end; a flat stream gives the beat without the risk. | Designer FYI |
| Lamp moment (fun review 1, item 3) | Plan section 4: a 1.9-unit gap, shade bottom y 5.0, table top 3.1 | A 2.7-unit gap: shade bottom 5.5 (rim radius 1.7, was 2.0), table top 2.8 | The designer's fix for the cliff; path, corridor and points unchanged. `docs/opening-plan.md` still shows the old numbers. | None (designer's own fix) |
| Gold "Perfect!" (fun review 2, item 3) | Plan section 4: quality 0.85 (about 43% of the radius) | Quality 0.95 (about 35%) | The designer's fix: gold had become the normal result. Points unchanged. `docs/opening-plan.md` still shows 0.85. | None (designer's own fix) |
| Skylight light | Light source 14 up | Visible shaft reaches the ceiling pane; lift stops at y 24.5 as planned; pane sized to the shaft | The shaft looked disconnected from its skylight. | None |

## What lives in `scripts/tuning.gd`

Every number that changes how the game feels: flight, air, collisions, controls, camera
(distance, height, look-ahead, smoothing, lean, field of view, opening shot, shake), sound
(volumes, wind swell, tap), style pop-ups, end-card delays, the plane's turn and bump wobble,
and scoring. Left in code on purpose, as look or layout rather than feel: lighting and colours,
screen layout of the readouts and end card, the "tilt to fly" hint, the end card's 0.25 s
fade-in, the crash crumple animation, the camera's clearance from walls, and the start-of-run
hold (the throw waits for a few smooth frames, at most 2 s).

## Designer's Phase A review (`docs/review-phase-a.md`): where each item went

| # | Item | Done in |
|---|---|---|
| 1 | Sloped header on the stair side of the arch, so non-divers glance through | Section 6 (arch): 35° slope as asked, but rising 6 over 8.6 (plan: 4 over 5.7) so it also catches floaters arriving up to y 17.5; its top is drawn as a visible ledge; underside band slightly darker. Fully effective together with the stairwell downdraft (Section 7), which brings floaters down to the header's range; Section 7 adds the designer's floater sweep (from the gallery, never diving) as an end-to-end test. |
| 2 | `landing_turn` radius 2.0 → 3.0 | Section 8 (scoring) |
| 3 | `stair_downdraft` radius 2.0 → 1.5 | Section 8 (scoring) |
| 4 | Stronger wind swell in the dive | Phase B fix 4 (fun review 1, item 4): the stair dive is about 10 dB louder than gallery cruising |
| 5 | Sunbeam path heights to match the real lift; test pilot uses the course's own paths | Section 8 (scoring) |
| 6 | Light shafts drawn 0.2 inside walls (no flicker) | Section 3 (sunbeam) |
| 7 | End card: "79 m = 791" and "N of 8 moments" | Section 8 (scoring) |

## Decisions for the owner

- **Phase B changes parts of the original demo.** The brief says the old sequence "continues
  unchanged" after the new opening, and also asks Phase B to make the whole flight fun through
  layout, tuning and feel. The lead read "unchanged" as describing how the opening joins the old
  demo (Phase A), and Phase B as allowing layout changes anywhere; the designer flagged the
  tension. Changes to the old demo so far: a meadow thermal, hay field, stream and a wider
  tree-free valley outdoors (fun review 1, item 2). To undo: revert the commit "Phase B fix 2:
  a meadow thermal past the window" (it also carries the tests and the test pilot's new line).
  Also more room under the dining lamp (fun review 1, item 3): the lamp hangs 0.5 higher, its
  shade is a little narrower and the table 0.3 lower. To undo: revert the commit "Phase B fix 3:
  more room under the dining lamp" (it also carries the test that needs the room), but keep its
  longer test watchdog (`TIME_LIMIT` in `tests/run_tests.gd`).
- A lavender field is painted on the valley floor where a good glide comes down (fun review 2,
  item 4): a last thing to aim for, paint only. To undo: remove the `_ground_patch` call for
  `LAVENDER_X` in `scripts/course.gd` and the lavender checks in `tests/test_course.gd` and
  `tools/flight_log.gd`.
- The kettle steam now reaches down to y 3.0 (it started at 4.2) and is taller, so its top
  stays at 11.2 (fun review 2, item 1): planes coming into the kitchen low catch it instead of
  hitting the counter under the window. To undo: revert the commit "Phase B round 2, fix 1:
  the kettle steam reaches low planes" (it also carries the test).
- Close calls (fun review 1, item 5): rushing past a surface within 1 unit at 7.5 u/s or more,
  and getting clear again without touching it, gives a soft whoosh and a short swell of wind
  (once clear, so flying into a wall never sounds like a reward). It needs a small proximity
  check every tick; the lead counts that as an effect the brief asks for ("close calls ... feel
  good through ... a soft whoosh"), not a new game system. Clean lines never trigger it;
  moderate dives that skim the stairs get one or two; a pass that touches anything gets none. To undo: set `close_call_speed` to 1000 in `scripts/tuning.gd`.
- Bursting out of the window now also gets a gust of wind, a soft whoosh and a view that widens
  (70 to 76 degrees) outdoors (fun review 1, item 4). To undo: set `window_gust_db` to 0,
  `whoosh_volume_db` to -80 and `camera_fov_outside` to 70 in `scripts/tuning.gd`.

## Open items: settled in the fun reviews

- **60 s target:** met. A skilled test-pilot run lasts 60.4 s and novices 60.2-61.9 s (fun review 1,
  item 2). The longest stretch without a new event is 6.3 s, from entering the meadow thermal
  (46.0 s, climbing for the first 2 s) to the stream (52.4 s); the lavender field (fun review 2,
  item 4) splits the final glide into 3.7 s and 4.3 s.
- **Lamp moment:** fixed, more room under the lamp (fun review 1, item 3).
- **Late first-timers weaving after the door turn:** no layout change; check on the phone
  (fun review 1; fallback `full_tilt_deg` 25 -> 30).
- **Banister handrail crash on a full-strength early-turning dive:** fair, no action (fun review 1).
- **Plane hard to see through the arch:** fixed by the felt-pen wing tips (fun review 1, item 1).
- **Window whoosh** (the lead's addition): signed off (fun review 2).
- **Camera under the lamp shade's rim, the shade's top at y 7.1, gentle divers low into the
  kitchen:** keep as they are (fun review 2; the kitchen also got lower steam, item 1).
- **A steady circle in the meadow thermal never ends:** keep; it earns nothing and the player
  leaves when they like (fun review 2).

## Still open: the owner's phone test

The designer's list, with pass marks and fallback numbers, is in `docs/fun-review-2.md` ("Wait
for the phone test"). From the build:

- Tilt directions match the README's controls table (if not: `invert_tilt_pitch` /
  `invert_tilt_roll` in `scripts/tuning.gd`).
- Crash to flying again in about 2 s ("Fly again" rebuilds the house in code, about 60 ms on PC;
  fallback `card_delay_crash` 0.45 -> 0.30).
- Frame rate (PC captures dip to about 40-50 fps in these stretches):
  - **Stair dive:** the downdraft column (which the camera flies through), two light shafts and
    three sets of motes and wisps can all be in view on top of the watercolour pass. Fallbacks:
    narrow the column to the window's width (x 5-13), or drop the column and keep the falling
    wisps.
  - **Kitchen:** the steam's column is now taller and reaches below the counter top.
  - **Meadow thermal:** the largest column (radius about 4.5, 12 high, 110 motes), and the camera
    flies inside it. Fallbacks: fewer motes, or draw only the column's front faces.
  - **The sunbeam and the arch.**
- Listen to a fast close call in the stair dive (wind at its +2 dB ceiling plus the whoosh) for
  any crackle; if it clips, lower `wind_max_db`.

# Phase 3: the balloon and the outside (docs/outside-plan.md)

## Deviations from the outside plan

| Where | Plan | Built | Why |
|---|---|---|---|
| Hay bales | 5 bales on the hay field | 5 bales out at the sides of the field (|x| ≥ 8 from the line) | A bale on the line out of the window crashed planes that came down low and straight. |
| Picnic blanket | Landing rectangle x -77..-67, z -209.5..-200.5 | Blanket drawn at x -75..-69, z -202.5..-207.5; the 2 u slide margin is added when scoring the landing | So `PICNIC_X/Z` is exactly what you see. |
| Outdoor motes | clamp(r² × 1.2, 110, 170), 1 in 4 a seed or leaf | clamp(r² × 0.8, 80, 120), all motes | Phone frame budget (code review). |
| Bonfire smoke | Puffs live 8 s | 40 puffs, 8 s, fading out 4-10 u from the camera | Phone frame budget: big see-through puffs close to the camera are costly (code review). |
| Air-zone visuals | Not covered | Indoor zones are drawn only while the camera is in the house, outdoor zones from the kitchen on, and outdoor ones not beyond 150 u | Phone frame budget (code review). The air itself always works. |
| Trees near the picnic | None within 8 u of the blanket | None within 16 u (`PICNIC_CLEARANCE`) | A full-bank circle down onto the blanket (radius about 5.6) passed through tree crowns 8 u out. |
| Plan step 3 test (tour pilot, ≥ 12 above the ground at each thermal, lands ≥ 55 s after the window) | Step 3 | Step 8, with the new pilots | Done in step 8: `test_outdoor_routes_fly_the_chain_the_ridge_and_the_picnic`. |

## Phase 3: check on the phone

- **Balloon:** "Fly the balloon" on the end card. Does it feel better to fly than the plane? Is the string calm in flight (no jitter or whipping)? Does a crash pop it? Is the bigger plane (1.3x, `look_scale`) the right size?
- **Finding lift outside:** fly straight out of the window. Does the hay field's warm air carry you up? Do the clouds and circling birds tell you where the next lift is?
- **Staying in lift:** does "Keep circling to climb" appear on your first low entry, and do the beeps help you stay in the warm air? If circling still loses the lift, the fallback is hay-field radius 12 -> 14 (fun review 3, item 7).
- **Ridge:** from the hay field's top, can you see the kite and the hovering birds on the left hillside? Does flying along it carry you up?
- **Frame rate, 60 fps pass bar:**
  - circling inside the bonfire smoke (fallbacks: puff size 3.2 -> 2.6, or the scale curve's end 1.6 -> 1.2);
  - the top of the hay field, the barn's top, along the ridge, and the kitchen looking out of the window;
  - first cut if slow: outdoor motes to clamp(r² × 0.8, 50, 80), then ridge seeds 160 -> 100.
- **Landing bonuses:** the lavender (+200) and the picnic blanket on the plateau (+400, the hard one).

# Phase 4: deeper flying and more world (docs/phase4-plan.md)

## Deviations from the Phase 4 plan

- **Lift-lost sigh (A2), a fifth rule:** the sigh also needs the air at the plane to have dropped
  to `lift_lost_air_drop` (0.5) of the strongest air felt during that climb. Without it, pulling
  into a dive in the middle of a thermal stops the beeps and would sigh, though no lift was lost.
  The risk: on a weaker column, an exit where the beeps stop while the air is still over half its
  peak stays silent. When drift (A1) lands, a test checks that a naive off-centre orbit in
  BarnHeat still sighs at least once per drifted lap.
- **Measured:** the four skilled routes sigh 0 times and land and score as before; 10 novice
  flights sighed 5 times in all, each a side exit from the hay field at y 16-18 (the plan
  expected 1-4 per novice; most novices pass through too briefly to have beeped 1.5 s).
- **Drift (A1), measured weaker than the plan's sim:** real climbs are quick (BarnHeat from y 5
  to 2 below its top in about 8 s), so the air slides only about 2 units during a climb. A pilot
  who re-centres gets there in 8.2 s and one who circles the old spot in 9.5 s (14% slower, not
  the plan's 20%); neither hears a sigh. The four routes still land where they did (chain
  118.8 s, was 114.5 s). For fun review 4: drift is a gentle nudge as tuned. If it should teach
  re-centring, try a faster drift (`thermal_drift_speed` 0.5) rather than a bigger cap.
  **Open for the owner and fun review 4:** drift does not separate the two pilots by sighs (0 and
  0; the plan's sim had 4 and 1), so as tuned it does not yet teach re-centring.
- **Drift resets each run** because "Fly again" reloads the scene, which builds new thermals.
- **Cloud thinning (A3), one rule added:** a cloud thins only while the plane is climbing in lift
  (the beeps are on) near its top, so gliding high over a thermal after topping out in another
  doesn't thin it.
