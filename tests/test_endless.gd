# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Endless (docs/endless-plan.md, step 1; marks in §11): the generator's rules, the pieces, stars
## and arcs, the wind, the run's end, retrying, and a test pilot flying it.


func _endless() -> EndlessGame:
	EndlessGame.looked_back = true
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	await physics_frames(2)
	return game


# --- The generator (mark 4) -------------------------------------------------------------

## 10,000 sequences of 45 pieces from random seeds, across difficulty 0 to 1: a good pilot always
## enters a piece at least the margin above what it needs; no piece comes back too soon; never too
## many pieces without lift in a row; a rest piece often enough; every run starts Rim, Street.
func test_ten_thousand_sequences_keep_every_rule() -> void:
	var tune := Tuning.new()
	var bad := PackedStringArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var reached_full := 0
	for run in 10000:
		var g := EndlessGenerator.new(tune, rng.randi())
		var seq: Array[EndlessGenerator.Placement] = []
		for i in 45:
			seq.append(g.next())
		if seq[0].id != &"rim" or seq[1].id != &"street":
			bad.append("run %d opens %s, %s" % [run, seq[0].id, seq[1].id])
		if seq[-1].d >= 1.0:
			reached_full += 1
		for i in range(2, seq.size()):
			var p := seq[i]
			var room := p.h_in - g.margin(p.d)
			if EndlessPieces.need_in(p.id, p.d) > room + 0.001:
				bad.append("run %d piece %d %s needs %.1f, room %.1f" % [run, i, p.id, EndlessPieces.need_in(p.id, p.d), room])
			for back in range(1, EndlessGenerator.no_repeat(p.d) + 1):
				if i - back >= 2 and seq[i - back].id == p.id:
					bad.append("run %d piece %d %s again after %d" % [run, i, p.id, back])
			var without := 0
			for j in range(i, 0, -1):
				if bool(EndlessPieces.info(seq[j].id)["lift"]):
					break
				without += 1
			if without > EndlessGenerator.max_without_lift(p.d):
				bad.append("run %d: %d pieces without lift to %d" % [run, without, i])
			var since_rest := 0
			for j in range(i, -1, -1):
				if bool(EndlessPieces.info(seq[j].id)["rest"]):
					break
				since_rest += 1
			if since_rest >= EndlessGenerator.rest_every(p.d):
				bad.append("run %d: no rest piece in %d to piece %d" % [run, since_rest, i])
		if bad.size() > 20:
			break
	check(bad.is_empty(), "%d broken rules: %s" % [bad.size(), bad.slice(0, 6)])
	check(reached_full > 9000, "the sequences reach full difficulty (%d of 10000)" % reached_full)


func test_the_same_seed_gives_the_same_country() -> void:
	var tune := Tuning.new()
	var a := EndlessGenerator.new(tune, 42)
	var b := EndlessGenerator.new(tune, 42)
	var same := true
	for i in 40:
		same = same and a.next().id == b.next().id
	check(same, "a seed always makes the same sequence (for the daily flight later)")


# --- The pieces --------------------------------------------------------------------

## Every piece meets the next at the valley's standard cross-section, so joins never step.
func test_pieces_meet_on_the_standard_section() -> void:
	for id: StringName in EndlessPieces.ids():
		var length := EndlessPieces.length(id)
		for x in range(-96, 97, 6):
			var standard := EndlessPieces.standard(x)
			var out_edge := EndlessPieces.grid_height(id, x, -length + 0.001)
			check(absf(out_edge - standard) < 0.01, "%s leaves on the standard section at x %d (%.2f vs %.2f)" % [id, x, out_edge, standard])
			if id != &"rim":
				var in_edge := EndlessPieces.grid_height(id, x, -0.001)
				check(absf(in_edge - standard) < 0.01, "%s begins on it at x %d (%.2f)" % [id, x, in_edge])
	# The Rim begins where the Course's bowl ends.
	for x in [-60, -20, 0, 20, 60]:
		check(absf(EndlessPieces.grid_height(&"rim", x, -0.001) + EndlessWorld.FLOOR_Y - Course.terrain_height(x, EndlessWorld.START_Z)) < 0.6,
			"the Rim meets the bowl's far rim at x %d" % x)


