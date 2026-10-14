# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Boot
extends RefCounted
## Which flight PLAY opens, and opening it: the mode flown last, Endless (once unlocked) or the
## Course.


## The scene to open: Endless if it was flown last and is unlocked, otherwise the Course.
static func first_scene() -> String:
	return first_scene_for(Progress.load_all())


static func first_scene_for(progress: Dictionary) -> String:
	if progress["unlocked"] and progress["last_mode"] == Progress.ENDLESS:
		return EndlessGame.SCENE
	return EndlessGame.COURSE_SCENE


## Opens `scene`, or the Course if it can't be opened.
static func open(tree: SceneTree, scene: String) -> void:
	if tree.change_scene_to_file(scene) != OK and scene != EndlessGame.COURSE_SCENE:
		push_warning("Could not open %s; opening the Course." % scene)
		tree.change_scene_to_file(EndlessGame.COURSE_SCENE)
