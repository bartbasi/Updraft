# Fun review 5: Endless step 1

**SEND BACK.** The Endless loop works. The look-back, the six pieces in a new order every run, the tinks and chimes, the arch whoosh and the retry all read as a game, and no test pilot crashed into anything it couldn't see. Two things must change before the phone. The Barley spiral pays for the wrong flying (item 1), and three star lines start where the usual pilot can't be (item 2). Items 3-4 should be done in the same pass. Items 5-8 are small. On the novice question: the test novice is a fair stand-in after all, because the stars are the line. Step 1 has no way to run out of height for anyone who follows them. That is expected before the rising wind and hazards, so I am not asking for tuning to chase the mark (see "The novice question").

## Evidence I gathered

- `endless_log` runs at wind 1.5:
  - verbose skilled seed 3 and novice seed 1 (200 s);
  - skilled ×6 for 600 s;
  - `--calibrate --piece=street` on today's build.
- My flights ran on the 13:45 build. The lead's 14:11-14:25 edits (the test-pilot Callable, the run counter for card timers, kit keys) leave the spiral, the star and line layouts, the touchdown rule and the look-back eye as I measured them.
- The lead's batch logs: novice ×20, shaky ×20 and an older `calibrate.log`.
- My scratch pilots, in the session's scratch folder (`sim/firsttimer.gd`, `sim/spiraltrace.gd`; not in the repo). All four use `Autopilot.novice`'s hands: reaction 0.15-0.35 s, wobble 0.15-0.35, steer gain 1.2-3.2.
  - **Hands-off:** no input at all.
  - **Middle-flyer:** keeps to the valley's middle at a neutral glide. It never circles and ignores the stars. It dives for the middle arch once it sees the viaduct wall (reacting 30-70 u out).
  - **Star-chaser:** flies at the nearest untaken star it can see ahead (within 45° and 45-70 u), otherwise drifts back to the middle. Also dives for the arch. Two kinds: one never circles; one circles 4-10 s, either way round, when it hears beeps in a big thermal.
  - **Trace:** the skilled pilot's Barley climb, every 0.1 s, star by star.
- Contact sheets `e2_sheet.png` and `cards_sheet.png`, and single shots `e2/00` and `e2/04`.

## Step 1 marks (§11)

| Mark | Result | |
|---|---|---|
| 4 Generator | Lead's 10,000-sequence test | Pass (not re-run) |
| 5 Calibration | Street from its need now climbs out (lowest 3.6-3.8 u over the ground at d 0; it was a touchdown in the older log). Every out is within ±1.5 at wind 1.5. Nearest solid 4.0 (Hamlet). | Pass. The 3.6 is under the 4.0 clearance only because need 4 is entered at exactly 4. Make the Street's need (4.5, 6). |
| 6 Skilled ≥ 85% of stars | Lead: median 87%. Mine: seed 3 71%; 600 s runs 71-77%. | **Unsafe.** It includes spiral jackpots (item 1). Re-measure after items 1-2. |
| 7 Shaky | 20/20, 83% | Pass |
| 8 Novice 45-90 s, 25-50% of stars | 20/20 still flying at 200 s, 76% | Fail as written. See "The novice question". |
| 9 Cadence: median 2-4 s, longest ≤ 5 s | Median 1.7-2.8 s. Longest 7.6-11 s as logged. | The log doesn't count star pickups, so circling the Barley and flying along a street show as "nothing happening" when stars are ringing every 0.5-0.9 s. The real dead air is the Street from a low entry: 8 s climbing under stars you can't reach (item 2). Ask: log each star (quietly) for the gap figures. |

## The novice question

All runs: 20 seeds, wind 1.5, 200 s cap.

| Pilot | Median time | Pieces | Stars | How the runs ended |
|---|---|---|---|---|
| Hands-off | **82 s** (58-171) | 5 | 22% | 12 crashed into the viaduct's face. 8 ran out of height during or just after a Ridge or a Hamlet. |
| Middle-flyer | 167 s (65-200) | 11 | 21% | 15 ran out of height: 7 over a Hamlet, 4 over a Ridge, 4 on the piece after one. 5 still flying. |
| Star-chaser, never circles | 200+ | 14 | 67% | none |
| Star-chaser, circles on beeps | 200+ | 13 | 71% | none |
| Lead's novice (ideal lines + wobble) | 200+ | 13 | 76% | none |
| 600 s runs: skilled ×6, star-chaser ×6, non-circling chaser ×6 | **600+, all 18** | 36-41 | 55-77% | none, past 1,000 m (d 1 for the last 6 minutes) |

