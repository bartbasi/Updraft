# Fun review 7: Endless step 3 (forks and the Warm Down)

**SEND BACK.** The forks work as a choice. From the split you can see both roads: the gorge's red bridges on one side, the thermal column and cloud on the other, and a line of stars down each. The commit pop-up lands mid-dive. Both roads keep their promise: the high road leaves 4.9-5.7 higher and the low road pays about 3× the stars. Shaky pilots fly both roads with no touchdowns. The gorge and the river dips look and feel like the best low flying in Endless.

Four things must change before the phone:

1. **A trough on the High Down holds a flyer for minutes.** One run was still bumping at 420 s (item 1).
2. **A pilot who arrives low or circling gets nothing at the fork,** at the very moment of choosing. That is 9 of 55 skilled fork passes, each with 10-12 s of nothing (item 2).
3. **The Warm Down kills first-timers who don't circle.** They hit the same spot: the high crest just downwind of the sun-trap, beside the saddle (item 3).
4. **The gorge's mouth walls rise like a cliff.** A flyer 6-8 u off the gorge's axis meets them as a wall face (item 4).

The rest is tuning.

## Evidence I gathered

- **Batches on the working tree as of 04:20:**
  - skilled ×20 (`--road=alt`), 420 s;
  - shaky ×20 with `--road=low` and ×20 with `--road=high`;
  - novice ×20 (`height`);
  - hands-off ×20.
- **Calibration:** `--calibrate` for gorge_down, river_rail, warm_down and the Mere (the Mere with `--trace`).
- **FirstTimer batches** (chaser, no-circle, middle ×20):
  - My first batch logged a script error in `FirstTimer._wall_aim` thousands of times: `openings[2]` on the forks' and the saddle's one-opening arches. The lead fixed it at 04:34 (`placement.id != &"viaduct"`).
  - I re-ran all three from a scratch copy taken just after the fix. Every run's summary is identical to the first batch, so the error was noise, not a changed flight, and earlier batches stand.
- **Screenshots:**
  - the lead's five sheets;
  - mine (scratchpad `r7/`): the High Down after the chalk figure was redrawn, the Warm Down from 11 (its need), the gorge at d 1 from 14, and the approach to the first fork from 100-200 u (seed 1, 62-78 s).
- **Geometry:** the fork and Warm Down ground functions, re-computed in a scratch script.

## Marks (forks-plan §9)