## No star within 2 u of anything solid (spirals form round the pilot, away from anything), at
## every difficulty step.
func test_no_star_is_near_anything_solid() -> void:
	var bad := PackedStringArray()
	for id: StringName in EndlessPieces.ids():
		for d in [0.0, 0.25, 0.5, 0.75, 1.0]:  # every layout step a player can fly
			var kit := EndlessPieces.kit(id, d)
			var body := StaticBody3D.new()
			for shape in kit.shapes:
				var cs := CollisionShape3D.new()
				cs.shape = shape
				body.add_child(cs)
			add_node(body)
			await physics_frames(2)
			var query := PhysicsShapeQueryParameters3D.new()
			var ball := SphereShape3D.new()
			ball.radius = 2.0
			query.shape = ball
			var space := body.get_world_3d().direct_space_state
			for arc in kit.arcs:
				if arc.has("spiral"):
					continue
				for p: Vector3 in arc["stars"]:
					query.transform = Transform3D(Basis.IDENTITY, p)
					if not space.intersect_shape(query, 1).is_empty():
						bad.append("%s d %.1f %s star at %s" % [id, d, arc.get("name", ""), p])
			body.queue_free()
	check(bad.is_empty(), "stars near solids: %s" % bad.slice(0, 6))


func test_every_piece_builds_with_its_parts() -> void:
	for id: StringName in EndlessPieces.ids():
		var kit := EndlessPieces.kit(id, 0.5)
		check(kit.mesh != null and kit.mesh.get_surface_count() == 1, "%s has one mesh" % id)
		check(kit.shapes.reduce(func(n: int, sh: ConcavePolygonShape3D) -> int: return n + sh.get_faces().size(), 0) > 1000, "%s has ground to land on" % id)
		check(not kit.arcs.is_empty() and not kit.line_points.is_empty(), "%s has stars and a line" % id)
		var faces := 0
		var arrays := kit.mesh.surface_get_arrays(0)
		faces = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		check(faces < 12000, "%s stays light (%d triangles)" % [id, faces])


# --- Stars (mark 10) ---------------------------------------------------------------------

func _stars(arcs: Array[Dictionary], zones := {}) -> EndlessStars:
	var stars := EndlessStars.new()
	stars.tuning = Tuning.new()
	add_node(stars)
	stars.add_piece(0, arcs, Vector3.ZERO, zones)
	return stars


func test_a_star_is_taken_within_reach_and_not_beyond() -> void:
	var stars := _stars([{"stars": PackedVector3Array([Vector3(0, 10, -10)]), "big": [false], "zone": "", "title": "", "bonus": false}])
	check(stars.check(Vector3(0, 10, -10) + Vector3(1.5, 0, 0)).is_empty(), "not from 1.5 away")
	check(stars.check(Vector3(0, 10, -10) + Vector3(0, 1.39, 0)).size() == 1, "taken from 1.4")
	check(stars.check(Vector3(0, 10, -10)).is_empty(), "and only once")


