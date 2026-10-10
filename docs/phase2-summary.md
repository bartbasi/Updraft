# Phase 2: what changed

The 30-second demo now has a new opening and lasts about a minute for a well-flown run, with
downdrafts and scoring, tuned over two rounds of the designer's fun reviews. Every change was
reviewed by the code-reviewer before it was committed. Details and every decision are in
`docs/build-notes.md`; the plans and reviews are in `docs/opening-plan.md`,
`docs/review-phase-a.md`, `docs/fun-review-1.md` and `docs/fun-review-2.md`.

## The flight now

1. **Bedroom.** The run starts in the air, seen from the kid's eye, and eases into the chase
   camera within the first second. A 90-degree turn out of the door (rounded door posts, so a
   clip is a bump, not a crash).
2. **Landing and gallery.** A sunbeam thermal slants in through a high window (the lift follows
   the visible light), then a long gallery with a skylight top-up.
3. **Stair hall.** Dive down the first flight, helped by cold air sinking from the north window
   (a downdraft), turn on the landing, and through a wide arch into the living room. A sloped
   header over the arch glances pilots who never dive down into it instead of crashing them.
4. **The original demo.** Radiator, the low lamp (more room under it now), kettle steam (reaches
   lower now), and out of the window.
5. **Outside.** A gust, a soft whoosh and a wider view; a meadow thermal over a hay field, a
   stream, and a lavender field where a good glide comes down.

Test pilots: a skilled run lasts 60.4 s and flies 90.8 m; ten first-timers 60.2-61.9 s, none
crash. With no input at all, the plane crashes after 6.7 s.

## Scoring

- **Distance** in metres, small in the top-right corner (furthest progress along the course).
- **Style** at 8 moments: bedroom turn, sunbeam, stairwell downdraft, landing turn, radiator,
  lamp, kettle, window. Each is graded by how close you stay to its optimal path: full points
  near it, falling off smoothly to nothing at the corridor's edge. A pop-up and a sound for every
  award; a gold "Perfect!" and a brighter sound for a really close pass.
- **End card:** distance (metres and points), style (and how many of the 8 moments), total, best.
  The best score is saved on the phone, checked when loaded, and a damaged file is ignored.
- **Debug overlay** of the paths and corridors: debug builds only (F3, or tap the fps counter).
- All points, corridor sizes and grading curves are in `scripts/tuning.gd`.

## Feel and look

- Coral felt-pen marks on the wing tips, so the plane stands out against the pale rooms.
- The wind swells with speed: the stair dive is about 10 dB louder than cruising.
- Close calls (rushing past something without touching it) give a whoosh and a swell of wind.
- Inside warm air the camera rises with the plane and nearby motes fade, so the plane stays
  visible.
- Every feel value (flight, air, camera, sound, pop-ups, scoring) is in `scripts/tuning.gd`, with
  quick recipes at the top.

## Changes to the original demo (your call)

The brief says the old sequence "continues unchanged", and also asks Phase B to make the whole
flight fun. I read "unchanged" as covering how the opening joins the old demo, so Phase B made
small changes there too. Each has an undo note in `docs/build-notes.md` ("Decisions for the
owner"):

- more room under the dining lamp
- lower kettle steam
- the window gust, whoosh and wider view
- the meadow thermal, stream, lavender and a wider tree-free valley outdoors
- close calls everywhere

## Safety and security

- The Android build requests no permissions at all and needs no internet.
- No analytics, ads or third-party code.
- No keystores or passwords in the repo.
- Saved data is validated when it is loaded.
- No debug tools in a release build.

## Numbers

- 19 reviewed changes since the Phase 1 demo: the groundwork, 9 build sections and 9 Phase B
  fixes (5 from fun review 1, 4 from fun review 2), each its own commit.
- 101 automated tests (flight, controls, collisions, the course section by section, scoring, the
  best-score file, sounds and camera), all passing.
- The code-reviewer blocked 6 times; each block was fixed and reviewed again:
  - invisible collision around lamp shades and trees
  - the narrowing landing into the gallery was untested
  - the sunbeam was built before its sun angle was set, so it ignored the slant
  - hollow stairs
  - an undrawn ledge on top of the arch header
  - a close-call whoosh that played on the way into a wall
