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
- **The ground past the valley (B1), measured against the plan:**
  - The Gap's floor now ends on the lake bed (-1.15, the plan had -1.5) and the cut runs to z -400,
    where the bowl is already flat bed, so there is no step where the cut ends. The channel is
    0.3 u higher at z -370 (1.8, plan 1.5).
  - Ground beyond the lake's edge (q > 1.15) is kept above the water, so the bowl's rolls make
    no stray ponds; the only water outside the lake's sheet is the inlet at the Gap's stream mouth.
  - Sand is painted on the grass triangles that cross the waterline, not as a ring (a ring
    missed the real, jagged shoreline).
  - Bowl trees (orchard and pines) come with the landmarks in step 8.
  - **For the owner:** the plan says the Downs are 45 or higher beyond 30 u of the Gap; the
    lowest crossing there is 31.7 at x -25, on the Gap's left shoulder (the crest at x -24 is
    30.2). From the ridge top (33) a pilot could skim over the shoulder instead of through the
    Gap. It lands in the same bowl, so it does no harm; raising the shoulder would stop it.
- **Sink ticks (A2):** they reach their fastest and loudest at 0.4 u/s of sink
  (`sink_tick_air_full`), the lake's strongest, not at the plan's 1.0, which nothing reaches.
- **At the Gap** (camera between z -300 and the crest), only the valley's far end (the ploughed
  field, the bonfire and the chalk pit) and the bowl's zones are drawn, to keep live motes down.
- **Glide arrivals (B2):** each leg arrives at least as high as the plan's pure-glide figure,
  and the chalk legs about 5 higher (they leave one column and end inside the next).
