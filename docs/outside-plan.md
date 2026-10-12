# Outside plan (Phase 3)

Owner feedback: outdoors it is too hard to find lift and nothing invites exploring. This plan
replaces the outdoor layout. Items 1-6 are owner-approved new systems. Everything else here is
layout, tuning, looks, sound or scoring.

World axes: the window is at (0, 4.5..10.5, -89) and the flight heads -Z. +X is the player's right.
Story: a light breeze blows from the right (+X). Smoke leans left, the windsock points left, and
the **left** hillside faces into the wind, so that is the ridge.

## 0. Measured baseline

- Flight logs (10 novice runs, 2 skilled runs) all leave the window at **y 7.0-7.2, 5.9-6.7 u/s, t ≈ 42 s**.
  Outdoors today: one thermal, then touchdown at t ≈ 60 s, so **≈ 18 s outside**.
- Glide measured from FlightModel (scratch script, 10 s of steady flight):

  | Input | Speed | Sink | Glide ratio |
  |---|---|---|---|
  | Neutral | 6.05 u/s | 0.62 u/s | 9.7 : 1 |
  | Pitch +0.15 | 4.9 u/s | 0.37 u/s | 13 : 1 |
  | Pitch -0.2 | 7.9 u/s | 1.30 u/s | 6 : 1 |
  | Full bank | 6.3 u/s | 0.71 u/s | (circling) |

- Turn radius at full bank is 6.3 / 1.134 rad/s = **5.6 u**. At half bank it is about 11 u.
- Climb while circling in a uniform updraft is about the updraft minus 0.7:
  - 4.5 u/s air gives a 3.8 u/s climb.
  - 3.0 gives 2.3.
  - 1.5 gives 0.8.
- `Thermal.profile` is full strength inside 0.55 × radius. **For a full-bank circle to stay entirely in the
  core, the radius must be at least 5.6 / 0.55 ≈ 10.** The meadow thermal today has radius 6, so its
  core is only 3.3 and a full-bank circle spends most of its time in the fringe. That is the owner's
  "hard to find lift".

## 1. Ground shape

Replace `ground_height()` with the formula below. Plain smoothstep(a, b, v) has a < b. The
`d / 25` fade on the rolls stays.

```
d     = max(0, -89 - z)                                  # distance out from the window wall
h     = -1.2
      + 0.03  * d                                         # gentle valley floor (was 0.085)
      + 0.015 * max(0, d - 190)^2                         # head wall at the far end
      + 0.006 * max(0, x - 28)^2                          # right-hand slopes
      + 22.0  * smoothstep(26, 66, -x)                    # LEFT RIDGE: face x -26..-66, crest plateau
      + 0.012 * max(0, -x - 84)^2                         # behind the plateau, up to the edge
      + 0.04  * max(0, z + 64)^2 * smoothstep(12, 20, |x|)  # embankment behind/beside the house
      + 0.6 * rolls                                       # today's two sines, at 60 % amplitude
```

Heights (smooth curve, without the rolls; checked in a scratch script):

| Point (x, z) | Height | Note |
|---|---|---|
| Window foot (0, -95) | -1.0 | |
| Hay field, L1 (-2, -118) | -0.3 | |
| Stream (0, -150) | 0.6 | |
| Lavender centre (-5, -182) | 1.6 | Flat, slope 0.03 |
| L3 (-12, -215) | 2.6 | |
| L4 (34, -268) | 4.4 | |
| (0, -320) | 30.9 | Head wall |
| (0, -342) edge | 66 | Head wall |
| Ridge face, x -38 / -46 / -56 (z -200) | 6.9 / 13.1 / 20.7 | |
| Crest plateau (-66..-84, -200) | 24.1 | Flat, the picnic spot |
| Edge (-126, -200) | 45 | |
| Edge (126, -200) | 60 | |
| Behind the house (±30, -30) | 45 | |

