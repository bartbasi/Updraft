# Phase 4 plan: deeper flying and more world (Updraft)

Owner brief: Phase 3 "worked great" for both the plane and the balloon, at 115-120 fps on a Galaxy Z Flip5.
This plan covers:

- **Part A, deeper flying.** These are owner-approved new systems:
  - drifting thermals;
  - a "lift lost" sound;
  - clouds that thin once they have been climbed;
  - a ridge gull;
  - plus one sink zone that I propose.
- **Part B, more world:** a gap through the far hills to a lake.

Everything else here is layout, tuning, looks, sound or scoring.

World axes are as before. The window is at z -89 and the flight heads -Z. +X is the player's right. The breeze blows toward -X.
Glide figures come from `docs/outside-plan.md` §0:

- neutral glide 6.05 u/s, sinking 0.62 u/s, which is **9.7 : 1**;
- full-bank turn radius 5.6;
- a circling climb is about the updraft minus 0.7.

## 0. Measured baseline (today's build)

Each skilled route is one autopilot flight (seed 1). The novice row is 10 flights.

| Pilot | Run | Outside | Ends | Total |
|---|---|---|---|---|
| Skilled, lavender | 70.9 s | 29 s | Lavender | 1986 |
| Skilled, picnic | 77.0 s | 36 s | Picnic | 2400 |
| Skilled, ridge | 87.6 s | 46 s | Lavender | 2235 |
| Skilled, chain | 114.5 s | 73 s (airtime capped at 60) | Lavender | 2324 |
| Novice ×10 | 72-76 s (median 73) | about 31 s | 10/10 reach outside, 0 crashes | |

- The window is always at t ≈ 41.5 s.
- A good pilot's usual run (ridge or picnic) is **77-88 s**. The target is about **120 s**.
- The chain already reaches 115 s, but with 11-13 s silent glides at autopilot speed.

**Approach.** Do not lengthen the house: that would slow every retry and change the opening. Instead, give good pilots somewhere to *go* past the valley. The novice run stays as it is (73 s), so retries stay fast.

---

# Part A: Deeper flying

New `tuning.gd` group **"Lift feel"**. The numbers are next to each mechanic.

## A1. Thermals drift with the breeze

**Rules**

- Applies to every outdoor *cylinder* thermal: L1-L4 and the new ChalkHeat and SandHeat.
- It does not apply to box zones (the ridge, the bluff, lake sink) or to anything indoors.
- Each thermal has its own drift clock. The clock starts the first time the plane comes within `thermal_drift_wake` × radius of the thermal's centre (plan view).
  - So every thermal is exactly where its cloud said it was when you first arrive. This is a fairness rule.
  - Then it drifts in -X at `thermal_drift_speed`, up to `thermal_drift_max` × radius, and stays there.
- The drift resets every run.
- These move with it:
  - the air (`Thermal` node position);
  - its column mesh and mote emitter (motes already in the air stay put, which gives a natural downwind smear);
  - its cloud puffs;
  - its circling birds.
- The ground cause (field, barn, fire, chalk, sand) stays put. With the cap at 0.5 × radius, the column always still stands at least half over its cause.

| Field | Value | Why |
|---|---|---|
| `thermal_drift_speed` | **0.25** u/s | One full-bank lap (≈ 5.5 s) shifts the core 1.4 u. That is noticeable over 2-3 laps, never within one. |
| `thermal_drift_max` | **0.5** (× radius) | L1 stops after 6 u (24 s), the others after 5 u (20 s). |
| `thermal_drift_wake` | **1.5** (× radius) | Starts as you arrive. |

**What it does to a climb.** I measured this with a FlightModel-only scratch sim (not in the repo): an orbit-at-6-u pilot, 25 s from entry at y 5.

| Thermal | Drift | Naive (keeps the old centre) | Re-centres on the beeps | Vario sighs, naive / re-centre |
|---|---|---|---|---|
| L1, R 12, 4.5 u/s | 0 | 29.5 | 29.5 | 0 / 0 |
| L1, R 12 | 0.25 | 28.6 | 29.5 | 1 / 0 |
| R 10, 4.0 u/s | 0 | 28.2 | 28.2 | 1 / 1 |
| R 10 | 0.25 | **22.9** | **27.5** | **4 / 1** |
| R 10 | 0.35 | 21.9 | 27.4 | 4 / 1 |

What this shows:

- **L1 is barely affected.** The first-timer's thermal stays forgiving.
- In the 10-radius thermals, re-centring is worth about +4.6 u per climb. A naive circler still climbs (to 22.9).
- The sigh count separates the two pilots cleanly, so A2 is how a player learns to re-centre.
- I chose 0.25 over 0.35: the gain is the same and it is gentler.

**How it reads**

- Clouds slide slowly left against the hills. Real cumulus do this.
- Birds stay under their cloud.
- Motes stream left as the emitter moves.
- No HUD.

**Fair**

- The thermal is where you saw it on arrival.
- The drift is capped.
- It is always toward -X, the way the windsock, smoke and seeds already point.
- The trees on the right-hand slopes are upwind, so drifting moves columns *away* from them. The tree-clearance check uses radius × 1.5 + 4 for new trees.

**Test**

