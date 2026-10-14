# Title screen, Info and About: fun review

**SEND BACK.** These are small fixes, all tuning and layout. The title and About are good
and match the plan. Info is the problem: on the cover screen its text is too small and the
lines are too long for a brand-new player to read comfortably. Items 1 to 3 must be done.
Items 4 to 7 are quick polish and can go in the same pass.

Evidence: the screenshots in the session scratchpad `title_shots` (2316x904 cover, 2176x1421
inner), `scripts/info_panel.gd`, `scripts/title_screen.gd`, `scripts/how_to_fly.gd`, and
`FlightGame.make_theme()`.

## What works (keep)

- **The title invites play.** PLAY is the biggest thing on screen, it has the lilac focus
  ring, and it breathes (1.00 to 1.03 over 1.6 s). The painted sky, the hills, the cottage
  and the balloon riding its rising dots read as "gentle flying game" at a glance. Nothing is
  clipped on the cover screen, and the inner screen re-centres cleanly. INFO and ABOUT are
  clearly secondary.
- **Navigation is simple.** The rule is one screen up, the title is the top, and focus goes
  back to the opener (`_on_closed` calls `opener.grab_focus()`). Escape never quits. PLAY
  can't double-launch.
- **Info's structure.** The rail of eight sections works. Each section opens at its top
  (`scroll_vertical = 0`). The cut-off last line shows there is more to scroll. The style
  list as one tight block reads well (Points and bonuses shot), and the Objectives list with
  its gaps reads well too.
- **About has everything the owner asked for.** License: the GPL v3 line plus the License
  page. Repository: the Source code button plus `github.com/bartbasi/Updraft` written out.
  General info: version, author, blurb, feedback ask, and the privacy line. It fits the cover
  screen with room to spare (the bottom of the legal text is at about 715 of 781 in the shot).
  Approved as built.

## Changes (ranked)

### 1. Info body text is too small to read at arm's length on the cover screen. Raise 24 to 28.

- **Fails:** Readable.
- **Evidence:** `BODY_SIZE := 24`. On the cover screen that is 24 x 1.256 = 30 physical px.
  The cover is about 402 ppi, so 30 px is about 11.5 sp, smaller than Android's usual 14 sp
  body text. In the info shots the body text is the smallest text in the game apart from the
  version label. My plan picked 24; looking at the shots, I was wrong.
- **Fix:** `BODY_SIZE` 24 to **28** (35 px, about 13.5 sp). `SUBHEADING_SIZE` 28 to **32**.
  Section title 36 to **40**. Paragraph separation 16 to **14**. On the inner screen 28 is 48
  physical px, which is still fine.

### 2. Info lines are about 115 characters long on the cover screen. Cap the text width.

- **Fails:** Readable.
- **Evidence:** On the cover the logical canvas is 1844 wide. The right column is 1844 - 80
  (outer) - 64 (inner) - 280 (rail) - 32 (gap), about 1390 wide. At 24 px that is about 115
  characters a line. See info0 ("A kid lets the red balloon go ... along the gallery,") and
  info3. Lines that long make the eye lose its place going back to the next line. On the inner
  screen the column is about 824 wide, about 68 characters, which is fine.
- **Fix:** Limit the text column to **at most 1000 logical px wide**. The simplest way is
  `custom_minimum_size`/max width on `_text_box`, or a MarginContainer whose right margin
  grows with the extra width. Keep the column left-aligned next to the rail. Keep the Back
  button at the panel's top right. With item 1 this gives about 70 characters a line on both
  screens.

### 3. The section showing is hard to tell apart once focus leaves the rail. Make "selected" obvious.

- **Fails:** Readable (the player should always see where they are).
- **Evidence:** The rail's selected state is the theme's `pressed` fill `e8b3c4` against
  `normal` `f2c6d4`, which is a very small step. In the shots the selected button is found
  mostly by the lilac focus ring. Arrow Right to Back, or tap Back, and the ring leaves the
  rail, so the only marker left is that slight shade. In Godot 4 a toggled button under a
  hovering finger or mouse uses `hover_pressed`, which the theme doesn't set.
- **Fix:** For the rail buttons only, set `pressed` and `hover_pressed` to a stronger look:
  fill **`d9a0b6`** with a **3 px `c9b2d6` lilac border**, and set the pressed font colour to
  full ink. Leave the focus ring as it is, so focused-and-selected shows both.

### 4. Split "Course and Endless" in two. It is the longest section and buries its point.

