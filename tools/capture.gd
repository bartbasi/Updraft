extends SceneTree
## Flies the course with the autopilot in a real window and saves screenshots along the way.
##   godot --path . -s res://tools/capture.gd -- --out=<folder> [--times=0.3,5.5,...]

var _times: Array[float] = [0.3, 4.6, 5.6, 8.2, 9.6, 12.8, 15.4, 18.0, 23.0]
var _out := "user://screens"
var _game: Node
var _plane: PaperPlane
var _pilot := Autopilot.new(Autopilot.course_line())  # Held here: a Callable alone does not keep its object alive.
var _shot := 0
var _ended_at := -1.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--times="):
			_times.clear()
			for t in arg.trim_prefix("--times=").split(","):
				_times.append(float(t))
	DirAccess.make_dir_recursive_absolute(_out)
	# The test pilot's score goes to its own file, never the player's best score.
	BestScore.file_path = "user://capture_best_score.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	_game = load("res://scenes/main.tscn").instantiate()
	root.add_child(_game)
	_plane = _game.get_node("Plane")
	_plane.autopilot = _pilot.fly
	_run.call_deferred()


func _run() -> void:
	while true:
		await process_frame
		var t := _plane.flight_time
		if _shot < _times.size() and t >= _times[_shot]:
			await _save("t%05.1f" % t)
			_shot += 1
		if _plane.is_ended() and _ended_at < 0.0:
			_ended_at = Time.get_ticks_msec() / 1000.0
		if _ended_at > 0.0 and Time.get_ticks_msec() / 1000.0 - _ended_at > 2.5:
			await _save("end_card")
			break
		if t > 90.0:
			break
	print("fps at end: ", Engine.get_frames_per_second())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	_game.queue_free()
	for _i in 10:  # let the audio thread release the game's sounds before quitting
		OS.delay_msec(20)
		await process_frame
	quit()


func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out.path_join("%02d_%s.png" % [_shot, label])
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