| Mark | Result | |
|---|---|---|
| Calibration | Outs +0.2 to +1.0 over the table. Lowest 4.0 (gorge, d 1) and 4.4 (river). Nearest solid 2.0 (under the humpbacks, an opening). No touchdowns. **But some arcs are never full:** the Warm Down's saddle (2 of 9), the railway's "along the line" (star 1 never), the brickworks and the kiln (star 4) | Fail: items 3, 8 |
| Both roads, shaky ×20 | Low 20/20 and high 20/20 with no touchdown; outs low 17.3/17.6, high 23.3/22.4 | Pass |
| Stars, low ≥ 2× high | Available: F1 29 vs 9, F2 28 vs 12. Taken (skilled): about 26 vs 8 (F1) and 26 vs 9 (F2) | Pass |
| Height, high ≥ low + 4 | Skilled medians: F1 23.0 vs 17.3 (+5.7); F2 22.7 vs 17.8 (+4.9) | Pass |
| Choice cadence | Every run met its first fork at the 5th-7th piece entered. Fork to fork: 7-11 pieces, median 10 | Pass (upper end) |
| Skilled overall ≥ 85% | 91% (85-95%), no crashes | Pass |
| Hands-off ×20 | Median 105.5 s (65-131); none past 12 pieces; 0 crashes at a nose (the one crash was the High Down's outer wall) | Pass |
| Chaser and no-circle ×20 | **No-circle: all 11 endings are on the Warm Down (9 runs flew the full 420 s). Chaser (17 of 20 flew 20 pieces): 3 on the Warm Down, 1 lured across a fork's nose, 2 arrived at a fork below 10.** None ends at a footbridge or a humpback | **Fail: items 3, 5** |
| Middle (not a mark, but telling) | 16 of 20 runs end or stall at the first fork: 9 in the gorge (5 crashes), 6 touchdowns in the High Down's trough, and 1 still pinned there at 420 s. Median 94 s | Items 1, 4 |
| Pilot vs game | 0 road mismatches; "replanned" 0-1 per run | Pass |
| Cadence (skilled, no gap > 5 s except the glide out of a climb) | High Down: 10.6-13.1 s at its end in 18 of 18 passes. Railway: 9-11 s. **9 of 55 fork passes: 9.7-12.4 s with nothing before the commit** | **Fail: items 2, 5** |

## Changes, most important first

### 1. The High Down's trough pins a flyer and the run never ends (fair failure, fast retry)

**Evidence:**

- Middle-flyer seeds 3 and 5 (fixed pilot) bump at local (18, 5.8, -150..-176) with h 0.3-0.6:
  - one for 250 s (1,318 bumps) before it touches down;
  - the other for 320 s (1,646 bumps), still flying at 420 s.
- Five more middle runs touch down at the same place. Counting seed 3, that makes six touchdowns at x 18.2-18.5.
- **The cause is the ground.** At z -150:
  - the spine is 19 at x 12;
  - the brow's inner ramp `smoothstep(14, 22, x)` is still low at x 16-18;
  - on the 6 u grid this gives x 12 → 19, x 18 → 5, x 24 → 10: a V trough with 50° sides, running from z -104 to -196.

**Fix:**

1. **Layout.** Change the brow's inner ramp to `smoothstep(8, 14, x)`. The plateau (10) then meets the spine's flank where that flank is 10 (x 14). The grid becomes x 12 → 19, x 18 → 10, x 24 → 10, with no trough. The brow lift box and the brow stars stay where they are.
2. **Correctness guard (lead and code reviewer to decide).** A flyer that is in ground contact (a bump, or h < 0.6) for 3 s in a row ends the run as a touchdown. Nothing else should be able to stall a run for minutes, but this makes sure of it.
3. **Mark:** middle ×20 and hands-off ×20 have no run with more than 30 bumps, and none of their endings is at x 14-22 on the High Down.

### 2. A circling arrival gets nothing at the fork (no dead air, readable)

**Evidence:**

- In 13 of 55 skilled fork passes the log shows more than 5 s "with nothing happening", ending at the commit. In 9 of them the gap is 9.7-12.4 s: both signposts are flown past, and so are the first dive stars.
- All 9 enter at 11-16, most of them finishing the previous piece's spiral across the join. For example: 353.6 enter at 11.4, spiral done at 355.8, then nothing until the commit at 365.8.
- The signposts (`follow_entry`) and the dives (`from_entry`) are fitted at the join. The pilot then climbs 3-4 u before it heads on and passes over all of them.
- This is fun review 6's Standing Stones bug again, on the fork's most important 10 seconds.

**Fix:** forks use §6.1's choice point.

- Fit the signposts and both dives at the first tick that is ≥ 6 u in and heading on.
- The fallback is 12 u in, not 24, because the first signpost star is at -16.
- **Mark:** in 20 skilled runs, no fork pass has a gap over 5 s before the commit, and the signposts are taken at ≥ 75% (today low 62%, high 77%).

### 3. The Warm Down kills first-timers who don't circle; move the saddle downwind of the sun-trap (fair failure, readable, feel)

**Evidence:**

- **No-circle ×20:** all 11 runs that ended did so on the Warm Down. Chaser: 3 of its 6 endings.
- All 11 no-circle endings, and one chaser's, are at **x -6.6..-11.3, z -72..-78, y 12.5-14**. The other two chasers touch the crest at x -1..2, z -86, cutting across toward the big star.
- That first spot is the near face's 14 u crest, straight downwind of the sun-trap (centre x -12). These pilots arrive at 9-15 and gain a few units passing through the drifting thermal. They come out at 13-15, exactly where the crest is 14. The saddle's floor (x 4..12, at 10) is 12-19 u to their right.
- **Skilled:** the saddle arc is full in 2 of 12 passes. Star 1 is taken 2 times in 12 and star 2 5 times. There is a 5.1-5.3 s gap between the climb and the saddle.
- The climb ends at (-13..-16, 18-21, -56..-63), and the pilot flies a 45° diagonal to the big star. The arc's stars sit on x 0..6.5, 4-5 u off that path.
- The calibrated arc is full only at d 0 from need and from 18.

**Fix (layout): put the saddle where the thermal sends you.**

- **Saddle:** `SADDLE.x` 8 → **-8**, so the floor (10) spans x -12..-4, the shoulders reach 14 at x -20 and x +4, and the big star is at (-8, 13.5, -84).
  - A flyer that leaves the sun-trap at 12 or more now crosses the saddle with 2+ u to spare.
  - Hands-off (x 0) meets the same 12 u of crest as today: 0 is 8 from the saddle's centre either way.
- **Saddle arc,** straight down from the climb: (-10.5, 17.5, -68), (-10, 16.3, -73), (-9, 15, -78), big (-8, 13.5, -84). Spacing is 5.1-6.1. Clearance falls from 10 at the first star to 3.5 at the big star. The no-circle endings' points would clear the new saddle by 3.7-3.9.
- **Hold and lee:**
  - hold point (-8, 13.8, -91);
  - lee stars (-7.5, 10.5, -99), (-5.5, 8.0, -106), (-2.5, 6.2, -113);
  - then (3, 7.5, -126) to the hayrick's near edge (10, ·, -131).
  - The hayrick stays at (10, -142), off the middle line.
- **Looks:**
  - The chalk track zigzags up the face **into the saddle**: its x runs from -1 at the foot to -8 at the crest. It is the "low way over" sign.
  - Gorse keeps 6 u clear of the new saddle.
  - The hawthorn stays at (-20, -82): it now marks the saddle's west shoulder, which reads well.
- **Step 4 note:** the lee rotor moves to the high crest's lee on the other side (x 2..28).
- **Marks:**
  - no-circle and chaser ×20: ≤ 2 endings each on the Warm Down;
  - saddle arc full in ≥ 6 of 9 calibration flights and ≥ 60% of skilled passes;
  - lowest clearance on the line ≥ 3.5 / 2.5 as before.

### 4. The gorge's mouth walls rise like a cliff (fair failure, readable)

**Evidence:**

- **Middle-flyer:** 9 of 20 runs end in the gorge (5 crashes, "Popped! in the Gorge"). Each one comes along x -27..-30, 6-9 u off the axis, at 8-15 u high. It meets the inner wall at z -110..-125, bumps (h 1.2), slides, and hits the floor or the first two bridges.
- **The cause:** the walls fade in over 16 u of z (`g = smoothstep(76, 92)`). At |u| 9-12 the leading face rises 12-24 u in 16 u: up to 66° head-on, over the 50° crash angle.
- **The screenshots:** the walls are the same green as the valley, so the slot doesn't read until you're in it. The plan's pale sand floor and boulders weren't built.

**Fix:**

- **Layout:** `g = smoothstep(68, 108, -z)` (a 40 u fade-in). The steepest leading face becomes 1.5 × 24 / 40 = 0.9, which is 42°: a glancing bump.
  - The walls still reach the first bridge's deck in time (g at -112 is 1).
  - The dive line stays on the floor; I checked -60 to -86.
- **Looks:**
  - floor (|u| ≤ 6) sand `e6d6a8`;
  - walls chalk-grey `cfc7b4` from 3 u up, blending to grass at the rim;
  - 6-8 dark stone boulders on the walls' lower slopes (looks only).
  - From the split the gorge then reads as a pale slot with red bridges in it.
- **Mark:** middle ×20: ≤ 3 crashes in the gorge.

### 5. The high roads go quiet at the end; and a chaser was lured across the nose (no dead air, fair failure)

**Evidence:**

- **High Down:** after the brow's stars (about 100 s), the only events are "into Knoll" and "fork out". The knoll leg alone is 10.6-13.1 s with nothing, in 18 of 18 skilled passes, after a 5.6-6.2 s glide to the knoll. Shaky `--road=high` has a 13.4-13.5 s gap in all 20 runs.
- **Railway:** from the brickworks to the exit, steam climb included, is 9-11 s.
- **The lure:** chaser seed 4 took the Railway's signpost, then dove at the next nearest star. That was the River's dive on the far side of the nose (from (18, 14, -42)), and it touched the nose's flank at (-8, 7.6, -57). The high road has no stars between its signpost and z -96.

**Fix (layout and scoring):**

- **Into the lift:**
  - 2 stars from each high signpost's end toward its thermal's near edge, at (16, ·, -36) and (21, ·, -42), mirrored for F2. They are 7.8 u apart, on the line to (28, ·, -48).
  - Heights continue the signpost's fitting to your real height (`follow_entry`, 0.5 lower each).
  - Make them part of the "signpost high" arc (5 stars) or their own no-bonus arc, road "high".
  - They continue the high road's own line, so a chaser follows it rather than the other road's dive.
- **Climb spirals:** a 3-star spiral on the knoll (start y 14) and on the engine's steam (start y 21), road "high".
- **Totals:**
  - F1 high: 9 → 14 small (28 vs 14);
  - F2 Railway: 12 → 17 (River 28).
- **Revised mark (my own):** "low ≥ 2× high" counts the stars the skilled pilot takes, not the stars on offer. Today's takes (26 vs 8, 26 vs 9) leave room. If the lead wants the Info text exact, change "more than twice the stars" to "far more stars".
- **Mark:** no high-road gap over 7 s in the skilled batch, glide-outs included.

### 6. The footbridges go silent after the first (reward moments)

**Evidence:**

- Skilled gorge passes: 26 of 39 are under 7.5 u/s (6.6-7.1 at bridges 2 and 3), so they get no whoosh, swell or FOV kick.
- The River's passes run 8.7-10.1 and all are rewarded.
- After the dive the breeze holds the line level, and the glider settles to its trim speed.

**Fix (effects):**

- The footbridges' openings get their own pass speed of **6.3** (`arch_pass_speed` stays 7.5 everywhere else).
- In the gorge the reward is for threading, not for speed.

### 7. The fingerpost hides behind the flyer (readable)

**Evidence:**

- Shots `gorge_down_low/00` and `cap_approach/04`: the 7 u post on x 0 sits exactly behind the balloon from 30-40 u.
- The chase camera hides anything about 0.29 × its distance below the flyer. From 18, a 7 u post 34 u ahead is hidden.
- It shows only at about 2 s, at the bottom of the screen, as you pass it.

**Fix (layout and looks):**

- Post 11 tall at z -40.
- Arms 5.5 long and 1.0 tall: gold at 9.5, blue at 10.5.
- From 18 the arms are then above the flyer from 60 u to 28 u (about 4.5 s), and always visible from 14 or lower.

### 8. Arcs nobody completes (style points feel earned)

From the skilled batch and calibration:

| Arc | Problem | Fix |
|---|---|---|
| Along the line | Star 1 is taken 0 of 6 | Start 6 u later: z -102 to -126, y 20 → 18 (the pilot is at (-35.5, 20.0) at -100.7) |
| Brickworks | Star 4 is taken 0 of 6 | Rise per star 1.65 → 1.2 |
| Kiln | Star 4 is taken 3 of 20 | Rise per star lerp(1.65, 1.15) → lerp(1.2, 0.85) |

**Mark:** each arc full in ≥ 6 of 9 calibration flights.

### 9. The Mere's across-arc (fun review 6 follow-up)

**Evidence:**

- Stars 3-4 are taken in 21 and 20 of 23 skilled passes, which meets that mark.
- The full arc comes in 6 of 23 (26%), against a mark of ≥ 50%. Stars 6-7 are taken 9 and 6 times.
- The d 1 trace has the pilot at x -2.5 at star 6's z (star at -4.2) and x -4.2 at star 7's z (star at -6). The stronger wind's ground speed makes it under-turn by about 1.8 u.

**Fix (layout):**

- `turn` = [0, 0, 0, 0.1, 0.3, 0.55, 0.8], which puts stars 6-7 at x -3.3 and -4.8.
- At d 0 the pilot passes star 7's z at x -4.9, so this still fits.

### 10. Looks, low priority

- **The spine head-on.** From 100-200 u (`cap_approach`) the 24 crowns line up behind the nose and read as two trees on a cone. Stagger them across x ±3..±8 (ground there is 33+ at full height). Add 4 crowns at z -84..-92: H there is 32+, well above every nose bump in the batches (h 6-11) and every commit height (25 or less).
- **The river cliff** reads as a flat orange card. Add two rose bands (`dba58e`, y 3-4 and 7-8) and 6 bushes along its top (looks only).
- **The humpbacks** are striped like a barcode (1 u slices alternating). Use STONE_DARK on every 4th slice only, or only on the arch ring.

## What's good (keep)

- **The reveal works.** At the entry you see both roads at once, and the chalk paper plane (redrawn smaller) reads from 150 u and is a real delight. Gold means stars and blue means lift.
- **The River is the best low run in Endless.** Bridge passes speed up from 8.6 to 10.1 u/s, with whooshes all the way. That is what the gorge should feel like (item 6).
- **The gull joins on the brow** in every high pass.
- **The Viaduct after the Railway** gives a high arrival (22.4-22.7) and the long dive the plan promised.
- **Hands-off is fixed.** The split breeze stopped the "Wrong way!" drifts; there were no nose crashes in 20.
- **The Stones' choice point works.** No low-line pass took 0 stars.
  - The three "arc flown past (0 of 9)" lines in the skilled log are the low arc closing during high-line passes. It is alt, so the game doesn't count it, but `endless_log`'s arc stats do: please skip alt arcs there.
  - One pass chose low at 20.8 while still circling and broke the dive's start. Watch for it; no change asked.

## Later ideas

- A high-road-only moment: the train (step 4) running along the embankment beside you, or kites flown from the High Down's crest.
- The "both roads" badge (forks-plan §13).
- The gull following you from the brow to the knoll, and leaving at the merge.

---

## Re-check after the changes (2026-10-15)

**APPROVE**, with three small tuning changes to make before the commit (A-C below). They need no further review from me: re-measure them with the marks given. Poplar Row stays as it is.

**What I flew.** I made a fresh scratch copy of the repo after the lead's changes and flew these on it:

- skilled ×10 (seeds 21-30);
- shaky `--road=high` ×10;
- no-circle ×10 (seeds 21-30);
- middle ×10;
- calibration of all three new pieces, with a trace of the Warm Down;
- captures of the gorge, the Warm Down from 11, and the river.

I also read the lead's `r7_*.log` batches.

**Fixed, as asked:**

| Item | Now |
|---|---|
| 1. The trough | Gone: no middle-flyer ends at x 14-22 on the High Down; the 3 s guard ends any run held down |
| 2. Gaps before the commit | One gap over 5 s (6.4 s) in my skilled batch, against 9 of 55 before. Signposts taken: low 83%, high 85% |
| 3. Warm Down for pilots who don't circle | No-circle: 0 Warm Down endings in 10 runs (the lead's batch: 0 in 20) |
| 4. The gorge's mouth | Middle-flyer: no gorge endings in my 10 runs (the lead's batch: 1 in 20). The gorge reads as a pale slot with red bridges from the split; boulders show inside |
| 5. The lure across the nose; dull high roads | Railway: no gaps over 6.2 s. High Down: see B. Nose: see the watch item |
| 6. Footbridges | Whoosh on every pass |
| 7. Fingerpost | Visible beside the balloon from the entry |
| 8. Arcs nobody completed | Along the line, brickworks and kiln: full in every pass |
| 9. The Mere | 6 of 11 full (55%); stars 6-7 taken 9 and 7 times out of 11 |
| Skilled overall | 92% (89-94%), no crashes; high outs 22.7-23.5 against low 17.1-17.9 |

