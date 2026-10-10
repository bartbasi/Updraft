# Build notes: deviations from the plan, and open items

Kept by the lead builder. Anything that departs from `docs/opening-plan.md`, or that needs a
decision from the designer or the owner, is written down here rather than settled silently.

## Deviations from the opening plan

| Where | Plan | Built | Why | Needs |
|---|---|---|---|---|
| Sunbeam angle | Sun about 40° from vertical; window x 85–93, y 15–24.5 | Sun about 18° from vertical (`SUNBEAM_SUN`); window x 83–93.5, y 14.7–24.9 | The lift follows the visible light exactly (code-review fix). At 40° the lift would hug the south wall, away from the centre line the player flies after the turn. The steeper light keeps lift and light on the line. Trade-off: the shaft reads as a high window/clerestory more than a low window. | Designer sign-off (Phase B) |
| Opening shot length | 0.9 s ease | 0.65 s ease (`camera_intro_duration`) | The brief asks for the follow camera "within the first second" counted from the first frame; the plane also waits a few frames for smooth drawing. The designer's Phase A review approved it. | None |
| Door posts | Square jambs | Rounded posts, radius 0.6, drawn as they collide | A sharp corner turns a light clip into a head-on crash; rounded posts turn it into a bump. | None |
| Cones and lamp shades | (not in plan) | Collide exactly as drawn (convex hull) | They used to collide as full cylinders, an invisible wall (code-review blocker). This also changes the existing living-room lamp shade and the outdoor trees slightly. | None |
| Mobile in the bedroom | (dressing) | No collision | Soft paper birds on strings; the plane brushes through. | None |
| Hall table props | Props below y 16 | Plant reaches y 18.5 and a photo frame 17.4, both solid | A plant on a hall table; solid so what you see is what you hit. Sticks out 1.9 from the north wall at x 26.5–33.5; the flying corridor stays clear. | Designer FYI |
| Arch header | Rise 4 over 5.7 (35°) | Rise 6 over 8.6 (still 35°), top drawn as a visible ledge, darker underside band | Catches floaters arriving up to y 17.5 as well as those the downdraft brings lower; the floater sweep (18 never-diving pilots) has 0 arch crashes with it and 17 without. | Designer sign-off (Phase B) |
| Newel posts | 0.5 x 0.5 box posts | Round posts with ball tops, all solid | Round posts make a clipped corner a glancing bump; the ball tops collide as drawn. | None |
| Meadow landmark (fun review 1, item 2) | Optional stream with a low footbridge near z -150 | Stream with flat stepping stones, no footbridge | Anything standing up where planes come down to land could turn a good run into a crash at the very end; a flat stream gives the beat without the risk. | Designer FYI |
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
| 4 | Stronger wind swell in the dive | Phase B |
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

## Open items for Phase B

- A skilled run now lasts 60.4 s (novices 60.2-61.9 s) with the meadow thermal. The longest
  stretch with nothing new is now the final glide from the stream to the grass, about 8 s
  (flight log); designer to judge in review 2.
- The lamp style moment (under the lamp) can be flown: a test pilot with a firm hand on the
  pitch follows the course's own paths and earns it (83-101 points, quality 0.55-0.67), then the
  kettle and window (`test_a_firm_pilot_earns_every_downstairs_moment_including_the_lamp`). But
  the standard test pilot, which pitches gently, crashes into the lamp shade at about
  (0.2, 5.5, -43) on that path, and no novice run earns it (0/10). Designer to judge whether
  real players will thread it, or whether the dip under the shade wants more room.
- Late first-timers (test pilot with 0.3–0.9 s reaction lag, seeds 300–319): 15–16/20 get
  through the door turn, but the lag makes them weave afterwards; measured to the gallery mouth
  (x 79) only 11/20 survive: four hit the angled wall up in the sunbeam (x 80–83, y about 24),
  and through the whole gallery 10/20. Normal first-timers: 20/20 through the whole gallery.
  Designer to judge in Phase B whether real players would weave like this (pilot-induced
  oscillation) and whether the angled wall or the sunbeam's height needs softening.
- The banister boards now reach the top of the drawn handrail (what you see is what you hit), so a
  full-strength dive (-1.0) that turns early (x 12) crashes on flight 1's handrail instead of
  glancing off its top. The handrail is visible there; designer to judge whether that is fair.
- Crash-to-flying time and frame rate need checking on a real phone ("Fly again" rebuilds the
  house in code).
- Through the arch at speed the camera trails about 6 units behind, and the white plane, seen
  from behind, sits over the white coffee-table top and pink rug and is hard to pick out
  (screenshots at 24-25 s). Designer to judge: plane colour or outline, camera distance, or
  the furniture.
- Frame rate while circling in the meadow thermal on the phone: its see-through column is the
  largest in the game (radius about 4.5, 12 high, 110 motes) and the camera flies inside it for
  a second or two. No cost on PC. Fallbacks: fewer motes, or draw only the column's front faces.
- A run can now go on and on: a steady circle in the meadow thermal holds the plane at about
  y 12.5 with no end (no distance or style is earned meanwhile). Designer to judge in review 2
  whether the thermal should top out lower or fade, or whether that is a fine reward.
- Frame rate in the stair dive on the phone: the downdraft's see-through column (the camera flies
  through it), two light shafts and three sets of motes and wisps can all be in view on top of the
  watercolour pass; the designer measured 40-51 fps on PC in this stretch. Fallbacks if it drops:
  narrow the column to the window's width (x 5-13), or drop the column and keep the falling wisps.
