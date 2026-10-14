# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Scoring in the real game: each course moment's path and corridor, a whole scored run,
## and restarting many times in a row.

const MAIN := preload("res://scenes/main.tscn")
const ZONES := ["Sunbeam", "Skylight", "StairDowndraft", "RadiatorHeat", "KettleSteam", "HayHeat", "BarnHeat", "FieldHeat", "BonfireSmoke", "RidgeLift",
	"ChalkHeat", "SandHeat", "BluffLift", "LakeSink"]


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


## "Perfect!" is earned, not routine: a pass that averages a fifth of the corridor's radius off
## the path is perfect; one that averages two fifths off still pays most of the points, but is
## not (fun review 2, item 3).
func test_perfect_means_really_close() -> void:
	var t := Tuning.new()
	for def in Course.style_moment_defs():
		var id := String(def["id"])
		var radius: float = t.style_moments[id]["radius"]
		var close := _only(def)
		_fly_path(close, def["path"], radius * 0.2)
		var near := _only(def)
		_fly_path(near, def["path"], radius * 0.4)
		var close_q: float = close.moments[0].quality
		var near_q: float = near.moments[0].quality
		check(close_q >= t.style_perfect_quality, "%s: a fifth of the radius off is perfect (quality %.2f)" % [id, close_q])
		check(near_q < t.style_perfect_quality and near_q > 0.8, "%s: two fifths off pays well but is not perfect (quality %.2f)" % [id, near_q])


func test_every_moment_is_tuned() -> void:
	var t := Tuning.new()
	for def in Course.style_moment_defs():
		check(t.style_moments.has(String(def["id"])), "%s has points and a radius in Tuning" % def["id"])
	check(Course.style_moment_defs().size() == 10, "the eight moments from the brief, the ridge run and the Gap")


func test_a_whole_run_scores_distance_and_style_and_distance_never_drops() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))  # so this run is a new best
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := MAIN.instantiate()
	add_node(game)
	var plane := game.get_node("Plane") as Flyer
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
	check(game.close_calls <= 1, "a clean line has (almost) no close calls: %d" % game.close_calls)
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
		var plane := game.get_node("Plane") as Flyer
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
	var plane := game.get_node("Plane") as Flyer
	plane.tuning = Tuning.new()
	plane.tuning.wind_quiet = 0.0
	plane.tuning.wind_quiet_speed = 100.0
	plane.tuning.wind_loud_speed = 100.0
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
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
		var plane := game.get_node("Plane") as Flyer
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
	var plane := game.get_node("Plane") as Flyer
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
			gallery.append(game._wind_db)  # from airspeed alone, not counting any swell
			gallery_pitch.append(wind.pitch_scale)
		if Course.section_at(p) == "stair hall":
			dive_db = maxf(dive_db, game._wind_db)
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
	var plane := game.get_node("Plane") as Flyer
	var camera := game.get_node("Camera") as FollowCamera
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
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


