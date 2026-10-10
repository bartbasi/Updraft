# Paper Plane: Phase 2 brief (from the owner, verbatim)

## Where we are

The 30-second demo works. It launches in a room of the house, catches a radiator thermal, dives under an obstacle, climbs on kettle steam, and flies out an open window over pastel hills. Read the existing code, tests, and git history before changing anything. Keep what works. Do not rewrite systems that aren't part of this job.

## The goal

Add a new opening before the existing demo, then make the whole flight genuinely fun. There is no point to this game if it isn't fun. Correctness and security come first, then fun.

## New opening sequence

- **Bedroom.** The run now starts in a bedroom with the plane already in the air. The player is the kid who just threw it: the first frame is from the kid's eye level with the plane gliding away just ahead. We never see the kid or the throw. Within the first second, the camera eases smoothly from that view into the normal follow camera. The bedroom should feel cozy and lived-in but stay in the soft watercolor pastel style.
- **The turn.** The bedroom door opens onto a hallway at a right angle. The player has to bank to make the turn out the door. The doorway should be wide enough that a first-time player makes it most of the time. Brushing the door frame is a glancing bump, not a crash.
- **Hallway sunbeam.** Just past the turn, sunlight from a window or skylight falls across the hallway floor, warming the air into a clear, visible updraft. Catching it lifts the plane back up after the turn. Show it with a soft light shaft and dust motes drifting upward, plus the same chime as other thermals. Do not use floor vents or registers anywhere.
- **Down the hallway.** A straight run long enough for the player to settle in and feel the plane glide.
- **Down the staircase.** The hallway ends at a staircase going down, with a landing and a turn partway down. The player dives into the stairwell, picks up speed, banks around the landing, and has to level out at the bottom. Cool air sinking down the stairwell creates a visible downdraft (soft, pale blue wisps drifting down) that helps the dive if the player uses it.
- **Into the existing demo.** The bottom of the stairs opens into the first room of the current demo, and the existing sequence continues unchanged through to the open window and the outdoor hills.

Remove the old launch point, since the run now starts in the bedroom. A player who flies it well should get at least 60 seconds of play. Reach that through good pacing and space to fly, not padding. Longer runs (up to about 120 seconds) will come from more rooms in a later phase. The house must stay original. Do not copy the look, room layouts, or names of any existing game, including the 1988 Mac game Glider.

## Downdrafts

This phase adds downdrafts: zones of sinking air that push the plane down while it's inside them. They work like thermals in reverse, with their own clear visual cue (pale, cool-colored wisps falling) and a distinct sound. Used well, a downdraft adds speed for a dive. The stairwell has one. Add others only if the designer can show they make the flight more fun.

## Scoring

- **Distance score.** Points for distance flown, shown small and unobtrusive on screen during the run.
- **Style points.** At each key moment on the course (the bedroom turn, the sunbeam, the stairwell downdraft, the landing turn, the radiator, the obstacle, the kettle steam, the window), the designer defines an optimal flight path through it and a corridor around that path. Style points are graded: flying right on the optimal path earns full points, and the award drops smoothly to zero at the edge of the corridor. Outside the corridor earns nothing. Show the result with a quick, cheerful pop-up and a sound, and make a near-perfect pass look and sound a little better than an average one.
- **End card.** Shows distance, style points, total, and best score. Best score is saved on the device.
- Put point values, corridor widths, and the shape of the grading curve in the tuning file.
- Make the optimal paths visible as a debug overlay for testing only.

## Team setup

Use a multi-agent setup with these subagents, defined as files in `.claude/agents/`. The main session is the lead builder: it writes the code and coordinates the agents.

- **designer** owns fun. Plans each section of the course before it's built: what the player sees, what they're asked to do, how long it takes, and why it feels good. Reviews every built section for fun using the fun checklist. Has authority to send work back. Does not write game code.
- **code-reviewer** owns correctness and security. Reviews every change before it's committed: bugs, edge cases, physics stability, performance, code clarity, and the security checklist. Runs the tests. Has authority to block a commit. Does not write game code. Reviews with fresh eyes: give it the diff and the goal, not the lead's reasoning.

Disagreements between the two get written down and brought to the owner. Don't settle them silently.

## Work order

**Phase A: build it right**

