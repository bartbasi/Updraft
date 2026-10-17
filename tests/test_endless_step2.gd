# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Endless step 2 (docs/endless-plan.md §10.2): the rising wind, recentring the world, the new
## pieces' snags and water, and the bunting where your best run ended.


func _endless() -> EndlessGame:
	EndlessGame.looked_back = true
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	await physics_frames(2)
	return game


func _at_piece(id: StringName, h: float, d := 0.0) -> EndlessGame:
	var game := await _endless()
	game.calibration = {"pieces": [id, &"street", &"street"], "d": d, "h": h}
	game.test_pilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	game.start_run(false)
	await physics_frames(2)
	return game


## The tailwind rises from 1.0 to 3.0 over the first 1,000 m, then 0.1 more each 100 m up to 3.5.
func test_the_wind_rises_with_distance() -> void:
	var tune := Tuning.new()
	var at := func(m: float) -> float: return EndlessGame.wind_at(tune, m)
	check(is_equal_approx(at.call(0.0), 1.0) and is_equal_approx(at.call(500.0), 2.0) and is_equal_approx(at.call(1000.0), 3.0),
		"1.0 at the start, 2.0 at 500 m, 3.0 at 1,000 m")
	check(is_equal_approx(at.call(1300.0), 3.3) and is_equal_approx(at.call(3000.0), 3.5), "then 3.3 at 1,300 m, and never past 3.5")
	var g := EndlessGenerator.new(tune, 1)
	check(is_equal_approx(g.difficulty(500.0), 0.5) and is_equal_approx(g.difficulty(1000.0), 1.0), "difficulty reaches 1 at 1,000 m")


## The game's wind follows the run's distance (the flyer is carried by it).
func test_the_flyer_is_carried_by_the_wind_for_its_distance() -> void:
	var game := await _endless()
	game.plane.held = false
	game.furthest_z = EndlessWorld.START.z - 4.0 * 600.0
	game._physics_process(1.0 / 60.0)
	check(is_equal_approx(game.world.wind, 2.2) and is_equal_approx(game.plane.air_drift.z, -2.2), "at 600 m the wind is 2.2 (%.2f)" % game.world.wind)


## Most a thermal (and its stars) or the flyer drifts with the wind in a tick.
const DRIFT := 0.1


## A 2,100 m flight (carried straight along, high over everything) crosses two recentres: the
## distance, where the flyer is in the country and where the camera is never jump, and no star
## or zone is lost (docs/endless-plan.md §11, steps 2-4).
func test_recentring_moves_everything_together() -> void:
	var game := await _endless()
	game.plane.held = false
	var step := 4.0
	var y := EndlessWorld.FLOOR_Y + 45.0
	var course_z := EndlessWorld.START.z
	var last := {}
	var jumps := PackedStringArray()
	var recentres := 0
	var steady_camera := 0.0
	var ticks := 0
	while EndlessWorld.metres(game.plane.global_position.z) < 2100.0 and not game._ended:
		course_z -= step
		var at := Vector3(0.0, y, course_z + EndlessWorld.shift)
		game.plane.global_position = at
		game.plane.model.position = at
		game.plane.model.velocity = Vector3(0.0, 0.0, -6.0)  # carried by hand at a usual speed, the same each tick
		var shift_before := EndlessWorld.shift
		await tree.physics_frame
		await tree.process_frame
		var shifted := EndlessWorld.shift != shift_before
		if shifted:
			recentres += 1
		var now := {"metres": EndlessWorld.metres(game.furthest_z), "plane": EndlessWorld.unshifted(game.plane.global_position.z),
			"camera": EndlessWorld.unshifted(game.camera.global_position.z), "stars": _stars(game), "zones": _zones(game)}
		ticks += 1
		if ticks > 30:  # (once it has settled into being carried along)
			var moved: float = now["plane"] - last["plane"]
			var cam: float = now["camera"] - last["camera"]
			if shifted:
				if absf(float(now["metres"]) - float(last["metres"]) - step / 4.0) > 0.01:
					jumps.append("distance %.2f -> %.2f" % [last["metres"], now["metres"]])
				if absf(cam - steady_camera) > 0.01:
					jumps.append("camera moved %.3f (steady %.3f)" % [cam, steady_camera])
				for key in last["stars"]:
					if (now["stars"] as Dictionary).has(key) and ((now["stars"] as Dictionary)[key] as Vector3).distance_to(last["stars"][key]) > DRIFT:
						jumps.append("star %s moved" % key)
				for key in last["zones"]:
					if not (now["zones"] as Dictionary).has(key):
						jumps.append("zone %s lost" % key)
					elif ((now["zones"] as Dictionary)[key] as Vector3).distance_to(last["zones"][key]) > DRIFT:
						jumps.append("zone %s moved" % key)
			else:
				steady_camera = cam
			if absf(moved + step) > DRIFT:
				jumps.append("flyer moved %.2f at %.0f m%s" % [moved, now["metres"], " (recentred)" if shifted else ""])
		last = now
	check(recentres == 2, "two recentres in 2,100 m (%d)" % recentres)
	check(jumps.is_empty(), "nothing jumps: %s" % jumps.slice(0, 6))
	check(not game._ended and game.world.pieces.size() >= 5, "still flying over a country that's there")


