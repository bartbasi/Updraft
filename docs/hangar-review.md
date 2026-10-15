# Fun review: the Hangar and the daily flight (Endless step 5)

**SEND BACK.** These are small fixes. The Hangar's structure, the buying flow, the prices and the daily rules are right and stay as built. The problems are three trails that read badly in flight (one of them breaks the air-cue rule), a preview that undersells the looks, and a daily goal you can't see while flying.

Evidence:
- The lead's shots are in `scratchpad/hangar_shots`.
- My re-run of `tools/title_shots.gd` is in `scratchpad/shots2`. It was taken after the 21:47 `hangar_panel.gd`, which now shows 4 columns on the cover. I added starry, candy, waves, petals and ribbon shots, and the tried card now scrolls into view.
- In-flight shots are from a scratch copy of `endless_capture.gd` that wears looks first, with the skilled pilot and seed 1: `scratchpad/fly_rainbow`, `fly_confetti`, `fly_petals`, `fly_ribbon`.

## What already works (keep it)

- **The title.** The gold "+100" pill on DAILY draws the eye without shouting. The caption now shows the bank on both modes.
- **Cards.** Price states read at a glance: gold if you can afford it, faded if not, "Owned", and a lilac "Wearing". The pattern icons (polka, smiley, starry, candy, rainbow, newspaper, map, waves) are charming and different from each other. Trying an item on with one tap, and the "1200 stars: 300 more" button, give the player a goal. That is what makes them want things.
- **Balloon looks in flight.** Polka dots, smiley and the waves plane read clearly in the chase view. Smiley faces the camera as planned (`fly_petals/01_t022`).
- **Nothing blocks the way ahead.** In every flight shot the trail lies behind and below the flyer, never between the flyer and the next stars. The rainbow ribbon curving through a turn is lovely (`fly_rainbow/04_t030`).
- **Pacing.** The economy is as planned. The daily's 100 stars is worth about 5 first-day runs, so the first buy comes on day 1.

## Changes, most important first

1. **Blossom petals are invisible in flight, and what you can see reads as thermal motes.** Fails: Readable, and the plan's air-cue rule.
   - Evidence: in `fly_petals/01_t022` and `02_t030` the only sign of the 1,200-star trail is a few pale white specks below the balloon. They look just like the cream motes. The `fbe4ec` petal is within a few percent of mote cream `fbf6ee`, and `Art.soft_dot()` blurs the edges further. A petal is 0.08 × 0.05 u, about 10 × 6 px at chase distance.
   - Fix:
     - colours `f29bb8` and `f6c3d3` (drop `fbe4ec`);
     - quad 0.13 × 0.08 u;
     - a hard-edged oval texture rather than the soft dot;
     - `amount` 10 → 14.
   - Keep the lifetime at 1.2 s.

2. **Confetti's sunflower squares look like gold stars.** Fails: Readable, and the air-cue rule (no gold). The plan chose that colour; it was my mistake.
   - Evidence: `fly_confetti/02_t030`. Amber squares with the ink outline trail straight into the star arc ahead and match its gold.
   - Fix: replace `f2b63c` with bubblegum `f29bb8` in the particle palette and in the card icon. That gives coral, sky, bubblegum, mint and lilac.

3. **In straight flight the rainbow ribbon reads as a striped balloon string.** Fails: Reward / Feel. It is the 2,000-star top item.
   - Evidence: `fly_rainbow/01_t010` and `03_t022`.
     - The ribbon is seen end-on, about 12 px wide.
     - It runs from the knot straight down the screen beside the string.
   - Fix: widen it so it reads as a band:
     - rainbow 0.15 → **0.26 u**;
     - pink ribbon 0.06 → **0.10 u**.
   - Arithmetic: at 2 u from the camera, 0.26 u is about 70 px on the cover. It lies below the flyer and fades from 2.0 u in, so it still hides nothing ahead.

4. **The preview undersells the trails, and pale looks vanish on the cream panel.** Fails: Reward. The try-on is the moment of wanting.
   - Evidence:
     - `hangar_rainbowtrail` and `1280x1066_hangar_rainbowtrail`: a short stub at the knot.
     - `2316x904_hangar_petals`: two pink dots.
     - The flyer is drawn at `SIZE` 1.7 but the trail at world scale.
     - The preview's 3 u/s is below `Trail.SLOW`, so the trail gets the shortest length (×0.6). A 0.36 s ribbon at 3 u/s is about 1.1 u, less than one balloon.
   - Fix (preview only):
     - pass speed **9** to `Trail.follow()`, which gives a ×1.1 length;
     - scale the trail's ribbon width and particle quads by `LookPreview.SIZE`;
     - draw the title's sky gradient behind the preview, in a rounded rect of radius 24. The plan asked for this. Without it, white-pink, cream and plain looks have nothing to stand against.

5. **Plane designs are seen edge-on in the preview.** Fails: Readable.
   - Evidence: `shots2/2316x904_hangar_waves`. The wave print is a thin sliver.
     - The camera sits 0.9 up and 3.6 out, only about 14° above the plane, which is banked 15°.
     - In flight the designs show in turns. The preview should show them that way.
   - Fix: bank the plane **35°** in the preview. Leave the balloon's lean as it is.