## Close calls: rushing along a wall close to it, then getting clear without touching it, gives
## a whoosh and a swell of wind, but only once clear; the same pass slower, or further from the
## wall, gives nothing; and flying into the wall (head-on, or glancing off it) is never a close
## call, even though the plane was close and fast on the way in.
func test_close_calls_whoosh_only_for_near_misses() -> void:
	var gap := 0.8
	# [distance from the wall, speed, angle toward the wall (degrees), peel away after, expect]
	for setup in [[gap, 8.5, 0.0, true, true], [gap, 6.0, 0.0, true, false], [2.0, 8.5, 0.0, true, false],
			[3.0, 8.5, 90.0, false, false], [1.5, 8.5, 25.0, false, false]]:
		var game := MAIN.instantiate()
		add_node(game)
		var plane := game.get_node("Plane") as Flyer
		plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
		var north := Course.GALLERY_Z.y  # the gallery's north wall (inner face), at +z
		var a := deg_to_rad(float(setup[2]))
		var dir := Vector3(-cos(a), 0.0, sin(a))  # west along the wall, turned toward it by the angle
		plane.launch(Vector3(55.0, 21.5, north - Flyer.RADIUS - float(setup[0])), atan2(-dir.x, -dir.z))
		var waited := 0
		while plane.held and waited < 600:
			await tree.process_frame
			waited += 1
		plane.model.velocity = dir * float(setup[1])
		var label := "%.1f u/s, %.1f from the wall, %.0f deg toward it" % [setup[1], setup[0], setup[2]]
		await physics_frames(12)
		if setup[3]:
			check(game.close_calls == 0, "%s: nothing yet while still close" % label)
			plane.model.velocity = Vector3(-0.8, 0.0, -0.6) * float(setup[1])  # peel away from the wall
			await physics_frames(20)
		else:
			# Fly on until well clear of the wall (or crashed), so a touched pass has had every
			# chance to sound wrongly as the plane gets away.
			var frames := 0
			while frames < 240 and not plane.is_ended() and (frames < 48 or plane.global_position.z > north - Flyer.RADIUS - plane.tuning.close_call_distance - 0.3):
				await tree.physics_frame
				frames += 1
			check(plane.model.crashed or plane.global_position.z <= north - Flyer.RADIUS - plane.tuning.close_call_distance, "%s: the plane crashes or gets clear of the wall" % label)
		var whoosh: AudioStreamPlayer = game._whoosh
		if setup[4]:
			check(plane.touches == 0, "%s: the plane never touches the wall" % label)
			check(game.close_calls == 1, "%s: a close call once clear (%d)" % [label, game.close_calls])
			check(whoosh.playing and game._swell_db > 0.0, "%s: with a whoosh and a swell of wind" % label)
			# Even with a big swell on a fast dive, the wind never gets louder than its ceiling.
			game.swell(30.0, 1.0)
			await tree.process_frame
			var wind: AudioStreamPlayer = game._wind
			check(wind.volume_db <= plane.tuning.wind_max_db + 0.001, "the wind stays under its ceiling (%.1f dB)" % wind.volume_db)
		else:
			if float(setup[2]) > 0.0:
				check(plane.touches > 0, "%s: the plane hits the wall (%s)" % [label, "crashed" if plane.model.crashed else "glanced off"])
			check(game.close_calls == 0 and not whoosh.playing, "%s: no close call (%d)" % [label, game.close_calls])
		await cleanup()


## Two clean close passes within the cooldown give one close call, not two.
func test_close_calls_have_a_cooldown() -> void:
	var game := MAIN.instantiate()
	add_node(game)
	var plane := game.get_node("Plane") as Flyer
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	var north := Course.GALLERY_Z.y
	var range_edge := north - Flyer.RADIUS - plane.tuning.close_call_distance  # closer than this is "near"
	plane.launch(Vector3(60.0, 21.5, north - Flyer.RADIUS - 0.8), PI / 2.0)
	var waited := 0
	while plane.held and waited < 600:
		await tree.process_frame
		waited += 1
	var speed := 8.5
	var came_back := false
	# Pass 1: along the wall, then away; pass 2: back in close, along, and away again.
	for leg in [[Vector3(-1.0, 0.0, 0.0), 10], [Vector3(-0.8, 0.0, -0.6), 12], [Vector3(-0.8, 0.0, 0.6), 12], [Vector3(-1.0, 0.0, 0.0), 6], [Vector3(-0.8, 0.0, -0.6), 14]]:
		plane.model.velocity = (leg[0] as Vector3) * speed
		for i in int(leg[1]):
			await tree.physics_frame
			if leg[1] == 6 and plane.global_position.z > range_edge:
				came_back = true
	check(plane.touches == 0, "neither pass touches the wall")
	check(came_back, "the second pass comes close to the wall again")
	check(plane.flight_time < plane.tuning.close_call_cooldown + 3.0, "both passes within a short time")
	check(game.close_calls == 1, "one close call for the two passes (%d)" % game.close_calls)
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
		var plane := game.get_node("Plane") as Flyer
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


