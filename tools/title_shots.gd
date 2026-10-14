# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Saves pictures of the title screen, Info (each section) and About, at the window size given.
## godot --path . --resolution 2316x904 -s res://tools/title_shots.gd -- --out=C:/somewhere


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://shots"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var tag := "%dx%d" % [root.size.x, root.size.y]
	var title: TitleScreen = load(TitleScreen.SCENE).instantiate()
	title.opens_scenes = false
	root.add_child(title)
	await _frames(30)
	_save(out, "%s_title" % tag)
	title.show_info()
	for i in title._info.rail.size():
		title._info.rail[i].grab_focus()
		await _frames(12)
		_save(out, "%s_info%d" % [tag, i])
	title._info.go_back()
	title.show_about()
	await _frames(6)
	_save(out, "%s_about" % tag)
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(dir: String, name: String) -> void:
	root.get_texture().get_image().save_png(dir.path_join(name + ".png"))
