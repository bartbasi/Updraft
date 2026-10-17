# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Endless step 3 (docs/forks-plan.md): the forks (when they come, their ground and openings, the
## road you're on and its stars), the Warm Down, the daily flight staying the same whatever road
## is flown, and the two follow-ups from fun review 6 (the choice point).

const FORKS: Array[StringName] = [EndlessForks.GORGE_DOWN, EndlessForks.RIVER_RAIL]


## In thousands of countries: no fork too early, one every FORK_GAP placements while fair, F2
## always followed by the Viaduct (and the Viaduct fair after it), and never the same fork twice
## running while the other was fair.
func test_forks_come_as_planned() -> void:
	var bad := PackedStringArray()
	var late := 0
	var gaps := 0
	var twice := 0
	for run in 2000:
		var gen := EndlessGenerator.new(Tuning.new(), run * 7 + 3)
		var seq: Array[EndlessGenerator.Placement] = []
		for i in 60:
			seq.append(gen.next())
		var last_fork := -1
		for i in seq.size():
			var p := seq[i]
			var info := EndlessPieces.info(p.id)
			if not bool(info.get("fork", false)):
				continue
			var metres := p.tile * EndlessGenerator.TILE_METRES
			if metres < float(info["min_m"]):
				bad.append("run %d: %s at %d m" % [run, p.id, metres])
			if info.has("follower") and i + 1 < seq.size():  # (the last placement's follower is still to come)
				if seq[i + 1].id != info["follower"]:
					bad.append("run %d: %s not followed by %s" % [run, p.id, info["follower"]])
				elif EndlessPieces.need_in(seq[i + 1].id, seq[i + 1].d) > seq[i + 1].h_in - gen.margin(seq[i + 1].d):
					bad.append("run %d: the follower unfair after %s" % [run, p.id])
			if last_fork >= 0:
				gaps += 1
				if seq[last_fork].id == p.id and p.tile * EndlessGenerator.TILE_METRES >= 400.0:
					twice += 1  # (before 400 m only F1 can come)
				var gap := i - last_fork - (2 if EndlessPieces.info(seq[last_fork].id).has("follower") else 1)
				if gap < EndlessGenerator.FORK_GAP.x:
					bad.append("run %d: forks %d apart" % [run, gap])
				if gap > EndlessGenerator.FORK_GAP.y + 3:
					late += 1
			last_fork = i
		if bad.size() > 10:
			break
	check(bad.is_empty(), "fork rules: %s" % bad.slice(0, 6))
	check(twice < gaps / 4, "the same fork twice running only when the other wasn't fair (%d of %d)" % [twice, gaps])
	check(gaps > 1000 and late <= gaps / 100, "forks come at most 3 places late in 99%% (%d of %d)" % [late, gaps])


## Each fork's table: the low road's out under the high road's by at least 4 (calibrated), and
## the need the same for both roads.
func test_the_high_road_leaves_you_higher() -> void:
	for id in FORKS:
		var info := EndlessPieces.info(id)
		var high: Vector2 = info["out_high"]
		var low: Vector2 = info["cap"]
		check(high.x - low.x >= 4.0 and high.y - low.y >= 4.0, "%s: high road out %s, low %s" % [id, high, low])


## The same seed gives the same country (ids, tiles, difficulty) for 60 placements, forks and all,
## and nothing in the country's code draws from the global random numbers (only seeded RNGs of its
## own), so the daily flight is the same whatever road is flown.
func test_the_country_is_pure() -> void:
	for seed_value in [Daily.seed_for("2026-10-15"), 12345]:
		var a := EndlessGenerator.new(Tuning.new(), seed_value)
		var b := EndlessGenerator.new(Tuning.new(), seed_value)
		var same := true
		for i in 60:
			var p := a.next()
			var q := b.next()
			same = same and p.id == q.id and p.tile == q.tile and p.d == q.d
		check(same, "seed %d: the same 60 placements" % seed_value)
	var global := RegEx.create_from_string("(?<![.\\w])(randi|randf|randi_range|randf_range|randomize)\\(")
	for path in ["res://scripts/endless/generator.gd", "res://scripts/endless/pieces.gd", "res://scripts/endless/forks.gd", "res://scripts/endless/endless_world.gd", "res://scripts/endless/stars.gd"]:
		var hits := global.search_all(FileAccess.get_file_as_string(path))
		check(hits.is_empty(), "%s uses no global random numbers (%d)" % [path.get_file(), hits.size()])