## Outdoors: time in the air pays, up to a cap, and coming to rest on a landing spot pays a
## bonus once.
func test_airtime_pays_up_to_its_cap_and_landing_spots_pay_once() -> void:
	var t := Tuning.new()
	var s := Scoring.new(t, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -1)]), [])
	for i in 60 * 30:
		s.add_airtime(1.0 / 60.0)
	check(s.airtime_points() == roundi(30.0 * t.airtime_points_per_second), "30 s in the air pays %d (%d)" % [roundi(30.0 * t.airtime_points_per_second), s.airtime_points()])
	for i in 60 * 120:
		s.add_airtime(1.0 / 60.0)
	check(s.airtime_points() == roundi(t.airtime_max_seconds * t.airtime_points_per_second), "but no more than the cap (%d)" % s.airtime_points())
	var spots := Course.landing_spots()
	s.land(Vector3(-5.0, 2.0, -180.0), spots)
	check(s.landing_points == int(t.landing_bonus["lavender"]) and s.landing["id"] == "lavender", "resting in the lavender pays its bonus")
	s.land(Vector3(-72.0, 25.0, -205.0), spots)
	check(s.landing["id"] == "lavender", "and only once")
	var p := Scoring.new(t, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -1)]), [])
	p.land(Vector3((Course.PICNIC_X.x + Course.PICNIC_X.y) * 0.5, 25.0, Course.PICNIC_Z.y - 1.5), spots)
	check(p.landing_points == int(t.landing_bonus["picnic"]), "sliding just off the blanket still counts for the picnic")
	var none := Scoring.new(t, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -1)]), [])
	none.land(Vector3(20.0, 2.0, -140.0), spots)
	check(none.landing.is_empty() and none.landing_points == 0, "plain grass pays no bonus")


## In the game: gliding down onto the lavender ends the run with its bonus on the card; a crash
## there pays none.
func test_landing_in_the_lavender_shows_on_the_card_and_a_crash_pays_nothing() -> void:
	for crash in [false, true]:
		var game: Node = add_node(MAIN.instantiate())
		var plane := game.get_node("Plane") as Flyer
		plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
		await physics_frames(2)
		var y := Course.ground_height(-5.0, -168.0)
		plane.launch(Vector3(-5.0, y + 1.2, -168.0), 0.0)
		if crash:  # crumpled just above the lavender (the ground's slopes there are too gentle to crash on)
			await physics_frames(20)
			plane.model.crashed = true
			plane.crashed.emit()
		var frames := 0
		while not plane.is_ended() and frames < 60 * 20:
			await tree.physics_frame
			frames += 1
		await tree.create_timer(1.0).timeout
		var label := "crash" if crash else "landing"
		check(plane.model.crashed == crash, "%s: it %s" % [label, "crashes" if crash else "lands"])
		if crash:
			check(game.scoring.landing_points == 0, "a crash in the lavender pays no landing bonus")
		else:
			check(Course.in_lavender(plane.global_position), "came to rest in the lavender (%s)" % plane.global_position)
			check(game.scoring.landing_points == int(plane.tuning.landing_bonus["lavender"]), "the lavender bonus is paid")
			check(game._card_title.text == "Lavender landing!" and game._card_lines.text.contains("Lavender landing  +200"), "the card says so: %s / %s" % [game._card_title.text, game._card_lines.text])
			check(game._card_lines.text.contains("Airtime"), "and shows the airtime")
		await cleanup()


