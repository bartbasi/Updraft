# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Saves pictures of the title screen, Info (each section), About and the Hangar (each tab, and a
## few looks tried on), at the window size given. Uses scratch saves (Endless unlocked, 900 stars),
## never the player's own.
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
	Progress.file_path = "user://shots_progress.json"
	PlayerSettings.file_path = "user://shots_settings.json"
	Progress.save_all({"unlocked": true, "stars": 900, "owned": ["sky", "pink"], "wear": {"balloon": "sky", "paper": "plain", "trail": "none"}})
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
	title._about.go_back()
	title.show_hangar()
	var hangar := title._hangar
	for shot in [["balloon", "sky"], ["balloon", "polka"], ["balloon", "smiley"], ["balloon", "starry"], ["balloon", "candy"], ["paper", "map"], ["paper", "waves"], ["trail", "rainbowtrail"], ["trail", "confetti"], ["trail", "petals"], ["trail", "ribbon"]]:
		hangar.show_tab(shot[0])
		hangar.try_on(shot[1])
		await _frames(2)
		hangar._scroll.ensure_control_visible(hangar.cards[shot[1]])  # the card tried on, in view
		await _frames(50)
		_save(out, "%s_hangar_%s" % [tag, shot[1]])
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(dir: String, name: String) -> void:
	root.get_texture().get_image().save_png(dir.path_join(name + ".png"))