## Stars by tile and arc and index, where they are before any shift.
func _stars(game: EndlessGame) -> Dictionary:
	var out := {}
	for i in game.world.stars.arcs.size():
		var arc := game.world.stars.arcs[i]
		for j in arc.stars.size():
			var p := arc.stars[j].position()
			out["%d_%s_%d" % [arc.tile, arc.name, j]] = Vector3(p.x, p.y, EndlessWorld.unshifted(p.z))
	return out


func _zones(game: EndlessGame) -> Dictionary:
	var out := {}
	for p in game.world.pieces:
		for zone: Thermal in p.zones.values():
			var g := zone.global_position
			out[zone.name] = Vector3(g.x, g.y, EndlessWorld.unshifted(g.z))
	return out


## Washing snags (never crashes) and sends a sock down; the line itself snags without one.
func test_washing_snags_and_a_sock_flies() -> void:
	var game := await _at_piece(&"washing", 12.0)
	game.plane.held = false
	var p := game.world.pieces[0]
	var sheet: Dictionary = p.kit.snags.filter(func(s: Dictionary) -> bool: return s["sock"])[0]
	game.plane.model.velocity = Vector3(0.0, 0.0, -8.0)
	game.plane.global_position = p.origin + ((sheet["a"] as Vector3) + (sheet["b"] as Vector3)) * 0.5
	game._check_snags(0.016)
	check(game.snags == 1 and not game.plane.model.crashed and game.plane.model.velocity.length() < 8.0 * 0.8,
		"a sheet snags: speed lost, no crash (%d, %.1f u/s)" % [game.snags, game.plane.model.velocity.length()])
	check(p.node.get_children().any(func(c: Node) -> bool: return c.name.begins_with("Sock")), "and a sock flies off")
	game._check_snags(0.016)
	check(game.snags == 1, "not again at once")
	game.plane.global_position = p.origin + Vector3(0.0, 4.0, EndlessPieces.WASHING_LINES_Z[0])
	game._check_snags(0.016)
	check(game.snags == 1, "under the sheets, nothing")


## Coming down on the Mere is a splashdown, which ends the run and says where.
func test_coming_down_on_the_mere_is_a_splashdown() -> void:
	var game := await _at_piece(&"mere", 12.0)
	game.plane.held = false
	var p := game.world.pieces[0]
	var at := p.origin + Vector3(8.0, EndlessPieces.MERE_WATER + 0.2, -30.0)
	check(is_equal_approx(game.world.water_level(at.x, at.z), p.origin.y + EndlessPieces.MERE_WATER), "there is water here")
	check(game.world.water_level(p.origin.x + 40.0, at.z) == -INF, "and none on the bank")
	game.plane.global_position = at
	game.plane.last_normal = Vector3.UP
	game.plane.model.grounded = true
	game._physics_process(1.0 / 60.0)
	check(game._ended and game.ending.contains("water"), "splashdown (%s)" % game.ending)
	await tree.create_timer(game.plane.tuning.endless_card_delay_touchdown + 0.2).timeout
	check(game._card_title.text == "Splashdown on the Mere", "the card says where: %s" % game._card_title.text)


