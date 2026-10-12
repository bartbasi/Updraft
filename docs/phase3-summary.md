# Phase 3: what changed

You asked for: lift outside that's easy to find, a bigger plane, and a red balloon to try (with the same physics). Each step was planned by the designer (`docs/outside-plan.md`), checked by the code-reviewer and given a fun review (`docs/fun-review-3.md`). Deviations are listed in `docs/build-notes.md` under "Phase 3".

## The balloon and the bigger plane

- The plane is drawn 1.3x bigger (`look_scale` in `scripts/tuning.gd`). It collides exactly as before.
- **Fly the balloon / Fly the paper plane** on the end card switches between the two. Your choice is saved on the phone.
- The balloon flies exactly like the plane (a test checks this). It leans gently into turns, its string trails behind and floats up in rising air, and a crash pops it.
- Outdoors the camera sits a little higher behind the balloon, so it doesn't hide what's ahead.

## The outside

- **A wide valley to explore.** The old hills were built to end the flight within seconds. The new valley floor rises gently, there's a ridge and plateau on the left, and every edge is high ground.
- **Lift you can't miss.** Straight out of the window, warm air rises over a hay field (radius 12, up to y 24; the old one was radius 6 and off to one side).
- **A chain of thermals,** each visible from the top of the one before: a barn's dark roof, a ploughed field, and a bonfire's smoke.
- **Ridge lift.** A breeze blows up the left hillside, so the air rises all along it. Seeds stream up the slope, birds hover over it, and a big red kite flies above it.
- **Signs of lift.** A puffy cloud over every thermal, with birds circling under it. A windsock shows the breeze.
- **"You're in lift" beeps.** Soft beeps while you climb in rising air, coming faster and higher the faster you climb. They work in the house too.
- **"Keep circling to climb"** shows once, the first time you fly into warm air low down outdoors.
- **Landing spots.** Lavender +200, the picnic blanket on the plateau +400. A crash pays no bonus.
- **Airtime.** 5 points a second outdoors, up to a minute.
- **Ridge run.** A ninth style moment.

## How it plays (test pilots)

| Pilot | Time outside | Landing |
|---|---|---|
| Hands off | 35 s | Was 18 s before this phase |
| Through the hay field and down to the lavender | 28 s | Lavender |
| Ridge | 46 s | Lavender |
| The whole chain | 74 s | Lavender |
| Over the ridge to the picnic | 36 s | Picnic, +400 |

The designer's own pilots, who don't know where the lift is, stayed up 97 s on average just by circling in the beeps and steering for the next cloud.

## Safety and tests

- Still no permissions, no internet, and no third-party code.
- The new settings file is validated when it loads.
- To keep the phone at 60 fps, air you can't see isn't drawn.
- 124 tests, all passing.

**What to check on the phone:** the "Phase 3: check on the phone" list in `docs/build-notes.md`.
