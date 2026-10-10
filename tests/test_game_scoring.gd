extends TestCase
## Scoring in the real game: each course moment's path and corridor, a whole scored run,
## and restarting many times in a row.

const MAIN := preload("res://scenes/main.tscn")
const ZONES := ["Sunbeam", "Skylight", "StairDowndraft", "RadiatorHeat", "KettleSteam", "MeadowHeat"]


func _only(def: Dictionary) -> Scoring:
	return Scoring.new(Tuning.new(), PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -1)]), [def])


func _sideways(dir: Vector3) -> Vector3:
	var s := dir.cross(Vector3.UP)
	return (s if s.length() > 0.01 else Vector3.RIGHT).normalized()


## Flies a moment's path every 0.1 units, `offset` units to the side, with a short lead-in
## before the start and run-out past the end.
func _fly_path(s: Scoring, path: PackedVector3Array, offset: float) -> void:
	var first := (path[1] - path[0]).normalized()
	var last := (path[path.size() - 1] - path[path.size() - 2]).normalized()
	for i in range(-20, 0):
		s.update(path[0] + first * (i * 0.1) + _sideways(first) * offset)
	for i in path.size() - 1:
		var span := path[i + 1] - path[i]
		var steps := maxi(int(span.length() / 0.1), 1)
		for k in steps:
			s.update(path[i] + span * (float(k) / steps) + _sideways(span.normalized()) * offset)
	for i in range(1, 30):
		s.update(path[path.size() - 1] + last * (i * 0.1) + _sideways(last) * offset)


func test_every_course_moment_pays_full_on_its_path_less_halfway_and_nothing_outside() -> void:
	var t := Tuning.new()
	for def in Course.style_moment_defs():
		var id := String(def["id"])
		var full: int = t.style_moments[id]["points"]
		var radius: float = t.style_moments[id]["radius"]
		var on := _only(def)
		_fly_path(on, def["path"], 0.0)
		check(on.style_points == full, "%s: on the path pays %d (got %d)" % [id, full, on.style_points])
		var half := _only(def)
		_fly_path(half, def["path"], radius * 0.5)
		check(half.style_points > 0 and half.style_points < full, "%s: halfway to the edge pays less (%d of %d)" % [id, half.style_points, full])
		var out := _only(def)
		_fly_path(out, def["path"], radius * 1.2)
		check(out.style_points == 0, "%s: outside the corridor pays nothing (%d)" % [id, out.style_points])
		_fly_path(on, def["path"], 0.0)
		check(on.style_points == full, "%s: pays only once per run" % id)


func test_every_moment_is_tuned() -> void:
	var t := Tuning.new()
	for def in Course.style_moment_defs():
		check(t.style_moments.has(String(def["id"])), "%s has points and a radius in Tuning" % def["id"])
	check(Course.style_moment_defs().size() == 8, "all eight moments from the brief")


func test_a_whole_run_scores_distance_and_style_and_distance_never_drops() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))  # so this run is a new best
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := MAIN.instantiate()
	add_node(game)
	var plane := game.get_node("Plane") as PaperPlane
	check(game.best_score == 0, "no best score yet")
	plane.autopilot = pilot.fly
	var awards := []
	game.scoring.style_awarded.connect(func(id: StringName, _t: String, points: int, _q: float) -> void: awards.append([String(id), points]))
	var last := 0.0
	var dropped := false
	var frames := 0
	while not plane.is_ended() and frames < 150 * 60:
		await tree.physics_frame
		frames += 1
		var d: float = game.scoring.distance_meters()
		dropped = dropped or d < last
		last = d
	await tree.create_timer(0.6).timeout
	print("        scored run: %.1f m (%d) + style %d = %d, awards %s" % [game.scoring.distance_meters(), game.scoring.distance_points(), game.scoring.style_points, game.scoring.total(), awards])
	check(not dropped, "distance never goes backward during a flight")
	check(game.scoring.distance_meters() > 60.0, "the whole course is a long way (%.1f m)" % game.scoring.distance_meters())
	check(awards.size() >= 4, "a good pilot earns style at several moments (%d)" % awards.size())
	check(game.scoring.total() == game.scoring.distance_points() + game.scoring.style_points, "total = distance + style")
	check(game.best_score == game.scoring.total(), "the run is the new best")
	check(BestScore.load_best() == game.scoring.total(), "and it is saved")


