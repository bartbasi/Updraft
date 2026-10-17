# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Endless step 4a (docs/hazards-plan.md §11): the kitten (fair reach, its telegraph, the string),
## being caught, homes (seeded, clear of every line), the Farmyard's geometry, the lee rotor and
## the generator's hazard spacing.

const DT := 1.0 / 60.0


## A kitten awake at the origin, facing +z.
func _kitten() -> Kitten:
	var k: Kitten = add_node(Kitten.new("pip", 1))
	k.state = Kitten.State.IDLE
	return k


## Flies straight past `k` at `speed`, its closest approach to C `miss` away (along x, at C's height
## plus `rise`, in front); returns {events, closest (to C), caught}.
func _pass(k: Kitten, miss: float, speed := 8.0, rise := 0.0, string := false, heading := 0.0) -> Dictionary:
	var c := Kitten.CHEST
	var dir := Vector3(cos(heading), 0.0, -sin(heading)).normalized()
	var side := Vector3(-dir.z, 0.0, dir.x)
	if side.z < 0.0:
		side = -side
	var near := c + side * miss + Vector3(0.0, rise, 0.0)
	var events := PackedStringArray()
	var closest := INF
	var t := -70.0 / speed
	while t < 40.0 / speed:
		var at := near + dir * speed * t
		var pts := PackedVector3Array()
		if string:
			for i in 6:
				pts.append(at + Vector3(0.0, -0.6 - i * 0.6, 0.0))
		closest = minf(closest, at.distance_to(c))
		var e := k.step(DT, at, dir * speed, pts)
		if e != Kitten.NOTHING:
			events.append(e)
		if e == Kitten.CAUGHT:
			break
		t += DT
	return {"events": events, "closest": closest, "caught": Kitten.CAUGHT in events}


func test_straight_passes() -> void:
	var far := _pass(_kitten(), 10.0)
	check(not ("missed" in far["events"]) and not far["caught"], "10 u: no lunge (%s)" % ", ".join(far["events"]))
	for miss in [6.5, 4.5]:
		var r := _pass(_kitten(), miss)
		check(Kitten.MISSED in r["events"] and not r["caught"], "%.1f u: a lunge that misses (%s)" % [miss, ", ".join(r["events"])])
	var close := _pass(_kitten(), 3.8)
	check(close["caught"], "3.8 u: caught (%s)" % ", ".join(close["events"]))


## Nothing beyond REACH + CATCH (4.0 u) from C is ever caught; nearly everything within 3.5 is.
func test_the_reach_is_fair() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var unfair := 0
	var near := 0
	var near_caught := 0
	for i in 5000:
		var miss := rng.randf_range(2.0, 9.0)
		var args := [miss, rng.randf_range(4.0, 14.0), rng.randf_range(-2.0, 2.0), rng.randf_range(-0.6, 0.6)]
		if 0.5 + args[0] * cos(args[3]) + 70.0 * sin(args[3]) < 0.5:
			continue  # (an approach out of the wall: no flight does that)
		var r := _pass(_kitten(), args[0], args[1], args[2], false, args[3])
		if r["caught"] and float(r["closest"]) > Kitten.REACH + Kitten.CATCH:
			unfair += 1
		if float(r["closest"]) < 3.5 and "ready" in r["events"]:
			near += 1
			near_caught += int(r["caught"])
		cleanup()
	check(unfair == 0, "no catch beyond 4.0 u (%d)" % unfair)
	check(near > 0 and near_caught >= near * 0.99, "caught below 3.5 u when ready (%d of %d)" % [near_caught, near])


