# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name BestScore
extends RefCounted
## The best total score, saved on the device as a tiny JSON file. Anything missing,
## unreadable, oversized or out of range counts as "no best yet" (0) instead of crashing.

const PATH := "user://best_score.json"
const MAX_SCORE := 10_000_000

## Where the game keeps its best score (the test runner points this at a scratch file).
static var file_path := PATH


static func load_best(path := "") -> int:
	if path == "":
		path = file_path
	if not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1024:
		return 0
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return 0
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return 0
	var value: Variant = (data as Dictionary).get("best", 0)
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return 0
	var number := float(value)
	if is_nan(number) or number < 0.0 or number > MAX_SCORE or number != floorf(number):
		return 0
	return int(number)


## Writes to a temporary file first, so a crash mid-save can't wipe the old best.
static func save_best(score: int, path := "") -> bool:
	if path == "":
		path = file_path
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var text := JSON.stringify({"best": clampi(score, 0, MAX_SCORE)})
	file.store_string(text)
	file.close()
	if FileAccess.get_file_as_string(temp) != text:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK
