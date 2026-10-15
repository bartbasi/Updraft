# Hangar and daily flight plan (Endless step 5)

The owner's order (2026-10-14): this step first, then step 3 (forks and Warm Down), then step 4
(hazards and movers, plus the houses and the kitten). The owner liked the balloon colours and
patterns, paper-plane designs and trails from `endless-plan.md` §9. **No real-money purchases,
ever**: stars are earned only by flying.

This plan replaces `endless-plan.md` §8.2, §8.4 and the looks rows of §9 where they differ. It
fits what has been built since: the title (PLAY / INFO / ABOUT), the Menu button, banking stars
when you leave mid-run, the bunting, and `Progress` / `PlayerSettings` as they are now.

**Scope.** The Hangar with three tabs (Balloon, Paper plane, Trails). Buying, wearing and
saving. The daily flight. Info and title text. **Not in scope:** power-ups, upgrades, second
wind, missions, countries (steps 6-8). The hooks for them are listed in §7.

---

## 0. What players earn now (measured 2026-10-14, wind rising, `tools/endless_log.gd`)

| Pilot (proxy for) | Runs | Run length | Stars a run | Rate |
|---|---|---|---|---|
| Hands-off (a first-timer on the phone) | 12 | 65-238 s, median 126 s | 11-39, median **16** | 0.13 ★/s |
| Middle-flyer (a first-timer) | 12 | median 132 s | about the same (21% taken) | |
| Chaser (improving, chases stars) | 12 | 400 s cap, still flying | 313-465, median **395** | 1.0 ★/s |
| Skilled | 4 | 600 s cap, still flying | 666-731, median **715** | 1.2 ★/s |

The test pilots above the hands-off one never fail, so a human's run ends sooner. For pacing I
use these human runs:

| Player | Run | ★ a run |
|---|---|---|
| First days | 1-2 min | 15-25 |
| Improving (week 2) | 2-3 min at about 50% of stars | 60-120 |
| Good (week 3+) | 4-5 min at about 75% | 250-350 |

Every hands-off run passed 100 m (the lowest was 115 m). That sets the daily flight's goal (§4).

---

## 1. Where the Hangar lives, and its screens

### 1.1 Ways in

The Hangar appears **once Endless is unlocked**. Stars only come from Endless, so before that
there is nothing to buy. The Course's unlock card already celebrates; the Hangar button simply
shows up from then on.

| Where | What changes |
|---|---|
| **Title** | The row under PLAY becomes **[DAILY] [HANGAR] [INFO] [ABOUT]**, each 250 × 96, font 36, 20 apart (1,060 wide; fits the inner screen's 1,280). Locked: **[INFO] [ABOUT]** as now. Focus: Down from PLAY lands on DAILY, and Left/Right walks the row. |
| **End cards** (Course once unlocked, and Endless) | The bottom row becomes **[Fly the paper plane] [Hangar] [Settings] [Menu]** (340 / 200 / 200 / 160 × 64; 942 wide). Debug builds' Wind button still fits (1,248 with the card's margins). |

The Hangar is **one panel (`HangarPanel`, a Control like `InfoPanel`) used in both places**. On
the card it opens over the card with no scene change. Back or [Done] returns to the card with
focus on [Hangar]. On close, the flyer takes on whatever is worn now, so "Fly again" flies it.
From the title, Back returns to the title with focus on HANGAR. The title's flyer redraws in the
new look.

Why both: the end card is where the stars have just landed ("I can afford it!"), and the title
is where a player browses. "Fly the paper plane" stays on the card because it is the one-tap
swap players already use.

### 1.2 Layout

The layout is chosen by aspect: **side by side** when width / height ≥ 1.3, so the cover screen
(1,844 × 720 logical) and any phone held landscape. **Stacked** below 1.3, so the inner screen
(1,280 × 1,066).

**Side by side (cover, 1,844 × 720):**