## The downstairs moments can be flown for real, with collisions, the lamp included: a pilot
## with a firm hand on the pitch follows the course's own paths from the arch to the window.
func test_a_firm_pilot_earns_every_downstairs_moment_including_the_lamp() -> void:
	for gain in [1.2, 2.0]:
		var pilot := Autopilot.new(Autopilot.downstairs_style_line())
		pilot.pitch_gain = gain
		var game := MAIN.instantiate()
		add_node(game)
		var plane := game.get_node("Plane") as PaperPlane
		plane.autopilot = pilot.fly
		plane.launch(Course.LIVING_ROOM_ENTRY, 0.0)
		(game.get_node("Camera") as FollowCamera).snap()
		var earned := {}
		game.scoring.style_awarded.connect(func(id: StringName, _t: String, points: int, quality: float) -> void: earned[String(id)] = [points, snappedf(quality, 0.01)])
		var frames := 0
		while not plane.is_ended() and frames < 60 * 60:
			await tree.physics_frame
			frames += 1
		print("        pitch gain %.1f: %s, ended at %s" % [gain, earned, plane.global_position])
		check(not plane.model.crashed, "gain %.1f: no crash (at %s)" % [gain, plane.global_position])
		check(Course.is_outside(plane.global_position), "gain %.1f: lands outside" % gain)
		for id in ["radiator", "lamp", "kettle", "window"]:
			check(earned.has(id) and earned[id][0] >= 50, "gain %.1f: earns %s well (%s)" % [gain, id, earned.get(id)])
		await cleanup()


## The wind sound survives its quietest settings: silent at low speed and the same speed for
## quiet and loud, through a flight and its end (no -inf or NaN volume).
func test_wind_survives_its_quietest_settings() -> void:
	var game := MAIN.instantiate()
	var plane := game.get_node("Plane") as PaperPlane
	plane.tuning = Tuning.new()
	plane.tuning.wind_quiet = 0.0
	plane.tuning.wind_quiet_speed = 100.0
	plane.tuning.wind_loud_speed = 100.0
	plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2.ZERO
	add_node(game)
	var wind: AudioStreamPlayer = game._wind
	var bad := []
	var frames := 0
	var ended_frames := 0
	while ended_frames < 60 and frames < 60 * 30:
		await tree.process_frame
		frames += 1
		ended_frames += 1 if plane.is_ended() else 0
		if not (is_finite(wind.volume_db) and is_finite(wind.pitch_scale)) and bad.size() < 3:
			bad.append("frame %d: volume %s, pitch %s" % [frames, wind.volume_db, wind.pitch_scale])
	check(plane.is_ended(), "the hands-off flight ends")
	check(bad.is_empty(), "the wind's volume and pitch stay real numbers: %s" % [bad])
	await cleanup()


## The lamp is a slope, not a cliff: first-timers who commit to the dive only moderately
## (pitch gain 0.45, between the gentle 0.3 and the firm pilot) all get past it and most earn
## it; gentler ones (0.38) still get past and at least half earn it.
func test_moderate_divers_thread_the_lamp() -> void:
	for setup in [[0.45, 8], [0.38, 5]]:
		await _lamp_divers(float(setup[0]), int(setup[1]))


