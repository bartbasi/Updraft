# Phase A section review: the new opening (bedroom to arch) and scoring feel

**Verdict: SEND BACK.** There are three must-fix items, all small: one piece of arch geometry and two
corridor widths in `tuning.gd`. Everything else is approved. Of the built sections, five pass and two
(the stair hall and the arch) go back.

Reviewed against the working copy (`scratchpad/next`), the skilled-pilot screenshots (`shots_opening`) and
the flight logs. I also ran my own fixed-input sweeps with the real collisions: a pilot who turns at a set
spot with a set bank, dives with a set input, or never dives. I used a scratch script outside the repo and
did not modify the copy. The novice autopilot follows the optimal style line with wobble, so its scores
(20/20 runs reach outside, bedroom-turn style averages 94) overstate what a first-timer will do. The sweeps
are the better guide to forgiveness and to how hard each style moment is.

| Section | Verdict |
|---|---|
| Opening shot and bedroom glide | **APPROVE** |
| Door turn | **APPROVE** |
| Sunbeam | **APPROVE** (optional path tweak, item 5) |
| Gallery and skylight | **APPROVE** |
| Stair dive and downdraft | **SEND BACK** (item 3; item 4 should follow) |
| Landing turn | **SEND BACK** (item 2) |
| Arch into the living room | **SEND BACK** (item 1) |
| Scoring feel (pop-ups, HUD, end card) | **APPROVE** with items 2, 3 and 7 |

---

## Ranked fixes

### 1. MUST: Floaters crash into the wall above the arch every time (fair failure, forgiving)
- **Evidence.** I flew a pilot who never pushes the nose down in the stair hall (pitch input 0 or +0.1),
  turning right at x 11, 7 or 3 with full or half bank. All **12 runs crashed** head-on into the wall
  above the arch, at about (-1, 12.5, 15.3). They reach z 16 at **y 11.5 to 14.0**, and the arch top is
  11.5. Only a pilot holding a slight dive (-0.15) gets under it, at y 9.0 to 10.9. The cause is visible,
  but this is the most common beginner behaviour. It ends the run 25 s in, at the end of the best part,
  and the retry then replays 19 s before the stairs again. The plan accepted this risk; the measurements
  say it is too harsh.
- **Fix (layout).** Add a **sloped header (a deep coved arch head)** on the stair-hall side of the arch.
  - It is a solid slope, **35°**, with its underside running from **(y 11.5, z 15.0)** up to
    **(y 15.5, z 20.7)**, across **x -7.6 to 6.6** (post to post). It is filled solid back to the wall,
    so there is no pocket behind it.
  - Draw it in trim colour (`fbf7f0`) with a slightly darker underside band, so it reads as the arch's own
    curve, lit warm from the living room.
- **Measured with a runtime what-if** (an extra collider added in my scratch script):
  - All 12 floaters now **glance down through the arch** with 1 to 3 soft bumps on the header (strength
    1.3 to 3.4, the same as a door-post scrape). They enter the living room at 4.8 to 6.5 u/s and fly on past z -40.
  - All 47 dive lines from the stair sweep are unchanged; none of them touch it.
- **Keep the slope at 35° or less.** A level plane meets it at the slope angle. A plane climbing at 10°
  meets it at 45°, still under the 50° head-on crash angle.
- Leave the downdraft strength at 0.6. The plan's reasoning still holds: 1.0 puts hard divers onto flight
  2's steps.

### 2. MUST: The landing-turn style corridor is too narrow; nobody can get "Perfect" (style earned)
- **Evidence.** Skilled pilot 44/150 (quality 0.29), novices average 59. In 47 fixed-input lines (dive
  input 0 to -1.0, turn started at x 13 to 1, full right bank), **only 10 earned anything**. The best line
  scored **100, which is quality 0.67**: a held -0.5 dive with the turn started at x 5 to 7. So at radius
  2.0, **no line in the sweep reached the 0.85 needed for "Perfect"**.
