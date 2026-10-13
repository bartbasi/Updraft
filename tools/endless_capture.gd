# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Flies Endless with a skilled test pilot in a real window, from the look back over the bowl,
## and saves screenshots along the way (and the end card, if the run ends).
##   godot --path . -s res://tools/endless_capture.gd -- --out=<folder> [--times=0.3,1.0,...]
##     [--seed=S] [--look=plane] [--wind=W] [--max=SECONDS]

var _times: Array[float] = [0.3, 0.8, 1.6, 4.0, 12.0, 20.0, 30.0, 40.0]
var _out := "user://endless_screens"
var _seed := 1
var _look := PlayerSettings.BALLOON
var _max := 120.0
var _game: EndlessGame
var _shot := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--times="):
			_times.clear()
			for t in arg.trim_prefix("--times=").split(","):
				_times.append(float(t))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--look="):
			_look = arg.trim_prefix("--look=")
		elif arg.begins_with("--wind="):
			EndlessGame.debug_wind = float(arg.trim_prefix("--wind="))
		elif arg.begins_with("--max="):
			_max = float(arg.trim_prefix("--max="))
	DirAccess.make_dir_recursive_absolute(_out)
	# The test pilot's progress and look go to their own files, never the player's.
	Progress.file_path = "user://endless_capture_progress_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
	BestScore.file_path = "user://endless_capture_best_%d.json" % OS.get_process_id()
	PlayerSettings.file_path = "user://endless_capture_settings_%d.json" % OS.get_process_id()
	PlayerSettings.save_look(_look)
	EndlessGame.looked_back = false
	_game = load(EndlessGame.SCENE).instantiate()
	_game.next_seed = _seed
	Autopilot.fly_endless(_game, "skilled", _seed)
	root.add_child(_game)
	_run.call_deferred()


func _run() -> void:
	if _game._fps != null:
		_game._fps.visible = false  # release builds have no fps counter, so the shots shouldn't either
	var ended_at := -1.0
	while true:
		await process_frame
		var t := _game.plane.flight_time
		if _shot < _times.size() and t >= _times[_shot]:
			await _save("t%05.1f" % t)
			_shot += 1
		if _game._ended and ended_at < 0.0:
			ended_at = Time.get_ticks_msec() / 1000.0
		if ended_at > 0.0 and Time.get_ticks_msec() / 1000.0 - ended_at > 2.0:
			await _save("end_card")
			break
		if t > _max or (_shot >= _times.size() and ended_at < 0.0 and t > _times[-1] + 1.0):
			break
	print("ended: ", _game.ending, " at ", int(EndlessWorld.metres(_game.furthest_z)), " m; fps ", Engine.get_frames_per_second())
	for path in [Progress.file_path, BestScore.file_path, PlayerSettings.file_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_game.queue_free()
	for _i in 10:
		OS.delay_msec(20)
		await process_frame
	quit()


func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out.path_join("%02d_%s.png" % [_shot, label])
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