```
+-----------------------------------------------------------------------------------+
| [Back]                       Hangar                                  (star) 1,204 |  bar 88
+--------------------------------+--------------------------------------------------+
|                                | [ Balloon ] [ Paper plane ] [ Trails ]           |  tabs 72
|      live preview              |  +------+ +------+ +------+ +------+             |
|      (the flyer turning,       |  |icon  | |icon  | |icon  | |icon  |             |
|       trail streaming)         |  |Red   | |Sky   | |Sun-  | |Mint  |             |  cards
|                                |  |Wear- | |(s) 50| |flower| |(s)150|             |  230 x 230
|   Polka dots                   |  +------+ +------+ +------+ +------+             |  (scrolls)
|   [   Buy  (star) 600   ]      |  ...                                              |
+--------------------------------+--------------------------------------------------+
```

- Preview: the left 40% of the width, less a 24 margin, so about 690 × 560.
- Under the preview: the item's name (font 34) and **one action button, 340 × 96**.
- The cards are a grid in a vertical ScrollContainer that scrolls by dragging. They are 230 × 230
  with 20 gaps, so 4 a row in the right 60% (about 1,040 wide) and 2 rows in view.

**Stacked (inner, 1,280 × 1,066):**

- The same bar.
- Preview: full width, 420 tall, with its name and action button at the bottom right of the
  preview area.
- Tabs.
- Cards: 4 a row (4 × 280 + 3 × 20), 2 rows in view.

**Sizes on the phone.** Cards at 230 logical are 290 px on the cover (about 18 mm): easy to
tap. The bank's star is drawn, as on the HUD, never a glyph.

### 1.3 A card

| Part | Spec |
|---|---|
| Icon | 150 × 150. The item drawn in 2D: a balloon disc in its colours, a paper dart with its design, or a short curve of the trail. Built once from the item's colours, and its texture if it has one. |
| Name | font 24 |
| Status line | Wearing: lilac fill and "Wearing". Owned: "Owned". Not owned: drawn star + price, gold if affordable, ink 50% if not. |

### 1.4 Trying, buying, wearing

1. **Tapping a card puts it on the preview at once**, owned or not. You try before you buy.
   Leaving the tab or the Hangar without buying puts back what you wear.
2. **The action button** shows one of four things:
   - Owned and not worn: **[Wear]**.
   - Worn: **"Wearing"**, disabled.
   - Affordable: **[Buy (star) 600]**.
   - Not affordable: **"(star) 600: 214 more"**, disabled, ink 60%.
3. **Buying takes two taps.** [Buy] turns into a confirm row in the same place: "Buy Polka dots
   for (star) 600?" with [Buy] (gold) and [Not now].
4. **A purchase:**
   - saves first (§3.3). If the save fails: "Couldn't save. Nothing was spent." and nothing
     changes.
   - Then wears it.
   - The bank counts down over 0.4 s.
   - The style_perfect sparkle bursts on the preview with `style_perfect.wav`.
   - The preview flyer does one faster lap (1.0 s).
5. **Wearing** a balloon item also makes the balloon your flyer. Wearing a paper design makes the
   plane your flyer. A trail applies to both. A small line under the name says "You fly the
   balloon" or "You fly the paper plane".
6. Back from the confirm row cancels it. Back from the Hangar closes it.

### 1.5 The preview