- **Why.** The path is right: it is the fast, still-diving carve, which is the line worth rewarding. But
  it is 35 units long and asks for two skills in a row, and 2.0 units is too tight for that.
- **Fix (tuning).** `style_moments.landing_turn.radius` **2.0 → 3.0**. Keep the path and the 150 points.
  The same 47 lines re-scored at 3.0:

| Dive input before the turn | Now (r 2.0) | At r 3.0 |
|---|---|---|
| none | 0 | 0 (a floater earns nothing, which is correct) |
| -0.3 | 0 | 0 to 32 |
| -0.5 | 0 to 5 | 41 to 78 when turning at x 1 to 7 |
| -0.8 / -1.0, turn on time (x 5 to 7) | 17 to 76 | 93 to **131** |
| -0.5 held through a full-bank turn at x 5 to 7 | 95 to 100 | **139 to 141** |

  - At 3.0 the scores spread properly: 3 of 47 lines are "Perfect", and about half earn something.
  - If the phone test says it is still too hard, 3.5 is the fallback: 8 lines score 100 or more instead
    of 5, though still only 3 reach Perfect.
  - The bots never use full bank (they peak at about 26° of the 35°), which is part of why they score low.

### 3. MUST: The downdraft moment pays nearly everyone in full (style earned)
- **Evidence:**
  - Any dive from -0.3 to -0.8 started at the top step scores 107 to 120 of 120.
  - A pilot who does not dive at all still gets 56 to 61.
  - Skilled 120, novices average 114. It is the cheapest 120 points on the course and does not separate
    a good dive from any dive.
- **Fix (tuning).** `style_moments.stair_downdraft.radius` **2.0 → 1.5**. Keep the path. Re-scored:
  - No dive: 3 to 17, still "a few points".
  - -0.3: 35 to 102.
  - -0.5 to -0.8: 112 to 120 (70 to 85 if the turn starts as early as x 13).
  - Slamming at -1.0: 64 to 82, because "ride the middle of the cold air" now means something.

### 4. SHOULD: Make the stair dive sound fast (feel, reward moment); may ride with Phase B
- **Evidence.** The stair dive is already the fastest moment of the run:
  - Skilled top speed **9.2 u/s**. The radiator reaches 8.0 and the kettle 8.1, and those are mostly the
    lift's vertical speed.
  - Committed divers reach 10 to 12 u/s.
  - But the wind curve (`(speed - 2) / 10` in `game.gd`) makes 6 → 9 u/s only **+3.5 dB**.
- **Fix (sound):**
  - `t = clamp((speed - 5) / 6, 0, 1)`
  - volume `lerp(0.10, 0.80, t)`
  - pitch `lerp(0.85, 1.45, t)`
  - Result: cruising at 6 u/s gets a little quieter (0.22), 9 u/s is +8 dB over cruise, and 11 u/s is
    full. Move these numbers into `Tuning`.
- I would try a camera FOV kick (70 → 78 between 7.5 and 11 u/s) in Phase B, not now. It also shrinks the
  plane, which is already small during the dive (see Phase B).

### 5. NICE: Sunbeam style path heights (style earned)
- **Evidence.** The skilled pilot scores 51/80. A centred hands-off line rises 18.8 → 20.7 → 22.9 → 23.5
  → 23.3 at x 95, 91, 87, 83 and 79. The path says 19.0, 20.5, **22.0**, 23.2, **23.8**, so the
  autopilot pushes the nose down against the lift at 7.2 s.
- **Fix (path).** Use **(95, 19.0, 41.5) → (91, 20.7, 41.5) → (87, 22.9, 41.5) → (83, 23.5, 41.5) →
  (79, 23.4, 41.5)**, radius 2.0. Update the matching points in `Autopilot.course_line()` too.
- The beam is broad: lines at z 38.8 and z 41.5 differ by 0.5 or less in height. So this moment stays a
  friendly "fly clean and let it carry you" moment, and that is fine for the first lift of the run.

### 6. NICE: Speckle where the light shafts touch the gallery walls (readability, polish)
- **Evidence.** Dotted hatching on the south wall at the skylight (screens t 12.0 and t 14.6), and
  diagonal hatching on the north wall at the sunbeam exit (t 7.0).
