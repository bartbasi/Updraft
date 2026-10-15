# Fun review 8: Endless step 4a (the kitten, homes, the Farmyard, the lee rotor)

**SEND BACK.** The fixes are small. The kittens are adorable, the homes are a lovely sight, and the telegraph is well timed. But the Farmyard's whole point, a near miss you earn by flying close, is not happening yet: Pip's paws stop 5-6 u short of every flyer, she never swipes at all at d 1 from mid or high entries, and the skilled pilot fills "Cat's whiskers!" on only a third of its passes.

Evidence:

- `batch4a_*.txt`, 20 runs per pilot.
- My own runs:
  - `--calibrate --piece=farmyard`;
  - skilled seeds 104, 107 and 109 (`scratchpad/fr8_s*.txt`);
  - `--calibrate --piece=warm_down`.
- The kitten and homes sheets.

## What works (keep it)

- **Cute, all three of them.** The big low eyes with two glints, the blush, the "w" mouth, the stubby white socks and the yarn ball all read as a baby animal. The yawn frame (eyes shut, pink tongue) is the cutest thing in the game. Nobody will call these scary.
- **Readable.** In `homes_70u` the pink shutters and a dark room make a kitten window pop at 70 u. In `farmyard_entry` Pip is a clear orange dot in her door from the piece's start.
- **The telegraph is well timed.** On the skilled line she watches 4.9 s before the lunge and wiggles 2.0 s before it (seed 104: watching 143.2, ready 146.1, lunge 148.1). Both beat the 4 s and 1.2 s marks.
- **Homes stay scenery.**
  - 0 lunges by any home kitten across all six batches.
  - 0 catches anywhere.
  - Middle and hands-off: 0 lunges.
  - Skilled meets 1-4 kittens a run, which is "occasionally" as the owner asked.
- **The rest:**
  - info text (§13) as planned;
  - catch card delay 0.9 s, so retry stays about 1.7 s;
  - the rotor only on the high crests, and the Warm Down's calibrate is unchanged in stars, out and lowest.

## Fixes, most important first

### 1. The Whiskers line is too far from Pip; move the barn, not the stars

**Checklist:** Style points feel earned; Reward moments.

**Evidence:**

- The reshaped "gentler swing" put star 5 at (8.6 - 0.3d, 8.6 → 8.1, -50). C is at about (16.3, floor + 6.2, -48.7).
- So the closest approach is now about **7.8 u (d 0) and 8.1 u (d 1)**. The plan was 6.7 / 5.6 ±0.3, and it now gets *further* as difficulty rises.
- Every logged miss is 5.0-6.2 u from the paw (skilled 5.1-6.2, shaky 5.2-6.0). Pip's paws stop about two kitten-heights short. That is not a whisker.
- At d 1 from h 18 and h 26 the calibrate shows **no lunge at all** (the flyer stays outside 9 u). The hardest Farmyard has no cat in it.

**Fix (layout).** Keep stars 5-7 where pilots can fly them. Instead, shift the barn (BARN, the yard paint, the cart doors, the hood, the beam and PIP_AT together) toward the line by **lerp(1.0, 2.3, d)** in x:

| | d 0 | d 1 |
|---|---|---|
| Barn's left wall | x 13.0 | x 11.7 |
| PIP_AT.x | 15.5 | 14.2 |
| Closest approach (horizontal at star 5) | about 6.85 | about 5.9 |
| Wall clearance, star 6 | 4.0 | 2.5 |
| Wall clearance, star 5 | 4.4 | 3.4 |

- The closest approach is within ±0.3 of 6.7 / 5.6 once the height difference is counted.
- The beside rule holds: wall clearances of 4.0 / 2.5.

**Check in the calibrate:**

- closest approach to C at star 5 is 6.7 / 5.6 ±0.3 (please print it);
- star rule ≥ 5.6 everywhere.

### 2. Pip lunges late, after you have gone past

**Checklist:** Reward moments; Readable.

**Evidence:**

- `farm_trace.txt` (d 0, h 12): the flyer is nearest at about 7.4 s (x 9.3, z -49, about 7.0 u from C). The lunge comes at 8.2 s (x 10.0, z -54.2, about 8.4 u).
- Today's calibrate lunges at z -54..-59 every time, 4-9 u past star 5.
- So she swipes at where you were 0.6-1.1 s ago, and the paw gap grows by 1-2 u.

