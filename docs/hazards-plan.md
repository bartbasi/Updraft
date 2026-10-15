# Hazards plan (Endless step 4): homes, the kitten, hazards and movers

The owner's words (2026-10-14): "Your ideas for hazards are great - now let's add in two elements in
endless mode A. Buildings/Houses/Barns that show up occasionally as the player flies the balloon
around the countryside. And sometimes inside a home or a barn there will be a cat! The cat will try
to catch the balloon or plane and if the cat catches it, it's a crash ... the cat is a fun cute
hazard, cat should be very kitten like, cute."

**This step adds** (in build order; §0 has the split):

- **4a, homes and the kitten** (the owner's ask; goes to the phone first):
  - the kitten (§1);
  - homes in the countryside (§2);
  - **P20 Farmyard**, the kitten's own piece (§3);
  - the lee rotor on P13 (§4).
- **4b, weather and wires:** the viaduct train, P14 Rain Shower, P18 Pylons, P15 Windy Gap, P19 Windmill (with the miller's kitten) (§5).
- **4c, wood, water and balloons:** F3 Wood or Water (P16 is its low road), P17 Balloon Fair (§6).

**Built on:**

- endless-plan §3, §7.3, §10.4 and §11;
- forks-plan §12 ("Step 4 neighbours");
- hangar-plan §4.2 (seed purity);
- the build notes through step 3 and the phone sections;
- `pieces.gd`, `forks.gd`, `generator.gd`, `endless_world.gd` and `endless_game.gd` as they are today.

**Conventions** are the Endless plan's:

- piece-local x is across the valley, y is above the floor, and z runs from 0 down to -96 per tile;
- d is difficulty; lerp(a, b) means a at d 0 and b at d 1;
- T is the tailwind;
- **C** is a kitten's pounce centre (§1.4).

All numbers are **estimates** until `--calibrate` has measured them (§12).

---

## 0. Decisions in one page

| Question | Decision |
|---|---|
| Who is the cat? | **A kitten, always in a window or a hayloft door, never loose.** A litter of three: **Pip** (ginger, white socks), **Smudge** (soft grey) and **Bramble** (calico). Pip always lives at the Farmyard. Big head, big low eyes, stubby legs, fluffy tail. Charming, never scary (§1.1-1.2). |
| How it threatens | It watches you come, wiggles its bottom, then **lunges out of its window** with its back paws still on the sill. **It can reach 4.0 u from C and no further, at every difficulty.** Inside that, during a lunge, you are caught. Outside it, you are always safe (§1.4). |
| Telegraph | Pink shutters open with a ball of yarn on the sill: a kitten is home. It wakes at 80 u, chirps and tracks you with its head at 45 u, and wiggles from 18 u (at least 0.6 s before any lunge). It lunges at anything passing within 9 u, so you see near misses long before you are ever caught (§1.3). |
| Caught | The run ends, as the owner asked. **No pop, no crumple:** the kitten hugs the balloon (or holds the plane) and purrs, eyes happily squeezed shut, with three little hearts. The card says **"Caught by Pip!"** plus where (§1.6). |
| The string | A lunge that touches only the balloon's string **snags** (speed ×0.75, flutter). It does not catch (§1.5). |
| Near miss | A lunge that misses gives a whoosh, a +4 dB swell, a +3° FOV kick and the pop-up "Missed me!". Behind you the kitten flops on its back, then washes a paw as if it meant to (§1.7). |
| Homes (owner's A) | **Homesteads**: cottages, farmhouses and barns stand on the valley's side slopes now and then. A seeded choice per (seed, tile) fills a piece's home slots (about one home every 4 tiles), always ≥ 12 u from every line. About 3 in 10 have a kitten in the window. Those kittens just watch: you only meet them if you wander (§2). |
| The kitten as a real hazard | Two pieces put a kitten next to the line: **P20 Farmyard** (4a, from 80 m) and the miller's cottage in **P19 Windmill** (4b). A star arc, **"Cat's whiskers!"**, sweeps past just outside its reach (§3). |
| How often | About 3-5 kittens in a skilled 5-minute run. Most watch from homesteads; 1-2 are on the line. Kittens are ≥ 5 tiles apart. |
| Seed purity | Homes, kittens (where, which coat, idle timings) and mover phases come from **(seed, tile)** through local RNGs. The kitten's pounce, and the train's timing, react to the flyer: deterministic, pilot-caused, like the spiral. No global `randi()` (§9). |
| Rest of step 4 | **4b:** train, Rain Shower, Pylons, Windy Gap, Windmill. **4c:** F3 Wood or Water, Balloon Fair. P16 Pine Wood is built only as F3's low road (owner call 8). |

---

## 1. The kitten

### 1.1 Character

| | Pip | Smudge | Bramble |
|---|---|---|---|
| Coat | Ginger tabby `f2a65a`, stripes `e08a3c` on the brow, back and tail rings | Blue-grey `b8bccb`, darker nose smudge `9a9eb0` | Cream-white `fbf4ea` with ginger `f2a65a` and slate `7d7590` patches (one ear of each) |
| White bits (`fbeedd`) | Socks, bib, muzzle, tail tip | Muzzle, chest, socks | Mostly white |
| Where | Always at the Farmyard; also in homes | Homes, the station, the mill | Homes, the station, the mill |

- **Shared features:** inner ears and nose `f4b0bc`; eyes `3b3350`, each with a big white glint (upper left) and a small one (lower right); cheek blush `f6c3c9`, painted.
- **No black cat:** it would read badly against a dark window, and it carries a superstition.
- **Why three:** kids will want to meet them all. One coat per home, seeded. Pip is the face of the hazard.

### 1.2 Looks (all code-drawn, low-poly, vertex colours)

**Proportions, in units, sitting.** Storybook scale: the kitten is about 3.5× the drawn balloon (0.7 u), so a balloon is the size of its head.

| Part | Size | Where |
|---|---|---|
| Whole | 2.0 to the top of the head, 2.45 to the ear tips | |
| Head | Ellipsoid 1.30 wide × 1.10 tall × 1.05 deep: **45% of its height** (a grown cat's is about 30%) | Centre y 1.55 |
| Eyes | 0.30 × 0.36 ellipsoids, slightly proud | Centres (±0.28, 1.47): **below the head's middle and set wide**, which reads as a baby |
| Ears | Pyramids 0.48 at the base, 0.50 tall, tilted 15° out | (±0.38, 2.0) |
| Muzzle | Cream ellipsoid 0.42 × 0.26; nose a 0.1 pink triangle; a small "w" mouth (two thin dark arcs) | (0, 1.33) |
| Whiskers | 3 a side, 0.5 long, thin cream two-sided quads | Seen only close up, as in the lunge |
| Body | Egg 1.05 wide × 1.15 tall × 1.3 deep, plus round haunches | Centre y 0.55 |
| Front legs | Stubby, r 0.14, with round paws (r 0.17, white) | |
| Tail | Thick: 6 segments, r 0.16 → 0.12, 1.3 long, with a fluffy tip (r 0.18) | Held up with a hook when curious |
| Head tuft | Two tiny cones | |

**Budget:** about 700 triangles.

**Rig:** nodes so the parts move.

- Rump: body, haunches, hind legs.
- Chest: front body and front legs. It stretches in the lunge.
- Head: ears, face and whiskers.
- Eyes: a separate node, for blinks and the happy squint.
- Tail base and tail tip.

That is 6 MeshInstances, so 6 draw calls while it is drawn. A Skeleton3D with code-built bone weights (1 draw call) is welcome if the lead prefers it. Either way, only kittens within 150 u are drawn and animated (`visibility_range_end` 150), and there is rarely more than one.

**Its window ("kitten window", drawn with the kitten):**

- open casement shutters in pastel pink `e7a6c0`;
- a deep cream sill board 0.8 deep;
- a lilac ball of yarn `b9a6dc` with a loose strand hanging over the edge;
- a dark interior `4e4256` behind it, so the ginger, grey and white all pop.

**Pink shutters open always mean a kitten is home.** Other windows have closed sage `a8c49a` or blue `a9c8e8` shutters. That is the one rule the player learns.

### 1.3 Behaviour (driven by the flyer; numbers are Tuning fields)

Distances are measured from C (§1.4). "In front" means the flyer is in the kitten's front half-space: dot(facing, to flyer) > -0.2.

| State | Enters when | What you see and hear |
|---|---|---|
| **Asleep** | Flyer beyond `kitten_wake` **80 u** | Curled in a ginger (grey, calico) loaf on the sill, tail wrapped round, breathing (scale y ±3% at 0.4 Hz), an occasional ear flick |
| **Waking** (1.2 s) | Flyer in front within 80 u | Head up, a big pink **yawn** (mouth oval 0 → 1 → 0 over 0.8 s), a stretch (front paws forward, rump up), then it sits |
| **Idle** (sitting) | Awake, flyer beyond 45 u | Tail-tip sway ±25° at 0.4 Hz. Every 2.5-5 s a blink (eyes scale y 1 → 0.1 → 1 in 0.15 s). Every 3-6 s one ear twitches 20° for 0.2 s. Every 6-9 s either a face wash (paw to face, 2 strokes, 1.6 s) or a pat at the yarn (0.8 s, the yarn rolls a little). An occasional head tilt ±12°. All intervals come from the home's seeded RNG. |
| **Watching** | Flyer in front within `kitten_notice` **45 u** | Head tracks you (yaw ±75°, pitch ±45°, smoothed 0.15 s); eyes widen (×1.25), pupils fill them; tail up in a question-mark hook; ears forward; one **"mrrp?"** trill. **The first kitten of a session** adds the hint "A kitten! Don't fly too close" (2.5 s). |
| **Ready** (the wiggle) | Watching, flyer within `kitten_ready` **18 u** and closing, or within 9 u | Chest low (pitched 25° down, body 0.3 lower), front paws forward on the sill, rump up, **the wiggle**: the rump swings ±8° about the vertical at 6 Hz (ramping in over 0.2 s), with a 0.04 bob; tail low with its tip flicking; a tiny squeak once |
| **Lunge** | Ready for ≥ `kitten_wiggle_min` **0.6 s**, flyer within `kitten_lunge_trigger` **9 u**, and either it has stopped getting closer (closest approach) or it is within 4.6 u | Chest stretches toward you (×1.8 along its length), front paws spread wide, mouth open, ears back 10°, tail straight out behind; a **"mew!"**. The **back paws stay on the sill**. |
| **Miss** | Lunge over with no catch | It springs back, overbalances and **flops on its back** in the window (0.25 s), paws batting the air twice; rolls up (0.3 s); sits and **licks a paw** with great dignity (1.5 s). Then idle. It re-arms after `kitten_rearm` **3.0 s**. |
| **Caught** | Catch test passes (§1.4) | §1.6 |

**Timing at the worst case** (T 3.5, ground speed about 9.5 u/s on the line):

- wake at 80 u: 8.4 s before you pass;
- watch at 45 u: 4.7 s before;
- wiggle at 18 u: 1.9 s before.

The kitten itself is in view 60+ u out (§3.1 of the Endless plan), and its barn from 200 u.

**Readability on the cover screen** (11.3 px per degree):

| Distance | Kitten's head (1.3 u) | Kitten sitting (2.45 u) |
|---|---|---|
| 80 u | 11 px | 20 px |
| 45 u | 19 px | 35 px |
| 18 u | 47 px | 88 px |

Waking, yawning and head-tracking are motion, and motion is what catches the eye at 80 u.

### 1.4 Reach and the catch: the fairness rule

- **C** (the pounce centre) = the sill's middle + 0.5 along the facing + 1.2 up: the kitten's chest.
- **Lunge timing:** out 0.15 s (`kitten_lunge_out`), hold 0.15 s, back 0.3 s.
- **The paw target:** the flyer's position 0.15 s ahead, clamped to:
  - at most `kitten_paw_reach` **3.0 u** from C;
  - in front of the wall: dot(facing, target - C) ≥ 0.1;
  - no lower than the sill - 0.5.
- The paw point eases from C to the target over the 0.15 s out.
- **Caught** if, at any physics tick from the lunge's start to the end of its hold, the flyer's centre is within `kitten_catch_radius` **1.0 u** of the paw point.

**Consequences, which is what makes it fair:**

1. **Nothing beyond 3.0 + 1.0 = 4.0 u from C can ever be caught.** That distance is the kitten's **reach**. It is the same at every difficulty, so it can be learned.
2. **A flyer passing within about 3.5 u of C is caught** almost every time the kitten is ready. A test checks 99% of random straight passes.
3. **No lunge without at least 0.6 s of visible wiggle,** and none at a flyer behind the wall's plane or one it never saw ("watching" first). A kitten that didn't see you can't catch you.
4. **Line rule:** every ideal line keeps ≥ reach + lerp(2.5, 1.5), which is **6.5 → 5.5 u**, from C.
5. **Star rule:** every star keeps ≥ reach + pickup radius + 0.1 from C:
   - 5.5 for a small star;
   - 5.6 for a big one.

   So **you can never be caught while taking a star**, even from its kitten side (§4.2 rule 5 of the Endless plan: a risk, never a trap). The danger is drifting closer between stars.
6. **Lunge trigger 9 u > line distance**, so every pass on a kitten's line draws a lunge that misses by 1.5-2.5 u. You see the reach before it ever costs you.

**Example (Farmyard at d 1).**

- The closest star is 5.6 u from C (§3.3).
- A pilot sweeping through it 1.4 u off-centre toward the kitten is 4.2 from C: the lunge's paw stops at 3.0, which leaves 1.2. Missed, by a whisker.
- A pilot 1 u further in is caught. That is the hazard working as intended: earned, visible, fair.

### 1.5 The balloon's string

During a lunge, if any point of `string_points` comes within 1.0 of the paw point and the balloon itself does not, the kitten **bats the string**:

- a snag (`snag_speed_keep` 0.75), the flutter sound, and the string's points kicked 0.5 u away from the paw;
- the kitten plays the miss animation;
- a snag breaks the arc you are on, as every snag does.

Kittens batting strings is the most kitten thing there is. Since it's a snag it never ends a run (decision 3's spirit). The plane has no string.

### 1.6 Caught: what happens

1. **The flight ends.** It counts as a crash for everything that follows (ending, stars banked, step 6's soap bubble and second wind), but:
   - **no crumple and no pop**;
   - no `crash_shake`.
   - This needs a small Flyer method (for example `caught(holder: Node3D)`) that ends the model without `_crumple()` and lets the kitten carry the flyer's visual.
2. **The hug** (1.2 s):
   - The paws close and the kitten draws the flyer back to its chest (0.35 s ease).
   - It sits holding it:
     - the balloon squashed a little (scale 1.1 wide, 0.9 tall) between its paws, its string dangling;
     - the plane held under its chin like a toy.
   - Head rubs (head roll ±10° at 1.5 Hz).
   - **Eyes squeezed into happy arcs** (eyelids at 15%, curved up).
   - Tail swishes proudly; a **purr** plays.
   - **Three pink hearts** (`f4b0bc`; two spheres and a cone each, opaque) rise 1.5 u and shrink to nothing over 1.2 s.
3. **Camera:**
   - It stops following and holds its position;
   - it turns to look at the kitten over 0.4 s;
   - FOV -6° over 0.6 s, a gentle "aww" push-in;
   - no shake.
4. **Sound:**
   - a happy "mew" at the catch, then the purr (1.5 s, loop once);
   - the wind bed fades out over 0.5 s.
5. **Card** after `endless_card_delay_caught` **0.9 s** (longer than a crash's 0.45, so the hug shows).
   - **Title:** "Caught by Pip!", then the usual where: **"Caught by Pip in the Farmyard"**, "Caught by Smudge on the Long Ridge".
   - **Log:** `ended: Caught by Pip in the Farmyard (caught by the kitten, 3.6 u from it) at 212 m, 41 stars`.
   - Optional (looks only): a small drawn kitten face (the coat's colours) beside the title.
6. **Retry budget:** card at 0.9 s, tap at +0.5, flying 0.3 s later, for **1.7 s**. That is under the 2.0 s mark (Endless plan §1.4).

### 1.7 Missed: the reward

When a lunge ends with no catch and the flyer was within the trigger (9 u):

- the whoosh (`whoosh_volume_db`), `swell(4.0, 0.5)`, `camera.kick_fov(arch_pass_fov_kick)` (3°);
- a pop-up **"Missed me!"** (cream, 0.8 s);
  - It is skipped if an arc's pop-up showed within the last 0.5 s.
  - It is also skipped on a string bat.
- the log note `kitten lunged: missed by 1.8 u (Pip)`.

This is the close call that makes the kitten fun rather than a wall. The "Cat's whiskers!" arc (§3) pays for flying it well.

### 1.8 Sounds (`tools/gen_sounds.py`)

| File | Recipe | Peak |
|---|---|---|
| `mrrp.wav` | 0.22 s. Sine sweeping 420 → 560 Hz, amplitude-modulated at 28 Hz (depth 0.7), harmonics 0.4× at 2f and 0.15× at 3f; 10 ms attack, 60 ms release | -12 dBFS |
| `mew.wav` | 0.35 s. Fundamental gliding 650 → 900 Hz (0.1 s) → 720 Hz, vibrato 6 Hz ±15 Hz, harmonics 0.5× at 2f and 0.25× at 3f, plus 0.3× of a 1.2-2.4 kHz band of noise for breath | -10 dBFS |
| `squeak.wav` | 0.12 s. Sine 1,200 → 1,500 Hz | -18 dBFS |
| `purr.wav` | 1.5 s, loopable. Noise band-passed 60-250 Hz, amplitude-modulated at 24 Hz (depth 0.85), with a 0.6 Hz breath swell | -16 dBFS |

- **Volume** = `kitten_db` (-6) - 12 dB × (distance / 45). The purr and the catch mew are always at full volume.
- All 2D, like today's sounds.

### 1.9 Logic, determinism and performance

**The logic** is a pure class (for example `Kitten`) stepped in `_physics_process` with the flyer's position, velocity and string points.

- Its state lives in piece-local coordinates, so a recentre moves it with its piece.
- Drawing and animation run in `_process` with physics interpolation off, like `PropMotion`.
- The catch test is in the physics tick, so the same flight always gives the same outcome.

**Seeded per home from hash(seed, tile, slot):**

- coat (except Pip at the Farmyard);
- idle intervals;
- asleep or already sitting when first seen (70 / 30).

There is no other randomness.

**Logs (`note`):**

- `kitten Pip watching (44 u)`
- `kitten ready (17 u)`
- `kitten lunged: missed by 1.8 u`
- `kitten batted the string`
- `caught by Pip (3.6 u)`

**Cost:**

- about 700 triangles and 6 draw calls for the one kitten in range;
- logic only within 150 u;
- a kitten beyond 150 u is a hidden node with no `_process`.

---

## 2. Homes in the countryside (the owner's "A")

### 2.1 What stands there

**Homesteads** stand on the valley's side slopes, a farmyard's width from the line: scenery that makes the country feel lived in, and where kittens sometimes sit.

| Type | Footprint (x × z) | Walls / ridge | Details | Kitten window |
|---|---|---|---|---|
| **Cottage** | 7 × 9 | 4 / 7 | One storey and an attic. Chimney to 9 at one gable. Rose or slate roof; walls cream `f2e3d5`, rose `f1d4cc` or butter `f4dc9b` | The attic gable window, sill at 4.2 |
| **Farmhouse** | 9 × 12 | 6.5 / 10 | Two storeys, two chimneys, a porch, a painted garden with a picket fence (looks) | An upstairs window, sill at 4.0 |
| **Red barn** | 10 × 16 | 6 / 10.5 (gambrel) | Big doors with white cross-braces; red `c1675a` | The hayloft door in the gable, sill at 5.5 |
| **Stone barn** | 9 × 14 | 5.5 / 9 | Cream stone `e9d7b6`, slate roof `5f5b70`, a cart door | None |

- **Meshes:** 2 palettes per type, so 8 meshes, each with a shared collision shape. They are built once at scene load, in pump steps of ≤ 4 ms on the PC.
- **Footprints on slopes:** a stone plinth down to the lowest corner, so a house never floats.
- **Optional:** chimney smoke on homes within 150 u, 8 puffs, looks only.

### 2.2 Where: home slots

Each ordinary piece's kit lists 0-2 **home slots**: {at (x, z), yaw (front facing the valley's middle, turned 30° up-valley so a kitten window is seen 3/4 on from the approach), size S or L}.

**Slot rules.** The kit build checks every slot and drops any that fails; a test re-checks them all.

- |x| 34-56, where the side is ≤ 9 high.
- Not in the first 20 u or the last 12 u of the piece.
- ≥ **12 u** laterally from every ideal-line point, including high lines.
- ≥ 8 u from any lift zone's edge. The homes are lower than any zone's top - 6, so the downwind clearance rule (Endless plan §2.3) holds.
- ≥ 4 u from any star; ≥ 6 u from other props.
- Tree spots keep 10 u from every slot, whether or not a home stands there. An empty slot is a meadow.
- **No slots** in:
  - the Hamlet (already a village);
  - forks (their walls);
  - the Rim;
  - the Ridge's left side;
  - the Farmyard (it has its own buildings).

### 2.3 The seeded choice

`EndlessHomes.plan(seed, placement)` is a pure, static function: a local `RandomNumberGenerator` seeded with hash([seed, tile, "homes"]). Per slot:

| Draw | Value |
|---|---|
| A home stands | `homes_chance` **0.25** (about one home every 4 tiles; "occasionally") |
| Type | By slot size; palette 50/50 |
| A kitten in it | `home_kitten_chance` **0.3**, only if the type has a kitten window, metres ≥ 40, and ≥ `kitten_gap_tiles` **5** tiles since the last kitten |
| Coat | Pip / Smudge / Bramble, equal |

- `last_kitten_tile` is kept by the world and fed through in placement order. Placement order depends only on the seed, so the plan is the same whatever is flown.
- The Farmyard and the fixed homes (§2.4) go through the same counter.

**Expected per 25 tiles** (a skilled 5 minutes):

- about 6 homesteads;
- about 2 of them with kittens;
- plus 1-2 Farmyards and Windmills;
- so **3-5 kittens a run, 1-2 of them on the line.**

**Homestead kittens are ≥ 11 u from any line** (slot rule 12 u, less C's offset). They watch, chirp and track you; only a wanderer is ever lunged at. They introduce the kittens before the Farmyard asks anything of you.

### 2.4 Fixed homes in existing pieces (forks-plan §12's candidates)

| Where | Home | Kitten | Why it's safe |
|---|---|---|---|
| F2 Railway | The **station house** at (side × 40, -213): a pink-shuttered window on its platform side, sill at 2.8 | 50%: **the station cat** | The steam circle's nearest edge (x side × 30) starts at y ≥ 9; C is about 8 u away. Scenic. |
| P13 Warm Down | A new **hayrick cottage** (cottage type) at (-26, -150), facing the hayrick | 40% | 25+ u from the hayrick thermal's centre and the circle |
| P19 Windmill (4b) | **The miller's cottage** | 60%, on the line (§5.5) | It's that piece's hazard |
| F1 kiln | (none) | | The gorge floor is too tight for a window near the line, and on the rim it would be scenery 20 u up: not worth it |

---

## 3. P20 Farmyard (the kitten's piece; 1 tile, from 80 m)

### 3.1 Summary

| | |
|---|---|
| Verbs | around (a hazard past it), lift |
| Table | tiles 1, lift yes, rest no, min_m **80**, need **(12, 11)**, add INF, cap **(21, 19.5)**, `hazard: true`, `kitten: true` |
| WHERE / NAMES | "in the Farmyard" / "Farmyard" |
| Stars | "Cat's whiskers!" 7 (a big star at the closest point from layout d 0.5) + rickyard spiral 6 |
| Why fun | You see Pip's face in the hayloft door from far off, watching you come. The star line swings past the barn's end, just outside her reach. She wiggles and lunges, misses by a whisker, and flops over. You whoosh past into the rickyard's warm air. |

### 3.2 Layout

| Thing | Where and what |
|---|---|
| Ground | Standard. A straw-gold yard (`e9d29a`) painted round the barn's front (x 8-34, z -40..-50). A duck pond (`a9cfe0`, r 5) at (-8, -20) with 3 white ducks (looks). |
| **The barn** (solid) | The red-barn style, **across the valley's right half**: x 14..34, z -50..-62, walls 8, gambrel roof to 13, on a plinth. Big cart doors (closed) in its +z wall at x 24-30. |
| **Hayloft door** | In the +z (up-valley) wall near the left end: x 15..18, sill y 5.0, top 8.5, with a little gabled hay-hood above it and a hoist beam. The pink doors are swung open. |
| **Pip** | Sits on the sill at (16.5, 5.0, -49.6), facing +z turned 20° toward -x: facing (-0.34, 0, 0.94). **C = (16.2, 6.2, -49.6).** Always home (always Pip). |
| Farmhouse (solid) | Farmhouse type at (-22, -40), front toward the yard (+x). Closed sage shutters, chimneys with looks-only smoke. |
| Rickyard | 3 round hay ricks (solid, r 2.2, 3.0 + a 1.2 thatch cone) at (-20, -74), (-24, -82), (-19, -90) |
| **Rickyard thermal** | Centre (-4, -80), R lerp(11, 10), strength lerp(0.85, 0.75), top lerp(25, 23), WARM_AIR, drifts, a cloud at top + 4, 3 birds |
| Scenery | A gate and a field of sheep on the left slope; no trees within 10 u of the barn |

**Checks:**

- **Join buffers:** the farmhouse (z -34..-46), barn (-50..-62) and ricks (≤ 4.2 tall) keep the first 30 u and last 12 u clear above 6 within |x| ≤ 28.
- **Thermal clearance:** the ricks are 4.2 tall, under top - 6. The barn is upwind of the thermal, so the drift carries it away.
- **The right side:** past the barn (x 34-40, ground 0.6-2.3) a pilot can slip round the far end. No stars there; it's fine.

### 3.3 Stars and line

**"Cat's whiskers!"** (bonus title; 7 stars). The first three fit to the entry (`from_entry` 3, never above their laid height). Stars 4-7 are fixed: they must keep their distance from C.

| # | d 0 | d 1 | Distance to C (d 0 / d 1) |
|---|---|---|---|
| 1 | (0, 12.5, -26) | same | 27 |
| 2 | (3, 11.6, -32) | same | 22 |
| 3 | (6, 10.6, -38) | (6.3, 10.6, -38) | 16 |
| 4 | (8.6, 9.6, -44) | (9.3, 9.6, -44) | 10.0 / 9.4 |
| 5 (big from layout d 0.5) | **(10.0, 8.7, -50)** | **(11.2, 8.7, -50)** | **6.7 / 5.6** |
| 6 | (9.8, 8.2, -56) | (10.6, 8.2, -56) | 9.2 / 8.7 |
| 7 | (7.8, 8.0, -62) | (8.4, 8.0, -62) | 15.1 / 14.7 |

- **Spacing** 6.0-6.6 u.
- **Turn:** about 25° of heading change, spread over 18 u, so r ≥ 8. Descent 12.5 → 8.0 over 36 u, which is 1 : 8 (gentler than a half dive).
- **The barn's left wall** (x 14) is 4.0 (d 0) / 2.8 (d 1) from star 5. The beside rule needs 4.0 / 2.5.
- **Star rule (§1.4 rule 5):** star 5 is ≥ 5.6 from C everywhere. The big star's pickup radius is 1.5, so a flyer taking it is at least 4.1 from C: safe.
- **Line rule (§1.4 rule 4):** the line through the stars is 6.7 / 5.6 from C at its closest. That meets 6.5 / 5.5.

**Rickyard spiral:** 6 stars, `_spiral` start y 9.

**Ideal line:**

1. (0, h, 0)
2. Whiskers 1-7
3. (2, 7.6, -68)
4. near edge (0, 7.4, -71)
5. circle right at r 6 to top - 2
6. (2, ·, -96)

**Heights (estimate):**

- **need (12, 11):** about 75 u of path to the near edge at 12.2 : 1 (T 1.5) costs 6.1, leaving ≥ 6 at d 0. At d 1 (T 3, about 14.6 : 1), -5.1 leaves ≥ 4 (the rule's minimum) from 11. The tightest spot is arriving at the rickyard (about 7 at d 0): calibrate first.
- **out (21, 19.5):** leave the climb at 23 / 21, then about 20 u of glide.
- **Entering high (≥ 21):** stars 1-3 slide down for anyone entering lower than they were laid (`fit_to_entry`, never higher). From 24, reaching star 4 is 14.4 down over 44 u (1 : 3.1), a firm dive. Anyone higher just passes over the barn: C is then ≥ 10 u below them. Pip tracks them overhead and doesn't lunge (9 u trigger). No high line is needed.

### 3.4 Cadence (skilled, T 1.5, about 7.5 u/s)

| t | Event |
|---|---|
| -3 s | Pip in view from the piece before (80 u): she wakes and yawns |
| 0.5 s | "mrrp?": she watches you (45 u) |
| 3.5 s | Whiskers 1 |
| 5.5 s | She wiggles (18 u) |
| 6.7 s | Whiskers 5 (the big star); **she lunges and misses**: whoosh, "Missed me!" |
| 7.5 s | She flops behind you |
| 8.3 s | Whiskers 7, "Cat's whiskers! +5" |
| 9.5 s | Into the rickyard's warm air, spiral |
| 10-16 s | Climb, glide out |

The longest gap is about 3 s.

---

## 4. The lee rotor on P13 Warm Down (4a)

Behind the **high crest only, both sides of the saddle**, so the saddle's lee stays the safe way down (forks-plan §5):

| Zone | Box | Strength |
|---|---|---|
| Rotor west | x -28..-2, y 0..12, z -88..-118 | sink, peak -1.0 u/s at layout d 0.75, -1.2 at d 1 |
| Rotor east | x 20..34, y 0..12, z -88..-118 | the same |

- **Only in kits at layout d ≥ 0.75**, which is from about 625 m (layout d steps 0.25; the plan's "d 0.6" rounds down to 0.5).
- **Visible, always:**
  - 40 leaves per rotor tumbling in a rolling loop: down the lee and back up toward the crest, rotating about x, period 3 s;
  - sink ticks (the existing ones);
  - a darker, wind-flattened strip of grass painted on each high lee.
- **Cost:** crossing the high crest at 16-18 and gliding down either lee takes about 3 s in it, about -3.3 u more than the saddle. That still reaches the hayrick (Endless plan §11's hazard mark: never more than the margin).
- **Line, stars and table:** unchanged; the swoop at x 5.5-8 is ≥ 7 u from the west box. At d ≥ 0.75 the saddle crossing is the only clean line, which is the point.

---

## 5. Step 4b: weather and wires

### 5.1 The viaduct train (on every P6, from 75 m)

**The train:**

- an engine (green `4f6b5a`, like F2's) and 2 cream coaches with red waist bands;
- 16 u long, 2.6 wide, roof 3.2 over the deck, so the roof is at 25.2 and the chimney top at 26.4;
- solid, as a moving body (AnimatableBody3D); rounded front and back.

**The track:**

- the rails are drawn on P6's deck (forks-plan §3.2);
- tunnel mouths are drawn where the deck meets each hillside (x ±66).

**Its run:**

- 6 u/s, left to right, once per pass: out of the west tunnel, over, into the east tunnel;
- 20 steam puffs from the chimney (particles);
- a whistle 3 s before it reaches x 0;
- a rumble while it is within 40 u of the flyer.

**Timing, from the flyer (deterministic, no RNG).** At the tick the flyer is 60 u from the viaduct's near face (z -53):

| The flyer's local y then | Timing | Effect |
|---|---|---|
| **< 28.2** (it can't make the deck: 23.2 + 60 / 12) | The train's front reaches x 0 when the flyer is 1.0 s from the face | **It is right overhead as you dive through the middle arch**: a dark mass rumbling over the big star, steam, a 0.03 shake while it is within 12 u. Fear, then the arch, then relief. |
| **≥ 28.2** (a deck crosser) | The train's tail clears x +6 when the flyer is 3.0 s from the face | You watch it pass ahead; the deck is clear well before you reach it |

**Fairness:**

- The train starts its run ≥ 7 s before it reaches x 0. It is in plain view the whole way: its 3.2 u height against the deck is 15 px at 100 u.
- It is never on the deck's middle within 3 s of a flyer above the deck line.
- The deck stars stay at 25.5 (an alt line). They are only taken when the train has gone.
- A flyer circling on the previous piece just meets an empty viaduct.

**Not built: the plan's moving steam plume.** Its lift moving sideways at 6 u/s can't be flown on purpose. The puffs are looks only.

**Seed purity:** the timing depends only on the flight (as the spiral does). A test checks the same flight gives the same train.

### 5.2 P14 Rain Shower (1 tile, from 400 m; hazard, around, then sun)

| Thing | Spec |
|---|---|
| Cloud | Dark puffs `8d93a6`, base 24, R 14, centred (-8, -48) |
| Sink | Cylinder R 14 at (-8, -48), floor to 24, peak -1.5 (lerp(-1.4, -1.6)); sink ticks |
| Cues | 60 grey rain streaks falling at 8 u/s (particles, only within 150 u); a soft hiss within 40 u (`rain.wav`: noise high-passed at 2 kHz, -20 dBFS, loop); the ground under it painted darker, wet `7f9a7a` |
| Clear air | x 8..28 |
| **Sun after rain** (plan change) | A thermal steaming off the wet, sunlit field at (12, -84): R lerp(10.5, 10), strength lerp(0.8, 0.75), top lerp(24, 22), drifts, cloud, birds. Turns a pure loss into fear then relief. |
| Stars | "Round the shower": 8 curving round its right side, from (0, h-1, -14) to (14, ·, -60), ≥ 4 u outside the sink's radius. Then a 6-star spiral up the sun thermal. |
| Table | lift yes (now), rest no, min_m 400, need (12, 12), cap (19, 17.5), `hazard: true` |
| Mark | Straight through the core costs 4-7 u more than going round (Endless plan §11) |

### 5.3 P18 Pylons (1 tile, from 400 m; under, between or over)

As the Endless plan §7.3, with these settled:

- **Towers:**
  - 3 lattice towers, 26 tall, at x -40, 0 and 40, z -50;
  - drawn as a tapered lattice (4 wide at the base, 1.2 at the top);
  - they **collide as their outer hull at 0.9** (as round things do), plus a solid 1.5 × 1.5 core.
- **Wires** (snags, `kit.snags` capsules, r 0.1):
  - three spans sagging to y 12 / 16 / 20 at the middle of each span;
  - red-and-white 1.2 u marker balls every 8 u on the top wire.
- **Stars:**
  - "Under the wires": 5 at y 8;
  - "Between the wires" (experts): 5 at y 14, 2.0 from each wire;
  - a big star at (6, 14, -50) in the bay beside the middle tower, 2.0 from it.
- **Lift:** none; a weak street before it (z -8..-40, strength 0.3) sets up the height.
- **Table:** lift no, rest no, min_m 400, need (12, 12), add -7.
- The towers are in view from 200 u. Wires are 4 px at 40 u; the markers 19 px.

### 5.4 P15 Windy Gap (1 tile, from 550 m; hazard, through)

- **The gap:** two chalk buttresses (x ±12..±30, 30 tall, rounded noses, solid) narrow the valley to 24 u at z -40..-56.
- **The gust:** `air_drift.x` -2.5 over z -42..-54, ramping in and out over 3 u. It uses the same drift as the fork's split breeze, plus -0.5 sink.
- **Cues:**
  - 80 leaves streaming -X through the gap;
  - pennant flags on both buttresses, standing out to -X;
  - a gust whoosh and `swell(3, 0.6)` on entry.
- **The line** runs at x +3 to allow for the drift; 5 stars there.
- **Table:** lift no, min_m 550, need (10, 10), add -6, `hazard: true`.
- **Mark:** uncorrected drift ≤ 6 u, never a touch.

### 5.5 P19 Windmill (1 tile, from 450 m; timed through, plus the miller's kitten)

**The mill:**

- a post mill on a knoll at (20, -50), hub at y 14;
- 4 sails, radius 7, turning at 0.5 rad/s in the plane facing up-valley;
- the gap between sails at r 3.5 is 3.9 u wide and comes round every 3.1 s;
- the sails snag (capsules); the buck (body) and post are solid.

**The sails' phase** = hash(seed, tile) + 0.5 × run time, both deterministic.

**The big star:** in the sail disc at r 3.5, optional and timed.

**The miller's cottage** (cottage type) at (-10, -72), with a chimney plume at its far gable (-10, -77): R lerp(4.5, 4.0), base 9, top 20, strength lerp(1.2, 1.1). This is the recovery.

**The miller's kitten** (60%, coat seeded):

- in the cottage's up-valley gable window, facing +z turned 25° toward +x;
- the approach to the plume swings past it with C at lerp(6.5, 5.5);
- a 4-star "Cat's whiskers!" arc on that approach, under §1.4's rules.

**Stars:**

- "Round the mill": 5 stars past the mill at 10+ u from the sails' tips;
- the timed big star;
- Whiskers 4;
- 4 rising through the plume.

**Table:** lift yes, min_m 450, need (10, 10), cap (15, 14), `kitten: true` (when the kitten is home, it counts for kitten spacing).

---

## 6. Step 4c: wood, water and balloons

### 6.1 F3 Wood or Water (3-tile fork, from 600 m)

It reuses the fork frame, commit, stars and log rules (forks-plan §1). **Sides:** the Wood (low road) **left**, the Water (high road) **right**.

**Low road: the Wood** (this is P16 Pine Wood).

- Pines 10-14 tall, every 5 u, fill the left road from z -90 to -184.
  - Crowns r 2.0, colliding at 0.8; trunks as drawn.
  - One mesh, about 150 trees, about 6k triangles.
- **The ride:** a straight forest ride along the road's axis.
  - Clear for |u| ≤ lerp(5, 4) between crown edges, so 10 → 8 wide.
  - The line runs down the middle at y lerp(6, 5.5).
- **Air:**
  - a warm-layer box along the ride under 8 (WARM_LAYER), as the gorge breeze;
  - canopy sink -0.3 over the trees outside the ride (y 10..20).
- **The sawmill clearing** at the road's end (z -184), with a sawdust burner plume (R 4.5, peak 6.5, y 3-21) to climb out.
- **Merge:** the sawmill yard thermal (as F1's quarry: R 11, top 24).
- **Stars:**
  - signpost 3;
  - "Into the wood" 6 (diving to the ride's mouth);
  - **"Down the ride"** 10, with a big star at a woodcutter's clearing (z -136, a 12 u glade);
  - burner 4;
  - yard spiral 6.
  - About 29 + big, so **about 64 ★ if all taken**.
- **Sight line:** the ride's mouth is framed by dark pines from 80 u (the gorge-dive rule).

**High road: the Water.**

- **The boathouse slip thermal** at the mouth (30, -60): R 12, strength 0.9, top 28. This is the promised big safe thermal.
- **A reservoir** filling the road from z -100 to -190: water solid (splashdown "on the Water"), lake sink lerp(0.3, 0.45).
- A dinghy sailing round (the Mere's mover).
- **Sunny far bank:** ridge lift, box along the outer shore, peak 2.0, `gull_lift`.
- Merge: the knoll thermal (as F1's).
- **Stars:** signpost 3 + "Over the water" 6, so **about 19 ★**.

**Table:** need (12, 12); out = the Wood's (estimate 16.5 / 16); `out_high` (22, 22); `fork: true`; WHERE "in the Wood" / "over the Water". **Calibrate the Water's exit: it must be ≥ the Wood's + 4.**

### 6.2 P17 Balloon Fair (1 tile, from 300 m; around, moving lift)

**Three hot-air balloons:**

- envelopes r 5, in pastel gores: coral, butter, lilac;
- wicker baskets 2 × 2 × 1.5 on 4 ropes (looks);
- at (−10, 12, -30), (8, 18, -55), (−4, 14, -80);
- each bobs ±1 u at 0.15 Hz (seeded phase).

**From wake** (flyer within 120 u) they drift with the wind at T, as thermals do. Your closing speed is then your airspeed, so you have time to read them.

**Collisions:**

- **Envelopes are soft:** a game-level sphere check (r 4.6) bounces you off with 80% speed, a soft "boing" and a wobble. **Never a crash.**
- **Baskets are solid** (a moving body), small, under the envelope.

**Burner lift:**

- a drifting cylinder above each envelope: R 3, peak 6, from 1 to 9 u over its top;
- the burner flame flickers (orange cone, looks) with a soft roar while you are within 10 u.

**Stars:** 3 arcing over each balloon, riding with it (zone stars).

**Table:** lift yes, min_m 300, need (12, 12), add 2, cap 24.

---

## 7. Generator rules

Added to `EndlessGenerator` (pure and seeded, as now). The new TABLE fields are `hazard` and `kitten`.

```
new ordinary pieces: farmyard (4a); rain, pylons, windy_gap, windmill (4b); balloon_fair (4c)
new fork: wood_water (4c), min_m 600, joins FORKS as F1/F2 do

_fair():
  ... existing rules ...
  if the last piece had hazard: drop pieces with hazard                    (HAZARD_GAP 1 at d >= 0.5)
  if d < 0.5 and either of the last 2 had hazard: drop pieces with hazard  (HAZARD_GAP 2 at d < 0.5)
  if a kitten piece is among the last KITTEN_GAP_PIECES (3) places: drop pieces with kitten
_way_on(): applies the same filters (they only remove options; the rescue street has neither flag)
```

**Flags:**

| Piece | hazard | kitten |
|---|---|---|
| farmyard | yes | yes |
| rain | yes | |
| windy_gap | yes | |
| windmill | | yes |
| pylons, balloon_fair, wood_water | | |

**Table rows (estimates; calibrate):**

| id | tiles | lift | rest | min_m | need d 0 / d 1 | add | cap d 0 / d 1 | step |
|---|---|---|---|---|---|---|---|---|
| farmyard | 1 | yes | no | 80 | 12 / 11 | INF | 21 / 19.5 | 4a |
| rain | 1 | yes | no | 400 | 12 / 12 | INF | 19 / 17.5 | 4b |
| pylons | 1 | no | no | 400 | 12 / 12 | -7 / -7 | INF | 4b |
| windy_gap | 1 | no | no | 550 | 10 / 10 | -6 / -6 | INF | 4b |
| windmill | 1 | yes | no | 450 | 10 / 10 | INF | 15 / 14 | 4b |
| balloon_fair | 1 | yes | no | 300 | 12 / 12 | 2 / 2 | 24 / 24 | 4c |
| wood_water | 3 | yes | no | 600 | 12 / 12 | INF | 16.5 / 16 (out_high 22 / 22) | 4c |

**Homes are not the generator's business.**

- `EndlessHomes.plan()` is a separate pure function with its own RNG per (seed, tile).
- **Adding it changes no piece sequence:** a test compares 1,000 seeds' sequences with homes on and off.
- **New pieces in the table do change today's daily sequences.** That is expected: "same app version" (hangar-plan §4.2).

**"First appears"** (Endless plan §6, updated):

| Distance | First appears |
|---|---|
| 0 m | homesteads |
| 40 m | homestead kittens |
| 75 m | the train (with the Viaduct) |
| 80 m | Farmyard |
| 300 m | Balloon Fair |
| 400 m | rain, pylons |
| 450 m | windmill |
| 550 m | windy gap |
| 600 m | Wood or Water |
| 625 m | lee rotor |

---

## 8. Star lines (new)

| Piece | Arc (title) | Stars | Big | ★ if all |
|---|---|---|---|---|
| Farmyard | Whiskers ("Cat's whiskers!") | 7 | 1 from layout d 0.5 (star 5) | 7 + 9 + 5 (+ 6 + 5 spiral) |
| Windmill | Round the mill; sail disc (timed big); Whiskers ("Cat's whiskers!"); plume | 5 + 4 + 4 | 1 | about 30 |
| Rain | "Round the shower!"; sun spiral | 8 + 6 | | 24 |
| Pylons | Under the wires; "Between the wires!" (expert) | 5 + 5 | 1 | about 30 |
| Windy Gap | "Through the gap!" | 5 | | 10 |
| Balloon Fair | "Over the balloons!" (3 × 3, one arc each) | 9 | | 24 |
| F3 Wood | signpost, into the wood, "Down the ride!", burner, yard spiral | 29 | 1 | about 64 |
| F3 Water | signpost, over the water | 9 | | about 19 |

**Rules unchanged** (Endless plan §4.2). Added:

- **Kitten rule** (§1.4 rule 5): no star within reach + pickup + 0.1 of any kitten's C.
- **Home rule:** no star within 4 u of a home.

---

## 9. Seed purity (hangar-plan §4.2)

**From (seed, tile) through local `RandomNumberGenerator`s:**

- homes, their types and palettes;
- which have kittens, and the coats;
- kitten idle intervals and asleep/awake;
- the windmill's phase;
- the balloons' bob phases.

**From the flight (deterministic; the same flight gives the same result):**

- the kitten's states, lunges and catches;
- the train's timing;
- the run-time clock driving the sails.

**Visual-only randomness is allowed:** rain streaks, leaves, steam puffs and hearts can never touch the flyer.

**Never:** global `randi()`, `randf()`, `randomize()` or `randi_range()`. The source guard (forks test 5) extends to the new files.

---

## 10. Test pilots, tools and logs

**`tools/endless_log.gd`:**

- `--piece=farmyard|rain|pylons|windy_gap|windmill|balloon_fair|wood_water`;
- `--homes=on|off`, and `--kittens=always` (every slot and chance kitten home, for stress runs);
- **per run:** kitten notes (§1.9), "kittens met: 4 (lunges 2, missed 2, caught 0, string 0)";
- **batch summary:**
  - caught-by-kitten endings per pilot;
  - closest approach to C per pass (median, minimum);
  - Whiskers arcs full;
  - train overhead offset (s) for divers;
  - rotor sink taken.

**`tools/endless_capture.gd --kitten`:** a **kitten sheet** for the design review before anything else in 4a is wired.

- Each coat in each state (asleep, yawn, idle, watching, wiggle, lunge, flop, paw-lick, hug with the balloon, hug with the plane).
- At 10 u, 45 u and 80 u.
- Plus the Farmyard from 80 u and 45 u on the line, at the cover screen's size.

**Autopilot and FirstTimer:** no new behaviour. The lines already keep out of reach.

- The chaser follows Whiskers stars, which is the real test of rule 5.
- The middle-flyer passes the Farmyard 16 u from Pip.

---

## 11. Tests to add (`tests/test_kitten.gd`, `tests/test_hazards.gd`)

**Kitten logic (pure, fast):**

1. **Straight passes, closest approach at:**
   - 10 u: no lunge;
   - 6.5 u and 4.5 u: lunge, miss, the "Missed me!" signal;
   - 3.8 u: caught.
2. **Property:** 10,000 random straight passes (speeds 4-14, heights, angles):
   - **0 catches with closest approach > 4.0**;
   - ≥ 99% caught below 3.5 when ready.
3. **No lunge:**
   - before 0.6 s of wiggle;
   - at a flyer behind the wall's plane;
   - at a flyer it never watched (arriving from behind).
   - It re-arms 3.0 s after a miss.
4. **The string:** balloon at 5 u, string within reach: a snag, not a catch; the plane at the same spot: a miss.
5. **Caught ends the run:**
   - the title "Caught by Pip in the Farmyard";
   - card delay 0.9;
   - no crumple or pop;
   - `crash_shake` not applied;
   - stars banked;
   - retry ≤ 2.0 s with a tap at +0.5.
6. **Recentre during a lunge:** the outcome is unchanged and the paw stays with its piece.

**Homes:**

7. `EndlessHomes.plan(seed, …)` is identical across calls, and differs between seeds:
   - kittens ≥ 5 tiles apart, including the Farmyard and fixed homes;
   - none before 40 m;
   - **the Farmyard is always Pip**.
8. **Every slot in every kit at d 0..1:**
   - ≥ 12 u from every line point (both lines);
   - ≥ 8 u from zone edges;
   - ≥ 4 u from stars;
   - no tree within 10 u;
   - out of the join margins.
9. Piece sequences are identical with homes on and off (1,000 seeds).

**Farmyard and kitten geometry:**

10. At layout d 0, 0.25 … 1:
    - every star ≥ reach + pickup + 0.1 from C;
    - the line ≥ lerp(6.5, 5.5) from C;
    - the line ≥ beside clearance from the barn;
    - the ground ≥ 6 / 4 under the line.
    - Same for the windmill's kitten.
11. **Sight line:** from 60 u back along the line, a ray to Pip's head hits nothing solid. The kitten draws at 80 u.

**Movers:**

12. **The train:**
    - scripted divers at T 1, 2, 3 pass under with the train's front within ±0.5 s of x 0;
    - a scripted deck-crosser (29 at 60 u) finds |x| < 6 clear from 3 s before the deck;
    - the same flight gives the same train twice.
13. **Windmill:** the sails' phase is the same for the same seed and flight; the sails snag, never crash.
14. **Balloon Fair:** an envelope hit is a bump at any speed and angle; the burner zone moves with its balloon.

**Hazards:**

15. **Lee rotor:** present only at layout d ≥ 0.75; ≥ 7 u from the swoop line; its leaves exist whenever its zone does.
16. **Rain:** a scripted pass through the core loses 4-7 u more than the round line (T 2).
17. **Windy Gap:** an uncorrected flyer centred drifts ≤ 6 u and never touches.

**Generator:**

18. 10,000 sequences of 40 placements:
    - all existing rules;
    - no two hazards in a row (no hazard within 2 at d < 0.5);
    - kitten pieces ≥ 3 placements apart;
    - new min_m respected;
    - F3 not before 600 m.

**Seed purity:**

19. Forks test 4 extended:
    - one daily seed flown low and high;
    - identical homes, kitten coats and home positions;
    - identical windmill phase and balloon phases.
    - Source guard over `homes.gd`, `kitten.gd` and the mover files.

**Kits and budget:**

20. New kits, home meshes and the kitten build in steps of ≤ 4 ms each on the PC.
21. **HowToFly:**
    - names every new piece;
    - names "Cat's whiskers!" and the other new bonus titles;
    - names Pip, Smudge and Bramble.

---

## 12. Calibration and marks

**Calibrate first, in this order:**

1. **Farmyard** (from need, 18 and 26; d 0 / 0.5 / 1, with each d's wind):
   - the arrival height at the rickyard (≥ 6 / 4);
   - out within ±1.5 of the table;
   - **closest approach to C on the skilled line 6.7 / 5.6 ±0.3**;
   - the barn-wall clearance at star 5 (≥ 4.0 / 2.5).
2. **Kitten timing**, all pilots, T 1-3.5:
   - the wiggle starts ≥ 1.2 s before the closest approach;
   - "watching" ≥ 4 s before.
3. **Lee rotor:** the high-crest crossing costs 3-4 u more than the saddle; no touchdowns.
4. **4b / 4c pieces:** need and out, as every piece; F3's Water ≥ Wood + 4.

**Marks:**

| Mark | Pass |
|---|---|
| Skilled ×20 (420 s) | 0 caught; Whiskers arcs full in ≥ 80% of passes; all existing step-1/2/3 marks still met |
| Shaky ×20 | ≤ 2 of 20 runs caught; Whiskers full ≥ 50% |
| Chaser and no-circle ×20 | ≤ 3 of 40 runs caught; every catch log shows a closest approach < 4.0 and a lunge after ≥ 0.6 s of wiggle |
| Hands-off and middle ×20 | 0 caught (they fly the middle) |
| Novice ×20 | Median 45-90 s still; ≤ 2 caught |
| Fair failure | Every kitten ending names the kitten and the distance; every kitten was "watching" ≥ 4 s before |
| Kittens a run | Skilled: 3-5 kittens met per 420 s run (median), 1-2 lunges |
| Train | Overhead within ±0.5 s for ≥ 90% of skilled dives; 0 train contacts for any pilot |
| Cadence | No gap over 5 s on the Farmyard, Rain, Pylons, Windmill or Balloon Fair (skilled) |
| Budget (PC) | ≤ 43 draw calls and ≤ 50k primitives in view: at the Farmyard with Pip lunging and a homestead in view; in the rain; at the Balloon Fair; at the split of F3. No frame over 16.7 ms while home meshes or kits build. |

---

## 13. Info text (`scripts/how_to_fly.gd`)

**Places → Endless, place by place:**

- **Replace the opening line** with: "New places turn up the further you fly: the Farmyard from about 80 m, the first fork at about 120 m, the Mere after 200 m, the Warm Down after 250 m, and the River or the Railway after 400 m." (4b and 4c extend it: "the Balloon Fair after 300 m, rain showers and pylons after 400 m, the windmill after 450 m, the Windy Gap after 550 m, and the Wood or the Water after 600 m".)
- **Add after Warm Down:** "Farmyard: a big red barn with its hayloft door open, and Pip the farm kitten sitting in it. Swing past the end of the barn along the stars for Cat's whiskers!, but not too close: Pip will try to catch you. Then climb the warm air over the rickyard."
- **Add after Farmyard:** "Homes: here and there a cottage, farmhouse or barn stands on the hillside. Open pink shutters mean a kitten is at home."

**Add a section after "Touching things": "Kittens".**

> Three kittens live in the country: Pip, Smudge and Bramble. They love balloons and paper planes. A kitten always stays in its window or hayloft door, behind open pink shutters. When it sees you coming it sits up and watches you. When it wiggles its bottom, it's about to pounce.
>
> A kitten can reach out about as far as a cottage is tall. Stay a little further off and it only swipes the air (you'll hear a whoosh: "Missed me!"). Fly within its reach and it catches you, and the run ends: "Caught by Pip!". If you're flying the balloon and it only bats your string, it just snags you.

**Touching things:** append "A hot-air balloon's envelope is soft: it bounces you off." (4c) and "Pylon wires and windmill sails snag, like kite rings." (4b)

**Downdrafts** (4a: the rotor; 4b: rain):

- "**Behind a hill:** late in a run, the air tumbles down behind the Warm Down's high tops. Falling leaves and ticks show it. Cross at the low saddle instead."
- "**Rain showers:** a dark cloud with rain falling from it. The air under it sinks hard. Go round, and catch the warm air off the sunny field beyond."

**Low warm air** (4c): append "Along the ride through the Wood the air holds you up low in the same way."

**Points and bonuses → Endless:** add "Cat's whiskers!" (4a), and "Round the shower!", "Between the wires!", "Through the gap!", "Over the balloons!" and "Down the ride!" (4b/4c) to the list of bonus names.

**Sounds:**

- add "A little trill or a mew: a kitten has seen you, or pounced. A purr: it caught you.";
- (4b) "A whistle and a rumble: the train on the viaduct. A soft hiss: rain ahead.";
- (4c) "A roar: a hot-air balloon's burner."

**Tips:**

- add "Watch the windows. Fly past a kitten at a few lengths and it can only swipe at the air.";
- (4b) "At the viaduct, a train may pass right over you as you dive through the arch. Keep going!"

---

## 14. Phone checklist (owner, Fold5)

**4a:**

1. **Pip, first sight** (the Farmyard, from about 80 m):
   - Did you see her before you needed to do anything?
   - **Is she cute?** Show someone who has never played. If anyone says "scary", say what made it so.
2. **The wiggle:** did you know a pounce was coming? Did a lunge that missed feel like a close shave you'd earned?
3. **Getting caught** (fly at her on purpose):
   - Did you understand at once why the run ended?
   - Is the hug charming, or a cheat?
   - Is "Caught by Pip!" the right words?
   - Is the 0.9 s before the card too long?
4. **The string** (the balloon): fly so only the string passes her. Does the bat feel fair and funny?
5. **Homes:**
   - Do the cottages and barns make the country feel lived in?
   - Too many, or too few (about one every 4 tiles)?
   - Did you spot kittens watching from the hillside?
   - Did the pink shutters mean anything to you after a few runs?
6. **How often** you meet kittens: too often, about right, or too rare?
7. **The lee rotor** (past 625 m): did you notice the leaves? Did the saddle feel like the right way over?
8. **Frame rate:** 120 fps with Pip in view and lunging, and with a homestead in view. Watch for a stall when a piece with a home spawns.

**4b:**

9. **The train:** did it come over as you dived under? The best moment so far, or distracting?
10. **The rain:** readable from far off? Did going round feel like a choice?
11. **The pylons:** can you see the wires in time (the marker balls)? Did a snag ever feel like a crash?
12. **The windmill's sails:** is threading them for the big star tempting or annoying?
13. **The Windy Gap:** did the push feel like wind, or like the controls going wrong?

**4c:**

14. **The Wood:** thrilling or claustrophobic? The Water: calm or dull?
15. **The balloons:** do they read as things to avoid (and ride over)? Is bouncing off one fun?
16. **Frame rate** in the Wood (150 pines) and in the rain.

---

## 15. Owner calls worth flagging

1. **Caught = the run ends, but the kitten hugs the balloon rather than popping it.** This is a crash in every rule (your "it's a crash"), shown gently. **Recommend the hug.** The alternative is today's pop or crumple, with the card "Popped by Pip!".
2. **A litter of three named kittens** (Pip, Smudge, Bramble), with Pip always at the Farmyard. **Recommend.** The alternative is one kitten, Pip, everywhere. Names are yours to change.
3. **The kitten never leaves its window, and its reach is the same at every difficulty** (4 u). Learnable and fair. Difficulty only brings the star line closer and the wind faster. **Recommend.**
4. **The balloon's string being batted is a snag, not a catch.** **Recommend:** it's the funniest bit, and it keeps the balloon (the default) from being punished for its string.
5. **How often:** about 3-5 kittens in a 5-minute run, most watching from homes and 1-2 next to the line. A tuning number (`home_kitten_chance`, the Farmyard's weight) if you want more or fewer.
6. **The train is timed by your flight:** it passes overhead as you dive under. The daily flight's country stays the same for everyone; only the train's moment depends on how you fly, as the spiral already does. **Recommend.**
7. **Step 4 in three parts, each to the phone:** 4a (kitten, homes, Farmyard, rotor), then 4b, then 4c. **Recommend.**
8. **The Pine Wood is built only as the Wood road of the third fork,** not also as its own piece. It saves a large piece for little gain. **Recommend.** It can be split out later.
9. **The Rain Shower gets a thermal after it** (sun on the wet field). The plan had none. Fear, then relief. **Recommend.**
10. **Step 6 (soap bubble):** a bubble should save you from a kitten too: the bubble pops, the kitten tumbles back startled with its ears flat (cute, not hurt), and you fly on. **Recommend;** noted for step 6.

---

## 16. Later ideas (not this step)

- **A kitten-face balloon** in the Hangar (hangar-plan §9), and **a kitten sticker** paper design.
- **Missions** (step 7): "Make Pip miss 3 times", "Meet all three kittens in one run", "Fly past the station cat".
- **A slow blink:** a kitten that slow-blinks (cat for "I like you") if you circle a thermal nearby for 5 s.
- **A rainbow** after the rain shower, standing in the far sky (looks only), with a star arc under it.
- **A kitten wave goodbye** on the card after a catch: a paw raised.
- **Home lights:** lit windows in the homes on an evening flight (the "Weather and light" idea).
- **A sheepdog** trotting the Farmyard's field (looks only).