## Flying the barn's line through its doors meets nothing solid, at both ends of difficulty.
func test_the_barn_can_be_flown_through() -> void:
	var hits := PackedStringArray()
	for d in [0.0, 1.0]:
		var game := await _at_piece(&"barn", 12.0, d)
		var p := game.world.pieces[0]
		var space := game.plane.get_world_3d().direct_space_state
		var query := PhysicsShapeQueryParameters3D.new()
		var ball := SphereShape3D.new()
		ball.radius = Flyer.RADIUS + 0.3
		query.shape = ball
		query.collision_mask = Flyer.WORLD_LAYER
		var through := lerpf(4.2, 3.6, d)
		var z := EndlessPieces.BARN_Z.x + 8.0
		while z > EndlessPieces.BARN_Z.y - 8.0:
			query.transform = Transform3D(Basis.IDENTITY, p.origin + Vector3(0.0, through, z))
			if not space.intersect_shape(query, 1).is_empty():
				hits.append("d %.0f z %.0f" % [d, z])
			z -= 1.0
		game.queue_free()
		await physics_frames(1)
	check(hits.is_empty(), "the way through is clear: %s" % hits)


## The bunting hangs where the best run ended; crossing it cheers once.
func test_the_bunting_hangs_at_your_best_and_crossing_it_cheers() -> void:
	Progress.save_all({"unlocked": true, "best_m": 30})
	var game := await _endless()
	game.next_seed = 4
	game.start_run(false)
	await physics_frames(2)
	var z := EndlessWorld.START.z - 30.0 * 4.0
	var holder := game.world.piece_at(z)
	check(holder != null and holder.node.has_node("BestMarker"), "the bunting is in the piece at 30 m")
	var notes := PackedStringArray()
	game.note.connect(func(t: String) -> void: notes.append(t))
	game.plane.held = false
	game.plane.global_position = Vector3(0.0, EndlessWorld.FLOOR_Y + 40.0, z + 1.0)
	game._physics_process(1.0 / 60.0)
	check(not game.passed_best, "not yet")
	game.plane.global_position = Vector3(0.0, EndlessWorld.FLOOR_Y + 40.0, z - 1.0)
	game._physics_process(1.0 / 60.0)
	game.plane.global_position = Vector3(0.0, EndlessWorld.FLOOR_Y + 40.0, z - 3.0)
	game._physics_process(1.0 / 60.0)
	check(game.passed_best and Array(notes).filter(func(t: String) -> bool: return t.begins_with("past your best")).size() == 1, "past it, once: %s" % notes)


## In the very tick of a recentre the ground has already moved for physics too, so the flyer's
## move that tick can't miss it (code review, step 2).
func test_the_ground_is_solid_in_the_tick_of_a_recentre() -> void:
	var game := await _endless()
	game.plane.held = false
	game.plane.global_position = EndlessWorld.tile_origin(1) + Vector3(0.0, 5.0, -40.0)
	await physics_frames(2)
	game._recentre()
	var at := game.plane.global_position
	var ray := PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 40.0, Flyer.WORLD_LAYER, [game.plane.get_rid()])
	var hit := game.plane.get_world_3d().direct_space_state.intersect_ray(ray)
	var ground := game.world.terrain_height(at.x, at.z)
	check(not hit.is_empty() and absf((hit["position"] as Vector3).y - ground) < 0.2,
		"the ground is under the flyer at once (%s, expected y %.1f)" % [hit.get("position", "nothing"), ground])