- **Ridge face slope:** the steepest is 0.82 (39°). A plane drifting into it bounces rather than
  crashes, because hits only crash above 50° steepness.
- **No lift at all:** from y 7 at the window, the gap to the ground closes at 0.103 + 0.03 =
  0.133 per unit flown, so 8.2 / 0.133 = 62 u, about **10 s**. The plane lands near the stream
  (z ≈ -151; the sim gives t 10.3).
- **Grid:** the 42 × 52 grid from (-126, -30) is enough. Every edge is at least 43 high, and no
  outdoor lift tops out above y 33.
- **Safety net (correctness).** A plane flying back toward the house at y > 12.5 lands on the flat
  kitchen roof, which is fine (card: "On the roof!"). If the plane is ever below y -10, or outside
  x ±123 / z < -339, end the run as a landing. It should never happen; it must not fall forever.
- **Trees.** Replace TREE_FREE_*. Place about 40 trees, only:
  - on the right slopes, x 45..110;
  - on the plateau, x -72..-115;
  - on the head wall, z < -295.
  Rejection rules:
  - none within 4 u of any lift zone's edge (in plan view);
  - none on the ridge face (x -24..-66, z -120..-270);
  - none within 8 u of the picnic blanket, barn or bonfire.
  The valley floor stays open.
- Stream: keep STREAM_Z -150, but draw it from x -28 to 60. It rises at the ridge foot, so no water
  runs up the hill. Fence: trim it to x -30..30.

## 2. Lift sources

Every thermal is a cylinder standing on `ground_height(centre)`, with `height = TOP_Y - ground`.
Peak updraft is 5.0 × scale. The order is L1, then L2, L3 and L4, with the ridge as a left-hand
branch from L1 to L3.

| # | Centre (x, z) | Radius | Top y | Scale (peak u/s) | Chime pitch | Ground cause | Long-range cue |
|---|---|---|---|---|---|---|---|
| L1 Hay field | (-2, -118) | 12 | 24 | 0.9 (4.5) | 0.9 | Golden hay rows 24 × 24, 5 round bales (solid cylinders on their side, r 1.0, length 1.5) | Big cumulus, 3 circling birds, warm motes, windsock by the fence |
| L2 Barn roof | (30, -165) | 10 | 27 | 0.8 (4.0) | 0.95 | Barn at (35, -163): 10 × 7, walls 5, ridge 8.5 (solid), walls `d98b7a`, dark slate roof `5f5b70`, earth yard `b8a68c` 16 × 16 | Cumulus, 3 birds, motes |
| L3 Ploughed field | (-12, -215) | 10 | 29 | 0.8 (4.0) | 1.0 | Dark furrows `a88b74` / `94785f`, 22 × 22 | Cumulus, 3 birds, motes |
| L4 Bonfire | (34, -268) | 10 | 29 | 0.8 (4.0) | 1.05 | Leaf bonfire at (36, -268): stone ring r 1.2, logs, 3 small unshaded flame cones. Not solid. | **Smoke plume** (STEAM look, tinted `e2ddd8`), cumulus, 3 birds |
| Ridge | Box, centre (-38, 0, -195), size (24, 33, 140) | Not rotated | 33 | 0.4 (2.0) | 0.85 | Left hillside facing the breeze | Seeds streaming up the slope, wind-bent grass, 3 hovering birds, kite over the picnic |

### Why each source is placed there (glide 9.7 : 1; arrival heights from a scripted sim of FlightModel and these zones)

- **L1, straight out of the window.** Its edge is at z -106, 2.5 s after the sill. The flight line
  x = 0 passes 2 u from its centre, inside the 6.6 u core.
  - Flying straight through gains **+8.8** (y 7 → 15.8).
  - Circling at full bank climbs ≈ 3.8 u/s and reaches y 22.5 at t 10.4 s outdoors.
  - Circling at half bank (a sloppy novice) still climbs ≈ 1 u/s.
  - The 12 u radius means a 24 u wide orange column, square in the view through the window.
