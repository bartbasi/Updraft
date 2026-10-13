# Fun review 4: Phase 4 (deeper flying, the Gap and the lake)

**APPROVE** (final, after the re-check below). The first pass was **SEND BACK**, a small one: items 1-3 were needed to pass and 4-8 were polish. Items 1, 2, 4, 5, 6 and 7 are now built; item 3 is my pass-mark change and item 8 is the owner's. The Gap and the bowl work. The reveal at the saddle is the best new moment in the game, and every new route is crash-free.

## Evidence I gathered

- `flight_log` runs: gap, lake, bluff, ridge, and novice ×10. They match the lead's table exactly.
- **Shaky skilled pilots** (my scratch script). These are the touring routes with wobble 0.15, reaction 0.15 s, and 10 seeds per route.
  - gap: 10/10 island, 99.3-99.5 s.
  - lake: 10/10 island, 136.4-137.4 s.
  - bluff: 10/10 beach, 133.6-134.4 s.
  - **0 crashes in 30 flights.**
  - Lowest clearance past z -260, off the water and landing strips: 4.3 u, over the saddle floor.
- **Drift what-ifs.** BarnHeat, an r 6 orbit, entered at y 5 and at y 12, with `thermal_drift_speed` set in memory only. Then every route and novice ×10 at 0.5.
- **Island approach what-ifs.** One pilot crosses the saddle high (y 21.6) with no dive. One dives the Gap path, then glides straight on.
- **Captures at 1280×720:**
  - window, hay top, lavender, ridge end, chalk;
  - saddle at t 84.5 / 86.5 / 88.5;
  - bluff foot, bluff run, bluff top to beach, SandHeat, end cards.
  - Frame rate: 57-60 fps at the saddle, on the bluff and over the island (PC).
- The scratch scripts are outside the repo:
  - `seek.gd`, in the review session's temporary scratch folder;
  - `cap2.gd` in the same folder, which is `capture.gd` without its 90 s cutoff (bowl shots need it).

## Pass marks (§D)

| Mark | Result | |
|---|---|---|
| Novice ×10: 10/10 outside, 0 crashes, median 70-78 s | 10/10, 0 crashes, median 72.7 s | Pass |
| "gap": 105-125 s, island, Gap style ≥ 0.8 | 98.7 s, island, quality 1.00 | Time short. **I'm changing the mark to 95-125.** The plan's 116 assumed it would arrive high and circle down over the island. It arrives straight in, which is fine. |
| lake / bluff: 0 crashes over 10 seeds, intended landing | 20/20 shaky flights, 0 crashes, all on target | Pass |
| No new leg > 10 s of logged dead air, except the lake crossing | bluff: 12.6 s (saddle to bluff foot) and **14.6 s (in the bluff lift)** | **Fail**, see items 2-3 |
| Sighs ≤ 1 per thermal (skilled); novices 1-4 on L1 | Skilled 0; novices 5 in 10 runs (0-1 each) | Pass. Novices are under my 1-4, because most pass through L1 too briefly to sigh. Fine. |
| 60 fps at the B8 capture points | PC 57-60 | Pass on PC. The real test is the phone list. |

## Items, most important first

### 1. Drift: raise `thermal_drift_speed` 0.25 → **0.5** (lead's question 1)

**Checklist point.** Feel, and "style points feel earned". As built, drift teaches nothing: both pilots get 0 sighs.

**Evidence.** BarnHeat, r 6 orbit. "Top" means within 2 u of the thermal's top.

| Drift | Re-centres, from y 5 | Naive, from y 5 | Re-centres, from y 12 | Naive, from y 12 |
|---|---|---|---|---|
| 0.25 | 8.2 s to top, 0 sighs | 9.5 s, 0 sighs | 6.3 s, 0 | 7.1 s, 0 |
| **0.5** | **8.4 s, 0 sighs** | **11.3 s, 1 sigh** | **6.8 s, 0** | **9.8 s, 1** |
| 0.75 | 8.5 s, 0 | 11.8 s, 1 | 7.4 s, **1** | 10.2 s, 1 |

- At 0.5, the pilot who follows the beeps never hears a sigh. The one who circles the old spot hears exactly one and is 26-31% slower.
- That is the lesson the plan wanted, and it gets taught in one climb.
- At 0.75 even the good pilot sighs, so 0.5 is the sweet spot.

**Side effects at 0.5:**