- A SubViewport (transparent; the title's sky gradient behind it) holding:
  - only the flyer's meshes, built by the same static builders the Flyer uses;
  - one directional light;
  - the trail.
- No physics and no Flyer node.
- **Motion:**
  - the flyer flies a slow level circle, radius 1.2 u, at 3 u/s, banked 15°;
  - the camera sits 3.2 u out, 0.8 u up, and looks at the circle's centre;
  - so the trail streams out behind it and the pattern shows from every side over one lap
    (2.5 s).
- The balloon's string is drawn hanging straight with a gentle sway (no simulation).
- **Cost:** under 1 ms a frame. It renders only while the Hangar is open.
- **The title's flyer** (`Flyer2D`) is replaced by the same preview at 90 px, hovering on the
  updraft as now. It shows no trail on the title: the motes are the updraft, so keep them
  readable. It costs one tiny SubViewport, with no world to build, so the title still opens at
  once.

---

## 2. The catalogue

Rules for every look:

- **Looks never change flying.** The collision sphere, the flight model and every cue are as
  before.
- **Nothing may look like an air cue.** Cream motes and seeds mean thermals and ridges, pale
  wisps mean sink, smoke means plumes, gold means stars. Trails therefore use no cream dots, no
  seeds, no wisps, no smoke and no gold sparkle. The soap bubble is kept for step 6's shield.
- **Drawn in code only:** vertex colours, small textures painted into an `Image` at load
  (cached, built once, never per frame), ribbons in an ImmediateMesh like the string, and
  CPUParticles3D. No imported art.
- **Sizes on screen.** In the chase view (camera 3.4 back, 1.0 up, 80° FOV), 1 u is about
  121 px.
  - The balloon is about 85 × 98 px. Pattern features must be at least 0.1 u (12 px).
  - The plane spans about 157 px, but from behind and above its wing is only about 45 px deep
    in level flight. Its designs show best in turns, so they must be bold: a few strong
    features, with lines at least 3 texels thick on a 128 texture.

### 2.1 Starters (owned by everyone, free)

- **Red** balloon (`e0484f`, as now).
- **Plain** paper, white with the coral felt-pen tips (as now).
- **No trail.**

### 2.2 Balloon: one worn at a time

Built with a finer sphere for the balloon (24 segments × 16 rings, about 400 triangles; it
was 14 × 8). The knot is darkened 20% from the base colour. **The pop's scraps take the
balloon's colours** (pattern balloons alternate their two main colours), and so does the title
icon.

| id | Name | ★ | How it's drawn |
|---|---|---|---|
| `red` | Red | starter | `e0484f` |
| `sky` | Sky blue | **50** | `6fb3e0` |
| `sunflower` | Sunflower | **75** | `f2b63c` (warmer than the stars' `f4c84a`) |
| `mint` | Mint | **150** | `8fd1a8` |
| `lilac` | Lilac | **150** | `b9a2dc` |
| `bubblegum` | Bubblegum | **150** | `f29bb8` |
| `twotone` | Two-tone | **300** | Vertex bands. Top 55% sky `6fb3e0`, bottom cream `fbf6ee`, with a 1-ring sunflower band between. |
| `candy` | Candy stripes | **400** | Vertex gores. 8 vertical gores alternating red `e0484f` and cream `fbf6ee`, flat-coloured per gore (split vertices at the seams). |
| `polka` | Polka dots | **600** | Texture, 128 × 64 equirectangular. Bubblegum `f29bb8` ground, 18 cream dots of radius 0.06 u (about 7 texels), offset rows. Dots near the poles are drawn smaller to undo the stretch. |
| `smiley` | Smiley | **800** | Sunflower ground with a simple ink `5d5468` face: two oval eyes 0.06 u and a smile arc 3 texels thick. **The face is on the side the camera sees** (+Z, facing back at you). Two pink cheeks at 40%. |
| `starry` | Starry night | **1,200** | Texture 256 × 128. Navy `2c3a6b` ground, 14 cream five-point stars of 0.06-0.1 u (cream, not gold, so they never read as pickups), and a crescent moon 0.18 u on the camera side. |
| `rainbow` | Rainbow | **2,000** | Vertex bands. 7 horizontal bands top to bottom: `e0484f`, `f29a4a`, `f2c14e`, `8fd1a8`, `6fb3e0`, `7c86d0`, `b9a2dc`. |

### 2.3 Paper plane: one worn at a time

- **UVs.** The plane mesh gets planar UVs from above: u = (x + 0.5) / 1.0, v = (z + 0.62) / 1.04.
  Art.Builder needs UV support for these two flyer meshes only; that is the lead's call.
- The texture is multiplied by the vertex colour, so the crease and keel stay shaded.
- The felt-pen tips are drawn on Plain and the coloured papers only.
- The crumpled ball takes the paper's ground colour.
- Textures are 128 × 128 with linear filtering and mipmaps.

| id | Name | ★ | How it's drawn |
|---|---|---|---|
| `plain` | Plain | starter | As now |
| `pink` | Pink paper | **50** | Vertex colours: white becomes `f6c3d3`, the crease `ebb0c2` |
| `skypaper` | Blue paper | **75** | `b9d8f0` / `a6c8e4` |
| `lemon` | Lemon paper | **150** | `f6e49a` / `ead489` |
| `notebook` | Notebook | **100** | Cream `fbf8f1`. 7 pale-blue `9fc3e6` lines across the chord, 3 texels thick. One coral margin line along the chord near the left tip. |
| `graph` | Graph paper | **200** | Pale `f1f6ec`, a sage `b7cfa0` grid every 12 texels, 2 texels thick, with every 4th line 4 thick. |
| `newspaper` | Newspaper | **400** | Grey cream `ece8df`. Columns of ink bars at 45% (no real words), one solid headline bar, and one grey picture block. |
| `map` | Old map | **800** | Parchment `ead9b3`. A blue-grey coastline curve, a dotted coral route and a coral X near the right tip. |
| `waves` | Wave print | **1,500** | Indigo `3f4e8c` ground with rows of cream scallops (arcs 3 texels thick) and a sky-blue fill in every other row. |

### 2.4 Trails: one worn at a time; both flyers

- **Where they start.** A trail comes from the balloon's knot, or from the plane's tail.
- **World space.** Particles stay where they are emitted, so the trail stays behind in turns.
- **Near-camera fade.** Every trail material uses distance fade (pixel alpha, fully faded at
  0.8 u from the camera, full from 2.0 u). In straight flight the trail runs toward the camera,
  so this keeps it from filling the view.
- **Speed shows (Feel).** The emission rate and the ribbon's length scale with airspeed, from
  ×0.6 at 4 u/s to ×1.6 at 14 u/s. A dive visibly streams.
- **On a crash** the trail stops emitting, and what is already out fades over its life.
- **Budget:** at most 48 particles, 1 draw call, unshaded, no shadows, and under 0.2 ms on the
  Fold5.

| id | Name | ★ | How it's drawn |
|---|---|---|---|
| `none` | No trail | starter | |
| `ribbon` | Ribbon | **250** | A ribbon strip 0.06 u wide, the last 0.5 s of the path (up to 0.8 s when diving). Bubblegum `f29bb8` fading to transparent. It twists gently: its width faces the camera with a slow ±20° roll. |
| `confetti` | Paper confetti | **600** | Squares 0.06 u, 14 a second at 6 u/s. Five colours (coral, sky, sunflower, mint, lilac). They tumble, fall at 0.6 u/s and live 0.9 s. |
| `petals` | Blossom petals | **1,200** | Oval petals 0.08 × 0.05 u, pink `f6c3d3` and white-pink `fbe4ec`, 8 a second. They flutter (sideways sine 0.3 u at 1.5 Hz), fall at 0.4 u/s and live 1.2 s. |
| `rainbowtrail` | Rainbow ribbon | **2,000** | The ribbon at 0.15 u wide, with the 7 rainbow bands across it as vertex colours. 0.6 s of path. |

### 2.5 Totals and pacing

| Group | Items | ★ |
|---|---|---|
| Balloon colours | 5 | 575 |
| Balloon patterns | 6 | 5,300 |
| Paper colours | 3 | 275 |
| Paper designs | 5 | 3,000 |
| Trails | 4 | 4,050 |
| **All looks** | **23** | **13,200** |

Half by price is 6,600 (about 17 items, because the cheap ones go first).

Each tier has a cheap first buy whichever flyer you like: 50 for the balloon (Sky blue), 50 for
the plane (Pink paper), 250 for a trail.

**Runs to milestones** (stars from runs as in §0, plus the daily reward from §4, which pays
100-200 a day):

| Player | First buy (50) | Half (6,600) | Everything (13,200) |
|---|---|---|---|
| First-timer, 16 ★ a run | **run 1** if they fly the daily (100 at 100 m); otherwise run 3-4 | | |
| Casual, 15 min a day, 5 days a week, improving (day 1: 6 × 20 + 100; week 1 about 450 a day; week 2 4 × 120 + 150; week 3 3 × 200 + 150; week 4 3 × 250 + 150) | day 1 | about **day 12** (week 3) | about **week 4** (20 play days) |
| Good, 300 ★ a 5-min run | run 1 | about 20 runs (under 2 hours) | about 40 runs (3.5 hours) |

**Why these numbers.**

- The first buy should come on the first day: the daily makes that certain without making runs
  pay more.
- A casual player owns everything in about a month. That suits a looks-only shop until step 6
  adds 13,800 of upgrades and step 7's missions add income.
- Good players clear the looks in a few evenings, which is fine: step 6 gives them the long
  goal.
- The owner can scale every price with one number: `HangarCatalogue.PRICE_SCALE` (1.0, applied
  to the table at load and rounded to 5).

**The owner's bank already holds stars.** It is kept as it is (§3.2), so on day one the owner
can probably buy a good part of the catalogue. That is expected: the pacing above is for new
players.

### 2.6 Feedback outside the Hangar

- **A card note when you can afford something new.** On the Endless card, if this run's
  banking lifted the bank from below to at or above the price of the cheapest item you don't own,
  add a gold line: **"Enough for Mint in the Hangar!"**.
  - It shows only when the bank crosses that line, so it is earned and rare. "New best!" keeps
    the note slot; this line goes last among the card lines in gold.
- The **Endless HUD** is unchanged.

---

## 3. Owning, wearing, saving

### 3.1 The catalogue lives in code, never in the save

- **`HangarCatalogue`** (static, data only) lists every item: id, slot (`balloon` / `paper` /
  `trail`), name, price, and how it is drawn.
- **Prices are read only from here.** The save holds ids, never prices.
- **Ids are never renamed or reused**, so a save from any version means the same things.

### 3.2 The new fields in `progress.json`

Existing fields are unchanged: `unlocked`, `stars`, `best_m`, `best_score`, `last_mode`.

| Field | Type | Valid | Default / when bad |
|---|---|---|---|
| `v` | int | 1-1000 | 2 (a missing `v` means a version 1 file: fine, nothing to convert) |
| `owned` | array of strings | each matches `^[a-z0-9_]{1,24}$`, duplicates dropped, at most 64 kept, starters dropped (they are implicit) | `[]`. A bad entry drops that entry only. |
| `wear` | dictionary | `{"balloon": id, "paper": id, "trail": id}`. Each must be a known item of that slot that is owned or a starter. | `red` / `plain` / `none`, per slot |
| `daily_date` | string | `YYYY-MM-DD` that parses as a real date | `""` |
| `daily_best_m` | int | 0..MAX_METRES | 0 |
| `daily_paid` | string | as `daily_date` | `""` |
| `daily_steps` | int | 0..5 | 0 |

- **Unknown but well-formed ids in `owned` are kept**, not dropped. A player who goes back to an
  older version, or a version that hid an item, keeps the purchase when they come back. They
  just don't show.
- **`MAX_BYTES` rises from 4,096 to 8,192** for steps 6-7 (levels and missions). It is still
  tiny.
- **The flyer choice stays in `settings.json` as `look`.** Wearing a balloon or paper item
  writes `look` too (both files, progress first). If the second write fails, the flyer is still
  the one wanted for this session, and the look is put right at the next save.

### 3.3 Spending, and never going negative

- **`Progress.buy(id) -> bool`** is the only way stars go down. Step 6's upgrades and second wind
  will use `Progress.spend(amount)`, the same core. It works on a fresh `load_all()`:
  1. Refuses if `unreadable`, an unknown id, already owned, or `price > stars`.
  2. Sets `stars -= price`, appends the id and sets `wear`.
  3. Saves with `save_all` (temp file, then rename).
  4. Returns false if the save failed. The caller then shows the old state and the stars are
     not spent.
- **`Progress.wear(slot, id) -> bool`** checks ownership and saves.
- **Banking a run** (`_finish`, `go_to_title`) already re-loads before adding. Keep that, so the
  Hangar opened over a card can never double-count.

### 3.4 Migration and bad files

- **An existing save** (only the five fields) loads with its bank, bests and unlock intact. The
  rest takes the defaults. It is written in the new shape at the next save. No conversion code
  is needed, only `clean()`'s new fields. A test uses a literal copy of today's file shape.
- **A backup, new this step** (purchases are now at stake):
  - Before every successful rename onto `progress.json`, copy the old file to
    `progress.json.bak`.
  - On load, if the main file opens but fails to parse, is over size, or is not a dictionary,
    **load `.bak` instead** (cleaned just the same), and warn.
  - If both are bad: defaults, as today.
- **Unreadable** (it exists but won't open): as today, saving is refused. In the Hangar, buying
  and wearing are disabled, with "Can't reach your save right now", so nothing can overwrite a
  bank that is only locked for the moment.
- **The bank is never negative.** `clean()` already turns any negative or fractional value into
  0. `buy()` checks before subtracting.

---

## 4. The daily flight

### 4.1 The seed

- **Today** = `Time.get_date_string_from_system()` (the phone's local date, `YYYY-MM-DD`). No
  internet.
- **Seed** = 32-bit FNV-1a over the UTF-8 bytes of `"updraft-daily-" + today`, written out in
  GDScript. It does not use `String.hash()`, so an engine update can't change everyone's day.
- **The date is fixed at the run's start.** A run that crosses midnight belongs to the day it
  began. "Fly again" re-reads the date, so after midnight it is the new day's flight.
- **For tests:** `Daily.today_override` (a static string, empty by default) replaces the clock.
  Debug builds also get a card button **[Day +1]**, which moves the override by a day.

### 4.2 What is the same for everyone that day (same app version)

- The **sequence of pieces** and their difficulty steps, since the generator is pure and seeded
  (`EndlessGenerator`).
- The **stars, arcs and big stars**, the rising wind by distance, the thermals' drift, and the
  freshening marks.

What differs is only what the pilot causes:

- which line's stars show at a two-line piece (by your height);
- where the spiral forms;
- the gull.

**Keep this true in later steps:**

- Step 3's forks must not draw from the run's RNG along the branch flown. The generator should
  choose both branches' pieces up front, or seed each tile from (seed, tile).
- Step 4's movers, houses and the kitten must take their timing from the tile's seed, not from
  `randi()`.
- A test (§6) guards this.

### 4.3 How it's reached

1. **Title [DAILY]** (unlocked only). When today's reward is still unpaid, a gold pill sits on
   its top-right corner: **"+120"** (today's reward). When paid, there is no pill.
2. **The Endless card:** while today's reward is unpaid, a third big button
   **[Daily +120]** joins the top row: [Fly again] [Daily +120] [Course] (3 × 340 + 28; fits).
   Once paid, it goes away. The daily is one tap away for exactly as long as it pays.
3. **The daily run's own card:** [Fly again] flies **today's** flight again; [Endless] goes to a
   normal run. The bottom row is as on any card.

Retry is in place (`next_seed` = today's seed) behind the usual fade. The look-back plays once a
session, as now. A daily run sets `last_mode` to Endless, so PLAY then opens normal Endless.

### 4.4 What it says and pays

- **The start hint** (2.5 s): **"Today's flight: the same country for everyone today"**. While
  unpaid, it is followed by **"Reach 100 m for 120 stars"** (2 s). Both use the word "stars";
  the hint has no drawn star.
- **The HUD:** distance shows as usual, with a small "Daily" tag under the stars count.
- **At 100 m (first time today):**
  - a gold pop-up **"Today's stars! +120"**;
  - the style_perfect sparkle and a gust swell (`swell(3, 1.0)`).
  - The reward is added to the run's banking and paid with it at the run's end, or on leaving
    for the title, in **one save** together with `daily_paid` = the run's date. If the game is
    killed mid-run nothing is paid, nothing is marked, and the player can try again.
- **The bunting** marks **today's daily best**, with "Past today's best!", not the all-time best.
  The all-time best still updates from daily runs, so they count for everything else too.
- **The card:**

```
Touchdown
212 m                         (gold "Today's best!" when beaten)
Stars  64   (bank 1,388)
Today's stars  +120           (or "Reach 100 m for 120 stars", or "Paid today")
Today's best  212 m
Best  520 m
[ Fly again ]   [ Endless ]
```

### 4.5 Rules

- **Unlimited attempts.** Every run banks its stars as normal. The reward pays **once per
  date**, on the first daily run that reaches 100 m.
- **Reward = 100 + 20 × steps**, so 100, 120, … 200. Steps (0-5) are the streak, kept gently:
  - Paying on the day after the last paid day: steps + 1 (max 5).
  - Paying after missed days: steps − (days missed), floored at 0. One missed day costs one
    step, not the whole streak. Children have weekends.
  - The pill and the hint show the reward that would pay today.
- **The clock:**
  - A date at or before `daily_paid` never pays.
  - A clock moved forward pays as a new day. That is accepted (endless-plan decision 8):
    single-player, and no money involved.
  - Day gaps are worked out as whole days between the two date strings, each read as UTC
    midnight with `Time.get_unix_time_from_datetime_string`.
- **Today's best** resets when `daily_date` isn't today.

---

## 5. Info and the title

### 5.1 The title caption

- Unchanged for Endless: "Endless  ·  best 812 m  ·  340 stars".
- Once unlocked, the Course caption gains the bank too: "The Course  ·  best 2340  ·  340 stars".
  The bank is what the Hangar spends, so it should be on show whichever mode PLAY opens.

### 5.2 HowToFly.TEXT: edits and one new section

The new section goes after "Points and bonuses", so the rail has 10 sections. 10 × 56 + 64 =
624, which fits 720. If the lead finds it tight, use 52-tall rail buttons (584).

**Objectives → Endless:** replace the last sentence with:

> Every star you catch is kept in your bank, to spend in the Hangar on new looks.

**Objectives → Choosing a mode:** append:

> Once Endless is open, DAILY on the title flies today's flight, and HANGAR spends your stars.

**Controls:** replace "The red balloon and the paper plane fly exactly the same. Swap between
them on the end card." with:

> The balloon and the paper plane fly exactly the same, whatever they wear. Swap between them on the end card or in the Hangar.

**Points and bonuses → Endless → Your bank:** append:

> Spend it in the Hangar.

**New section:**

```
# Hangar and daily flight

## The Hangar

Spend the stars in your bank on new looks: colours and patterns for the balloon, papers and designs for the plane, and trails that stream out behind you, longer the faster you go. Open it with HANGAR on the title or Hangar on the end card. It opens once Endless does.

Tap anything to try it on. Buy it if you like it, then Wear it. Wearing a balloon look flies the balloon, and a paper look flies the plane. A trail goes with both.

Looks never change how you fly. Stars are only ever earned by flying: nothing in Updraft costs money.

## The daily flight

DAILY on the title flies today's flight: the same country, pieces and stars for everyone on the same day. Fly it as often as you like. Its bunting marks your best today.

The first time each day you reach 100 m, you earn bonus stars: 100, and 20 more for each day in a row you have done it, up to 200. Miss a day and the bonus drops back a step.
```

**Tips:** add:

> Fly the daily flight a few times: it is the same all day, so you can learn its line.

---

## 6. Tests the build should add

**Save (`tests/test_progress.gd`, extending what's there):**

1. **Today's file shape**, `{"unlocked":true,"stars":1204,"best_m":520,"best_score":4750,"last_mode":"endless"}`,
   loads with all five kept and the new fields at their defaults. A save then a load round-trips.
2. **Fuzz** 500 random corrupt files: wrong types, negative or huge or fractional stars, `owned`
   as a string or a dict or 10,000 entries, `wear` naming unowned or unknown or wrong-slot ids,
   bad dates (`2026-13-40`, `"x"`, numbers), steps of 6 or -1, over size. No crash, no negative
   stars, `wear` always valid, `owned` ≤ 64 and well-formed.
3. **Unknown well-formed owned ids survive** a load-save cycle. Malformed ones don't.
4. **Backup:** with a corrupt main file and a good `.bak`, the `.bak`'s bank loads. With both
   bad, defaults. A save leaves the previous good file as `.bak`.
5. **Unreadable:** `buy` and `wear` refuse and change nothing.

**Buying:**

6. Exact price. `buy` with stars = price leaves 0 and owns the item; price + 1 short refuses.
   Buying an owned item refuses. A starter can't be bought. An unknown id refuses.
7. A failed save (read-only path) spends nothing and owns nothing.
8. Prices come only from the catalogue: a save with `"price"` fields is ignored. Every item has
   a unique id, a known slot, a price > 0 (starters 0), and a name in the font (the title's
   character test).

**Looks:**

9. Every item builds its mesh, texture or trail headless without errors.
   - Pattern balloons have ≤ 900 triangles, textures are the sizes above, and trails have ≤ 48
     particles.
   - The balloon's collision radius and the flight model are untouched by any look: a Course
     route flown with every look logs byte-identical positions.
10. Pop scraps take the worn balloon's colour. The crumpled ball takes the paper's colour.

**Daily:**

11. The same date gives an identical piece sequence twice, and identical star positions for
    the first 20 pieces. The next date differs. The FNV seed for `2026-10-14` equals a constant
    written in the test, which guards against hash drift.
12. Reward and steps:
    - Days 1-7 in a row pay 100, 120, 140, 160, 180, 200, 200.
    - A gap of one missed day after steps 5 pays 180.
    - A gap of 10 pays 100.
    - Same date twice pays once.
    - An earlier date pays nothing.
13. **A run that reaches 100 m** pays at its end, in the same save as its stars. One that
    doesn't, pays nothing. Leaving for the title after 100 m pays. A run started at 23:59:59
    (override) pays to the day it began.
14. **Daily best** resets on a new date. The bunting uses it in a daily run and the all-time best
    otherwise.
15. **Guard for steps 3-4:** a daily seed flown by two pilots taking different lines produces
    the same piece ids for 30 pieces.

**Screens (`tests/test_title.gd`, a new `tests/test_hangar.gd`):**

16. Locked: the title has no DAILY or HANGAR, and the cards have no Hangar button. Unlocked: all
    are present, with focus neighbours wired.
17. Back:
    - the confirm row goes back to the item;
    - the Hangar goes back to the title or card with focus on the opener;
    - Back on the card still goes to the title.
18. The DAILY pill and the card's [Daily +120] show only when unpaid.
19. The card's "Enough for X" line shows only when the bank crosses the cheapest unowned price.
20. **Layout:** at 1,844 × 720 and 1,280 × 1,066 the Hangar has no overlapping controls and every
    card is at least 200 logical. Extend `tools/title_shots.gd` to save Hangar shots at both
    sizes for the fun review.

**Economy sim (pure, offline):**

21. With §0's human figures and the daily rule:
    - a 16-★ first-timer can buy their first item on day 1 with the daily, and by run 4 without;
    - the casual profile owns everything in 15-25 play days.

---

## 7. Hooks for later steps (don't build now)

- **Tabs** come from a list. Step 6 adds **Power-ups** (level pips ●●○○○ and "14 s → (star)
  900"). Step 7 adds **Missions**. Step 8 adds **Countries** ([Start here]).
- **`Progress.spend()`** is the one way down. Second wind uses it from the card.
- The save's `v` and the larger `MAX_BYTES` leave room for `levels` and `missions`.
- **The preview** can show a power-up's icon in step 6.
- The **daily flight stays seed-pure** (§4.2). Step 4's kitten and movers must be seeded per
  tile.
- Step 7's mission "Fly the daily flight" reads `daily_paid`.

---

## 8. Phone checklist (owner, Fold5)

1. **The cover screen:**
   - Is the Hangar comfortable to scroll and tap?
   - Does the try-on preview make you want things?
   - Is the two-tap buy safe without being a nuisance?
2. **Unfold:** does the stacked layout look right on the inner screen?
3. **In flight**, for the balloon patterns (stripes, polka, smiley, starry night) and the plane
   designs (notebook, newspaper, map):
   - Can you tell them apart in flight?
   - Do the plane's designs show in a turn?
4. **Each trail:** is it pretty without hiding anything? Watch for the ribbon or confetti
   filling the view in a straight glide or a dive.
5. Does a dive's longer trail make diving feel faster?
6. **The frame rate:** 120 fps with each trail on, in the hamlet smoke and through the viaduct.
7. **The daily flight:**
   - Does the title's pill draw you in?
   - Does 100 m feel reachable but earned?
   - Is it fun to fly the same country twice in a day?
8. **After the update:** is your existing bank intact? Buy something, close the app, reopen:
   still owned and worn?

---

## 9. Later ideas (not this step)

- A **kitten-face balloon** once step 4's kitten exists (ears on top, whiskers on the camera
  side).
- **Colour your own:** pick the two colours of a pattern from the colours you own.
- A **calendar strip** in the daily card showing the week's streak.
- **Seed codes** to share a run (from endless-plan §14).
- **Badges** for firsts.