Not measured: wind 3.0. My runs stalled on the mid-review tool change. Lead, please run skilled ×6 at `--wind=3.0 --max=400` before the phone, so the owner knows what the Wind 3.0 button will feel like.

What it says:

1. **The novice model is fair enough; the gap is in the game.** A pilot who knows nothing except "fly at the gold stars" does as well as the line-following novice. In Endless every star line runs into lift: the street's ribbon, the ridge band, the plumes, the shingle thermal. So chasing stars is staying up. The one thing the stars don't teach is circling, and circling isn't needed: the non-circling chaser flew furthest.
2. **The 45-90 s / 25-50% mark describes a pilot who doesn't steer at all** (82 s, 22%). I wrote it expecting first-timers to miss most lines. The star lines make the lines easy to find.
3. **In step 1, a run ends only by touching something.** The generator's fairness rule works: no line-follower ever ran low. That leaves three things that end runs: the viaduct's face, grazing a hillside or the ridge (item 3), and the church at d 1. A real first run on the phone will sit between the middle-flyer and the star-chaser. My guess is 2-4 minutes, ended by one of those touches. A competent run may not end for 10 minutes.
4. **Is it too forgiving?** For a first run, no: a kids' game should let you fly on. For a runner, yes, but the pressure was always going to come from step 2-4: the rising wind, sink (Mere, rain), and obstacles you must time (hedges, barns, poplar gaps, washing, pylons). The fairness guarantee means height alone will never end a good run. In a runner, mistakes under pace end runs, and step 1 has almost nothing to mistime. Tuning lift or margins down can't fix that without hurting the forgiving start, so I'm not asking for it.

**For step 1 (tuning only), item 5:**

- `endless_full_distance_m` 600 → **400**. A star-follower reaches d 1 (arch span 7.5, hoops 2.2, the church 3.5 u off the line, Barley off the middle) at about 3.5 minutes instead of 5.5, so the owner sees the whole range in one sitting.
- Change mark 8 for step 1 to: **hands-off pilot median 45-120 s and ≥ 3 pieces** (passes at 82 s). Record the star-chaser, with no mark.
- Phone checklist, add:
  - your first three Endless runs, with how long each lasted and how it ended;
  - if possible, a first-timer's first three (a child's is best);
  - one run at Wind 3.0 to feel the pace step 2 brings.

**Record for step 2:**

- Add the hands-off, middle-flyer and star-chaser pilots to `endless_log` (`--pilot=handsoff|middle|chaser`).
- Set the step 2-4 novice marks on them, not on the line-follower:
  - hands-off 45-90 s;
  - star-chaser median 2-4 minutes with the rising wind.
- If the phone says first runs are much longer than 3 minutes, build the Mere (sink) and the Pasture (hedges) first in step 2. They are the cheapest pressure.

## Items, most important first

### 1. The Barley spiral pays for flying straight past and misses the pilot who circles (must)

**Checklist point.** Style points feel earned. Feel (the climb moment).

**Evidence.**

- **Jackpot for no input.** Hands-off, seeds 10 and 16: "arc started" 43.5 s, then "Full spiral!" 43.7 s. That is all 10 stars and the +5 in 0.2 s, flying straight down x 0 with no input. It is common:

  | Pilot | Full spirals |
  |---|---|
  | Hands-off | 8 in 27 Barleys |
  | Middle-flyer | 8 in 41 |
  | Star-chaser that circles | 9 in 55 |
  | Star-chaser that never circles | 0 in 59 |

  - The lead's novice batch, whose circles stop after 3.5 s, shows 30 of 46 spirals full. Eight of stars 2-10 were taken exactly 30 or 31 times, so those 30 are cascades.
  - Old calibration: from 26, 10/10; from need 10, 2-3/10.
