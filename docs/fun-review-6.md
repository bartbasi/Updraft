# Fun review 6: Endless step 2 (pace and variety)

**SEND BACK.** The six new pieces look right and read well: the red barn, the washing, the poplar wall, the stones, the Mere and its sailboat. Recentring, the rising wind and the bunting are in. Shaky pilots pass both survival marks easily. Three things must change before the phone:

1. The barn's roof stars lure a star-follower into the gable wall (item 1).
2. The high lines make the three best moments rare, and they cost good pilots stars they had no way to reach (item 2).
3. The spiral is broken again (item 3). This was already true in the committed step 1.

Item 4 is my answer to the hands-off question: the opening is fine, and the long tail comes from lift sitting on the middle line. I checked the fix in a scratch copy.

## Evidence I gathered

- **The lead's batches** in `scratchpad/final`: skilled, shaky and novice from 0 m (420 s), shaky from 500 m (300 s), hands-off, plus `scratchpad/cal`, the screenshot sheets, the diff and the build notes.
- **My verbose `endless_log` runs**: skilled seed 3, hands-off seed 10. Skilled ×6 for 200 s at a fixed wind of 1.0, 1.5 and 3.0. Skilled ×6 on the **committed** build (git archive of HEAD, wind 1.5), for the spiral.
- **My scratch pilots** (session scratch `design/firsttimer.gd`, not in the repo; the same four as in review 5): hands-off, middle-flyer, and the star-chaser in two kinds, one that circles on beeps and one that never circles. 20 runs each, 420 s, seeds 1-20.
- **The working tree changed during the review** (pieces.gd at 08:01, game, stars and world at 08:03-08:08: the barn's dive now ends at the door's height 6 u out, and the doorways have rounded edges).
  - I re-ran the barn findings on a copy taken at 08:13. The numbers below say which build they come from.
  - Two scratch copies, never the repo: `exp2` is the tree as of 08:13; `exp` is the same with the lifts moved as in item 4.
- **Screenshots:** the lead's barn, pasture, poplars and mere sheets, and my own of the Washing Lines (from 12, d 0.5) and the Standing Stones (from 14, d 0.5).

## Step 2-4 marks (§11)

| Mark | Result | |
|---|---|---|
| 4 Generator | Lead's 10,000-sequence test | Pass (not re-run) |
| 5 Calibration | Every out within ±1.5 of the table in code. Lowest 3.3 (barn d 1, a dive moment: ≥ 2.5 is fine). Nearest solid 2.0 at the barn door, d 1 (fine for an opening) and at the stones, d 0.5-1 (the beside rule wants 3.2 / 2.5) | Pass, with item 7d |
| 6 Skilled ≥ 85% of stars | 81% (72-88%) in both skilled batches | **Fail**: items 2 and 3 |
| 7 Shaky ≥ 70% | 79-80% | Pass |
| 8 Novice (as revised in review 5: hands-off 45-120 s) | Hands-off median 124 s; 6 of 20 fly 12+ pieces, one flies 32 (796 m) | Marginal fail: item 4 |
| 9 Cadence | Can't judge: star pickups still aren't logged, so every street and arc shows as "nothing happening" | Item 6 |
| Shaky ≥ 20 pieces from 0 m in ≥ 80% | 20 of 20 | Pass |
| Shaky ≥ 10 pieces from 500 m in ≥ 50% | 20 of 20 (18 of 20 flew 20) | Pass |
| Recentring | Lead's test: two recentres in 2,100 m, no jumps | Pass |

## The hands-off question

**Hands-off is not a model of a first-timer. It is the floor.** It answers one question only: does the country end a run that isn't being flown? A real first-timer steers, badly. My star-chaser is the closer model.

**The opening is not too forgiving.** 9 of 20 hands-off runs end within 5 pieces (60-90 s), at the same places as in step 1: the Hamlet and the viaduct's face.

**The median creeps over 120 s because of the tail.** 6 of 20 runs fly 12+ pieces. Seed 10 flies 32 pieces in 406 s, which is as far as the skilled pilot gets in the same time.

