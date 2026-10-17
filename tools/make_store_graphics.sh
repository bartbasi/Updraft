#!/usr/bin/env bash
# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
# Makes every Play store graphic in docs/store/graphics/ from the game itself: the app icon and
# feature graphic (tools/store_graphics.gd), then eight 1920x1080 screenshots of real screens and
# flights by the test pilots, on fixed routes and seeds, with no captions. Then checks them all.
#   bash tools/make_store_graphics.sh
# Needs a desktop session (the flights are rendered in a real window). Uses scratch saves only.
# Updraft plays in landscape, so the screenshots are 16:9 landscape (Play allows up to 2:1).
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT=/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe
OUT=docs/store/graphics
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SHOT=(--path . --resolution 1920x1080)

"$GODOT" --path . --resolution 1024x500 -s res://tools/store_graphics.gd
"$GODOT" "${SHOT[@]}" -s res://tools/title_shots.gd -- --out="$TMP/title"
"$GODOT" "${SHOT[@]}" -s res://tools/capture.gd -- --out="$TMP/course" --times=9.6
"$GODOT" "${SHOT[@]}" -s res://tools/capture.gd -- --out="$TMP/ridge" --route=ridge --times=40,64
"$GODOT" "${SHOT[@]}" -s res://tools/endless_capture.gd -- --out="$TMP/farmyard" --piece=farmyard --d=0.5 --times=6
"$GODOT" "${SHOT[@]}" -s res://tools/endless_capture.gd -- --out="$TMP/viaduct" --piece=viaduct --d=0.5 --times=6
"$GODOT" "${SHOT[@]}" -s res://tools/endless_capture.gd -- --out="$TMP/fork" --piece=river_rail --d=0.5 --times=2

rm -f "$OUT"/screenshot_*
cp "$TMP/title/1920x1080_title.png" "$OUT/screenshot_1_title.png"
cp "$TMP/course/00_t009.6.png" "$OUT/screenshot_2_sunbeam.png"
cp "$TMP/ridge/00_t040.0.png" "$OUT/screenshot_3_kettle_steam_out_the_window.png"
cp "$TMP/ridge/01_t064.0.png" "$OUT/screenshot_4_valley_with_the_gull.png"
cp "$TMP/farmyard/00_t006.0.png" "$OUT/screenshot_5_farmyard_kitten.png"
cp "$TMP/viaduct/00_t006.0.png" "$OUT/screenshot_6_under_the_viaduct.png"
cp "$TMP/fork/00_t002.0.png" "$OUT/screenshot_7_river_or_railway.png"
cp "$TMP/title/1920x1080_hangar_polka.png" "$OUT/screenshot_8_hangar.png"

python tools/check_store.py