func test_a_full_arc_pays_once_and_a_miss_breaks_it() -> void:
	var line := PackedVector3Array([Vector3(0, 10, -10), Vector3(0, 10, -16), Vector3(0, 10, -22)])
	var stars := _stars([{"name": "a", "stars": line, "big": [false, false, false], "zone": "", "title": "Full arc!", "bonus": true},
		{"name": "b", "stars": line + PackedVector3Array(), "big": [false, false, false], "zone": "", "title": "Full arc!", "bonus": true}])
	var full := 0
	for p in line:
		for pick in stars.check(p):
			full += 1 if pick.full_arc else 0
	check(full == 2, "both arcs (on the same line here) end full, each paying once (%d)" % full)
	stars.clear()
	stars.add_piece(0, [{"name": "c", "stars": PackedVector3Array([Vector3(0, 10, -10), Vector3(0, 10, -16), Vector3(0, 10, -22)]),
		"big": [false, false, false], "zone": "", "title": "Full arc!", "bonus": true}] as Array[Dictionary], Vector3.ZERO, {})
	var picks := stars.check(Vector3(0, 10, -16))  # the first one flown round
	check(picks.size() == 1 and picks[0].broke and not picks[0].full_arc, "skipping the first breaks the arc")
	check(stars.arcs[0].stars[0].missed and stars.arcs[0].broken, "the skipped star is missed")
	stars.check(Vector3(0, 10, -22))
	stars.check(Vector3(0, 10, -40))
	check(stars.arcs[0].closed and stars.missed_total == 1 and stars.taken_total == 2, "closed once flown past: 2 taken, 1 missed")


func test_flying_past_an_arc_closes_it_and_a_bump_breaks_the_one_in_progress() -> void:
	var stars := _stars([{"name": "a", "stars": PackedVector3Array([Vector3(0, 10, -10), Vector3(0, 10, -16)]), "big": [false, false], "zone": "", "title": "", "bonus": true}])
	stars.check(Vector3(0, 10, -10))
	check(stars.break_current() and stars.arcs[0].broken, "a bump breaks the arc being flown")
	check(not stars.break_current(), "and nothing else")
	var past := _stars([{"name": "b", "stars": PackedVector3Array([Vector3(5, 10, -10)]), "big": [false], "zone": "", "title": "", "bonus": true}])
	past.check(Vector3(0, 10, -10 - EndlessStars.CLOSE_PAST - 0.5))
	check(past.arcs[0].closed and past.closed_broken.size() == 1, "an arc flown past is closed and counted missed")


func test_stars_in_a_thermal_ride_its_drift_and_a_spiral_forms_round_the_pilot() -> void:
	var zone := Thermal.new()
	zone.radius = 11.0
	zone.height = 20.0
	zone.outdoors = true
	add_node(zone)
	await physics_frames(1)
	var spiral := PackedVector3Array([Vector3(6, 8, 0), Vector3(0, 10, 6), Vector3(-6, 12, 0)])
	var stars := _stars([{"name": "s", "stars": spiral, "big": [false, false, false], "zone": "Z", "title": "Full spiral!", "bonus": true,
		"spiral": {"radius": 6.0, "rise": 3.0, "step": 40.0, "top": 20.0}}], {"Z": zone})
	var before := stars.stars[0].position()
	zone.drift_offset = Vector3(0, 0, -3)
	check(stars.stars[0].position().is_equal_approx(before + Vector3(0, 0, -3)), "a star rides its thermal's drift")
	zone.drift_offset = Vector3.ZERO
	# Flying straight across its middle takes at most one star, and lays nothing.
	var taken := 0
	for i in 200:
		taken += stars.check(Vector3(0.0, 9.0, 9.0 - 0.09 * i), Vector3(0, 0, -7)).size()  # (not past its far end, which would close it)
	check(taken <= 1 and not stars.arcs[0].anchored, "a straight pass takes at most one spiral star (%d)" % taken)
	stars.check(Vector3(30, 9, 0), Vector3(0, 0, -7))  # out of the thermal again
	# Circling at 8 u round the thermal, climbing: the spiral is laid only after a real turn, then
	# just ahead, out of reach, the way the pilot turns, at its radius.
	var at := Vector3.ZERO
	var velocity := Vector3.ZERO
	for deg in range(0, 40, 5):
		var a := deg_to_rad(deg)
		at = Vector3(8.0 * cos(a), 5.0 + deg * 0.02, 8.0 * sin(a))
		velocity = Vector3(-sin(a), 0.0, cos(a)) * 7.0 + Vector3(0, 2.0, 0)  # round with the angle rising
		stars.check(at, velocity)
	check(not stars.arcs[0].anchored, "not after under 45 degrees")
	for deg in range(40, 80, 5):
		var a := deg_to_rad(deg)
		at = Vector3(8.0 * cos(a), 5.0 + deg * 0.02, 8.0 * sin(a))
		velocity = Vector3(-sin(a), 0.0, cos(a)) * 7.0 + Vector3(0, 2.0, 0)
		stars.check(at, velocity)
		if stars.arcs[0].anchored:
			break
	check(stars.arcs[0].anchored, "laid once the pilot has circled 45 degrees")
	var next: EndlessStars.Star = stars.arcs[0].stars.filter(func(s: EndlessStars.Star) -> bool: return not s.taken)[0]
	var first := next.at
	check(absf(Vector2(first.x, first.z).length() - 8.0) < 0.1 and first.y > at.y - 0.01, "at the pilot's radius, no lower (%s)" % first)
	check(first.distance_to(at) > 3.0, "out of reach, so one star never takes the next (%.1f)" % first.distance_to(at))
	check(Vector2(at.x, at.z).angle_to(Vector2(first.x, first.z)) > 0.0, "and ahead, the way the pilot turns")