## The barn's solid doorway (round edges and all) is never smaller than the drawn one, on any side,
## and its round edges are there just outside it (code review, step 2).
func test_the_barn_door_is_as_open_as_it_looks() -> void:
	for d in [0.0, 1.0]:
		var game := await _at_piece(&"barn", 12.0, d)
		var p := game.world.pieces[0]
		var door := Vector2(lerpf(8.0, 6.5, d), lerpf(8.0, 6.5, d))
		var space := game.plane.get_world_3d().direct_space_state
		for z in [EndlessPieces.BARN_Z.x - 0.25, EndlessPieces.BARN_Z.y + 0.25]:
			var solid_at := func(x: float, y: float) -> bool:  # a short ray straight through the end wall there
				var from := p.origin + Vector3(x, y, z + 1.5)
				var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, -3.0), Flyer.WORLD_LAYER)
				ray.hit_back_faces = true
				return not space.intersect_ray(ray).is_empty()
			for at in [Vector2(-door.x * 0.5 + 0.05, door.y * 0.5), Vector2(door.x * 0.5 - 0.05, door.y * 0.5), Vector2(0.0, door.y - 0.05),
					Vector2(-door.x * 0.5 + 0.05, door.y - 0.05), Vector2(door.x * 0.5 - 0.05, door.y - 0.05)]:
				check(not solid_at.call(at.x, at.y), "d %.0f: open just inside the drawn door at %s" % [d, at])
			check(solid_at.call(door.x * 0.5 + 0.9, door.y * 0.5) and solid_at.call(0.0, door.y + 0.9), "d %.0f: and solid just outside it" % d)
		game.queue_free()
		await physics_frames(1)


func _two_lines() -> EndlessStars:
	return _stars_of([
		{"name": "low", "stars": PackedVector3Array([Vector3(0, 5, -10), Vector3(0, 5, -14)]), "big": [false, false], "zone": "", "title": "", "bonus": true, "line": "low"},
		{"name": "high", "stars": PackedVector3Array([Vector3(0, 20, -10), Vector3(0, 20, -14)]), "big": [false, false], "zone": "", "title": "", "bonus": true, "line": "high"}])


func _stars_of(arcs: Array[Dictionary], h_in := INF) -> EndlessStars:
	var stars := EndlessStars.new()
	stars.tuning = Tuning.new()
	add_node(stars)
	stars.add_piece(0, arcs, Vector3.ZERO, {}, h_in)
	return stars


## Two lines: until the piece the high line's stars are alt; on the low line they're hidden (not
## taken, not broken, closing silently); on the high line the low line's dim and don't count.
func test_the_stars_show_the_line_for_your_height() -> void:
	var stars := _two_lines()
	check(stars.arcs[1].alt and not stars.arcs[0].alt, "before the piece, the high line is the alternative")
	stars.choose_line(0, false)
	check(stars.arcs[1].hidden and not stars.arcs[0].hidden, "low: the high line's stars go")
	check(stars.check(Vector3(0, 20, -10)).is_empty(), "and can't be taken")
	stars.check(Vector3(0, 5, -10))
	stars.check(Vector3(0, 30, -40))  # flown past both
	var names := stars.closed_broken.map(func(a: EndlessStars.Arc) -> String: return a.name)
	check(names == ["low"], "and they close without a word: %s" % [names])
	var bumped := _two_lines()
	bumped.choose_line(0, false)
	bumped.break_current()
	check(not bumped.arcs[1].broken, "a bump doesn't touch them")
	var high := _two_lines()
	high.choose_line(0, true)
	check(high.arcs[0].dim and high.arcs[0].alt and not high.arcs[0].hidden and not high.arcs[1].alt, "high: the low line dims and is the alternative")
	check(high.check(Vector3(0, 5, -10)).size() == 1, "its stars can still be taken")
	high.check(Vector3(0, 30, -40))
	check(high.missed_total == 2, "missing the line you're on counts, the dimmed one doesn't (%d)" % high.missed_total)