**Fix (feel, kitten timing).**

- Fire the lunge when the flyer's time to closest approach is ≤ LUNGE_OUT (0.15 s), so the paws arrive as you pass. The time to closest is -dot(to, v) / |v|² in kitten space.
- Keep "or within CLOSE_IN" and every fairness constant (REACH 3.0, CATCH 1.0, WIGGLE_MIN 0.6, TRIGGER 9). Reach stays 4.0 at every difficulty.

**Target, with fix 1:** "missed by" on the skilled line is **2.6-3.9 u**, meaning the paw ends about one kitten-height from you. That is the near miss.

### 3. "Cat's whiskers!" is too hard to fill for a skilled pilot

**Checklist:** Style points feel earned.

**Evidence:**

| Pilot | Full Whiskers | Mark |
|---|---|---|
| Skilled | 5 of 15 passes (33%) | ≥ 80% |
| Shaky | 2 of 15 | ≥ 50% |

- The breaks are at **star 3 or 4**. The pilot is still inside the swing: (5.3-5.8, z -44) against star 4 at x 6.6-7.2. Calibrate d 1 at h 11 and h 18 both break there (12/13).
- High entries (h 24-27) break at stars 1-2 because they are still diving.

**Fix (layout).** Start the swing at star 1 and even it out. Stars 5-7 are unchanged.

| Star | x now | x new |
|---|---|---|
| 1 | 0.6 | **1.2** |
| 2 | 3.0 - 0.4d | **3.0** |
| 3 | 5.2 - 0.6d | **4.8 - 0.4d** |
| 4 | 7.2 - 0.6d | **6.5 - 0.4d** |

- Lateral steps become 1.8 / 1.8 / 1.7 / 2.1 instead of 2.4 / 2.2 / 2.0 / 1.4. The heading change is spread over all of stars 1-5.

**Mark (my call as designer):**

- Measure the 80% / 50% on passes entering **≤ 21** (the cap).
- From h 24+ you choose to dive through the barn's end. Partial Whiskers there is fair, not a fault.

### 4. The wiggle is too small to read

**Checklist:** Readable (the telegraph).

**Evidence:**

- Rump yaw ±8° at 6 Hz moves its back about 0.1 u.
- At 18 u, using the plan's 11.3 px per degree, that is about **3-4 px**. At 6 Hz it is closer to a shimmer than a wiggle.
- From the front (`wiggle_10u`) what reads is the crouch, not the bottom.

**Fix (feel):**

- rump yaw **±15° at 4 Hz**;
- add a rump sideways sway **x ±0.1 u** in phase;
- rump pitch **-0.25** (bottom higher);
- keep the 0.2 s ramp.

That moves the bottom about 0.28 u, roughly **10 px at 18 u**: a wiggle anyone can spot at a glance, and still cute.

### 5. The catch should be a hug, not a teleport

**Checklist:** Fair failure; Feel; Reward moments (the "aww").

**Evidence:**

- `Flyer.caught()` sets `global_position` to the hug point at once, so the balloon jumps up to 4 u in one frame.
- The camera only gets `kick_fov(-6)`, which kicks in and back out, and it keeps chasing the flyer. The plan's §1.6.3 (hold, turn to the kitten, push in) isn't there.
- In `hug_10u` the squint (eyes at 15% of their height) reads as **smug slits**, not happy arcs.

**Fix (camera, effects):**

- **Flyer:** ease the flyer's visual to `hug_point()` over **0.35 s** (ease out). Looks only: the outcome is already decided in the tick.
- **Camera:**
  - hold its position;
  - turn to look at the kitten's head over **0.4 s**;
  - FOV **-6° over 0.6 s, held** until the card (not kicked back);
  - no shake.
- **Hug face:** show `_mouth` at **scale 0.45** (a small open smile) with the squint, as in the yawn frame, which is the happiest face the kitten has.
- **Check:** please capture a screenshot 0.7 s after a catch with the plane and one with the balloon. The kitten's face must be in frame.

### 6. No part below the sill, in any pose

**Checklist:** Readable (the first sight at 80 u is usually asleep: 70% of kittens).

**Evidence:**