**A. The saddle: yes, change it before the commit.**

- **The problem:** in my skilled batch the saddle arc is full in 0 of 6 passes, and **the big star is taken in only 2 of 6**. The lead's batch has 3 of 7 for every star. In the batches the pilot crosses the saddle at 14 and 9-10 u/s (the whoosh fires) but at **x -11.2..-13.5**, 1.2-3.5 u left of the big star at x -10.
  - The traces show why. The climb ends at a different point on the circle each time, and the pilot swings out of it. In calibration it crosses at x -9.5..-11.3; in the batches (after re-entering the drifting thermal) at -12.3..-13.5. At stars 1-3 it is 1-1.5 u below them.
- **The fix:**
  - big star at **x -11.5** (the saddle is flat ±6, so its 3.5 u clearance is unchanged);
  - stars 1-3 **1.0 lower**, at x **-12.5** (16.5, 15.3, 14.0 at z -68, -73, -78);
  - lee star 3 from (-3.5, 6.2, -113) to **(-4.8, 6.7, -113)**: pilots pass at (-5.0, 6.8), and it is taken 0 of 6 today.
- **Mark:** the big star in ≥ 5 of 6 skilled passes; the saddle arc full in ≥ 50%; the lee arc full in ≥ 50%.
- If the full saddle arc still misses after that, drop star 1 (the arc becomes 2 + big). That star depends most on where the circle ends.

