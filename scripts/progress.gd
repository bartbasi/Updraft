# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Progress
extends RefCounted
## What the player has done beyond a single flight, saved on the device as a tiny JSON file:
## whether Endless is unlocked, the bank of stars, the best Endless distance and score, and which
## mode was flown last (the app opens in it). Like BestScore, anything missing, unreadable,
## oversized, of the wrong type or out of range loads as its default instead of crashing.

const PATH := "user://progress.json"
const MAX_BYTES := 4096
const COURSE := "course"
const ENDLESS := "endless"
const MAX_STARS := 100_000_000
const MAX_METRES := 1_000_000
const MAX_SCORE := 100_000_000
## A Course best this high can only come from flying outdoors. Players who had one before Endless
## existed find it already unlocked: checked once, the first time there is no progress file.
const UNLOCK_BEST := 1500
const DEFAULTS := {"unlocked": false, "stars": 0, "best_m": 0, "best_score": 0, "last_mode": COURSE}

## Where the game keeps its progress (the test runner points this at a scratch file).
static var file_path := PATH
## Endless was unlocked this session (kept even if saving it failed, until the game closes).
static var unlocked_this_session := false
## The file is there but couldn't be opened (locked, or no permission) at the last load. Saving is
## refused then, so a run's stars can't overwrite a bank that is only unreadable for now. (A file
## that opens but is corrupt loads as the defaults and is written over, as BestScore's is.)
static var unreadable := false


## Every field, each checked and any missing or bad one replaced by its default. With no file at
## all (a first launch of this version), it starts one, unlocked if the saved Course best is
## UNLOCK_BEST or more.
static func load_all(path := "") -> Dictionary:
	if path == "":
		path = file_path
	if not FileAccess.file_exists(path):
		unreadable = false
		var fresh := DEFAULTS.duplicate()
		fresh["unlocked"] = BestScore.load_best() >= UNLOCK_BEST
		if not save_all(fresh, path):
			push_warning("Could not start the progress file.")
		fresh["unlocked"] = fresh["unlocked"] or unlocked_this_session
		return fresh
	var raw := {}
	var file := FileAccess.open(path, FileAccess.READ)
	unreadable = file == null
	if unreadable:
		push_warning("Could not open %s (%s); keeping it as it is." % [path, error_string(FileAccess.get_open_error())])
	if file != null:
		if file.get_length() <= MAX_BYTES:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				raw = json.data
		file.close()
	var out := clean(raw)
	out["unlocked"] = out["unlocked"] or unlocked_this_session
	return out


## A copy of `raw` with only known fields, each valid.
static func clean(raw: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate()
	if typeof(raw.get("unlocked")) == TYPE_BOOL:
		out["unlocked"] = raw["unlocked"]
	out["stars"] = _whole(raw.get("stars"), MAX_STARS)
	out["best_m"] = _whole(raw.get("best_m"), MAX_METRES)
	out["best_score"] = _whole(raw.get("best_score"), MAX_SCORE)
	var mode: Variant = raw.get("last_mode")
	if typeof(mode) == TYPE_STRING and (mode == COURSE or mode == ENDLESS):
		out["last_mode"] = mode
	return out


## A whole number from 0 to `most`, or 0 for anything else.
static func _whole(value: Variant, most: int) -> int:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return 0
	var number := float(value)
	if not is_finite(number) or number < 0.0 or number > most or number != floorf(number):
		return 0
	return int(number)


## Writes to a temporary file first, so a crash mid-save can't leave a half-written file.
static func save_all(progress: Dictionary, path := "") -> bool:
	if path == "":
		path = file_path
	if unreadable and FileAccess.file_exists(path):
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var text := JSON.stringify(clean(progress))
	file.store_string(text)
	file.close()
	if FileAccess.get_file_as_string(temp) != text:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK


## Unlocks Endless and saves it. Returns false if it wasn't already unlocked (this is news).
static func unlock() -> bool:
	var progress := load_all()
	if progress["unlocked"]:
		return false
	unlocked_this_session = true
	progress["unlocked"] = true
	if not save_all(progress):
		push_warning("Could not save that Endless is unlocked; it stays open until the game closes.")
	return true


## Remembers which mode was flown last (COURSE or ENDLESS), so the app opens in it.
static func note_mode(mode: String) -> void:
	var progress := load_all()
	if progress["last_mode"] == mode:
		return
	progress["last_mode"] = mode
	if not save_all(progress):
		push_warning("Could not save which mode was flown last.")
