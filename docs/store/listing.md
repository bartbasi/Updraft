# Updraft: Google Play listing

Everything to paste into Play Console for Updraft, and the answers to its App content
questions. The app will go on Play, Inc.'s organization account, which is waiting on a DUNS
number. Nothing here has been entered in Play Console yet. Character counts are checked by
`python tools/check_store.py`.

## Store listing (Grow > Store presence > Main store listing)

**App name** (30 characters at most): 7 characters

> Updraft

**Short description** (80 characters at most): 78 characters

> Tilt your phone to fly a red balloon on warm air, out of the house and beyond.

**Full description** (4,000 characters at most): 1490 characters

<!-- full description start -->
A kid lets go of a little red balloon in the bedroom, and you take it from there. Or swap it for a folded paper plane.

Tilt your phone to bank out of the door and ride a sunbeam down the long gallery. Dive the stairwell, catch warm air off the radiator and steam from the kettle, swoop under the lamp over the dining table, then burst out of the kitchen window into the valley.

Outside, circle in the warm air to climb. Go from thermal to thermal over the hay field, the barn roof, the ploughed field and the bonfire smoke, or soar the wind up the ridge. A soft beep tells you when you're rising, and a sigh when you've flown out of it.

Land outside once and Endless opens: a country beyond the lake that never ends. Ride cloud streets and ridges, choose the gorge or the open down, the river or the railway, dive under the viaduct and collect stars as you go. Watch out for the kittens in the cottages and barns. They would love to catch you.

Spend your stars in the Hangar on new looks for the balloon and the plane, and come back for a new daily flight every day.

• Tilt to fly: a Course flight takes one to two and a half minutes, and Endless lasts as long as you stay up
• A balloon and a paper plane, with the same gentle physics
• No ads, no in-app purchases, no internet, no account, no tracking
• Stars are only ever earned by flying
• Adjustable tilt sensitivity, sound on or off, climb and dive can be swapped
• Free and open source (GNU GPL v3): github.com/bartbasi/Updraft
<!-- full description end -->

**Category**: Game > Casual.

**Tags** (pick up to 5 from Play's list): Flying, Relaxing, Casual, Simulation, Offline.

**Contact details**:

- Email (required, shown publicly): bartbasi@gmail.com
- Website: https://github.com/bartbasi/Updraft
- Phone: leave empty.

**Privacy policy URL**: https://bartbasi.github.io/Updraft/privacy-policy/
(published from [privacy-policy.md](privacy-policy.md) by GitHub Pages on every push to main).

**Graphics**: all in [graphics/](graphics/), made by the game's own code (see
[graphics/README.md](graphics/README.md)).

## App content (Policy > App content)

- **Privacy policy**: the URL above.
- **Ads**: No, the app contains no ads.
- **App access**: All functionality is available without special access (no login).
- **Data safety**: "Does your app collect or share any of the required user data types?" **No.**
  Encryption in transit: not applicable, nothing is sent. Account creation: none. The listing then
  shows "No data collected" and "No data shared". Send feedback, Source code and Buy me a coffee
  only hand an address to the phone's own email app or browser; the app itself sends nothing,
  so the answer stays No.
- **Content rating** (IARC questionnaire): category Game. Answer **No** to violence, fear,
  sexuality, language, controlled substances, gambling, user interaction or chat, sharing
  location, and digital purchases (stars are earned only by flying and can't be bought). A
  kitten "catching" the balloon ends the run with no harm shown. Expect **Everyone** and
  **PEGI 3**.
- **Target audience and content**: **13 and over** (13 to 15, 16 to 17, 18 and over).
  Including under 13s brings in Google's Families policy, which is strict about links that take
  a child out of the app to a payment page, such as the Buy me a coffee button.
- **Government app, financial features, health, news**: No.

## Known risk: the Buy me a coffee button

Google Play's payments policy only allows in-app donation links to tax-exempt charities outside
the US. In the US a court order currently allows outside payment links, reportedly until
November 2027. Review could flag the button. Play, Inc. chose to ship it for everyone anyway
(decision of 17 October 2026). If review rejects it, the button is in `scripts/links.gd`,
`scripts/title_screen.gd` and `scripts/about_panel.gd`.

## Countries

Production > Countries/regions: add all, or just the ones you want.
