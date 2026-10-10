# Opening plan: bedroom, gallery, stair hall (Phase A, step 1)

Designer's plan for the new opening. The lead builds directly from these numbers.
Units: 4 units = 1 m, Y up. "Left/right" are as the player sees them while flying.

**The route in one line.** A kid kneeling on a loft bed throws the plane down a long bedroom (heading -Z).
The player banks **left** through a wide door onto a sunny upper landing, and a sunbeam lifts the plane
into a long upstairs **gallery** (heading -X). Halfway along, a skylight beam gives a top-up. The gallery
floor turns into the top step of a two-storey **stair hall**. The player dives down flight 1 with cool air
falling around it, banks **right** past the newel post at the landing, follows flight 2 down, levels out,
and swoops through a wide **arch** in the living-room back wall (heading -Z) into the unchanged demo.

**Decisions for the owner** (details in section 8):
1. **60 s:** at the current tuning, a well-flown run with this layout is about **54 s**. A decent run is
   about 49 s. Reaching 60 s through space alone would need a gallery of about 30 m, which would be
   padding. My recommendation is in section 8.
2. **Second lift.** I added a small skylight beam halfway down the gallery, so the long gallery has a beat
   in the middle. It is not scored and the run works without it. If the owner wants exactly one sunbeam,
   cut it.

---

## 1. Layout (world units)

Upstairs levels: **floor top y = 12.5** (on the existing ceiling slab). **Ceiling y = 26.5**, the same in
the bedroom, gallery and stair hall: 14 units (3.5 m), the high ceilings of an old house. That height is
what lets the sunbeam lift the plane. Upstairs interior walls are **0.5** thick.

### Top-down sketch (not to scale; +Z up the page, +X to the right)

```
                                  z 79.5 +----------------------+
                                         |  BEDROOM  x 90..108  |
                                         |  eye *  (100,21.9,76.5)
                                         |  start v (100,21.5,74.5)
                                  z 46.5 +---| DOOR |-----------+   door x 94.5..102.5
 z 46 +-------------------------------+--------------------------------+------------+
      | STAIR HALL                    |  GALLERY  <-- heading -X       |  UPPER     |
      | [LANDING]<- flight 1 (down)   |   skylight beam x 41..49       |  LANDING   |
      |  x -7.5..1.5                  |                    sunbeam x 81..97          |
 z 37 |  +--o newel (1.5,37)  rail    +------- gallery south wall ---\ taper       |
      |  |f |                        x 16.5                (79,37)->(94,33)         |
      |  |l |   open well                                         z 33 +-----------+
      |  |2 |   (ground floor)                                             x 108.5
      |  |v |
 z 22 |  +--o bottom newel
 z 15 +--| ARCH x -7..6 |-------+ x 16.5
 z 14     LIVING ROOM (existing, x -9..9)
```

### Bedroom (the kids' room)
| Item | Value |
|---|---|
| Interior | x **90 to 108** (18 wide), z **46.5 to 79.5** (33 deep), floor 12.5, ceiling 26.5 |
| Loft bed (thrower) | against the back wall, x 96 to 104, z 75.9 to 79.5, mattress top y 18.9, guard rail top 19.9 |
| Door (south wall, z 46.0 to 46.5) | x **94.5 to 102.5** (**8 wide**, a double door with both leaves open flat against the bedroom wall), floor to **y 22.5** (10 tall) |
| Keep clear | nothing above y 16 between the bed and the door, except a mobile hanging from the ceiling no lower than y 24 |
| Dressing | second bed along the east wall, desk and window on the west wall (x 90, z 60 to 68, curtains), rug, toy shelf, play tent, posters, a paper-plane drawing pinned up. Soft pastels. |

