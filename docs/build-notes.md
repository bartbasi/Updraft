# Build notes: deviations from the plan, and open items

Kept by the lead builder. Anything that departs from `docs/opening-plan.md`, or that needs a
decision from the designer or the owner, is written down here rather than settled silently.

## Deviations from the opening plan

| Where | Plan | Built | Why | Needs |
|---|---|---|---|---|
| Sunbeam angle | Sun about 40° from vertical; window x 85–93, y 15–24.5 | Sun about 18° from vertical (`SUNBEAM_SUN`); window x 83–93.5, y 14.7–24.9 | The lift follows the visible light exactly (code-review fix). At 40° the lift would hug the south wall, away from the centre line the player flies after the turn. The steeper light keeps lift and light on the line. Trade-off: the shaft reads as a high window/clerestory more than a low window. | Designer sign-off (Phase B) |
| Opening shot length | 0.9 s ease | 0.65 s ease (`intro_duration`) | The brief asks for the follow camera "within the first second" counted from the first frame; the plane also waits a few frames for smooth drawing. The designer's Phase A review approved it. | None |
| Door posts | Square jambs | Rounded posts, radius 0.6, drawn as they collide | A sharp corner turns a light clip into a head-on crash; rounded posts turn it into a bump. | None |
| Cones and lamp shades | (not in plan) | Collide exactly as drawn (convex hull) | They used to collide as full cylinders, an invisible wall (code-review blocker). This also changes the existing living-room lamp shade and the outdoor trees slightly. | None |
| Mobile in the bedroom | (dressing) | No collision | Soft paper birds on strings; the plane brushes through. | None |
| Hall table props | Props below y 16 | Plant reaches y 18.5 and a photo frame 17.4, both solid | A plant on a hall table; solid so what you see is what you hit. Sticks out 1.9 from the north wall at x 26.5–33.5; the flying corridor stays clear. | Designer FYI |
| Arch header | Rise 4 over 5.7 (35°) | Rise 6 over 8.6 (still 35°), top drawn as a visible ledge, darker underside band | Catches floaters arriving up to y 17.5 as well as those the downdraft brings lower; the floater sweep (18 never-diving pilots) has 0 arch crashes with it and 17 without. | Designer sign-off (Phase B) |
| Newel posts | 0.5 x 0.5 box posts | Round posts with ball tops, all solid | Round posts make a clipped corner a glancing bump; the ball tops collide as drawn. | None |
| Skylight light | Light source 14 up | Visible shaft reaches the ceiling pane; lift stops at y 24.5 as planned; pane sized to the shaft | The shaft looked disconnected from its skylight. | None |

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

## Open items for Phase B

- A skilled run is about 52 s; the brief's goal is at least 60 s for a well-flown run. The
  designer's measured levers: gravity 8 → 7 (about +3 s), and a 15-unit longer gallery (about
  +3 s). See `docs/opening-plan.md` section 8.
- The lamp style moment (under the lamp) was not earned in any test-pilot run; show it can be flown.
- Late first-timers (test pilot with 0.3–0.9 s reaction lag, seeds 300–319): 15–16/20 get
  through the door turn, but the lag makes them weave afterwards; measured to the gallery mouth
  (x 79) only 11/20 survive: four hit the angled wall up in the sunbeam (x 80–83, y about 24),
  and through the whole gallery 10/20. Normal first-timers: 20/20 through the whole gallery.
  Designer to judge in Phase B whether real players would weave like this (pilot-induced
  oscillation) and whether the angled wall or the sunbeam's height needs softening.
- The banister boards now reach the top of the drawn handrail (what you see is what you hit), so a
  full-strength dive (-1.0) that turns early (x 12) crashes on flight 1's handrail instead of
  glancing off its top. The handrail is visible there; designer to judge whether that is fair.
- Camera and sound feel values move into `scripts/tuning.gd` (the brief's "one place" rule).
- Crash-to-flying time and frame rate need checking on a real phone ("Fly again" rebuilds the
  house in code).
