# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Scripted test flights through Endless with a readable log, for judging it without a phone.
##   godot --headless --fixed-fps 60 --path . -s res://tools/endless_log.gd -- [options]
## Options:
##   --pilot=skilled|shaky|novice   who flies (default skilled)
##   --runs=N                       number of flights (default 1)
##   --seed=S                       first seed (default 1); each run's country and pilot use seed + run
##   --wind=W                       the tailwind (default Tuning's)
##   --max=SECONDS                  stop a flight after this long (default 600)
##   --quiet                        only each run's summary and the totals
##   --calibrate                    fly each piece alone instead (see _calibrate())
##   --piece=ID                     with --calibrate, only this piece
## Each flight logs pieces entered, lift, stars, arcs, hoops, arches, snags, bumps, the gull and
## the ending with its cause, and any stretch of more than 5 s with none of those ("dead air").

const DEAD_AIR := 5.0

var _pilot_kind := "skilled"
var _runs := 1
var _seed := 1
var _wind := -1.0
var _max := 600.0
var _quiet := false
var _calibrate_mode := false
var _piece := ""  ## --piece=ID: calibrate only this piece.
## For each arc's name: [stars taken, stars, full arcs, arcs], over every flight.
var _arc_stats := {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pilot="):
			_pilot_kind = arg.trim_prefix("--pilot=")
		elif arg.begins_with("--runs="):
			_runs = maxi(1, int(arg.trim_prefix("--runs=")))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--wind="):
			_wind = float(arg.trim_prefix("--wind="))
		elif arg.begins_with("--max="):
			_max = float(arg.trim_prefix("--max="))
		elif arg == "--quiet":
			_quiet = true
		elif arg == "--calibrate":
			_calibrate_mode = true
		elif arg.begins_with("--piece="):
			_piece = arg.trim_prefix("--piece=")
	# Test pilots' progress and settings go to their own files, never the player's.
	Progress.file_path = "user://endless_log_progress_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
	BestScore.file_path = "user://endless_log_best_score_%d.json" % OS.get_process_id()
	PlayerSettings.file_path = "user://endless_log_settings_%d.json" % OS.get_process_id()
	EndlessGame.looked_back = true  # straight into the chase camera
	if _wind >= 0.0:
		EndlessGame.debug_wind = _wind
	_run_all.call_deferred()


func _run_all() -> void:
	if _calibrate_mode:
		await _calibrate()
	else:
		var results := []
		for i in _runs:
			results.append(await fly(_seed + i, _pilot_kind, not _quiet))
		_summary(results)
	for path in [Progress.file_path, BestScore.file_path, PlayerSettings.file_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()


## One flight; returns its summary.
func fly(run_seed: int, kind: String, verbose: bool) -> Dictionary:
	var game: EndlessGame = load(EndlessGame.SCENE).instantiate()
	root.add_child(game)
	var plane := game.plane
	var pilot := Autopilot.fly_endless(game, kind, run_seed)
	if kind == "novice":  # circles at most about a lap, then flies on
		game.world.placed.connect(func(_p: EndlessWorld.Piece) -> void:
			for o in pilot.orbits:
				o["max_time"] = minf(float(o["max_time"]), 3.5))
	game.arc_closed.connect(func(arc: EndlessStars.Arc) -> void:
		var row: Array = _arc_stats.get(arc.name, [0, 0, 0, 0])
		row[0] += arc.stars.filter(func(s: EndlessStars.Star) -> bool: return s.taken).size()
		row[1] += arc.stars.size()
		row[2] += 0 if arc.broken else 1
		row[3] += 1
		if row.size() < 5:
			row.append(PackedInt32Array())
		var by_star: PackedInt32Array = row[4]
		by_star.resize(maxi(by_star.size(), arc.stars.size()))
		for i in arc.stars.size():
			by_star[i] += 1 if arc.stars[i].taken else 0
		row[4] = by_star
		_arc_stats[arc.name] = row)
	game.next_seed = run_seed
	game.start_run(false)
	var log := []
	var state := {"last": 0.0, "dead": 0.0, "gaps": []}
	game.note.connect(func(text: String) -> void:
		var t := plane.flight_time
		var gap := t - float(state["last"])
		if gap > DEAD_AIR:
			log.append("%6.1f  .. %.1f s with nothing happening" % [t, gap])
		state["dead"] = maxf(float(state["dead"]), gap)
		(state["gaps"] as Array).append(gap)
		state["last"] = t
		var p := plane.global_position
		log.append("%6.1f  %-46s  (%5.1f, %5.1f, %7.1f)  h %5.1f" % [t, text, p.x, p.y - EndlessWorld.FLOOR_Y, p.z, p.y - game.world.terrain_height(p.x, p.z)]))
	var frames := 0
	while not game._ended and plane.flight_time < _max and frames < int(_max * 60.0) + 600:
		await physics_frame
		frames += 1
	var stars_total := 0
	for arc in game.world.stars.arcs:
		stars_total += arc.stars.size()
	var gaps: Array = state["gaps"]
	gaps.sort()
	var result := {"seed": run_seed, "time": plane.flight_time, "metres": int(EndlessWorld.metres(game.furthest_z)),
		"stars": game.stars_run, "arcs": game.arcs_full, "snags": game.snags, "bumps": game.bumps,
		"ending": game.ending if game._ended else "still flying", "crashed": plane.model.crashed,
		"tiles": EndlessWorld.tile_at(game.furthest_z), "dead": state["dead"], "pieces": game.pieces_entered,
		"star_share": float(game.world.stars.taken_total) / maxf(game.world.stars.taken_total + game.world.stars.missed_total, 1.0),
		"median_gap": gaps[gaps.size() / 2] if not gaps.is_empty() else 0.0}
	if verbose:
		print("\n--- %s pilot, seed %d, wind %.1f ---" % [kind, run_seed, game.world.wind])
		for line in log:
			print(line)
	print("seed %3d  %6.1f s  %4d m  pieces %2d  stars %3d (%2.0f%% taken)  arcs %2d  snags %d  bumps %d  gaps median %.1f, longest %.1f  %s" % [
		run_seed, result["time"], result["metres"], result["pieces"], result["stars"], 100.0 * result["star_share"], result["arcs"],
		result["snags"], result["bumps"], result["median_gap"], result["dead"], result["ending"]])
	game.queue_free()
	await process_frame
	return result


func _summary(results: Array) -> void:
	print("
stars by arc:")
	var names := _arc_stats.keys()
	names.sort()
	for arc_name in names:
		var row: Array = _arc_stats[arc_name]
		print("  %-16s %3.0f%% of stars, %2d of %2d full   taken by star: %s" % [arc_name, 100.0 * row[0] / maxf(row[1], 1.0), row[2], row[3], row[4] if row.size() > 4 else []])
	if results.size() < 2:
		return
	var times := []
	var metres := []
	var shares := []
	var crashes := 0
	var past_3 := 0
	var flew_12 := 0
	for r in results:
		times.append(r["time"])
		metres.append(r["metres"])
		shares.append(r["star_share"])
		if r["crashed"]:
			crashes += 1
		if int(r["pieces"]) > 3:
			past_3 += 1
		if int(r["pieces"]) > 12 or (int(r["pieces"]) == 12 and r["ending"] == "still flying"):
			flew_12 += 1
	times.sort()
	metres.sort()
	shares.sort()
	print("\n%d runs: time median %.1f s (%.1f-%.1f), distance median %d m (%d-%d), stars taken median %.0f%% (%.0f-%.0f%%), %d crashes, %d got past 3 pieces, %d flew 12" % [
		results.size(), times[times.size() / 2], times[0], times[-1], metres[metres.size() / 2], metres[0], metres[-1],
		100.0 * shares[shares.size() / 2], 100.0 * shares[0], 100.0 * shares[-1], crashes, past_3, flew_12])


## --calibrate (docs/endless-plan.md §2.4, mark 5): the skilled pilot flies each piece on its own, at
## difficulty 0, 0.5 and 1, wind 0, 1.5 and 3, entering at the piece's need and at 26 (above the
## floor), and the log gives, for each: the height it left at (against the generator's table), the
## lowest it came over the ground, the closest it came to anything solid, its stars, and any
## touchdown, crash or snag. A piece is followed by two Cloud Streets so there is ground to fly on.
func _calibrate() -> void:
	print("piece     d    wind  in    out (table)  diff  lowest  nearest  stars   events")
	var worst := {}
	for id: StringName in EndlessPieces.ids():
		if id == &"rim" or (_piece != "" and String(id) != _piece):
			continue
		for d in [0.0, 0.5, 1.0]:
			for wind in [0.0, 1.5, 3.0]:
				for h_in in [EndlessPieces.need_in(id, d), 26.0]:
					var r: Dictionary = await _calibrate_one(id, d, wind, h_in)
					var table := EndlessPieces.out(id, d, h_in)
					var diff: float = r["out"] - table
					print("%-9s %.1f  %.1f  %4.1f  %4.1f (%4.1f)  %+5.1f  %5.1f  %6.1f  %2d/%-2d  %s" % [id, d, wind, h_in, r["out"], table, diff,
						r["lowest"], r["nearest"], r["taken"], r["stars"], r["events"]])
					var w: Dictionary = worst.get(id, {"diff": 0.0, "lowest": INF, "nearest": INF})
					if absf(diff) > absf(w["diff"]):
						w["diff"] = diff
					w["lowest"] = minf(w["lowest"], r["lowest"])
					w["nearest"] = minf(w["nearest"], r["nearest"])
					worst[id] = w
	print("\nworst by piece: out vs table, lowest over the ground, nearest to a solid")
	for id in worst:
		var w: Dictionary = worst[id]
		print("  %-9s %+5.1f  %5.1f  %5.1f" % [id, w["diff"], w["lowest"], w["nearest"]])


func _calibrate_one(id: StringName, d: float, wind: float, h_in: float) -> Dictionary:
	EndlessGame.debug_wind = wind
	var game: EndlessGame = load(EndlessGame.SCENE).instantiate()
	root.add_child(game)
	var plane := game.plane
	Autopilot.fly_endless(game, "skilled", 1)
	game.calibration = {"pieces": [id, &"street", &"street"], "d": d, "h": h_in}
	game.start_run(false)
	var events := PackedStringArray()
	game.note.connect(func(text: String) -> void:
		if text.begins_with("snag") or text.begins_with("bump") or text.begins_with("ended"):
			events.append(text.get_slice(" (", 0)))
	var end_z := EndlessWorld.tile_origin(0).z - EndlessPieces.length(id)
	var lowest := INF
	var nearest := INF
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	query.shape = ball
	query.collision_mask = Flyer.WORLD_LAYER
	var frames := 0
	while plane.global_position.z > end_z and not game._ended and frames < 60 * 90:
		await physics_frame
		frames += 1
		if plane.held:
			continue
		var at := plane.global_position
		lowest = minf(lowest, at.y - game.world.terrain_height(at.x, at.z))
		if frames % 6 == 0:  # how close is the nearest solid? (grow a ball until it touches; ground excluded by the ray check above)
			var space := plane.get_world_3d().direct_space_state
			for r in [1.0, 2.0, 3.0, 4.0]:
				ball.radius = r
				query.transform = Transform3D(Basis.IDENTITY, at)
				var hits := space.intersect_shape(query, 4)
				if not hits.is_empty() and at.y - game.world.terrain_height(at.x, at.z) > r:
					nearest = minf(nearest, r)
					break
	var taken := 0
	var total := 0
	for arc in game.world.stars.arcs:
		if arc.tile == 0 and not arc.alt:
			total += arc.stars.size()
			taken += arc.stars.filter(func(s: EndlessStars.Star) -> bool: return s.taken).size()
	var out := plane.global_position.y - EndlessWorld.FLOOR_Y
	var result := {"out": out, "lowest": lowest, "nearest": nearest, "taken": taken, "stars": total, "events": ", ".join(events)}
	game.queue_free()
	await process_frame
	EndlessGame.debug_wind = -1.0 if _wind < 0.0 else _wind
	return result