- Unit test: a thermal's centre, its cloud puffs and its bird centres all move by the same offset; the offset is 0 before wake, 0.25 × t after it, and capped at 0.5 R.
- Autopilot: skilled orbits use the thermal's **live** centre. Add a `naive_orbits` flag that keeps the original centre.
- Pilot test, BarnHeat entered at y ≈ 18:
  - the re-centring pilot reaches top - 2 within 12 s;
  - the naive pilot still gains ≥ 5 u in 15 s;
  - the re-centring pilot is at least 20 % faster to the top.

## A2. "Lift lost": a soft sigh, plus low ticks in sinking air

The vario currently goes silent both at the edge of a column and at its top. The sigh tells these two apart: the edge sighs, the top does not.

**Sigh rules.** It plays once when the vario turns off and all of these hold:

1. The plane is outdoors and not stalled.
2. The vario had been on for at least `lift_lost_min_on`. Brief passes and indoor lift never sigh: the radiator and kettle are flown through on purpose.
3. The plane is more than `lift_lost_top_margin` below the top of the zone giving the most lift on the last "on" tick. For a cylinder the top is base + height; for a box it is its origin y + size.y.
   - Topping out is silent: the beeps just slow and stop, and A3 thins the cloud.
   - A ridge pilot holding y 31 under the ridge's 33 top never sighs.
4. No sigh in the last `lift_lost_cooldown` seconds.

Sound and tuning:

- Pitch is the zone's `chime_pitch` × 0.9, so each thermal keeps its own voice.
- A repeat within `chime_repeat_window` (12 s) is `chime_repeat_db` (-4 dB) quieter, the same as the re-entry chime.
- The lap rhythm when circling off-centre becomes: chime, beeps, sigh, quiet, chime. The sigh lands on the side to turn away from.

| Field | Value |
|---|---|
| `lift_lost_min_on` | **1.5** s |
| `lift_lost_top_margin` | **3.0** u |
| `lift_lost_cooldown` | **4.0** s |
| `lift_lost_db` | **-15** dB (the beeps run -14..-7, so it sits under them) |

**Sink ticks.** These exist only because of the new lake sink (B2). If the owner turns lake sink down, drop the ticks too.

- They play outdoors only, while the air at the plane is ≤ `sink_tick_air` and the plane is not grounded.
- They never play indoors: the stair downdraft is a thrill and keeps its own whoosh.
- Interval and loudness lerp with sink from 0.3 to 1.0 u/s.

| Field | Value |
|---|---|
| `sink_tick_air` | **-0.3** u/s |
| `sink_tick_interval_slow` / `_fast` | **0.8 / 0.5** s |
| `sink_tick_db_quiet` / `_loud` | **-21 / -16** dB |

**Sounds (gen_sounds.py)**

- `audio/sigh.wav`:
  - 0.38 s sine gliding exponentially from 470 to 300 Hz;
  - plus 12 % band-passed noise (a breath) under the same envelope;
  - 40 ms attack, smooth decay, peak -6 dBFS.
- `audio/sink_tick.wav`:
  - 0.06 s, 210 Hz sine with the 2nd harmonic at 0.3;
  - 3 ms attack, 45 ms decay.

**Test**

- Vario unit tests:
  - a mid-height exit sighs;
  - a climb to the top does not;
  - on for 1.2 s does not;
  - indoors does not;
  - a second exit within 4 s does not.
- Ticks:
  - none in the stair downdraft;
  - ticks over the lake at y 10;
  - none on the grass.
- The flight log gets `lift lost (sigh) in <zone> at y` and `sink ticks on/off`.
- Expected counts:
  - re-centring skilled routes: ≤ 1 sigh per thermal;
  - novices: 1-4 on L1, from flying straight through it. That is the "turn back" lesson.

## A3. Clouds thin once climbed

**Rules**

- A thermal counts as "climbed" this run when the plane is within its radius (plan view, live centre) and at least `top - cloud_thin_below_top`.
- From then, over `cloud_thin_seconds`, each of its 4 puffs:
  - scales to `cloud_thin_scale`;
  - moves out from the cloud centre by `cloud_thin_spread` (it breaks up);
  - shifts colour from `fdfbf8` to `eef2f6`, so it fades toward the sky.
- **The lift is unchanged.** It is a nudge, not a penalty. Going back to an old thermal still works, so it stays forgiving.
- Birds stay. They are the "lift is here" sign, and that stays true.

| Field | Value |
|---|---|
| `cloud_thin_below_top` | **2.5** u |
| `cloud_thin_seconds` | **8** s |
| `cloud_thin_scale` | **0.55** |
| `cloud_thin_spread` | **1.3** |

**Build note (frame budget)**

- Move the cumulus out of the "Outside" mesh into **one MultiMesh**: 6 thermals × 4 puffs = 24 instances, using the existing puff sphere, vertex colour and per-instance colour.
- Drift (A1) and thinning are then both just instance transforms. That is one extra draw call.
- Keep the clouds **opaque**. No alpha: big overlapping see-through spheres overhead are exactly the overdraw that phones hate.

**How it reads.** At the top, the cloud overhead visibly shrinks and frays while the next fat cloud sits on the horizon. "Go there."

**Test**

- Unit test: after a climb, the puff scale is ≤ 0.6 by 8 s; unclimbed clouds are unchanged; a new run resets everything.
- Capture from L1's top facing L2 at t+0 and t+8 s.

## A4. A gull joins you on the ridge

**Rules (looks and sound only; no collision, no effect on flight or score)**