- **Landmarks (B3):**
  - **Windmill on the Gap's right shoulder** (36, -336), not the left: on the left, the chalk
    pit's cloud hid it from the valley. **For fun review 4:** from the kitchen window the hay
    field's warm column and the row of thermal clouds cover the whole far skyline, so neither
    the notch nor the windmill shows from the sill (the plan's B4 first sight line). Both show
    clearly from the valley's far end and the ridge.
  - **The jetty is 13 long** (plan 8) and steps down the bank: the bank slopes gently from the
    boathouse (floor -0.2) to open water about 10 u out, so a flat 8 u deck was half buried.
  - **32 bowl trees** (plan about 24): the orchard's two rows at a 10 u step, plus 6 pines,
    built light (6 x 3 crowns, 5-sided trunks) to stay near the plan's triangle budget.
  - **For fun review 4:** the windmill's sails face the breeze (+X), so from the valley they are
    seen edge-on, a bar turning in place.
  - Moving props (the sails, the sailboat) are a small PropMotion node, moved in `_process` with
    physics interpolation off, like the birds.
- **Scoring past the Gap (B5):** "Through the Gap!" goes on the card for any run that crossed the
  saddle (where the gust blows), not only for one resting past the crest; the beach landing
  starts 2 u in from the waterline (x 42..58, as the plan's rectangle); a fast nose-dive into the
  lake is still a crash (crumple, no splash); only coming to rest on the water is a splashdown.
- **Fun review 4 fixes:** drift 0.5 u/s; a gull for each ridge lift (the ridge and the bluff);
  the far rim lowered (0.013); the windmill's sails turned to face half toward the valley; the
  Gap style path ends at y 13.5; sink ticks quiet within 1 u of the ground or water. The drift
  test's naive pilot hears exactly one sigh, right on its threshold: retuning drift or the sigh
  may need that test's numbers revisited.

# Phase 5: open source, How to fly, and Endless step 1 (docs/endless-plan.md)

## License and About (done first)

- GPL v3 (LICENSE) with additional terms in NOTICE (attribution 7(b), marking 7(c)/(d), name and
  icon 7(e)); a two-line notice on every source file, enforced by a test. Repo public since
  2026-10-13.
- About (Settings > About): the blurb, How to fly, Send feedback (a mailto: draft to
  bartbasi@gmail.com with the version and phone), the address shown too, Source code, License,
  Credits (Godot's notices, FreeType's line, AndroidX and Kotlin). Android Back steps out of pages,
  About and Settings, then closes the game.
- **How to fly** (owner's request): the player's guide, `scripts/how_to_fly.gd`: controls, how
  flying works, every kind of rising and sinking air and how to spot it, sounds, how the Course
  and Endless score, tips. A test checks it names every style moment and gives the landing
  bonuses, scoring numbers and star values as the game has them.

## Deviations from the Endless plan

- **game.gd changed more than "the card's Endless button and unlock line".** Everything both
  modes share (sky, watercolour pass, sounds, vario, sigh, sink ticks, close calls, hint and
  pop-up labels, the end card's frame, Settings, About, Back) moved into a base class,
  `scripts/flight_game.gd`; game.gd keeps the Course's own parts. The Course flies identically:
  the flight logs of all seven routes and ten novices are byte-identical before and after.
- **Decision 9 is a one-time step**: a saved Course best of 1500+ unlocks Endless only when there
  is no progress file yet (the first launch of this version). Checked on every load, a crash with
  a big score could have unlocked it silently.
- **Thermals' Endless drift** is its own method (drift_with_wind) with a life and a fade; the
  Course's drift (toward -X, capped) is unchanged.
- **The Barley Field's spiral of stars forms around the pilot.** A helix laid in advance climbs at
  the same rate as the pilot, so anyone who doesn't arrive at its exact starting height and place
  stays out of step with it all the way up (the test pilot took 0%). Now, once you circle inside
  the thermal, the spiral lays itself a little ahead of you at your own height and distance from
  the middle, turning your way, and re-forms ahead after each star; its stars are taken from 3 u
  (spiral_pickup_radius) because nobody circles exactly. Its stars slide into place (0.5 s). The
  skilled pilot now takes about 60% of them. **For the fun review and the phone:** does it read
  as the stars coming to meet you, or as stars jumping?
- **The good line through the Barley Field dives into the thermal's lower part first** (to y 9 at
  its near edge), then circles up. Arriving high over the field is the usual case (the pieces
  before it leave you high), and the spiral can only be flown from below.
- **Hoops start 20 u in** (plan: 16), every hoop 4 u further: from 16 there was too little room to
  line up from wherever the previous piece ended (the plan's own reaction-distance rule wants
  about 23 u). The Hamlet's chimney stars sit 1.5 u further upstream, clear of the turn to the
  next plume; the Ridge's first star is on the band's line, 4 u further in; the Rim's welcome S is
  a little gentler and back on the middle before its last star.
- **Calibrated numbers** (`tools/endless_log.gd --calibrate`, wind 1.5): the generator's table now
  matches the measured exits within about 1.5 u for every piece at wind 1.5. Two changes:
  Cloud Street's add is (14, 11) (plan 14, 13: at difficulty 1 the street lifts less), and the
  Hamlet's cap is (15, 14.5) (plan 17.5, 16.5: the line holds you near the rooftops whatever
  height you arrive at). So at difficulty 0 only a street can follow the Hamlet. Step 2's rising
  wind will need the table measured again at 1.0-3.0 (at wind 3 the street from its lowest entry
  leaves 3-4 u below the table).
- **The viaduct's deck stars are an alternative line** (counted apart: they don't count against the
  share of stars taken by a pilot who goes under).
- **Test pilots in Endless** pitch firmer (gain 0.7), look a little less far ahead (2.5) and climb
  gently in lift (+0.15; +0.3 sits right at the stall). Novices circle at most about a lap.
- **Clouds and birds**: Endless has its own manager (`scripts/endless/sky.gd`), using the Course's
  puff and bird shapes and the same thinning, since the Course's are built once for fixed thermals.
- **Tiles' meshes are built per piece and difficulty step (0.25)** and kept; continuous lerps in the
  plan are taken at the nearest step.
- **Not in step 1 yet**: the plan's PC frame-time captures and the fair-failure sight-line check
  (no obstacle hidden less than 60 u before it); the hoop's white flash; ribbons don't flutter.

## Endless step 1: measured

- Generator: 10,000 sequences of 30 pieces, no broken rules (a test).
- Skilled pilots, 20 runs of 200 s: all flew 12+ pieces, no crashes or touchdowns, stars taken median
  87% (77-91%). Shaky pilots: 20 of 20 flew 12+ pieces, no crashes, median 83%.
- Calibration: every piece within about 1.5 u of its table at wind 1.5; lowest over the ground
  7.3 u (Long Ridge), nearest solid 3 u (the Hamlet's cottages).

## Endless step 1: check on the phone

The plan's checklist (§10.1): pace at wind 0 / 1.5 / 3.0 (debug button on the card); following
star lines on tilt (Hamlet, Kites); the viaduct dive; the hoops at their smallest; whether every
ending made sense; the retry; frame rate (target 120 fps); the height bar. Plus: the spiral
forming around you.

## Endless step 1: after the code review and fun review 5

- **Shipped code never names the test pilot.** EndlessGame has a `test_pilot` Callable and a
  `run_started` signal; tools and tests attach `Autopilot.fly_endless()`. A test fails if anything
  in scripts/ or scenes/ names a class or path from tests/ or tools/; an exported pack opened with
  last mode Endless flies Endless with no errors.
- **Kits are built a step at a time on the main thread** (EndlessPieces.KitBuild, pumped about
  3 ms a physics tick), from three tiles before a piece is drawn; the longest step measured 3.3 ms
  on the PC. Building them on a worker thread corrupted the engine's shared strings and hung, so
  that was dropped. The ground grid's heights are computed once (each was computed up to four
  times). Collision comes in several shapes of about 1,500 triangles each.
- **A retry resets every sound count and wait** (FlightGame.reset_flight_sounds()); a card timer
  from an earlier run shows nothing (run ids); an unreadable progress file is never overwritten.
- **The HUD's star is drawn**, not a glyph a phone's font may lack.
- **Fun review 5 (all eight items):**
  1. The Barley spiral is laid only after the pilot has turned 120 degrees inside the thermal; its
     next star is 4.5 u of arc ahead (out of reach); at most one spiral star in 0.25 s; the way
     round, radius and climb are judged afresh at every star; 6 stars 40 degrees apart; a re-lay
     that moves no star more than 1 u is skipped. A straight pass takes at most one (a test).
  2. Hamlet: three stars a plume, 5/3/1 u upstream of the chimney, plume 0 from y 15 (line
     starts (-8, 15, -16), (-8, 16, -27)). Cloud Street: from an entry below 23 its stars rise
     from the entry height (1.4 a star at d 0, 1.0 at d 1). Viaduct dive: 6 stars from z -16.
  3. A touch on a slope steeper than about 25 degrees nudges you off like a bump; a touchdown is
     flat ground or half a second of sliding.
  4. The look-back eye is (-6, 2.5, -9): the balloon sits clear of the lake and the Gap.
  5. Full difficulty at 400 m (step 2 sets 1,000 with the rising wind).
  6. "The breeze is behind you: fly on!" when heading back near the start.
  7. The card says where: "Touchdown in the Hamlet".
  8. How to fly: the designer's text changes (opener, beeps, ridges, sounds, the viaduct wall, the
     spiral, the paper plane, "Follow the stars").