func test_no_lunge_unless_fair() -> void:
	# Never before WIGGLE_MIN of wiggle: straight in from the side at 9 u, then held still at 5 u.
	var k := _kitten()
	k.state = Kitten.State.WATCHING_YOU
	var lunged_early := false
	for i in int(Kitten.WIGGLE_MIN / DT) - 1:
		k.step(DT, Kitten.CHEST + Vector3(0.0, 0.0, 4.0), Vector3.ZERO)
		lunged_early = lunged_early or k.state == Kitten.State.LUNGE
	check(not lunged_early, "no lunge before %.1f s of wiggle" % Kitten.WIGGLE_MIN)
	# Behind the wall's plane: nothing at all.
	k = _kitten()
	var woke := false
	for i in 600:
		k.step(DT, Kitten.CHEST + Vector3(sin(i * 0.02) * 3.0, 0.0, -3.0), Vector3.ZERO)
		woke = woke or k.state in [Kitten.State.WIGGLE, Kitten.State.LUNGE]
	check(not woke, "nothing behind its wall")
	# Arriving from behind it (never watched) and passing close: no lunge on the first moment.
	k = _kitten()
	var e := k.step(DT, Kitten.CHEST + Vector3(0.0, 0.0, 3.0), Vector3(8.0, 0.0, 0.0))
	check(e == Kitten.WATCHING and k.state != Kitten.State.LUNGE, "a flyer it never watched isn't lunged at (%s)" % e)
	# It re-arms REARM after a miss.
	k = _kitten()
	_pass(k, 5.0)
	check(k.state == Kitten.State.MISS or k.state == Kitten.State.IDLE or k.state == Kitten.State.WATCHING_YOU, "after a miss it rests")
	k._enter(Kitten.State.MISS)
	k.step(DT, Kitten.CHEST + Vector3(0.0, 0.0, 30.0), Vector3.ZERO)
	for i in int(Kitten.REARM / DT) - 2:
		k.step(DT, Kitten.CHEST + Vector3(0.0, 0.0, 30.0), Vector3.ZERO)
	check(k.state == Kitten.State.MISS, "still resting before %.1f s" % Kitten.REARM)
	for i in 4:
		k.step(DT, Kitten.CHEST + Vector3(0.0, 0.0, 30.0), Vector3.ZERO)
	check(k.state != Kitten.State.MISS, "re-armed after %.1f s" % Kitten.REARM)


## A balloon's string within its reach is batted (a snag), never caught; the plane there is missed.
func test_the_string_is_batted() -> void:
	var batted := 0
	var caught := 0
	for rise in [3.5, 4.0, 4.5]:  # (the balloon itself 4.6 u or more off: out of reach)
		var r := _pass(_kitten(), 3.0, 6.0, rise, true)
		batted += int(Kitten.BATTED in r["events"])
		caught += int(r["caught"])
	check(caught == 0, "a balloon passing above is never caught (%d)" % caught)
	check(batted > 0, "its string gets batted (%d of 3)" % batted)
	var plane := _pass(_kitten(), 3.0, 6.0, 4.0)
	check(not plane["caught"], "the plane at the same spot isn't caught (%s)" % ", ".join(plane["events"]))


## Caught ends the run as a crash does, with the hug instead of a pop: the title, the delay, the bank.
func test_caught_ends_the_run() -> void:
	Progress.save_all({"unlocked": true, "stars": 10})
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	game.opens_scenes = false
	await physics_frames(2)
	var notes := PackedStringArray()
	game.note.connect(func(t: String) -> void: notes.append(t))
	game.stars_run = 3
	var p: EndlessWorld.Piece = game.world.pieces[0]
	var k := Kitten.new("pip", 1)
	p.node.add_child(k)
	k.global_position = game.plane.global_position + Vector3(0.0, 0.0, -2.0)
	game._caught(k, 3.6)
	var ended := notes[notes.size() - 1]
	check(ended.begins_with("ended: Caught by Pip"), "the card's title (%s)" % ended)
	check(game.plane.model.crashed and not game._pop.playing and not game._crumple.playing, "no pop or crumple")
	await physics_frames(30)
	check(game.plane.global_position.distance_to(k.hug_point()) < 0.01, "drawn into the hug (%.2f)" % game.plane.global_position.distance_to(k.hug_point()))
	check(Progress.load_all()["stars"] == 13, "stars banked (%d)" % Progress.load_all()["stars"])
	check(is_equal_approx(game.plane.tuning.endless_card_delay_caught, 0.9), "the card waits 0.9 s")