func _lamp_divers(gain: float, must_earn: int) -> void:
	var earned := 0
	var stuck := []
	var runs := 10
	for run_seed in range(1, runs + 1):
		var pilot := Autopilot.novice(Autopilot.downstairs_style_line(), run_seed)
		pilot.pitch_gain = gain
		var game := MAIN.instantiate()
		add_node(game)
		var plane := game.get_node("Plane") as PaperPlane
		plane.autopilot = pilot.fly
		plane.launch(Course.LIVING_ROOM_ENTRY, 0.0)
		(game.get_node("Camera") as FollowCamera).snap()
		var frames := 0
		while not plane.is_ended() and plane.global_position.z > Course.LAMP.z - 8.0 and frames < 60 * 30:
			await tree.physics_frame
			frames += 1
		var lamp: Scoring.Moment = game.scoring.moments.filter(func(m: Scoring.Moment) -> bool: return m.id == &"lamp")[0]
		earned += 1 if lamp.award > 0 else 0
		var p := plane.global_position
		if plane.is_ended() or p.z > Course.LAMP.z - 8.0:
			stuck.append("seed %d %s at %s" % [run_seed, "crashed" if plane.model.crashed else "stopped short", p])
		await cleanup()
	print("        divers at pitch gain %.2f: %d/%d earn the lamp, %d don't get past it" % [gain, earned, runs, stuck.size()])
	check(stuck.is_empty(), "gain %.2f: everyone gets past the lamp: %s" % [gain, stuck])
	check(earned >= must_earn, "gain %.2f: at least %d of %d earn the lamp (%d)" % [gain, must_earn, runs, earned])


## The stair dive's wind is much louder and higher than cruising down the gallery, as the
## designer asked (at least 6 dB louder, and clearly higher pitched).
func test_wind_swells_in_the_stair_dive() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := MAIN.instantiate()
	add_node(game)
	var plane := game.get_node("Plane") as PaperPlane
	plane.autopilot = pilot.fly
	var wind: AudioStreamPlayer = game._wind
	var gallery := []
	var gallery_pitch := []
	var dive_db := -INF
	var dive_pitch := 0.0
	var frames := 0
	while not plane.is_ended() and Course.section_at(plane.global_position) != "living room" and frames < 60 * 40:
		await tree.process_frame
		frames += 1
		var p := plane.global_position
		if p.x > 30.0 and p.x < 70.0 and p.y > 19.0:  # gliding down the gallery, between the lights
			gallery.append(wind.volume_db)
			gallery_pitch.append(wind.pitch_scale)
		if Course.section_at(p) == "stair hall":
			dive_db = maxf(dive_db, wind.volume_db)
			dive_pitch = maxf(dive_pitch, wind.pitch_scale)
	gallery.sort()
	gallery_pitch.sort()
	var cruise: float = gallery[gallery.size() / 2]
	var cruise_pitch: float = gallery_pitch[gallery_pitch.size() / 2]
	print("        wind: gallery %.1f dB (pitch %.2f), stair dive peak %.1f dB (pitch %.2f)" % [cruise, cruise_pitch, dive_db, dive_pitch])
	check(dive_db - cruise >= 6.0, "the stair dive is much louder than cruising (%.1f dB more)" % (dive_db - cruise))
	check(dive_pitch - cruise_pitch >= 0.3, "and clearly higher pitched (%.2f vs %.2f)" % [dive_pitch, cruise_pitch])
	await cleanup()