- **Measured after the fixes** (skilled, 8 runs of 200 s): all flew 12+ pieces, no crashes; stars
  taken median 94%; spiral 21 of 21 full; chimneys 95%, street 96%, dive 92%.
- **Not done from the reviews (later):** the hands-off, middle and star-chaser pilots in
  endless_log for the step 2 novice marks; wind 3.0 batch; the content and mesh steps could be
  split further if the phone shows dropped frames.

## Endless step 2: pace and variety (built)

What's in (docs/endless-plan.md §10.2):

- **The rising wind**: T = lerp(1.0, 3.0) over 0-1,000 m, then +0.1 per 100 m up to 3.5
  (`EndlessGame.wind_at()`, Tuning `endless_wind_start/_full/_rise/_max`). Full difficulty at
  1,000 m. The debug button on the card now cycles rising / 0 / 1.5 / 3.0.
- **Recentring**: past world z -4,600 the whole world moves 42 tiles (4,032 u) toward +z between
  two physics ticks: pieces (zones ride along), stars, clouds, birds, the flyer (and its string),
  the camera, the gull, the test pilot's line. `EndlessWorld.shift` keeps tiles, distance and the
  wrong-way check in the original coordinates. Thermal wisps (world-space particles) are refilled
  in place, already spread through the air.
- **Six pieces**: Pasture, Washing Lines, Poplar Row, Dutch Barn, Standing Stones, Mere.
- **The best-distance bunting**: pennants across the valley where your best run ended (hung in
  whichever piece holds that spot), a chime and "Past your best!" once per run as you cross.
- **Calibration re-measured with the wind each distance brings** (1.0 at d 0, 2.0 at d 0.5, 3.0 at
  d 1), entering at each piece's need, at 18 and at 26. The table's outs sit a little under the
  measurements; the tool now waits for the pilot to finish circling before reading the height.
- **How to fly** gains the rising wind, low warm air, the copper's steam, the solid new pieces,
  the washing, the Mere and its splashdown, and the bunting.

Deviations from the plan (all mine, from calibration):

- **Low warm layers.** The Pasture's hedge-hop and the Washing Lines' duck-under were impossible on
  a glide (3-4 u lost between hedges or lines), so both have a weak box of rising air under 9 / 7 u
  (about 0.75 u/s up: it roughly holds a glide level). Above it the safe line sinks as usual.
