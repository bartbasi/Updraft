class_name PlayerSettings
extends RefCounted
## What the player flies (the paper plane or the balloon), saved on the device as a tiny JSON
## file. Anything missing, unreadable, oversized or unknown counts as the paper plane instead
## of crashing.

const PATH := "user://settings.json"
const PLANE := "plane"
const BALLOON := "balloon"

## Where the game keeps its settings (the test runner points this at a scratch file).
static var file_path := PATH


static func load_look(path := "") -> String:
	if path == "":
		path = file_path
	if not FileAccess.file_exists(path):
		return PLANE
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1024:
		return PLANE
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return PLANE
	var value: Variant = (json.data as Dictionary).get("look", PLANE)
	return BALLOON if typeof(value) == TYPE_STRING and value == BALLOON else PLANE


## Writes to a temporary file first, so a crash mid-save can't leave a half-written file.
static func save_look(look: String, path := "") -> bool:
	if path == "":
		path = file_path
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var text := JSON.stringify({"look": BALLOON if look == BALLOON else PLANE})
	file.store_string(text)
	file.close()
	if FileAccess.get_file_as_string(temp) != text:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK
