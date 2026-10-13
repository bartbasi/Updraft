# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends Node
## Opens the game in the mode flown last: Endless (once unlocked) or the Course.


func _ready() -> void:
	_open.call_deferred(first_scene())


## The scene to open: Endless if it was flown last and is unlocked, otherwise the Course.
static func first_scene() -> String:
	var progress := Progress.load_all()
	if progress["unlocked"] and progress["last_mode"] == Progress.ENDLESS:
		return EndlessGame.SCENE
	return EndlessGame.COURSE_SCENE


func _open(scene: String) -> void:
	if get_tree().change_scene_to_file(scene) != OK and scene != EndlessGame.COURSE_SCENE:
		push_warning("Could not open %s; opening the Course." % scene)
		get_tree().change_scene_to_file(EndlessGame.COURSE_SCENE)
