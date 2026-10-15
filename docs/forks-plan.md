# Forks plan (Endless step 3): forks and the low hill

Owner's order (2026-10-14): step 5 (Hangar and the daily flight) first, then this step, then step 4 (hazards and movers, plus the cottages, barns and kitten).

**This step adds:**

- **F1 Gorge or Down**, the first fork;
- **F2 River or Rail**, which meets the Viaduct;
- **P13 Warm Down**, the low hill;
- fork choices in the logs and the test pilots;
- the two follow-ups from fun review 6.

**Built on:**

- endless-plan §2.6 and §7.3;
- build notes (step 1, step 2);
- `generator.gd`, `endless_world.gd`, `pieces.gd` and `stars.gd` as they are today;
- hangar-plan §4.2 (seed purity).

Conventions are the Endless plan's:

- piece-local x is across the valley, y is above the floor, and z runs from 0 down to -96 per tile;
- d is difficulty; lerp(a, b) means a at d 0 and b at d 1;
- T is the tailwind.

All numbers are **estimates** until the lead's `--calibrate` has measured them. Section 9 lists what must be measured.

---

## 0. Decisions in one page

| Question | Decision |
|---|---|
| What is a fork in the world? | **One 3-tile piece** (288 u) whose kit holds **both roads side by side**, split by a wooded spine too tall to cross. The world stays one line of pieces. Streaming, recentring, `piece_at()`, kit builds and the bunting work as for the 2-tile Long Ridge. |
| Seed purity (daily) | **Free by construction.** Both roads are always built, from the fork's fixed kit (no RNG). The generator never learns which road was flown: its `h` uses need = the higher road's need and out = the lower road's out. The only new RNG draw is the gap to the next fork, taken when a fork is *placed*. A test flies one daily seed down the low road and again down the high road, and compares (§8). |
| How the roads read | Seen from the piece before: a **wooded spine** (38 u, plus trees to about 46) rising mid-valley. At the split: a **fingerpost** whose **gold arm** points to the low road and **sky-blue arm** to the high road, and **two 3-star signpost lines** diverging from z -14. The **high road always opens with a big thermal under a cloud** at its mouth. **The low road always shows its first obstacle** (bridges) framed in its mouth. |
| The promise | **Low road:** at least 2× the stars, low and tight flying, exits lower. **High road:** a big safe thermal first, few stars, exits at least 4 u higher. The same on every fork, so it is learnable. |
| When forks come | First fork due at **120 m**; then every **6-10 placements** (a seeded draw). A fork is placed only when fair. If a rest piece is due, the rest piece comes first. |
| Which forks | F1 from 120 m, F2 from 400 m. Never the same fork twice running if the other is fair. Step 4 adds Wood or Water to the same list. |
| F2 "merges at the Viaduct" | F2 is 3 tiles, and the generator **always places P6 Viaduct straight after it** (a forced follower, part of the same placement). The river runs on into P6's river. Low-roaders dive the arch. High-roaders arrive about 22 u and make the longest viaduct dive in the game. |
| P13 Warm Down | **2 tiles** (the plan said 1): climb the sun-trap thermal, cross the saddle (big star), swoop down the lee, catch the hayrick thermal. In one tile a low crossing exits too low (about 14) and a high one makes the hill scenery. Section 5 has the arithmetic. |
| Committing to a road | The game decides the road by **where you are once the spine is too tall to cross**, not by stars or input. The other road's arcs then become alt and dimmed, and are never counted as missed. |
| Fun review 6 follow-ups | (1) A two-line piece chooses its line at a **choice point** (6 u in and heading on, or 24 u in at the latest), not at the join. The test pilots **follow the game's choice**. (2) The Mere's across-arc holds x 0 for three stars, then turns at r ≥ 15. |

---

## 1. The fork frame (shared by every fork)

### 1.1 Ground

Fork-local z runs 0..-288: the **split tile** 0..-96, the **branch tile** -96..-192 and the **merge tile** -192..-288.

**Branch offset.** The two roads' centres sit at x = ±X(z):

- X(z) = 36 · smoothstep(12, 72, -z) · (1 - smoothstep(204, 264, -z))
- s = X / 36 runs 0..1.

| z | -12 | -30 | -42 | -60 | -72 … -204 | -224 | -234 | -244 | -264 |
|---|---|---|---|---|---|---|---|---|---|
| X | 0 | 7.8 | 18 | 32.3 | 36 | 26.7 | 18 | 9.3 | 0 |

**Each road's cross-section:**

- floor half-width F = lerp(28, 14, s);
- sides k · max(|u| - F, 0)², with k = lerp(0.016, 0.04, s) and u = x ∓ X;
- valley V = min(section(x + X), section(x - X)).

At s 1:

- the outer walls reach 85 u at |x| 96, and 30 u at |x| 77, so nothing leaves the tile;
- between the roads the ground humps to 19 at x 0.

**The spine.** S(x, z) = H(z) · (1 - smoothstep(6, 18, |x|)), where

- H(z) = 38 · smoothstep(36, 100, -z) · (1 - smoothstep(196, 236, -z));
- the nose's toe is at z -36; the crest is full (38) from -100 to -196; the tail is gone by -236.

| z | -36 | -50 | -60 | -70 | -80 | -90 | -100 … -196 | -206 | -216 | -226 | -236 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| H | 0 | 4.6 | 12 | 21 | 29.6 | 35.6 | 38 | 32 | 19 | 5.9 | 0 |

**Putting it together.**

- **Ground** = max(V, S) + rolls, then each road's own shaping (§2-3). The edges at z 0 and -288 are the standard section exactly, with rolls faded as usual.
- **On the 6 u grid:** the spine's centre (x 0) and each road's centre at full split (±36) sit on grid lines. So the gorge, the river cut and the spine come out as clean low-poly ramps. Specify their shapes in grid terms (§2-3), not as finer curves the grid can't draw.
- **Trees on the spine:** about 24 crowns (beech and pine mix, solid as usual) along x ±7 from z -96 to -200. They take the crest to about 46 and make it read as "wooded hill, not a ramp".