- **Trigger:** the plane is inside RidgeLift (or the new BluffLift, whichever comes first), with its heading within 40° of the ridge's long axis (±Z), for `gull_wait` seconds. At most once per run.
- **Arrive (2.5 s):**
  - starts 25 u ahead, `gull_side` to the hill side and 4 u up;
  - eases into the slot `gull_side` to the hill side, `gull_up` up and `gull_ahead` ahead;
  - "hill side" means toward -X in world terms, mapped to the plane's left or right.
- **Escort (`gull_stay` s):**
  - follows the slot with a lerp at rate `gull_follow`, so it lags and floats naturally;
  - adds its own ±0.3 u bob over 2.5 s and banks with the plane;
  - wings held still: gulls soar ridges.
- **Leave (3 s):** banks away over the crest, climbing 2 u/s with 3 wing beats, and is gone past 40 u. It also leaves early if the plane exits the lift box.
- **Never:**
  - closer than 1.5 u to the plane;
  - below terrain + `gull_min_ground` (if the slot would be, the gull swaps to the valley side);
  - within 15° of screen centre.

  Check of the last rule: the slot at 3.5 to the side and 1 ahead, with the camera 3.4 behind, is 38° off-axis, inside the ±60° horizontal view at FOV 80 on a 2:1 screen.
- **Looks:**
  - white body `fbf8f1`, grey wing tops `9aa3ad`, dark tips `5f5b70`, wingspan 2.4;
  - two wing halves so they can beat;
  - one MeshInstance.
- **Sound:** `audio/gull.wav` once on arrival at `gull_call_db`.
  - 0.55 s "kee-ow": 1500 Hz rising to 1900 Hz in 80 ms, then falling to 1100 Hz;
  - 7 Hz ±3 % vibrato, 2nd harmonic 0.25, 3rd harmonic 0.1.

| Field | Value |
|---|---|
| `gull_wait` | **1.5** s |
| `gull_stay` | **6** s |
| `gull_side` / `gull_up` / `gull_ahead` | **3.5 / 0.8 / 1.0** u (× 1.2 when flying the balloon) |
| `gull_follow` | **3.0** /s |
| `gull_min_ground` | **2.5** u |
| `gull_call_db` | **-12** dB |

**Test**

- The ridge route log shows `gull joins` about 1.5 s after RidgeLift and `gull leaves` about 6 s later, once per run.
- A geometry test on every frame of the escort checks the three "never" rules.
- Capture mid-escort on the ridge, plane and balloon.

## A5. Sink: what I propose, and what I don't

- **Yes: lake sink (B2).**
  - Weak: 0.4 u/s peak.
  - Readable: open water. Audible: the ticks.
  - It creates a real decision: cross the water directly and lose height faster, or skirt the shore.
- **No general sink between thermals.**
  - Novices glide L1 → lavender with about 10 u to spare. Even 0.3 u/s of sink costs a third of every glide.
  - Novices would land short of the lavender and lose +200, which goes against "forgiving".
- **No lee-side sink behind the ridge crest.**
  - The picnic route arrives only about 3 u above the plateau.
  - 0.5 u/s over the 5.5 s from crest to blanket costs 2.7 u, which turns the expert landing into luck.
  - It is also invisible air, so it would not be fair.

---

# Part B: More world: "the Gap" and the lake beyond

## B0. The idea

- The valley's far head wall becomes **the Downs**, a line of high hills with one wide notch: **the Gap**. A white windmill turns on its left shoulder.
- The notch shows on the skyline from the window: 245 u away and 11° tall, through fog at 0.54 transmittance. It invites exploring from the first second outdoors.
- Only a pilot who has climbed past the first thermal can clear it. A new **chalk-pit thermal** at the valley's end is the last step up.
- Through the Gap:
  - the ground drops away into a bowl with a lake;
  - there is an island, a slowly sailing boat, a beach with huts and a warm-sand thermal;
  - there is a windy west bluff with ridge lift.
- It is a second "window reveal", with two new landing prizes.
- Novices never need it. Their run, the opening, the downstairs demo and the valley routes are unchanged.

## B1. Ground (scripts/course.gd)

`ground_height(x, z)` is restructured as below.

- `_valley(x, z)` is **exactly today's formula**, renamed.
- Every height in the valley with z > -285 is unchanged. I checked this to 0.0 in a scratch port.

