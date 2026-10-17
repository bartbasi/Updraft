# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name PlayerSettings
extends RefCounted
## The player's choices, saved on the device as a tiny JSON file: what they fly (the balloon,
## the default, or the paper plane), tilt sensitivity, sound on or off, and whether climb and dive are
## swapped. Anything missing, unreadable, oversized or out of range falls back to the default
## for that setting instead of crashing.

const PATH := "user://settings.json"
const PLANE := "plane"
const BALLOON := "balloon"
## Tilt sensitivity is a multiplier on Tuning.sensitivity, within this range.
const SENSITIVITY_MIN := 0.5
const SENSITIVITY_MAX := 2.0
const SENSITIVITY_STEP := 0.25
const DEFAULTS := {"look": BALLOON, "sensitivity": 1.0, "sound": true, "invert_pitch": false}

## Where the game keeps its settings (the test runner points this at a scratch file).
static var file_path := PATH


## Every setting, each checked and any missing or bad one replaced by its default.
static func load_all(path := "") -> Dictionary:
	if path == "":
		path = file_path
	var raw := {}
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			if file.get_length() <= 1024:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
					raw = json.data
			file.close()
	return clean(raw)


## A copy of `raw` with only known settings, each valid.
static func clean(raw: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate()
	var look: Variant = raw.get("look")
	if typeof(look) == TYPE_STRING and (look == BALLOON or look == PLANE):
		out["look"] = look
	var sens: Variant = raw.get("sensitivity")
	if (typeof(sens) == TYPE_FLOAT or typeof(sens) == TYPE_INT) and is_finite(float(sens)):
		out["sensitivity"] = clampf(snappedf(float(sens), SENSITIVITY_STEP), SENSITIVITY_MIN, SENSITIVITY_MAX)
	for flag in ["sound", "invert_pitch"]:
		if typeof(raw.get(flag)) == TYPE_BOOL:
			out[flag] = raw[flag]
	return out


## Writes to a temporary file first, so a crash mid-save can't leave a half-written file.
static func save_all(settings: Dictionary, path := "") -> bool:
	if path == "":
		path = file_path
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var text := JSON.stringify(clean(settings))
	file.store_string(text)
	file.close()
	if FileAccess.get_file_as_string(temp) != text:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK


static func load_look(path := "") -> String:
	return load_all(path)["look"]


## Changes only the look, keeping the other settings.
static func save_look(look: String, path := "") -> bool:
	var settings := load_all(path)
	settings["look"] = look
	return save_all(settings, path)
