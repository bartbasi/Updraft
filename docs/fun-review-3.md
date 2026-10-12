# Fun review 3: the new outside (Phase 3, steps 1-8)

**APPROVE**, with the fixes below. Do items 1-3 before the owner's phone test. The rest can come with it or after.

## Does it fix the owner's complaint ("too hard to find lift")?

Mostly yes. The one weak link left is staying in a thermal while circling, not finding it.

### What I measured

I wrote my own pilots (`<scratchpad>/seek.gd`). They fly the house like the skilled pilot. At the window they hand over to a "human" who does **not** know where the thermals are:

| Pilot outside (12 runs each) | Time outside (mean) | What happened |
|---|---|---|
| Hands off (straight) | 35 s | +10 through the hay field, then a lucky pass through the ploughed field. It was 18 s before Phase 3. |
| Weaves at random, ignores lift | 15 s | Finds L1 in 5 of 12 runs. |
| Circles on beeps; **gives up 2 s after they stop** | 17 s | Only 3-4 s in lift; leaves L1 at y ≈ 16. |
| Circles on beeps; **keeps turning 5 s after they stop** | 57 s | Reaches L1's top (23.6) in 10 of 12 runs, in about 16 s (2 laps). |
| Circles on beeps, then steers at the nearest cloud ahead | **97 s** | 9 of 12 runs chain 3-5 thermals. The 3 failures left L1 early (y ≈ 12) and reached the barn at y 2-3. |

### Conclusions

- **Finding lift is solved.**
  - L1 can't be missed. The view out of the window (`window.png`) is a golden field, an orange column, birds and a cloud dead ahead.
  - Every cloud I checked sits over its column (`hay_top_to_barn.png`, `fire_top_home.png`).
  - A player who flies at clouds stays up for 1.5-2.5 minutes.
- **Staying in lift is the gap.** Here is one traced lap at input 0.67:
  - bank 23°, 44°/s at 7.3 u/s, so the turn radius is 9.6 and a lap takes about 8 s;
  - the turn starts 4.8 from the centre, but the circle swings out to r 17;
  - beeps run for 3.0 s, then there is **silence for about 4-5 s** (trace t 6.6-11).
  - A first-timer hears the silence as "the lift is gone" and leaves.
  - Circling longer is worth +40 s outside. A larger L1 helps much less: radius 16 added only about 2-3 u of height for the pilots who gave up early.

### Skilled routes

These match the plan:

| Route | Time outside | Notes |
|---|---|---|
| Chain | 81 s | |
| Ridge | 46 s | Ridge run style 0.92 |
| Picnic | 35.5 s | +400 |

The novices are unchanged indoors: 10 of 10 reach the outside with no crashes.

## Fixes, most important first

### 1. Readable: the ridge can't be seen from where you'd choose it

- **Evidence.** In `hay_top_to_ridge.png` the left hillside looks like any other slope:
  - The kite isn't visible: 2.5 u at 119 u is about 1.2°, or about 14 px, behind fog.
  - The 1.6 u ridge birds and the 0.3 u seeds can't be seen beyond about 30 u.
  - My pilots found the ridge only by accident (4 of 48 runs). It is meant to be the "explore" branch.
- **Fix (layout and looks):**
  - **Kite:** size 2.5 → **6 u**, colour `f19e8f` → **`e8604c`**, ribbon tail **10 u**. Move it to **(-62, 36, -190)**, over the band and 92 u from L1's top instead of 119. Keep the string down to the blanket.
  - **Ridge birds:** 3 → **6**, wingspan 1.6 → **2.4** (ridge birds only), spread along z -150..-240 at crest + 3.
  - **Seeds:** quad 0.3 → **0.5**.
  - **Pale wind-bent grass:** widen the strip to x **-28..-52** and make its tufts **1.5×** taller, so the band reads as a stripe from 60 u.
- **Check:** retake `hay_top_to_ridge`. The kite should be at least 30 px, and the hovering birds visible.

### 2. Feel and sound: teach "keep turning"

- **Evidence:** see the table above. Pilots who give up 2 s after the beeps stop average 17 s outside; pilots who keep turning average 57 s. Each lap has 4-5 s of silence.
- **Fix:**
  - **(a) Hint.** On the first outdoor thermal entry of a run, show the existing hint label with **"Keep circling to climb"** for **2.5 s**. Fade it the same way as "tilt to fly". Show it only while the plane is below 18 there, so a player already circling to the top never sees it.
  - **(b) Re-entry cue.** Re-entering the same thermal already replays the chime (the log shows HayHeat at t 3, 11 and 19). Keep that. It is the "you're back in" beat each lap. Lower `chime_volume_db` for a **repeat entry within 12 s** by **-4 dB**, so the lap rhythm (chime, beeps, quiet) sounds deliberate rather than nagging.
  - **Owner note.** If the lead counts (a) as a new system, it goes to the owner. I count it as reusing the existing hint.

