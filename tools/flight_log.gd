extends SceneTree
## Scripted test flights with a readable log, for judging the course without a phone.
##   godot --headless --fixed-fps 60 --path . -s res://tools/flight_log.gd -- [options]
## Options:
##   --pilot=skilled|novice|handsoff   who flies (default skilled)
##   --route=lavender|chain|ridge|picnic  where a skilled pilot goes outdoors (default lavender)
##   --runs=N                          number of flights (default 1; novices vary by seed)
##   --seed=S                          first random seed (default 1)
##   --quiet                           only the summary, no per-flight timeline
## Each flight logs section changes, thermals and downdrafts, bumps, style points, close calls,
## landmarks passed outdoors, the crash or landing, and any stretch of more than 5 s with none of
## those happening ("dead air").

const MAX_SECONDS := 150.0
const DEAD_AIR := 5.0

var _pilot_kind := "skilled"
var _route := "lavender"
var _runs := 1
var _seed := 1
var _quiet := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pilot="):
			_pilot_kind = arg.trim_prefix("--pilot=")
		elif arg.begins_with("--route="):
			_route = arg.trim_prefix("--route=")
			if not _route in ["lavender", "chain", "ridge", "picnic"]:
				push_error("Unknown --route=%s (lavender, chain, ridge or picnic)" % _route)
				quit(1)
				return
		elif arg.begins_with("--runs="):
			_runs = maxi(1, int(arg.trim_prefix("--runs=")))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg == "--quiet":
			_quiet = true
	# Test pilots' scores go to their own file, never the player's best score.
	BestScore.file_path = "user://flight_log_best_score.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	_run_all.call_deferred()


func _run_all() -> void:
	var results := []
	for i in _runs:
		results.append(await _fly(_seed + i))
	_summary(results)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	quit()