- **The mechanism.** The anchor test passes when you fly past the centre tangentially at 2.5-12 u. Each star taken re-lays the rest 30° ahead on your radius, clamped to at least 4.5. At r 4.5 that is 2.4 u away (3D, including the 0.95 u rise), inside the 3 u pickup. So the same pickup loop takes the next star, which re-lays again, and so on. All 10 go in a tick or two.
- **The careful circler loses out** (trace, skilled seed 3, first Barley):
  - It anchored at 40.7 s while the pilot was still cutting in across the thermal (its radius fell to 3.0). The stars were laid at r 8.1, going clockwise (−30°, −66°, …). The pilot then circled anticlockwise. The direction is never re-judged, so after each re-lay the stars sat behind it again.
  - Each re-lay spreads the remaining climb over all remaining stars: about 0.6 u per star at y 18. The core lifts 2.5 u per 40° at d 0 (3.8 u/s). The pilot rose past them and took 3 of 10.
- **The climb is too short for 10 stars.** It is about 0.7 of a lap at either end of the range:
  - d 0, from y 9 to the top − 2: 3.9 s, 0.68 laps;
  - d 1: 4.5 s, 0.77 laps.
- To the lead's question: as built, it reads as stars jumping. On anchoring the whole spiral slides up to 10 u to the other side, and then again after every star.

**Fix.** This is feel for the lead's own mechanism; the numbers are mine.

1. **Never lay a star inside the pickup reach.** The next star goes at least 4.5 u of arc ahead: 45° at r 6, 57° at r 4.5. Take at most one spiral star per 0.25 s.
2. **Anchor only on a real circle:** the pilot has turned at least 120° of heading while within the thermal's radius of its live centre. Until then, the drawn helix stays where it is, low on the near side as the invitation.
3. **Re-judge at every re-lay** the way round, the radius and the climb from the plane's current velocity. It is already passed in as `_velocity`.
4. **Rise per star** = current climb rate × the time to fly one step at the current speed and radius, clamped to 0.5-3.0, with the last star at or below top − 2.5. In the d 0 core that is about 2.5 u.
5. **Spiral 10 → 6 stars, 40° apart.** 6 × 40° fits the 0.7-lap climb from y 9 at every d.
6. Skip a re-lay that would move no star more than 1 u. With 3 and 4 the stars barely move, so it reads as the spiral forming ahead of you. Keep the 0.5 s slide.

**Pass marks.**

- Flying straight through within 3 u of the centre takes at most 1 spiral star.
- The skilled pilot from y 9 takes at least 5 of 6, with a full spiral in at least half the Barleys.
- A novice circling at most a lap takes 2-4.

### 2. Three star lines start where the usual entry can't reach (must)

**Checklist point.** Style points feel earned. No dead air (the Street).

#### Hamlet chimneys

**Evidence.**