**B. The high roads' closing spirals sit too low.**

- **The problem:** the knoll spiral (3 stars from 14) is done 1 s after you arrive at 13. The next 11-12 s are silent: shaky `--road=high` still has its longest gap at 12.2-12.4 s in all 10 runs, and skilled at 10.9-12.1. The steam spiral's star 3 is taken 1 time in 4, because pilots leave the steam at about 24.
- **The fix:**
  - knoll spiral start **20** (stars at about 20-25, during the climb to 27.5);
  - steam spiral start **19.5**.
- **Mark:** no high-road gap over 8 s (skilled), and the steam spiral full in ≥ 75%.

**C. Poplar Row: no change.** The middle-flyer's two Poplar Row crashes (and the lead's 4) come in at 7.7 or lower, flying the valley's middle with no reaction to the gap. That is the pilot, not the piece. If the lead wants a cleaner test, give the middle-flyer a gap reaction like its viaduct one (test code), and I'll judge Poplar Row from that in step 4's review.

**Watch item: the nose lure.**

- One pilot in each batch crashed on F2's nose just after taking the Railway's signpost: no-circle seed 29 in mine, one no-circle and one chaser in the lead's 20 + 20.
- Seed 29 enters from the left at 18 (off the Ridge), takes signpost-high star 3 at (-11, 15, -29), then dives 10 u in 24 u toward x 0 and pops at (-7.4, 5.5, -52).
- The lead-in stars should have drawn it left. Please trace that seed before step 4: check where the lead-in stars were fitted for a pilot arriving from the side. 1 in 10 to 20 doesn't hold up the commit.

**Hands-off** now ends mostly "pinned" at the foot of a fork's nose. That is the floor case, ending immediately as intended: median 100.6 s (mark 45-150).