## Fun review 3, item 2: the first time outdoors that the plane flies into rising air low down,
## a hint says to keep circling; flying back into the same air a lap later chimes quieter.
func test_low_in_the_first_outdoor_thermal_a_hint_says_keep_circling() -> void:
	var game: Node = add_node(MAIN.instantiate())
	var plane := game.get_node("Plane") as Flyer
	var turning := [false]  # once past the middle of the field, it keeps circling
	plane.autopilot = func(p: Flyer) -> Vector2:
		turning[0] = turning[0] or p.global_position.z < -114.0
		return Vector2(0.0, -0.6) if turning[0] else Vector2.ZERO
	await physics_frames(2)
	plane.launch(Vector3(3.6, 7.0, Course.FAR_Z - 1.5), 0.0)
	var volumes := []
	var chime := game._chime as AudioStreamPlayer
	plane.entered_thermal.connect(func(z: Thermal) -> void:
		if z.name == "HayHeat":
			volumes.append(chime.volume_db), CONNECT_DEFERRED)
	var frames := 0
	while frames < 60 * 25 and not plane.is_ended():
		await tree.physics_frame
		frames += 1
		if frames == 60 * 5:
			check(game.circle_hint_shown and game._hint.text == "Keep circling to climb" and game._hint.modulate.a > 0.5, "the hint shows on entering the hay field's warm air low")
	check(volumes.size() >= 2, "the plane flies back into the warm air on its laps (%d entries)" % volumes.size())
	if volumes.size() >= 2:
		check(is_equal_approx(volumes[0], plane.tuning.chime_volume_db), "the first chime is full (%.1f dB)" % volumes[0])
		check(is_equal_approx(volumes[1], plane.tuning.chime_volume_db + plane.tuning.chime_repeat_db), "a lap later it is quieter (%.1f dB)" % volumes[1])
	check(game._hint.modulate.a < 0.05, "and the hint has faded")


## ...but not for a plane already high in the warm air, nor on the ridge (which you fly along,
## not round).
func test_no_circling_hint_high_up_or_on_the_ridge() -> void:
	for start in [Vector3(0.0, 19.5, -112.0), Vector3(-37.0, 12.0, -150.0)]:
		var game: Node = add_node(MAIN.instantiate())
		var plane := game.get_node("Plane") as Flyer
		plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
		await physics_frames(2)
		plane.launch(start, 0.0)
		var entered := []
		plane.entered_thermal.connect(func(z: Thermal) -> void: entered.append(String(z.name)))
		await physics_frames(60 * 4)
		check(not entered.is_empty(), "from %s the plane flies into rising air (%s)" % [start, entered])
		check(not game.circle_hint_shown, "from %s: no circling hint" % start)
		await cleanup()


## Past the Gap: resting on the island or the beach pays their bonuses; airtime now caps at 90 s.
func test_the_island_and_the_beach_pay_and_airtime_caps_at_ninety_seconds() -> void:
	var t := Tuning.new()
	var spots := Course.landing_spots()
	for spot in [["island", Vector3(Course.ISLAND.x, 0.3, Course.ISLAND.y)], ["beach", Vector3(50.0, 0.2, -430.0)]]:
		var s := Scoring.new(t, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -1)]), [])
		s.land(spot[1], spots)
		check(s.landing.get("id", "") == spot[0] and s.landing_points == int(t.landing_bonus[spot[0]]), "resting on the %s pays %d (%d)" % [spot[0], int(t.landing_bonus[spot[0]]), s.landing_points])
	var a := Scoring.new(t, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -1)]), [])
	for i in 60 * 150:
		a.add_airtime(1.0 / 60.0)
	check(a.airtime_points() == 450, "airtime pays at most 450 (%d)" % a.airtime_points())
	check(Course.on_water(Vector3(20.0, -1.15, -420.0)) and not Course.on_water(Vector3(Course.ISLAND.x, 0.2, Course.ISLAND.y)) and not Course.on_water(Vector3(50.0, 0.2, -430.0)), "the lake is water; the island and the beach are not")


## In the game: coming down in the lake is a "Splashdown!" with no bonus (and not a crash: the
## airtime counts); coming to rest elsewhere past the crest is "Through the Gap!".
func test_splashdown_and_through_the_gap_on_the_card() -> void:
	for case in [["Splashdown!", Vector3(20.0, 0.2, -420.0)], ["Through the Gap!", Vector3(-20.0, 0.0, -470.0)]]:
		var game: Node = add_node(MAIN.instantiate())
		var plane := game.get_node("Plane") as Flyer
		plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
		await physics_frames(2)
		var at: Vector3 = case[1]
		plane.launch(Vector3(at.x, Course.terrain_height(at.x, at.z) + 1.0, at.z), 0.0)
		var frames := 0
		while not plane.is_ended() and frames < 60 * 20:
			await tree.physics_frame
			frames += 1
		await tree.create_timer(1.0).timeout
		check(not plane.model.crashed, "%s: not a crash" % case[0])
		check(game._card_title.text == case[0], "the card says %s (%s at %s)" % [case[0], game._card_title.text, plane.global_position])
		check(game.scoring.landing_points == 0, "%s: no landing bonus" % case[0])
		check(game.scoring.airtime > 0.0, "%s: the airtime counts" % case[0])
		await cleanup()