- **Pasture**: hedges at z -32 / -56 / -80 (not -24 / -50 / -76) so there's room to dive to the
  first; the bonfire on the line at (0, -90), smoke R 5.5, peak 7.5 (plan 4.5 / 6.5), smoke stars up
  the climb a pilot really makes. Skim over the hedge tops lerp(3.0, 2.25) (plan 2.0 at d 1 would
  sit exactly 2 u from the hedge, against the stars' 2 u rule).
- **Washing Lines**: lines at z -36 / -52 / -68; the wash-house chimney's plume became a **washing
  copper's steam** wide enough to circle (R 8, peak 4.5, drifts like a thermal) with a spiral of
  stars, because a straight pass through an R 4 plume gave 7-8 u out against the plan's 14. Over the
  lines: 3 "alt" stars (not counted in the star share).
- **Poplar Row**: a second street after the row (z -58..-92) as well as the one before, so the
  piece has lift after the gap (otherwise ~6 u out). Trees are spaced every 4 u outward from the
  gap's two sides, so at d 1 no second, narrower gap opens beside it.
- **Dutch Barn**: at z -44..-64 (plan -40..-60), the heap thermal at (0, -78); the dive's first
  stars start from the entry height when entering low; the stars out of the barn became a spiral
  up the heap; 3 alt stars over the roof.
- **Standing Stones**: ring radius 14 (plan 12) for 6 u gates between 2 u stones, centred at
  z -56. With 11 stones, straight across from a gate is a stone, so the way out is the gate just
  left of straight ahead, and the thermal stands 26 u beyond it.
- **Mere**: the water itself is solid, so touching it is a splashdown ("Splashdown on the Mere");
  the sink is a box over the water at lerp(0.4, 0.6) u/s.
- **High lines.** Pieces whose bold line dives to a low opening (Washing, Barn, Stones) have a
  second ideal line over the top for entries at 21 or above (`Kit.high_points`,
  `EndlessPieces.HIGH_FROM`). Test pilots get both and take one just before the piece, by the
  height they really have (and the high one whenever the dive would be steeper than about 19°).
- **The generator looks two pieces ahead.** With low-exit pieces (Washing then Pasture) a
  one-piece look-ahead could corner the run into repeating the rescue street. It now tries picks
  in the usual weighted order and takes the first that leaves a fair choice two pieces on
  (`LOOK_AHEAD`); its look-ahead also respects each piece's first distance.
- **Tools**: `endless_log --from=500` flies as if the run began 500 m along; `--pilot=handsoff`
  never touches the controls; the summary counts runs that flew 10 and 20 pieces; `--calibrate
  --piece=ID` (without --quiet) prints that piece's events.

## Endless step 2: after the code review and fun review 6

Code review (approved, two should-fixes, done):

- **Recentring and physics**: the moved pieces' bodies are pushed to the physics server at once, so
  the flyer's move in the same tick meets the ground where it now is (a test checks the ground is
  under the flyer in the very tick of a recentre; it fails without the fix).
- **Wisps on a recentre** get 1.5 s of head start (not their whole life), only within 200 u.
- Nits: `shift` cleared in `setup()` and at every `start_run()`; `terrain_height` passes the
  unshifted z to the Course; the sock has its own RNG; the stars' recentre comment.

Fun review 6 (sent back; all items addressed):

1. **Stars show the line for your height.** At a two-line piece's entry the game decides by the
   flyer's height (`Kit.takes_high()`: at or above `HIGH_FROM`, or a dive to the low line's lowest
   point steeper than `STEEPEST_DIVE` 0.35). Low: the high line's stars are hidden and can't be
   taken. High: the low line's dim and are alt. Before the entry the high line's are alt.
2. **High lines rarer**: Washing, Barn and Stones weigh ×0.25 when the good pilot's height is 21+
   (`HIGH_ENTRY_WEIGHT`); the over-the-washing stars step down 12.5 / 11.5 / 10.5.