```
const CREST_Z := -339.0                 # the Downs' crest line (the old head wall, 250 out)
const GAP_X := 6.0                       # centre line of the Gap
const GAP_HALF := 14.0                   # half-width of its flat floor
const GAP_WALL := 1.1                    # slope of its walls (48°)
const GAP_CUT_Z := Vector2(-285.0, -395.0)
const SADDLE := Vector2(-334.0, 13.0)    # z and height of the Gap's highest point
const DOWNS_FALL := 35.0                 # the far side falls to the bowl over this distance
const LAKE_Y := -1.0                     # water surface
const LAKE_CENTRE := Vector2(0.0, -420.0)
const LAKE_RADII := Vector2(40.0, 30.0)
const ISLAND := Vector2(-6.0, -424.0)
const ISLAND_RADIUS := 8.0
const BLUFF_FACE_X := Vector2(-44.0, -84.0)
const BLUFF_HEIGHT := 24.0

ground_height(x, z):
    h = _valley(x, z) if z > CREST_Z else _bowl(x, z)
    if GAP_CUT_Z.y < z < GAP_CUT_Z.x:
        h = min(h, _gap_floor(z) + GAP_WALL * max(0, |x - GAP_X| - GAP_HALF))
    return h

_gap_floor(z):        # valley side rises to the saddle, lake side falls to the shore
    if z >= SADDLE.x:  v = _valley_smooth(GAP_X, -290)   # no rolls; ≈ 6.6
                       return lerp(v, SADDLE.y, smoothstep(290, 334, -z))
    else:              return lerp(SADDLE.y, LAKE_Y - 0.5, smoothstep(334, 385, -z))

_bowl(x, z):
    e = CREST_Z - z                               # distance beyond the crest
    f = smoothstep(0, DOWNS_FALL, e)
    q = Vector2(x - LAKE_CENTRE.x, z - LAKE_CENTRE.y) / LAKE_RADII  .length()
    h = _valley(x, CREST_Z) * (1 - f)                                  # the Downs, falling away (meets the valley exactly at the crest)
      + 0.012 * max(0, x - 58)^2 * f                                   # dunes and slopes beyond the beach
      + BLUFF_HEIGHT * smoothstep(44, 84, -x) * smoothstep(0, 30, e)   # west bluff and its plateau
      + 0.03 * max(0, -x - 96)^2 * smoothstep(0, 30, e)                # up to the west edge
      + 0.02 * max(0, e - 120)^2                                        # far rim
      + rolls(x, z) * f * smoothstep(1.0, 1.5, q) * (1 - smoothstep(40, 58, x))   # no rolls on the lake, shore or beach
    bed = LAKE_Y - 0.15
    if h > bed: h = bed + (h - bed) * smoothstep(0.85, 1.15, q)        # the lake: flat bed just under the water
    h = max(h, LAKE_Y + 1.2 - 3.0 * smoothstep(ISLAND_RADIUS - 2, ISLAND_RADIUS + 2, |(x,z) - ISLAND|))
```

`rolls(x, z)` is today's two-sine term × 0.6, without the d/25 fade (that fade is 1 out here anyway).

**Heights** (smooth curve, from my scratch port):

| Point (x, z) | Height | Note |
|---|---|---|
| Gap floor (6, -300) / (6, -320) / saddle (6, -334) | 7.5 / 11.5 / **13.0** | Was 12.5 / 30.9 / 50 |
| Gap at the saddle, x -16 / x 26 | 21.8 / 19.6 | The corridor at y 20 runs from x -14 to 26, **41 u wide** |
| Gap floor (6, -352) / (6, -370) / shore (6, -385) | 8.9 / 1.5 / -1.4 | A short valley down to the water |
| Downs crest, x -40 / x 50 | 48 / 46 | The crest elsewhere is 45-110 |
| Downs inner face (-30, -350) / (-30, -370) | 34 / 2 | Steep; scenery |
| Chalk pit (-14, -290) | 5.2 (with rolls) | At the foot of the Downs |
| Lake bed / water | -1.15 / -1.0 | |
| Island top | 0.2 | Flat out to r 6, shore at about r 7.8 |
| Beach (x 42..58, z -380..-446) | 0 ± 0.3 | Flat |
| Bluff face x -48 / -60 / -72 / plateau -84 | 0.7 / 8.4 / 18.8 / 24 | Steepest 0.9 (42°) |
| Far shore (0, -460) / rim foot (0, -480) / rim (0, -500) / edge (0, -525) | 0 / 8.8 / 33.6 / 87 | |
| West edge (-123, -420) / east edge (123, -420) | 46 / 51 | |

**Bounds and safety**

- `WORLD_BOUNDS` z limit goes from -339 to **-525**.
- Every bowl edge is ≥ 45, and no bowl lift tops out above 34.
- Checked: a plane at 34 meets the rim at z ≈ -501, the west slope at x ≈ -114 and the east slope at x ≈ 108, all inside the bounds.
- A hands-off glide straight on from the saddle at 22.5 meets the rim foot at z ≈ -474, after about 23 s. The slope there is 31°, so with the 6° glide path the plane meets it at about 37°: a slide, not a crash (crashes need 50°).
- The Downs elsewhere are ≥ 30 within 30 u of the Gap and ≥ 45 beyond that. Even from the ridge top (33), nobody crosses the Downs except through the Gap.

**Grid**

- Add a second terrain grid, a separate MeshInstance "Bowl" with its own collision:
  - x -126..126, z -342..-528, at step 6;
  - 42 × 31 cells, about 2,600 triangles.
- Skip cells that lie entirely under the water: the water surface covers them, and the flat bed still collides.
- The existing valley grid stays as it is. Its last rows (to -342) now follow the cut.

**Water**

- Look only, not solid: the bed collides at -1.15, so a plane comes to rest floating 0.15 under the surface.
- Drawn as an ellipse fan (32 segments) at LAKE_Y with radii × 1.05. The shoreline is wherever the terrain crosses -1.0.
- Opaque, vertex-coloured `a9cfe0`.
- Six thin lighter ripple stripes, `c4e0ec`, running along X (they show the breeze).
- A 1.5 u pale sand rim `efe2c6`, painted along the shore.

**Trees**

- **Keep today's 40 valley trees** by generating them with today's rules, then *filtering*:
  - drop any with z < -285 and |x - GAP_X| < GAP_HALF + 12;
  - drop any within 10 × 1.5 + 4 of the chalk pit.
  - Generating with new rules would shift every later tree.
  - Log how many are dropped. I expect 2-5, all on the old head wall.