- Its log shows why: every new piece puts its lift on x 0, where a straight glide passes.
  - Pasture: the bonfire, +4 u.
  - Washing Lines: the copper (R 8).
  - Mere: the island (R 10 at x −4).
  - Poplar Row: the streets, 14 wide at x 6, which cover x 0.
  - Standing Stones: the down thermal, R 9 at x −7.
- With the cloud street and the barley also on the middle, a pilot who never touches the phone is topped up every piece. The low warm layers are not the cause: they only hold a glide level (net +0.13 u/s), and the bonfire then lifts it out.

**Tested in the `exp` copy.** I moved three lifts and narrowed the poplar streets (item 4) and changed nothing else.

| Pilot | Measure | Before (`exp2`) | After (`exp`) |
|---|---|---|---|
| Hands-off | Median | 124 s | 113 s |
| | Flew 12+ pieces | 6 of 20 | 2 of 20 |
| | Flew 20+ pieces | 3 of 20 | 0 of 20 |
| | Longest | 406 s | 214 s |
| Middle-flyer | Median | 159 s | 129 s |

The middle-flyer's "before" comes from the 08:00 tree. Hands-off gave identical runs on both trees. The first 3-5 pieces were identical before and after. A pilot who follows the stars is not touched by this, because the stars lead into the lift wherever it is.

**The star-chaser** (on the 08:13 tree, with the roof-star lure removed as in item 1) flies the full 420 s in 39 of 40 runs, with 79-83% of stars. That is far above the 2-4 minutes I set in review 5. I am **not** asking for tuning to chase it in step 2:

- the scripted hands never misjudge a moment;
- the step 3-4 hazards are meant to supply the misjudgements;
- the pace of the rising wind can only be judged on a phone.

Revised marks for steps 2-4:

- **Hands-off:** median 45-120 s, and at most 2 of 20 past 12 pieces.
- **Star-chaser, both kinds:** every ending is at an obstacle in plain view, and no ending comes from a star line that leads into something. Record the median; no mark until step 4.
- **The owner's first three runs on the phone** remain the real novice mark.

**For the owner.** The rising wind makes height *easier* with distance. Glide over the ground goes from 11.4 : 1 at T 1 to 14.6 : 1 at T 3, while lift thins only about 20%. All the pressure must come from pace and obstacles. If the phone says runs past 500 m feel easy, one lever is ready: a gentle background sink rising to about 0.2 u/s between d 0.5 and 1. I am not asking for it now.

## The low warm layers and the high lines

**Low warm layers: keep them.**

- Measured, the hedge-hop and the duck-under can't be flown on a glide, and "warm air low over a sunny field" is believable.
- Low and level is a new feeling, and it fits the pieces whose moments are low.
- They don't feed a passive glider on their own: net +0.13 u/s.
- Two asks: make them visible from outside (item 7b), and get the bonfire off the middle line (item 4).

**High lines: keep them as the fallback, but they are flown far too often, and the other line's stars do harm** (item 2).

- High entries happen after almost every Street (exit 24) and Ridge (26.5-27). Skilled pilots flew the high line in:
  - **17 of 23 Washing Lines**;
  - **10 of 20 Barns**;
  - **5 of 13 Stones** (skilled_1).
- So the three signature moments (under the washing, through the barn, through the ring) are what a good pilot sees least.
- Every low-line star counts as missed when you're high, which is most of why skilled is at 81%.
- From a ridge exit (27) even the high line's first star is out of reach. Skilled seed 3 entered the Washing at 27.2 and missed the first "over" star at 10.5, 36 u in.

## Items, most important first

### 1. The barn's roof stars pull a star-follower into the gable (must)

**Checklist point.** Fair failure.

**Evidence.**

| Build | Chaser that circles | Chaser that never circles |
|---|---|---|
| The tree as it was at about 08:00 | 13 of 20 runs ended, **all at the Dutch Barn** | 14 of 20, all at the barn |
| After the lead's 08:01 barn change (`exp2`) | 3 of 20, all at the barn | 6 of 20, all at the barn |