# --- The wind (mark 11) ------------------------------------------------------------------

## At 1.5 u/s of wind, a hands-off glide covers about 12.2 u for each unit of height lost (9.7 still).
func test_the_tailwind_stretches_the_glide() -> void:
	EndlessGame.debug_wind = 1.5
	var game := await _endless()
	game.plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	game.plane.launch(EndlessWorld.START + Vector3(0, 30, 0), 0.0)
	game.plane.held = false
	await physics_frames(240)  # settle into the glide
	var a := game.plane.global_position
	await physics_frames(360)
	var b := game.plane.global_position
	var ratio := Vector2(b.x - a.x, b.z - a.z).length() / maxf(a.y - b.y, 0.01)
	EndlessGame.debug_wind = -1.0
	check_between(ratio, 11.9, 12.5, "glide ratio in the wind")


func test_the_wind_dies_near_the_ground_so_a_slide_stops() -> void:
	var game := await _endless()
	game.plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2(-0.2, 0.0)
	var start := EndlessWorld.tile_origin(1) + Vector3(0.0, 1.5, -40.0)
	game.plane.launch(start, 0.0)
	game.plane.held = false
	var frames := 0
	while not game.plane.model.grounded and frames < 600:
		await tree.physics_frame
		frames += 1
	check(game.plane.model.grounded and game._ended, "touching down ends the run")
	await physics_frames(180)
	var z := game.plane.global_position.z
	await physics_frames(30)
	check(absf(game.plane.global_position.z - z) < 0.05, "and within 3 s the slide has stopped: the wind doesn't push it along")


func test_without_wind_endless_thermals_never_fade() -> void:
	var zone := Thermal.new()
	zone.radius = 10.0
	zone.outdoors = true
	zone.drifts_with_wind = true
	zone.life = 1.0
	add_node(zone)
	await physics_frames(1)
	var tune := Tuning.new()
	for i in 600:
		zone.drift_with_wind(1.0 / 60.0, zone.global_position, 0.0, tune)
	check(not zone.fading() and zone.peak_speed(tune) > 0.0, "no wind: no drift, so no fading")
	for i in 600:
		zone.drift_with_wind(1.0 / 60.0, zone.global_position, 3.0, tune)
	check(zone.fading() and zone.drift_offset.z < -20.0, "in the wind it drifts and, past its life, fades")


# --- The run --------------------------------------------------------------------------