## A dive's first stars slide lower for a low entry, never higher than laid, and leave taken stars
## and the rest of the arc alone.
func test_a_dive_fits_the_height_you_come_in_at() -> void:
	var stars := _stars_of([{"name": "dive", "stars": PackedVector3Array([Vector3(0, 15, -10), Vector3(0, 12, -14), Vector3(0, 9, -18)]),
		"big": [false, false, false], "zone": "", "title": "", "bonus": true, "from_entry": 2}], 20.0)
	var ys := func() -> Array: return stars.arcs[0].stars.map(func(s: EndlessStars.Star) -> float: return s.at.y)
	check(ys.call() == [15.0, 12.0, 9.0], "laid as given for a high entry: %s" % [ys.call()])
	stars.fit_to_entry(0, 11.0)
	check(ys.call() == [10.0, 9.5, 9.0], "a low entry pulls the first two down: %s" % [ys.call()])
	stars.fit_to_entry(0, 30.0)
	check(ys.call() == [15.0, 12.0, 9.0], "never above where they were laid: %s" % [ys.call()])
	stars.arcs[0].stars[0].taken = true
	stars.fit_to_entry(0, 11.0)
	check(ys.call() == [15.0, 9.5, 9.0], "a taken star stays put: %s" % [ys.call()])
	stars.fit_to_entry(1, 5.0)
	check(ys.call() == [15.0, 9.5, 9.0], "and another tile's entry changes nothing")
	var short := _stars_of([{"name": "short", "stars": PackedVector3Array([Vector3(0, 15, -10)]), "big": [false], "zone": "", "title": "", "bonus": true, "from_entry": 3}], 5.0)
	check(short.arcs[0].stars.size() == 1, "a from_entry longer than the arc is clamped, not a crash")


## Which line a pilot is on: at or above HIGH_FROM, or too high to dive to the low opening in time.
func test_the_high_line_is_for_high_or_steep_entries() -> void:
	var kit := EndlessPieces.kit(&"barn", 0.0)
	check(kit.takes_high(Vector3(0.0, EndlessPieces.HIGH_FROM, -1.0)), "at HIGH_FROM: high")
	check(not kit.takes_high(Vector3(0.0, 12.0, -1.0)), "low: the door")
	check(not kit.takes_high(Vector3(0.0, 18.0, -1.0)), "18 at the entry: there's room to dive to the door")
	check(kit.takes_high(Vector3(0.0, 19.0, -30.0)), "19 just 16 u before it: too steep, so over the top")
	check(not EndlessPieces.kit(&"barley", 0.0).takes_high(Vector3(0.0, 30.0, -1.0)), "a piece with one line never goes high")


## A spiral isn't laid while the pilot is only crossing its thermal's middle, however it turns.
func test_a_spiral_waits_until_you_circle_out_from_the_middle() -> void:
	var zone := Thermal.new()
	zone.radius = 11.0
	zone.height = 20.0
	zone.outdoors = true
	add_node(zone)
	await physics_frames(1)
	var stars := EndlessStars.new()
	stars.tuning = Tuning.new()
	add_node(stars)
	stars.add_piece(0, [{"name": "s", "stars": PackedVector3Array([Vector3(6, 8, 0), Vector3(0, 10, 6)]), "big": [false, false], "zone": "Z",
		"title": "", "bonus": true, "spiral": {"radius": 6.0, "rise": 3.0, "step": 40.0, "top": 20.0}}] as Array[Dictionary], Vector3.ZERO, {"Z": zone})
	for deg in range(0, 180, 5):  # a tight turn right round the middle
		var a := deg_to_rad(deg)
		stars.check(Vector3(2.0 * cos(a), 5.0, 2.0 * sin(a)), Vector3(-sin(a), 0.0, cos(a)) * 7.0)
	check(not stars.arcs[0].anchored, "not laid while crossing the middle")
	for deg in range(180, 260, 5):
		var a := deg_to_rad(deg)
		stars.check(Vector3(6.0 * cos(a), 5.0, 6.0 * sin(a)), Vector3(-sin(a), 0.0, cos(a)) * 7.0)
	check(stars.arcs[0].anchored, "laid once circling further out")