func _fly(run_seed: int) -> Dictionary:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var plane: PaperPlane = game.get_node("Plane")
	var pilot: Autopilot = null
	match _pilot_kind:
		"novice":
			pilot = Autopilot.novice(Autopilot.course_line(), run_seed)
		"handsoff":
			pass
		_:
			pilot = Autopilot.touring(_route, run_seed)
	plane.autopilot = pilot.fly if pilot else func(_p: PaperPlane) -> Vector2: return Vector2.ZERO

	var log := []
	var state := {"section": "", "last_event": 0.0, "dead_air": 0.0, "max_speed": 0.0, "sections": {}}
	var note := func(text: String) -> void:
		var t := plane.flight_time
		var gap := t - float(state["last_event"])
		if gap > DEAD_AIR:
			log.append("%6.1f  .. %.1f s with nothing happening" % [t, gap])
			state["dead_air"] = maxf(float(state["dead_air"]), gap)
		state["last_event"] = t
		log.append("%6.1f  %s" % [t, text])
	plane.entered_thermal.connect(func(z: Thermal) -> void: note.call("%s %s  (y %.1f, %.1f u/s)" % ["downdraft" if z.sinks else "thermal", z.name, plane.global_position.y, plane.model.velocity.length()]))
	plane.bumped.connect(func(s: float) -> void: note.call("bump %.1f at %s" % [s, _v(plane.global_position)]))
	plane.crashed.connect(func() -> void: note.call("CRASH in %s at %s" % [Course.section_at(plane.global_position), _v(plane.global_position)]))
	game.scoring.style_awarded.connect(func(id: StringName, _title: String, points: int, quality: float) -> void: note.call("style %s +%d (quality %.2f)" % [id, points, quality]))

	var frames := 0
	while not plane.is_ended() and frames < int(MAX_SECONDS * 60.0):
		await physics_frame
		frames += 1
		if plane.held:
			continue
		var section := Course.section_at(plane.global_position)
		state["max_speed"] = maxf(float(state["max_speed"]), plane.model.velocity.length())
		if section != state["section"]:
			state["section"] = section
			(state["sections"] as Dictionary)[section] = plane.flight_time
			note.call("enter %s  (y %.1f, %.1f u/s)" % [section, plane.global_position.y, plane.model.velocity.length()])
		var p := plane.global_position
		if game.vario.on != bool(state.get("vario", false)):
			state["vario"] = game.vario.on
			note.call("vario %s  (y %.1f)" % ["on" if game.vario.on else "off", p.y])
		if game.close_calls > int(state.get("close_calls", 0)):
			state["close_calls"] = game.close_calls
			note.call("close call at %s  (%.1f u/s)" % [_v(p), plane.model.velocity.length()])
		if not state.has("lavender") and Course.in_lavender(p):
			state["lavender"] = true
			note.call("over the lavender field  (%.1f above the grass)" % [p.y - Course.terrain_height(p.x, p.z)])
		if not state.has("barn") and p.z < Course.BARN.y and Vector2(p.x, p.z).distance_to(Course.BARN) < 20.0:
			state["barn"] = true
			note.call("passes the barn  (%.1f away, %.1f above the grass)" % [Vector2(p.x, p.z).distance_to(Course.BARN), p.y - Course.terrain_height(p.x, p.z)])
		if not state.has("stream") and p.z < Course.STREAM_Z:
			state["stream"] = true
			note.call("passes over the stream  (%.1f above the grass)" % [p.y - Course.terrain_height(p.x, p.z)])
	if not game.scoring.landing.is_empty():
		note.call("comes to rest: %s" % game.scoring.landing["title"])
	if state.has("sections") and (state["sections"] as Dictionary).has("outside"):
		log.append("        outside for %.1f s, airtime %d s" % [plane.flight_time - float(state["sections"]["outside"]), game.scoring.airtime_seconds()])
	var end_gap := plane.flight_time - float(state["last_event"])
	state["dead_air"] = maxf(float(state["dead_air"]), end_gap)
	var result := {
		"seed": run_seed,
		"time": plane.flight_time,
		"crashed": plane.model.crashed,
		"where": Course.section_at(plane.global_position),
		"distance_m": game.scoring.distance_meters(),
		"style": game.scoring.style_points,
		"total": game.scoring.total(),
		"awards": {},
		"sections": state["sections"],
		"dead_air": state["dead_air"],
		"max_speed": state["max_speed"],
		"close_calls": game.close_calls,
	}
	for m in game.scoring.moments:
		(result["awards"] as Dictionary)[String(m.id)] = m.award
	if not _quiet:
		print("\n=== %s flight, seed %d ===" % [_pilot_kind, run_seed])
		for line in log:
			print(line)
		print("end: %s in %s after %.1f s | distance %.1f m | style %d | total %d" % ["CRASH" if result["crashed"] else "landed", result["where"], result["time"], result["distance_m"], result["style"], result["total"]])
	game.queue_free()
	await process_frame
	return result


func _summary(results: Array) -> void:
	print("\n=== summary: %d %s flights ===" % [results.size(), _pilot_kind])
	var crashes := {}
	var reached := {}
	var awards := {}
	var times := []
	for r in results:
		times.append(r["time"])
		if r["crashed"]:
			crashes[r["where"]] = int(crashes.get(r["where"], 0)) + 1
		for section in (r["sections"] as Dictionary):
			reached[section] = int(reached.get(section, 0)) + 1
		for id in (r["awards"] as Dictionary):
			var a: Array = awards.get(id, [])
			a.append(r["awards"][id])
			awards[id] = a
	times.sort()
	print("flight time: min %.1f  median %.1f  max %.1f s" % [times[0], times[times.size() / 2], times[-1]])
	print("reached (of %d): %s" % [results.size(), reached])
	print("crashes by section: %s" % [crashes])
	for id in awards:
		var a: Array = awards[id]
		var earned := a.filter(func(x: int) -> bool: return x > 0).size()
		var total := 0
		for x in a:
			total += x
		print("  style %-16s earned %d/%d runs, average %.0f" % [id, earned, a.size(), float(total) / a.size()])
	var dead := results.map(func(r: Dictionary) -> float: return r["dead_air"])
	print("longest dead air: %.1f s" % [dead.max()])


func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]