- `asleep_10u`: the white front paws hang under the sill board, and the tail sticks out at head height, where it reads as a raised paw. It doesn't read as a curled loaf.
- `flop_10u`: the paws show under the sill too.

**Fix (looks):**

- **Asleep:**
  - `_chest.position` (0, 0.05, 0.05), scale (1, 0.6, 1);
  - `_head.position` (0, 0.9, 0.35);
  - `_tail.rotation` about (1.55, 1.3, 0), so the tail lies along the sill round the paws.
- **Flop:** clamp so the paws' lowest point stays ≥ 0 (the sill top).
- **Rule for all poses:** nothing below y 0 except the yarn's strand.

### 7. (Polish, optional) Farmhouse window overlap

When a kitten is home, the farmhouse's closed upstairs window at x -2.6 sits behind the open pink shutter (`homes_a`, `homes_b`). Drop that window when a kitten is home, so the pink stands alone.

## Re-check after the fixes

- **Farmyard calibrate:**
  - closest to C at star 5 is 6.7 / 5.6 ±0.3;
  - a lunge on every pass at every d;
  - "missed by" 2.6-3.9 on the skilled line;
  - Whiskers 13/13 from need and h 18 at d 0 / 0.5 / 1.
- **Batches ×20:**

  | Pilot | Pass |
  |---|---|
  | Skilled | 0 caught; Whiskers full ≥ 80% (entries ≤ 21) |
  | Shaky | ≤ 2 caught; Whiskers ≥ 50% |
  | Chaser + no-circle | ≤ 3 of 40 caught, each with a closest approach < 4.0 and ≥ 0.6 s of wiggle |
  | Middle and hands-off | 0 caught |

  Zero catches anywhere today is a sign the cat has no claws yet. After fixes 1-2 I expect a rare chaser catch, and that is right.
- **Screenshots:** the catch (fix 5), and the asleep and wiggle poses at 3/4 view from 18 u.

## Not judged here (phone)

The lee rotor: no pilot crosses the high crests, and its look (falling wisps rather than the plan's rolling leaves) needs the owner's eye at 625 m+ (phone checklist item 7).

## Later ideas

- A kitten that follows you with its whole body (turns on the sill) when you circle near a home.
- Pip's mother asleep in the barn's doorway at the Farmyard, as looks only.

## Re-check (after the lead's fixes)

**APPROVE.** I read the lead's numbers and the new sheet (`kitten_sheet3`); I did not run Godot.

### Fixes 1 and 2: closeness and the lunge's timing

- **Pass distance:** now 6.6-7.6 u from her chest, down from 7.8-8.1.
- **Misses:** "missed by" is now 3.7-4.6 u, down from 5.0-6.2. Her paws now end about a kitten-height and a half from you.
- **Lunges:** she lunges on every pass at every d.
- **Catches:** 0 catches in any batch, but the chaser had a 3.7 near miss.
- This is not quite the 2.6-3.9 I asked for, but it is close enough to feel like a swipe, and it stays fair.

### Fix 3: Cat's whiskers! completion

- 13/13 from need and h 18 at every d.
- Full on every entry at h ≤ 21 in the batches.
- Breaks only on the h 26.6 dives, which is the partial-from-high I accepted.

### Fixes 4 and 6: the poses

- **Wiggle:** in `wiggle_10u` the bottom swing now reads, even from the front.
- **Sill rule:** the paws stay on the sill in the asleep, wiggle and flop poses.

### Fix 5: the hug

- `hug_10u` now has a little open mouth. It reads content rather than smug.
- The 0.35 s ease and `hold_and_look` are as specified.

### Not blocking (for the phone pass or a later tune)

1. **Shifting the barn no longer makes d 1 closer than d 0.** The pass is still about 6.6 u at d 1, against the plan's 5.6. If the owner finds Pip too easy late in a run, add about 0.5 u more barn shift at d 1 only. Keep the beside rule (≥ 2.5 at d 1) and re-check catches: shaky ≤ 2 of 20.
2. **The in-game catch screenshot is still owed.** It must show her face in frame, for the plane and for the balloon. This is phone checklist item 3.
3. **Asleep pose:** the tail's white tip still sits beside Pip's face and can read as a raised paw. Polish: lower the tail rotation x by about 0.2 so the tip rests on the sill.