### 3. Readable: the bonfire smoke doesn't work as a beacon

- **Evidence.** In `field_top_to_fire.png`, from L3's top at 69 u, the plume is a faint grey smear behind the plane. The plan called it "the best beacon outdoors". Only the cloud gives L4 away.
- **Fix (looks only, keep 40 puffs for the frame budget):**
  - puff size **×1.6**;
  - opacity beyond 20 u **0.8**, near-camera fade unchanged;
  - tint `e2ddd8` → **`d6d0cb`**, a touch darker so it separates from the cream clouds;
  - puff lifetime 8 → **9 s**, so the plume reaches the cloud base.

### 4. No dead air: the L3 → L4 glide has no mid-point beat

- **Evidence.**
  - Edge to edge is 69 - 20 = 49 u, which is 8.1 s at a neutral 6.05 u/s.
  - The chain log shows 16.8 s from FieldHeat to BonfireSmoke, because the autopilot flies slowly, nose up.
  - Every other hop has a beat: the stream on L1 → L2, the lavender on L2 → L3.
- **Fix (layout):** move L4 and the bonfire **10 u closer**, to centre **(30, -258)** and bonfire **(32, -258)**.
  - The hop becomes 59 - 20 = 39 u, or **6.4 s**.
  - The home glide shrinks from 95 to 85 u (14 s).
  - Ground there is d = 169, below 190, so the head wall is not involved. The nearest allowed trees are at x 45, beyond the edge (40) plus 4.
  - Re-run the chain test.

### 5. Feel: the balloon hides what it flies toward

- **Evidence.** In `capb/02_t057.0.png` the balloon sits exactly on the ploughed field's column, the next target. It is about 2× the plane's frontal area at the same camera position.
- **Fix (camera, balloon look only):** `camera_height` 1.0 → **1.6** and `camera_look_above` 0.3 → **0.7** while the balloon is flown. The balloon then sits below the horizon line and the targets stay clear above it.

### 6. Feel, phone risk: outdoor frame rate

- **Evidence.** The fixed-spot captures run at 39-43 fps on the PC's GTX 1650 at L1's top, the barn's top and the ridge run. The flight captures run at 60.
- **Fix:** add these to the phone-test list.
  - First cut: outdoor motes clamp(r² × 0.8, 80, 120) → **(50, 80)**.
  - Second cut: the ridge seeds 160 → **100**.
  - Do not cut the clouds or the smoke: they are the cues.

### 7. Optional layout: a slightly larger L1

- L1 radius 12 → **14**, with the hay paint 24 → **28** square. The bales stay at |x| ≥ 8.
- **Evidence:** in my sims at radius 16, pilots who give up early topped out about 2-3 u higher, and those who keep circling were unchanged.
- Small gain. Do it only if item 2 isn't enough on the phone.

### 8. Tooling (the lead's call, not fun)

- **Flight log.** Log `vario on` and `vario off` as events. The "nothing happening" gaps in the chain log (11.6-18.6 s) include the climbs. The real glide gaps are 8.6, 11 and 15 s at autopilot speed, and about 6-8 s at neutral speed.
- **Birds warning.** `scripts/birds.gd:68` prints a physics-interpolation MultiMesh warning every frame in windowed runs (`_place` is called from `_process`). For the code reviewer: possible jitter, and log spam on the phone.

## Checklist, briefly

| Point | Verdict |
|---|---|
| No dead air | OK at neutral speed (hops of 5.8 / 7.4 / 8.1 s); item 4 fixes the longest. The 13.9 s novice "dead air" is the scripted spiral down onto the lavender; a person glides straight in. |
| Readable | L1, L2 and L3 are good. The ridge (item 1) and the smoke (item 3) are weak. |
| Fair failure | No outdoor crash in any route or novice log. My "humans" crashed only by rolling out of a circle toward the house (z -77 to -89): the house is in full view, so this is fair. |
| Forgiving start / Fast retry | Unchanged. |
| Style earned | The ridge run is earned only by the ridge route (0.92). Novices get airtime and the lavender. |
| Scoring | Lavender-direct 1986, chain 2344, picnic 2400. Exploring pays, and the picnic stays the expert prize. Keep. |
| Window reveal | Strong (`window.png`): golden field, column, birds, barn, valley and clouds in one frame. |

## Balloon

The outside suits the red balloon very well:

- A balloon riding warm air under cumulus is the natural story.
- Red against green and cream reads at every distance in the captures.
- Landing it on the picnic blanket is a lovely goal.

The only change is item 5, so it doesn't hide its own target. No physics changes.

## Later ideas (new systems, not for this phase)

- A soft "lift lost" sigh, or a low tick in sinking air, so the vario tells "edge of the column" apart from "top of the thermal".
- A thermal that drifts slowly with the breeze (-X), with its cloud, to reward re-centring.
- Clouds that thin out once their thermal has been climbed in this run, to nudge the player on to the next one.
- A gull that joins you along the ridge (carried over from the plan).