## Forks and the Warm Down meet the standard section at both ends, and nobody can leave the valley
## or cross a fork's spine.
func test_the_new_ground_joins_and_holds() -> void:
	for id: StringName in FORKS + [&"warm_down"]:
		var worst := 0.0
		for x in range(-96, 97, 6):
			for z in [0.0, -EndlessPieces.length(id)]:
				worst = maxf(worst, absf(EndlessPieces.ground(id, x, z) - EndlessPieces.standard(x)))
		check(worst < 0.01, "%s meets the standard section (%.3f)" % [id, worst])
	for id in FORKS:
		var low_spine := INF
		var low_wall := INF
		for z in range(-100, -197, -4):
			low_spine = minf(low_spine, EndlessPieces.ground(id, 0.0, z))
		for z in range(0, -289, -6):
			for x in [-90.0, 90.0, -96.0, 96.0]:
				low_wall = minf(low_wall, EndlessPieces.ground(id, x, z))
		check(low_spine >= 36.0, "%s: the spine can't be crossed (lowest %.1f)" % [id, low_spine])
		check(low_wall >= 30.0, "%s: nor the valley's walls (lowest %.1f)" % [id, low_wall])
	var edge := 0.0
	for x in range(-30, 31, 6):
		for z in [-2.0, -20.0, -28.0, -184.0, -190.0]:
			edge = maxf(edge, EndlessPieces.ground(&"warm_down", x, z))
	check(edge <= 6.0, "the Warm Down rises only inside (%.1f near its ends)" % edge)


## The bridges' openings, at the easiest and hardest layouts, as the kits register them: the
## footbridges' undersides over the gorge floor and the humpbacks' crowns over the water.
func test_the_bridges_leave_room() -> void:
	for d in [0.0, 1.0]:
		var gorge := EndlessPieces.kit(EndlessForks.GORGE_DOWN, d)
		check(gorge.arches.size() == 3, "the gorge's three bridges are openings")
		for a in gorge.arches:
			var o: Dictionary = a["openings"][0]
			var under := float(o["springing"]) + float(o["half_span"])  # the deck's underside
			var floor_y := EndlessPieces.ground(EndlessForks.GORGE_DOWN, float(o["x"]), float(a["z"]))
			check(under - floor_y >= lerpf(5.5, 4.5, d), "d %.0f: footbridge at %.0f, %.1f over the floor" % [d, a["z"], under - floor_y])
		var river := EndlessPieces.kit(EndlessForks.RIVER_RAIL, d)
		check(river.arches.size() == 3, "and the river's three")
		var space := PhysicsServer3D.space_create()
		for a in river.arches:
			var o: Dictionary = a["openings"][0]
			# the solid's lowest point over the river's middle, under the bridge (a ray up from the water)
			var faces := PackedVector3Array()
			for shape in river.shapes:
				faces.append_array(shape.get_faces())
			var lowest := INF
			for t in range(0, faces.size(), 3):
				var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3(float(o["x"]), -0.9, float(a["z"])), Vector3.UP, faces[t], faces[t + 1], faces[t + 2])
				if hit != null:
					lowest = minf(lowest, (hit as Vector3).y)
			check(lowest + 1.0 >= lerpf(6.5, 4.75, d), "d %.0f: humpback at %.0f, %.1f from the water to the crown" % [d, a["z"], lowest + 1.0])
		PhysicsServer3D.free_rid(space)