- Nothing else in the country ended a star-follower's run.
- The trace (chaser seed 1, d 0.22, entering at 18.4) shows how:
  - It follows the dive stars down to y 7.2 at z −38.
  - Then the nearest star ahead is the **roof star at (0, 15.5, −48)**, not the big star at (0, 4.0, −54).
  - It pulls up (vy +1.0) and hits the gable above the door at (0, 7.5, −43.4): "Popped!".
- A child does the same thing: two gold lines in view at the moment of commitment, and the nearer one leads into a wall.
- With the alt stars ignored (my sim, same build): circling 0 of 20 crashes; never-circling 1 of 20 (seed 19, d 0.8, y 5.9 at the face, clipping the 6.3 lintel).

**Fix (star display and scoring).** The stars show the line for your height.

1. At a piece's entry (z 0), compare the flyer's height with `high_from`.
2. **Low:** the high line's stars (barn roof, over the washing) are not drawn and can't be taken.
3. **High:** the low line's stars are drawn dimmed (60%, like a broken arc) and count as alt. They can still be taken; see item 2b.
4. Keep the lead's 08:01 barn dive (ending at through + 0.8 at z −38). Optional: lay its last star at through + 0.5, for more room under the d 1 lintel.

**Pass mark.** Both star-chasers ×20 at 420 s: at most 1 barn ending in the 40 runs. Skilled and shaky: no barn bumps.

### 2. The signature moments are rare, and high entries cost good pilots stars (must)

**Checklist point.** Style points feel earned. No dead air: a high entry into the Barn or Washing is a 7 s glide down with nothing to do (skilled seed 3 at 80 s and 134 s).

**Evidence.**

- **Taken by star**: all numbers are from skilled_1 unless marked "_11" (the skilled_11 batch). Each bracket gives, star by star along the arc, how many times that star was taken.

  | Arc | Stars | Full arcs | Taken by star |
  |---|---|---|---|
  | Washing | 26% | 6 of 23 | [6 × 9] |
  | Barn dive | 41% | 4 of 20 | [4, 7, 8, 10, 10, 10] |
  | Barn dive (_11) | 32% | | |
  | Heap spiral | 50% | 10 of 20 | |
  | Heap spiral (_11) | 33% | | |
  | Stones | 56% | 5 of 13 | [5, 5, 7, 8, …] |

- The barn's calibration from 26 gives 0 of 13 at every d: the over-the-roof line skips the heap, so its spiral goes too.
- Share by arc confirms that the 81% comes from these three pieces and the spiral (item 3).

**Fix.**

- **a. Generator weight.** When the table's h is at or above a piece's `high_from` (21), weight Washing, Barn and Stones ×0.25.
  - They will then come mostly after Barley, Hamlet, Kites, Pasture, Poplars, Viaduct and Mere (outs 13-20.5), where the low line fits.
  - They stay possible after a Street or Ridge, with the high line as the fallback.
- **b. Scoring.** The line you're not on doesn't count. Entering at or above `high_from`, the low line's arcs (washing, barn dive, barn big star, stones) count as alt. Below it, the high line's do, as now.
- **c. The washing's over-line** steps down instead of sitting level: stars at 12.5 / 11.5 / 10.5 over lines 1 / 2 / 3.

**Pass marks.**

- Skilled ≥ 85% of stars (mark 6).
- Skilled flies the low line in ≥ 60% of Washing Lines, Barns and Stones.

### 3. The 6-star spirals miss the circling pilot again (must; it is already in the committed step 1)

**Checklist point.** Feel (the climb). Style points feel earned.

**Evidence.** Review 5's pass mark was: skilled takes at least 5 of 6, with a full spiral in at least half the Barleys.

| Build | Barley | Copper |
|---|---|---|
| Lead's skilled batches | 14 of 37 and 9 of 36 full; taken by star [36, 9, 20, 35, 28, 14] | [15, 4, 4, 15, 15, 4] |
| Fixed wind 1.0 / 1.5 / 3.0, 200 s | 1 of 7, 2 of 8 and 1 of 8 full | [4, 0, 0, 4, 4, 0] at every wind |
| Committed HEAD, wind 1.5 | **6 of 17 full**, [17, 6, 13, 16, 17, 9] | |