- **Likely cause:**
  - The skylight box is z 37 to 42, so its shaft's south face lies exactly on the south wall (z 37).
  - The sunbeam's floor patch is z 35 to 46, so its north edge sits on the north wall (z 46).
- **Fix.** Draw each shaft 0.2 inside any wall it touches. The lift zones can stay as they are.

### 7. NICE: End card clarity (scoring feel)
- `Distance  79 m   791` does not say what 791 is. Show **`Distance  79 m  =  791`**.
- Show the number of moments hit, **`Style  655  (7 of 8)`**, so players know there is more to chase.
- Pop-ups are good as built: gold, larger and brighter for a perfect pass, ink-coloured for an ordinary
  one, with their own sound, and never on screen at the same time.

---

## Section notes (the approvals)

**Opening shot and bedroom glide: APPROVE.**
- The first frame matches the plan:
  - The plane fills about 23% of the screen width.
  - The door is visible 28 units ahead.
  - Golden light falls in from the left of the doorway.
- `intro_duration` is 0.65 s, not the planned 0.9 s. That is fine: the kid's eye is only about 1 unit
  from the chase spot, so the move is mostly a gentle look-up and reads as seamless (screens t 0.0 and
  t 0.5).
- The camera settles at 5.3 units behind and does not pull in at the door (5.0 to 5.3 all through the
  turn).
- The glide is calm and clear for 3.6 s before the first input is needed.

**Door turn: APPROVE.** It is forgiving for decisive and timid turners alike. Distances are from the
door's bedroom face; + means before the door:

| Bank | Clean | Glancing bump, flies on | Crash |
|---|---|---|---|
| Full | +4.5 to -6.5 (11 units, about 1.8 s) | n/a | +5.5: the west door post, side-on |
| 60% | +7.5 to -2.5 | -3.5 to -6.5 (landing wall) | +8.5: the west door post |
| 40% (timid) | +9.5 to +3.5 | +2.5 to -3.5 | -4.5 or later: the landing's south wall, head-on |

- Starting a full-bank turn earlier than +6.5 finishes the turn inside the bedroom. My scripted pilot
  does not re-aim, so it hits the west wall. A person will see the wall and re-aim; there is room, since
  the bedroom is 18 wide.
- The hands-off plane ends at the landing's south wall at 6.7 s, as planned.
- **Style is earned.**
  - At full bank, 76 points or more needs the turn started +2.5 to -0.5 (about 0.5 s).
  - At least 35 points comes from a window of about 0.85 s.
  - New players will often earn some, and only good timing earns "Perfect".

**Sunbeam: APPROVE.**
- It lifts the plane **+5.0 units in 2.0 s** (18.8 → 23.8, peak climb 3.75 u/s). That is a lift, not a
  teleport.
- The chime plays, and the shaft, motes and tall window read well (t 3.5 and t 5.4).
- It sits across the full width of the turn exit, so it pays every turn back, as intended.

**Gallery and skylight: APPROVE.**
- The skilled pilot spends 11 s in the gallery (x 80 → 16.5).
- The log flags 5.8 s (8.6 → 14.4) and 5.0 s (14.4 → 19.4) with no events. The flight log only counts
  logged events, though, and the plane passes the closed door and picture at x 66 (about 10.9 s) and the
  hall table and photos at x 30 (about 17.2 s). So something to see comes every 3.5 s or less.
- The skylight on the right is visible about 2.5 s ahead (blue panes and a yellow floor patch) and adds
  about +1.4.
- The plane reaches the top step at y 19.5 to 20.5, which is good height for the dive.
- Timing matches the plan within 1 to 2 s throughout:

| | Plan (good pilot) | Built (skilled) |
|---|---|---|
| Door turn | 5.0 to 6.4 s | 3.6 to 6.5 s |
| Sunbeam | 6.0 to 8.5 s | 5.8 to 8.4 s |
| Gallery | 8.5 to 21.0 s | 8.4 to 19.4 s |
| Arch | 26.6 s | 24.6 s |