1. Designer writes a short plan for the new opening: layout of each space, where the sunbeam and downdraft sit, door and stairwell sizes, the style-point moments and their optimal paths, and target timing for each part. Save it in the repo. Do not wait for approval; run straight through the whole job.
2. Build the opening one section at a time (bedroom and opening camera, turn, sunbeam, hallway, stairs with landing, connection to the existing demo). Then add downdrafts and scoring.
3. After each section: code-reviewer reviews and tests pass, then commit.
4. Phase A is done when the full course flies start to finish with scoring working, all tests pass, code-reviewer has no open issues, and a debug APK builds.

**Phase B: make it fun**

5. Designer reviews the whole flight against the fun checklist and writes a ranked list of problems and fixes.
6. Fix them in that order. Each fix still goes through code-reviewer.
7. Repeat once. Then stop and hand it to the owner to play on a phone.

## Security checklist (code-reviewer)

- The game needs no internet. The Android build must not request the INTERNET permission or any permission besides what tilt controls need.
- No analytics, ads, tracking, or third-party SDKs.
- No secrets in the repo. Signing keystores and passwords stay out of git and are listed in .gitignore.
- Any saved data (settings, best distance) is validated when loaded, and a corrupt or missing file falls back to defaults instead of crashing.
- No debug tools, cheat keys, or test shortcuts reachable in a release build.

## Bug checklist (code-reviewer)

- Automated headless tests cover the new geometry: a scripted plane path that makes the turn clears the doorway; the sunbeam lifts the plane; the downdraft pushes it down; flying down the stairs and around the landing at speed does not clip through steps, railings, or walls.
- Scoring tests: a scripted flight along each optimal path earns full style points; a flight halfway to the corridor edge earns less; a flight outside the corridor earns none; points can't be earned twice for the same moment in one run; distance never goes backward.
- Fast collisions never tunnel through walls, railings, or stairs.
- Physics stays stable at low frame rates and does not depend on frame rate.
- Restarting a run fully resets the plane, camera, audio, and thermals. Test 20 restarts in a row.
- Tilt calibration still works after the new launch point.
- Performance holds at 60 fps on a mid-range Android phone. Flag anything that adds heavy draw calls or overdraw (steam and shimmer effects are the usual culprits).

Bug free is the target, but nobody can prove that. The bar is: every known bug fixed, tests for each fixed bug so it can't come back, and nothing open from code-reviewer.

## Fun checklist (designer)

Agents can't feel a phone tilt, so judge fun with things you can check, and use a scripted test pilot that flies the course and logs what happens.

- No dead air. Something to react to, see, or decide at least every 4 to 5 seconds.
- Readable. The player can see the next thermal, doorway, or obstacle before they need to act on it.
- Fair failure. Every crash has a cause the player can see and understand. No surprise walls, no unavoidable hits.
- Forgiving start. A first-time player gets through the bedroom turn most of the time.
- Style points feel earned. Hitting the optimal path should be clearly harder than just surviving, but reachable. A new player should earn a few style points on their first runs, and a skilled player should be chasing them all.
- Feel. Diving builds noticeable speed. Thermals feel like a lift, not a teleport. The stairs dive should be the most thrilling moment before the window.
- Reward moments. Close calls, a fast stair dive, and bursting out the window should feel good through camera, sound, and visuals. Small touches like a camera lean, a swell in the wind sound, or a soft whoosh count.
- Fast retry. From crash to flying again in under 2 seconds.
- The window reveal. Flying outside should feel like a payoff.

Fun changes are limited to tuning, layout, feel, camera, effects, sound, and scoring values. No new game systems beyond scoring and downdrafts (no collectibles, menus, or power-ups). Write those ideas down for the owner instead.

## Rules carried over

- Godot 4.x, GDScript, Android first, landscape, tilt controls with keyboard fallback for desktop testing.
- No paid or third-party assets. Every model, texture, and sound is made in code or as files in this repo.
- All tuning values stay in one clearly labeled place.
- Fun comes first. Where physics and fun disagree, fun wins.
- Commit at each working milestone with clear messages.
- If anything is unclear or two parts of this conflict, ask the owner before deciding.

## Hand-back

- A debug APK and how to install it.
- A one-page summary of what changed.
- A short list of exactly what to test by hand on the phone, especially the opening camera, the bedroom turn, the sunbeam, the stair dive and landing turn, and whether style points feel fair.
- Any open disagreements between designer and code-reviewer.