func test_a_run_banks_its_stars_and_keeps_the_best_distance() -> void:
	Progress.save_all({"unlocked": true, "stars": 100})
	var game := await _endless()
	game.stars_run = 12
	game.furthest_z = EndlessWorld.START.z - 4.0 * 50.0  # 50 m
	game._finish("Touchdown", 0.1, "test")
	var p := Progress.load_all()
	check(p["stars"] == 112 and p["best_m"] == 50 and p["best_score"] == 50 * EndlessGame.POINTS_PER_METRE + 12 * game.plane.tuning.points_per_star,
		"banked and saved: %s" % p)
	await tree.create_timer(0.3).timeout
	check(game._card.visible and game._card_note.text == "New best!", "the card says it's a new best")
	check(game._card_lines.text.contains("50 m") and game._card_lines.text.contains("bank 112"), "with the distance and the bank: %s" % game._card_lines.text)


## Retry starts over in place, quickly (mark 3: the reset itself well under 0.3 s on a PC).
func test_fly_again_starts_over_in_place_and_fast() -> void:
	var game := await _endless()
	var world := game.world
	game._on_crashed()
	await tree.create_timer(game.plane.tuning.card_delay_crash + 0.1).timeout
	check(game._card.visible, "the card is up after a crash")
	var t := Time.get_ticks_usec()
	game._on_fly_again()
	var took := (Time.get_ticks_usec() - t) / 1000.0
	check(took < 300.0, "the reset took %.0f ms" % took)
	check(game.world == world and not game._card.visible and not game._ended, "same scene, card gone, flying again")
	check(game.plane.global_position.is_equal_approx(EndlessWorld.START) and game.stars_run == 0, "from the start, with no stars")
	var frames := 0
	while game.plane.held and frames < 180:
		await tree.process_frame
		frames += 1
	check(not game.plane.held, "and let go within %d frames" % frames)


## A skilled test pilot flies the first several pieces without touching down or crashing.
func test_a_skilled_pilot_flies_on() -> void:
	var game := await _endless()
	Autopilot.fly_endless(game, "skilled", 5)
	game.next_seed = 5
	game.start_run(false)
	while not game._ended and game.pieces_entered < 6 and game.plane.flight_time < 120.0:
		await tree.physics_frame
	check(not game._ended and game.pieces_entered >= 6, "6 pieces in (%d, %s)" % [game.pieces_entered, game.ending])
	check(game.stars_run > 30, "with stars (%d)" % game.stars_run)


# --- What ships --------------------------------------------------------------------------

## Shipped code (scripts/, scenes/) never names a class or path that lives in tests/ or tools/,
## which the export leaves out: a game that did would fail to compile on the phone.
func test_shipped_code_never_needs_the_tests_or_tools() -> void:
	var outside := PackedStringArray()
	var name_line := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for dir in ["res://tests", "res://tools"]:
		for file in DirAccess.get_files_at(dir):
			if file.get_extension() == "gd":
				var m := name_line.search(FileAccess.get_file_as_string(dir.path_join(file)))
				if m:
					outside.append(m.get_string(1))
	check(outside.has("Autopilot") and outside.has("TestCase"), "found the test classes (%s)" % outside)
	var bad := PackedStringArray()
	var files := PackedStringArray()
	var dirs := ["res://scripts", "res://scenes"]
	while not dirs.is_empty():  # and every folder in them
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			dirs.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if file.get_extension() in ["gd", "tscn"]:
				files.append(dir.path_join(file))
	for path in files:
		var code := ""
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if not line.strip_edges().begins_with("#"):
				code += line.get_slice("#", 0) + "\n"  # comments don't count
		for cls in outside:
			if RegEx.create_from_string("\\b%s\\b" % cls).search(code):
				bad.append("%s names %s" % [path, cls])
		if code.contains("res://tests") or code.contains("res://tools"):
			bad.append("%s loads from tests/ or tools/" % path)
	check(bad.is_empty(), "shipped code depends on what isn't shipped: %s" % bad)