### Upper landing, taper and gallery
| Item | Value |
|---|---|
| Upper landing (outside the door) | x **94 to 108.5**, z **33 to 46**. It is 13 deep opposite the door, so late turners have room. East end wall at x 108.5 (leaves 6 units east of the door for the camera). |
| Taper | the south wall runs straight from (94, 33) to **(79, 37)**: 15° to the gallery axis, so any scrape is a glancing bump |
| Gallery | x **16.5 to 79** at full width (to 94 counting the taper), z **37 to 46** (**9 wide**, centre line z **41.5**), 14 tall. The north wall at z 46 runs unbroken from x 16.5 to 108.5 except the bedroom door. |
| Gallery west end | the floor simply continues as the top step of flight 1, across the full 9-unit width. **No railing across the path.** |
| Visual beats | x ≈ 66: a closed door on the north wall (sibling's room, a sliver of light under it) and a big picture opposite. x ≈ 30: a hall table with a plant against the north wall and a row of family photos. Striped runner rug down the centre (gives a sense of speed). All props flat against the walls, below y 16. |

### Sunbeam (just past the turn) and skylight beam (mid-gallery)
| Zone | Box origin (bottom centre) | Size (x, y, z) | Strength | Notes |
|---|---|---|---|---|
| **Sunbeam** | **(89, 12.5, 40.5)** | **(16, 12, 11)**: x 81 to 97, z 35 to 46, y 12.5 to 24.5 | **0.9× thermal = 4.5 u/s** | Lift starts as the turn finishes (east edge x 97) and fades at the top (y 22.5 to 24.5), 2 units below the ceiling. A centre pass lifts the plane about **+4.5 to +5** (from about 19 to 23.8) over about 2 s: gentler per second than the radiator but longer. Light source: a tall window in the angled south wall, x 85 to 93, sill y 15, top y 24.5 (light_source ≈ (0, 7.5, -6.2) from the origin). Seen through the door, the golden light falls in from the **left**, which tells the player which way to turn. |
| **Skylight** (not scored) | **(45, 12.5, 39.5)** | **(8, 12, 5)**: x 41 to 49, z 37 to 42 (the right-hand half of the gallery), y to 24.5 | **0.7× = 3.5 u/s** | On the centre line the plane gets about half the lift (+1); steering 2 units right gets all of it (+2 to +2.5). Gives low planes a catch-up and rewards good pilots with a higher, faster stair dive. Vertical shaft from a 6 × 4 skylight in the ceiling right above it (light_source (0, 14, 0)). It is the first thing to cut if performance is tight. |

### Stair hall
| Item | Value |
|---|---|
| Interior | x **-7.5 to 16.5** (24), z **15 to 46** (31), y **0 to 26.5** (two storeys, open to the ceiling) |
| Flight 1 (from the gallery, heading -X, **down**) | z **37 to 46** (**9 wide**), from x **16.5** (top, y 12.5) to x **1.5** (y 6.25). 12 steps: tread 1.25, rise 0.52 (22.6°). Solid underneath (a closet under the stairs, with a little door facing the well). |
| Landing | x **-7.5 to 1.5**, z **37 to 46**, top y **6.25**. Keep it clear apart from a flat rug. |
| Flight 2 (heading -Z, **down**) | x **-7.5 to 1.5** (9 wide), from z **37** (y 6.25) to z **22** (y 0). 12 steps, same proportions. Solid underneath. |
| Run-out | ground floor from z 22 to the arch at z 15 |
| **Turn at the landing** | **right**, 90° (heading -X to heading -Z) |
| Newel posts (0.5 × 0.5) | landing inner corner **(1.5, 37), top y 10.45**; top of flight 1 (16.5, 37), top 16.7; bottom of flight 2 (1.5, 22), top 4.2 |
| Banisters | flight 1 along its **south (well) edge** z = 37, x 1.5 to 16.5; flight 2 along its **east (well) edge** x = 1.5, z 22 to 37. Handrail top = stair surface + **3.6**. Both are on the **inside** of the turn; the plane never has to cross them on the good line. |
| Wall handrails | on the north and west walls: visual only, no collision |
| Collision | Each flight is **one smooth inclined slab** under the step nosings, with the steps visual only. A plane that skims the stairs then glances off a 22.6° ramp instead of catching step edges. Each banister is a 0.25-thick slab from the stair surface to the handrail top. Newels are boxes. |
| Light | a high window in the north wall above flight 1 (x 5 to 13, y 17 to 25): cool blue light, and the downdraft's source. A round window (diameter 5) high on the west wall above the landing (centre y 16, z 41.5) marks the turn. |
| Ground-floor dressing | rug, shoe bench, coat stand, all along the walls. Nothing taller than 4 units inside x -7 to 12. |
| Ceiling | 26.5. There is no lintel where the gallery meets the stair hall: the ceilings are continuous. |

### Downdraft (stairwell)
| Box origin | Size | Strength |
|---|---|---|
| **(10, 13, 41.75)** | **(12, 13.5, 8.5)**: x 4 to 16, z 37.5 to 46 (over flight 1, not over the well), y 13 to 26.5 | **0.6 × downdraft_strength = 2.1 u/s** peak |

Pale blue wisps fall from the north window's sill along flight 1. The plane meets the downdraft the moment
it passes the top step: the floor drops away and cool air pulls it down the stairs. Strength 0.6 is
deliberate:
- **At 1.0,** a pilot diving at -0.8 who eases to -0.3 for the turn leaves it at y 2.4 to 5.4: at or
  just above flight 2's steps (surface y 3.3 there).
- **At 0.6,** a pilot holding -0.5 leaves the turn at y 7 to 10 and about 9.7 u/s, with a downdraft
  speed gain of about +0.5 u/s.
- **A non-diver** still drops about 3.3 units more than with no downdraft, which gets novices down
  toward the arch.

### Opening into the living room
| Item | Value |
|---|---|
| Arch | in the living-room back wall (z 14 to 15): x **-7 to 6** (13 wide), y **0 to 11.5** |
| Remove | the launch bookcase (x -3.2 to 3.2, z 7.8 to 10), its books and plant, and `LAUNCH` |
| Join | the plane enters heading -Z at about x -2, y 8 to 9, speed 7 to 9.5. That is the old start's line and height with spare speed. The radiator is 37 units ahead, 3 units to the left. Nothing else in the living room changes. |

**Why this join:** flight 2 already heads -Z, so the plane needs no extra turn and meets the old flight
line (x ≈ 0, y ≈ 9) in the same state as the old launch. The stair hall sits behind the back wall, where
the exterior is never seen.

---

## 2. Opening shot

| Item | Value |
|---|---|
| Kid's eye | **(100, 21.9, 76.5)**: kneeling on the loft bed, 9.4 units (2.35 m) above the floor, looking down the room at the door |
| Plane start | **(100, 21.5, 74.5)**, 2.0 ahead of and 0.4 below the eye, just past the bed's guard rail. Heading **0 (toward -Z)**. |
| Start speed | **6.5 u/s** (`launch_speed`: a fresh throw that settles to cruise) |
| First frame | Camera at the eye, looking straight at the plane (11° down). The plane fills about 20% of the screen width, and the open door is visible 28 units ahead with golden sunbeam light spilling in from the left. |
| Ease into follow | Over **0.9 s** with a smoothstep, ease position from the eye to the chase position and the look target from the plane to the chase look point (what `start_intro` does now). The smoothstep's flat start means the camera barely moves for the first ~0.2 s, so the plane visibly glides away from the kid's eye before the camera follows. Camera lean stays 0 during the intro. |
| Camera room | The chase position at t = 0 is (100, 22.5, 77.9), inside the room (back wall at z 79.5, ceiling 26.5) |

---

## 3. Section by section

Times are from a simulation with the real `FlightModel` along these lines (no collisions).
**Decent** pilot: hands-off cruise about 6 u/s, makes every turn and catches every beam.
**Good** pilot: slight nose-up glide (pitch +0.15, about 5 u/s, sink 0.37 instead of 0.62), clean lines,
dives the stairs.

| Section | What the player sees and does | Why it feels good | Decent | Good |
|---|---|---|---|---|
| **Throw and bedroom glide** | The plane leaves the kid's hand and floats down a cozy room toward a bright double door. The first tilts are calibration. | A calm, readable first 4 s with one clear goal. The plane is high (y 21.5 → 19.5), so there is nothing to hit. | 0 – 4.5 s | 0 – 5.0 s |
| **Bedroom turn** | Bank left through the door. Golden light on the floor to the left shows the way. | The first real skill. The wide door and the deep landing make it forgiving; a clean carve onto the gallery's centre line scores. | 4.5 – 5.8 | 5.0 – 6.4 |
| **Sunbeam** | Fly through a slanting shaft of light full of rising dust; the chime plays and the plane rises about 5 units. | It pays the turn back: "lifts the plane back up after the turn." A steady, smooth climb. | 5.4 – 7.8 | 6.0 – 8.5 |
| **Gallery** | A long, high, sunny gallery: closed doors, pictures, a striped runner. The skylight beam on the right is a mid-way choice. The bright stair hall grows at the far end. | "Settle in and feel the glide." Something to see every 3 to 4 s (x 66 door, skylight, x 30 hall table, stair hall). Height management decides how big the dive will be. | 7.8 – 18.2 | 8.5 – 21.0 |
| **Stair dive** | The floor turns into stairs and drops away. Push the nose down; cool blue wisps pull the plane down flight 1. Speed goes from about 5 to about 10 u/s in 2 s, steps streaming past 4 units below. | The most thrilling moment before the window: the biggest drop in the game, the fastest speed so far, things close by, and the wind sound swelling. | 18.2 – 20.6 | 21.0 – 23.4 |
| **Landing turn and level-out** | Bank hard right past the newel post over the landing, follow flight 2 down, pull up and swoop through the arch. | A carved, high-speed turn followed by a pull-out: two skills back to back, with a clear target (the warm, bright arch). | 20.6 – 23.6 | 23.4 – 26.6 |
| **Existing demo** | radiator, lamp, door, kettle, window, hills, unchanged | as before | ≈ 23.6 – 49.5 | 26.6 – 53.7 |

Simulated heights on the good line: door 19.9, sunbeam exit 23.9, stair top 21.1, landing-turn apex
11 to 13 (depending on how hard the player dives), flight 2 bottom 8, arch 8, radiator entry 7.

---

## 4. Style-point moments

Grading, as the lead's `Scoring` does it:
- Average distance from the path while the moment is engaged, divided by the corridor radius.
- **Full points at or below 25% of the radius** (`style_full_fraction` 0.25), then a smoothstep fall to
  **0 at the corridor edge**. `style_curve_power` 1.0.
- "Perfect" pop-up at quality **≥ 0.85**, which is an average offset of about 43% of the radius or less.
- `style_capture_factor` 2.0.
- **Distance: 10 points per metre** of progress along the spine. A full run is about 80 m, so about 800
  points. All eight moments together are worth 950, so style is where good pilots pull ahead.

| id | Optimal path (x, y, z) | Radius | Points | Skill it rewards |
|---|---|---|---|---|
| `bedroom_turn` | (100, 19.6, 51) → (100, 19.3, 47) → (98.4, 19.1, 43.1) → (94.5, 19.0, 41.5) → (90, 20.0, 41.5) | 2.5 | 100 | Timing the bank at the door so the plane carves one clean quarter-circle onto the gallery's centre line. |
| `sunbeam` | (95, 19.0, 41.5) → (91, 20.5, 41.5) → (87, 22.0, 41.5) → (83, 23.2, 41.5) → (79, 23.8, 41.5) | 2.0 | 80 | Holding a steady, wings-level line through the heart of the light and letting it carry you, not fighting it. |
| `stair_downdraft` | (17, 20.5, 41.5) → (13, 18.0, 41.5) → (10, 15.8, 41.5) → (7, 13.6, 41.5) | 2.0 | 120 | Committing to a steep dive right at the top step and riding the cold air down the middle of flight 1. |
| `landing_turn` | (7, 13.6, 41.5) → (3.5, 12.2, 40.6) → (0, 11.4, 38.6) → (-2.5, 9.8, 34.5) → (-3, 7.5, 26) → (-2, 8.5, 15.5) | 2.0 | 150 | Carving the turn at full speed about 2.2 units from the newel post, then pulling out in time to swoop level through the arch. |
| `radiator` | (-3.5, 7.0, -12) → (-4.5, 7.5, -18.5) → (-5, 9.0, -22) → (-5, 10.5, -25.5) → (-4.5, 10.8, -30) | 2.5 | 100 | Steering into the core of the heat column instead of clipping its edge. |
| `lamp` (the obstacle) | (-1.5, 6.5, -36) → (0, 4.2, -42) → (0, 4.05, -45) → (0, 4.2, -48) → (-0.5, 5.2, -52) | 1.5 | 150 | Threading the 1.9-unit gap between the lamp shade (bottom y 5.0) and the dining table (top y 3.1), then rising through the door. Flying past beside the lamp scores nothing. |
| `kettle` | (0.5, 5.2, -58) → (2.5, 5.5, -65) → (3, 7.0, -69) → (3, 9.0, -72) → (2, 10.0, -76) | 2.5 | 100 | Dropping into the base of the steam low and riding it straight up its middle. |
| `window` | (1, 9.0, -79) → (0.3, 8.0, -84) → (0, 7.5, -88.5) → (0, 7.2, -93) | 2.0 | 150 | Lining up early and bursting out through the dead centre of the window, wings level. |

Paths for the four existing moments come from the geometry in `course.gd` and the old autopilot. Check
them with the debug overlay against the skilled test pilot's log, and move them by up to 1 unit if needed.

Simulated check (same grading):
- **The sim pilots steer straight at these lines, so their scores are an upper bound.**
- **Decent pilot:** bedroom 100, sunbeam 76, downdraft 120, landing 93.
- **Good pilot:** bedroom 100, sunbeam 63, downdraft 82, landing 52, existing moments 346; 643 of 950 in
  all. The good pilot flies higher and slower than the opening lines; it got 0 for the lamp because the
  sim pilot goes beside it.
- **Humans on tilt will wobble.** I expect first runs to score roughly 20 to 60% on the bedroom, sunbeam
  and downdraft moments, which is the brief's "a few style points".
- **Tuning the paths:** in Phase B, set the path heights from the skilled test pilot's log; ±1 unit is
  fine.

**Spine** (distance centre line) for the opening, then on into the existing spine:
(100, 21.5, 74.5) → (100, 19.5, 47.5) → (97.6, 19.2, 42.6) → (94.5, 19.5, 41.5) → (16.5, 21, 41.5) →
(7, 13.6, 41.5) → (0, 11.4, 38.6) → (-3, 8.5, 31) → (-3, 7.5, 22) → (-2, 8.5, 15).
That is about 156 units (39 m) before the living room.

---

## 5. Other downdrafts: no

None besides the stairwell this phase. The stairwell is the one place where going down fast is the goal.
Anywhere else, sinking air takes height the player needs: in the gallery it would only shorten the glide,
and in the living room or kitchen it would change the existing sequence, which is meant to stay unchanged.
A later room built around a dive could use one (see Later ideas).

---

## 6. Risks and geometry checks

Turn radius = speed / 1.134 (65°/s). From the sim, a 90° full-bank turn takes 1.52 s at any speed and covers:

| Speed | Forward | Sideways | Height lost |
|---|---|---|---|
| 6 u/s | 6.0 | 5.5 | 1.1 |
| 8.9 u/s | 8.6 | 7.9 | 2.8 |
| 10.6 u/s | 10.1 | 9.2 | 4.7 |

**Bedroom turn (where first-timers will most often crash).** The plane's line x = 100 is 5.5 inside the
west jamb and 2.5 inside the east jamb. Simulated turn-start windows, measured from the door's bedroom
face (z 46.5):

| Pilot | Clean | Glancing bump | Crash |
|---|---|---|---|
| Full bank, 6 u/s (R 5.3) | from 4.5 before to about 7 after the door. That is about 11 units, **≈ 1.9 s**. The 13-deep landing gives late turners room; the 9-wide gallery alone gave only 1.15 s. | later still: the plane scrapes the landing's south wall or the 15° taper | starting 5 to 6.5 units early catches the west jamb nearly side-on. Earlier than that, the plane turns inside the 18-wide bedroom and has to re-aim at the door. |
| Half bank, a typical novice (R ≈ 10.6) | from 8.5 before to about 1 before | from about 1 before to about 6 after (landing wall or taper, ≤ 45°) | starting 9.5 or more early (jamb), or more than 6 after the door |

Brushing either jamb at under 50° is a bump. Doors 0.5 thick keep the jamb face small. The narrow
early-jamb band is visible (it's the door frame) and well before the natural moment to turn.

**Camera at the door.** The camera trails about 5 units behind. Because the turn is a smooth arc through
an 8 × 10 opening, the line from the plane back to the camera passes through the doorway throughout the
turn (checked by geometry at headings 0°, 45° and 90°; confirm in screenshots). There is no sudden pull-in unless the plane hugs the west jamb.
The landing's 6-unit stub east of the door gives the camera somewhere to be when the plane points west.

**Gallery.** Low risk: 9 × 14 and straight, with no railing at the stair top.
- A hands-off plane flies straight through the door and hits the landing's south wall at about 6.7 s.
  That is correct: a visible wall, and the run must end.
- A plane that dives into the gallery floor slides at a shallow angle.

**Stair hall: landing turn at dive speed.** The plane comes off the gallery at y 17 to 21 and dives.
Simulated turn-start windows (x of the turn start, measured on flight 1):

| Pilot | Clean | Bump | Crash |
|---|---|---|---|
| Moderate dive held, pitch -0.5, about 8.5 u/s at the turn, R ≈ 7.5 | x 12 to 2: **10 units ≈ 1.2 s**. Leaves the turn at y 7 to 10, 9.4 to 9.9 u/s. | x 1: west wall | |
| Hard dive held, -0.8 to -1.0, 9.5 to 11 u/s, R 8.4 to 9.7 | x 8 to 3 for the walls, but holding this dive through the turn puts the plane onto flight 2's steps | turning at x ≥ 10 clips flight 1's banister; x 2 to 1: west wall | only with no turn until about x 0 (hits the wall at ≥ 50°) |

Specific risks:
- **Diving too hard through the turn** (holding -0.8 or more) puts the plane on flight 2's steps. The ramp
  collider makes this a skim, not a step-edge crash. Visible cause: "I dove into the stairs."
- **Turning early while low** clips flight 1's banister. On a moderate dive it clears the rail by 0.7 to
  1.7, and a non-diver by 2.4 or more. Only hard divers who also cut the corner touch it.
- **Floaters** (no dive) leave the turn at y 12.5 to 14.5. They then need a gentle dive (about 12°) to get
  under the 11.5-high arch 15 units ahead. The arch is the brightest thing in view. Without the downdraft
  they would be at y 16 to 17, so the downdraft is doing its job.
- **Newel post at the apex:** the good line passes 2.2 units away, 1 unit above its top. Only very tight
  cutters bump it.

**Camera in the stair hall.** It is open and tall, so the chase camera has room.
- The only cramp is a plane skimming flight 2 within about 1 unit of the steps: the steps behind rise into
  the camera ray and the camera pulls in.
- Optional camera tweak: ease the camera height from 1.0 to 1.5 while the plane is over a stair flight.

**Arch and living room.** The plane arrives at y 8 to 9.5, so the camera (+1) stays under the 11.5 arch
top. The radiator is entered at y 5 to 7.5 (simulated), enough for its full climb. The floor lamp (-7.5, -9),
armchair and plant all stay at least 3.5 units off the line.

**Performance.** This adds:
- two light shafts (transparent overdraw: keep them soft and thin)
- about 80 sunbeam motes, about 40 skylight motes and about 60 downdraft wisps

If the phone drops frames, cut the skylight's particles first.

---

## 7. Later ideas (outside this phase)

- **More rooms** (the owner's plan for 90 to 120 s): for example, a bathroom with shower steam off the
  gallery, or an attic playroom.
- **A sunroom with a wide thermal** (radius 6 or more, room 16 × 16 or larger) where skilled pilots can
  circle to climb. This is the classic glider skill, and it suits a later room.
- **A cold-window downdraft** in a later room built around a dive.
- **Live props:** a cat on the landing that turns its head, curtains stirring in the gallery, a door left
  ajar that swings. Anything that moves or collides is a new system.
- **Best-run ghost plane;** a combo bonus for chained "perfect" moments.
- **A soft giggle or "whee" at the throw and at the window.** This is sound, but it may break "we never
  see the kid"; owner's call.
- **Time-of-day variants:** the sunbeam angle changes with the hour.

---

## 8. The 60-second target (decision for the owner)

Simulated whole runs with this layout and the current tuning:

| Pilot | Arch reached | Whole run |
|---|---|---|
| Decent | 23.6 s | ≈ 49 to 50 s (adding the lead's measured ~25 s for the existing demo, +1 s for the longer entry) |
| Good (nose slightly up, clean lines) | 26.6 s | **53.7 s** |
| Expert floater (pitch +0.2, about 4.5 u/s) | | 55.4 s |

**Why space alone doesn't close the gap.** Time is roughly path length divided by speed. The opening is
already about 156 units long, with a 64-unit straight after the sunbeam (the gallery, about 12 s). Gaining
6 s more for a good pilot needs about 30 more units of gallery: a straight of more than 22 m. That is the
dead air the brief rules out.

**Levers, measured in the sim:**
- **Gravity 8 → 7** (stall 3.74 / 5.05, per the tuning note): good run 53.7 → ≈ 57 s. Everything is a
  little slower and floatier, turns get easier, the top dive speed drops about 6%, and thermals feel
  stronger. Gravity 6.5 gives ≈ 58.6 s but the stair dive loses thrill (top speed about 9).
- **Gallery +15 units** (move everything east of x 79 by +15, and the skylight to x ≈ 52): about +3 s for
  a good pilot. It needs one more visual beat.
- **The next phase's rooms:** this is the honest route to 60 s and beyond.

**My recommendation.** Build Phase A at the dimensions above. In Phase B, run the test pilots and the
phone playtest. If the plane feels a little quick on the phone, try gravity 7. If good runs are still
under 60, add the +15-unit gallery. I would not ship a longer gallery than that.