## The river is water only on its cut, along the low road: a splashdown there, nowhere else.
func test_the_river_is_water_only_on_its_cut() -> void:
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	game.calibration = {"pieces": [EndlessForks.RIVER_RAIL, &"street", &"street"], "d": 0.5, "h": 18.0}
	game.start_run(false)
	await physics_frames(2)
	var p: EndlessWorld.Piece = game.world.pieces[0]
	var at := func(x: float, z: float) -> float: return game.world.water_level(x, p.origin.z + z)
	var mid := EndlessForks.road_x(EndlessForks.RIVER_RAIL, "low", -140.0)
	check(is_equal_approx(at.call(mid, -140.0), p.origin.y - 1.0) and is_equal_approx(at.call(mid + 3.5, -140.0), p.origin.y - 1.0), "on the river: water at -1")
	check(at.call(mid + 5.0, -140.0) == -INF and at.call(mid - 5.0, -140.0) == -INF, "a step off it: none")
	check(at.call(EndlessForks.road_x(EndlessForks.RIVER_RAIL, "low", -210.0), -210.0) == -INF and at.call(EndlessForks.road_x(EndlessForks.RIVER_RAIL, "low", -70.0), -70.0) == -INF, "nor before or after its cut")
	check(at.call(-mid, -140.0) == -INF, "nor on the railway")
	game.queue_free()


## The ground's kept heights give exactly the grid the curve does, anywhere (on the grid, between
## its points, and beyond the piece where nothing is kept).
func test_kept_heights_match_the_curve() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for id: StringName in [&"barley", &"warm_down", EndlessForks.GORGE_DOWN]:
		EndlessPieces.kit(id, 0.0)  # (builds, and keeps its heights)
		var kept: PackedFloat32Array = EndlessPieces._heights[id]
		var worst := 0.0
		for i in 300:
			var x := rng.randf_range(-110.0, 110.0)
			var z := rng.randf_range(-EndlessPieces.length(id) - 12.0, 12.0)
			var with := EndlessPieces.grid_height(id, x, z)
			EndlessPieces._heights.erase(id)
			worst = maxf(worst, absf(with - EndlessPieces.grid_height(id, x, z)))
			EndlessPieces._heights[id] = kept
		check(worst < 1e-4, "%s: kept and worked out agree (%.6f)" % [id, worst])


## The road is decided once the spine stands between the roads, by your side; not before.
func test_the_road_is_the_side_you_are_on() -> void:
	var id := EndlessForks.GORGE_DOWN  # its low road is on the left
	check(EndlessForks.road_at(id, Vector3(-20.0, 10.0, -70.0)) == "low", "left, below the spine: the low road")
	check(EndlessForks.road_at(id, Vector3(20.0, 10.0, -70.0)) == "high", "right: the high road")
	check(EndlessForks.road_at(id, Vector3(-20.0, 30.0, -60.0)) == "", "high over the spine's nose: not yet")
	check(EndlessForks.road_at(id, Vector3(-5.0, 10.0, -30.0)) == "", "before the nose: not yet")
	check(EndlessForks.road_at(id, Vector3(-5.0, 60.0, -100.0)) == "low", "at the latest, by -100")
	check(EndlessForks.road_at(EndlessForks.RIVER_RAIL, Vector3(20.0, 10.0, -70.0)) == "low", "the river is on the right")


func _two_roads() -> EndlessStars:
	var stars := EndlessStars.new()
	stars.tuning = Tuning.new()
	add_node(stars)
	var arcs: Array[Dictionary] = [
		{"name": "low", "stars": PackedVector3Array([Vector3(-4, 10, -14), Vector3(-8, 10, -20)]), "big": [false, false], "zone": "", "title": "", "bonus": true, "road": "low"},
		{"name": "high", "stars": PackedVector3Array([Vector3(4, 10, -14), Vector3(8, 10, -20)]), "big": [false, false], "zone": "", "title": "", "bonus": true, "road": "high"}]
	stars.add_piece(0, arcs, Vector3.ZERO, {})
	return stars


