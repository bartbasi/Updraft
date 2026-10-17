# Updraft store graphics

Every image here is made by the game's own code, with no image editor and nothing downloaded.
To make them all again (in a desktop session, since the flights render in a real window):

    bash tools/make_store_graphics.sh

That also runs `python tools/check_store.py`, which checks sizes and formats against Google
Play's rules. Updraft plays in landscape, so the screenshots are 1920x1080 (16:9; Play allows up
to 2:1).

| File | What it is | How it is made |
|---|---|---|
| `icon_512.png` | App icon, 512x512, 32-bit PNG, full square (Play rounds it) | The launcher icon's layers in `icons/`, by `tools/store_graphics.gd` |
| `feature_graphic_1024x500.png` | Feature graphic, 24-bit PNG, no alpha | The title screen's sky, balloon and name without its buttons, by `tools/store_graphics.gd` |
| `screenshot_1_title.png` | The title screen, Endless open | `tools/title_shots.gd` (scratch saves: 900 stars) |
| `screenshot_2_sunbeam.png` | The gallery's sunbeam, with its style points | `tools/capture.gd --times=9.6` |
| `screenshot_3_kettle_steam_out_the_window.png` | Out of the kitchen window on the kettle steam | `tools/capture.gd --route=ridge`, 40 s |
| `screenshot_4_valley_with_the_gull.png` | The valley, a gull and the bonfire smoke | `tools/capture.gd --route=ridge`, 64 s |
| `screenshot_5_farmyard_kitten.png` | Endless: the Farmyard's kitten in the barn | `tools/endless_capture.gd --piece=farmyard --d=0.5`, 6 s |
| `screenshot_6_under_the_viaduct.png` | Endless: diving under the viaduct for a star | `tools/endless_capture.gd --piece=viaduct --d=0.5`, 6 s |
| `screenshot_7_river_or_railway.png` | Endless: the River or the Railway | `tools/endless_capture.gd --piece=river_rail --d=0.5`, 2 s |
| `screenshot_8_hangar.png` | The Hangar, trying on polka dots | `tools/title_shots.gd` |

The flights are flown by the test pilots on fixed routes and seeds, so each run makes the same
pictures, give or take a frame. None has a caption added; any words on them are the game's own.