## The first time over the saddle: a gust, a whoosh and the view widening a moment, once.
func test_crossing_the_gap_gusts_and_widens_the_view() -> void:
	var game: Node = add_node(MAIN.instantiate())
	var plane := game.get_node("Plane") as Flyer
	var camera := game.get_node("Camera") as FollowCamera
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	await physics_frames(2)
	plane.launch(Vector3(Course.GAP_X, 22.0, Course.SADDLE.x + 12.0), 0.0)
	camera.snap()
	var widest := 0.0
	var base := camera.fov
	for f in 60 * 4:
		await tree.process_frame
		widest = maxf(widest, camera.fov - camera._base_fov)
	check(game.crossed_gap, "it crossed the Gap")
	check_between(widest, plane.tuning.camera_fov_gap_kick - 0.6, plane.tuning.camera_fov_gap_kick + 0.01, "the view's widest kick (degrees)")
	check(absf(camera.fov - camera._base_fov) < 0.01, "and it eases back (%.2f, from %.1f)" % [camera.fov - camera._base_fov, base])
	plane.launch(Vector3(Course.GAP_X, 22.0, Course.SADDLE.x + 12.0), 0.0)  # and across again
	var again := 0.0
	for f in 60 * 3:
		await tree.process_frame
		again = maxf(again, camera.fov - camera._base_fov)
	check(again < 0.01, "only the first time (%.2f)" % again)


## A pilot arriving over the Gap at 21.5 and diving down its style path in real flight earns
## "Through the Gap" without touching the ground or the Gap's walls.
func test_diving_through_the_gap_earns_its_moment() -> void:
	var game: Node = add_node(MAIN.instantiate())
	var plane := game.get_node("Plane") as Flyer
	var path: PackedVector3Array
	for def in Course.style_moment_defs():
		if def["id"] == &"gap":
			path = def["path"]
	var pilot := Autopilot.new(PackedVector3Array([Vector3(Course.GAP_X, 21.5, -300.0)]) + path + PackedVector3Array([Vector3(4.0, 8.0, -385.0)]))
	pilot.pitch_gain = 0.6
	plane.autopilot = pilot.fly
	await physics_frames(2)
	plane.launch(Vector3(Course.GAP_X, 21.5, -300.0), 0.0)
	var touches := plane.touches
	var frames := 0
	while frames < 60 * 14 and not plane.is_ended() and plane.global_position.z > -380.0:
		await tree.physics_frame
		frames += 1
	var award := 0
	var quality := 0.0
	for m in game.scoring.moments:
		if m.id == &"gap":
			award = m.award
			quality = m.quality
	print("        through the Gap: +%d (quality %.2f), y %.1f at z %.0f" % [award, quality, plane.global_position.y, plane.global_position.z])
	check(award > 0, "the dive earns the Gap moment (+%d)" % award)
	check(not plane.model.crashed and plane.touches == touches, "without touching anything")


## After a crash the end card offers a way out of the game: a Quit button that closes it.
func test_after_a_crash_the_card_offers_menu() -> void:
	var game: Node = add_node(MAIN.instantiate())
	var plane := game.get_node("Plane") as Flyer
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	await physics_frames(2)
	plane.launch(Vector3(0.0, 8.0, -130.0), 0.0)
	await physics_frames(10)
	plane.model.crashed = true
	plane.crashed.emit()
	await tree.create_timer(plane.tuning.card_delay_crash + 0.5).timeout
	check(game._card.visible, "the end card shows after the crash")
	var menu := game._menu as Button
	check(menu.is_visible_in_tree() and not menu.disabled and menu.text == "Menu", "with a Menu button")
	check(menu.pressed.is_connected(game.go_to_title), "that goes to the title")