## Homes are the seed's: the same plan every time, kittens apart and not too early.
func test_homes_are_seeded_and_spaced() -> void:
	var slots: Array[Dictionary] = [{"at": Vector2(44.0, -60.0), "side": 1.0, "yaw": 0.0, "large": true},
		{"at": Vector2(-44.0, -60.0), "side": -1.0, "yaw": 0.0, "large": false}]
	var differs := false
	var homes_seen := 0
	var kittens_seen := 0
	for seed_value in 300:
		var last := -1000
		var last_b := -1000
		var first: Array = []
		for tile in range(0, 120):
			var metres := tile * EndlessGenerator.TILE_METRES
			var a := EndlessHomes.plan(seed_value, tile, slots, metres, last)
			var b := EndlessHomes.plan(seed_value, tile, slots, metres, last_b)
			if a != b:
				check(false, "seed %d tile %d: the same plan twice" % [seed_value, tile])
				return
			for h: Dictionary in a["homes"]:
				homes_seen += 1
				if h["kitten"] != "":
					kittens_seen += 1
					if metres < EndlessHomes.KITTEN_FROM_M or tile - last < EndlessHomes.KITTEN_GAP_TILES:
						check(false, "seed %d tile %d: a kitten too soon (%.0f m, %d tiles)" % [seed_value, tile, metres, tile - last])
						return
			if tile < 30:
				first.append(a["homes"])
			last = a["last_kitten_tile"]
			last_b = b["last_kitten_tile"]
		var other := []
		var last_o := -1000
		for tile in range(0, 30):
			var o := EndlessHomes.plan(seed_value + 1, tile, slots, tile * EndlessGenerator.TILE_METRES, last_o)
			other.append(o["homes"])
			last_o = o["last_kitten_tile"]
		differs = differs or other != first
	check(differs, "different seeds, different homes")
	check(homes_seen > 0 and kittens_seen > 0, "homes (%d) and kittens (%d) turn up" % [homes_seen, kittens_seen])
	var farm := EndlessPieces.kit(&"farmyard", 0.5)
	check(farm.kittens.size() == 1 and farm.kittens[0]["coat"] == "pip", "the Farmyard's kitten is Pip")


## Every home slot of every piece at every layout keeps clear of lines, lifts, stars and joins,
## and trees keep off them.
func test_home_slots_keep_clear() -> void:
	var bad := PackedStringArray()
	var count := 0
	for id: StringName in EndlessPieces.TABLE:
		for d in [0.0, 0.5, 1.0]:
			var k := EndlessPieces.kit(id, d)
			var lines := k.all_lines(0.0)
			lines.append_array(k.all_lines(40.0))
			for slot in k.home_slots:
				count += 1
				var at: Vector2 = slot["at"]
				for p in lines:
					if Vector2(p.x, p.z).distance_to(at) < EndlessHomes.CLEAR_OF_LINE:
						bad.append("%s d%.1f: a line at %.1f" % [id, d, Vector2(p.x, p.z).distance_to(at)])
						break
				for arc in k.arcs:
					for s: Vector3 in arc["stars"]:
						if Vector2(s.x, s.z).distance_to(at) < EndlessHomes.CLEAR_OF_STAR:
							bad.append("%s d%.1f: a star" % [id, d])
				if at.y > -20.0 or at.y < -EndlessPieces.length(id) + 12.0:
					bad.append("%s d%.1f: in a join (z %.0f)" % [id, d, at.y])
				var rng := RandomNumberGenerator.new()
				rng.seed = 7
				for t in EndlessPieces._tree_spots(k, rng):
					var base: Vector3 = t["base"]
					if Vector2(base.x, base.z).distance_to(at) < 10.0:
						bad.append("%s d%.1f: a tree" % [id, d])
	check(count > 0, "pieces have home slots (%d)" % count)
	check(bad.is_empty(), "slots keep clear: %s" % ", ".join(bad.slice(0, 6)))


