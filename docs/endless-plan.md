# Endless plan (Phase 5): an endless country beyond the lake

The owner's brief, word for word: "Right now I can fly one path in the house and I can fly through the pass to the lake and that's it. But it's a really short game. I want to leave all of that alone - using that as a learning phase for the game player, but then I want the player to have an endless route where they can keep flying. We need to add things they need to fly over, fly under, fly through, setup various obstacles for them. We should also look to having them choose a particular path to achieve points, maybe they collect stars and then can trade those stars in later for something else. Take a look at the game 'temple run' for inspiration on how this might work."

**Settled by the owner.**

- The Course (house, opening, valley, Gap, bowl, scoring, novice run) does not change. It is the learning flight.
- Endless is a separate mode. It unlocks the first time the player lands the Course outdoors. It starts in the air past the lake, and a retry takes seconds.
- Approved new systems for this phase:
  - the Endless mode;
  - pieces chained by a generator;
  - obstacles;
  - forks;
  - stars;
  - a Hangar (shop);
  - power-ups;
  - missions;
  - a daily flight.
- No real money, no ads, no internet, no new permissions.
- The flight model does not change. Pace comes from the environment.

**What this plan covers:** the opening, the piece system, a piece library, obstacle rules, stars, scoring, the difficulty curve, the economy, power-ups, missions, the daily flight, build steps, test marks and decisions. **Step 1 (§10.1) is a small prototype**, specified in full, that goes on the phone before any Hangar or economy work.

**Conventions.**

- World axes are as before: flight heads -Z, +X is the player's right, 4 units = 1 metre.
- **Piece-local coordinates:** x across the valley (0 = its centre), y above the valley floor, z from 0 at the piece's entry edge to -96 at its exit (-192 for a two-tile piece).
- **d** is difficulty, 0..1. **lerp(a, b)** means a at d 0 and b at d 1.
- **T** is the tailwind in u/s.
- **Sim-checked** means flown in my scratch sims: FlightModel, the real Thermal profiles, a tailwind and a pure-pursuit pilot like `tests/autopilot.gd`. The sims live in the session's scratch folder, not the repo.
- **Estimate** means arithmetic only. The lead's calibration tool (§2.4) measures every piece before it ships.

---

## 0. The flight numbers this plan stands on

All measured with today's `FlightModel` and `tuning.gd` in the scratch sims.

**Steady glide by pitch input (15 s settled)**

| Input | Airspeed | Sink | Glide |
|---|---|---|---|
| +0.3 | 4.0 | 0.26 | 15 : 1 |
| +0.15 | 4.9 | 0.37 | 13 : 1 |
| 0 (hands off) | **6.05** | **0.62** | **9.7 : 1** |
| -0.2 | 7.9 | 1.30 | 6 : 1 |
| -0.5 | 10.6 | 3.0 | 3.4 : 1 |
| -1.0 | 14 (cap) | 7.0 | 1.7 : 1 |

**Manoeuvres from a neutral glide (no wind)**

| Move | Time | Ground covered | Height |
|---|---|---|---|
| Full dive to 10 u/s | 1.6 s | 11 u | -6.3 |
| Drop 3-4 u and level out | 1.1-1.3 s | 7-9 u | leaves at 7.7-8.4 u/s |
| Pull up from 6 u/s (a "hop") | 0.5 s | 2-3 u | **+0.5** |
| Pull up from 10 u/s | 1.3 s | 9 u | +3.2 |
| Pull up from 14 u/s | 1.9 s | 15 u | +6.3 |
| 90° turn, full bank | 1.5 s | | -1.0 |
| 180° turn, full bank | 2.9 s at any speed | diameter 10.7 at 6 u/s, 13.9 at 8 | -2.0 |
| Sidestep 5 u and straighten | 2.2 s | 12 u | |
| Sidestep 11 u | 3.2 s | 13 u | |

**Lift**

| Source | What it gives |
|---|---|
| Thermal R 12, 4.5 u/s peak, circled at r 6 | y 5 → 25 in 6 s (3.4 u/s) |
| Thermal R 10, 3.5 | y 5 → 25 in 12-15 s; from y 10, 3-4 s per 10 u |
| Thermal flown straight through its centre (60 u) | R 12 / 4.5: +6.9. R 10 / 4.0: +3.6. Slow flight (+0.15) about doubles both. |
| A band of 2.0 u/s (ridge or street) flown along its core | net +1.2 u/s at neutral |
| Plume R 4, 6 u/s, flown through its centre | +5.3 u compared with missing it (net +1.2 over 40 u). Half a radius off-centre: +4.1. |
| Three plumes (R 3.5, 6 u/s) 12 u apart | +4.7 net over 80 u (+13 compared with none) |
| Sink 0.4 / 0.8 / 1.5 u/s over 60 u | -3.2 / -6.4 / -12 extra |

**Rules of thumb used everywhere below**

1. **"Over" is never a hop.** Pulling up from a glide buys 0.5 u. Clearing anything means arriving high or using lift in front of it.
2. **"Under"** needs about 1.2 s and 8 u of travel per 3-4 u of drop, plus a second to decide.
3. **"Around"** needs about 2.2 s and 12-16 u of travel to sidestep 5 u.
4. **Height is health.** You lose 0.62 u/s, which is about 8 u per 96 u tile at T 1.5.
5. **Thermals need R ≥ 10** to be circled in their core, because the full-bank radius is 5.6. Plumes (R 3.5-5) are flown through, never circled.

---

## 1. The opening: unlocking, starting, retrying

### 1.1 Unlocking

- Endless unlocks the first time a Course run **comes to rest outdoors without a crash**: the lavender, picnic, island, beach, the kitchen roof, a splashdown or plain grass all count. It is saved at once.
- That end card gets a gold line, **"Endless unlocked!"**, with the style_perfect sparkle (first time only).
- Players with an older save: see decision 9.

### 1.2 The end cards

**The Course card, once unlocked**

- Its lines are unchanged.
- Two big buttons, each 340 × 96: **[Fly again]** and **[Endless]**.
- The row below is unchanged: swap look, Settings, Quit.
- Focus goes to Endless on the unlocking run. After that it goes to the mode just flown.

**The Endless card**

```
Touchdown                      (or Crumpled! / Popped! / Splashdown! / Wrong way!)
412 m                          (44 pt; a gold "New best!" when beaten)
Stars ★ 63   (bank 1,204)
Score 4,750
Best 520 m
[ Fly again ]   [ Course ]
[ Fly the paper plane ] [ Settings ] [ Quit ]
```

- Debug builds add a **[Wind 1.5]** button that cycles 0 / 1.5 / 3.0 for this session (§10.1).
- Later steps add [Hangar] and [Daily] (step 5), "Second wind" (step 6) and a missions line (step 7).

### 1.3 The first Endless flight of a session

**Where it is.** Endless keeps the Course's world coordinates, so the bowl sits behind you exactly where it is in the Course.

- The Endless valley floor is at **world y 40**.
- Tile *i* has its piece-local origin at world (0, 40, -528 - 96 *i*). Tile 0 is the launch tile, which begins at the bowl's edge (z -528).
- The scene draws a **coarse backdrop of the bowl**. It is not solid:
  - `Course.ground_height()` sampled at a 12 u step over z -339..-528 (read-only use of the static function; course.gd does not change);
  - the lake sheet, the island and the boat at rest;
  - the Downs' crest and the windmill with its sails turning.
  - About 1,500 triangles and 2 draw calls. It is freed once the flyer passes tile 2.

**The sequence**

1. Tap **Endless**.
2. A 0.25 s cream fade, then a cream card reading "Beyond the lake…" while the scene loads and prebuilds its piece meshes (§2.7). Budget ≤ 0.6 s on the phone.
3. **Start.** The flyer is in the air at world **(0, 72, -530)**, heading -Z at the throw speed (6.5 u/s).
   - The rim of the bowl continues 6 u past the Course's edge to a rounded crest about 4 u higher (world z -534, y ≈ 66 at x 0).
   - So the flyer starts 4 u short of the crest and passes about 6 u over it.
4. **Look-back shot, 1.4 s.** Controls are locked and the flyer glides hands-off.
   - The camera starts 10 u ahead of the flyer and 4 u above it, looking back past it.
   - It sees the whole bowl: the lake 120 u away and 33° down, the island, the boat, and the Downs with the Gap's notch and the windmill 205 u away (fog transmittance 0.6).
   - It then swings up and over the flyer (smoothstep) into the chase position.
5. **At 1.4 s, the reveal.** Control is released, and the phone's angle becomes level.
   - Gust swell (`gap_gust_db` 4 over 1.2 s), whoosh, FOV kick +5°.
   - Ahead: the rim's far slope falling 26 u into a new valley, a star arc running down it, and the first line of clouds.
6. Hint "Stay up as long as you can" (2.5 s). On the very first Endless run only, "Catch the stars" follows (2 s).

From tap to control is about 2.3 s, once per session.

### 1.4 Retry

- **"Fly again" resets in place**; it does not reload the scene.
  1. Free the tiles.
  2. Reset the flyer, camera, score, vario and gull.
  3. Generate a new sequence with a new seed.
  4. Place the launch tile and the next 4 tiles from the prebuilt meshes.
  5. Launch at the start point with the chase camera already in place (no look-back), behind a 0.2 s cream fade-in.
  6. Release after 6 smooth frames, as the Course does.
- **Card delays:** crash 0.45 s (`card_delay_crash`); touchdown and splashdown 0.6 s, so the slide shows.
- **Budget:** crash, then the card at 0.45 s, then the tap, then flying within 0.3 s. That is under 0.8 s plus the player's tap. Pass mark: ≤ 2.0 s with a scripted tap at +0.5 s (§11).

### 1.5 App start and "Wrong way"

- **App start:** the app opens in the mode last flown (decision 5). This needs a tiny boot scene that reads the save and opens `main.tscn` or `endless.tscn`. An app start into Endless gets the look-back.
- **"Wrong way!"** ends the run if the flyer goes back past world z -520. To do that the player has to fly upwind on purpose.

---

## 2. The piece system

### 2.1 Tiles and pieces