## Before the road is decided neither road's stars can be missed; after it, the other road's dim,
## close quietly and stop counting (even one taken on it before swinging across).
func test_the_road_not_taken_stops_counting() -> void:
	var stars := _two_roads()
	stars.check(Vector3(4, 10, -14))  # a high signpost star, then swinging across
	stars.check(Vector3(-2, 10, -40))  # past both, the road not yet decided
	check(stars.missed_total == 0 and not stars.arcs[0].closed, "nothing missed before the road is decided")
	stars.choose_road(0, "low")
	check(stars.arcs[1].alt and stars.arcs[1].dim and stars.arcs[1].closed, "the high road's stars dim and close")
	check(stars.taken_total == 0, "the star taken on it stops counting (%d)" % stars.taken_total)
	stars.check(Vector3(-2, 10, -41))
	check(stars.missed_total == 2, "the low road's flown-past stars count as missed (%d)" % stars.missed_total)


## A fork's kit has both roads (lines, circles, arcs on each), and its card names your road.
func test_a_fork_has_both_roads() -> void:
	for id in FORKS:
		var kit := EndlessPieces.kit(id, 0.5)
		check(not kit.fork.is_empty() and (kit.fork["lines"]["low"] as Array).size() > 5 and (kit.fork["lines"]["high"] as Array).size() > 5, "%s: both roads' lines" % id)
		var roads := {}
		for arc in kit.arcs:
			roads[arc.get("road", "")] = int(roads.get(arc.get("road", ""), 0)) + (arc["stars"] as PackedVector3Array).size()
		check(int(roads.get("low", 0)) >= 1.5 * int(roads.get("high", 1)), "%s: the low road has far more stars %s" % [id, roads])
		check(kit.orbits.all(func(o: Dictionary) -> bool: return o.get("road", "") in ["low", "high"]), "%s: every circle is on a road" % id)


## A pilot circling across a two-line piece's join chooses its line where it straightens out, at
## the height it has there (not at the join): the Standing Stones' 0 of 9.
func test_the_line_is_chosen_at_the_choice_point() -> void:
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	game.calibration = {"pieces": [&"stones", &"street", &"street"], "d": 0.0, "h": 13.5}
	game.start_run(false)
	await physics_frames(2)
	var p: EndlessWorld.Piece = game.world.pieces[0]
	var chosen := []
	game.line_chosen.connect(func(_z: float, high: bool) -> void: chosen.append(high))
	game._choosing = p
	game.plane.model.velocity = Vector3(6.0, 0.0, 2.0)  # circling, heading back
	game._choose_line(p.origin + Vector3(0.0, 13.5, -10.0))
	check(chosen.is_empty(), "not while circling just inside")
	game.plane.model.velocity = Vector3(0.0, 0.0, -7.0)  # straightened out, having climbed
	game._choose_line(p.origin + Vector3(0.0, 22.0, -12.0))
	check(chosen == [true], "straightened out at 22: the high line (%s)" % [chosen])
	game.queue_free()


## The Warm Down: a hill to cross by its saddle, with lift either side.
func test_the_warm_down_has_its_saddle() -> void:
	check(absf(EndlessPieces.down_height(EndlessPieces.SADDLE.x, -82.0) - EndlessPieces.SADDLE_FLOOR) < 0.5, "the saddle is the low way over")
	check(EndlessPieces.down_height(-30.0, -82.0) > 13.5, "the rest of the crest is the full height")
	var kit := EndlessPieces.kit(&"warm_down", 0.5)
	check(kit.zones.filter(func(z: Dictionary) -> bool: return z["shape"] == Thermal.Shape.CYLINDER).size() == 2, "a thermal each side")
	check(kit.arches.size() == 1, "crossing the saddle is felt")