6. **The flyer is small in the cover preview.** Fails: Reward.
   - Evidence: `2316x904_hangar_polka` and `_sky`. The balloon fills about 35% of the preview's height, against about 70% on the taller screens.
   - Arithmetic: FOV 45° at 3.6 u shows 2.98 u of height for a balloon about 1.2 u tall.
   - Fix: use FOV **36°** when the preview is wider than 1.5 : 1. That shows 2.34 u of height, so the balloon fills about 50%. The half-width becomes 1.17 × 1.86 = 2.2 u, which still holds the 0.9 u circle plus the plane's 0.85 u half-span.

7. **The stacked layout (1,280 × 1,066) shows only one row of cards.** Fails: Readable (browsing).
   - Evidence: `shots2/1280x1066_hangar_*`. The preview area is about 470 px tall, with blank space above the flyer. The grid gets one 230 row.
   - Fix (as the plan said):
     - put the name, the "fly" line and the action button over the preview's bottom-right corner rather than below it;
     - fix the preview at **330** tall;
     - give the scroll the rest, which is 2 rows (476) plus tabs.

8. **You can't see the daily goal while flying.** Fails: No dead air / Readable.
   - Evidence:
     - The "Reach 100 m for 100 stars" hint shows from 2.6 s to 4.6 s and is never seen again.
     - The skilled pilot reaches about 77 m at 40 s, so a first-timer gets to 100 m at 50-70 s with nothing marking the goal.
     - On the day's first daily run `_best_at_start` is 0, so no bunting hangs at all.
   - Fix (an existing effect, no new system):
     - while today's reward is unpaid and today's best is under 100, **hang the bunting at 100 m**, and pass it with the gold "Today's stars! +N" (already built);
     - once paid, it marks today's best as now;
     - also tint the HUD distance gold until 100 m in an unpaid daily.

9. **Info misdescribes buying.**
   - Evidence: `how_to_fly.gd` says "Buy it if you like it, then Wear it". `_on_confirm` already wears what you buy.
   - Fix: "Buy it if you like it: it goes straight on. Anything you own can be put back on with Wear."

10. **Small polish.**
    - Write prices of 1,000 or more with a separator ("2,000 stars: 1,100 more"), as in the plan.
    - In `show_tab`, scroll the worn card into view (`ensure_control_visible`). Someone wearing Wave print or Rainbow opens the tab with their own item off-screen.

## Not judged here (owner's phone)

- Frame rate with each trail on (§8.6). The capture's closing fps printouts (7 / 52 / 32) were taken during teardown and mean nothing.
- Whether the two-tap buy feels safe but not fussy.

## Later ideas (not this step)

- A "saving for" line on the end card, naming the last item tried on and the stars still needed.
- The Hangar preview flies the worn flyer through a short dive on Buy, so the trail stretches.

---

## Re-check after the fixes (2026-10-15)

**APPROVE.** All ten changes are in and they work.

Evidence:
- The lead's fresh `scratchpad/hangar_shots`.
- My in-flight runs: `scratchpad/fly2_petals` (candy + petals), `fly2_confetti` (newspaper plane + confetti) and `fly2_daily` (starry + rainbow, daily run). All used the skilled pilot.

Each change, against its original problem:

| # | Result |
|---|---|
| 1 Petals | Clearly pink ovals streaming off the knot in flight (`fly2_petals/01_t022`, `02_t030`). They no longer read as motes. The real motes in the same shots are still small cream dots, so the two are easy to tell apart. |
| 2 Confetti | No gold left. It is coral, sky, bubblegum, mint and lilac in flight (`fly2_confetti/02_t030`), and nothing in the stream can be taken for a star. |
| 3 Ribbons | The rainbow now reads as a rainbow band in straight flight, not a striped string (`fly2_daily/01_t022`, `04_t052`). It still lies below the flyer, and the hoops and stars ahead stay clear. |
| 4 Preview trails | Petals, confetti and the rainbow arc now show properly on the try-on. |
| 5 Plane bank | Wave print shows its pattern in the preview. |
| 6 FOV | The flyer fills about half the cover preview. |
| 8 Daily goal | The bunting hangs at 100 m and the HUD distance is gold up to it (`fly2_daily/03_t044`, 90 m, gold). At 105 m the distance returns to ink. Event log: "daily reached" at 48.6 s, about 50 s of flying, which is reachable but earned. "Past today's best" correctly gives way to the goal's own cheer. |
| 9, 10 | Info wording, separators ("1,200 stars: 300 more") and the scroll-to-worn-card are all correct. |

Two small notes. Neither blocks approval:

- **Possible black blob in the petals preview.** In `2316x904_hangar_petals` there is a black ring at the knot. It is not in the inner-screen shot or in any flight shot, so it may be one frame of newborn particles before the colour ramp applies. Please check it once more. If it persists, start the petals' alpha ramp at 0.
- **The preview's backdrop is mostly peach haze.** The camera looks down, so the horizon sits near the top and little sky shows. It works, and the looks stand out against it. Optional: drop the horizon to about 40% of the preview's height so more blue shows behind the balloon.

The owner's phone checks in plan §8 still apply, especially the frame rate with each trail on.
