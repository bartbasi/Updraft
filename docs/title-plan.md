# Title screen, Info and About: plan

Owner's ask: a splash/title screen with three buttons. **PLAY** goes straight into the game,
**INFO** explains everything (objectives, Course vs Endless, controls, updrafts, downdrafts,
points and bonuses), **ABOUT** has the license, the GitHub repository and general information.

Sizes below are in the game's logical pixels. The project is 1280 x 720 with stretch mode
`canvas_items` and aspect `expand`, so:

| Screen | Physical | Scale | Logical canvas |
|---|---|---|---|
| Fold5 cover (landscape) | 2316 x 904 | 904/720 = 1.256 | 1844 x 720 |
| Fold5 inner (landscape) | 2176 x 1812 | 2176/1280 = 1.70 | 1280 x 1066 |

**The 720 logical height on the cover screen is the binding limit, and so is the 1280 width
on the inner screen.** Everything below fits 1280 x 720.

---

## 1. The title screen

### What's behind it: a painted 2D sky, not a 3D scene

Decision: **a flat painted backdrop drawn with 2D polygons in one Control**, matching the
game's colours. No 3D, no watercolour pass, no textures.

Why: the Course scene builds a whole house and valley, and Endless builds its country, in
`_ready`. Showing either behind the title would cost that load once for the title and again
when PLAY reloads the scene (or need a new "fly from the title" path through the flight code).
A 2D backdrop builds in well under a frame, draws in a few batches at 120 Hz, and gets the
player to the buttons at once.

What it shows (all original, no reference to other games):

- **Sky**: vertical gradient from `9fc3e6` (top) to `f6e1d3` (horizon at 62 % of the height),
  the same colours as the flight's ProceduralSky.