- **A tile is 96 u long and 192 wide** (x -96..96).
  - It is a 16 × 32 grid at the Course's 6 u step, so 1,024 terrain triangles.
  - At 7-9 u/s over the ground, a tile takes 10.6-13.6 s at a neutral glide.
- **A piece is 1, 2 or 3 tiles.** Most are 1; the Long Ridge is 2; forks are 3.

### 2.2 Joins

**The standard cross-section** is used at every piece's entry and exit edge:

- floor y 0 for |x| ≤ 28;
- sides at 0.016 (|x| - 28)²: 2.3 at |x| 40, 7.7 at 50, 16.4 at 60, 28 at 70, 74 at 96.

A flyer at 30 (the top of the flying band) meets the side at |x| 71, so nothing can leave the valley.

**Rolls.** Soft rolls (±0.5 u) on the floor only, faded to 0 within 12 u of each edge, so the edges always match exactly.

**Join buffers.** In the first 30 u and the last 12 u of every piece:

- nothing solid stands above y 6 within |x| ≤ 28;
- no lift zone starts there.

The only thing that crosses a join is a drifting thermal and the climb in it, and the buffer keeps that climb clear.

**Height band.** Every ideal line crosses its joins between y 8 and 28.

### 2.3 The air

**Tailwind (environment only; the flight model is unchanged)**

- The air mass moves toward -Z at T u/s. The flyer moves by its flight-model velocity plus (0, 0, -T·w), where w = smoothstep(0, 4, height above the ground).
  - The wind dies within 4 u of the ground (`endless_wind_ground_fade`), so slides stop and landings look as they do today.
  - In the Course T is 0, so nothing changes there.
- The flight model still sees only vertical air. Inside the moving air, glides, turns, climbs and stalls are exactly today's; only ground speed changes (6.05 + T at neutral).
  - Bumps and crashes are judged on the flight-model velocity, as today.
  - The drift goes into the same `move_and_collide` motion, so it slides along walls.
- **Step 1:** T is a constant 1.5, with a debug toggle for 0 / 1.5 / 3.0.
- **From step 2:** T = lerp(1.0, 3.0) over 0-1,000 m, then +0.1 per 100 m up to 3.5.
- **What it buys:**
  - ground speed +17-50%;
  - a decision every 2-4 s instead of every 4-6 s;
  - circling carries you down the course;
  - turning back crawls (4.5 u/s at T 1.5), so you are always going forward, as in a runner.
  - The rising wind is the "speed goes up" of Temple Run, without touching the flyer.