- Add about 24 bowl trees:
  - an orchard of round trees in rows on the rim slope, z -488..-498, x -60..60, step 8. That is beyond where a hands-off glide from the saddle comes down (about -474).
  - 6 wind-bent pines (crowns offset 1 u toward -X) on the bluff plateau, x -80..-110.
- No bowl tree within 4 u of any lift zone's edge (thermals at radius × 1.5), inside the lake ellipse × 1.1, in the beach strip, within 8 u of the boathouse, or in the gap channel.

**Far hills.** Today's six decorative hill spheres stand where the bowl now goes. For example, (-60, -12, -430) with radius 120 would rise through the lake. Move them out:

```
[-220, -620, 90], [-60, -700, 130], [120, -660, 110], [260, -580, 80], [10, -780, 170], [-330, -540, 70]
```

The camera's far plane is 900, so these are fine.

## B2. Lift sources

| Name | Centre | Size | Top | Scale (peak u/s) | Chime pitch | Ground cause | Long-range cue |
|---|---|---|---|---|---|---|---|
| **ChalkHeat** (valley) | (-14, -290) | R 10 | 27 | 0.8 (4.0) | 1.08 | White chalk scar on the Downs' foot: `efe9df` / `e4ddd0` stripes, x -24..-4, z -282..-300 | Cumulus (base 31), 3 birds, motes |
| **SandHeat** | (50, -392) | R 10 | 30 | 0.85 (4.25) | 1.12 | North end of the beach, pale sand `f1e3c4` / `ead8b0`, x 40..58, z -380..-446; 3 beach huts | Cumulus (base 34), 3 birds, motes |
| **BluffLift** | Box centre (-60, 0, -420) | (24, 34, 100), so x -72..-48, z -370..-470 | 34 | 0.45 (2.25) | 0.8 | West bluff facing the breeze | 100 seeds, wind-bent grass strip x -46..-70, 6 hovering birds (×1.5), flag on the plateau |
| **LakeSink** | Box centre (0, -1, -420) | (72, 26, 54) | 25 | `downdraft_strength` × **0.115** (0.4 down) | n/a | Open water | Water itself; ticks (A2) |

The new zone looks:

- `Look.RIDGE` for the bluff, the same as the valley ridge.
- A new `Look.LAKE` for the lake sink: no column, no wisps, **no entry sound**. The ticks are its only cue, so gliding over a lake never plays a "whoosh".
- ChalkHeat and SandHeat join `OUTDOOR_THERMALS`, so they get clouds, birds, drift and thinning.

**Why each is there**

- **ChalkHeat** is the gate and the last step up.

  | From | Distance | Arrives at | Ground there | Clearance |
  |---|---|---|---|---|
  | L1 top (22.5) | 172 u | y 4.8 | 5.2 | Below the ground: this route is out of reach (novices only fly L1) |
  | L2 top (27) | 133 u | y 13.3 | 5.2 | 8.1, reachable |
  | L3 top (29) | 75 u | y 21.3 | 5.2 | 16.1 |
  | Ridge end (-37, 31, -255) | 42 u | y 26.7 | 5.2 | Fly through and pick up beeps |

  - It sits 10 u north of where the Downs steepen, so a full-bank circle (r 5.6) clears the slope.
  - The sim shows radius 9 / 0.7 climbs too weakly for an r 6 orbit (14.8 at 25 s), so it is a full R 10 / 0.8 like L2-L4.
- **The Gap**, from each source (the floor is 13):

  | From | Distance | Arrives at | Clearance |
  |---|---|---|---|
  | Chalk top | 48 u, 8 s | y 22 | 9 |
  | L4 top (30, 29, -258) | 84 u, 14 s | y 20.8 | 7.8 |
  | Ridge end → chalk → saddle | | y 21.3 | 8.3 |

  - The corridor is 41 u wide at y 20.
- **Through the Gap, follow the channel.**
  - The Downs' inner flanks fall steeply. A straight line from the saddle to the bluff foot clips the left flank at (-22, -361).
  - Via the channel (fly on to about z -366, then turn) the minimum clearance is 9.2.
  - The channel reads as a little valley with a painted stream down it, the boathouse and the water at its end, so the line is obvious.
- **The lake**, from the saddle at 22.5 (glides with lake sink included):

  | To | Arrives at | Height above ground | Time |
  |---|---|---|---|
  | Island | y 11.2 | 11 | 15 s |
  | Beach landing | y 11.9 | 12 | 17 s |
  | SandHeat (via the channel) | y 14.4 | 14.7 | 13 s |
  | Bluff foot (via the channel) | y 12.9 | 12.6 | 15 s |

  - Every destination in the bowl is reachable from a normal Gap crossing. The lift sources are for staying longer and exploring.
- **BluffLift:** 2.25 u/s air gives about 1.5 u/s climbing straight along the face. From 13 at the foot it reaches about 30 in roughly 12 s and 75 u along.
- **Sink math:** over the water the glide is 6.05 / (0.62 + 0.4) = **5.9 : 1** instead of 9.7. Crossing all 80 u of the lake costs 13.5 u instead of 8.3. From any lift top in the bowl the far shore is still reachable. Sink costs height; it never traps you.

## B3. Landmarks and looks (all drawn in code, original)