## Bursting out of the window: a gust of wind, and the view widens and stays wide outdoors.
func test_window_burst_gusts_and_widens_the_view() -> void:
	var game := MAIN.instantiate()
	add_node(game)
	var plane := game.get_node("Plane") as PaperPlane
	var camera := game.get_node("Camera") as FollowCamera
	plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2.ZERO
	plane.launch(Vector3(0.0, 7.5, Course.FAR_Z + 6.0), 0.0)
	camera.snap()
	var wind: AudioStreamPlayer = game._wind
	var tune := plane.tuning
	var before := 0.0
	var frames := 0
	while frames < 600:
		await tree.process_frame
		frames += 1
		if game.reached_outside:
			break  # the game has just seen the plane outside: measure the gust now
		before = wind.volume_db
		check(is_equal_approx(camera.fov, tune.camera_fov), "indoors the view stays at %.0f (%.1f)" % [tune.camera_fov, camera.fov])
	check(game.reached_outside, "the plane flies out of the window")
	var gust: float = wind.volume_db - before
	check(gust > tune.window_gust_db * 0.8, "a gust of wind on the way out (+%.1f dB)" % gust)
	check((game._whoosh as AudioStreamPlayer).playing, "and a whoosh")
	var waited := 0.0
	while waited < tune.camera_fov_ease + 0.3 and not plane.is_ended():
		await tree.process_frame
		waited += game.get_process_delta_time()
	check(is_equal_approx(camera.fov, tune.camera_fov_outside), "the view has widened to %.0f outdoors (%.1f)" % [tune.camera_fov_outside, camera.fov])
	for i in 30:
		await tree.process_frame
		if not is_equal_approx(camera.fov, tune.camera_fov_outside):
			check(false, "and stays wide outdoors (%.1f, %d frames later)" % [camera.fov, i + 1])
			break
	check(game._swell_db == 0.0, "and the gust has faded (%.1f dB left)" % game._swell_db)
	await cleanup()


## Every moment's pop-up, plain and perfect, sits in the middle of the screen and grows from its
## middle, whatever the length of its title.
func test_style_popups_are_centred() -> void:
	var game := MAIN.instantiate()
	add_node(game)
	await physics_frames(2)
	var popup: Label = game._popup
	var ui: Control = game._ui
	for def: Dictionary in Course.style_moment_defs():
		for quality in [0.5, 1.0]:
			game._on_style_awarded(def["id"], def["title"], 150, quality)
			await tree.process_frame
			var centre := popup.position.x + popup.size.x * 0.5
			check(absf(centre - ui.size.x * 0.5) < 1.0, "'%s' is centred (%.0f of %.0f)" % [popup.text, centre, ui.size.x])
			var biggest: float = maxf(game.plane.tuning.popup_scale, game.plane.tuning.popup_perfect_scale) * 1.1  # the pop overshoots a little
			check(popup.get_minimum_size().x * biggest <= ui.size.x, "'%s' fits on screen at full size" % popup.text)
			check(popup.pivot_offset.is_equal_approx(popup.size * 0.5), "'%s' grows from its middle" % popup.text)
	await cleanup()


func test_twenty_restarts_reset_everything() -> void:
	tree.change_scene_to_packed(MAIN)
	await tree.process_frame
	await tree.process_frame
	var baseline_nodes := -1.0
	for i in 20:
		var game: Node = tree.current_scene
		var plane := game.get_node("Plane") as PaperPlane
		var camera := game.get_node("Camera") as FollowCamera
		check(plane.global_position.distance_to(Course.START) < 0.01 and plane.held, "restart %d: plane back at the throw" % i)
		check(camera.in_intro(), "restart %d: the opening shot plays again" % i)
		check(game.scoring.total() == 0 and not plane.is_ended(), "restart %d: score reset" % i)
		var names := tree.get_nodes_in_group("thermals").map(func(n: Node) -> String: return n.name)
		names.sort()
		var expected := ZONES.duplicate()
		expected.sort()
		check(names == expected, "restart %d: one of each air zone, no leftovers %s" % [i, names])
		await physics_frames(60)
		check(not plane.held and plane.model.velocity.length() > 3.0, "restart %d: flying again" % i)
		check(game._wind.playing, "restart %d: wind sound playing" % i)
		var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		if i == 2:
			baseline_nodes = nodes
		elif i > 2:
			check(nodes <= baseline_nodes + 2.0, "restart %d: no nodes pile up (%d vs %d)" % [i, nodes, baseline_nodes])
		game._on_fly_again()
		await tree.process_frame
		await tree.process_frame
	tree.unload_current_scene()
	await tree.process_frame