- **L1 top → L2:** 57 u away, 34° right; its cloud sits 9° above the horizon. Edge to edge is ≈ 45 u
  (7.5 s). The plane arrives at y ≈ 21, 19 above the ground, crossing the stream on the way at about
  5 s. It climbs ≈ 6 back to 27.
- **L2 top → L3:** 65 u, 40° left. The plane arrives at y ≈ 23, 20 above the ground, and climbs to 29.
  L3 sits **off the centre line** (its edge is at x -2), so a straight-flying player gets only one free
  climb.
- **L3 top → L4:** 69 u, 40° right. The smoke plume is the best beacon outdoors: it is visible from
  the window (180 u, fog transmittance 0.64). The plane arrives at y ≈ 23, 19 above the ground.
- **L4 top → home to land:** the lavender field is 94 u back towards the house, 16° below the horizon.
  The plane arrives ≈ 15 above it and spirals down to land.
- **L1 top → ridge:** 36 u left. The plane arrives at y ≈ 20, 18 above the face. Flying straight along
  x ≈ -37 in 2.0 u/s air climbs ≈ 1.4 u/s. In the sim it climbed 20 → 31 between z -159 and -219, then
  held 31 to the end. From the ridge's end, L3 is 30 u away (5 s).
- **The ridge cannot be reached from the window without L1** (the sim landed at t 8.8). L1 first is
  intended.
- **Thermal tops are capped at 29 and the ridge at 33.** From the highest point the plane meets the
  head wall before z -320 or the side slopes before |x| 90 (checked: the plane at y 30 meets ground
  30.9 at z -320).

### Ridge visuals and sound

These are a new `Look.RIDGE` on the box zone. Do not draw a column: a 140 u glass wall would read
wrong.

- **Dandelion seeds:**
  - CPUParticles, about 160, emitted over the band at heights 6-22;
  - direction (-0.5, 1, 0), drifting up-slope with the breeze;
  - speed 2-3 u/s, lifetime 6 s;
  - white `fbf7f0`, 0.3 u;
  - the existing near-camera distance fade.
- **Grass:** a strip of paler, wind-bent grass tufts (`d4e6b5`, painted triangles leaning -X) along
  x -30..-48. It marks the band on the ground.
- **Birds:** 3 birds hang almost still over the face at (-40, crest + 3, z -170 / -200 / -230),
  bobbing ±0.3 u over 3 s. Hovering on ridge lift is the real-world tell.
- **Kite and picnic:** a diamond kite (2.5 u, `f19e8f`, ribbon tail) flies at (-82, 34, -205) on a
  string down to a picnic blanket at (-72, -205) on the plateau. It is visible from L1's top
  (119 u away). Not solid.
- **Sound:** entering the band plays the chime at pitch 0.85 and `swell(3.0, 1.0)` of wind.

### Shared cues for L1-L4 (looks only, nothing collides)

- **Cumulus:**
  - 4 flattened spheres (stretch 1.4, 0.55, 1), each radius 0.6-0.8 × the thermal radius, colour `fdfbf8`;
  - flat base at top y + 4, so circling at the top puts the cloud just overhead;
  - drawn once in the "Outside" mesh.
- **Birds:**
  - 3 per thermal: dark V shapes (`6f6478`), wingspan 1.6 u (≈ 20 px at 60 u on a phone);
  - circling at 0.5 × radius, 0.45 rad/s, at top y - 4 ± 1.5;
  - phases 120° apart.
- **Motes:**
  - lifetime 4 → 7 s, initial speed 1-1.9 → 2.5-3.5 u/s, so they climb the whole column;
  - amount = clamp(radius² × 1.2, 110, 170);
  - outdoors, about 1 in 4 is a seed or leaf: white or `d4e6b5`, quad 0.5;
  - CPUParticles3D `tangential_accel` 1.5 if it spirals in 3D; skip it if not.