3. **The spiral** (broken since step 1): strong thermals topped out the pilot in half a lap, before
   the 120° anchor, and stars were laid above where climbs end. Now: laid after 45° of turning
   while circling at least 3.5 u out (`SPIRAL_FROM_MIDDLE`), never above top − 2.5. The copper's
   column is R 10 (R 8 was narrower than the pilot's circle).
4. **Lift off the middle line**: bonfire (7, −90), copper (9, −84), island (−10, −58), poplar
   streets 10 wide; the hedge-hop stars step 0 / 2.5 / 5 toward the bonfire, the under-washing
   stars 0 / 1.5 / 3 toward the copper, the smoke stars on the traced climb.
5. **First stars**: no hedge-hop star before hedge 1; the Mere's arc from (0, 15, −22), 7 stars; the
   poplar gap's first two at 11 / 10.5; the stones' way in from z −28. Arcs that lead down from the
   entry (barn dive, stones, poplar gap, Mere) slide their first stars lower when the flyer enters
   lower than they were laid for (`EndlessStars.fit_to_entry()`; never higher). Ideal lines fixed
   for the barn dive (down the stars), the Mere and the poplar gap.
6. **Tools**: `--pilot=chaser|nocircle|middle` (FirstTimer, tests/first_timer.gd); star pickups
   count as events in the dead-air gaps.
7. How to fly ("skim", "fly over them", the stars-show-your-line sentence); the ground under the
   warm layers tinted hay-gold; the stones' line lined up through the exit gate. **Not done**: the
   Pasture's exit stays 13 / 11 (the smoke stars now reach about 12.5; a straight pass through the
   smoke can't give 15 without circling it).
8. **The breeze freshens**: a gust and "The breeze is freshening" at 250, 500 and 1,000 m (rising
   wind only); the wind bed +2 dB from T 1 to T 3.

Also: the barn's door at d 1 is 6.5 × 6.5 (was 6 × 5.5) and its dive's last star at through + 0.5,
after chasers still clipped the lintel late in runs; the washing sheets drawn both ways round.

Measured after (20 runs each, 420 s; shaky from 500 m 300 s):

| Pilot | Result |
|---|---|
| Skilled | all 420 s, stars median 88-90% (82-93%) |
| Shaky | all 420 s, 86-87%; from 500 m all 300 s, 82-86% |
| Chaser / no-circle | 40 of 40 flew 420 s; 0 barn endings |
| Hands-off | median ~130 s (65-238), 3 of 20 past 12 pieces |
| Middle-flyer | median ~140 s (65-246) |
| Spirals (skilled) | Barley 93-97% (31 of 35, 38 of 41 full), copper 100%, heap 93%, island 100% |
| Low line flown (skilled) | Barn 15 of 18, Washing 17 of 21, Stones: high line has no stars |
| First stars (skilled) | hedge-hop 85% / 64%, barn dive 40-47%, Mere 59-61%, poplar gap 35-62% (all full from a typical entry in traces; the misses are high or circling entries) |

Follow-up code review (approved): the barn's round door edges sat 0.3 u inside the drawn frame
(the cylinders were centred on the cut, not just outside it); now the solid doorway is the drawn
one plus the grace on every side (a test checks both, at d 0 and 1). New unit tests cover the
two-line stars, fit_to_entry, takes_high, the spiral waiting until you circle out from the middle,
and the freshening cue. A piece counts as entered only once it is spawned. `from_entry` is clamped
to its arc; tools starting further on (--from) skip the freshening marks already passed.
Fun review 6 re-check: approved, with revised marks (hands-off median 45-150 s, at most 3 of 20
past 12 pieces, none past 20; first stars recorded, each arc full in calibration from need and 18).
Step 3 follow-ups from it: the Standing Stones' 0-of-9 run after a spiral across the join, and the
Mere's middle stars.

## Endless on the phone: the piece stutter (2026-10-14)

The first phone probe of Endless (Galaxy Z Fold5, cover screen, 120 Hz, the skilled pilot, seed 3)
averaged 117 fps but stalled 80-140 ms each time a piece was built, every 13-25 s. The kit builds
run a step at a time, but single steps took far longer on the phone than the PC's 3.3 ms: a
piece's own content up to 607 ms (Pasture; Poplars 119, Viaduct 104), four trees 25-48 ms.

The cause was every shape asking the renderer: `PrimitiveMesh.new()` makes a mesh on the
rendering server and `get_mesh_arrays()` builds it there and reads it back, a round trip per box,
cylinder and sphere. Headless runs use a dummy renderer, which hid it (Pasture's content 6 ms
headless, 114 ms on the PC with the real renderer). Now `Art.triangles()` scales boxes, cylinders
and spheres from unit shapes made once (and tori once per size), and the kits never make a mesh
per shape; the Course's buildings share the same Builder and load faster too. A test checks the
cached shapes against the meshes' own triangles. `tools/kit_times.gd` times each kit's steps
(run it without --headless to see the renderer's cost).

| Phone, after | |
|---|---|
| Frames over 30 ms after the first second | none in 90 s (one of 25 ms) |
| Longest build step | 16.6 ms (Pasture's content), the rest 11 ms or less |
| Placing a piece (its thermals) | 5-7 ms (was 15-18) |
| Average | 119 fps |