- **Hills**: three soft rolling bands under the horizon. Far: lilac-grey (`c9b2d6` mixed 50 %
  with the horizon colour). Middle: sage `b7cfa0`. Near: `c9dcb8` (the sky's ground colour).
  On the middle band, toward the left, a small cream cottage (`fbf6ee`, roof `e8b3c4`) with
  one lit open window. That's a nod to the Course, kept tiny.
- **Clouds**: five soft cream puffs (3-4 overlapping ellipses each, `fbf6ee` at 90 %), drifting
  left to right at 8-14 px/s at different heights. They wrap round off the right edge.
- **An updraft**: a faint column of 14 small cream dots in the right third, rising at
  20-30 px/s and fading out near the top.
- **The flyer**: whichever look is saved in settings (red balloon by default, else the paper
  plane), drawn as simple 2D shapes about 90 px tall. It rides the top of that column at about
  82 % of the width and 34 % of the height, bobbing +/-10 px over 4 s and rocking +/-3 degrees.
- Animate by moving child nodes (`position`/`rotation`). Don't redraw the backdrop each frame.

### Sound

The existing `wind.wav` loops quietly (-24 dB) if sound is on in settings. Pressing PLAY plays
`whoosh.wav` once. Nothing else.

### Layout (centred column, anchored to the centre so it re-centres on fold/unfold)

| Item | Size / font | Notes |
|---|---|---|
| Top margin | 56 | |
| Title "Updraft" | font 112, ink `5d5468`, cream outline 10 | |
| Tagline | font 28, ink | "Ride warm air through a house, down a valley and out over a lake." |
| Gap | 36 | |
| **PLAY** | 440 x 128, font 60 | Has focus on open. Breathes gently: scale 1.00 to 1.03 over 1.6 s, looping. Stops once pressed. |
| Mode caption | font 24, ink 80 % | Just under PLAY. Says what PLAY opens (see below). |
| Gap | 24 | |
| **INFO**  **ABOUT** | 260 x 96 each, font 38, 24 apart | One row. |
| Version | font 18, bottom-right, 24 in from the edges | "Version 0.1.0" |

Height used: 56 + 135 + 36 + 36 + 128 + 30 + 24 + 96 is about 541 of 720. Width: the widest
item is the tagline (about 900), which fits 1280. All buttons use the existing theme (pink
rounded, lilac focus ring). PLAY at 128 logical is 161 px tall on the cover screen (about
10 mm). INFO and ABOUT at 96 logical are 121 px. Both clear the 48 dp minimum touch size.

### Focus and keys

- PLAY has focus on open. Left/Right move between INFO and ABOUT. Up/Down move between PLAY
  and that row. Enter or Space presses. Set focus neighbours explicitly so Down from PLAY lands
  on INFO.
- Tilt does nothing on the title. The tilt "level" is still taken when the flight starts, so
  however the player holds the phone when pressing PLAY becomes level. That is the comfortable
  hold, which is what we want.

### What PLAY opens

**PLAY opens the mode flown last, as now (`Boot.first_scene()`).** Never flown or not
unlocked: the Course. Unlocked and Endless flown last: Endless.

**The Course/Endless choice stays on the end card, not on the title.** The owner asked for
"just PLAY", and one button that always does something is the fastest start. Switching modes
is already one tap on the end card (Course / Endless). The mode caption under PLAY makes the
choice visible, so PLAY never surprises anyone:

- Endless locked (always the Course): "The Course", plus "  ·  best 2340" if the best is above 0.
- Course flown last: "The Course  ·  best 2340".
- Endless flown last: "Endless  ·  best 812 m  ·  340 stars".

On press: disable PLAY, set its text to "Taking off...", play the whoosh, and change scene on
the **next** frame so the new text shows during the load. No double launches.

---

## 2. Navigation (one rule: Back goes one screen up; the title is the top)

```
Title ──PLAY──> Flight ──end card──> Fly again (same mode)
  │                          ├─> Course / Endless (switch mode)
  │                          ├─> Settings ──Done/Back──> end card
  │                          └─> Menu ──> Title
  ├─INFO──> Info  ──Back──> Title
  └─ABOUT─> About ──License/Credits──> page ──Back──> About ──Back──> Title
```

| Where | Phone Back / Escape |
|---|---|
| Title (nothing open) | Back **closes the game** (Android convention). Escape does nothing, so a desktop never quits on Escape (keeps the current rule). |
| Info, About | Back to the title, with focus on the button that opened it. |
| License / Credits page | Back to About, with focus on that page's button. |
| Settings | Closes Settings, back to the end card (as now). |
| End card showing | Back goes to the **title**. |
| In flight (no card) | First Back shows the hint "Press Back again to leave this run" (2 s, existing `show_hint`). A second Back within 2 s goes to the title. Anything else, or waiting, keeps flying. |

Why ask twice in flight: holding the phone like a wheel, a thumb can easily brush the Android
edge-swipe Back gesture. Today that **quits the game** and loses the run. Going to the title is
gentler, and the second press stops a stray swipe from ending a long Endless run. It's not a
pause: the flight keeps going while the hint shows. Leaving mid-run abandons it and scores
nothing, the same as quitting does today.

**End card:** **Quit becomes Menu** (160 x 64, font 26, same slot). Don't add both: the title's
Back already quits, and two exits on a small card invite mis-taps. "Fly again" keeps its focus
and its place, so a retry stays one tap.

**Settings:** remove the About button. About and Info now live on the title, reached by
Menu. Settings becomes sensitivity, sound, swap climb and dive, Done. The flight scenes then no
longer build AboutPanel at all.

**Boot:** make the title the main scene (`run/main_scene`). Keep `first_scene()` as a static
helper (tests use it) and call it from PLAY. The fallback stays: if Endless fails to open,
open the Course.

---

## 3. INFO

### Layout: a section rail on the left, one section showing at a time

A full-screen cream panel (outer margins 40 left/right, 24 top/bottom):

- **Left rail**, 280 wide: eight toggle buttons, 280 x 60, font 24, 8 apart, all in one
  ButtonGroup. The section showing stays in the "pressed" pink (`e8b3c4`) so the player can
  see where they are. Height: 8 x 60 + 7 x 8 = 536. That fits 720 with room to spare.
- **Right column** (fills the rest): a header row with the section title (font 36) and a
  **Back** button (160 x 64, font 26) at the right. Below it, the existing ScrollContainer with
  the soft lilac thumb-wide scroll bar, holding the section's paragraphs.
- Text: body font **24** (up from 20; it's read at arm's length on a 904 px screen). `## `
  sub-headings are font 28. Use **autowrapping labels**, one per paragraph. The longest
  section is about 2,600 characters, so re-wrapping is cheap, and the text reflows across the
  cover and inner screens. Keep the existing few-paragraphs-per-frame fill (4 ms budget). If
  it is slow on the phone, fall back to `wrap_lines` at column 64 (the right column is about
  830 wide on the inner screen).

Why tabs and not one long page with jump links: each section is short (1-2 screens). It opens
at its top, with nothing to land mid-paragraph, and a player who taps "Points" sees only points.

Rail sections, in order: **Objectives, Course and Endless, Controls, Updrafts, Downdrafts,
Points and bonuses, Sounds, Tips.** INFO opens on Objectives.

Focus and keys: the first rail button has focus. Up/Down move along the rail, and
**moving focus shows that section** so the arrows browse. Right moves to Back. The mouse wheel
or a finger drag scrolls the text. Escape/Back returns to the title.

Text source: `HowToFly.TEXT` stays the single source. `# ` starts a rail section (its button
label is the heading), `## ` starts a sub-heading inside a section, and anything else is a
paragraph. Lines starting "- " are list items, shown as they are. Don't use bullet or star
glyphs, because phone fonts may lack them.

### The guide text (paste as `HowToFly.TEXT`)

Every number below was checked against `tuning.gd` (`style_moments`, `landing_bonus`,
`airtime_*`, `points_per_meter`, `big_star_value`, `arc_bonus`, `points_per_star`,
`endless_wind_*`), `endless_game.gd` (`POINTS_PER_METRE`, `FRESHENING_AT`, the end rules),
`game.gd` (the unlock rule, splashdown), `pieces.gd` (the lift sources, the line-bonus titles,
the first distance at which each place can appear) and `player_settings.gd` (sensitivity 0.5 to 2).
It keeps every phrase `test_the_guide_matches_the_game` looks for.

```text
# Objectives

Updraft is about staying in the air. You are always gliding gently down, and rising air lifts you back up. Find it, ride it, and see how far you can go.

## The Course

A kid lets the red balloon go (or throws the paper plane) in an upstairs bedroom. Fly out of the door, along the gallery, down the stairs, through the living room and the kitchen, and out of the open window into the valley. Outdoors, go where you like: thermal to thermal down the valley, along the long ridge on the left, or on through the Gap in the far hills to the lake.

Things to aim for, from your first flight to your hundredth:

- Get out of the window.

- Then come to rest anywhere without crashing. Coming down on the lake counts. The first time you do, Endless opens.

- Fly the best line through the tricky moments for style points.

- Come to rest on a landing spot for a bonus: the lavender field in the valley, the beach by the lake, the picnic blanket up on the plateau above the ridge, or the hardest and best of all, the little island in the middle of the lake.

- Beat your best score.

## Endless

Endless starts in the air beyond the lake, over a country that never ends and is made fresh every run. Stay up as long as you can, catch the stars, and fly past the bunting that marks your best distance. Every star you catch is kept in your bank.

## Choosing a mode

PLAY on the title opens the mode you flew last. To switch, finish a flight and press Course or Endless on the end card.

# Course and Endless

## The Course

Where: a house, a valley and a lake. It is the same every time, so you can learn it.

Start: thrown from the bedroom.

The air: still, apart from the rising and sinking air you find. You set the pace.

Ends: when you come to rest or crash. Bumping a wall or sliding along the ground does not end it.

Score: distance, style, airtime outdoors and a landing bonus (see Points and bonuses).

Best: your best total score.

## Endless

Where: open country beyond the lake, different every run.

Start: in the air at the Rim, above the lake, looking out over the country.

The air: a breeze behind you carries you along. It freshens the further you go, at 250 m, 500 m and 1000 m (you will see "The breeze is freshening"), so the country comes at you faster.

Ends: the moment you come down on flat ground, slide along the ground, come down on water, or crash. Turning round and flying back past the start ends it too ("Wrong way!"). Just grazing a steep hillside bounces you off and the run goes on.

Score: distance and stars.

Best: your furthest distance, marked across the valley with bunting.

Opens: once you have flown out of the Course's window and come to rest without crashing.

## The Course, room by room

Bedroom: turn out through the door onto the landing and bank left into the gallery.

Gallery: a long, sunny glide. A sunbeam through a window and another through the skylight lift you.

Stair hall: a cool downdraft pulls you down the first flight of stairs. Turn right at the landing and fly down the second flight, through the arch.

Living room: warm air over the radiator, and a lamp to fly under.

Kitchen: steam from the kettle lifts you toward the open window.

The valley: the hay field, the barn roof, the ploughed field, the bonfire and the chalk pit each send up a thermal. The long ridge on the left has lift all along its slope, and the lavender field lies on the valley floor. Up on the plateau above the ridge is the picnic blanket.

The Gap and the lake: through the notch in the far hills a bowl opens with a lake, an island, a beach and a bluff with lift along it.

## Endless, place by place

New places turn up the further you fly. The Mere only appears after 200 m.

Cloud Street: a line of clouds over a long band of rising air. Fly along underneath.

Barley Field: a thermal with a spiral of stars that starts low over the field. Dive down to it, then circle: the stars form in front of you as you climb.

Long Ridge: lift all along the slope. Fly along it, a little way out.

Hamlet: chimney smoke rises in plumes. Weave through them.

Kite Meadow: ring kites to fly through. Touching a ring snags you but never crashes you.

Viaduct: a solid stone wall. Dive through an arch (the middle one holds a big star) or go over the top. There's a thermal off the shingle beyond.

Pasture: hedges to skim low and fast, warm air close over the grass, and a bonfire whose smoke lifts you out.

Washing Lines: duck under the sheets or hop over the lines. The washing copper's steam lifts you on.

Poplar Row: a wall of poplars with one gap. Thread it.

Dutch Barn: fly in one door and out of the other, or over the roof. The muck heap beyond sends up a thermal.

Standing Stones: weave in through the stones, past the big star in the middle. A thermal rises off the down beyond.

Mere: a lake where the air sinks. Make for the island and spiral up its thermal.

# Controls

Hold your phone sideways in both hands, like a steering wheel.

- Dive: tilt the top edge away from you. The nose drops and you speed up.

- Climb: tilt the top edge toward you. The nose rises and you slow down. Hold it too long and you stall: the nose drops and you lose height until you have speed again.

- Turn: tilt left or right to bank. The further you tilt, the tighter the turn.

Level is however you are holding the phone when a flight starts, so get comfortable before you press PLAY or Fly again.

Settings, on the end card, has tilt sensitivity (0.5x to 2x), sound on or off, and "Swap climb and dive" if you want it the other way round.

The red balloon and the paper plane fly exactly the same. Swap between them on the end card.

On a computer: Up or W dives, Down or S climbs, Left/Right or A/D turn, and Escape steps back.

## Getting around

Back steps out of Info, About and Settings. On the end card, Back (or Menu) goes to the title. While flying, press Back twice to leave the run. On the title, Back closes the game.

## How flying works

You are always gliding gently downhill. The only way to gain height is to find rising air.

Speed and height trade with each other. Dive to gain speed, to reach somewhere or squeeze through a gap. Climb to turn speed back into a little height.

## Touching things

A gentle touch on a wall, the floor or a hillside bounces you off or slides you along. You hear a tap. Flying hard and head-on into something is a crash: the plane crumples, the balloon pops, and the flight ends.

In Endless, kite rings and the washing never crash you: touching one snags you and costs some speed.

# Updrafts

Rising air lifts you. When it is carrying you up you hear soft beeps, faster and higher the stronger the lift. Each kind looks different.

## Warm air indoors

The radiator's shimmer, the kettle's steam, and the sunbeams through the gallery window and the skylight. Fly into them to climb.

## Thermals

Warm air rising off sun-warmed ground. In the Course: the hay field, the barn roof, the ploughed field, the chalk pit and the beach sand. In Endless: the barley field, the shingle by the viaduct, the muck heap by the barn, the down past the standing stones and the island's sand.

How to spot one: drifting motes, a faint shimmering column, a fluffy cloud sitting on top, and birds circling near the top.

How to use one: fly in and keep turning in a steady circle inside it. You climb with every lap. Once you reach a thermal it drifts slowly with the breeze, so follow the beeps and keep re-centring. The lift stops near the cloud, and the cloud thins once you have climbed it: time to glide on to the next. In Endless, thermals also fade once they have drifted a while.

## Smoke and steam

The Course's bonfire smoke is a wide column: circle in it like a thermal. In Endless, the Hamlet's chimney plumes and the Pasture's bonfire are narrow and strong, so fly through them for a quick lift. The washing copper's steam is wide enough to circle in.

## Ridges

Where the wind blows up a hillside, the air rises all along the slope: the long ridge on the left of the valley, the bluff above the lake, and Endless's Long Ridge. Dandelion seeds float up it, and the wind swells as you arrive. Fly along the slope, a little way out from it, and you climb as you go. A gull may come and fly beside you. Don't touch the slope. In Endless a graze bumps you off and breaks your line of stars, and sliding on it ends the run.

## Cloud streets

In Endless, a straight line of clouds marks a long band of gentle rising air: Cloud Street, over Kite Meadow, and leading into and out of the gap at Poplar Row. Fly along underneath them.

## Low warm air

In Endless, close over the Pasture and the cottage gardens by the Washing Lines, the sun-warmed air holds you up, so skimming low you hardly sink. A little higher and it is gone.

# Downdrafts

Sinking air pushes you down. It is useful for a quick dive, but costly when you need height.

## Always sinking a little

Wherever there is no rising air you sink slowly, and faster when you dive. That is normal gliding, not a downdraft.

## The stair downdraft

In the Course's stair hall, cool air pours down the first flight of stairs. You will see pale wisps falling and hear a rush as you enter. Dive with it for speed: going straight down its middle is the Downdraft dive, a style moment. Then turn right at the landing.

## Over the water

Over the Course's lake and Endless's Mere the air sinks gently. Low ticks tell you, coming faster the stronger it sinks. Crossing the water costs height, so go over it high. In Endless, make for the island's thermal and spiral up.

## Losing the lift

Outdoors, a soft sigh means you have just flown out of the side of rising air. Turn back into it.

# Points and bonuses

## The Course

Distance: 10 points for every metre along the way. It is measured along the route from the bedroom, and only your furthest point counts, so circling does not add to it.

Style: ten moments pay extra for flying close to the best line through them. Each pays once a flight. The closer you stay all the way through, the more it pays: right on the line pays in full, and the award falls to nothing at the edge. Cutting part of a moment short counts as flying far off. A golden "Perfect" pop-up means a near-perfect pass.

- Door turn: up to 100
- Sunbeam: up to 80
- Downdraft dive: up to 120
- Landing turn: up to 150
- Radiator lift: up to 100
- Under the lamp: up to 150
- Kettle steam: up to 100
- Out of the window: up to 150
- Ridge run: up to 120
- Through the Gap: up to 150

All ten together: 1220.

Airtime: 5 points for every second in the air outdoors, up to 90 seconds (450 points).

Landings: come to rest in the lavender (+200), on the picnic blanket (+400), on the island (+500) or on the beach (+250). A crash pays no landing bonus. Coming down on the water is a splashdown: no bonus, but not a crash either, and your airtime still counts.

The end card adds it up: distance, style (and how many of the ten moments you scored), airtime, landing bonus, total and your best.

## Endless

Score: 10 points for every metre and 10 for every star.

Stars: 1 each, and big stars are worth 10 (that's 100 points). Stars lie in lines along the best way through each place, so they show you where to fly. Take every star of a line for a bonus (+5), worth 50 points. The bonus pops up with the line's name: Full arc!, Full spiral!, Hoop run!, Hedge-hop!, Under the washing!, Threaded! or Through the stones!

Missing a star breaks its line, and the rest of it dims. A bump or a snag breaks the line you are on too. You keep the stars you have already caught, and the run goes on.

The line follows your height. Come in low and the stars lead through the barn door, under the washing or into the stones. Come in high and they lead over the top.

Your bank: every star you catch, bonuses included, goes into your bank when the run ends, however it ends. The end card shows this run's stars and your bank.

Your best: your furthest distance. Bunting across the valley marks where your best run ended. Fly past it for a cheer and "Past your best!".

# Sounds

A chime: you have flown into rising air. Each kind has its own note.

Beeps: you are climbing. Faster and higher means stronger lift.

A sigh (outdoors): you have just flown out of the lift.

A rush of air: into the stair downdraft.

Low ticks: you are in sinking air over water.

The wind: it gets louder the faster you fly, and swells when you burst out of the window, reach a ridge or pass through the Gap.

A whoosh: you rushed close past something without touching it, or through an arch at speed.

A sparkle: style points. A brighter sparkle for a perfect pass, a big star or a full line.

A tink: a star. Each star in a row along a line rings a note higher.

A bell: through a kite ring.

A flutter: a kite ring or the washing snagged you.

A tap: a bump.

A crumple or a pop: a crash.

A splash: down in the water.

# Tips

Arrive high. It is much easier to lose height than to find it.

In a thermal, keep turning steadily. If the beeps fade you have drifted out, so turn back toward where they were strongest.

Climb gently in rising air, with just a little nose-up. You rise faster than if you dive through it.

Give yourself time: line up with a door, a gap or an arch early, then hold steady.

Watch the clouds and the birds. They mark the rising air before you can feel it.

In Endless, follow the stars. They lead into rising air and through the safe way.

For the island: come through the Gap high, ride the thermal over the beach sand, then glide out over the water with height to spare and settle gently on the island.

Style points come from smooth, early lines. Start each turn before you need it, and stay in the middle of doors and arches.
```

(The list items are separated by blank lines so that each is its own paragraph. The style
list is one paragraph of ten lines.)

---

## 4. ABOUT (opened from the title)

The About page loses "How to fly" (now Info). It keeps everything else. It's still built the
first time it opens, and its License and Credits pages still fill a few paragraphs a frame.

| Row | Content |
|---|---|
| Title | "Updraft", font 52 |
| Byline | "Version 0.1.0  ·  Made by Bart Basi", font 22 |
| Blurb | the existing BLURB, font 26 |
| Feedback ask | the existing FEEDBACK_ASK, font 26 |
| Buttons | **Send feedback** and **Source code**, 300 x 80, font 32 |
| Plain text | `bartbasi@gmail.com    github.com/bartbasi/Updraft`, font 22. The repository address is shown as well, for a phone where the link can't open (the owner asked for the repository). |
| Buttons | **License**, **Credits**, **Back** (180 x 64, font 26; "Done" becomes "Back" to match Info) |
| Privacy line | "Updraft collects nothing: no ads, no tracking, no internet." font 19 (true per `docs/privacy.md`) |
| Legal | the existing LEGAL, font 19 |

Height check: 62 + 30 + 2 x ~70 (two-line paragraphs) + 80 + 30 + 64 + 26 + 50 + 12 x 9 gaps
+ 56 margins is about 646 of 720. Tight but fits. If it overflows on the cover screen, drop
the privacy line first. Focus opens on Send feedback. Back from License/Credits returns focus
to that button. Back from About returns to the title with focus on ABOUT.

**Doc fix for the lead:** `docs/privacy.md` says the feedback button is under "Settings >
About" and that there are "two small files". It should become "About, on the title screen",
and three files (settings, best score, progress).

---

## 5. Testing

### Tests the build should add or change

1. **Boot/title:** the main scene opens the title. PLAY's target equals `first_scene()` for
   each progress state: fresh, unlocked + last Course, unlocked + last Endless, locked + last
   Endless (a hand-edited file). Expect Course, Course, Endless, Course.
2. **Title:** three buttons named PLAY / INFO / ABOUT. PLAY has focus. Each button is at least
   the size above. The mode caption reads correctly for each of the four states.
   PLAY is disabled after one press (a second press doesn't load twice).
3. **Back on the title:** `handle_back()` returns false with nothing open (so Back quits).
   From Info, About, and License/Credits, it steps back one screen and focus lands on the
   opener.
4. **Back in flight:** the first Back shows the hint and the flight continues. A second Back
   within 2 s changes to the title. A second Back after 2.5 s shows the hint again. With the
   end card showing, one Back goes to the title. With Settings open, Back closes Settings first.
5. **End card:** it has Menu and no Quit. Menu changes to the title. Fly again still has
   focus.
6. **Settings:** no About button. Flight scenes never build AboutPanel.
7. **Guide:** keep `test_the_guide_matches_the_game`. Add: the `# ` headings are exactly the
   eight rail sections, in order. Every section is non-empty. The text contains the sum of
   `style_moments` points ("1220", computed in the test, not hard-coded), the airtime cap in
   points (`airtime_points_per_second x airtime_max_seconds`), the big star in points
   (`big_star_value x points_per_star`) and the line bonus in points
   (`arc_bonus x points_per_star`). Every `FRESHENING_AT` distance appears ("250 m", ...).
   Every line-bonus title in `pieces.gd` appears. Every place in `EndlessPieces.NAMES`
   appears. No character outside the theme font's glyphs (check with
   `Font.has_char` on the default font).
8. **Info fill:** each section fills within 10 frames. After filling, every section's last
   paragraph is reachable by scrolling. Moving focus down the rail shows each section in turn.
9. **About:** has no "How to fly" button. It shows the repository address text. The existing
   feedback URL, license and credits tests still pass.

### On the phone (Fold5, cover and inner)

- [ ] Cold start to the title in under 1.5 s. The backdrop animates smoothly at 120 Hz.
- [ ] Title fits the cover screen (2316 x 904) with nothing clipped. Fold open: it re-centres on
      the inner screen (2176 x 1812). Fold shut while on the title: still right.
- [ ] Every button can be hit first try with a thumb while holding the phone like a wheel.
- [ ] PLAY shows "Taking off..." at once. Time from the tap to flying is about the same as
      today's app start. Tilt is level at the angle held when PLAY was pressed.
- [ ] The caption under PLAY matches the mode that opens (test with Endless locked, then
      flown last, then the Course flown last).
- [ ] Info: all eight sections readable at arm's length on the cover screen (body 24). Each
      scrolls by finger and by the scroll bar. No section shows a missing-glyph box.
- [ ] Info on the inner screen: text reflows and nothing runs under the rail.
- [ ] About: Send feedback opens the email app, and Source code opens GitHub in the browser.
      Coming back from each lands on About with the game intact.
- [ ] Back gesture: from the title it quits. From Info, About, License and Credits it steps up
      one screen. In flight, one swipe only shows the hint and two leave. From the end card
      it goes to the title.
- [ ] Deliberately brush the edge-swipe while flying with both hands: one stray swipe must
      not end the run.
- [ ] Sound off in Settings also silences the title's wind.
- [ ] Menu, then PLAY: the same mode as just flown, and the bests on the caption are updated.

---

## Later ideas (not for this build)

- A small mode switch (Course | Endless) under PLAY once Endless is unlocked, if playtesters
  ask to start Endless from the title.
- A settings gear on the title, so swap climb and dive can be set before the first flight.
- A pause in flight (the double-Back hint is the light stand-in for now).
- Banking an abandoned Endless run's stars when the player leaves mid-run.
- Little illustrations per Info section (a thermal with a cloud and circling birds, a ridge
  with the wind arrow), drawn in the title's 2D style.