func test_the_game_opens_in_the_mode_flown_last() -> void:
	var boot: GDScript = load("res://scripts/boot.gd")
	Progress.save_all({"unlocked": true, "last_mode": Progress.ENDLESS})
	check(boot.first_scene() == EndlessGame.SCENE, "unlocked and last flown: Endless")
	Progress.save_all({"unlocked": false, "last_mode": Progress.ENDLESS})
	check(boot.first_scene() == EndlessGame.COURSE_SCENE, "not unlocked: the Course")
	Progress.save_all({"unlocked": true, "last_mode": Progress.COURSE})
	check(boot.first_scene() == EndlessGame.COURSE_SCENE, "last flown the Course: the Course")


# --- The run's events ----------------------------------------------------------------------

func test_flying_back_past_the_start_is_the_wrong_way() -> void:
	var game := await _endless()
	# Turn round hard, then fly straight back upwind.
	game.test_pilot = func(p: Flyer) -> Vector2: return Vector2(0.0, 1.0) if absf(p.model.heading) < 2.9 else Vector2.ZERO
	game.start_run(false)
	game.plane.global_position += Vector3(0.0, 12.0, 0.0)  # high above the crest, room to turn
	var frames := 0
	while not game._ended and frames < 60 * 30:
		await tree.physics_frame
		frames += 1
	check(game._ended and game.ending == "flew back past the start", "turning back ends the run (%s)" % game.ending)


func _at_piece(id: StringName, h: float) -> EndlessGame:
	var game := await _endless()
	game.calibration = {"pieces": [id, &"street", &"street"], "d": 0.0, "h": h}
	game.test_pilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	game.start_run(false)
	await physics_frames(2)
	return game


func test_kite_rings_snag_and_never_crash_and_ring_when_threaded() -> void:
	var game := await _at_piece(&"kites", 20.0)
	var p := game.world.pieces[0]
	var hoop: Dictionary = p.kit.hoops[0]
	var centre: Vector3 = p.origin + hoop["centre"]
	var axis: Vector3 = hoop["axis"]
	var side := axis.cross(Vector3.UP).normalized()
	var notes := PackedStringArray()
	game.note.connect(func(t: String) -> void: notes.append(t))
	game.plane.model.velocity = axis * 8.0
	game.plane.global_position = centre + side * float(hoop["radius"]) + axis * 0.1  # on the ring itself
	game._check_hoops(0.016)
	check(game.snags == 1 and not game.plane.model.crashed and game.plane.model.velocity.length() < 8.0 * 0.8,
		"touching a ring snags: speed lost, no crash (%d snags, %.1f u/s)" % [game.snags, game.plane.model.velocity.length()])
	game.plane.global_position = centre - axis * 1.0  # just before the middle...
	game._check_hoops(0.016)
	game.plane.global_position = centre + axis * 1.0  # ...and just through it
	game._check_hoops(0.016)
	check(notes.has("through hoop 1"), "threading a ring rings it: %s" % notes)


func test_an_arch_pass_is_felt_only_through_an_opening() -> void:
	var game := await _at_piece(&"viaduct", 20.0)
	var p := game.world.pieces[0]
	var z: float = p.origin.z + EndlessPieces.VIADUCT_Z
	var notes := PackedStringArray()
	game.note.connect(func(t: String) -> void: notes.append(t))
	game.plane.model.velocity = Vector3(0, 0, -9.0)
	game.plane.global_position = Vector3(0.0, p.origin.y + 7.0, z + 0.5)
	game._check_arches()
	game.plane.global_position = Vector3(0.0, p.origin.y + 7.0, z - 0.5)
	game._check_arches()
	check(notes.size() == 1 and notes[0].begins_with("through the arch"), "through the middle arch: %s" % notes)
	game.plane.global_position = Vector3(6.25, p.origin.y + 7.0, z + 0.5)
	game._check_arches()
	game.plane.global_position = Vector3(6.25, p.origin.y + 7.0, z - 0.5)  # where a pier stands
	game._check_arches()
	check(notes.size() == 1, "crossing where a pier stands is no pass: %s" % notes)