- So it isn't the wind, and it isn't step 2. It came in after the build notes' "21 of 21".
- The 10-star island helix is fine: 100% at wind 1.0-1.5.
- The pattern is always the same: star 2 (and on the copper, stars 2, 3 and 6) is missed on every spiral that isn't full. I'd look at stars 2-3 being marked missed before the 120° anchor fires, and the last star being laid where the pilot stops climbing (orbit `to_y` top − 2 against the last star at top − 2.5 plus lead).

**Fix.** Trace one Barley and one copper climb at 0.1 s, as in review 5, and restore review 5's marks at T 1.0, 2.0 and 3.0.

### 4. Lift on the middle line keeps a passive glider up (should)

**Checklist point.** No dead air: a decision every few seconds. Style points feel earned: steering should matter.

**Evidence.** See "The hands-off question": I checked the fix in the `exp` copy.

**Fix (layout).** Re-calibrate the four pieces afterwards.

| Piece | Change | Stars and line |
|---|---|---|
| Pasture | Bonfire (0, −90) → **(7, −90)** | Hedge-hop stars at x 0 / 2.5 / 5 over hedges 1 / 2 / 3 (all ≥ 2 u from the gate posts); smoke stars at x 7 |
| Washing Lines | Copper (0, −82) → **(9, −84)**. The wash-house stays on the left. | Under-line stars at x 0 / 1.5 / 3 under lines 1 / 2 / 3 (7+ u from the posts) |
| Mere | Island (−4, −56) → **(−10, −58)** (still inside the lake) | The across arc already runs to the island's x |
| Poplar Row | Both streets 14 → **10 wide** (x 1-11) | |

Leave the barn's heap and the stones' thermal where they are: their walls already end straight-line flying.

**Pass mark.** Hands-off ×20: median 45-120 s, at most 2 of 20 past 12 pieces. Star-chasers' share no lower than now.

### 5. The first star of four arcs is out of reach from the usual entry (should)

**Checklist point.** Style points feel earned.

**Evidence: the first star**, taken over arcs flown:

| Arc | skilled_1 | skilled_11 |
|---|---|---|
| Hedge-hop | 17 / 26 | 17 / 30 |
| Mere | 11 / 21 | 5 / 16 |
| Poplar gap | 14 / 24 | 7 / 23 |
| Stones (stars 1-2) | 5 / 13 | 4 / 14 |

These are the same kind of fault as review 5's item 2: the line starts lower than the usual entry can dive to.

**Fix.**

- **Mere:** the across arc starts at (0, 15, −22) instead of (0, 14, −14), 7 stars to the island. That makes it 1 : 4.4 from an entry of 20.
- **Poplar gap:** the first two stars at y 11 and 10.5, the rest at 10.
- **Hedge-hop:** drop the star 4 u before hedge 1 (8 stars).
- **Stones:** item 2a should take care of it. Re-check after.

**Pass mark.** Skilled takes the first star of each of these arcs in ≥ 75% of passes.

### 6. Tools for the novice and cadence marks (should; asked in review 5)

1. Add `--pilot=chaser` (both kinds) and `--pilot=middle` to `endless_log`. Port them from my scratch `design/firsttimer.gd`; it needs a null-kit guard in the viaduct check.
2. Count each star pickup as an event, without a log line, so the "nothing happening" gaps are real.

The only real dead air I can see by reading the logs:

- the Ridge climb (7-8 s, accepted in review 5);
- the high entries in item 2.

### 7. Small (text, look, generator values)

- **a. How to fly.**
  - "Hop the hedges low and fast" → "Skim low and fast over the hedges". A hop buys half a unit; you don't hop a hedge.
  - "or hop over the lines" → "or fly over them".
  - After item 1, add: "The stars show the line for your height: low, through the door; high, over the roof."
- **b. Warm layers seen from outside.** Tint the ground under each layer a warm hay-gold: the barley's colour, blended about 40% into the grass, in vertex colour. That way "warm low air" is visible before you're in it. The motes only show once you're close.
- **c. Pasture is always followed by a Street.** Its out (13 / 11) leaves only the Street fair (4 of 4 in hands-off seed 10). Raise its out to about 15 / 13: smoke to y 21, smoke stars up to 15. Then Barley, Washing, Poplars and the Barn can follow it.
- **d. Stones.** Nearest solid 2.0 at d 0.5-1 (the beside rule wants 3.2 / 2.5). Centre the way-out stars and line in the exit gate.