| Thing | Where | Spec | Solid? |
|---|---|---|---|
| **Windmill** | Left shoulder of the Gap, (-26, ground ≈ 32.8, -332) | White tapered tower (r 2.0 → 1.4, 10 tall, `fbf7f0`), cap `b5524a`; 4 sails, radius 5, dark lattice `7a6a5e`, hub at +9; faces the breeze (+X), turning 0.5 rad/s; top at y ≈ 47 | Tower yes. The sails are 15 u above any flight line and are not solid. |
| **Stone wall and sheep** | Across the valley at z -252, x -28..22 | Dry-stone wall `c9c2ba`, 1.2 tall, with a white gate; 8 sheep (white puff + `5f5b70` head) grazing south of it | Wall yes; sheep no |
| **Gap stream** | From a spring at (6, -346) down the channel to the shore at (6, -385) | Painted ribbon, 2 wide, wiggling ±1.5, like the valley stream | No (painted) |
| **Sailboat** | Circles (14, -410) at r 12, 1.2 u/s anticlockwise | Hull 3.2 long, `fbf7f0` with a `a9c8e8` stripe; sail triangle 3.5 tall, heeled 10° toward -X; pennant `f19e8f` | No |
| **Island** | (-6, -424), r 8 | Grass top `c6dfa8`, sand ring; a small red pennant on a thin pole at its north edge; a beached rowing boat on the south shore | Pole no; boat no |
| **Beach huts** | (63, -398), (63, -405), (63, -412), backing onto the dunes | 2.4 × 3.2 × 2.4 with pitched roofs, striped `a9c8e8` / `f4dc9b` / `f2b8a2` and white | Yes |
| **Boathouse and jetty** | Far shore, (-22, -452) | 7 × 5, walls 3.5 `e9d7b6`, roof `c1675a`; jetty 1.2 × 8 into the water at LAKE_Y + 0.2 | House yes; jetty no |
| **Bluff flag** | Plateau (-88, ground, -415) | Pole 8 tall, pennant 3 long `e8604c`, streaming -X | No |
| **Wildflower meadow** | Far shore, z -455..-485 | Painted grass with `FLOWERS` speckles at 3× today's rate | No |

Nothing copies any game. It is generic English-downland countryside, in the same pastel palette as the valley.

## B4. Sight lines (FOV 80; fog transmittance exp(-0.0025 d))

| From | You see | Check |
|---|---|---|
| Window sill | The notch in the Downs on the skyline, 11° tall, with the windmill sails turning on its left | 245 u, transmittance 0.54. The tower is 12 tall, about 2.8° or about 38 px on a 1080 px-tall phone. Sails in motion catch the eye. |
| L3 / L4 / ridge tops | The notch with sky through it, the windmill, the chalk scar and its cloud ahead | 75-90 u, transmittance about 0.8 |
| Crossing the saddle | The lake 14° below the horizon straight ahead; the island; the sailboat; the beach and its cloud 30° right; the bluff, flag and hovering birds 45° left | Island 90 u, beach cloud 73 u, bluff 108 u, all at transmittance ≥ 0.76 |
| Bluff top | The island and the beach across the water | 57 u / 107 u |

The bowl's contents are hidden from the valley except through the notch. That is deliberate: the reveal is the reward.

## B5. Scoring