- **Fails:** Readable / no dead air (a new player wanting "what's the difference" gets four
  screens).
- **Evidence:** Section lengths in `HowToFly.TEXT`: Course and Endless **3,328** characters
  (the plan's estimate was 2,600), Points 2,324, Updrafts 2,198, the rest under 1,700. With
  items 1 and 2 (about 70 characters a line at 28) it runs about 4 cover screens. The
  comparison the owner asked for is only the first half. The second half ("room by room",
  "place by place") is a field guide.
- **Fix:** Move "## The Course, room by room" and "## Endless, place by place" into a new
  ninth rail section **`# Places`**, placed right after Course and Endless. Change their
  sub-headings to "## The Course, room by room" and "## Endless, place by place" (unchanged
  text). Rail height for nine: 9 x 60 + 8 x 8 = 604 against 720 - 48 - 48 = 624 available.
  That fits, but to be safe use rail buttons 280 x **56** (9 x 56 + 64 = 568). Update the test
  that checks the eight headings to nine.

### 5. Wrapped list items run under their dash. Indent the list lines.

- **Fails:** Readable (minor).
- **Evidence:** In info0, "- Then come to rest ... Endless" wraps to "opens." at the left
  margin, level with the dash. The same happens in Controls ("and you lose height ...").
- **Fix:** For paragraphs starting "- ", put the label in a MarginContainer with
  **left margin 28** and keep the "- " text. That gives a hanging indent with no new glyphs.

### 6. The caption under PLAY is faint over the hills. Make it full ink.

- **Fails:** Readable (it is the only thing that says which mode PLAY opens).
- **Evidence:** In the title shots "The Course · best 2975" is at 80 % ink, font 24, and sits
  right on the lilac-to-sage hill edge. It is the lowest-contrast text on the title.
- **Fix:** Caption at **100 % ink, font 26**, with the theme's cream outline at **size 8**
  (not 6). No other change to the title.

### 7. The title shows through the Info and About panels. Make those panels opaque.

- **Fails:** Readable (minor); polish.
- **Evidence:** The panel's fill is `Color(CREAM, 0.96)`, which suits the flight's end card
  over the 3D world. Over the painted sky, the red balloon ghosts through the text in every
  info shot (around 1640,250 on the cover). On the inner About shot, "Version 0.1.0" shows at
  the bottom right, and in inner info6 it is cut in half by the panel edge, even though
  `_menu` (which holds it) is meant to be hidden under Info and About. Check that the version
  label really hides. It may be a quirk of the clipped 1421 px window, but confirm it.
- **Fix:** Give Info and About their own panel stylebox with the alpha at **1.0** (same
  colour, border and shadow). Leave the flight's end card at 0.96. Make sure the version label
  hides with the menu.

## Navigation

There is nothing confusing to send back. One note for the phone pass: "Back" sits at the top
right of Info, the far corner from a left thumb on the rail. That is fine, because the phone's
Back gesture also works there, and the button is 64 logical (80 px) tall.

## Later ideas (not for this build)

- Per-section small illustrations in the title's 2D style (already in the plan's later ideas).
  The Updrafts section would gain the most.
- A "Start here" marker on Objectives for a first-time player (needs progress state, so it's
  a system and not tuning).

---

## Re-check after the fixes (2026-10-14)

**APPROVE.** I checked all seven changes in the new shots (cover 2316x904 and inner 2176x1421:
title, info0 to info8, about).

1. Body text at 28 now reads at arm's length. On the cover it is about 35 px, close to
   Android's normal body size. Sub-headings at 32 and the title at 40 are clearly above it.
2. Lines on the cover are now about 70 characters (info0 and info3), down from about 115.
   They are easy to follow.
3. The section showing (`d9a0b6` with the lilac rim) stands out from the rest of the rail at
   a glance, with or without focus.
4. "Places" is a sensible ninth stop. "Course and Endless" is now a short comparison. Nine
   rail buttons fit the cover with room to spare.
5. List items hang under their dash (Controls, Objectives).
6. The PLAY caption is now clearly readable over the hill edge.
7. The panels are opaque. No balloon or version label shows through on either screen.

**One optional polish, not blocking:** on the cover, capping the text column leaves an empty
band about 390 logical px wide at the panel's right, and Back now sits in the middle of the
panel. If cheap, limit the Info panel to about **1440 logical wide and centre it** (rail +
32 + 1000 + scroll bar + margins), so on wide screens the panel hugs its content. The inner
screen is unaffected, because it is narrower than that.