### 1.2 The nose: fair when you don't choose

- **Head-on along the crest,** the nose's steepest slope is 1.5 × 38 / 64 = 0.89, which is 42°.
- **A hands-off glide** (about 5° down) meets it at 47°. That is under `head_on_angle_deg` 50, so it is a **bump**, not a crash.
- **Off the crest line** the flanks also face sideways, so the hit is more glancing still.
- **A pilot who dives into the nose** (more than 8° down) can crash. That is fair: it is the biggest thing in the valley, in view for 20+ s.
- **Mark** (§8): 20 hands-off runs that reach a fork have **0 crashes at the nose**. A bump, then a touchdown, is acceptable. If crashes show up, lengthen the nose's rise from 64 u to 80.

### 1.3 Reading it from the air

**Spawn and visibility.** The fork spawns 5 tiles ahead, as every piece does.

**From the piece before (150-250 u out):**

- The spine's wooded crest (38-46) stands above anything else in the country (the viaduct deck is 23). Fog transmittance at 200 u is 0.61.
- The high road's cumulus (base about 32) sits to one side of the nose.
- The low road's smoke or bridges are framed by its mouth.

**At the entry (z 0):**

- **The fingerpost** (looks only, not solid) stands at (0, ground, -34), on the nose's toe:
  - a cream post 7 tall with two arms 4 u long, angled 35° forward to each side;
  - **gold arm** (`f4c84a`, three small cream star shapes) toward the low road;
  - **sky-blue arm** (`a9c8e8`, a white cloud puff) toward the high road.
  - At 60 u an arm is about 43 px.
- **Two signpost arcs** of 3 stars each, at (±4, ·, -14), (±8.5, ·, -20) and (±13, ·, -26).
  - They are fitted to the entry height (`from_entry` 3: entry - 1, never above 17).
  - 8 u apart at the first star, so taking one is already a lean toward that road.

**The same colour code on every fork:** gold is stars, blue is lift.

**Choose by z -40.** At -40 the roads are 2 × 16 apart and the nose is about to rise. A sidestep of 13-16 u takes about 3.5 s and 16-20 u of ground (§0 of the Endless plan). From the entry, that leaves 2+ s to decide after the first signpost star.

**The whole-line-visible rule (§3.1)** cannot hold across a spine. For forks it becomes: **each road's next arc and next obstacle are in plain view at least 60 u before you must act on them** (80 u for the gorge dive). The sight-line test checks this (§8).

### 1.4 Committing, stars and what the game says

**The commit rule.** A fork commits on the first tick when either:

- (local z ≤ -40 **and** H(z) ≥ flyer's local y + 2), that is, it can no longer cross; or
- local z ≤ -100 (the fallback).

The road is the side of the flyer's local x (the low road's side is given per fork). Before the commit the card says "at the fork". After it, it names the road.

**Arcs.**

- A fork's arcs carry `"road": "low" | "high"`. Shared arcs in the merge carry none.
- **Before the commit,** road arcs are normal (not alt). They **cannot close or be marked missed**: closing is deferred.
- **At the commit:**
  - the other road's arcs become **alt and dim**, and close silently (no "arc flown past", no missed count);
  - the chosen road's arcs are then checked as usual, so a star of yours flown past before the commit is missed at the commit.
- Stars you took on the other road's signpost before swinging across are kept (banked) and stop counting in the share.

**What the player sees and hears:**

- **The first fork of the session** (a static, like `looked_back`; no save field): the hint "Two ways: low road for stars, high road for height" (2.5 s), shown on entering the fork.
- **At the commit:**
  - a pop-up, **"Low road!"** in gold or **"High road!"** in cream (1.0 s);
  - a gentle wind swell (+2 dB over 0.6 s).
- **Card "where":** "in the Gorge", "on the High Down", "on the River", "on the Railway", or "at the fork" (before the commit; this includes the nose).

**Logs (`note`):**

- `fork Gorge or Down: low road (z -63, h 14.2)`
- `fork out: low road h 17.9`, at the fork's last tile.

**Run counters** `roads_low` and `roads_high` exist for step 7's missions. They are not saved yet.

**Effects.** Bridge passes register as `kit.arches` openings, so passing under at ≥ 7.5 u/s gives the whoosh, the +5 dB swell and the +3° FOV kick, as at the Viaduct. Entering the gorge (where its walls stand) at ≥ 7.5 u/s also gives the +3° kick.

**Camera:** no other change. In the gorge the chase camera (3.4 back, 1 up) has 6+ u to the walls. There are no thermals in the gorge, so nobody circles there.

### 1.5 The bunting in a fork

If your best distance falls between fork z -30 and -250, hang **one short bunting across each road** at that z:

- poles at ±X(z) ± 12, with the same sag;
- a single standard bunting where X < 14.

The chime goes by distance, as now.

---

## 2. F1 Gorge or Down (3 tiles, from 120 m)

**Sides:** low road (the Gorge) **left**, at x -36; high road (the High Down) **right**, at x +36.

**Generator values:** need (12, 12); out = the low road's (17.5, 16); the high road's out is (22, 20) for logs and tests.

### 2.1 Low road: the Gorge

**Ground** (left road, within z -84..-188; the walls fade in over -76..-92 and out over -180..-196 with factor g):

- floor at 0 for |u| ≤ 6 (grid);
- walls to 24 · g at |u| 12;
- a rounded rim at 26 · g at |u| 18;
- the inner rim joins the spine.

The floor is painted pale sand, with a few boulders on the walls (looks).

**The ideal line at the gorge axis** is 4.5 u up and 7 u from the walls (2.5 u of floor, then the ramp).