- Full arcs: 7 of 43 (lead's novice), 9 of 45 (shaky).
- **Plume 0's stars are too low.** They sit at y 12-13.5 from z −19, but the Hamlet is usually entered at 20-27.5 (after a Street, Ridge, Barley or Viaduct).
  - From 24.5 that is a 1:1.5 dive right at the join. The plan's own rule is 1:3.4.
  - Shaky pilots took plume 0's stars 9-28 times in 45. The skilled pilot got to 13.6 at z −20, just missing.
- **The 4th star of plumes 0 and 1 sits in the turn.** It is at z cz − 1.5, 2 u before the line's turn point, and the pilot turns about 5.5 u early (look-ahead). Shaky took it 9/45 and 10/45. Plume 2, with no turn after it, gets 42/45.

**Fix.**

1. Plume 0's base height 12 → 15. Plumes 1 and 2 keep 13 and 14. The line's first two points become (−8, 15, −16) and (−8, 16, −27).
2. Three stars per plume, at 5, 3 and 1 u upstream of the chimney (z cz + 5, + 3, + 1), rising 0.5 per star from the plume's base: plume 0 at 15, 15.5 and 16. That makes 9 per Hamlet. The last star is then 4.5 u before the turn point, about 1 u into the pilot's early turn, where the path has moved under 0.1 u.
3. The exit stays about 15, so the table stands.
4. Also, my own spec's slip: C1's chimney (z −23.5, top 8) stands inside the 30 u entry buffer, where the limit is 6. Optional: cottages to z −27 / −51 / −75 (24 apart) and the church to −65. If you do, move the stars and line with them.

#### Cloud Street from a low entry

**Evidence.**

- The stars sit at 22-25. After a Hamlet (exit 15) the street lifts you under them for about 8 s before star 6-8 is in reach. That stretch is the logs' 7.6-8.2 s "nothing happening".
- Calibration from need: 0/12.
- Lead's novice batch: the first star taken 20 of 55 times.

**Fix.** Lay the street's stars per placement from the entry height, as its line already does:

- y_k = min(25, (h_in − 1) + lerp(1.4, 1.0) · k) when h_in < 23;
- today's 22 + 3k/11 otherwise.

1.4 and 1.0 are the street's climb per 6.5 u star at d 0 and d 1, between neutral and slow flight (d 0: 1.19-1.66; d 1: 0.84-1.25).

#### Viaduct dive

**Evidence.**

- The first two stars, (0, 19, −10) and (0, 17.3, −16), were taken 1 time in 35 by the lead's novice. From an entry of 24.5-27.5 they need a 1:1.5-1:2 dive at the join.
- The dive arc was full 0 of 35 times (novice) and 22 of 38 (shaky).

**Fix.** 6 stars every 6 u from (0, 19, −16) down to (0, 9, −46), a 1:3 dive. The line's first point moves to (0, 19, −16).

### 3. A gentle graze of a hillside ends the run, but a harder hit doesn't (should; owner's call if the lead disagrees)

**Checklist point.** Fair failure.

**Evidence.** `FlightModel.resolve_contact`:

- A touch slower than 0.8 u/s into a surface is a slide.
- A slide on anything flatter than 45° (normal.y > 0.7) sets `grounded`, and Endless ends the run as a touchdown.
- That covers the valley sides up to |x| ≈ 60 (about y 16) and the whole ridge face (steepest 0.83, normal.y 0.77). The cottage roofs (40°) count too.
- So drifting gently into the ridge while hugging it ends the run 15-20 u up, which is what How to fly tells you to do ("close to it"). Hitting the same face harder bounces you on.
- Decision 2 meant "a bounce off a slope is not a touchdown". A graze feels like a bounce.

**Fix (Endless's ending rule only; the Course is unchanged).** A touchdown needs ground flatter than 25° (normal.y > 0.9), or a slide lasting 0.5 s. A shorter slide on anything steeper nudges you off like a bump: `glance_speed_keep`, the tap and the wobble, and it breaks the star arc as a bump does.

**Check.** A scratch pilot that drifts into the ridge face at 0.3-0.5 u/s survives with a bump. One that lands on the floor still touches down.

### 4. The look-back puts the balloon on top of the lake (should)

**Checklist point.** Reward moments (the third reveal).

**Evidence.**

- `e2/00_t000.3`: the balloon sits right on the lake, and the windmill is a speck in the haze.
- The camera aims at the flyer from straight ahead and above, (0, 4, −10), so the balloon lines up with the middle of the bowl and covers the lake.
- The island and the boat (in the plan's backdrop list) aren't drawn.

**Fix.**

- `LOOK_BACK_EYE` (0, 4, −10) → **(−6, 2.5, −9)**. The balloon then sits to the left of the lake and the Gap's notch, and the swing into the chase position comes round from the side.
- Capture t 0.3 and 0.8 and check that the lake, the island's spot and the notch show clear of the balloon.
- Optional: draw the island as one low green cone with a sand rim.

### 5. Step 1 pace: d 1 sooner (small)

`endless_full_distance_m` 600 → 400, plus the mark and checklist changes in "The novice question". Step 2 sets it to 1,000 with the rising wind, as planned.

### 6. "Wrong way!" with no warning (small)

**Checklist point.** Fair failure.

**Evidence.** The run ends 8 u back past the start. A child who turns round to fly back to the lake they have just been shown gets "Wrong way!" about 9 s in, with nothing said first.

**Fix.** When the flyer is within 12 u of `WRONG_WAY_Z` and heading within 60° of upwind, show the hint "The breeze is behind you: fly on!" (2 s). End the run only at the line, as now.

### 7. The card should say where (small)

**Checklist point.** Fair failure, readable.

**Fix.** Title "Touchdown" → "Touchdown in the Hamlet" (or "Crumpled at the Viaduct"), using `piece_name`, which is already kept.

### 8. How to fly (small; text only)

Accurate and in a sensible order, and the tone is right: plain, warm, never jargon. Fixes:

1. **Rising air, first line.** "Whenever you are rising you hear soft beeps" is not true: pulling up out of a dive rises in silence. Make it: "When rising air is carrying you up, you hear soft beeps, faster and higher the stronger it is."
2. **Ridges.** "Fly along the slope, close to it" is the advice that ends Endless runs (item 3). Make it: "Fly along the slope, a little way out from it. Don't touch it: in Endless, landing on a hillside ends the run."
3. **Thermals list.** Add the shingle bank by the viaduct (Endless). In Endless the air carries you and the thermal alike, so you stay centred without chasing it. The Endless paragraph covers that, so this is optional.
4. **Sounds.** Add:
   - "A tink: a star. Each star in a row along a line rings a note higher."
   - "A bell: through a kite ring."
   - "A flutter: a kite ring snagged you."
   - The whoosh line: "…or through an arch at speed."
5. **Endless, the viaduct.** Say it plainly; it is what stops most pilots who don't steer. "The viaduct's wall is solid stone: dive through an arch (the middle one holds a big star) or go over the top."
6. **Endless, one tip.** The most useful sentence in the guide for staying up, by my test pilots: "Follow the stars: they lead into rising air."
7. **The spiral sentence.** After item 1: "The Barley Field's spiral starts low over the field. Dive down to it, then circle: the stars form in front of you as you climb."
8. **The Course, first line.** "A kid lets the balloon go (or throws the paper plane) in the bedroom."
9. **Optional opener** above Controls: "Fly as far as you can. You are always gliding gently down; rising air takes you back up."

## Also checked, no action

- **Cards.** "Endless unlocked!" in gold with the focus on [Endless], and the Endless card's lines match §1.2.
- **Height bar.** It reads well on the left.
- **Hamlet weave.** The church fills the view on the swing to plume 1 (`e2/04`). That is a landmark, 6.5 u from the line at d 0.25 and 3.5 u at d 1, and in view from far off. Fair.
- **Arch passes.** 9.2-9.7 u/s skilled and 7.8-9.4 for the chasers, so the whoosh, swell and +3° fire. It is the thrill as planned.
- **Barley line.** The dive to y 9 at the near edge is right. Arriving high is the usual case, and the spiral should be climbed from below.
- **Thermal life at wind 1.5** (24 s at d 0) never cuts a climb short. It only starts to matter at wind 3 and d 1, as planned.
- **Ridge stars.** A pilot slowing in the band, as How to fly advises, out-climbs the Ridge stars (15 → 21.5 over 48 u; slow flight climbs about 14 u there). Keep it: holding the line instead of floating up is a fair skill. Revisit if the phone says it feels wrong.

## Later ideas

- A seed shown on the card so a good country can be flown again (the plan's "seed codes").
- An ending that is a moment: when the run ends, a slow 1 s camera pull-back over the country you crossed, with the distance ticking up (no new system: camera and HUD).

## Re-check after the fixes: **APPROVE**

All eight items are in. Checked one Godot process at a time, in batches of 8 at wind 1.5 and 200 s, on the build after "after the code review and fun review 5".

| Item | Pass mark | Result | |
|---|---|---|---|
| 1 Spiral | A straight pass takes at most 1 star | Hands-off ×8: **0 full spirals in 8 Barleys** (was 8 in 27), stars 16-26% | Pass |
| 1 Spiral | Skilled ≥ 5 of 6, full in at least half | Lead's skilled ×8: 21 of 21 full | Pass |
| 1 Spiral | A novice circling about a lap takes 2-4 | Circling star-chaser ×8: 2-5 of 6 per Barley, 1 full in 22 | Pass |
| 2 Star lines | Arcs completable from the usual entry | Lead: chimneys 95%, street 96%, dive 92%. Chaser ×8: stars median 79% (was 71%) | Pass |
| 3 Graze rule | none | In the code (steeper than about 25° nudges; flat or a 0.5 s slide ends the run). Not flown by my pilots, which never touched a slope. | Pass; check on the phone along the ridge face |
| 4 Look-back | Lake and notch clear of the balloon | `e3_sheet.png` t 0.3: the lake and the island's sand below the balloon, the notch and windmill to its right | Pass |
| 5 Distance | 400 | `endless_full_distance_m` 400 | Pass |
| 6-8 | Hint, card title, How to fly | "fly on!" hint, "Touchdown in the Hamlet" titles, all my text changes present | Pass |
| Mark 8 (revised) | Hands-off median 45-120 s, ≥ 3 pieces | 77.5 s (58-143), 7 of 8 past 3 pieces, 3 crashed into the viaduct, 5 ran out of height | Pass |
| Mark 6 | Skilled ≥ 85% | Lead: 94% | Pass |

Still open, as recorded: the wind 3.0 batch; the three naive pilots in `endless_log` for the step 2 novice marks; the owner's first-run lengths from the phone.