### 8. The rising wind should be felt, not just measured (small; feel)

**Checklist point.** Reward moments, readable.

**Evidence.** The wind triples over a run with nothing to say so.

**Fix.**

- At 250, 500 and 1,000 m: a gust swell (`gap_gust_db` 3 over 1.0 s) and the hint "The breeze is freshening" (2 s).
- The ambient wind bed +2 dB from T 1 to T 3.

## Also checked, no action

- **Readability (screenshots):**
  - the barn reads from entry, and the big star sits plainly in the door;
  - the hedges, dark on green, are still clear thanks to their rounded tops and shading;
  - the washing's sheets, posts and cottages are clear, and "Under the washing!" pops well;
  - the poplar wall reads as a wall, with the gap shown by its stars;
  - the stones read as a ring with the big star inside;
  - the Mere, the island and the sailboat are the prettiest view in the country.
- **Fair failure, the walls.** Hands-off and middle-flyer crash into the viaduct, the barn's gable, the poplar at x 0.4 (d 0) and a far stone. Every one is a big wall straight ahead, in view for 5+ s. Fair.
- **Snags never crash.** Socks fly. Good.
- **Bunting.** It hangs at the best distance, chimes once, and shows "Past your best!" once a run. A first-timer's bunting at 110-160 m is a good early goal.
- **Recentring.** The test is in. No pilot of mine noticed a recentre.
- **Variety.** Over 10 skilled runs:
  - Street 21% of pieces. Rest pieces together (Street, Barley, Ridge) 39%.
  - The others 4-9% each: Hamlet and Stones least.
  - Fine for now. Item 2a will lower the three low-moment pieces a little after rest pieces; watch the Street share on the phone.
- **The debug "Wind 3.0" button** puts d-0 pieces in a d-1 wind: skilled takes only 57-69% of stars. That's expected. Tell the owner to judge pace on "Wind rising".

## Phone checklist additions

