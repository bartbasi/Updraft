# Phase 4: what changed

You asked for polish for sharing, deeper flying and more world, all of it. The designer planned the flying and the world (`docs/phase4-plan.md`). The code-reviewer checked every step, and the designer gave it a fun review (`docs/fun-review-4.md`, approved). Deviations from the plan are in `docs/build-notes.md` under "Phase 4".

## Ready to share

- **Updraft**, with its own icon, a settings screen (tilt sensitivity, sound, swap climb and dive) and the package `io.github.bartbasi.updraft`.
- **Signed release builds.** `bash tools/build_release.sh` makes `build/updraft.aab` for Google Play and `build/updraft.apk` to send to friends.
- **`docs/release.md`** covers:
  - backing up the signing key (do this);
  - sharing the APK;
  - every Google Play step;
  - the store text;
  - privacy and data-safety answers.
- **Store images** are in `docs/store/`.

## Deeper flying

- **"Lift lost."** A soft sigh when you fly out of the side of rising air outdoors, so you know to turn back. Topping out is silent.
- **Thermals drift with the breeze.** Once you reach one, it slides slowly downwind (up to half its width), taking its cloud and birds with it. Keep re-centring on the beeps; circling the old spot is slower and you'll hear the sigh.
- **Clouds thin once climbed.** At the top of a thermal its cloud shrinks and frays, while the next one sits fat on the horizon. The lift itself is unchanged.
- **A gull.** On each ridge, once a run, a gull joins you off your wing for a few seconds and calls once.

## More world: the Gap and the lake

- **The Gap.** The valley's far hills now have one wide notch, with a windmill on its shoulder.
  - **To get there:** a new **chalk pit** thermal at the valley's end is the last step up.
  - **Crossing it:** a gust and a whoosh, the view widens for a moment, and the bowl opens up below.
- **The bowl beyond:**
  - a lake with an island and a sailboat;
  - a beach with huts and its own warm air;
  - a windy west bluff (ridge lift, a flag, hovering birds);
  - a boathouse and jetty, an orchard, pines and a wildflower meadow;
  - a stone wall with sheep across the valley's far end on the way.
- **Weak sinking air over the lake,** with low ticks. Crossing the water costs some height, but it never traps you.
- **Scoring:**
  - a tenth style moment, **Through the Gap** (+150, for diving low over the saddle);
  - **Island landing** +500, **Beach landing** +250;
  - coming down in the water is a **Splashdown!** (no bonus, but not a crash);
  - airtime now counts up to 90 s.
- **The house, the opening, the valley's thermals, the ridge, the picnic and the lavender are unchanged.** The novice run is unchanged too.

## How it plays (test pilots)

| Route | Run | Ends | Total |
|---|---|---|---|
| Novice ×10 | 72-76 s | 10/10 outside, no crashes | about 1980 |
| Lavender / picnic / ridge / chain | 71 / 76 / 87 / 119 s | as before | 1981 / 2400 / 2234 / 2402 |
| Ridge → chalk → Gap → island | 99 s | Island landing | 3278 |
| Barn, field, chalk, beach thermal → island | 135 s | Island landing | 3366 |
| Ridge → Gap → bluff → across the lake | 133 s | Beach landing | 3298 |

The designer's shaky-handed pilots flew the new routes 30 times: all 30 landed where they aimed, with no crashes.

## Safety and tests

- **Same as before:** no permissions, no internet, no third-party code. The signing key stays outside the repo.
- **Tests:** 150 automated tests, up from 126.

## For you, on the phone

1. **Frame rate in the bowl:** at the saddle facing the lake, along the bluff, circling the beach thermal, and over the island. If a friend's slower phone struggles, the designer suggests a **"Lighter effects"** setting (fewer motes and seeds). Say yes and I'll add it.
2. **Drift:** does following a drifting thermal feel like a nudge or a chase on a real tilt? (`thermal_drift_speed` in `scripts/tuning.gd`, now 0.5.)
3. **The window view:** from the kitchen window, the hay field's warm column and the clouds hide the Gap and the windmill. They come into view about 12 s later, over the hay field. The designer accepted this.
4. **Best scores** will jump with the new landings. Your saved best is kept as it is.
5. **Publishing:** when you have a Google Play account, follow `docs/release.md`.