## Twenty retries in place leave nothing behind: nodes, thermals and the sounds' counts stay put.
func test_twenty_retries_leave_nothing_behind() -> void:
	var game := await _endless()
	Autopilot.fly_endless(game, "skilled", 2)
	var counts := []
	for i in 20:
		game.next_seed = 2
		game.start_run(false)
		for _f in 90:
			await tree.physics_frame
		game.close_calls += 3  # as if the run had had some
		game._on_crashed()
		await tree.process_frame
		await tree.process_frame
		counts.append([_count(game), tree.get_nodes_in_group("thermals").size()])
	check(counts[19] == counts[2], "the same nodes and thermals after 20 retries as after 3: %s vs %s" % [counts[19], counts[2]])
	game.start_run(false)
	check(game.close_calls == 0 and game.vario_beeps == 0 and game.sighs == 0, "a retry starts the sounds' counts afresh")


func _count(node: Node) -> int:
	var n := 1
	for c in node.get_children():
		n += _count(c)
	return n


# --- Kits off the main thread ---------------------------------------------------------------

func test_kits_build_in_the_background_and_pieces_wait_for_them() -> void:
	EndlessPieces.clear_kits()
	check(EndlessPieces.kit_when_ready(&"viaduct", 0.75) == null and EndlessPieces.building(), "a kit not built yet is queued, and isn't ready at once")
	var frames := 0
	var kit: EndlessPieces.Kit = null
	while kit == null and frames < 300:
		await tree.process_frame
		frames += 1
		EndlessPieces.pump(3000)
		kit = EndlessPieces.kit_when_ready(&"viaduct", 0.75)
	check(kit != null and kit.mesh != null and kit.shapes.size() > 1, "then it's ready (after %d frames)" % frames)
	check(EndlessPieces.kit(&"viaduct", 0.75) == kit, "and kept")
	# A run whose kits aren't built: its first pieces are built at once, the rest as they come.
	EndlessPieces.clear_kits()
	var game := await _endless()
	check(game.world.pieces.filter(func(q: EndlessWorld.Piece) -> bool: return q.spawned).size() >= 5, "the first pieces are there")
	Autopilot.fly_endless(game, "skilled", 3)
	game.next_seed = 3
	game.start_run(false)
	while game.pieces_entered < 4 and not game._ended and game.plane.flight_time < 80.0:
		await tree.physics_frame
	check(game.pieces_entered >= 4 and not game._ended, "flying on, each piece there when needed (%d, %s)" % [game.pieces_entered, game.ending])


## Grazing a slope nudges you off like a bump; coming down on flat ground is a touchdown.
func test_a_graze_of_a_slope_is_a_bump_and_flat_ground_ends_the_run() -> void:
	var game := await _at_piece(&"ridge", 20.0)
	game.plane.held = false  # (let go, as the game does once it draws smoothly)
	var bumps := game.bumps
	game.plane.last_normal = Vector3(0.6, 0.77, 0.0).normalized()  # the ridge face, about 40 degrees
	game.plane.model.grounded = true
	game._physics_process(1.0 / 60.0)
	check(not game._ended and game.bumps == bumps + 1 and not game.plane.model.grounded, "a graze: a bump, and flying on")
	game.plane.last_normal = Vector3.UP
	game.plane.model.grounded = true
	game._physics_process(1.0 / 60.0)
	check(game._ended and game.ending.begins_with("ran out of height"), "flat ground: touchdown (%s)" % game.ending)
	await tree.create_timer(game.plane.tuning.endless_card_delay_touchdown + 0.2).timeout
	check(game._card_title.text == "Touchdown on the Long Ridge", "the card says where: %s" % game._card_title.text)