- **Column tint:** keep it, at alpha 0.45 outdoors (0.6 today). The outdoor columns are 4× wider, so
  they are readable without being heavy.
- **Bonfire smoke:** STEAM look with a vertical column; puffs live 8 s at 3-3.6 u/s and drift -X at
  0.12 u/s². The plume leans 3-4 u by the top, which matches the breeze.
- **Windsock:** at (14, ground, -103), pole 5 u, sock pointing -X. Not solid. It is the first thing
  seen out of the window that says "breeze from the right".

## 3. Variometer sound ("you're in lift")

- **When it plays:**
  - the air at the plane rises at ≥ `vario_air_min` (Thermal air, the `_air.y` sum);
  - the plane's climb rate `velocity.y` is ≥ `vario_climb_min`;
  - the plane is not stalled or ended.
  It stops when the climb rate drops below 0.1 (hysteresis). It is silent when sinking, diving or
  in the downdraft. It plays indoors too, for consistency.
- **Sound:** soft beeps rather than a drone, which tires the ear less. `audio/vario.wav` is made by
  gen_sounds.py:
  - 0.09 s sine at 660 Hz;
  - 2nd harmonic at 0.15;
  - 5 ms attack, 60 ms exponential decay.
- **Mapping:** t = clamp((climb - 0.3) / (3.5 - 0.3), 0, 1). Interval, pitch and loudness all lerp
  with t. The wind at cruise is about -12 dB, so the beeps sit just above it.

  New `tuning.gd` group "Variometer":

  | Field | Value | Meaning |
  |---|---|---|
  | `vario_air_min` | 0.4 | Air must rise at least this fast (u/s) |
  | `vario_climb_min` | 0.3 | Climb rate that starts the beeps (u/s) |
  | `vario_climb_full` | 3.5 | Climb rate for the fastest, highest beeps (u/s) |
  | `vario_interval_slow` / `vario_interval_fast` | 0.45 / 0.15 | Seconds between beeps |
  | `vario_pitch_low` / `vario_pitch_high` | 1.0 / 1.7 | Pitch scale |
  | `vario_db_quiet` / `vario_db_loud` | -14 / -7 | Loudness |

## 4. Scoring outdoors

- **Landing bonus:** awarded only when the run ends by **stopping** (not by crashing), judged at
  the resting position. Rectangles include about 2 u of slide margin (slide ≈ 6² / (2 × 5) = 3.6 u).

  | Spot | Area | Bonus | Card title |
  |---|---|---|---|
  | Lavender field | Enlarge to x -14..4, z -166..-196 | **+200** | "Lavender landing!" |
  | Picnic blanket | Rectangle x -77..-67, z -209.5..-200.5 (on the plateau) | **+400** | "Picnic landing!" |

  The picnic is the expert target. From the ridge top (y ≈ 31 at x -37) it is 33 u, which arrives
  ≈ 3 u above the plateau (24.3). That is reachable but it needs the climb.
- **Airtime:** **5 points per second airborne outdoors**, capped at **60 s (300 points)**. The cap
  stops a circle or the ridge from farming points forever. For scale, a full indoor run is about 900
  distance plus 750 style.
- **Style moment "Ridge run"** (optional, recommended):
  - path (-33, 20, -160), (-37, 26, -188), (-37, 30.5, -215), (-37, 31, -245);
  - entry in `Tuning.style_moments`: `"ridge_run": {"points": 120, "radius": 4.0}`;
  - the path comes from the sim's ridge flight;
  - it is a line, which the style system scores well; thermal circling is not.
- **End card**, extra lines only when they are earned:

  ```
  Distance  96 m = 960
  Style  839   (8 of 9 moments)
  Airtime  42 s = 210
  Lavender landing  +200
  Total  2209
  ```

  The title becomes the landing-spot title when one is earned, otherwise "You flew outside!".