| Item | Value |
|---|---|
| New style moment **"Through the Gap"** (`gap`) | `{"points": 150, "radius": 4.0}`. Path: (6, 19.5, -318), (6, 17.5, -334), (6, 15.5, -350), (5, 12.0, -366). |
| Landing **Island** | **+500**, "Island landing!", Rect2(-11.5, -429.5, 11, 11), and only if the ground at the resting point is above LAKE_Y. The rectangle's corners are at the shoreline (r 7.8), so a plane that slid into the water gets "Splashdown!". |
| Landing **Beach** | **+250**, "Beach landing!", Rect2(42, -446, 16, 34) (the south part; SandHeat's lift ends at z -402) |
| Coming to rest on the water (lake ellipse, not the island) | Title **"Splashdown!"**, no bonus. Not a crash: no crumple, the airtime counts. A ring of 12 droplets and `audio/splash.wav`. |
| Any other rest past the crest | Title **"Through the Gap!"** |
| `airtime_max_seconds` | 60 → **90** |
| Spine | Replace the last point (0, 6, -280) with (0, 6, -280), (6, 18, -334), (4, 6, -400), (0, 4, -480). That adds up to +50 m (+500) for reaching the far shore. Valley distances are unchanged. |

About the "Through the Gap" path:

- It sits 4.5 u above the saddle.
- Pilots arrive at 21-22, so earning it means **diving about 4 u in the last 30 u**. That is speed, the floor rushing past, then the drop into the bowl. This is the outdoor answer to the stair dive.
- Arriving high and gliding straight over is 5 u off the path, which gives 0 points. Earned, not given.

**Gap gust (the reveal moment):**

- Fires the first time the plane passes z < SADDLE.x within 30 of GAP_X:
  - `swell(gap_gust_db 4.0, gap_gust_fade 1.2)` and the whoosh;
  - `camera_fov_gap_kick` **+5°** over 0.4 s, easing back over 1.6 s.
- These are new tuning fields in "Camera" and "Sound".

**Totals (estimates, so the reward ladder makes sense)**

| Run | Total | Breakdown |
|---|---|---|
| Novice lavender | about 1990 | Unchanged |
| Picnic | about 2400 | Unchanged |
| Chain | about 2320 | |
| **Ridge → Gap → island** | **about 3200** | 135 m = 1350, style 987, airtime 75 s = 375, island 500 |
| **Chain → Gap → beach thermal → island** | about 3250 | |

Going further is the big prize. The picnic remains the valley's expert prize.

## B6. Expected timings

Times are from the autopilot logs up to the ridge or L3 top, then neutral-glide arithmetic at 6.05 u/s.

| Pilot / route | Path | Run | Outside |
|---|---|---|---|
| Novice | L1 → lavender (unchanged) | about 73 s | about 31 s |
| Skilled lavender / picnic / ridge / chain | Unchanged | 71 / 77 / 88 / 115 s | |
| **New "gap"** | L1 → ridge (to its end at z -255) → chalk (fly through) → Gap → island | **about 116 s** | about 75 s |
| New "lake" | L1 → L2 → L3 → chalk (climb) → Gap → SandHeat (climb) → island | about 145 s | about 104 s |
| New "bluff" | L1 → ridge → chalk → Gap → bluff run → across the lake → beach landing | about 150 s | about 108 s |

The "gap" timeline:

- t 69: ridge run done;
- t 76: ridge end;
- t 83: chalk, with beeps;
- t 91: saddle, with the Gap style, gust and reveal;
- t 100: shore, ticks start;
- t 106: over the island at y 11;
- about t 116: landed.

**Dead air at neutral speed (new legs):**

| Leg | Time | Beat |
|---|---|---|
| Ridge end → chalk | 7 s | |
| Chalk → saddle | 8 s | |
| Saddle → shore | 9 s | Starts with the style and gust; the stream, boathouse and boat pass mid-way; ends with the ticks |
| Shore → island | 6 s | |
| L3 → chalk | 12 s | The stone wall and sheep at the mid-point, and L4's smoke 44 u to the right |
| Bluff → beach across the water | 18 s | The island and sailboat pass at the mid-point. This is the explorer's choice; flagged, accepted. |

## B7. Fair failure in the new area

- Every new solid thing is visible and off the main lines:
  - the windmill is 15 u above the flight lines;
  - the beach huts sit behind the landing strip;
  - the boathouse is off the island line;
  - the wall is 1.2 tall in a part of the valley flown at y 20+.
- **The Gap is 41 u wide** at flight height, and its walls are 48° hillsides in full view.
- **The Downs' inner flanks** are the one place to clip a hill. The channel ahead is the obvious line, and the flank is a big green slope in view for 5 s.
  - Test pilots must show **0 crashes** on the "gap", "lake" and "bluff" routes over 10 seeds each.
  - My seeking pilots (fun review 4) must too.
- **Water** ends the run as "Splashdown!", never as a crash, and keeps the airtime earned.
- Sink is weak, visible (water) and audible (ticks).

## B8. Frame rate on a mid-range phone

The Flip5 has headroom. Friends' phones (Adreno 610 / Mali-G57 class) may not. Budget rules:

1. **Nothing new is transparent** except particles. The clouds, water, gull, windmill and boat are all opaque vertex-colour (`Art.material()`).
2. **Particles:**
   - new systems: ChalkHeat and SandHeat motes 80 each (the current clamp floor), BluffLift seeds **100** (the Phase 3 "second cut" number from the start);
   - extend `_show_zones_near_camera()` with a region 3, "in the bowl" (camera z < CREST_Z): there, show only the bowl zones plus ChalkHeat;
   - in the valley (camera z > -300), hide SandHeat and BluffLift;
   - result: at most about 4 particle systems, about 400 particles, are live anywhere.
3. **Meshes:**
   - "Bowl" is its own MeshInstance, so frustum culling drops it when looking back to the house;
   - it adds about 2.6k terrain triangles plus about 1.5k for trees and buildings;
   - the valley mesh is unchanged.
4. **Draw calls added:** at most 7 (Bowl, cloud MultiMesh, gull, windmill sails, sailboat, plus 2 particle systems in view).
5. **Moving things** (sails, boat, gull, clouds) set transforms in `_process` with physics interpolation off. This is the same pattern as `Birds`, and avoids the warning noted in fun review 3, item 8.
6. **Pass bar:** PERF lines must show 60 fps on the PC flight captures at:
   - the saddle facing the lake;
   - circling SandHeat;
   - the bluff run;
   - over the island.
7. **Fallbacks, in order** (put them on the phone-check list):
   - outdoor motes clamp (80, 120) → (50, 80);
   - bluff and ridge seeds 100 → 60;
   - bonfire puffs 40 → 28;
   - `scaling_3d_scale` 0.85 on the Mobile renderer.
8. **Suggestion for the lead's settings screen (part 1):** a "Lighter effects" switch that applies those fallbacks. It is not a new game system, but the owner should agree to the extra setting.

---

# C. Build order (each step testable on its own)

1. **Lift-lost sigh** (A2, sigh only).
   - Add `sigh.wav`, the tuning fields, the rule and the log event.
   - Tests as in A2. No layout change.
2. **Clouds and birds follow a thermal's live centre.**
   - Move the cumulus into one MultiMesh.
   - Add a `Thermal.drift_offset` read by clouds and birds.
   - Test: with zero drift, every puff and bird is pixel-identical to today (compare captures `window.png` and `hay_top_to_barn.png`).
3. **Drift** (A1).
   - Add the wake, speed and cap; switch the autopilot to live centres plus the `naive_orbits` flag.
   - Tests as in A1. Re-run the four existing routes: same landings, outside times within ±5 s.
4. **Cloud thinning** (A3). Tests and captures as in A3.
5. **Gull** (A4). Tests and captures as in A4.
6. **Ground:**
   - the Downs, the Gap, the bowl, the lake bed and island, `WORLD_BOUNDS`, the far hills moved, tree filtering, the Bowl grid.
   - Tests:
     - valley heights unchanged at 200 sample points with z > -285;
     - the B1 table to ±0.2 (smooth);
     - a hands-off glide from the saddle at y 22.5 heading -Z comes to rest at z -468..-480 in 20-27 s, with no crash;
     - the safety net ends a run at z -526.
7. **Bowl and chalk lift:**
   - ChalkHeat, SandHeat, BluffLift, LakeSink (`Look.LAKE`) and the ground causes; sink ticks (A2).
   - Tests:
     - the B2 arrival heights ±1.5 using scripted straight glides;
     - a bluff pilot from (-50, 13, -380) holding x -58 reaches y ≥ 28 by z -460 and never touches the face;
     - ticks occur only over the lake.
8. **Landmarks** (B3): windmill, wall and sheep, stream, boat, island details, huts, boathouse, flag, meadow, bowl trees.
   - Captures:
     - from the window sill (the notch and windmill visible);
     - from the chalk top facing the Gap;
     - crossing the saddle (the reveal);
     - from the bluff top;
     - the frame rate in each.
9. **Scoring** (B5):
   - the `gap` moment, island, beach, splashdown and "Through the Gap!" titles;
   - the spine, airtime 90, gap gust and FOV kick;
   - the end card "x of 10 moments".
   - Tests: rest in each rectangle; a rest on water gives "Splashdown!" with no bonus; airtime caps at 450 points; the valley routes' distance points are unchanged.
10. **Pilots and logs:**
    - routes `gap`, `lake` and `bluff` in `Autopilot.route()`;
    - `flight_log.gd`: MAX_SECONDS 150 → **240**, the three new `--route` names;
    - new landmarks: "crosses the wall", "crests the Gap (y, above the saddle)", "over the lake", "passes the island", "gull joins/leaves", "cloud thins: <zone>", "lift lost", "sink ticks".
    - Then I run fun review 4 with logs, my seeking pilots and captures.

# D. Pass marks for fun review 4

- Novice ×10: unchanged. 10/10 outside, 0 crashes, median 70-78 s.
- "gap" route: run 105-125 s, island landing, Gap style ≥ 0.8.
- "lake" and "bluff" routes: 0 crashes over 10 seeds; each lands on its intended spot.
- No leg on the new routes has more than 10 s of logged "nothing happening" at neutral speed, except the explorer's lake crossing.
- Sighs: ≤ 1 per thermal climb for skilled pilots, 1-4 on L1 for novices.
- PERF: 60 fps at every capture point listed in B8.

# E. For the owner (things that change the current experience)

1. **The far end of the valley opens.** The head wall gets a wide notch (the Gap) with a windmill on its left shoulder, visible from the kitchen window. A few trees on the old head wall go (expected 2-5). The rest of the valley's ground is identical.
2. **A fifth valley thermal**, the chalk pit, at the far end (-14, -290). Pilots coming home from the bonfire may also use it.
3. **A stone wall and sheep** across the valley at z -252 (looks; the wall is 1.2 tall and solid).
4. **The world is bigger.** The run no longer ends at the old head wall line (z -339); it ends at z -525. The decorative far hills move further out.
5. **Thermals drift slowly to the left** once you reach them, up to half their width, taking their cloud and birds along. The hay field (L1) is barely affected.
6. **Clouds shrink and fray** after you've climbed to the top of their thermal (looks only; the lift is unchanged).
7. **New sounds:**
   - a soft sigh when you fly out of the side of rising air outdoors;
   - low ticks over the lake;
   - a gull's call;
   - a splash.
8. **A gull** flies with you along the ridge (or the new bluff) for a few seconds, once a run.
9. **Scoring:**
   - the airtime cap rises from 60 to 90 s;
   - distance can reach about 150 m;
   - a tenth style moment, "Through the Gap";
   - new landings: Island +500, Beach +250, "Splashdown!" (no bonus, not a crash).

   **Best scores will jump.** I recommend keeping the saved best as it is; the owner may prefer to reset it.
10. **Weak sinking air over the lake** (my proposal, not on the approved list). If you'd rather not have it, remove LakeSink and the sink ticks. Nothing else depends on them, and the island gets easier.
11. **Gap gust:** crossing the Gap gives a gust of wind, a whoosh and a brief widening of the view.
12. **Optional "Lighter effects" setting** for friends' slower phones (B8.8).
13. **Not changed:** the house, the opening, the downstairs demo, L1-L4 positions, the ridge, the picnic and the lavender.

# F. Later ideas (new systems, not in this phase)

- Thermal "pulses": a cloud that forms, matures and dissolves over a minute, with a fresh one forming upwind.
- A heron that lifts off the island as you approach.
- Ghost line of your best run, drawn faintly.
- A second gull at the bluff once the first has been met, flying in formation.
- Evening light: a run after dusk with warm windows in the house and fewer thermals.