**Thermals drift with the wind (Endless only; the Course's drift is unchanged)**

- From wake (the plane within 1.5 R, as today), the thermal, its cloud, its birds and any stars in it move at T toward -Z.
- After drifting `endless_thermal_life` (lerp(36, 24) u), its lift fades to 0 over 4 s and its cloud thins (today's thinning look).
  - That is 24 s at T 1.5 and 8 s at T 3: always enough for a climb (3-8 s), never enough to hang there forever.
- **Clearance rule:** nothing solid higher than (top - 6) stands within 36 u downwind of a thermal's home.

**Anchored lift.** Ridge bands, cloud streets and plumes stay where the ground puts them.

### 2.4 Piece metadata

Each piece in the library carries:

- `verbs`: lift, over, under, through, around, hazard;
- `rest`: true if it asks for no manoeuvre past an obstacle;
- `tiles`;
- `min_m`: the distance (metres) from which it may appear;
- `need_in(d)`: the lowest entry height (at z 0) from which the ideal line keeps ≥ 6 u over the ground (4 u at d 1) and every clearance in §3.2;
- `out(d, h)`: the height at which the ideal line's last climb ends (or at the exit if the piece has no climb), entering at height h;
- the **ideal line** (a polyline) and its **orbits** (circles in its thermals), in the same form the Course's Autopilot uses;
- its star arcs and big stars.

**The numbers are measured, not typed.** `tools/endless_log.gd --calibrate` flies the skilled pilot over each piece alone:

- at d 0, 0.5 and 1;
- at T 0, 1.5 and 3;
- entering at need_in and at 26.

The table in code is written from those runs.

### 2.5 The generator

A seeded RNG: a random seed per run, or the date for the daily flight (§8.4).

```
h = 24                                    # guaranteed height leaving the launch tile
place Launch, then Cloud Street
repeat:
  d = clamp(distance_m / D_FULL, 0, 1)    # D_FULL: 600 m in step 1, 1,000 m from step 2
  pool = pieces with min_m <= distance and d inside their range
  remove pieces used in the last 2 places (last 3 at d >= 0.5)
  if the last k pieces had no lift: remove pieces without lift    (k = 1 at d < 0.5, else 2)
  if no rest piece in the last R places: keep only rest pieces    (R = 3 at d 0 → 5 at d 1)
  remove anything with need_in(d) > h - margin(d)
  if a fork is due (every 6-10 pieces after 150 m): pick from forks that pass the same test
  if pool is empty: pool = [Cloud Street]   # need_in 4: the rescue piece
  pick by weight: 1.0; 0.6 for 2- and 3-tile pieces; x1.5 for a piece not yet seen this run
  h = out(piece, d, h)
margin(d) = lerp(6, 3)
```

**Fairness guarantee.** A pilot who flew the previous ideal lines enters every piece at least `margin` above what it needs, so lift is always in reach. §11 checks 10,000 sequences.

### 2.6 Forks

**Shape.** A fork is a three-tile set: split, branches, merge.

- The valley's middle rises into a **spine**, a steep wooded hill at least 36 high. It can never be crossed, because the flying band tops out at 30.
- The spine starts at a rounded nose at z -30 of the split tile (rising 0 → 36 over 50 u) and ends at z -40 of the merge tile.

**Making the choice.**

- The nose is in view from ≥ 150 u.
- A fingerpost (two arms, looks only) and two diverging three-star lines, starting 60 u before the nose, make the choice plain.
- You commit by z -20 of the split tile.

**Both branches stand alone.** need_in(fork) = the higher of the two branches; out(fork) = the lower. Whichever you pick, the next piece is fair.

**The trade between the roads.**

| Low road | High road |
|---|---|
| At least twice the stars | Few stars |
| Weaker or harder lift | Safe lift |
| Exits lower | Exits at least 4 u higher |

**Forks always rejoin within their set.** The world stays a single line, which keeps streaming, recentring and the daily flight simple.

### 2.7 Streaming, budget, recentring

**Prebuilt pieces.**

- At scene load, build every piece type's static mesh once: terrain and props in one vertex-coloured mesh with `Art.material()`, plus its collision faces.
- A tile on the map is one MeshInstance3D and one StaticBody3D sharing those resources, plus its zones (pooled Thermal nodes) and its stars (MultiMesh instances, not nodes).

**What is loaded.**

- Keep 5 tiles ahead (480 u) and 1 behind.
- Tile meshes use `visibility_range_end` 440 with a 60 u fade, so new tiles fade in out of the fog instead of popping. Fog stays at 0.0025, which is a transmittance of 0.33 at 440 u.

**Spawning.**

- At most 2 ms of spawn work per frame on the phone: one tile's mesh and body in one frame, then its zones one per frame.
- Spawning starts 5 tiles out, so there is always time.

**Budget (the same as the bowl).**

| Item | Limit | Expected |
|---|---|---|
| Draw calls in view | ≤ 43 | terrain and props, one per tile (≤ 5); clouds, birds, stars and big stars in 4 MultiMeshes; 2-4 zone columns and particle systems; flyer, shadow, gull, post pass, UI |
| Primitives in view | ≤ 50k | about 6-8k per tile |
| Live particles | ≤ 400 | |
| Transparency | particles only | everything else opaque |

**Distant hills.** A ring of 6 low-poly hills 350-600 u out, stepped forward a tile at a time, with no collision (like the Course's far hills).

**Recentring (step 2).**

- When the flyer passes world z -4,600, shift the whole world +4,096 in z between two physics ticks at a tile boundary.
- That means the flyer, camera, tiles, zones (with their homes), stars and the distance offset. Then reset physics interpolation.
- z stays below -500, so `FollowCamera`'s "outside" test stays true.

---

## 3. Obstacles

### 3.1 Reaction distance

The time to see, understand and act is 1.0 s plus the time of the move.

| Move | Move time | Lead at T 1.5 (7.55 u/s) | Lead at T 3 (9.05 u/s) |
|---|---|---|---|
| Drop 4 u to go under | 1.3 s | 17 u | 21 u |
| Sidestep 5 u to go around | 2.2 s | 24 u | 29 u |
| Line up with an opening (3 across, 2 up) | 2.0 s | 23 u | 27 u |
| A long dive of 12 u to go under | 3.5 s | 34 u | 41 u |

**Rules**

- Every manoeuvre's target is in plain view, not hidden by terrain or another obstacle, from at least twice its lead: ≥ 60 u for openings and sidesteps, ≥ 80 u for long dives.
- Consecutive manoeuvres are at least 28 u apart along the line (3.1 s at T 3).
- A piece's whole star line is visible from its entry.

### 3.2 Clearances (ideal line to any solid surface)

| | d 0 | d 0.5 | d 1 |
|---|---|---|---|
| Over (vertical) | 3.0 | 2.5 | 2.0 |
| Beside (lateral) | 4.0 | 3.2 | 2.5 |
| Opening, line to frame | 3.0 | 2.5 | 2.0 |
| Ground under the line | 6 | 5 | 4 |
| Lowest point of a dive moment (arches, barn, hedge hop) | 3.5 | 3.0 | 2.5 |
| Arch span / hoop radius / gap width | 10 / 3.0 / 8 | 8.75 / 2.6 / 6.75 | 7.5 / 2.2 / 5.5 |
| Smallest vertical opening | 5.5 | 5.0 | 4.5 |

For scale:

- The flyer collides as a 0.3 u sphere. It is drawn about 1.3 u across (the plane at `look_scale` 1.3) or 0.7 u (the balloon, whose 1.7 u string never collides).
- The Course's hardest opening, under the lamp, is 2.7 u tall. Endless's solid openings never go below 4.5. Things that only snag (kite hoops, 4.4 across at d 1; the windmill's sail gaps) may be a little tighter, because touching them costs speed, not the run.

### 3.3 Hit areas vs looks

- **Openings** (arches, doors, gates, gaps): the collision hole is 0.3 u bigger than drawn on every side.
- **Round things to fly around** (towers, chimneys, stones, baskets): they collide at 0.9 of their drawn radius. Tree crowns collide at 0.8; trunks as drawn.
- **Leading edges near a line** (pier fronts, door jambs, gate posts, buttresses) are rounded, like the Course's doorway posts, so clipping one glances off.
- **Wires, kite rings, washing and sail lattices are not solid.** They snag (§3.4).

### 3.4 Crash, bump, snag, touchdown

| Event | When | What happens |
|---|---|---|
| **Crash** | Today's rule: into-speed ≥ 3.0 and steeper than 50° | The run ends (unless a soap bubble is up, §8.1). Crumple or pop as today. |
| **Bump** | Any other hard touch | 80% of speed kept, a bounce, a wobble and the tap. The run goes on and the star arc is broken. |
| **Snag** (new, Endless) | Touching a wire, kite ring, washing or sail | Speed × 0.75 (`snag_speed_keep`), a wobble, a flutter sound, the arc broken. **Never a crash** (decision 3). |
| **Touchdown** | The first tick the flyer rests or slides on a floor-like surface (FlightModel `grounded`, normal.y > 0.7) | The run ends there and distance stops. The slide plays out for 0.6 s before the card. A bounce off a slope is not a touchdown. |
| **Splashdown** | Coming down on water | Ends like a touchdown. |

**Fair-failure check.** Every crash line in the logs names the obstacle, and every obstacle is in view at least 4 s before it.

### 3.5 Readability on the phone

The Fold5 cover screen is 904 px tall at 80° vertical FOV, so 11.3 px per degree.

| Thing | Size | Seen from | On screen |
|---|---|---|---|
| Star | 0.9 u | 60 u | 10 px, plus its spinning glint |
| Big star | 2.2 u | 60 u | 24 px |
| Kite hoop | 6 u ring | 120 u | 32 px |
| Viaduct | 22 u tall | 200 u | 71 px (fog 0.61) |
| Arch opening | 10 × 16 | 80 u | 80 × 130 px |
| Plume | 8 × 11 | 150 u | 35 × 47 px |
| Wire | 0.25 u | 40 u | 4 px, so wires carry 1.2 u marker balls (19 px) |

**Colour.** Obstacles are warm pastels against the green: cream stone, rose brick, red and yellow kites. Hazards are darker: rain grey `8d93a6`, water `a9cfe0`.

---

## 4. Stars

### 4.1 Values

| Item | Worth | Points | Drawn | Picked up within |
|---|---|---|---|---|
| Star | 1 ★ | 10 | 0.9 u, gold `f4c84a` with a `fbf3d6` rim, spinning | 1.4 u of the flyer's centre |
| Big star | 10 ★ | 100 | 2.2 u, at the hardest point of a line | 1.5 u |
| Full arc | +5 ★ | 50 | for every star of one arc | |

### 4.2 Placement rules

1. On the ideal line, within 0.5 u, every 5-6.5 u along it (0.6-0.9 s apart).
2. Arcs of 6-15 stars; at most 2 arcs per tile; about 10-12 stars per tile.
3. **Followable on tilt:** turns no tighter than r 8 (70% bank), climbs and dives no steeper than 1 : 3.4 (a half dive).
4. At least 2.0 u from any solid. Big stars in openings are at least 1.5 u from the frame.
5. **A low arc ends in lift** within 15 u of its lowest star (a plume, a thermal or a bank). Taking stars is a risk, never a trap.
6. Stars inside a thermal ride its air and drift with it.
7. Stars on an alternative high line (such as the viaduct's deck) are allowed, but never more than the main line's.

### 4.3 Feedback

- **Pickup:** `star.wav`, a "tink" whose pitch rises a semitone for each star in a row on the same arc (up to +12). It resets on a miss. The HUD counter pops (scale 1.15 → 1.0 over 0.15 s).
- **Full arc:** the style_perfect sparkle and a gold pop-up, "Full arc! +5".
- **Big star:** style_perfect plus a high tink, and a gold pop-up, "Big star! +10".
- **A missed star** dims the rest of its arc to 60%: the arc is broken.

### 4.4 Stars and the style moments

- The Course keeps its ten style moments unchanged.
- **In Endless, arcs replace graded corridors.** The arc *is* the best line, drawn in the sky, and a full arc is Endless's "Perfect". There are no graded style moments in Endless, and no second scoring system to learn.
- Close calls keep their whoosh (feel only).
- Passing through any arch or doorway at ≥ 7.5 u/s also whooshes, with a +3° FOV kick (0.3 s in, 1.0 s out).

---

## 5. Scoring and the end card

- **Distance:** the furthest progress along -Z from the start point, in metres. Shown top right, as in the Course.
- **Stars this run:** stars + big stars + arc bonuses.
  - They are banked at the end of the run, crashes included, times the mission multiplier (×1.0 until step 7).
- **Score** = 10 per metre + 10 per star this run (before the multiplier). It is one number to beat. Distance stays the headline record.
- **Saved** in `user://progress.json`:
  - unlocked, star bank, best distance, best score, last mode;
  - from step 5, owned items, the daily best and the streak.
  - Validated like `BestScore`: size ≤ 4 KB, every field type- and range-checked, anything bad → defaults, never a crash; temp file then rename.
- **HUD:**
  - distance top right, "★ 37" under it;
  - a **height bar** on the left edge (decision 4): 10 px wide, from 25% to 75% of the screen height, filling with mint `9cc48a` for 0-30 u above the ground under the flyer, coral `e8604c` and pulsing at 2 Hz below 4 u.
- **The card:** §1.2.

---

## 6. Difficulty curve

d = clamp(metres / 1,000, 0, 1). In step 1, d = metres / 600 with the wind fixed at 1.5, so the owner reaches d 1 in about 5 minutes.

| | d 0 (0 m) | 0.25 (250 m) | 0.5 (500 m) | 0.75 (750 m) | 1 (1,000 m) |
|---|---|---|---|---|---|
| About when (a skilled run) | start | 2.5 min | 5 min | 7 min | 9 min |
| Tailwind T | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 (+0.1 per 100 m after, cap 3.5) |
| Ground speed at neutral | 7.05 | 7.55 | 8.05 | 8.55 | 9.05 |
| Tile time / height lost with no lift | 13.6 s / 8.4 | 12.7 / 7.9 | 11.9 / 7.4 | 11.2 / 7.0 | 10.6 / 6.6 |
| Thermal R / peak / top | 12 / 4.5 / 26 | 11.5 / 4.25 / 25.3 | 11 / 4.0 / 24.5 | 10.5 / 3.75 / 23.8 | 10 / 3.5 / 23 |
| Thermal life (u drifted, s) | 36, 36 s | 33, 22 s | 30, 15 s | 27, 11 s | 24, 8 s |
| Street / ridge peak | 2.0 / 2.25 | 1.9 / 2.1 | 1.8 / 2.0 | 1.7 / 1.9 | 1.6 / 1.75 |
| Plume R / peak | 4.0 / 6.0 | 3.9 / 5.9 | 3.75 / 5.75 | 3.6 / 5.6 | 3.5 / 5.5 |
| Openings (arch / hoop / gap) | 10 / 3.0 / 8 | 9.4 / 2.8 / 7.4 | 8.75 / 2.6 / 6.75 | 8.1 / 2.4 / 6.1 | 7.5 / 2.2 / 5.5 |
| Clearances over / beside | 3.0 / 4.0 | 2.75 / 3.6 | 2.5 / 3.2 | 2.25 / 2.9 | 2.0 / 2.5 |
| Generator margin | 6 | 5.25 | 4.5 | 3.75 | 3 |
| A rest piece at least every | 3 | 3 | 4 | 4 | 5 |
| Non-lift pieces in a row, at most | 1 | 1 | 2 | 2 | 2 |
| Lake sink | | 0.45 | 0.5 | 0.55 | 0.6 |
| Power-up token every | 5 tiles | 5 | 4 | 4 | 4 |
| First appears | | forks, mere, barn, river | rain, pylons, windmill | windy gap, pine wood | lee rotor |

**Expected run lengths**

| Pilot | Run | Distance | Tiles |
|---|---|---|---|
| Novice, first runs | 45-90 s | 40-80 m | 3-6 |
| Improving | 2-3 min | | |
| Skilled | 4-6 min | 400-600 m | 17-26 |
| Expert | 9+ min | 1,000 m+ | |

---

## 7. The piece library (Downs country)

### 7.1 Summary

need_in and out are heights above the floor at T 1.5.

| # | Piece | Verbs | Tiles | From | Rest | need_in | out | Stars (big) | Step | Numbers |
|---|---|---|---|---|---|---|---|---|---|---|
| L0 | **The Rim** (launch) | — | 1 | fixed | | — | 24 | 8 | 1 | sim |
| P1 | **Cloud Street** | lift | 1 | 0 m | yes | 4 / 6 | min(h+14, 24.5) / min(h+13, 24.5) | 12 | 1 | sim |
| P2 | **Barley Field** | lift (thermal) | 1 | 0 m | yes | 10 | 21 / 17 | 10 | 1 | sim |
| P3 | **Long Ridge** | lift (ridge) | 2 | 40 m | yes | 11 | 27.5 | 16 (1) | 1 | sim |
| P4 | **Hamlet** | lift, through, around | 1 | 30 m | | 11 | min(h+3, 17.5) / min(h+2, 16.5) | 12 | 1 | sim |
| P5 | **Kite Meadow** | through | 1 | 0 m | | 14 | 16 | 15 (1 from d 0.4) | 1 | sim |
| P6 | **Viaduct** | under (over), lift | 1 | 75 m | | 12 | 20.5 / 17.5 | 7 + 3 (1) | 1 | sim |
| P7 | Pasture | over, lift | 1 | 30 m | | 9 | 13 | 13 | 2 | estimate |
| P8 | Washing Lines | under, lift | 1 | 60 m | | 10 | 14 | 12 | 2 | estimate |
| P9 | Poplar Row | through / over | 1 | 100 m | | 10 | h+2 | 5 (1) | 2 | estimate |
| P10 | Dutch Barn | through / over, lift | 1 | 120 m | | 10 | 22 / 20 | 6 + 3 (1) | 2 | sim |
| P11 | Standing Stones | around | 1 | 120 m | | 12 | h-6 | 8 (1) | 2 | estimate |
| P12 | Mere | hazard (sink), lift | 1 | 200 m | | 12 | 20 | 8 + 10 | 2 | estimate |
| F1 | Gorge or Down | fork | 3 | 150 m | | 12 | 18 | low 25 (1) / high 10 | 3 | partly sim |
| F2 | River or Rail | fork (merges at the viaduct) | 3 | 400 m | | 12 | 17 | low 22 (1) / high 8 | 3 | estimate |
| P13 | Warm Down | over, lift (lee rotor from d 0.6) | 1 | 300 m | | 12 | 20 | 10 (1) | 3 | estimate; must calibrate |
| P14 | Rain Shower | hazard, around | 1 | 400 m | | 12 | h-7 | 8 | 4 | estimate |
| P15 | Windy Gap | hazard (gust), through | 1 | 550 m | | 10 | h-6 | 5 | 4 | estimate |
| P16 | Pine Wood | around, hazard (sink), lift | 1 | 600 m | | 12 | 19 | 10 | 4 | estimate |
| P17 | Balloon Fair | around (moving), lift | 1 | 300 m | | 12 | h+2 | 9 | 4 | estimate |
| P18 | Pylons | under / between / over | 1 | 400 m | | 12 | h-7 | 10 (1) | 4 | estimate |
| P19 | Windmill | through (timed, optional), lift | 1 | 450 m | | 10 | 15 | 6 (1) | 4 | estimate |

### 7.2 Step 1 pieces (full spec)

The common scenery on every tile:

- painted fields and hedgerow strips on the floor;
- 8-12 trees on the side slopes (|x| 40-90), never within 6 u of a lift zone or an ideal line;
- a few sheep (not solid);
- the distant-hill ring.

Trees and props follow the Course's palette and builders.

#### L0 The Rim (launch, always first)

| | |
|---|---|
| **Ground** | From the Course's rim at world z -528 (heights from `Course.ground_height(x, -528)`, about 22 local at x 0), the ground rises 4 u more to a rounded crest at local z -6 (about 26). It then falls with a smoothstep to the standard section by local z -72: 26 u down over 66 u, average 21°, steepest about 31°. |
| **Start** | Local (0, 32, -2), which is world (0, 72, -530). |
| **Scenery** | A fingerpost on the crest pointing on ("Onward", looks only). The far slope is open grass with a few gorse bushes off the line. |
| **Stars** | "Welcome": 8 stars every 6.5 u from (0, 30.3, -22) to (0, 26.5, -67.5), on the hands-off glide (12.2 : 1 at T 1.5). Control comes back at about z -13, so the first star is a second away. They weave in a gentle S, x = 3 sin(π (-z - 22) / 22.75), to teach steering for stars. |
| **Ideal line** | The star line, then straight on. |
| **Out** | 24 (32 - 94 u / 12.2). |
| **Why fun** | The third reveal, after the window and the Gap: the whole bowl behind you, then a new country falling away below. The first stars are easy and musical. |

#### P1 Cloud Street (lift, rest)

| | |
|---|---|
| **Ground** | Standard; a patchwork of four painted fields; a painted stream at x -14. |
| **Lift** | A box centred (0, 0, -48), size (16, 26, 80): x -8..8, z -8..-88, top 26. Peak lerp(2.0, 1.6), which is `strength_scale` 0.4 → 0.32. New look **STREET**: warm motes rising in the box (80), no column. |
| **Clouds** | 5 cumulus along x 0 at z -8, -26, -44, -62, -80, base y 30, 3 puffs each (r 4.5-6): a line of clouds. |
| **Stars** | "Street": 12 stars at x 0, z -12 - 6.5k, y 22 + 3k/11 (k = 0..11). |
| **Ideal line** | (0, h, 0) → (0, 22, -12) → (0, 25, -84) → (0, 25, -96), slowing (+0.15) in the lift. |
| **Sim (T 1.5)** | From 26 → 24.6 with 12/12 stars. From 14 → 24.5 (7/12). From 6 → 24.2 at d 0, 19.9 at d 1. |
| **Why fun** | The breather that flows: a ribbon of lift and a ribbon of stars down the middle. It teaches "clouds mean lift" and "slow down in lift". The next piece shows under the street's end. |

#### P2 Barley Field (thermal, rest)

| | |
|---|---|
| **Ground** | Standard; a golden barley field 24 × 24 painted at (C.x, -44). Four round bales (solid, r 1.0, length 1.5) at (C.x ± 12, -32) and (C.x ± 12, -56), outside the circle. |
| **Thermal** | Centre C = (lerp(4, 12), -44): on the straight line at d 0, off to the right later. R lerp(12, 10), peak lerp(4.5, 3.5) (`strength_scale` 0.9 → 0.7), top lerp(26, 23), base on the floor. Look WARM_AIR, outdoors. Drifts with the wind from wake; its life is lerp(36, 24) u. A cumulus (base top + 4) and 3 circling birds follow it. |
| **Stars** | "Spiral": 10 stars on a helix of radius 6 around the thermal's live centre, so they drift with it. The helix starts on the near (+Z) side, turns right (the way the test pilots circle) 36° per star, from y 8 rising lerp(1.9, 1.5) per star. That matches the climb at a full-bank lap (about 0.55 s per star). |
| **Ideal line** | Enter the circle's near edge (C.x, h, -38); circle right at r 6 to (top - 2); glide on to (0, ·, -96). |
| **Sim (T 1.5)** | d 0: from 9-16 → 21-23.4, climb done in 3-6 s, lowest clearance 6.1. d 1: from 10-16 → 17-20.1. At T 3: d 0 → 22-25, d 1 → 18-21. |
| **Why fun** | The climb moment. A helix of stars teaches circling tight and in the core, and pays the pilot who arrives low. The cloud frays as you top out. A novice who just flies straight on at d 0 still gains about +6. |

#### P3 Long Ridge (ridge lift, rest, 2 tiles)

| | |
|---|---|
| **Ground** | The left side becomes a ridge: ground = max(standard, 20 · smoothstep(24, 60, -x) · w(z)), where w ramps in over z 0..-12 and out over z -180..-192. Its plateau is at 20, then the standard side takes over at about x -63. Ground under the line at x -36: 5.2. |
| **Lift** | A box centred (-36, 0, -96), size (20, 30, 176): x -46..-26, z -8..-184, top 30. Peak lerp(2.25, 1.75) (`strength_scale` 0.45 → 0.35). Look RIDGE: 120 seeds (centre y 16, half-height 6), wind-bent grass up the face, 4 hovering birds at (-54, 23, z -30 / -70 / -110 / -150). **The gull joins**, using today's Gull with this box. |
| **Scenery** | A granite tor (5 × 5 × 7, solid) on the face at (-46, ·, -124). Its top is about 20, 10 u to the side of the line and about 6 below it. A big diamond kite flown from the plateau at (-58, 34, -176). |
| **Stars** | "Ridge": 10 stars at x -36 from (-36, 14.5, -36) to (-36, 21.5, -86). "Crest": 6 stars every 6 u from (-36, 26.5, -120) to (-36, 29, -150), following the climb. Big star at (-36, 29, -170), with the kite flying beyond it. |
| **Ideal line** | (0, h, 0) → (-20, ·, -18) → (-34, 14.5, -36) → along x -36, climbing → (-36, 29, -150) → (-36, 29, -176) → (-14, 27.5, -192). |
| **Sim (T 1.5)** | From 10-18 → 27.5-27.6 at d 0 and d 1. Lowest clearance 7.4-11.7. 8/10 Ridge stars. |
| **Event times** | Turn (0-5 s), lift swell (6 s), gull (7.5 s), Ridge arc (7-14 s), gull leaves (14 s), Crest arc (17-20 s), big star (23 s), leave (26-28 s). The longest gap is about 4 s. |
| **Why fun** | The Course's best-loved flight, made long: a smooth climb along a hillside with the gull at your wingtip, ending at the top of the band with a big reserve. |

#### P4 Hamlet (plumes: lift, through, around)

| | |
|---|---|
| **Ground** | Standard; a village green (painted 30 × 60); a cream lane weaving through. |
| **Cottages** | Solid, gabled as `CourseFar._gabled`: footprint 6 (x) × 8 (z), walls 3.5, roof rise 2.5 (ridge at 6). Walls `f2e3d5` / `e3eedf` / `f4dc9b`; roofs `c1675a` / `5f5b70`. Centres C1 (-8, -20), C2 (8, -46), C3 (-8, -72). Each has a solid chimney stack (1 × 1) at its far gable, up to y 8. |
| **Church** | Solid tower 5 × 5 × 11 with a spire to 19, at (lerp(18, 14), -62). It stands 16 u (d 0) to 12 u (d 1) right of the line: the hamlet's landmark, and something to steer round if you swing wide after C2. |
| **Plumes** | A cylinder over each chimney: base y 8, height 11 (top 19), R lerp(4.0, 3.5), peak lerp(6.0, 5.5) (`strength_scale` 1.2 → 1.1). Outdoor smoke look, with its puffs leaning downwind (-Z). Chime pitches 1.0, 1.12 and 1.26: the three plumes play a rising do-re-mi. |
| **Stars** | "Chimneys": 4 in each plume, rising through it: (cx, 12 + k + 0.5i, cz + 3 - 2i) for plume k = 0..2 and i = 0..3. 12 in all. |
| **Ideal line** | (-8, 12, 0) → (-8, 12, -16) → (-8, 13, -27) → (8, 13, -44) → (8, 14, -53) → (-8, 14, -70) → (-8, 15, -79) → (0, 15, -96). A 16 u weave every 26 u, comfortable at T 1.5-3. |
| **Sim (T 1.5)** | From 10-13 → 14.6-14.7 with 10-12/12 stars. Lowest clearance 10. A shaky pilot (wobble 0.3) gets 83-100% of the stars. |
| **Why fun** | A rhythmic slalom low over rooftops: whoosh up, whoosh up, whoosh up, with the do-re-mi chimes and smoke puffs flashing past. |

#### P5 Kite Meadow (through)

| | |
|---|---|
| **Ground** | Standard; a festival meadow; 4 striped tents (4 × 4, 3 tall with peaks at 4.5, solid) at x ±22, z -20 and -70, off the line; 5 small figures holding kite strings. |
| **Lift** | A weak street: box (0, 0, -48), size (18, 26, 84), peak lerp(1.4, 1.1) (`strength_scale` 0.28 → 0.22). About enough to hold height. Three small clouds. |
| **Hoops** | 5 ring kites, static (no bob). Centres K1 (0, 20, -16), K2 (5, 19, -32), K3 (8, 18, -48), K4 (4, 17, -64), K5 (-2, 16, -80). Inner radius lerp(3.0, 2.2), tube drawn 0.3. Each faces along the line. Colours `e8604c`, `f6c66f`, `a9c8e8`, `b9a6dc`, `9cc48a`, each with a 6-bow ribbon tail fluttering downwind and a string to a figure. |
| **Snag, not solid** | Touching a ring tube snags (§3.4). Passing through a ring (crossing its plane within the inner radius) rings a bell (the chime, pitch 1.0 + 0.12 per hoop) and flashes the ring white for 0.2 s. |
| **Stars** | "Hoops": 3 in each hoop, at its centre and ±1.2 u along its axis. 15 in all. From d 0.4, K5 holds a big star instead of its 3. Threading all 5 shows "Hoop run! +5" (the arc bonus). |
| **Ideal line** | (0, 20, 0) → K1 … K5 → (-4, 16, -96). |
| **Sim (T 1.5)** | From 17-22 → 16. A shaky pilot gets 83-96% of the stars at T 1.5 and 55-61% at T 3. |
| **Why fun** | Pure arcade: a slalom of bright rings with bells, readable from 120 u. A gentle dive gives a touch of speed, and a miss costs only speed. |

#### P6 Viaduct (under, or over; then a thermal)

| | |
|---|---|
| **Ground** | Standard; a river painted 6 wide along x 0, meandering ±2; a pale shingle bank painted 20 × 20 at (0, -82). |
| **Viaduct (solid)** | Across the valley at z -56 (faces at -53 and -59, 6 deep). Deck top 22, parapets 1.2 (to 23.2). From x -80 to 80; it runs into the hillsides where the side passes 22 (beyond x ±65). Stone `e9d7b6`, voussoirs `c9b393`. |
| **Arches** | 5 arches over the floor, centred x 0, ±12.5 and ±25. d 0: span 10, springing 11, crown 16. d 1: span 7.5, springing 9, crown 12.75 (pier centres fixed, piers widening from 2.5 to 5). Smaller decorative arches carry on up the slopes. Each pier's upstream face has a half-cylinder cutwater up to the springing, so clipping a pier glances off. The collision hole is 0.3 u bigger than drawn. |
| **Thermal (recovery)** | "The shingle bank": centre (0, -82), R lerp(11, 10), peak lerp(4.25, 3.5), top lerp(24, 22). It drifts; its near edge is 12 u past the viaduct's far face. A cloud and 3 birds. |
| **Stars** | "Dive": 7 stars every 6 u from (0, 19, -10) down to (0, 9, -46), a 1 : 3.6 dive. Big star at (0, 8.5, -56), the centre of the middle arch, below the springing. "Deck": 3 stars at (0, 25.5, -52 / -56 / -60) for anyone who arrives high enough to go over. |
| **Arch pass** | Through an arch at ≥ 7.5 u/s: whoosh, wind swell (+5 dB over 0.5 s) and a +3° FOV kick. |
| **Ideal line** | (0, h, 0) → (0, 19, -10) → (0, 9, -46) → (0, 8.5, -56) → (0, 8, -70); circle right at r 6 to (top - 2); glide on. |
| **Sim (T 1.5)** | d 0: from 10-26 → 19.0-20.6. d 1: from 12-26 → 16.5-17.8. Lowest clearance 6.6. Through the arch at 9.5-10.5 u/s, 3-6 u under the crown. Arriving at 26 is fine: a firm half dive. At T 3 the climb ends about 5 u into the next tile (inside its buffer). |
| **Fairness** | Arriving between the crown and 25 needs a dive. The viaduct is in view from 200 u (fog 0.61), which is 26 s away at T 1.5. Its faces are crash surfaces (head-on); the pier noses glance. |
| **Why fun** | Endless's stair dive: a long dive at a big, readable target, speed building to 10 u/s, the arch rushing past with a whoosh, then a thermal catching you. Fear, then relief. |

#### Step 1 table for the generator (T 1.5, d 0 / d 1)

| Piece | Lift? | Rest? | min_m | need_in | out(h) |
|---|---|---|---|---|---|
| Cloud Street | yes | yes | 0 | 4 / 6 | min(h+14, 24.5) / min(h+13, 24.5) |
| Barley Field | yes | yes | 0 | 10 | 21 / 17 |
| Long Ridge (2 tiles) | yes | yes | 40 | 11 | 27.5 |
| Hamlet | yes | no | 30 | 11 | min(h+3, 17.5) / min(h+2, 16.5) |
| Kite Meadow | no | no | 0 | 14 | 16 |
| Viaduct | yes | no | 75 | 12 | 20.5 / 17.5 |

A sample run at d 0, margin 6:

| Piece | Check | h after |
|---|---|---|
| Rim | | 24 |
| Street | | 24.5 |
| Kites | 20 ≤ 24.5 | 16 |
| Barley | 16 ≤ 16 | 21 |
| Hamlet | 17 ≤ 21 | 17.5 |
| Ridge | 17 ≤ 17.5 | 27.5 |
| Viaduct | 18 ≤ 27.5 | 20.5 |
| … | | |

After the Hamlet, the Viaduct (needs 18) and the Kites (needs 20) are held back until a lift piece has run.

### 7.3 Step 2-4 pieces (key numbers; the lead calibrates)

**P7 Pasture** (over, step 2)

- Three hedgerows across the floor at z -24, -50 and -76: heights 2.5 / 3.0 / 3.5, 1.5 thick, rounded tops, solid.
- Each has a field gate (a gap 6 → 4.5 wide) at x -6, +8 and -2.
- A garden bonfire plume at (6, -88): R 4.5, peak 6.5, from y 1 to 19.
- Stars:
  - "Hedge-hop": 9 stars, 3 skimming lerp(3.0, 2.0) u over each hedge top (y 5.5 / 6 / 6.5 at d 0);
  - 4 more rising through the bonfire plume (8 → 14).
- The two lines:
  - The safe line stays at 9+ and exits at h - 8.
  - The bold line dives to 5-6, skims the hedges and climbs out of the plume to about 13.
  - From an entry at 20 both end near 13, so the stars are free if you fly it well.
- Why fun: low and fast over hedges, with the ground rushing past and close calls on the tops.

**P8 Washing Lines** (under, step 2)

- Three cottage gardens, with washing lines across the line at z -30, -50 and -70.
- Lines at 7.5, posts at x ±10, sheets hanging to 6.0 with gaps.
- Under at 3-4.5 for 9 stars (a 6 u opening between grass and sheets); over at 9.5+ to be safe.
- Lines and sheets **snag**, and a sock flies off.
- A wash-house chimney plume at (0, -86): R 4, peak 6.0.

**P9 Poplar Row** (through or over, step 2)

- 21 columnar poplars across at z -50, every 4 u from x -40 to 40.
- Crowns r 1.6 from y 2 to 14, colliding at r 1.4.
- One gap at x 6: 8 u wide at d 0, 5.6 at d 1.
- A street before it (z -8..-40, peak 1.8) sets up height.
- 5 stars through the gap at y 10, then a big star at d ≥ 0.5.
- Over needs 17+.

**P10 Dutch Barn** (through or over, step 2; sim-checked at T 1.5)

| | |
|---|---|
| **Barn** | An open barn across the line at z -40..-60: 14 wide, walls 9, barrel roof to 12. Both ends open: doorways 8 wide × 8 tall at d 0, 6 × 5.5 at d 1, with rounded jambs. Hay bales stacked along the inside walls, lanterns. |
| **After it** | A steaming muck-heap thermal at (0, -76), R 10, peak lerp(4.0, 3.5), top lerp(24, 22). |
| **Stars** | 6 diving from (0, 15, -10) to (0, 6, -36); a big star inside at (0, 4, -50); 3 on the way out. |
| **Lines** | Through at 4.2 → 3.6 (3.8 or more under the lintel at d 0, 3.6 or more above the barn floor), or over at 15+. Inside, the barn floor is ground: touching it is a touchdown. |
| **Sim (T 1.5, 7-tall doors)** | From 10-18 → 23.2-23.3. Lowest clearance 3.0, inside the barn; that is why the d 0 doors are now 8 tall. |
| **Why fun** | In one door, out the other. Dark, fast, then daylight and a lift. |

**P11 Standing Stones** (around, step 2)

- A ring of 11 stones (2 × 1 × 6-8 tall) of radius 12 at (0, -50), with 6 u gates between them.
- A big star at the centre at y 4: fly in through a gate and out through the opposite one.
- 8 stars curve in and out.
- A thermal beside it at (-16, -84) recovers.

**P12 Mere** (hazard, step 2)

- A lake filling the floor: an ellipse at (0, -50) with radii (24, 34), water at -1.
- An island at (-4, -56), r 6, with a warm-sand thermal: R 10, peak 4.0, top 24.
- Lake sink over the water: peak lerp(0.4, 0.6), with today's sink ticks.
- A sailboat circles.
- Stars: 8 across the water, then the 10-star helix over the island.

**F1 Gorge or Down** (fork, step 3)

*Split tile:* the spine rises from the nose.

*Branch tile:*

- **Low road** (left), a gorge:
  - floor 14 wide at x -18, walls 24 tall and steep, with rounded rims;
  - 3 footbridges across it (decks 1.2 thick) at y lerp(8, 6.5), at z -24, -48 and -72;
  - 3 stars under each bridge (y 4.5-5) and a big star under the middle one;
  - weak gorge lift: a box 12 wide along the floor, peak 1.0;
  - a lime-kiln plume at its mouth: R 4.5, peak 6.5, from y 3 to 21.
- **High road** (right): rising open downland (floor up to 10) with a chalk-scar thermal (R 12, 4.5, top 28) and 4 stars at its top.

*Merge tile:* the spine ends; a quarry thermal at the gorge mouth (-12, -30): R 11, 4.25, top 24.

| Sim of the gorge tile alone (T 1.5) | From 7-12 → 11.8-12.4 at the kiln | lowest clearance 5.3 | 6-9/9 stars |
|---|---|---|---|

The quarry thermal is what makes the low road fair. Fork totals: need_in 12, out 18.

**F2 River or Rail** (fork, step 3)

- **Low road:** the river, cut 3 deep (water at -3), with 3 humpback bridges.
  - Arch crowns at 5.5 above the water, decks at 4.5.
  - 3 stars under each arch and a big star under the last.
  - A river cliff on the left, 12 tall, with bank lift: box (-12, 0, -60), size (10, 20, 60), peak 2.5.
- **High road:** a railway on an embankment, and a station where a standing engine blows off steam: a plume R 5, peak 7.0, from y 8 to 26. 5 stars over the station canopy.
- **Merge tile:** the Viaduct (P6). The river goes under it, the railway over it.

**P13 Warm Down** (over, step 3)

- A low down across the valley:
  - crest 14, with a saddle of 10 at |x| < 12 (24 wide);
  - near face from z -36 to -60;
  - far side down to 0 by -84.
- A thermal on the face at (0, -44): R 12, peak lerp(4.5, 4.0), top lerp(28, 26). It drifts over the crest (life 30 u) and carries you over.
- Stars: the helix (10), plus a big star low over the saddle at (0, 13, -60).
- From d 0.6, a **lee rotor**: sink -1.0 behind the crest (box x -28..28, y 0..16, z -62..-84), shown by tumbling leaves and the ticks.
- **Caution from my sims:** a steeper cross-valley hill (crest 22, face lift only) left the pilot 1-3 u of clearance, and some flights touched down. Keep crests ≤ 14 with a thermal in front until this calibrates.

**P14 Rain Shower** (hazard, step 4)

- A dark cloud (puffs `8d93a6`, base 24, R 14) at (-8, -48).
- Sink under it: a cylinder R 14, peak -1.5, from the floor to 24.
- Cues: 60 grey rain streaks falling at 8 u/s, a soft hiss within 40 u, a darker shadow painted on the ground.
- Clear air at x 8..28.
- 8 stars curve round its right side.
- Straight through its core costs about 4-5 u more than going round.

**P15 Windy Gap** (hazard, step 4)

- Two chalk buttresses (x ±12..±30, 30 tall) narrow the valley to a 24 u gap at z -40..-56.
- A crosswind gust in the gap: horizontal air (-2.5, 0, 0) over z -42..-54, plus -0.5 sink. It uses the same air-mass drift as the tailwind.
- Cues: 80 leaves streaming -X through the gap, flags on both buttresses, a gust whoosh on entry.
- Uncorrected drift is about 4 u. The line runs at x +3 to allow for it, and 5 stars sit there.

**P16 Pine Wood** (around and hazard, step 4)

- Pines 10-14 tall every ~5 u fill the floor, with canopy sink -0.3.
- A straight forest ride 10 wide along x 0, where you can fly under the canopy at 5-7 for 6 stars.
- A sawmill clearing at the end with a thermal: R 10, 4.0.

**P17 Balloon Fair** (moving, around, step 4)

- 3 hot-air balloons (envelope r 5, basket 2 × 2 × 1.5) drifting at the wind's speed, at y 12 / 18 / 14 and z -30 / -55 / -80, rising and falling ±1 u/s.
- The envelope is a soft bump; the basket is solid but small.
- Burner lift above each envelope: R 3, peak 6, 1-9 u above its top.
- 3 stars arc over each balloon.

**P18 Pylons** (step 4)

- Lattice pylons 26 tall at x ±40 and one at x 0 (solid core 1.5 × 1.5).
- Three wires sagging to y 12 / 16 / 20 at the centre, with 1.2 u marker balls every 8 u on the top wire. The wires snag.
- 5 stars under at y 8; 5 between the lower wires at 14, for experts; a big star in the gap beside the middle pylon.

**P19 Windmill** (step 4)

- A post mill on a knoll beside the line at (20, -50).
- Hub at y 14; 4 sails of radius 7 turning at 0.5 rad/s. The gap between sails at r 3.5 is 3.9 u wide and comes round every 3.1 s.
- A big star in the sail disc. Optional and timed. The sails snag.
- The miller's cottage plume to recover.

**Also in step 4:** a train runs over the viaduct every 20 s (4 u/s across), with a moving steam plume (R 4, peak 6) above the deck, for the high road.

---

## 8. Power-ups, Hangar, missions, daily flight, countries

### 8.1 Power-ups (step 6; swallows in step 8)

**How they appear.** A token sits at an arc's midpoint, in place of a star, every 5 tiles (d < 0.5) or 4 tiles (d ≥ 0.5).

- Picked: pinwheel 35%, sun puff 30%, soap bubble 25%, swallows 10% once unlocked.
- Each token is a small glowing paper lantern (opaque, unshaded cream) with its icon inside. Pickup radius 1.6 u.
- **They act at once.** There is no button: a tilt game keeps both hands on the phone.
- Different power-ups stack; picking up the same one again refreshes it.
- The active one shows as an icon with a shrinking ring, top left.

| Power-up | What it does | L1 (free when first found) | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|---|
| **Pinwheel** (star magnet) | A paper pinwheel spins on your nose or string; stars within 5 u fly to you | 8 s | 11 s | 14 s | 17 s | 20 s |
| **Sun puff** (updraft burst) | Warm air under you: 6 u/s for the time shown | 1.2 s (+6 u) | 1.5 s (+8) | 1.8 s (+9.5) | 2.1 s (+11) | 2.5 s (+13) |
| **Soap bubble** (shield) | Absorbs one crash or touchdown: you bounce off (+3 u, 80% speed) and the bubble pops | 20 s | 30 s | 40 s | 50 s | 60 s |
| **Swallows** (guide, step 8) | A V of swallows flies you along the ideal line: tilt ignored, invulnerable, stars collected | 6 s | 7.5 s | 9 s | 10.5 s | 12 s |

Upgrade prices for L2 / L3 / L4 / L5: **150 / 400 / 900 / 2,000 ★** each.

**Second wind** (on the end card, not found in the air)

- Offered for 4 s after a crash, touchdown or splashdown, if the run passed 50 m and the bank can pay.
- Price per run: **50, 100, 200, 400 ★**.
- You come back at the last safe point: the most recent point on the ideal line at least 20 u behind where the run ended, at least 10 u above the ground and 8 u from solids. Height = max(line, need_in + 4).
- You are held 1.0 s with a soft countdown ring, then released (re-calibrated).
- Distance carries on.

### 8.2 Hangar (step 5)

- Opened from the card's [Hangar]. A full-screen panel in the same cream-and-lilac theme.
- Header "Hangar ★ 1,204". Tabs: **Looks**, **Power-ups**, **Countries**, **Missions**.
- Cards show an icon drawn in code, a name, and a price or "Owned" / "Wearing".
- Buying: tap a card, then "Buy Polka dots for ★ 600?" with [Buy] [Not now]. Owned items get [Wear].
- **Power-ups** show level pips (●●○○○) and the next level ("14 s → ★ 900").
- **Countries** you own get [Start here].
- **Missions** shows the three current missions with progress bars, and the multiplier.

### 8.3 Missions (step 7)

- Three at a time. Each pays stars when done.
- **Finishing all three raises the star multiplier by +0.25**, from ×1.0 up to a cap of ×2.0 after 4 sets (decision 6).
- After the 18 below, a repeating ladder of the same kinds: distance +200 m, stars +50 and counts +1 per round, rewards +25%.

| Set | Mission | ★ |
|---|---|---|
| 1 | Fly 75 m in one run | 25 |
| 1 | Collect 25 stars in one run | 25 |
| 1 | Complete a full arc | 50 |
| 2 | Fly under the viaduct | 50 |
| 2 | Have the gull join you on the Long Ridge | 50 |
| 2 | Thread 5 kite hoops in one run | 75 |
| 3 | Fly 200 m in one run | 75 |
| 3 | Fly through all three plumes in a hamlet | 75 |
| 3 | Climb 15 u in one thermal | 75 |
| 4 | Take the low road at a fork | 100 |
| 4 | Collect a big star | 75 |
| 4 | Fly through the Dutch barn | 100 |
| 5 | Fly 400 m in one run | 150 |
| 5 | Collect 100 stars in one run | 150 |
| 5 | Three close calls in one run | 100 |
| 6 | Take the high road at a fork | 100 |
| 6 | Use 3 power-ups in one run | 125 |
| 6 | Fly the daily flight | 100 |

### 8.4 Daily flight (step 5)

- **Seed** = a hash of the phone's local date, "YYYY-MM-DD". Everyone on the same app version gets the same country that day: the Downs, the same pieces, power-ups and stars. Nothing goes online.
- Opened from the card's [Daily] (it shows today's best). Otherwise it flies like any run.
- **Rewards:**
  - +100 ★ for the first run of the day that reaches 100 m;
  - +20 ★ more for each day the streak has already run, up to +100 (so 100, 120, 140 … 200).
- **The clock:** the save keeps the last date paid. A date at or before it never pays again (decision 8).

### 8.5 Countries

**Coast** is in step 8:

- sea-cliff ridge runs with the sea beyond;
- a lighthouse to fly around;
- a pier to fly under;
- a harbour of masts with a smokehouse plume;
- dune thermals;
- a bay with sea sink;
- a chalk sea arch to fly through;
- an opening off a cliff top.

**Mountains** (gorges, waterfall spray as sink, a cable car, snowfield thermals, strong ridges, lee sink) and **Town at dusk** (rooftop chimney rows, spires, canal bridges, string lights, a market bonfire, warm windows) come in a later phase (decision 10).

**A country** is a palette, an opening, and 8-10 pieces: about half reskinned Downs pieces and half its own. You pick the starting country in the Hangar.

---

## 9. Economy

**Prices (★)**

| Group | Items | Total |
|---|---|---|
| Balloon colours | Sky blue 75, Sunflower 75, Mint 150, Lilac 150 | 450 |
| Balloon patterns | Candy stripes 400, Polka dots 600, Starry night 1,500, Rainbow 3,000 | 5,500 |
| Paper designs | Notebook lines 100, Graph paper 200, Newspaper 500, Old map 1,000, Washi pattern 2,000 | 3,800 |
| Trails | Ribbon 300, Dandelion seeds 800, Soap bubbles 1,500, Paper confetti 2,500 | 5,100 |
| Power-up upgrades | 4 power-ups × (150 + 400 + 900 + 2,000) | 13,800 |
| Countries | Coast 3,000, Mountains 5,000, Town at dusk 7,500 | 15,500 |
| **Catalogue** | | **44,150** |
| Second wind | 50 / 100 / 200 / 400 per run | an ongoing sink |

The red balloon and the plain paper plane are owned from the start.

**Stars per tile.** The library averages about 10.3 small stars and 4.3 ★ of big stars per tile, plus about 1.1 arcs.

| Pilot | Small stars | Big stars | Full arcs | ★ per tile |
|---|---|---|---|---|
| Novice | 35% | 5% | 5% | about 4 |
| Skilled | 75% | 50% | 35% | about 11.7 |

**Stars per run (before the multiplier)**

| Pilot | Run | Tiles | ★ per run |
|---|---|---|---|
| Novice, first runs | 45-90 s | 3-6 | 15-35 (including about 4 from the Rim) |
| Improving | 2-3 min | 9-14 | 60-100 |
| Skilled | 4-6 min | 17-26 | 200-300 |
| Expert | 9 min | 40+ | 500+ |

**A casual player** (15 minutes a day, 5 days a week, improving). The daily streak breaks each weekend, so the daily bonus averages about 140 a day.

| Week | Runs a day × ★ | Multiplier | Missions + daily a day | ★ a day | Total by week's end |
|---|---|---|---|---|---|
| 1 | 10 × 30 | ×1.0-1.25 | 60 + 140 | about 530 | 2,650 |
| 2 | 7 × 80 | ×1.5 | 50 + 140 | about 1,030 | 7,800 |
| 3 | 5 × 140 | ×1.75 | 40 + 140 | about 1,405 | 14,800 |
| 4 | 4 × 200 | ×2.0 | 25 + 140 | about 1,765 | 23,600 |
| 5-6 | 4 × 230 | ×2.0 | 25 + 140 | about 2,005 | 33,600 / 43,600 |

**Milestones**

- **First purchase:** Sky blue (75 ★) after run 2-3. A first run gives about 25 ★, and set 1's missions pay 100.
- **First country:** Coast in week 2.
- **Everything:** about 6 weeks, a few days more with second-wind spending (about 10%).
- **A keen player** (30 minutes a day): about 3-4 weeks. Runs double, but missions and the daily bonus don't.

---

## 10. Build steps (each ends with something the owner can fly)

### 10.1 Step 1: the prototype (full spec)

**Question it answers:** is endless gliding fun on the phone? It comes before any Hangar or economy work.

**In scope**

1. The Endless scene, unlocking (§1.1), both end cards (§1.2), the look-back opening (§1.3), the in-place retry (§1.4) and the boot scene (§1.5).
2. Tiles, streaming and prebuilt meshes (§2.1-2.2, §2.7, without recentring).
3. The tailwind (constant 1.5) and Endless thermal drift with life (§2.3).
4. The generator (§2.5) with the step 1 table (§7.2) and D_FULL 600 m.
5. The Rim plus the six pieces in §7.2.
6. Stars, big stars and arcs (§4), with `star.wav`.
7. Snags (for the kite rings) and touchdown endings (§3.4).
8. HUD: distance, stars and the height bar (§5).
9. Saving: unlocked, star bank, best distance, best score, last mode (§5).
10. Reused unchanged:
    - vario beeps, sigh and sink ticks;
    - the gull on the Long Ridge;
    - clouds and birds (fed from tiles);
    - wind sound, close calls and the swap look.
11. Debug builds:
    - [Wind 0 / 1.5 / 3.0] on the card;
    - F3 or an fps tap shows the ideal lines, each tile's need_in/out, d, T and h;
    - the PERF line adds the tile and piece name.

**Out of scope for step 1:** the rising wind, recentring, forks, hazards, power-ups, the Hangar, missions, the daily flight, countries, the train, the best-distance marker.

**Suggested files.** These are the lead's call.

- `scenes/endless.tscn`.
- `scripts/endless/`:
  - `endless_game.gd`: run flow, HUD, card, sound; modelled on `game.gd`;
  - `endless_world.gd`: ground, tiles, streaming, generator;
  - `pieces.gd`: the library's layout constants, builders and metadata;
  - `stars.gd`: the MultiMeshes, pickup and arcs.
- `scripts/progress.gd`.
- `scenes/boot.tscn` with `scripts/boot.gd`.
- `tests/test_endless.gd`.
- `tools/endless_log.gd`: `--pilot=skilled|shaky|novice`, `--runs`, `--seed`, `--wind`, `--calibrate`.
- `gen_sounds.py`:
  - `star.wav`: 0.16 s; sines at 1,568 Hz, plus 0.35 × 3,136 Hz and 0.15 × 4,704 Hz; 2 ms attack; exponential decay with a 45 ms time constant; peak -8 dBFS.
  - `flutter.wav`: 0.3 s of noise band-passed 600-2,400 Hz, amplitude-modulated at 22 Hz and decaying; peak -10 dBFS.

**What changes in today's files**

- `flyer.gd`: an optional horizontal air drift with the ground fade, zero by default. The Course behaves identically.
- `thermal.gd`: Endless drift (a direction, a speed and a life). The Course's drift is unchanged.
- `game.gd`: the Course card's Endless button and unlock line, and writing the unlock. Nothing else.
- `project.godot`: the boot scene becomes the main scene.

**New `tuning.gd` group "Endless"**

| Field | Value |
|---|---|
| `endless_wind` | **1.5** u/s toward -Z (step 2 replaces it with `_start` 1.0, `_full` 3.0, `_max` 3.5) |
| `endless_wind_ground_fade` | **4.0** u |
| `endless_full_distance_m` | **600** (1,000 from step 2) |
| `endless_margin` | **(6, 3)** at d 0 / d 1 |
| `endless_thermal_life` | **(36, 24)** u drifted |
| `endless_thermal_fade` | **4.0** s |
| `endless_tiles_ahead` / `_behind` | **5 / 1** |
| `endless_tile_fade` | **(440, 60)** u: visibility end, fade margin |
| `endless_intro_seconds` | **1.4** |
| `endless_retry_fade` | **0.2** s |
| `endless_card_delay_touchdown` | **0.6** s |
| `star_pickup_radius` / `big_star_pickup_radius` | **1.4 / 1.5** u |
| `big_star_value` / `arc_bonus` / `points_per_star` | **10 / 5 / 10** |
| `star_db` / `star_pitch_steps` | **-10** dB / **12** semitones |
| `snag_speed_keep` | **0.75** |
| `height_bar_full` / `height_bar_warn` | **30 / 4** u |
| `arch_pass_fov_kick` | **3.0°** |

Per-piece numbers live in `pieces.gd` as (d 0, d 1) pairs, like Course's constants block.

**What the owner flies.** Land the Course once, tap Endless, and see the bowl behind you and the new country ahead. Then fly street, field, ridge, hamlet, kites and viaduct in a different order every run, until a touchdown or a crash. Tap and go again.

**Phone checklist for step 1**

1. **Pace:** fly 3 runs each at wind 0, 1.5 and 3.0 (debug button). Which feels best? Is 3.0 too fast to steer?
2. Can you follow a star arc on tilt? Hamlet and Kites are the tests.
3. Is the viaduct dive the thrill? Too easy or too scary?
4. Do the kite hoops at r 3.0 (start) and r 2.2 (after about 5 minutes) feel fair?
5. Did every run end for a reason you understood?
6. Is the retry fast enough?
7. Frame rate: 120 fps target; PERF lines in the hamlet smoke, the viaduct dive, circling the barley field and the reveal.
8. Is the height bar useful, or clutter?

### 10.2 Step 2: pace and variety

- The rising wind (§2.3) and the full difficulty curve to 1,000 m (§6).
- Recentring (§2.7).
- Six pieces: P7 Pasture, P8 Washing Lines, P9 Poplar Row, P10 Dutch Barn, P11 Standing Stones, P12 Mere.
- **A best-distance marker:** a line of pennants across the valley where your best run ended, with a chime and "Past your best!" as you cross it.
- The calibration table re-measured at T 1.0-3.0.
- Flies: 12 pieces with rising pace.

### 10.3 Step 3: forks and the low hill

- F1 Gorge or Down and F2 River or Rail (merging at the viaduct).
- P13 Warm Down, calibrated before it ships.
- Fork choices logged ("low road" / "high road").
- Flies: path choice every 6-10 pieces.

### 10.4 Step 4: hazards and movers

- P14 Rain Shower, P15 Windy Gap (local horizontal air), P16 Pine Wood, the lee rotor on P13.
- P17 Balloon Fair, P18 Pylons, P19 Windmill, and the viaduct train.
- A third fork, Wood or Water: P16 against P12 side by side.
- Flies: the full Downs country.

### 10.5 Step 5: progress, Hangar (looks) and the daily flight

- The save grows (validated); the Hangar's Looks tab.
- Balloon colours as vertex colours, patterns as vertex-colour bands, paper designs as small code-drawn textures, trails as ribbons or particles.
- The daily flight (§8.4).
- Flies: spending stars and a daily run.

### 10.6 Step 6: power-ups

- Pinwheel, sun puff and soap bubble; tokens; upgrades in the Hangar; second wind.
- Flies: runs with power-ups.

### 10.7 Step 7: missions

- The 18 missions and the ladder, the multiplier, the missions line on the card and the Hangar tab.

### 10.8 Step 8: swallows and the Coast

- The swallows power-up: a game-side line follower, like the test Autopilot.
- The Coast country: 8 pieces and its opening.
- Mountains and Town at dusk follow in a later phase.

---

## 11. Test marks (for the step reviews)

**Pilots.**

- **Skilled:** the Autopilot on the ideal lines with its orbits, steady hands.
- **Shaky skilled:** wobble 0.15, reaction 0.15 s (as in fun review 4).
- **Novice:** `Autopilot.novice` on the ideal lines, circling at most 1 lap per thermal.
- Wind 1.5 unless a mark says otherwise. Each mark is checked by tests or the `endless_log` tool.

### Step 1

1. **The Course is untouched.**
   - All existing tests pass.
   - Every Course route (lavender, picnic, ridge, chain, gap, lake, bluff) and novice ×10 logs the same times (±0.1 s) and scores as before.
2. **Unlock.** A Course run resting outdoors, not crashed, sets unlocked. A crash in the house does not. The save survives a corrupt file (falls back to defaults).
3. **Retry.** From the crash signal to physics flying again ≤ 2.0 s with a scripted tap at +0.5 s. The in-place reset itself ≤ 0.3 s on PC.
4. **The generator.**
   - 10,000 sequences of 30 pieces (random seeds, d 0..1): 0 lift-rule violations (h - margin ≥ need_in everywhere).
   - No piece repeated within 2.
   - Never more than the allowed non-lift run.
   - A rest piece within every R.
   - Every sequence starts Rim, Street.
5. **Calibration.**
   - Each piece flown alone by the skilled pilot from need_in and from 26, at d 0, 0.5 and 1 and T 0, 1.5 and 3.
   - No touchdown or crash; ground clearance ≥ 4 on the line (≥ 3 at the lowest point of a dive moment); ≥ 2.0 from any solid.
   - Its out is within ±1.5 of the table.
6. **Skilled.** 20 generated sequences of 12 pieces: 0 crashes, 0 touchdowns, ≥ 85% of stars.
7. **Shaky skilled.** At least 18 of 20 survive 12 pieces; ≥ 70% of stars.
8. **Novice.** 20 runs:
   - median 45-90 s;
   - at least 15 of 20 get past 3 pieces after the Rim;
   - 25-50% of stars;
   - every ending is logged with a named cause (the obstacle, or "ran out of height over <piece>").
9. **Cadence.** In skilled logs, the median gap between events is 2-4 s and the longest is ≤ 5 s.
   - Events: a piece entered, lift in or out, an arc started or finished, a big star, an obstacle passed (with its clearance), a snag, a bump, the gull.
10. **Stars and arcs.**
    - Unit tests: pickup within 1.4 u and not at 1.5; a full arc pays +5 exactly once; a missed star breaks its arc; stars in a thermal move with its drift.
    - The bank and best distance save and load; out-of-range values load as 0.
11. **Wind.**
    - At T 1.5 a hands-off glide covers 12.2 u per unit of height (±0.3).
    - Within 4 u of the ground the drift fades: the flyer slides to rest on flat ground within 3 s.
    - At T 0, Endless thermals never fade.
12. **Fair failure.** No solid within 2.0 u of any star. No obstacle face on a line hidden from view less than 60 u before it.
13. **Performance.**
    - PC captures at 60 fps at the reveal, circling the barley field, in the hamlet smoke, through the viaduct, and along the ridge with the gull.
    - Draw calls ≤ 43 and primitives ≤ 50k in view.
    - No frame over 16.7 ms during tile spawns (PC).
    - On the Fold5, the owner checks 120 fps with GPU ≤ 7 ms on average.

### Steps 2-4

- Marks 4-9 again on the full library.
- **Survival:**
  - shaky skilled survives ≥ 20 pieces from 0 m in ≥ 80% of 20 runs;
  - shaky skilled survives ≥ 10 pieces starting from 500 m in ≥ 50%;
  - novice median stays 45-90 s.
- **Forks:**
  - both branches flown 20/20 by shaky skilled with no touchdown;
  - the low road pays ≥ 2× the stars of the high road;
  - the high road exits ≥ 4 u higher.
- **Hazards:**
  - straight through the rain cloud's core costs 4-7 u more than going round, never more than the margin;
  - an uncorrected pilot centred in the Windy Gap drifts ≤ 6 u and never touches;
  - lee rotor sink only from d 0.6, always with leaves and ticks.
- **Recentring:** a 2,000 m scripted flight crosses 2 recentres with no jump in distance, position or camera (< 0.01 u) and no lost stars or zones.

### Steps 5-7

- The daily flight: the same date gives an identical sequence twice; the next date differs; a date at or before the last paid one pays nothing.
- **Economy sim** (scripted, offline, from the expected stars per run in §9):
  - a novice profile buys its first item by run 4;
  - set 1 finishes within 5 novice runs;
  - the casual profile owns the whole catalogue in 25-45 play-days.
- **The save** (stars, items, levels, missions, streak) passes fuzzed corrupt-file tests: no crash, defaults, never negative stars.
- **Power-ups:**
  - the soap bubble turns one crash into a bounce and is gone;
  - the sun puff gains within ±1 u of the table;
  - the pinwheel pulls only stars within 5 u;
  - second wind places the flyer ≥ 10 u above the ground and ≥ 8 u from solids, every time.

---

## 12. Decisions for the owner

1. **A tailwind that rises with distance**, from 1.0 to 3.0 u/s (§2.3).
   - It is the runner's rising speed, without touching how the balloon or plane flies. You can never turn back for a missed star.
   - **Recommend yes.** Step 1 has a debug button so you can compare 0 / 1.5 / 3.0 on the phone first.
2. **Any touchdown ends the run**, even a gentle landing. Bounces off slopes don't.
   - **Recommend yes:** it is simple, and it makes height the health bar.
3. **Wires, kite rings, washing lines and windmill sails snag** (lose speed) instead of crashing you.
   - **Recommend yes:** a kids' game shouldn't end on a thin line you could barely see.
4. **A height bar on the left in Endless only.** The Course stays without one.
   - **Recommend yes.** Check it on the phone in step 1.
5. **What the app opens into once Endless is unlocked.**
   - **Recommend the mode you last flew.**
   - The alternative is always the Course: one more tap to Endless and a house replay.
6. **Missions raise the star multiplier** by +0.25 per set of three, **capped at ×2**.
   - Recommend this over a bigger or uncapped multiplier: prices stay meaningful.
7. **Economy pace:** the whole shop in about 6 weeks at 15 minutes a day (3-4 weeks at 30); the first item in 2-3 runs.
   - Faster or slower is your taste; one number (all prices × k) changes it.
8. **The daily bonus can be farmed** by changing the phone's date. There is no internet to check the time.
   - **Recommend accepting it,** with "never pay twice for the same or an earlier date". It's single-player and nothing is bought with money.
9. **Players who already have a Course best of 1,500+** (only reachable outdoors) get Endless unlocked straight away.
   - **Recommend yes,** so your friends don't have to replay to unlock it.
10. **One extra country (Coast) this phase;** Mountains and Town at dusk next phase.
    - **Recommend:** each country is a content step about the size of the whole prototype.

---

## 13. Where I disagree with the direction

1. **"Updraft vents" → plumes.**
   - The house rule bars floor vents and registers as lift sources, because they echo the 1988 game.
   - The same mechanic is here as chimney smoke, kilns, bonfires and engine steam: plumes you fly through. Nothing reads as a vent.
2. **"Over" obstacles can't be hops.**
   - Pulling up from a glide buys 0.5 u; even from a 10 u/s dive it buys 3.2.
   - So "over" is about arriving high or using lift in front.
   - My sim of a steep cross-valley ridge with only face lift left 1-3 u of clearance, and some flights touched down. Cross-valley hills stay low (crest ≤ 14) with a thermal on the face until calibrated. Barns and walls are over-or-through choices, never walls you must clear.
3. **Power lines as crashes → snags.** See decision 3.
4. **The shield "for one bump" → for one crash or touchdown.** Bumps never end a run, so a bump shield would do nothing.
5. **"Thousands of generated flights."**
   - Yes for the generator's rules: 10,000 sequences checked analytically in seconds.
   - Full-physics flights run about 1,000× slower, so about 100 per difficulty band, in a tool rather than the test suite.
   - Every piece is still flown and calibrated at every difficulty and wind.
6. **"A decision every 2-4 s."**
   - At the calm start (T 1.0) the natural beat is 3-5 s, and I'd keep it so: the opening needs room to breathe.
   - 2-4 s arrives from about 250 m on, as the wind rises.
7. **"Other drifting balloons" → hot-air balloons.** A kid's balloon dodging other kids' balloons reads as something to collect, not avoid.
8. **Pressure.** Temple Run's chaser is replaced by the rising wind and lift that thins with distance. Every run still ends, by human error at a rising pace. A storm-front chaser is in Later ideas if the phone test says the pressure is too soft.

---

## 14. Later ideas (not this phase)

- **A storm front behind you:** a dark rain curtain that follows at a set speed and pushes you down if it catches you. It is visible whenever you circle. Only if the rising wind isn't pressure enough.
- **Countries chained by distance:** the Downs give way to the Coast at 1 km.
- **A ghost line of your best run;** the pennants of your last three runs.
- **Seed codes** to share a run with a friend by typing six letters (still no internet).
- **More power-ups:** a kite tow (pulled along a line for a few seconds); a "deep breath" that makes the balloon float slower for 10 s.
- **Weather and light:** misty mornings with short sight lines and big clouds; evening flights with lanterns.
- **Thermal pulses** (carried over): clouds that form, mature and dissolve.
- **A heron** lifting off the mere's island (carried over).
- **Badges** for firsts: first 1 km, all arcs on a ridge, a perfect hamlet.
- **Photo mode** at the top of a climb.