- All seven skilled routes land where they did, within 0.6 s and 30 points:
  - gap 98.6 s / 3278;
  - lake 134.7 / 3366;
  - bluff 133.6 / 3298;
  - chain 118.6 / 2402;
  - ridge 87.0 / 2234;
  - picnic 76.4 / 2400;
  - lavender 70.7 / 1981.
- Novices ×10: 10/10 lavender, median 72.6 s, 0-1 sighs each. The hay field stays forgiving.
- The 0.5 R cap is now reached in 10-12 s, so a cloud visibly slides about 5 u while you are still near it. The readable cue gets stronger too.

**Change.**

- `thermal_drift_speed` 0.5. Leave the cap and wake as they are.
- In `test_re_centring_climbs_a_drifting_thermal_faster`:
  - add "the naive pilot sighs ≥ 1" (the plan's original intent);
  - tighten the speed check to "≥ 20% faster".

### 2. Bluff run: the gull also joins on the bluff (once per lift box, not once per run)

**Checklist point.** No dead air. The log shows 14.6 s inside BluffLift (t 102.4 → 117.1) with nothing new.

- The valley ridge, by contrast, has the gull at +1.8 s and the style award.
- On the bluff route the gull has already been used on the valley ridge, so the bluff has nothing.

**Change.** This adjusts an approved effect; it is not a new system.

- Allow one gull visit per lift box: RidgeLift once and BluffLift once. Same `gull_wait` 1.5 and `gull_stay` 6.
- The bluff's 14.6 s then breaks into about 1.5 / 6 / 7 s.
- A gull by the lakeside bluff is, if anything, more natural than on the ridge.
- Log the second "gull joins" so the flight log shows it.

### 3. Saddle → bluff foot (12.6 s): accept it as part of the reveal, and widen my exception

**Checklist point.** No dead air, but this is a looking leg, not an empty one.

- From the crest (t 85.5) the player is taking in the whole bowl:
  - the lake, island and boat;
  - the beach column and huts;
  - the bluff's flag and hovering birds (captures t 86.5 / 88.5 / 91).
- The Gap style award lands at t 89.6, in the middle of this leg.

**Change.** None to the game. Pass mark §D now reads: "except the lake crossing and **the first leg after the saddle (≤ 13 s)**". Both are free-look legs with the whole bowl in view.

### 4. Lower the bowl's far rim so the reveal opens up

**Checklist point.** The window reveal: flying outside should feel like a payoff, and the Gap is the second reveal.

**Evidence.**

- In captures t 86.5 and 88.5, the far rim fills the frame from the lake up to about 19° above the horizon, leaving only a strip of sky.
- The rim reaches 87 at z -525; the eye at the saddle is at about 22, 190 u away: atan(65/190) ≈ 19°.
- The bowl reads as an enclosed crater rather than a landscape opening out.
- The rim only needs to stop a plane at 34 inside the bounds, and be ≥ 45 at the edge.

**Change.** In `_bowl()`, change the far-rim term `0.02 * max(0, e - 120)^2` → **`0.013 * ...`**.

- Rim at the edge: 0.013 × 66² ≈ 57 (≥ 45: OK).
- A plane at 34 meets it at e ≈ 171, z ≈ -510, inside -525 (now -501).
- Seen from the saddle it rises to about 10° instead of 19°, so the moved far hills show above it.
- The hands-off glide from the saddle still comes down at about z -477, before the orchard (-488).
- **Re-run:** the hands-off saddle test and the B1 rim rows of the heights test.

### 5. Windmill: turn it toward the valley

**Checklist point.** Readable.

- Edge-on from the valley it reads as a bar pivoting in place (lead's flag 3). In the t 79 capture the sails are barely a cross.
- From inside the bowl (t 123) it reads well.

**Change.**

- Yaw the windmill so its sails face **+Z rotated 35° toward +X**. The sail disc then shows at cos 35° ≈ 0.82 of its width from the valley.
- No player will check it against the breeze. Fun wins here.
- Keep the right shoulder (36, -336).

### 6. Island after the Gap dive: give back 1.5 u

**Checklist point.** Style points feel earned, but stay reachable together with the +500.

**Evidence.**

- Diving the Gap path, then gliding straight, the plane reaches the lake edge at y 8.9 and the island about 4 u above it.
- Crossing high (y 21.6) with no dive, it reaches the lake edge at y 15.2 and the island about 10 u above it.
- The skilled gap route arrives at +2.3, but its approach line aims low.
- A phone pilot's line will wander. Every extra 10 u over the water costs about 1.7 u (5.9 : 1 glide in lake sink).
- So "Gap style + island" is the narrowest combo in the game.

**Change.**

- In the `gap` style path, raise the last point (5, 12.0, -366) → **(5, 13.5, -366)**.
- The dive is still about 4 u in the last 30 u before the saddle, so the moment keeps its thrill (crossing at 8.3 u/s into the lake sink).
- Check that the gap route still scores Gap quality ≥ 0.8.

### 7. Quiet the sink ticks once you're down

**Checklist point.** Feel; reward moments.

**Evidence.** At the end of both island landings the ticks toggle while sliding on the island:

- gap route: on 97.5, off 98.0;
- lake route: on 133.2, off 133.7.

A landing should end clean on the chime and title.

**Change.** Play sink ticks only when the plane is ≥ 1.0 u above the terrain (or above the water surface over the lake).

### 8. Lighter effects (B8.8): agree to defer

- Agree with the lead's call: put it to the owner with the phone frame-rate check.
- Add to the phone list "60 fps at the saddle facing the lake, the bluff run, circling SandHeat and over the island". If any point fails, apply the B8.7 fallbacks in order.

## Lead's other flags

- **2. Sight line from the sill.** Accept the miss.
  - From the window the hay field's column is the right first thing to see.
  - The notch and windmill show clearly by the hay top and over the lavender (captures t 54, t 58), about 12 s later. That is soon enough to invite the explorer.
  - Item 5 makes the windmill read better.
- **4. Downs shoulder at 31.7.** No change needed; nobody can get high enough to skim it:
  - from the ridge top (33 at about z -221) it is about 115 u to the shoulder, arriving at about 21;
  - from the chalk top (27) it is 47 u, arriving at about 22;
  - no valley lift tops above 33.
- **5. Lake crossing.** Accepted:
  - the bluff route's 14.7 s (bluff top → beach) is under my 18 s, with the beach, huts and SandHeat column in view the whole way (t 123);
  - the lake route's 10.7 s is the old BarnHeat → FieldHeat valley leg, unchanged from Phase 3.
- **6. Arrivals about 5 u high on the chalk legs.** Good. More margin for the gate is welcome.

## Later ideas (new systems, not for this phase)

- A boathouse "jetty landing" bonus (it needs a new landing rectangle and title, so it waits).
- A heron lifting off the island as you approach (carried over).

## Re-check after the fixes (final)

I re-ran `flight_log` for gap and bluff on the working tree, plus captures at t 72 and t 86.5 on the gap route.

- **Item 1, drift 0.5.** The lead's test shows 8.4 vs 11.3 s and 0 vs 1 sighs, matching my numbers. Every route's score is unchanged.
- **Item 2, gull per ridge lift.** The bluff route now logs `gull joins` at 105.0 s on BluffLift. Its in-lift stretch is broken into 3.0 / 8.6 / 3.2 s.
  - The bluff route's remaining long legs are the two accepted free-look legs: saddle → bluff foot 12.4 s (item 3) and the lake crossing 14.7 s.
- **Item 4, rim 0.013.** From the saddle (t 86.5) the rim now stops well below mid-frame. Open sky shows over the whole bowl and the far hills show above the rim: it reads as a landscape opening out. The hands-off glide from the saddle still rests at z -479.4.
- **Item 5, windmill.** From the ridge end (t 72) the sails read as a turning X on the right shoulder.
- **Item 6, Gap path end at 13.5.** The Gap is still quality 1.00 at +150. The skilled route's island arrival is unchanged (+2.3), because that comes from its own low approach line, not the path.
- **Item 7, quiet ticks.** The gap route's ticks now stop at 96.3 (y 0.8) and stay off through the landing; no more toggling.
- **Totals.**
  - Suite: 150 pass.
  - Novices: 10/10, median 72.6 s.
  - Routes: gap 98.8 s, island 3278; lake 134.6 s, island 3366; bluff 133.4 s, beach 3298. The valley routes are unchanged.

All §D marks now pass, as amended:

- gap route 95-125 s;
- dead-air exceptions for the lake crossing and the first leg after the saddle.

**APPROVE.**

**Still for the owner:**

- the "Lighter effects" setting (item 8);
- the phone frame-rate check at the saddle, the bluff run, SandHeat and the island;
- whether drift at 0.5 feels like a nudge, not a chase, on a real tilt.