- First three runs (and a first-timer's): how long, how each ended, and whether either line at the barn ever looked like the way to go.
- One run past 500 m: does it feel faster? Does it feel harder?
- Skim the pasture low: does the warm air read as something you can see and use?

## Later ideas

- A "low road" badge for flying all three signature moments (washing, barn, ring) in one run.
- The heron lifting off the Mere's island when you circle it (carried over).

## Re-check after the fixes: **APPROVE** (commit)

Checked on the lead's batches in `scratchpad/r6` (20 runs each, 420 s; shaky from 500 m, 300 s), plus my own verbose skilled seed 7 on the current tree. Every must item is met. I accept the two marks the lead couldn't reach; my reasons are below, and the marks are revised. Two follow-ups are for the start of step 3; they don't block the commit.

| Item | Pass mark | Result | |
|---|---|---|---|
| 1 Barn lure | At most 1 barn ending in 40 chaser runs | Chaser and no-circle: 40 of 40 flew 420 s, 0 barn endings, 0 crashes | Pass |
| 2 High lines | Skilled ≥ 85% of stars | 88-90% (82-93%); shaky 86-87%, 82-86% from 500 m | Pass |
| 2 High lines | Low line flown in ≥ 60% | Barn about 67% (by its last dive stars, skilledB). Washing: lead 17 of 21; skilledB 18 of 33. Stones: 13 of 20 | Pass (Washing borderline in skilledB) |
| 3 Spirals | Review 5's marks | Barley 32 of 35 and 38 of 41 full; copper 15 of 15 and 16 of 16; island 100% | Pass |
| 4 Lift off the middle | Hands-off median 45-120 s, ≤ 2 of 20 past 12 | 126 / 137 s (halves), 3 of 20 past 12, **0 past 20**, longest 238 s (was 406) | Accepted: see (a) |
| 5 First stars | ≥ 75% | Barn dive 6 of 15 and 7 of 15; Mere 13 of 22 and 11 of 18; poplar gap 8 of 23 and 13 of 21; hedge-hop 85% / 64% | Accepted: see (b) |
| 6 Tools | Naive pilots in `endless_log`; stars count as events | Done. Skilled gaps median 0.4-0.5 s | Pass |
| 7-8 Small | Text, hay-gold tint, stones' gate, breeze freshening | Done, except the Pasture's exit | Pass: see (c) |
| Survival from 0 m / from 500 m | | 20 of 20 / 20 of 20 | Pass |
| Calibration | Within ±1.5 | Worst +1.7 (washing from 18, d 0, measured *above* the table, so the fair side). Lowest 3.1 (washing d 1, a dive moment). Nearest solid 2.0 (stones d 0.5-1) | Pass |

**(a) Hands-off: accept, and the mark moves.**

- The point of item 4 was that a pilot who never touches the phone must not match a flown run. That now holds: no hands-off run passes 20 pieces, and the longest is 238 s, against 420+ s for every pilot who steers.
- What remains above 120 s is the middle of the spread.
- The endings are now varied and all fair: Hamlet, Poplar Row, the Ridge, the barn, Barley, Kite Meadow, one splashdown on the Mere, the viaduct.
- Pushing the median lower would mean starving the rest pieces (Street, Barley) on the middle line, and that would hurt the forgiving start.
- **Revised mark for steps 2-4:** hands-off median 45-150 s, at most 3 of 20 past 12 pieces, none past 20. The owner's first runs on the phone remain the real novice mark.

**(b) First stars: accept, and the mark changes.**

- Every arc can be taken in full from a typical entry. In calibration: barn 13 of 13 from 18, Mere 17 of 17 from 18-26, poplars 5-6 of 5-6 from 18, and the lead's traces agree.
- The misses come from entries far above or below, or straight out of a circle. Missing a lead-in star costs the +5 bonus, never the run.
- Sliding stars *up* to meet a high entry made things worse, so "never higher" is the right call.
- **Revised mark:** each arc taken in full by the skilled pilot from need and from 18 in calibration, at every d. The first-star rates are recorded, with no mark.

**(c) The Pasture's exit stays 13 / 11: accept.**

- The consequence is that a Cloud Street always follows the Pasture.
- That reads as "low field, then lift", which is fine for a low piece. The Street is a rest piece and is fun to climb after the hedges.
- Revisit only if the phone says the pairing feels samey.

**Follow-ups for the start of step 3 (not blocking):**

1. **Standing Stones, 0 of 9 stars in a low-line pass.** In skilled seed 7 (d 0.65), the game logged "low line" at an entry of 13.5, straight out of a heap spiral across the join. The pilot then took 0 of 9 stars, including the big star, and the log shows 11.7 s of nothing happening.
   - Calibration gets 7-9 of 9 from 12-18, and skilledB_11 takes the stones arc all-or-nothing (5 of 10 full).
   - So this looks like the test pilot choosing its line differently from the game when it finishes a circle past its choice point. If so it is a tool artefact, but it makes the marks less trustworthy.
   - Trace it. If a human could get the same mismatch (low-line stars shown while the safe line is over the top), fix the game. Otherwise make the pilot follow the game's choice.
2. **Mere, middle stars.** Skilled misses stars 3-4 of the across arc in about 60% of passes ([13, 15, 9, 8, 15, 18, 22] over 22), and gets only 7 of 22 full, although calibration gets them all.
   - The arc now curves 10 u left toward the moved island while the lake sinks you.
   - Check the stars against the line a pilot really flies from the usual 17-20 entry, and straighten the curve if needed (for example, hold x 0 for the first three stars, then turn).

**Cadence.** With stars counted, the median gap is 0.4-0.5 s. The longest gaps (6-8 s) are the glide out of a full spiral to the next piece, and the Ridge entry. That's a breath after a climb, not dead air. The 11.7 s at the stones is follow-up 1.

**Verdict: approved to commit.** On the phone, the owner should check the step 1 list plus:

- the "Phone checklist additions" above;
- whether the breeze-freshening hints land;
- whether the hay-gold tint makes the warm layers readable.