## Pip's window: no star or line within her reach at any layout, and she sees you coming.
func test_the_farmyard_is_fair() -> void:
	var tune := Tuning.new()
	for d in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var k := EndlessPieces.kit(&"farmyard", d)
		var spec: Dictionary = k.kittens[0]
		var c: Vector3 = spec["at"] + Basis(Vector3.UP, float(spec["yaw"])) * Kitten.CHEST
		var nearest := INF
		for arc in k.arcs:
			for s: Vector3 in arc["stars"]:
				nearest = minf(nearest, s.distance_to(c) - maxf(tune.big_star_pickup_radius, tune.star_pickup_radius))
		check(nearest >= Kitten.REACH + Kitten.CATCH + 0.1, "d %.2f: no star within reach (%.2f)" % [d, nearest])
		var line := k.line(8.0)
		var line_near := INF
		for i in line.size() - 1:
			line_near = minf(line_near, Geometry3D.get_closest_point_to_segment(c, line[i], line[i + 1]).distance_to(c))
		check(line_near >= lerpf(6.5, 5.5, d) - 0.01, "d %.2f: the line keeps %.1f u off (%.2f)" % [d, lerpf(6.5, 5.5, d), line_near])


## The lee rotor: only late in a run, and well off the swoop's line.
func test_the_lee_rotor() -> void:
	for d in [0.0, 0.5, 0.6, 0.75, 1.0]:  # (0.6 lays out as 0.5)
		var k := EndlessPieces.kit(&"warm_down", d)
		var rotors := k.zones.filter(func(z: Dictionary) -> bool: return String(z["name"]).begins_with("Rotor"))
		check(rotors.size() == (2 if d >= 0.75 else 0), "d %.2f: %d rotors" % [d, rotors.size()])
		for r in rotors:
			var c: Vector3 = r["at"]
			var half: Vector3 = r["size"] * 0.5
			for h in [4.0, 20.0]:
				for p in k.line(h):
					var dx := maxf(absf(p.x - c.x) - half.x, 0.0)
					var dz := maxf(absf(p.z - c.z) - half.z, 0.0)
					if Vector2(dx, dz).length() < 7.0:
						check(false, "d %.2f: the line passes %s (%.1f)" % [d, r["name"], Vector2(dx, dz).length()])
						return


## Hazard pieces never come straight after one another (two apart early), kittens 3 apart.
func test_hazards_are_spaced() -> void:
	var bad := PackedStringArray()
	var farms := 0
	for run in 1500:
		var gen := EndlessGenerator.new(Tuning.new(), run * 13 + 5)
		var ids: Array[StringName] = []
		var ds: Array[float] = []
		for i in 40:
			var p := gen.next()
			ids.append(p.id)
			ds.append(p.d)
			var info := EndlessPieces.info(p.id)
			if bool(info.get("kitten", false)):
				farms += 1
				if p.tile * EndlessGenerator.TILE_METRES < float(info["min_m"]):
					bad.append("run %d: %s at %.0f m" % [run, p.id, p.tile * EndlessGenerator.TILE_METRES])
		for i in ids.size():
			var info := EndlessPieces.info(ids[i])
			if bool(info.get("hazard", false)):
				for j in range(maxi(i - (1 if ds[i] >= 0.5 else 2), 0), i):
					if bool(EndlessPieces.info(ids[j]).get("hazard", false)):
						bad.append("run %d: hazards at %d and %d" % [run, j, i])
			if bool(info.get("kitten", false)):
				for j in range(maxi(i - EndlessGenerator.KITTEN_GAP, 0), i):
					if bool(EndlessPieces.info(ids[j]).get("kitten", false)):
						bad.append("run %d: kittens at %d and %d" % [run, j, i])
	check(farms > 0, "the Farmyard turns up (%d)" % farms)
	check(bad.is_empty(), "spacing kept: %s" % ", ".join(bad.slice(0, 6)))


func test_kitten_code_uses_no_global_random_numbers() -> void:
	var global := RegEx.create_from_string("(?<![.\\w])(randi|randf|randi_range|randf_range|randomize)\\(")
	for path in ["res://scripts/endless/kitten.gd", "res://scripts/endless/homes.gd", "res://scripts/endless/farmyard.gd"]:
		var hits := global.search_all(FileAccess.get_file_as_string(path))
		check(hits.is_empty(), "%s uses no global random numbers (%d)" % [path.get_file(), hits.size()])