**Stair hall (beyond items 2 to 4): mostly good.**
- The downdraft wisps and the cool blue light read clearly (t 19.0).
- The arch and living room come into view mid-turn (t 21.8).
- The camera has room: 5.5 to 6.1 units and no pull-in.
- In 47 dive lines there was **one crash**, and it is fair: a -0.8 dive held into a turn started early,
  at x 9, hits the landing newel post.
- Holding a -1.0 dive through the turn lands the plane on the landing ("Touchdown"). That is also fair.
- Late turns glance off the west wall.

---

## Phase B (whole-flight items, short)

- **60 s.** The skilled run is 52.3 s: out of the window at 42.7 s, then a 9.7 s glide outside. The
  plan's levers stand: gravity 7, then the gallery +15. This is still the owner's decision.
- **Arch → radiator.** The skilled pilot has a 6.4 s gap here. It is partly the bot slowing to hold
  height; check it on the phone.
- **The 9.7 s glide after the window.** Is it a payoff or a wait?
- **The lamp moment was never earned in 21 bot runs.** The bot's line passes beside the lamp. A scripted
  flight along the lamp's optimal path, with real collisions, should prove it can be flown; otherwise 150
  points are out of reach.
- **Plane readability during the dive.** The camera's follow lag puts it 6 units back, so the plane is
  only about 86 px wide at 1280 and nearly edge-on at the top step (t 19.0 and t 20.4). Options:
  - Darker crease and keel colours on the plane.
  - Camera height 1.0 → 1.3 over the stairs, as the plan suggested.
  - `follow_speed` 3.5 → 4.5.
- **A close-call whoosh** when passing within about 1.2 of a door post or newel post above 7 u/s. This is
  sound and effects only, but it needs a small proximity check, so it is the lead's call whether it counts
  as a new system.
- **If the gallery drags on the phone**, hang a pendant lamp at x 62 (shade bottom y 21, centre line) as a
  pass-left-or-right beat. Do not add it unless the playtest asks for it.

## Notes for the code-reviewer

1. **The arch header (item 1)** must be a collider of 35° or less. Please test that:
   - A level plane at y 12 to 15, heading -Z at 5 to 7 u/s, **bumps** (does not crash) and reaches the
     living room.
   - The good line never touches the header.
2. **The novice autopilot follows the optimal style line.** So `test_most_first_time_pilots_make_the_turn`
   and the novice style averages do not test first-timer timing. Consider fixed-input tests: a turn started
   at fixed points before and after the door, at full and half bank. Also a stair-hall floater test (no
   dive, then a right turn, must reach the living room), which would have caught item 1.
3. **Paths are written twice.** `Autopilot.course_line()` repeats the style paths, so a path change
   (item 5) needs both edits.
4. **Tuning values outside `Tuning`.** The wind-curve numbers (`game.gd`) and the camera's distance,
   height, follow speed, lean and intro duration (`follow_camera.gd`) are outside `Tuning`. The brief asks
   for one place.
5. **Retry and start-up timing on a phone:**
   - "Fly again" rebuilds the whole house in code; please measure crash → flying on a mid-range phone
     (the target is under 2 s).
   - The plane can be held in the air for up to 2 s before the throw.
   - The "Tilt to fly" hint starts fading 2.5 s after load, so on a slow phone it may be gone by the throw.
6. **Frame rate.** The capture's fps label read 40 to 51 in the stair hall and through the arch (t 20.4
   to 24.8), against 60 elsewhere. This is probably the screenshot tool, but please check overdraw there on
   the phone: the downdraft column, two light shafts, three particle systems and the whole living room are
   all in view.
7. **Parallel runs.** Running two Godot processes on this project at the same time made one fail to
   resolve `game.scoring` (an invalid property access). That is worth knowing if tests are run in parallel.

No open disagreements with the code-reviewer that I know of.

## Later ideas (new systems, for the owner)

- A short "moments hit" strip on the end card (eight small icons) instead of the count.