## 5. Expected timings outdoors (from the window)

Measured in a FlightModel-only scratch sim with these zones; no collisions with objects.

| Pilot | Route | Time outside | Ends at |
|---|---|---|---|
| Ignores lift (L1 removed) | Straight | 10 s | Stream, z -151 |
| Flies straight (ignores turning) | Through L1 only | 24 s | z -238, past the lavender |
| Novice: circles L1 a bit, glides | L1 → lavender or valley | 25-40 s | Lavender or z -170..-240 |
| Skilled, ridge branch | L1 → ridge → L3 → lavender | ≈ 60 s | Lavender |
| Skilled, full chain | L1 → L2 → L3 → L4 → lavender | ≈ 65-75 s | Lavender |

The flying-straight player gets about 24 s instead of 10, because the owner asked for a free climb
on the natural line. That is the price, and I think a fair one.

**Dead-air note:** the glides between thermals are 7-9 s. The flight log will flag them, but this is
the exploring phase:

- the next cloud and birds are in view and growing the whole time;
- each glide has a mid-point beat: the stream on L1 → L2, the lavender on L2 → L3, the barn or smoke
  on the others;
- the chime plus beeps start at each edge.

Accept up to 8 s outdoors; flag anything over 10 s.

## 6. Small feel tunings

- `camera_fov_outside` 76 → **80**. It widens the horizontal view on a 2:1 phone to about 120°, so a
  thermal 40° off the nose stays in frame.
- No other camera changes. The 1.3× larger plane and the balloon need nothing extra: red against
  white cloud and green hills reads well, and the balloon's string already follows `_air`.

## 7. Build order (each step testable on its own)

1. **Ground, bounds, trees, stream, fence, lavender resize.**
   - Test: `ground_height` matches the table above to ±0.1 without the rolls.
   - Test: a hands-off glide from (0, 7, -89.5) heading -Z with no outdoor lift lands within 8-12 s.
   - Test: no tree is inside the exclusion rules.
   - Test: the safety net ends a run dropped at y -11.
2. **L1 replaces MeadowHeat**, with the hay field and bales.
   - Test: flying straight through gains ≥ 6.
   - Test: a full-bank circle from entry reaches y ≥ 22 within 12 s.
   - Update `downstairs_line()` to circle L1.
3. **L2, L3 and L4 thermals and their ground causes.**
   - Test: a tour pilot (go to centre, circle to top - 1.5, next) arrives at each ≥ 12 above the
     ground and lands ≥ 55 s after the window.
4. **Ridge box and `Look.RIDGE`.**
   - Test: a pilot holding x -37 from z -150 reaches y ≥ 29 by z -220 and never touches the face.
5. **Long-range cues:** clouds, birds, seeds, smoke, windsock, kite, picnic blanket. Captures:
   - from each thermal top facing the next;
   - from the window sill;
   - the frame rate in the L1 column, which has the most particles.
6. **Variometer:** sound file, tuning group, playback.
   - Test: beeps occur only when air > 0.4 and climb > 0.3.
   - Test: silent in the stair downdraft and in a dive.
7. **Scoring:** landing bonuses, airtime with its cap, "Ridge run", end-card lines.
   - Test: a rest in each rectangle; a crash in the lavender gets no bonus; airtime caps at 300.
8. **Pilots and logs.** Pilots:
   - skilled = the full chain;
   - a second skilled pilot = the ridge branch;
   - novice = sloppy L1 then lavender.

   New flight-log landmarks: entering the ridge, passing the barn, the landing spot reached.
   Then I review with logs and captures.

## Later ideas (not in this phase)

- Thermals that weaken after a long circle, to nudge players onward instead of relying on the
  airtime cap.
- Lee-side sink behind the ridge crest, to make the picnic approach more interesting.
- Lift "pulses": a cloud that forms and dissolves over a minute.
- A gull that flies with you along the ridge for a few seconds.