**Footbridges** (solid) at z **-112, -138 and -164** (26 u apart: one "stay low" manoeuvre, not three):

- each spans wall to wall where the walls reach the deck, about 18 u;
- deck underside lerp(8.0, 6.5), deck 1.0 thick, red rails (`c1675a`) 1.0 tall;
- **leading and trailing deck edges are half-cylinders (r 0.5)**, so a clip glances;
- the collision hole is the usual +0.3;
- registered as arches: openings {x -36, half_span 6, springing = underside}.

**The gorge breeze** (holds a low glide level, like the warm layers):

- box (-36, 0, -136), size (12, 9, 88);
- strength lerp(0.16, 0.14) (`WARM_LAYER`), look STREET (low motes).

**The lime kiln:**

- a stone kiln face built into the **outer wall** at x -45, z -184 (looks; inside the wall), with a glowing draw arch;
- its smoke billows over the gorge floor;
- plume zone at (-36, 2, -186): R lerp(4.5, 4.0), height 19 (top 21), strength lerp(1.3, 1.2), look STEAM, chime 1.08;
- nothing solid inside it.

**Stars:**

| Arc | Stars | Where |
|---|---|---|
| Signpost (low) | 3 | (-4, ·, -14), (-8.5, ·, -20), (-13, ·, -26), fitted to the entry |
| Into the gorge | 7 | (-22, 14.5, -50) to (-36, 6.5, -86), a gentle curve, every 5.7 u; 1 : 4.5 down |
| Under the bridges! | 9 (big star under the middle bridge) | At each bridge: z +4, 0, -4 at x -36, y lerp(4.5, 4.0) |
| Kiln | 4 | Rising through the smoke from (-36, 5.5, -182) on the traced climb (as the Pasture's bonfire) |

**Why lerp(4.5, 4.0) under the bridges:** at d 0 the line sits 3.5 under the deck and 4.5 over the floor. At d 1 it is 2.5 under and 4.0 over. Both meet §3.2's opening (3.0 / 2.0) and dive-moment (3.5 / 2.5) rules.

**Ideal line:**

1. (0, h, 0)
2. signpost
3. (-22, 14.5, -50)
4. into the gorge to (-36, 6.5, -86)
5. (-36, 4.5, -104), then level under the three bridges
6. (-36, 4.5, -176)
7. kiln smoke to (-34, 10.5, -192)
8. on to the merge (§2.3)

**Heights (estimate, T 1.3, ground speed about 7.3):**

- entering at 18 you reach the gorge at about 5;
- the breeze holds you level for 76 u;
- the kiln gives +5.3 (a plume through its centre), so about 10.5 at -192.

### 2.2 High road: the High Down

**The white scar thermal** (the safe lift, at the road's mouth):

- centre (30, -60), where the road's centre is +32 and the floor is flat;
- R lerp(12, 10.5), strength lerp(0.9, 0.8) (peak 4.5 → 4.0), top lerp(28, 26);
- drifts with the wind, cloud at top + 4, 3 birds;
- a white chalk scar painted on the outer slope beside it.

Near edge at -48 (outside the 30 u buffer). From an entry at 12 you reach it at about 6.7 (62 u, 8.4 s, -5.2), which meets the d 0 ground rule.

**The brow:**

- the right road's floor rises 0 → 10 over z -104..-140, stays at 10 to -160, and falls to 0 by -196 (for x > 18, blending into the walls);
- **brow lift** on its windward face:
  - box (36, 0, -122), size (24, 28, 36), strength lerp(0.4, 0.35) (peak 2.0 → 1.75), look RIDGE;
  - `gull_lift = "Brow"`: **the gull joins you on the high road.**

**The chalk figure:** a paper plane about 20 u long, painted (vertex colour) on the outer slope at x 60..80, z -40..-90, facing the valley. Pure delight, readable from the entry.

**The knoll thermal** (in the merge):

- (22, -228), on flat ground: the right road's centre there is 26.7, and the spine at x 22 is 0;
- R lerp(11, 10), strength lerp(0.85, 0.75), top lerp(28, 26);
- drifts, cloud, birds; a ring of gorse on the knoll (looks).

**Stars (few, by design):**

| Arc | Stars | Where |
|---|---|---|
| Signpost (high) | 3 | (4, ·, -14), (8.5, ·, -20), (13, ·, -26) |
| Brow | 6 | Along the brow at x 34, y lerp(25, 24), z -136 to -166, every 6 u |

There is no spiral on either high-road thermal. The high road pays in height and calm.

**Ideal line:**

1. signpost
2. (28, ·, -50)
3. circle right at r 6 to top - 2
4. (34, 25, -104), along the brow lift
5. Brow stars
6. (24, ·, -214)
7. circle the knoll to top - 2
8. (6, ·, -288)

**Heights (estimate):**

- the scar climb ends at 26 (about 6 s);
- the brow holds about 25-27;
- the knoll's near edge is reached at about 20;
- the climb ends at 26, leaving about **22 at the exit**: 4.3 over the low road.

### 2.3 The merge (both roads)

**The quarry thermal** (low road side):

- (-20, -224);
- R lerp(11, 10), strength lerp(0.85, 0.75), top lerp(24, 22);
- drifts, cloud, birds;
- a pale quarry face painted on the spine's tail.

Under its circle the ground is at most 2.2 (spine tail at x -14), and the drift carries it onto lower ground.

**Quarry spiral:** 6 stars (`_spiral`, start y 9), road "low".

**Low road line:** (-34, 10.5, -192) → near edge (-20, ~8, -213) → circle to top - 2 → (-4, ·, -288).

**Heights (estimate):**

- about 8.3 at the edge;
- leaves at 22 (d 0) / 20 (d 1);
- exits **17.7 / 16**.

### 2.4 F1 totals

| | Low road | High road |
|---|---|---|
| Small stars | 3 + 7 + 8 + 4 + 6 = 28 | 3 + 6 = 9 |
| Big stars | 1 (10 ★) | 0 |
| Arcs with a bonus | 5 (+25) | 2 (+10) |
| ★ if all taken | **63** | **19** (3.3×) |
| Out (d 0 / d 1) | 17.5 / 16 | 22 / 20 |
| Lift | breeze, kiln plume, quarry | scar thermal, brow, knoll |
| Hard part | three bridges, low between walls | none (the climbs) |

**Cadence (estimate):**

- **low road:** signpost 0-4 s, gorge dive 6-11, bridges 12-17, kiln 18-20, quarry 22-28;
- **high road:** signpost 0-4, scar climb 6-12, brow 15-21, knoll 26-30.

No gap is over 5 s.

---

## 3. F2 River or Rail (3 tiles, from 400 m, then the Viaduct)

**Sides:** low road (the River) **right**, at x +36; high road (the Railway) **left**, at x -36. The fingerpost's gold arm points right.

**Generator values:**

- need (12, 12); out = the River's (18, 16.5); the Railway's is (22, 20.5);
- `follower: viaduct`.

**Why the River's out matters:** the Viaduct needs 12 + margin. At F2's earliest exit (about 472 m, d 0.47) the margin is 4.6, so the River must leave ≥ 16.6. A test asserts the follower is always fair after the fork's out (§8).

### 3.1 Low road: the River

**The river:**

- It starts at the split as a painted stream at x 0 and follows the right road's centre.
- From z -80 to -200 it runs in a **cut**: bed -3 at the axis, 0 at |u| 6 (grid).
- Water surface at **-1**, 8 wide (where the bed is below it). The water is drawn and **solid**: touching it is a splashdown "on the River", like the Mere.
- In the merge it curves back to x 0 and runs straight into P6's painted river.

**The river cliff:** on the outer bank, x 44..52, z -96..-204, a sandstone cliff 12 tall (`e9c98a` with rose bands) with a wooded top. Sand martins hover at it (hovering birds, as on the Ridge).

**Bank lift** (sun-warmed cliff):

- box (39, 0, -150), size (10, 18, 104), so x 34..44 over the river's outer half;
- strength lerp(0.5, 0.4) (peak 2.5 → 2.0), look RIDGE (seeds up the cliff face).

**Humpback bridges** at z **-100, -136 and -172** (36 u apart, which meets §3.1's 28 u rule):

- stone single arches, `STONE` / `STONE_DARK`, rounded upstream faces;
- springing at the water (-1), span 12, crown lerp(5.5, 4.0);
- deck 1.2 over the crown, ramping down to the banks at 1.5;
- registered as arches.

**Clearances under the bridges:** the line at y lerp(2.5, 1.75) is 3.5 / 2.75 over the water and 3.0 / 2.25 under the crown. Laterally, the arch's side at that height is 4.9 u from the axis. All meet §3.2.

**The water meadow thermal** (merge, inside the river's bend):

- (16, -222);
- R lerp(11, 10), strength lerp(0.85, 0.75), top lerp(25, 23);
- drifts, cloud, birds.

**Stars:**

| Arc | Stars | Where |
|---|---|---|
| Signpost (low) | 3 | Mirrored right |
| Down to the river | 8 | (18, 14, -42) to (36, 5, -84), every 6 u, 1 : 5 |
| Under the bridges! | 11 (big star under the last bridge) | 3 under each bridge at z +3.5, 0, -3.5, y lerp(2.5, 1.75); a bank star at the top of each rise between bridges, (36, 7, -118) and (36, 7, -154). Each dip is 4.5 down over 18 u: 1 : 4 |
| Meadow spiral | 6 | Start y 9, road "low" |

**Ideal line:**

1. signpost
2. down to the river
3. (36, 2.5, -100)
4. (36, 7, -118)
5. (36, 2.5, -136)
6. (36, 7, -154)
7. (36, 2.5, -172)
8. rise in the bank lift to (34, 7.5, -202)
9. near edge (22, 6.5, -213)
10. circle to top - 2
11. (2, ·, -288)

**Heights (estimate, T 2, ground speed 8):** about 6.5 at the meadow's edge; leaves at 23 (d 0.5); exits about 18.5.

**A safe choice inside the low road.** Over the bridge decks (5.7 / 4.7), anything at 9+ is safe. So a low-roader who doesn't dip still gets the cliff lift, the meadow and the signpost stars.

### 3.2 High road: the Railway

**The cinder yard thermal** (mirror of F1's scar):

- (-30, -60);
- R lerp(12, 10.5), strength lerp(0.9, 0.8), top lerp(28, 26);
- dark cinder ground (`8a8496`), coal heaps (looks), cloud, birds.

**The embankment** (solid):

- along x -36 from z -80 to -200, top at 4 (ramping up over -70..-84), 8 wide, 35° sides;
- rails and sleepers drawn;
- telegraph poles every 12 u at x -42 (looks; no wires in this step).

**The brickworks chimney:**

- solid, r 1.2, top 12, at (-30, -164), with a low kiln shed beside it at x -24 (looks);
- plume on its top: base 12, height 16 (top 28), R lerp(4.5, 4.0), strength lerp(1.3, 1.2), look STEAM;
- the line crosses **over the chimney top at about 17**, 5 above it (the Hamlet's pattern).

**The station** (left side of the merge, z -200..-226):

- platform and canopy (solid, top 8), station house, signal;
- **the engine** standing at the platform (solid, roof 8.5, chimney at its front at (-26, -212));
- **steam:** a wide column you can circle, like the washing copper:
  - centre (-24, -220), R lerp(10, 9), base 9 (above everything solid), top lerp(28, 26);
  - strength lerp(0.9, 0.8), look STEAM, drifts.
- **The track** curves away up the left hillside toward the Viaduct's west end (looks). **P6's deck gets rails drawn** (looks only), ready for step 4's train.

**Stars:**

| Arc | Stars | Where |
|---|---|---|
| Signpost (high) | 3 | Mirrored left |
| Along the line | 5 | (-36, 22, -96) to (-36, 19.5, -120), every 6 u |
| Brickworks | 4 | Rising through the smoke on the traced climb |

**Ideal line:**

1. signpost
2. (-28, ·, -50)
3. circle to top - 2
4. along the line
5. (-30, 17.5, -164)
6. through the smoke
7. near edge (-24, ·, -210)
8. circle to top - 2
9. (-4, ·, -288)

**Heights (estimate, d 0.5):**

- leaves the cinder climb at 25;
- over the chimney at 18;
- 23 after the smoke;
- about 20 at the steam's edge;
- leaves it at 25-26;
- **about 22 at the exit**: 3.5-4 over the River. If calibration says less than +4, raise the steam's top by 1.

### 3.3 F2 totals, and the Viaduct after it

| | River | Railway |
|---|---|---|
| Small stars | 3 + 8 + 10 + 6 = 27 | 3 + 5 + 4 = 12 |
| Big | 1 (10 ★) | 0 |
| Bonus arcs | 4 (+20) | 3 (+15) |
| ★ if all taken | **57** | **27** (2.1×) |
| Out | 18 / 16.5 | 22 / 20.5 |

**P6 follows.**

- Low-roaders come in at about 18 and dive the arch as usual.
- High-roaders come in at about 22: the biggest viaduct dive in the game.
- The deck stars (25.5) stay an alt line.

"The river goes under, the rail goes over" is told by the drawn rails on the deck, and in step 4 by the train.

---

## 4. Generator rules

Added to `EndlessGenerator` (pure and seeded, as now):

```
FORK_FIRST_M := 120          # the first fork is due at the first place at or after this
FORK_GAP := Vector2i(6, 10)  # placements from one fork to the next fork being due
forks: TABLE entries with "fork": true ("follower": id for F2)

_fork_due := -1              # placement index at which a fork is due (-1: not yet set)

next():
  metres >= FORK_FIRST_M and _fork_due < 0  -> _fork_due = placed.size()
  if _fork_due >= 0 and placed.size() >= _fork_due and not rest_due:
      candidates = forks with min_m <= metres, need_in(d) <= h - margin(d),
                   a way on after the fork + follower (_way_on, LOOK_AHEAD),
                   and the follower fair at the fork's out;
                   prefer one that isn't the last fork placed
      if candidates: place the fork (weight 1 each);
                     then its follower, if any, as the next placement;
                     _fork_due = placed.size() + rng.randi_range(6, 10)
                     (drawn here, once per fork placed)
      else: choose normally; the fork stays due (tried at the next place)
  forks never enter _fair()'s ordinary pool, nor _way_on's look-ahead
  (conservative: the look-ahead never counts on a fork)
```

- **Rules unchanged:** a fork counts as lift (yes), rest (no), and a recent piece for no-repeat. Its follower is placed with its own tile's d.
- **What d means in a fork:** layout_d steps (0.25), as for every piece. Footbridge heights, the river's crowns, thermal strengths and radii use the fork's d; the follower uses its own.
- **Expected spacing:**
  - at d < 0.3, most exits (Street 24, Barley 20, Ridge 26.5, Viaduct 20, Barn 20.5, Stones 20, Mere 18) clear 12 + margin (17.6 at 120 m);
  - Hamlet, Kites, Pasture and Poplars don't;
  - so a due fork usually lands within 1-2 places, giving a choice every 6-10 pieces, about every 70-120 s at skilled pace.
  - **Mark:** in 10,000 sequences the fork comes at most 3 places late in 99%.
- **P13** joins the ordinary pool: 2 tiles (weight 0.6), lift yes, rest no.

**Seed purity (hangar-plan §4.2):**

- The generator takes no input from the flight. Its `h` is the table's, never the flyer's.
- Fork kits use no RNG beyond the existing per-id seeded `_paint_rng` and tree RNGs.
- The only draw is the fork gap, made at placement time.

---

## 5. P13 Warm Down (2 tiles, from 250 m)

**Why 2 tiles.**

- One tile has no room for lift after the hill. In 96 u, a crossing at the saddle (big star at 13.5) exits at about 11-14, and only the Street can follow that.
- A crossing high enough to exit at 20 passes 10+ u over the grass, and the hill is scenery.
- Two tiles give: climb, cross low, swoop, catch the next thermal. That is fear, then relief, like the Viaduct, but over a hill.

**Ground** (z 0..-192):

- **The down:** 14 · f(z) across the whole floor, merging into the sides (ground = max(standard, down) + rolls):
  - near face -50..-78 (0 → 14; steepest 1.5 × 14 / 28 = 0.75, which is 37°, so a glide into it bumps rather than crashes);
  - crest -78..-86;
  - lee -86..-116 (14 → 0; steepest 35°).
- **The saddle:** centred x +8, the crest dips to 10 for |x - 8| ≤ 4 and rises back to 14 at |x - 8| = 12. It is the low way over: the plan's "saddle of 10, 24 wide".
- **Looks:**
  - gorse in yellow flower and a chalk track painted up the face (the "warm" slope);
  - sheep on the crest;
  - a lone hawthorn on the crest at (-20, ·, -82), solid, 5 tall (it reads as scale);
  - a big round **hayrick** (solid, r 2.5, 4 tall) at (10, -142).
- Joins: nothing above 6 in the first 30 u or the last 12.

**Lift:**

| Zone | Where | Numbers |
|---|---|---|
| Sun-trap thermal | (-12, -44), on the flat at the face's foot | R lerp(12, 10); strength lerp(0.9, 0.8) (peak 4.5 → 4.0); top lerp(26, 24); drifts; cloud at top + 4; birds |
| Hayrick thermal | (10, -142), on the flat past the lee | R lerp(11, 10); strength lerp(0.85, 0.75); top lerp(25, 23); drifts; cloud (visible over the crest from the face: the promise beyond the hill); birds |

**Checking the sun-trap:**

- Near edge -32 (outside the buffer). Neither thermal is on the middle line (fun review 6, item 4).
- **The clearance rule (top - 6 within 36 u downwind):** the only thing there is the face's grass. The hawthorn is at x -20, z -82: 38 u downwind and beside the drift path.
- **Circling over the rising face (the plan's caution):**
  - drift 1.5-3 u/s × the face's average slope 0.5 means the ground under the circle's far side rises 0.75-1.5 u/s;
  - the climb is 2.5-3.4 u/s;
  - entering at 7, the far side of the r 6 circle starts over ground ≤ 1, and the gap grows.
  - **Calibrate this first** (§9).

**Stars:**

| Arc | Stars | Where |
|---|---|---|
| Sun-trap spiral | 4 | `_spiral`, start y 9: a short climb, about 2 laps |
| Over the saddle | 4 + big | (-4, 19.5, -64), (0, 18, -70), (4, 16.5, -75), (6.5, 15, -80), then the big star at (8, 13.5, -84): 3.5 over the saddle floor and 10 u from its shoulders |
| Down the lee | 4 | 4-4.5 u over the saddle's lee: (8, 13, -92), (7.5, 10.5, -99), (6.5, 8, -106), (5.5, 6.2, -113). 1 : 4 down, and speed builds to about 9.5 u/s |
| Hayrick spiral | 6 | `_spiral`, start y 9 |

Total: 18 small + 1 big.

**Ideal line:**

1. (0, h, 0)
2. near edge (-12, ·, -36)
3. circle right at r 6 to y lerp(20, 19) (leave early: the saddle is the point)
4. Over the saddle
5. big star
6. Down the lee
7. (8, 7.5, -126) (the swoop's pull-up from about 9.5 u/s gives +2-3)
8. near edge (10, ·, -131)
9. circle to top - 2
10. (2, ·, -192)

**Numbers (estimate):**

- **need_in (10, 11):** 36 u to the near edge costs 3.1 at T 1.6, arriving at ≥ 7.
- **out (20, 18.5):** leave the hayrick at 23 / 21, then 30 u of glide.

**Effects:**

- Crossing the saddle (the crest line at z -84 within |x - 8| ≤ 8) gives a wind swell (+3 dB over 0.8 s). At ≥ 7.5 u/s add the +3° FOV kick: the view opens down the lee.
- Register the saddle as an arch opening (x 8, half_span 8, springing 18) so the existing whoosh logic covers it.

**Step 4 neighbour: the lee rotor.** Put it **behind the high crest, not the saddle**: x -28..-2, y 0..12, z -88..-118. The saddle's lee stays the safe way down. Otherwise the swoop line (6-13 u over a 1 : 4 slope) would be pushed into the ground.

**Table row:** warm_down: tiles 2, lift yes, rest no, min_m 250, need (10, 11), add INF, cap (20, 18.5). WHERE "on the Warm Down".

---

## 6. Fun review 6 follow-ups

### 6.1 The Standing Stones' 0 of 9

**Cause.** The game picks the line at the join (`p.placement.tile > _piece_tile`). A pilot circling a drifting thermal across the join (here the heap spiral) is still at 13.5 there, so the game picks **low**. The pilot then climbs to 21+, and the Autopilot (which waits until it stops circling) picks **high**. The stars show a low line nobody is flying, and the high line has no stars. That gives 11.7 s of nothing.

**A human gets the same mismatch.** Circle over the join, top out, and the game shows stones stars you can't dive to (1 : 0.75 from 22). **So fix the game,** then make the pilots follow it.

**Fix:**

1. **The choice point.** A two-line piece decides (`takes_high`, `choose_line`) **and** fits its entry arcs (`fit_to_entry`) at the first tick the flyer is either:
   - ≥ 6 u into the piece **and** heading onward (horizontal velocity within 60° of -Z), or
   - ≥ 24 u in, whatever it is doing.

   Until then the high line's arcs are alt, as now before the entry.
   - A straight entry decides at -6, as today in effect.
   - A pilot circling over the join decides when it straightens out, at the height it really has.
   - The Barn's first dive star is at -12 and the Stones' at -28, so the 24 u fallback is in time for both.
2. **The game emits `line_chosen(tile, high)`.** Autopilot connects to it and switches that part's points to the game's line, replacing its own `_choose_lines` and `CHOOSE_AHEAD`. It keeps `_too_steep` only to plan ahead. Forks emit `road_chosen(tile, road)` the same way, for the logs.
3. **Mark:** a scripted test circles a thermal across the Stones' join at 13.5 and straightens at 22. It gets "high line", and no low-line stars are counted.
   - In 20 skilled runs no two-line piece logs "low line" with the pilot flying high, and no pass of the Stones takes 0 of 9 while flying its low line.

### 6.2 The Mere's middle stars

**Cause.** The across-arc is a straight diagonal from (0, 15, -22) to (-10, 10, -49): a 20° heading change at star 1, flown in the lake's sink. The pilot is still turning at stars 3-4.

**Fix (layout).** Hold the middle, then turn smoothly:

- x = 0, 0, 0, -1.5, -4, -7, -10
- z = -22, -27, -32, -37, -41.5, -45.5, -49
- y unchanged (15 → 10)

Spacing is 5-5.2 u, and the turn radius about 18. Move the ideal line's points to the stars. Keep `from_entry` 6.

**Mark:** the skilled pilot takes stars 3 and 4 in ≥ 75% of passes, and the full arc in ≥ 50%. Trace one pass at 0.1 s first, to confirm the turn (not the sink) is the cause.

---

## 7. Test pilots and tools

**Autopilot** (skilled, shaky, novice):

- `EndlessWorld.fork_choice(p)` returns {z, low_side, low, high} (both roads' lines in world coordinates).
- The pilot picks its road **before fork z -12** by `--road`:

| --road | What it does |
|---|---|
| `alt` (default) | Alternates low and high fork by fork, starting by seed parity, so every batch flies both |
| `low` / `high` | Always that road (calibration, marks) |
| `height` | Low if entering ≥ 18, else high (a sensible human) |

- The `novice` kind defaults to `height`.
- The pilot's choice must match the game's commit. The tool counts mismatches; the mark is 0.

**FirstTimer:**

- `chaser` and `nocircle` follow the nearest star. The signpost stars are 8 u apart, so that already picks a road.
- `middle` gets a **nose reaction** like the viaduct's: seeing the spine's nose within `react_wall`, it steers toward its side of x 0 (by its seed if |x| < 1).
- `handsoff` stays untouched (the floor: it meets the nose).

**`tools/endless_log.gd`:**

- `--road=` as above.
- `--calibrate --piece=gorge_down|river_rail --road=low|high` flies one road (F2 calibrates with its Viaduct).
- `--piece=warm_down`.
- **Per run:** fork notes, and a "roads: L H L" line.
- **Batch summary, per fork and road:**
  - flown;
  - stars taken (of that road's own);
  - full arcs;
  - out (median);
  - endings, and endings at the nose.
- **Endings** at forks name the place ("at the fork", "in the Gorge").

---

## 8. Tests to add (`tests/test_forks.gd`)

**Generator** (pure, fast):

1. **10,000 sequences of 40 placements, random seeds:**
   - every step-1/2 rule still holds;
   - no fork before 120 m (F2 before 400 m);
   - each fork comes 6-10 placements after the previous fork, or later only while unfair (99% within +3);
   - F2 is always followed at once by the Viaduct, and the Viaduct is fair at F2's out (need + margin ≤ out);
   - no fork twice in a row when the other was fair.
2. A fork's TABLE need = the higher road's, and out = the lower road's (the per-road values in the table).

**Seed purity** (hangar-plan test 15, made real):

3. The same seed gives identical ids, tiles and d for 60 placements; daily seeds included.
4. **Full physics:**
   - one daily seed flown by the skilled pilot with `--road=low` and again with `--road=high` until 30 pieces are placed;
   - identical piece ids, tiles and d;
   - identical zone homes and non-spiral star positions for every piece after the first fork.
5. **Source guard:** no `randi(`, `randf(`, `randomize(` or `randi_range(` on the global RNG in `generator.gd`, `pieces.gd`, `endless_world.gd` or `stars.gd`. Only local `RandomNumberGenerator`s with fixed seeds.

**Ground and fairness:**

6. Fork and P13 ground matches `standard(x)` at both ends (±0.01).
7. The band can't leave or cross:
   - fork z -100..-196: ground at x 0 ≥ 36;
   - every z: ground ≥ 30 at |x| ≥ 90;
   - P13: nothing above 6 in the first 30 u or last 12.
8. **Openings, at d 0 and 1:**
   - footbridges' vertical opening ≥ 5.5 / 4.5;
   - humpback arches ≥ 6.5 / 4.75 from water to crown;
   - collision holes are the drawn ones + 0.3;
   - every star ≥ 2.0 from any solid (the existing check, run over forks and P13).
9. **Sight lines** (§1.3, also step 1's mark 12, finally built): from 60 u back along each road's ideal line (80 u for the gorge dive), a ray to each bridge opening's centre, the saddle and the scar thermal's cloud hits nothing solid.
10. **Nose:** a hands-off flyer launched at (0, 15, -20) local at the fork, 6 u/s, gets a bump (not a crash) at the nose.

**Commit and stars:**

11. A flyer at local (-20, 10, -70) commits low and (20, 10, -70) high. At y 30, z -60 there is no commit. The fallback is at -100.
12. After a low commit, the high road's arcs are alt and dim and add nothing to `missed_total`. A low signpost star taken before swinging high is kept but not counted.
13. The commit pop-up, the first-fork hint (once a session) and the "where" texts.

**Follow-ups:**

14. The choice point (§6.1, the scripted Stones case): `fit_to_entry` runs at the choice point, not the join, and the Autopilot follows `line_chosen`.

**Kits:**

15. Fork and P13 kits build in steps of ≤ 4 ms each on PC headless (`tools/kit_times.gd`). The content is split into frame, low road, high road and merge steps.

**Guide:**

16. HowToFly names every piece in `NAMES` (forks and P13 included) and the new bonus title.

---

## 9. Calibration and marks

**Calibrate first, in this order:**

1. **P13's sun-trap,** entering at need and at 26, d 0 / 0.5 / 1, at each d's wind. Lowest clearance while circling over the face must be ≥ 5 (d 0) / 4 (d 1). Then the lee swoop's clearance (≥ 3.5 / 2.5) and the hayrick's arrival (≥ 6 / 4).
2. **The gorge:** heights under the bridges with the breeze, the kiln gain, and arrival at the quarry.
3. **The River:** the dips, the bank lift rise between bridges, arrival at the meadow, and **out ≥ 16.6 at d 0.5** (the Viaduct follower). If short, raise the meadow's top or move it 6 u nearer.
4. **Both high roads' outs:** at least the low road's + 4.
5. **The table** from the measured outs, as for steps 1-2.

**Marks** (§11 of the Endless plan, made specific):

| Mark | Pass |
|---|---|
| Calibration | Each road from need and 18: no touchdown or crash; clearance ≥ 4 on the line (≥ 3 / 2.5 at dive moments); ≥ 2.0 from solids; out within ±1.5 of the table; each arc full from need and 18 |
| Both roads, shaky ×20 each (`--road=low`, `--road=high`) | 20 of 20 with no touchdown |
| Stars | Low ≥ 2× high, as available (63 vs 19; 57 vs 27) **and** as taken by the skilled pilot |
| Height | High exits ≥ 4 u over low (skilled median, each d) |
| Choice cadence | In 20 skilled runs of 420 s: every run that passes 150 m meets a fork; the median gap between forks is 6-10 pieces |
| Skilled overall | ≥ 85% of stars still (mark 6); spirals at review 5's marks |
| Hands-off ×20 | Median 45-150 s, ≤ 3 past 12 pieces, none past 20 (as revised in review 6); 0 crashes at a nose |
| Chaser and no-circle ×20 | No ending from a star line that leads into something; ≤ 2 of 40 runs end at a footbridge or humpback bridge; record which roads they take |
| Pilot vs game | 0 road mismatches; 0 line mismatches (§6.1) |
| Cadence | Skilled: no gap over 5 s on either road except the glide out of a full climb |
| Budget | PC: draw calls ≤ 43, primitives ≤ 50k in view at the split (both roads in view) and in the gorge; no frame over 16.7 ms while a fork kit builds |

---

## 10. Info text (`scripts/how_to_fly.gd`)

**Places → Endless, place by place.** Replace the first line with:

> New places turn up the further you fly: the first fork at about 120 m, the Mere after 200 m, the Warm Down after 250 m and the River or the Railway after 400 m.

Add after Mere:

> Forks: now and then a wooded hill rises in the middle of the valley and splits it in two. A signpost and two short lines of stars show both ways: the gold arm points to the low road, the blue arm to the high road. The low road has more than twice the stars and tighter flying. The high road starts with a big thermal and leaves you higher. Pick a side before the hill: it is too tall to fly over. The two ways meet again beyond it.
>
> The Gorge or the High Down: dive into the gorge and fly under its three footbridges, with a big star under the middle one. The lime kiln's smoke lifts you out, and a thermal rises off the quarry beyond. Or take the high down: a thermal by the white scar, lift along the brow (the gull may join you), and another thermal on the knoll.
>
> The River or the Railway: skim the river under three stone bridges, with warm air rising off the cliff beside it, and a thermal over the water meadow. Or follow the railway, through the brickworks' smoke and up the engine's steam. They meet at the viaduct.
>
> Warm Down: a grassy hill across the valley. Climb the thermal at its foot, cross the low saddle for the big star, swoop down the far side and catch the thermal by the hayrick.

**Updrafts:**

- **Thermals,** Endless list: add "the white scar, the quarry and the knoll at the Gorge or Down, the cinder yard and the water meadow at the River or Rail, and the Warm Down's sun-trap and hayrick".
- **Smoke and steam:** append "The lime kiln and the brickworks chimney are narrow: fly through. The engine's steam is wide enough to circle in."
- **Ridges:** add "the High Down's brow, and the warm cliff along the river".
- **Low warm air:** append "In the gorge, air drawn up between the walls holds you up low in the same way."

**Downdrafts → Over the water:** append "Touching the river is a splashdown too."

**Points and bonuses → Endless:**

- add "Under the bridges!" to the list of bonus names;
- append to "The line follows your height": "At a fork, the stars of the road you didn't take stop counting once the hill is between you."

**Touching things:** append "A fork's hill is too steep and tall to cross. Fly into it gently and it bumps you off."

**Tips:** add "At a fork, take the high road when you are low or shaky: it leaves you higher for what comes next. Take the low road for stars."

---

## 11. Phone checklist (owner, Fold5)

1. **The first fork** (about 120 m):
   - Did you see the hill coming?
   - When did you know which way you'd go?
   - Did the signpost arms and the two star lines make the trade clear without reading the hint?
2. **The gorge:**
   - Are the footbridges easy to see, and to line up under?
   - Thrilling, or too tight?
   - Did any bridge hit feel unfair?
3. **The high roads:** calm and pleasant, or boring? Did the gull join on the brow?
4. **Over three or more forks,** which road did you pick and why? Do you ever pick the high road?
5. **The river** (after 400 m): are the dips under the humpback bridges fair at that speed? Does the viaduct dive after the railway feel like the payoff?
6. **The Warm Down:**
   - Does the hill look like something you must climb to clear?
   - Did you find the saddle?
   - Does the swoop down the lee feel fast?
7. **Fly into a fork's nose on purpose:** bump, crash or slide? Did it feel fair?
8. **Frame rate:** 120 fps at the split (both roads in view), in the gorge, and while a fork is being built (watch for a stall about 3 tiles before it).
9. **Circle a thermal across a join into the Stones or the Barn:** do the stars you see always match where you can fly?

---

## 12. Step 4 neighbours (don't design now)

- **The kitten's houses** will want a window facing a line.
  - Candidates: the station house (F2), a kiln cottage (F1's gorge mouth), and a cottage in P13's hayrick field.
  - Keep 8 u clear of any solid around those spots, and keep the lines' clearances valid if a cottage is added.
- **Movers and the kitten:** timing from (seed, tile), never `randi()` (hangar-plan §4.2). Test 4 above extends to them.
- **The train** runs on P6's drawn rails. F2's railway track already curves toward it.
- **The lee rotor** on P13 goes behind the high crest, not the saddle (§5).
- **Wood or Water** (the third fork) reuses the frame (§1) and the same commit, stars and log rules.

---

## 13. Later ideas

- A "both roads" badge for flying the low and the high road of the same fork in a day's flights.
- Telegraph wires along the railway that snag (step 4's Pylons family).
- A heron lifting off the river when you skim under the last bridge.
- The chalk figure changing to the look you wear (balloon or plane).