## The freshening breeze is felt once at each mark, only with the rising wind, and afresh each run.
func test_the_breeze_freshens_at_its_marks() -> void:
	var game := await _endless()
	game.plane.held = false
	var notes := PackedStringArray()
	game.note.connect(func(t: String) -> void:
		if t.begins_with("the breeze freshens"):
			notes.append(t))
	game.plane.global_position = EndlessWorld.START + Vector3(0, 30, -4.0 * 260.0)
	game.furthest_z = game.plane.global_position.z
	game._physics_process(1.0 / 60.0)
	game._physics_process(1.0 / 60.0)
	check(notes.size() == 1, "once at 250 m (%d)" % notes.size())
	game.furthest_z = EndlessWorld.START.z - 4.0 * 1010.0
	game._physics_process(1.0 / 60.0)
	game._physics_process(1.0 / 60.0)
	check(notes.size() == 3, "then at 500 and 1,000 m (%d)" % notes.size())
	EndlessGame.debug_wind = 1.5
	game.start_run(false)
	game.plane.held = false
	game.furthest_z = EndlessWorld.START.z - 4.0 * 300.0
	game._physics_process(1.0 / 60.0)
	EndlessGame.debug_wind = -1.0
	check(notes.size() == 3, "not in a steady wind chosen on the card")


## Shapes are scaled from cached unit shapes rather than asked of the renderer each time (a phone
## stalled ~100 ms a piece): the triangles that have any area match the meshes' own.
func test_cached_shapes_match_the_meshes() -> void:
	var cases: Array[PrimitiveMesh] = []
	for size in [Vector3(1.0, 2.0, 3.0), Vector3(0.24, 6.5, 0.6)]:
		var b := BoxMesh.new()
		b.size = size
		cases.append(b)
	for c in [[0.4, 0.3, 4.0, 5], [2.6, 0.0, 7.0, 6], [0.0, 1.5, 2.0, 8], [1.0, 1.0, 1.5, 10]]:
		var m := CylinderMesh.new()
		m.bottom_radius = c[0]
		m.top_radius = c[1]
		m.height = c[2]
		m.radial_segments = c[3]
		m.rings = 0
		cases.append(m)
	for c in [[2.5, 5.0, 6, 3], [0.7, 1.4, 7, 5], [1.0, 3.0, 9, 5]]:
		var s := SphereMesh.new()
		s.radius = c[0]
		s.height = c[1]
		s.radial_segments = c[2]
		s.rings = c[3]
		cases.append(s)
	var solid := func(tris: PackedVector3Array) -> PackedVector3Array:
		var out := PackedVector3Array()
		for t in range(0, tris.size(), 3):
			var a := tris[t]
			var b := tris[t + 1]
			var c := tris[t + 2]
			if not (a.is_equal_approx(b) or b.is_equal_approx(c) or a.is_equal_approx(c)):
				out.append_array([a, b, c])
		return out
	for mesh in cases:
		var arrays := mesh.get_mesh_arrays()
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var all := PackedVector3Array()
		for i: int in arrays[Mesh.ARRAY_INDEX]:
			all.append(verts[i])
		var want: PackedVector3Array = solid.call(all)
		var got: PackedVector3Array = solid.call(Art.triangles(mesh))
		var same := got.size() == want.size()
		for i in mini(got.size(), want.size()):
			same = same and got[i].distance_to(want[i]) < 1e-4
		if mesh is CylinderMesh and (mesh.top_radius == 0.0 or mesh.bottom_radius == 0.0):
			check(Art.triangles(mesh).size() < all.size(), "a cone leaves out its triangles that come to nothing")
		check(same, "%s %s: %d triangles as the mesh's %d" % [mesh.get_class(), mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX].size(), got.size() / 3, want.size() / 3])
