extends TestCase
## The demo course in the real scene: layout checks and whole flights.

const MAIN := preload("res://scenes/main.tscn")


func _start(pilot: Callable) -> Node:
	var game := MAIN.instantiate()
	add_node(game)
	(game.get_node("Plane") as Flyer).autopilot = pilot
	return game


## Starts a flight of the downstairs part on its own, entering the living room.
func _start_downstairs(pilot: Callable) -> Node:
	var game := _start(pilot)
	var plane := game.get_node("Plane") as Flyer
	plane.launch(Course.LIVING_ROOM_ENTRY, 0.0)
	(game.get_node("Camera") as FollowCamera).snap()
	return game


func _fly_until_end(plane: Flyer, max_seconds: float) -> void:
	var frames := 0
	while not plane.is_ended() and frames < int(max_seconds * 60.0):
		await tree.physics_frame
		frames += 1


func test_radiator_thermal_is_within_reach_of_the_living_room_line() -> void:
	var gap := absf(Course.RADIATOR_THERMAL.x - Course.LIVING_ROOM_ENTRY.x) - 3.6
	check_between(gap, -1.0, 3.0, "the entry line passes at or just inside the radiator thermal's edge")


func test_scene_has_the_downstairs_thermals() -> void:
	_start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var names := tree.get_nodes_in_group("thermals").map(func(n: Node) -> String: return n.name)
	check(names.has("RadiatorHeat") and names.has("KettleSteam"), "radiator and kettle thermals exist: %s" % [names])


func test_autopilot_flies_the_downstairs_course() -> void:
	var pilot := Autopilot.new(Autopilot.downstairs_line())
	var game := _start_downstairs(pilot.fly)
	var plane := game.get_node("Plane") as Flyer
	var thermals := [0]
	plane.entered_thermal.connect(func(_t: Thermal) -> void: thermals[0] += 1)
	var bumps := [0]
	plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
	await _fly_until_end(plane, 90.0)
	print("        ended at %.1f s, flew %.1f m, %d bumps" % [plane.flight_time, plane.distance / plane.tuning.units_per_meter, bumps[0]])
	check(not plane.model.crashed, "autopilot should not crash (at %s)" % plane.global_position)
	check(game.reached_outside, "autopilot should fly out of the window")
	check(plane.is_ended() and Course.is_outside(plane.global_position), "flight should end on the grass outside")
	check(thermals[0] >= 2, "both thermals should be flown through (%d)" % thermals[0])
	check_between(plane.flight_time, 40.0, 75.0, "flight time (s)")


func test_autopilot_flies_from_the_bedroom_to_the_hills() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := _start(pilot.fly)
	var plane := game.get_node("Plane") as Flyer
	var zones := []
	plane.entered_thermal.connect(func(z: Thermal) -> void: zones.append(String(z.name)))
	var bumps := [0]
	plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
	var sections := {}
	var frames := 0
	while not plane.is_ended() and frames < 150 * 60:
		await tree.physics_frame
		frames += 1
		if not plane.held:
			var here := Course.section_at(plane.global_position)
			if not sections.has(here):
				sections[here] = snappedf(plane.flight_time, 0.1)
	print("        whole run: %.1f s, %d bumps, sections %s, zones %s" % [plane.flight_time, bumps[0], sections, zones])
	check(not plane.model.crashed, "the good line flies the whole course without crashing (at %s)" % plane.global_position)
	check(plane.is_ended() and Course.is_outside(plane.global_position), "and lands on the grass outside")
	for zone in ["Sunbeam", "RadiatorHeat", "KettleSteam", "HayHeat"]:
		check(zones.has(zone), "flies through %s" % zone)
	check(sections.has("stair hall") and sections.has("living room"), "down the stairs into the living room: %s" % [sections])
	check(plane.flight_time >= 60.0, "a well-flown run lasts at least a minute (%.1f s)" % plane.flight_time)
	check(Course.in_lavender(plane.global_position), "and comes down in the lavender field (at %s)" % plane.global_position)


func test_hands_off_flight_ends_without_getting_stuck() -> void:
	var game := _start_downstairs(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as Flyer
	await _fly_until_end(plane, 60.0)
	print("        hands-off: ended at %.1f s, %s, crashed=%s" % [plane.flight_time, plane.global_position, plane.model.crashed])
	check(plane.is_ended(), "a flight with no input must end on its own")


func test_diving_flight_ends() -> void:
	var game := _start_downstairs(func(_p: Flyer) -> Vector2: return Vector2(-1.0, 0.0))
	var plane := game.get_node("Plane") as Flyer
	await _fly_until_end(plane, 30.0)
	check(plane.is_ended(), "a nose-dive must end the run")


## Heights here are where non-divers arrive once the stairwell downdraft has pulled them
## down; the header itself must also never crash a level or climbing plane.
func test_a_plane_that_never_dives_glances_down_through_the_arch() -> void:
	for setup in [[13.0, 7.0, 0.0], [15.0, 7.0, 0.0], [17.0, 9.5, 0.0], [13.0, 9.5, 0.0], [12.5, 7.0, 10.0], [14.5, 9.5, 10.0], [16.0, 7.0, 10.0]]:
		var climb_input := 0.3 if float(setup[2]) > 0.0 else 0.0
		var game := _start(func(_p: Flyer) -> Vector2: return Vector2(climb_input, 0.0))
		var plane := game.get_node("Plane") as Flyer
		plane.launch(Vector3(-2.0, setup[0], 30.0), 0.0)
		var bumps := [0]
		plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
		var waited := 0
		while plane.held and waited < 600:
			await tree.process_frame
			waited += 1
		var angle := deg_to_rad(float(setup[2]))
		plane.model.velocity = Vector3(0.0, sin(angle), -cos(angle)) * float(setup[1])
		var frames := 0
		while frames < 300 and not plane.is_ended() and plane.global_position.z > Course.BACK_Z - 2.0:
			await tree.physics_frame
			frames += 1
		var label := "at y %.1f, %.1f u/s, climbing %.0f deg" % [setup[0], setup[1], setup[2]]
		check(bumps[0] >= 1, "%s: meets the header" % label)
		check(not plane.model.crashed, "%s: glances through the arch instead of crashing (at %s)" % [label, plane.global_position])
		check(plane.global_position.z <= Course.BACK_Z - 2.0, "%s: and flies on into the living room" % label)
		await cleanup()


func test_the_good_line_passes_well_under_the_arch_header() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := _start(pilot.fly)
	var plane := game.get_node("Plane") as Flyer
	var clearance := INF
	var near_arch := [0]
	var header_end := Course.STAIR_HALL_MIN.y + Course.ARCH_HEADER_DEPTH
	plane.bumped.connect(func(_s: float) -> void:
		if plane.global_position.z < header_end + 1.0 and plane.global_position.z > Course.BACK_Z - 1.0:
			near_arch[0] += 1)
	var frames := 0
	while frames < 60 * 40 and not plane.is_ended() and plane.global_position.z > Course.BACK_Z - 3.0:
		await tree.physics_frame
		frames += 1
		var p := plane.global_position
		if p.z > Course.STAIR_HALL_MIN.y and p.z < header_end and absf(p.x) < 8.0:
			var underside := Course.ARCH_TOP + (p.z - Course.STAIR_HALL_MIN.y) * Course.ARCH_HEADER_RISE / Course.ARCH_HEADER_DEPTH
			clearance = minf(clearance, underside - p.y)
	check(near_arch[0] == 0, "the good line passes the arch untouched (%d bumps)" % near_arch[0])
	check(clearance > 2.0, "and well under the header (%.1f units clear)" % clearance)


func test_arch_and_header_collide_as_drawn() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var probe := func(at: Vector3) -> bool:
		var query := PhysicsShapeQueryParameters3D.new()
		var ball := SphereShape3D.new()
		ball.radius = Flyer.RADIUS
		query.shape = ball
		query.collision_mask = Flyer.WORLD_LAYER
		query.transform = Transform3D(Basis.IDENTITY, at)
		return not space.intersect_shape(query).is_empty()
	var wall := Course.STAIR_HALL_MIN.y
	var r := Flyer.RADIUS
	var slope := Course.ARCH_HEADER_RISE / Course.ARCH_HEADER_DEPTH
	var normal := Vector3(0.0, -Course.ARCH_HEADER_DEPTH, Course.ARCH_HEADER_RISE).normalized()  # down and away from the wall
	# The underside lies exactly on its slope: clear just below it, solid just into it.
	for x in [-6.0, -2.0, 2.0, 5.5]:
		for z in [16.0, 18.0, 20.0, 22.0]:
			var on := Vector3(x, Course.ARCH_TOP + (z - wall) * slope, z)
			check(not probe.call(on + normal * (r + 0.08)), "clear just under the header at %s" % [on])
			check(probe.call(on + normal * (r - 0.1)), "solid at the header's underside at %s" % [on])
			check(probe.call(Vector3(x, Course.ARCH_TOP + Course.ARCH_HEADER_RISE - 0.5, z)), "no pocket inside the header at %s" % [Vector3(x, 0, z)])
	# The arch opening is clear and the wall around it is solid.
	for x in [-6.6, -3.0, 0.0, 3.0, 5.6]:
		for y in [0.4, 4.0, 8.0, 11.1]:
			check(not probe.call(Vector3(x, y, Course.BACK_Z + 0.5)), "the arch is open at x %.1f, y %.1f" % [x, y])
	for at in [Vector3(-8.5, 6.0, Course.BACK_Z + 0.5), Vector3(8.0, 6.0, Course.BACK_Z + 0.5), Vector3(0.0, 11.6, Course.BACK_Z + 0.5)]:
		check(probe.call(at), "the wall beside and above the arch is solid at %s" % [at])


func test_arch_header_is_gentle_enough_to_glance_off() -> void:
	var slope := rad_to_deg(atan2(Course.ARCH_HEADER_RISE, Course.ARCH_HEADER_DEPTH))
	check(slope <= 36.0, "the header slopes at most about 35 degrees (%.1f), well under the 50-degree crash angle" % slope)


## Designer's Phase A must-fix #1, end to end: pilots who never push the nose down come down
## the stairs (with the downdraft's help) and must reach the living room.
func test_floaters_who_never_dive_get_through_the_arch() -> void:
	var stuck := []
	var runs := 0
	for climb in [0.0, 0.15, 0.3]:
		for turn_x in [11.0, 7.0, 3.0]:
			for bank in [1.0, 0.5]:
				var turned := [false]
				var steer := func(plane: Flyer) -> Vector2:
					var p := plane.global_position
					if not turned[0]:
						turned[0] = p.x < float(turn_x) and plane.model.heading <= 0.05
						return Vector2(climb, bank if p.x < float(turn_x) else 0.0)
					# After the turn: aim for the middle of the bright arch, still never diving.
					var to := Vector3(-0.5, 0.0, Course.BACK_Z) - p
					var error := wrapf(atan2(-to.x, -to.z) - plane.model.heading, -PI, PI)
					return Vector2(climb, clampf(-error * 2.0, -1.0, 1.0))
				var game := _start(steer)
				var plane := game.get_node("Plane") as Flyer
				plane.launch(Vector3(24.0, 20.5, 41.5), PI / 2.0)
				var frames := 0
				while frames < 60 * 20 and not plane.is_ended() and plane.global_position.z > Course.BACK_Z - 2.0:
					await tree.physics_frame
					frames += 1
				runs += 1
				var p := plane.global_position
				if plane.is_ended() or p.z > Course.BACK_Z - 2.0:
					var how := "crashed" if plane.model.crashed else ("came to rest" if plane.is_ended() else "ran out of time")
					stuck.append("climb %.2f, turn at x %.0f, bank %.1f: %s at %s" % [climb, turn_x, bank, how, p])
				await cleanup()
	print("        floaters: %d/%d reached the living room" % [runs - stuck.size(), runs])
	check(stuck.is_empty(), "every floater reaches the living room: %s" % [stuck])


## The ground outdoors has the shape the designer planned (docs/outside-plan.md, section 1),
## leaving out the soft rolls.
func test_ground_has_the_planned_shape() -> void:
	var rolls := func(x: float, z: float) -> float:
		var d := maxf(0.0, Course.FAR_Z - Course.WALL - z)
		return 0.6 * (1.4 * sin(x * 0.09 + z * 0.045) + 1.0 * sin(x * 0.05 - z * 0.08 + 1.3)) * clampf(d / 25.0, 0.0, 1.0)
	var table := [[0.0, -95.0, -1.0], [-2.0, -118.0, -0.3], [0.0, -150.0, 0.6], [-5.0, -182.0, 1.6], [-12.0, -215.0, 2.6],
		[34.0, -268.0, 4.4], [-38.0, -200.0, 6.9], [-46.0, -200.0, 13.1], [-56.0, -200.0, 20.7], [-75.0, -200.0, 24.1]]
	for row: Array in table:
		var h := Course.ground_height(row[0], row[1]) - float(rolls.call(row[0], row[1]))
		check(absf(h - float(row[2])) <= 0.15, "ground at (%.0f, %.0f) is %.2f, planned %.1f" % [row[0], row[1], h, row[2]])
	# Every edge of the world is high ground, except the Gap through the Downs (Phase 4).
	for x in range(-120, 121, 12):
		if absf(x - Course.GAP_X) > Course.GAP_HALF + 26.0:
			check(Course.ground_height(x, -336.0) > 40.0, "the head wall is high at x %d" % x)
	for z in range(-40, -331, -10):
		var low := minf(Course.ground_height(-126.0, z), Course.ground_height(126.0, z))
		check(low > 38.0, "both sides are high at z %d (%.1f)" % [z, low])


## A plane that ignores the warm air outdoors lands after about ten seconds.
func test_a_glide_with_no_lift_lands_in_about_ten_seconds() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	for zone in tree.get_nodes_in_group("thermals"):
		if zone.name == "HayHeat":
			zone.remove_from_group("thermals")
	var plane := game.get_node("Plane") as Flyer
	plane.launch(Vector3(0.0, 7.0, Course.FAR_Z - 1.5), 0.0)
	await _fly_until_end(plane, 30.0)
	print("        no lift: landed after %.1f s at %s" % [plane.flight_time, plane.global_position])
	check(not plane.model.crashed, "it lands, not crashes")
	check_between(plane.flight_time, 8.0, 12.0, "seconds from the window to the grass")


## The hay field's warm air is right on the line out of the window: flying straight through it
## climbs, and circling in it climbs to near its top within a dozen seconds.
func test_hay_field_thermal_lifts_straight_and_circling_planes() -> void:
	var hay: Vector2 = Course.HAY_FIELD["at"]
	var top := float(Course.HAY_FIELD["top"])
	for circling in [false, true]:
		var roll := 1.0 if circling else 0.0
		var game := _start(func(p: Flyer) -> Vector2:
			if not circling or p.global_position.z > hay.y:
				return Vector2.ZERO
			return Vector2(0.0, -roll))  # full bank left once near the middle
		var plane := game.get_node("Plane") as Flyer
		# The circling plane enters to the right of the middle, so its full-bank circle (radius 5.6) is centred on it.
		var start := Vector3(3.6 if circling else 0.0, 7.0, Course.FAR_Z - 1.5)
		plane.launch(start, 0.0)
		var highest := start.y
		var frames := 0
		var limit := 60 * (12 if circling else 8)
		while frames < limit and not plane.is_ended():
			await tree.physics_frame
			frames += 1
			highest = maxf(highest, plane.global_position.y)
		if circling:
			check(highest >= top - 2.0, "circling climbs to y %.1f or more within 12 s (%.1f)" % [top - 2.0, highest])
		else:
			check(highest >= start.y + 6.0, "flying straight through gains at least 6 (from %.1f to %.1f)" % [start.y, highest])
		check(not plane.model.crashed, "and nothing to hit")
		await cleanup()


## The trees stand only where the designer allowed, and the valley floor is open: nothing to
## hit above the grass but the hay bales and the barn.
func test_trees_keep_clear_and_the_valley_is_open() -> void:
	check(not Course.tree_allowed(-2.0, -118.0), "no tree in the hay-field thermal")
	check(not Course.tree_allowed(-2.0, -133.5), "nor just past its edge")
	check(not Course.tree_allowed(-40.0, -200.0), "nor on the ridge face")
	check(Course.tree_allowed(80.0, -200.0), "but on the right-hand slopes, yes")
	var blanket := Vector2((Course.PICNIC_X.x + Course.PICNIC_X.y) * 0.5, (Course.PICNIC_Z.x + Course.PICNIC_Z.y) * 0.5)
	check(Course.PICNIC_CLEARANCE >= 14.0 and not Course.tree_allowed(blanket.x - 14.0, blanket.y), "no tree within a circle down onto the picnic")
	var spots := Course.tree_spots()
	check(spots.size() == 40, "40 trees (%d)" % spots.size())
	for t in spots:
		check(Course.tree_allowed(t.x, t.z), "tree at %s is allowed" % t)
		check(Vector2(t.x, t.z).distance_to(blanket) >= Course.PICNIC_CLEARANCE, "tree at %s is clear of the picnic" % t)
		check(t.x >= 45.0 or t.x <= -72.0 or t.z <= -295.0, "tree at %s is on a slope, the plateau or the head wall" % t)
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = Flyer.RADIUS
	query.shape = ball
	query.collision_mask = Flyer.WORLD_LAYER
	var hits := []
	var z := Course.FAR_Z - Course.WALL - 15.0  # past the garden fence
	while z > -290.0:
		var x := -24.0
		while x <= 30.0:
			var near_bale := false
			for b: Vector2 in Course.HAY_BALES:
				near_bale = near_bale or Vector2(x, z).distance_to(b) < Course.BALE_LENGTH + 1.0
			var at_barn := absf(x - Course.BARN.x) < Course.BARN_SIZE.x * 0.5 + 1.5 and absf(z - Course.BARN.y) < Course.BARN_SIZE.z * 0.5 + 1.5
			if not near_bale and not at_barn:
				for up in [1.0, 3.0, 6.0, 10.0]:
					var at := Vector3(x, Course.ground_height(x, z) + up, z)
					query.transform = Transform3D(Basis.IDENTITY, at)
					if not space.intersect_shape(query, 1).is_empty() and hits.size() < 5:
						hits.append(at)
			x += 3.0
		z -= 3.0
	check(hits.is_empty(), "nothing solid above the valley floor: %s" % [hits])


## Every outdoor thermal lifts a plane circling in it to near its top, and each next one is far
## enough away to be a glide but close enough to reach from the top of the one before.
func test_every_outdoor_thermal_lifts_a_circling_plane_to_near_its_top() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2(0.0, -1.0))  # full bank left
	var plane := game.get_node("Plane") as Flyer
	await physics_frames(2)
	for t: Dictionary in Course.OUTDOOR_THERMALS:
		var at: Vector2 = t["at"]
		var top := float(t["top"])
		var y0 := Course.ground_height(at.x, at.y) + 11.0  # above the barn's roof
		# Heading -Z, banking left: the circle (radius 5.6) is centred 5.6 to the left.
		plane.launch(Vector3(at.x + 5.6, y0, at.y), 0.0)
		var touches := plane.touches
		var highest := y0
		var frames := 0
		while frames < 60 * 15 and not plane.is_ended():
			await tree.physics_frame
			frames += 1
			highest = maxf(highest, plane.global_position.y)
		check(highest >= top - 3.0, "%s: circling from y %.1f climbs to %.1f (top %.0f)" % [t["name"], y0, highest, top])
		check(plane.touches == touches, "%s: nothing to touch while circling" % t["name"])
	for i in range(1, Course.OUTDOOR_THERMALS.size()):
		var a: Dictionary = Course.OUTDOOR_THERMALS[i - 1]
		var b: Dictionary = Course.OUTDOOR_THERMALS[i]
		var gap := (a["at"] as Vector2).distance_to(b["at"])
		# A 9.7 : 1 glide from the top of one (less a few units of height) reaches the next with room to spare.
		var arrive := float(a["top"]) - gap / 9.7 - Course.ground_height((b["at"] as Vector2).x, (b["at"] as Vector2).y)
		check(arrive > 10.0, "%s -> %s: a glide arrives %.1f above the ground" % [a["name"], b["name"], arrive])


## A plane flying along the ridge, just out from the hillside, climbs on the breeze blowing up it
## and never touches the slope; the bonfire smoke rises from the fire, and the barn is solid.
func test_ridge_lifts_a_plane_flying_along_it() -> void:
	var game := _start(func(p: Flyer) -> Vector2:
		var err := wrapf(atan2(-(-37.0 - p.global_position.x), 8.0) - p.model.heading, -PI, PI)
		return Vector2(0.0, clampf(-err * 2.0, -1.0, 1.0)))
	var plane := game.get_node("Plane") as Flyer
	await physics_frames(2)
	plane.launch(Vector3(-36.0, 20.0, -150.0), 0.0)
	var touches := plane.touches
	var y_at := {}
	var ridge_entered := [false]
	plane.entered_thermal.connect(func(z: Thermal) -> void: ridge_entered[0] = ridge_entered[0] or z.name == "RidgeLift")
	while plane.global_position.z > -250.0 and not plane.is_ended():
		await tree.physics_frame
		if plane.global_position.z < -220.0 and not y_at.has("-220"):
			y_at["-220"] = plane.global_position.y
	print("        ridge: y %.1f at z -220, %.1f at the end (z %.0f)" % [y_at.get("-220", -1.0), plane.global_position.y, plane.global_position.z])
	check(ridge_entered[0], "the plane flies into the ridge's rising air")
	check(float(y_at.get("-220", 0.0)) >= 29.0, "it climbs to y 29 or more by z -220 (%.1f)" % float(y_at.get("-220", 0.0)))
	check(plane.touches == touches and not plane.is_ended(), "without touching the hillside")
	var ridge_run: Array = (game.scoring.moments as Array).filter(func(m: Scoring.Moment) -> bool: return m.id == &"ridge_run")
	check(ridge_run.size() == 1 and (ridge_run[0] as Scoring.Moment).award > 0, "and earns the Ridge run style points")
	var space := (game as Node3D).get_world_3d().direct_space_state
	var barn_ground := Course.terrain_height(Course.BARN.x, Course.BARN.y)
	var ray := PhysicsRayQueryParameters3D.create(Vector3(Course.BARN.x, barn_ground + 2.5, Course.BARN.y + 12.0), Vector3(Course.BARN.x, barn_ground + 2.5, Course.BARN.y))
	ray.collision_mask = Flyer.WORLD_LAYER
	check(not space.intersect_ray(ray).is_empty(), "the barn's wall is solid")
	ray = PhysicsRayQueryParameters3D.create(Vector3(Course.BARN.x + 2.0, barn_ground + 20.0, Course.BARN.y), Vector3(Course.BARN.x + 2.0, barn_ground - 1.0, Course.BARN.y))
	ray.collision_mask = Flyer.WORLD_LAYER
	var roof := space.intersect_ray(ray)
	check(not roof.is_empty() and (roof["position"] as Vector3).y > barn_ground + Course.BARN_SIZE.y, "the barn's roof is solid, above its walls")
	# Nothing can fly in under the roof, along the barn, at any height up to the ridge.
	var ball := SphereShape3D.new()
	ball.radius = Flyer.RADIUS
	for up in [5.5, 6.5, 7.5, 8.0]:
		var sweep := PhysicsShapeQueryParameters3D.new()
		sweep.shape = ball
		sweep.collision_mask = Flyer.WORLD_LAYER
		sweep.transform = Transform3D(Basis.IDENTITY, Vector3(Course.BARN.x, barn_ground + up, Course.BARN.y + 8.0))
		sweep.motion = Vector3(0.0, 0.0, -16.0)
		check(space.cast_motion(sweep)[0] < 1.0, "a plane %.1f up meets the barn's gable instead of flying through its attic" % up)
	var fire := Vector3(Course.BONFIRE.x, Course.terrain_height(Course.BONFIRE.x, Course.BONFIRE.y) + 0.5, Course.BONFIRE.y)
	ray = PhysicsRayQueryParameters3D.create(fire + Vector3(0.0, 5.0, 0.0), fire)
	ray.collision_mask = Flyer.WORLD_LAYER
	check(space.intersect_ray(ray).is_empty(), "the bonfire is not solid")
	for zone in tree.get_nodes_in_group("thermals"):
		if zone.name == "BonfireSmoke":
			check((zone as Thermal).look == Thermal.Look.STEAM and (zone as Thermal).outdoors, "the bonfire's thermal looks like smoke")


## A plane that somehow leaves the world comes to a stop instead of falling forever.
func test_leaving_the_world_ends_the_run() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2(-1.0, 0.0))
	var plane := game.get_node("Plane") as Flyer
	await physics_frames(2)
	plane.launch(Vector3(0.0, -11.0, -200.0), 0.0)  # below the world
	await physics_frames(5)
	check(plane.is_ended() and not plane.model.crashed, "it ends as a landing")
	plane.launch(Vector3(124.0, 30.0, -200.0), 0.0)  # off the right-hand edge
	await physics_frames(5)
	check(plane.is_ended(), "off the side of the world ends it too")
	# The whole house is inside the world.
	var inside := [Course.START, Course.KID_EYE, Course.LIVING_ROOM_ENTRY]
	for def in Course.style_moment_defs():
		inside.append_array(Array(def["path"]))
	for p: Vector3 in inside:
		check(Course.WORLD_BOUNDS.has_point(p), "%s is inside the world" % p)


## The hills' height helper matches the grass the plane actually lands on.
func test_terrain_height_matches_the_grass() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var worst := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 60:
		var x := rng.randf_range(-40.0, 40.0)
		var z := rng.randf_range(-105.0, -260.0)
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, 60.0, z), Vector3(x, -20.0, z), Flyer.WORLD_LAYER)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var p: Vector3 = hit["position"]
		if p.y > Course.terrain_height(x, z) + 0.5:
			continue  # landed on a tree or the fence
		worst = maxf(worst, absf(p.y - Course.terrain_height(x, z)))
	check(worst < 0.005, "the grass is where terrain_height says (worst %.4f off)" % worst)


## The plane's shadow shows over everything painted on a floor: the hay field, the stream, and
## (indoors) rugs and the sunbeam's floor glow.
func test_shadow_shows_over_painted_ground() -> void:
	check(Flyer.SHADOW_LIFT > 0.12 + 0.02, "the shadow sits above the sunbeam's floor glow and the rugs")
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as Flyer
	await physics_frames(2)
	plane.held = true
	var stream_x := 7.0
	var hay: Vector2 = Course.HAY_FIELD["at"]
	for spot in [hay + Vector2(2.0, 0.0), hay + Vector2(4.5, -6.5), Vector2(stream_x, Course.STREAM_Z + 2.0 * sin(stream_x * 0.12))]:
		var ground := Course.terrain_height(spot.x, spot.y)
		plane.global_position = Vector3(spot.x, ground + 1.6, spot.y)
		plane._update_shadow()
		var shadow: MeshInstance3D = plane._shadow
		check(shadow.visible, "a shadow under the plane at %s" % spot)
		var painted := ground + Course.PAINT_LIFT
		check(shadow.global_position.y > painted + 0.05, "the shadow is above the painted ground at %s (%.3f vs %.3f)" % [spot, shadow.global_position.y, painted])


## Planes that come into the kitchen low (just over the counter) still catch the kettle steam,
## and it carries them up and out of the window (fun review 2, item 1).
func test_low_planes_catch_the_kettle_steam_and_make_the_window() -> void:
	for y in [4.2, 4.5, 4.8]:
		for x in [1.5, 3.0]:
			var game := _start(func(p: Flyer) -> Vector2:
				var goal := Vector3(Course.KETTLE_THERMAL.x, 0.0, Course.KETTLE_THERMAL.z) if p.global_position.z > Course.KETTLE_THERMAL.z else Vector3(0.0, 0.0, Course.FAR_Z - 7.0)
				var to := goal - p.global_position
				return Vector2(0.0, clampf(-wrapf(atan2(-to.x, -to.z) - p.model.heading, -PI, PI) * 2.0, -1.0, 1.0)))
			var plane := game.get_node("Plane") as Flyer
			plane.launch(Vector3(float(x), float(y), -60.0), 0.0)
			var steam := [false]
			plane.entered_thermal.connect(func(z: Thermal) -> void: steam[0] = steam[0] or z.name == "KettleSteam")
			var frames := 0
			while frames < 60 * 12 and not plane.is_ended() and not game.reached_outside:
				await tree.physics_frame
				frames += 1
			var label := "into the kitchen at y %.1f, x %.1f" % [y, x]
			check(steam[0], "%s: the plane catches the steam" % label)
			check(game.reached_outside, "%s: and it carries it out of the window (%s at %s)" % [label, "crashed" if plane.model.crashed else "ended", plane.global_position])
			await cleanup()


## Air zones out of sight are not drawn and their motes stop: indoor ones once the camera is
## outside, outdoor ones until it reaches the kitchen (they show through the window from there);
## the bowl's only once the camera nears the Gap, and the valley's not from inside the bowl. The
## chalk pit's shows from both.
func test_only_air_zones_in_sight_are_drawn() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as Flyer
	var camera := game.get_node("Camera") as FollowCamera
	await physics_frames(3)
	# [where, plane at, valley zones shown, indoor zones shown, bowl zones shown]
	for where in [["bedroom", Course.START, false, true, false], ["kitchen", Vector3(0.0, 7.0, -70.0), true, true, false],
			["outside", Vector3(0.0, 15.0, -130.0), true, false, false], ["at the Gap", Vector3(6.0, 22.0, -318.0), false, false, true],
			["in the bowl", Vector3(6.0, 20.0, -380.0), false, false, true]]:
		plane.launch(where[1], 0.0)
		camera.snap()
		await physics_frames(3)
		for zone in tree.get_nodes_in_group("thermals"):
			var t := zone as Thermal
			var want: bool = where[3]
			if t.outdoors:
				var in_bowl := t.global_position.z < Course.CREST_Z
				want = (where[2] or where[4]) if t.name == "ChalkHeat" else (where[4] if in_bowl else where[2])
				if where[0] == "at the Gap" and not in_bowl:
					want = t.global_position.z < -200.0 or t.name == "ChalkHeat"  # only the valley's far end
			check(t.visible == want and (t._wisps == null or t._wisps.emitting == want), "%s: %s is %s" % [where[0], t.name, "shown" if want else "hidden"])


## Signs of rising air outdoors: three birds circle just under the top of each thermal (inside
## it, so they mark it), three hang over the ridge, and none of the cues is solid.
func test_birds_mark_the_lift_and_cues_are_not_solid() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var birds := (game.get_node("Course") as Course).get_node("Birds") as Birds
	check(birds.multimesh.instance_count == Course.OUTDOOR_THERMALS.size() * 3 + Course.RIDGE_BIRDS.size() + Course.BLUFF_BIRDS.size(), "3 birds per thermal and the ridge's and bluff's birds")
	for i in Course.OUTDOOR_THERMALS.size() * 3:
		var t: Dictionary = Course.OUTDOOR_THERMALS[i / 3]
		for time in [0.0, 3.3, 11.0]:
			var at := birds.bird_transform(i, time).origin
			check((t["at"] as Vector2).distance_to(Vector2(at.x, at.z)) < float(t["radius"]) * 0.6, "bird %d circles inside %s" % [i, t["name"]])
			check_between(at.y, float(t["top"]) - 6.0, float(t["top"]), "bird %d's height under the top of %s" % [i, t["name"]])
	var space := (game as Node3D).get_world_3d().direct_space_state
	# Rays straight through each cue (rays meet the merged trimesh; point queries would not).
	var sock := Vector3(Course.WINDSOCK.x - 1.0, Course.terrain_height(Course.WINDSOCK.x, Course.WINDSOCK.y) + 4.8, Course.WINDSOCK.y)
	var picnic := Vector3((Course.PICNIC_X.x + Course.PICNIC_X.y) * 0.5, 0.0, (Course.PICNIC_Z.x + Course.PICNIC_Z.y) * 0.5)
	picnic.y = Course.ground_height(picnic.x, picnic.z) + 0.3
	var hay: Vector2 = Course.HAY_FIELD["at"]
	var cloud := Vector3(hay.x, float(Course.HAY_FIELD["top"]) + Course.CLOUD_ABOVE_TOP + 3.0, hay.y)
	for p in [sock, Course.KITE, (Course.KITE + picnic) * 0.5, cloud]:
		var ray := PhysicsRayQueryParameters3D.create(p + Vector3(0.0, 0.0, 6.0), p + Vector3(0.0, 0.0, -6.0))
		ray.collision_mask = Flyer.WORLD_LAYER
		check(space.intersect_ray(ray).is_empty(), "nothing solid at %s (windsock, kite, its string, a cloud)" % p)
	var down := PhysicsRayQueryParameters3D.create(sock, sock + Vector3.DOWN * 10.0)
	down.collision_mask = Flyer.WORLD_LAYER
	check(not space.intersect_ray(down).is_empty(), "(and the same rays do meet the merged grass mesh)")
	var ridge_x := Vector2(Course.RIDGE_LIFT.x - Course.RIDGE_LIFT_SIZE.x * 0.5, Course.RIDGE_LIFT.x + Course.RIDGE_LIFT_SIZE.x * 0.5)
	var first := Course.OUTDOOR_THERMALS.size() * 3
	for i in range(first, first + Course.RIDGE_BIRDS.size()):
		var at := birds.bird_transform(i, 1.0).origin
		check(at.x > ridge_x.x and at.x < ridge_x.y, "ridge bird %d hangs over the ridge's rising air (x %.0f)" % [i, at.x])
	var bluff := (game.get_node("Course") as Course).get_node("BluffLift") as Thermal
	for i in range(first + Course.RIDGE_BIRDS.size(), birds.multimesh.instance_count):
		var at := birds.bird_transform(i, 1.0).origin
		check(bluff.contains(at) and bluff.vertical_air_speed(at, (game.get_node("Plane") as Flyer).tuning) > 0.5, "bluff bird %d hangs in the bluff's rising air (%s)" % [i, at])


## Test pilots fly each outdoor route from the living room (docs/outside-plan.md, section 7):
## the whole chain of thermals (arriving well above the ground at each, and landing a good
## while after the window), the ridge, and over the crest onto the picnic blanket.
func test_outdoor_routes_fly_the_chain_the_ridge_and_the_picnic() -> void:
	for route in ["chain", "ridge", "picnic"]:
		var pilot := Autopilot.new(Autopilot.downstairs_line(route))
		pilot.orbits.assign(Autopilot.route(route)["orbits"])
		var game := _start_downstairs(pilot.fly)
		var plane := game.get_node("Plane") as Flyer
		var arrivals := {}
		plane.entered_thermal.connect(func(z: Thermal) -> void:
			if z.outdoors and not arrivals.has(String(z.name)):
				var p := plane.global_position
				arrivals[String(z.name)] = p.y - Course.terrain_height(p.x, p.z))
		var out_at := -1.0
		var frames := 0
		while not plane.is_ended() and frames < 150 * 60:
			await tree.physics_frame
			frames += 1
			if out_at < 0.0 and game.reached_outside:
				out_at = plane.flight_time
		check(out_at >= 0.0, "%s: flies out of the window" % route)
		var outside := plane.flight_time - out_at
		print("        %s: %.1f s outside, arrivals %s, %s" % [route, outside, arrivals, game.scoring.landing.get("title", "no landing spot")])
		check(not plane.model.crashed and plane.is_ended(), "%s: lands, no crash (at %s)" % [route, plane.global_position])
		match route:
			"chain":
				for name in ["BarnHeat", "FieldHeat", "BonfireSmoke"]:
					check(float(arrivals.get(name, 0.0)) >= 12.0, "chain: arrives at %s at least 12 above the ground (%.1f)" % [name, float(arrivals.get(name, 0.0))])
				check(outside >= 55.0, "chain: lands at least 55 s after the window (%.1f)" % outside)
				check(game.scoring.landing.get("id", "") == "lavender", "chain: and comes home to the lavender")
			"ridge":
				check(arrivals.has("RidgeLift"), "ridge: flies in the ridge's rising air")
				var ridge_run: Array = (game.scoring.moments as Array).filter(func(m: Scoring.Moment) -> bool: return m.id == &"ridge_run")
				check((ridge_run[0] as Scoring.Moment).award > 0, "ridge: and soars along it (the Ridge run style points)")
				check(game.scoring.landing.get("id", "") == "lavender", "ridge: and comes home to the lavender")
			"picnic":
				check(game.scoring.landing.get("id", "") == "picnic", "picnic: lands on the blanket")
		await cleanup()


## A cumulus of four puffs over each thermal, in one draw call; when a thermal's air drifts,
## its cloud and its circling birds move with it by the same amount, and nothing else moves.
func test_clouds_and_birds_follow_their_thermal() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var course := game.get_node("Course") as Course
	var clouds := course.get_node("Clouds") as Clouds
	var birds := course.get_node("Birds") as Birds
	check(clouds.multimesh.instance_count == Course.OUTDOOR_THERMALS.size() * Clouds.PUFFS, "four puffs per thermal")
	for i in clouds.puffs.size():
		var t: Dictionary = Course.OUTDOOR_THERMALS[i / Clouds.PUFFS]
		var at := clouds.puff_transform(i).origin
		check((t["at"] as Vector2).distance_to(Vector2(at.x, at.z)) < float(t["radius"]) * 0.75, "puff %d over %s" % [i, t["name"]])
		check(at.y > float(t["top"]) + Course.CLOUD_ABOVE_TOP, "puff %d above the top of %s" % [i, t["name"]])
	var barn := course.get_node(String(Course.BARN_ROOF["name"])) as Thermal
	var k := Course.OUTDOOR_THERMALS.find(Course.BARN_ROOF)
	var puffs_before := []
	for i in clouds.puffs.size():
		puffs_before.append(clouds.puff_transform(i).origin)
	var birds_before := []
	for i in birds.flock.size():
		birds_before.append(birds.bird_transform(i, 2.0).origin)
	var shift := Vector3(-3.0, 0.0, 0.0)
	barn.drift_offset = shift
	for f in 2:  # process_frame fires before the nodes' _process
		await tree.process_frame
	for i in clouds.puffs.size():
		var want: Vector3 = puffs_before[i] + (shift if i / Clouds.PUFFS == k else Vector3.ZERO)
		check(clouds.puff_transform(i).origin.is_equal_approx(want), "puff %d %s" % [i, "moves with the barn's air" if i / Clouds.PUFFS == k else "stays put"])
	# (The headless test renderer keeps no MultiMesh data, so check the redraw by what it drew from.)
	check(clouds._offsets[k] == shift, "the clouds redrew with the barn's drift")
	for i in birds.flock.size():
		var want: Vector3 = birds_before[i] + (shift if i / 3 == k else Vector3.ZERO)
		check(birds.bird_transform(i, 2.0).origin.is_equal_approx(want), "bird %d %s" % [i, "moves with the barn's air" if i / 3 == k else "stays put"])


## Outdoor columns stay put until the plane first comes near, then drift downwind (-X) at a
## steady speed up to half their radius, with their cloud and birds. The ridge and everything
## indoors never move.
func test_thermals_drift_downwind_once_reached() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var tune := (game.get_node("Plane") as Flyer).tuning
	var course := game.get_node("Course") as Course
	var barn := course.get_node(String(Course.BARN_ROOF["name"])) as Thermal
	var start := barn.position
	var far := Vector3(barn.home.x + barn.radius * 2.0, 20.0, barn.home.z)
	for i in 60:
		barn.drift(1.0 / 60.0, far, tune)
	check(barn.position == start, "two radii away: not drifting yet")
	var near := Vector3(barn.home.x + barn.radius * 1.4, 20.0, barn.home.z)
	for i in 120:
		barn.drift(1.0 / 60.0, near, tune)
	check_between(start.x - barn.position.x, tune.thermal_drift_speed * 2.0 - 0.02, tune.thermal_drift_speed * 2.0 + 0.02, "drift after 2 s (units)")
	check(is_equal_approx(barn.position.z, start.z) and is_equal_approx(barn.position.y, start.y), "only downwind")
	for i in 60 * 60:
		barn.drift(1.0 / 60.0, far * 10.0, tune)
	check_between(start.x - barn.position.x, barn.radius * tune.thermal_drift_max - 0.01, barn.radius * tune.thermal_drift_max + 0.01, "drift stops at half the radius")
	check(barn.drift_offset.is_equal_approx(barn.position - barn.home), "the offset the cloud and birds follow is the same")
	for node in tree.get_nodes_in_group("thermals"):
		var zone := node as Thermal
		check(zone.drifts() == (zone.outdoors and zone.shape == Thermal.Shape.CYLINDER), "%s %s" % [zone.name, "drifts" if zone.drifts() else "stays put"])
	check(not (course.get_node("RidgeLift") as Thermal).drifts(), "the ridge never drifts")


## Circling the barn's warm air from low down while it drifts: a pilot who re-centres on it
## reaches near the top within 12 s and at least 20% faster than one who keeps circling where it
## first was, who still climbs but hears the air slide away. (Entered at y 5, not the plan's 18:
## from 18 the climb is a 3 s zoom.)
func test_re_centring_climbs_a_drifting_thermal_faster() -> void:
	var times := {}
	var sighs := {}
	var barn: Dictionary = Course.BARN_ROOF
	var at: Vector2 = barn["at"]
	var top := float(barn["top"])
	for naive in [false, true]:
		var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
		var plane := game.get_node("Plane") as Flyer
		var pilot := Autopilot.new(PackedVector3Array([Vector3(at.x, 18.0, at.y + 30.0), Vector3(at.x, 18.0, at.y - 30.0)]))
		pilot.orbits.assign([{"centre": at, "zone": barn["name"], "radius": 6.0, "to_y": top - 2.0, "up": true, "max_time": 40.0}])
		pilot.naive_orbits = naive
		plane.autopilot = pilot.fly
		await physics_frames(2)
		plane.launch(Vector3(at.x, 5.0, at.y + 10.0), 0.0)
		var start_y := 5.0
		var reached := INF
		var gained_15 := 0.0
		var frames := 0
		while frames < 60 * 20 and not plane.is_ended():
			await tree.physics_frame
			frames += 1
			if frames == 60 * 15:
				gained_15 = plane.global_position.y - start_y
			if reached == INF and plane.global_position.y >= top - 2.0:
				reached = frames / 60.0
		times[naive] = reached
		sighs[naive] = game.sighs
		if naive:
			check(reached < INF, "the naive pilot still reaches near the top")
			check(gained_15 >= 5.0, "the naive pilot still climbs (%.1f u in 15 s)" % gained_15)
		await cleanup()
	print("        drifting barn: re-centring top in %.1f s (%d sighs), naive %.1f s (%d sighs)" % [times[false], sighs[false], times[true], sighs[true]])
	check(times[false] <= 12.0, "re-centring reaches near the top within 12 s (%.1f)" % times[false])
	check(times[false] <= times[true] * 0.8, "at least 20%% faster than circling the old spot (%.1f vs %.1f s)" % [times[false], times[true]])
	check(sighs[false] == 0, "re-centring never loses the lift (%d sighs)" % sighs[false])
	check(sighs[true] >= 1, "circling the old spot, the pilot hears the air slide away (%d sighs)" % sighs[true])


## Climb to the top of the hay field's air and its cloud shrinks, frays and fades over 8 s;
## the other clouds stay full, and the hay field's lift is just as strong as before.
func test_a_climbed_thermals_cloud_thins() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var plane := game.get_node("Plane") as Flyer
	var tune := plane.tuning
	var course := game.get_node("Course") as Course
	var clouds := course.get_node("Clouds") as Clouds
	var hay := course.get_node(String(Course.HAY_FIELD["name"])) as Thermal
	var full := []
	for i in clouds.puffs.size():
		full.append(clouds.puff_transform(i))
	var lift_before := hay.vertical_air_speed(hay.global_position + Vector3(0.0, 10.0, 0.0), tune)
	var near_top := hay.global_position + Vector3(2.0, hay.top() - hay.global_position.y - 1.0, 0.0)
	clouds.note_plane(hay.global_position + Vector3(hay.radius * 1.2, hay.top() - hay.global_position.y - 1.0, 0.0), true)
	clouds.note_plane(hay.global_position + Vector3(0.0, hay.top() - hay.global_position.y - 4.0, 0.0), true)
	clouds.note_plane(near_top, false)
	check(clouds.thinning[0] < 0.0, "outside the column, not near the top, or gliding over: still a full cloud")
	clouds.note_plane(near_top, true)
	check(clouds.thinning[0] >= 0.0, "near the top inside it: thinning starts")
	for f in int(tune.cloud_thin_seconds * 60.0) + 2:
		await tree.process_frame
	for i in clouds.puffs.size():
		var k: int = clouds.puffs[i]["zone"]
		var now := clouds.puff_transform(i)
		var scale := now.basis.get_scale().x / (full[i] as Transform3D).basis.get_scale().x
		if k == 0:
			check(scale <= 0.6, "hay puff %d has shrunk (%.2f)" % [i, scale])
			var middle := Vector3.ZERO
			for j in Clouds.PUFFS:
				middle += (full[j] as Transform3D).origin / Clouds.PUFFS
			var was := Vector2(full[i].origin.x - middle.x, full[i].origin.z - middle.z).length()
			var spread := Vector2(now.origin.x - middle.x, now.origin.z - middle.z).length()
			check(spread >= was * (tune.cloud_thin_spread - 0.05), "and spread out (%.1f -> %.1f)" % [was, spread])
			check(clouds.puff_color(i).is_equal_approx(Clouds.THIN_COLOR), "and faded toward the sky")
		else:
			check(now == full[i], "puff %d over another thermal is unchanged" % i)
	check(is_equal_approx(hay.vertical_air_speed(hay.global_position + Vector3(0.0, 10.0, 0.0), tune), lift_before), "the lift is unchanged")


## A whole touring flight up the chain: each cloud the pilot climbs to the top of thins.
func test_the_chain_route_thins_each_cloud_it_tops() -> void:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	var plane := game.get_node("Plane") as Flyer
	var pilot := Autopilot.touring("chain")
	plane.autopilot = pilot.fly
	var clouds := (game.get_node("Course") as Course).get_node("Clouds") as Clouds
	var frames := 0
	while not plane.is_ended() and frames < 150 * 60:
		await tree.physics_frame
		frames += 1
	var thinned := []
	for k in clouds.thinning.size():
		if clouds.thinning[k] >= 0.0:
			thinned.append(Course.OUTDOOR_THERMALS[k]["name"])
	var valley_names := Course.VALLEY_THERMALS.map(func(t: Dictionary) -> String: return t["name"])
	print("        chain route thinned: %s" % [thinned])
	check(plane.is_ended(), "the flight finished")
	check(thinned == valley_names, "every cloud the chain climbs thins, and only those (%s)" % [thinned])


## The ridge route: a gull joins about 1.5 s after the pilot starts along the ridge lift, soars
## beside it for about 6 s and leaves, once a run. On every frame of the visit it keeps clear of
## the plane, stays above the hillside and stays out of the middle of the screen.
func test_a_gull_joins_once_along_the_ridge_and_keeps_its_distance() -> void:
	for look in [PlayerSettings.PLANE, PlayerSettings.BALLOON]:
		var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
		var plane := game.get_node("Plane") as Flyer
		plane.set_look(look)
		var tune := plane.tuning
		var pilot := Autopilot.touring("ridge")  # held here: a Callable alone does not keep its object alive
		plane.autopilot = pilot.fly
		var gull := game.gull as Gull
		var camera := game.get_node("Camera") as Camera3D
		var ridge := (game.get_node("Course") as Course).get_node("RidgeLift") as Thermal
		var entered := INF
		var joined := INF
		var leaving := INF
		var joins := [0]  # an array: a lambda captures an int by value
		var bad := []
		gull.joined.connect(func() -> void: joins[0] += 1)
		var frames := 0
		while not plane.is_ended() and frames < 150 * 60:
			await tree.physics_frame
			frames += 1
			var t := plane.flight_time
			if entered == INF and ridge.contains(plane.global_position):
				entered = t
			if joined == INF and gull.state != Gull.State.WAITING:
				joined = t
			if leaving == INF and gull.state == Gull.State.LEAVING:
				leaving = t
			if gull.state == Gull.State.ESCORTING:
				var g := gull.global_position
				var away := g.distance_to(plane.global_position)
				var ground := Course.terrain_height(g.x, g.z)
				var view := -camera.global_basis.z
				var off_centre := rad_to_deg(view.angle_to(g - camera.global_position))
				if away < Gull.NEAREST - 0.01 or g.y < ground + tune.gull_min_ground - 0.6 or off_centre < 15.0:
					bad.append("%.1f s: %.1f away, %.1f over the ground, %.0f° off centre" % [t, away, g.y - ground, off_centre])
		print("        %s: ridge at %.1f s, gull joins %.1f s, leaves %.1f s" % [look, entered, joined, leaving])
		check(joins[0] == 1, "%s: one gull a run (%d)" % [look, joins[0]])
		check_between(joined - entered, tune.gull_wait - 0.1, tune.gull_wait + 3.0, "%s: seconds from the ridge to the gull" % look)
		check_between(leaving - joined, Gull.ARRIVE_SECONDS + tune.gull_stay - 0.5, Gull.ARRIVE_SECONDS + tune.gull_stay + 0.1, "%s: seconds of company" % look)
		check(bad.is_empty(), "%s: the gull keeps clear: %s" % [look, bad.slice(0, 4)])
		await cleanup()


## The lavender route never flies along the ridge, so no gull.
func test_no_gull_off_the_ridge() -> void:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	var plane := game.get_node("Plane") as Flyer
	var pilot := Autopilot.touring("lavender")  # held here: a Callable alone does not keep its object alive
	plane.autopilot = pilot.fly
	var frames := 0
	while not plane.is_ended() and frames < 150 * 60:
		await tree.physics_frame
		frames += 1
	check(game.gull.state == Gull.State.WAITING and not game.gull.visible, "no gull on the lavender route")


## Soaring close along the ridge face, the way ridge lift is flown: the gull's whole visit
## (arriving, soaring and leaving) keeps it clear of the plane and above the grass, whichever
## side it ends up on.
func test_a_gull_keeps_off_the_hillside_on_a_low_pass() -> void:
	for case in [[-30.0, 5.0], [-34.0, 5.0], [-38.0, 4.5], [-42.0, 4.0], [-46.0, 3.0], [-38.0, 3.0]]:
		var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
		var plane := game.get_node("Plane") as Flyer
		plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
		var tune := plane.tuning
		var gull := game.gull as Gull
		await physics_frames(2)
		var x: float = case[0]
		var z := -140.0
		plane.launch(Vector3(x, Course.terrain_height(x, z) + case[1], z), 0.0)
		var lowest := INF
		var nearest := INF
		var came := false
		var frames := 0
		while not (came and not gull.visible) and frames < 20 * 60:
			await tree.physics_frame
			frames += 1
			# Hold the plane on its line: case[1] above the face, heading along the ridge.
			z -= 6.0 / 60.0
			plane.global_position = Vector3(x, Course.terrain_height(x, z) + case[1], z)
			plane.model.position = plane.global_position
			plane.model.velocity = Vector3(0.0, 0.0, -6.0)
			if gull.visible:
				came = true
				var g := gull.global_position
				lowest = minf(lowest, g.y - Course.terrain_height(g.x, g.z))
				nearest = minf(nearest, g.distance_to(plane.global_position))
		var tag := "x %d, %.1f up" % [x, case[1]]
		check(came and not gull.visible, "%s: the gull came and went" % tag)
		check(lowest >= tune.gull_min_ground - 0.05, "%s: never nearer the grass than %.1f (%.2f)" % [tag, tune.gull_min_ground, lowest])
		check(nearest >= Gull.NEAREST - 0.05, "%s: never nearer the plane than %.1f (%.2f)" % [tag, Gull.NEAREST, nearest])
		await cleanup()


## The valley's ground before the Gap was cut (Phase 3), to check the valley didn't move.
static func _phase3_ground(x: float, z: float) -> float:
	var d := maxf(0.0, Course.FAR_Z - Course.WALL - z)
	var h := -1.2 + Course.VALLEY_RISE * d
	h += 0.015 * pow(maxf(0.0, d - 190.0), 2.0)
	h += 0.006 * pow(maxf(0.0, x - 28.0), 2.0)
	h += Course.RIDGE_HEIGHT * smoothstep(-Course.RIDGE_FACE_X.x, -Course.RIDGE_FACE_X.y, -x)
	h += 0.012 * pow(maxf(0.0, -x - 84.0), 2.0)
	h += 0.04 * pow(maxf(0.0, z + 64.0), 2.0) * smoothstep(12.0, 20.0, absf(x))
	var rolls := (1.4 * sin(x * 0.09 + z * 0.045) + 1.0 * sin(x * 0.05 - z * 0.08 + 1.3)) * clampf(d / 25.0, 0.0, 1.0)
	return h + 0.6 * rolls


func test_the_valley_is_unchanged_up_to_the_gap() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var worst := 0.0
	for i in 200:
		var x := rng.randf_range(-126.0, 126.0)
		var z := rng.randf_range(-284.9, -30.0)
		worst = maxf(worst, absf(Course.ground_height(x, z) - _phase3_ground(x, z)))
	check(worst < 0.0001, "valley heights unchanged at 200 points (worst %.5f)" % worst)


## The Gap, the bowl and the lake have the shape the plan measured (smooth curve, ±0.2; the plan's
## table leaves out the bowl's soft rolls, so they are taken off first). The Gap's floor now ends on
## the lake's bed (-1.15, the plan had -1.4 at the shore) so the cut meets the bowl without a step.
func test_the_gap_and_the_bowl_have_their_planned_heights() -> void:
	var table := [
		[6.0, -300.0, 7.5, "Gap floor"], [6.0, -320.0, 11.5, "Gap floor"], [6.0, -334.0, 13.0, "the saddle"],
		[-16.0, -334.0, 21.8, "Gap wall, left"], [26.0, -334.0, 19.6, "Gap wall, right"],
		[6.0, -352.0, 8.9, "Gap floor, lake side"], [6.0, -370.0, 1.8, "Gap floor, lake side (plan 1.5; the floor now ends on the bed)"], [6.0, -385.0, -1.15, "the shore (the lake bed)"],
		[-14.0, -290.0, 5.2, "the chalk pit"], [20.0, -420.0, -1.15, "lake bed"], [-6.0, -424.0, 0.2, "island top"],
		[50.0, -420.0, 0.0, "the beach"],
	]
	for row in table:
		var slack := 0.3 if row[3] == "the beach" else 0.2
		check_between(Course.ground_height(row[0], row[1]), row[2] - slack, row[2] + slack, "%s (%d, %d)" % [row[3], row[0], row[1]])
	var rolling := [[-48.0, -420.0, 0.7, "bluff foot"], [-60.0, -420.0, 8.4, "bluff face"], [-72.0, -420.0, 18.8, "bluff face"],
		[-84.0, -420.0, 24.0, "bluff plateau"], [0.0, -500.0, 21.9, "far rim (lowered in fun review 4)"], [0.0, -525.0, 56.6, "far edge"]]
	for row in rolling:
		var x: float = row[0]
		var z: float = row[1]
		var f := smoothstep(0.0, Course.DOWNS_FALL, Course.CREST_Z - z)
		var rolls := Course._rolls(x, z) * f * smoothstep(1.0, 1.5, Course.lake_reach(x, z)) * (1.0 - smoothstep(40.0, 58.0, x))
		check_between(Course.ground_height(x, z) - rolls, row[2] - 0.2, row[2] + 0.2, "%s (%d, %d), less the rolls" % [row[3], x, z])
	# No step where the Gap's cut meets the valley or the lake's bed.
	for cut_z in [Course.GAP_CUT_Z.x, Course.GAP_CUT_Z.y]:
		for x in range(-40, 51, 2):
			var step := absf(Course.ground_height(x, cut_z + 0.01) - Course.ground_height(x, cut_z - 0.01))
			check(step < 0.02, "no step at the cut's end z %d, x %d (%.3f)" % [cut_z, x, step])
	# Away from the lake and the Gap's channel, the bowl's ground is above the water: no stray ponds.
	for x in range(-120, 121, 3):
		for z in range(-345, -525, -3):
			if Course.lake_reach(x, z) > 1.35 and not (absf(x - Course.GAP_X) < Course.GAP_HALF + 4.0 and z > -400.0):
				if Course.ground_height(x, z) < Course.LAKE_Y + 0.25:
					check(false, "dry ground at (%d, %d) is %.2f" % [x, z, Course.ground_height(x, z)])
	for x in [-123.0, 123.0]:
		check(Course.ground_height(x, -420.0) >= 45.0, "the bowl's side at x %d is high ground" % x)
	for x in range(-100, 101, 10):
		if absf(x - Course.GAP_X) > Course.GAP_HALF + 16.0:
			check(Course.ground_height(x, Course.CREST_Z) >= 30.0, "the Downs at x %d are high (%.1f)" % [x, Course.ground_height(x, Course.CREST_Z)])


## Hands off from the saddle: the plane glides down the far side, over the lake, and comes to rest
## by the far rim, without crashing; and nothing can fly out past the far edge.
func test_a_hands_off_glide_through_the_gap_lands_by_the_far_rim() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var plane := game.get_node("Plane") as Flyer
	plane.launch(Vector3(Course.GAP_X, 22.5, Course.SADDLE.x), 0.0)
	var crashed := [false]
	plane.crashed.connect(func() -> void: crashed[0] = true)
	var frames := 0
	while not plane.is_ended() and frames < 40 * 60:
		await tree.physics_frame
		frames += 1
	print("        from the saddle: rest at z %.1f after %.1f s" % [plane.global_position.z, plane.flight_time])
	check(not crashed[0], "no crash")
	check_between(plane.global_position.z, -484.0, -468.0, "rests at z")  # the plan said -468..-480; it rests at -479.5, and the orchard starts at -488
	check_between(plane.flight_time, 20.0, 27.0, "after (s)")
	plane.launch(Vector3(0.0, 120.0, -515.0), 0.0)
	frames = 0
	while not plane.is_ended() and frames < 10 * 60:
		await tree.physics_frame
		frames += 1
	check(plane.is_ended() and not plane.model.grounded, "past the far edge, the run ends in the air")
	check_between(plane.global_position.z, -527.0, -524.0, "where it ends (z)")


## Glides hands-off from `from` straight toward `to` (plan view): the height on arriving over it,
## or NAN if the run ended first.
func _glide_arrival(plane: Flyer, from: Vector3, to: Vector2) -> float:
	var dir := (to - Vector2(from.x, from.z)).normalized()
	plane.launch(from, atan2(-dir.x, -dir.y))
	var frames := 0
	while frames < 60 * 40 and not plane.is_ended():
		await tree.physics_frame
		frames += 1
		var p := plane.global_position
		if (to - Vector2(p.x, p.z)).dot(dir) <= 0.0:
			return p.y
	return NAN


## The gate to the Gap and what lies beyond, glided straight (plan B2): the chalk pit's warm air
## is reachable from the barn's top and the ploughed field's, the Gap clears from the chalk's top,
## and everything in the bowl is reachable from a normal Gap crossing. (The plan's heights are a
## pure glide; the real flight leaves one column and ends in the next, so it arrives higher.)
func test_the_chalk_pit_and_the_gap_are_within_a_glide() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as Flyer
	await physics_frames(2)
	var chalk: Vector2 = Course.CHALK_HEAT["at"]
	var saddle := Vector2(Course.GAP_X, Course.SADDLE.x)
	var legs := [
		["barn top -> chalk", Course.BARN_ROOF, 0.0, chalk, 13.3],
		["ploughed field top -> chalk", Course.PLOUGHED_FIELD, 0.0, chalk, 21.3],
		["chalk top -> the saddle", Course.CHALK_HEAT, 0.0, saddle, 22.0],
	]
	for leg in legs:
		var t: Dictionary = leg[1]
		var at: Vector2 = t["at"]
		var y := await _glide_arrival(plane, Vector3(at.x, float(t["top"]), at.y), leg[3])
		var ground := Course.ground_height((leg[3] as Vector2).x, (leg[3] as Vector2).y)
		print("        %s: arrives at y %.1f (%.1f above the ground)" % [leg[0], y, y - ground])
		check(y >= float(leg[4]) - 1.5, "%s: arrives at y %.1f, at least the planned %.1f" % [leg[0], y, leg[4]])
	var from_saddle := Vector3(Course.GAP_X, 22.5, Course.SADDLE.x)
	for target in [["the island", Course.ISLAND, 11.2], ["the beach", Vector2(50.0, -425.0), 11.9]]:
		var y := await _glide_arrival(plane, from_saddle, target[1])
		print("        saddle -> %s: arrives at y %.1f" % [target[0], y])
		check(y >= float(target[2]) - 1.5, "saddle -> %s: arrives at y %.1f, at least the planned %.1f" % [target[0], y, target[2]])


## Flying along the bluff face in its lift climbs well, without touching the hillside.
func test_the_bluff_lifts_a_pilot_flying_along_it() -> void:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	var plane := game.get_node("Plane") as Flyer
	var pilot := Autopilot.new(PackedVector3Array([Vector3(-58.0, 32.0, -380.0), Vector3(-58.0, 32.0, -470.0)]))
	plane.autopilot = pilot.fly
	await physics_frames(2)
	plane.launch(Vector3(-50.0, 13.0, -380.0), 0.0)
	var touches := plane.touches
	var top := -INF
	while not plane.is_ended() and plane.global_position.z > -460.0:
		await tree.physics_frame
		top = maxf(top, plane.global_position.y)
	print("        bluff: y %.1f by z -460" % top)
	check(top >= 28.0, "climbs to y 28 or more along the bluff (%.1f)" % top)
	check(plane.touches == touches, "without touching the face")


## Low ticks over the lake, and nowhere else: not in the stair downdraft, not over the grass.
func test_sink_ticks_only_over_the_lake() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as Flyer
	await physics_frames(2)
	plane.launch(Vector3(0.0, 10.0, -398.0), 0.0)
	var beeped := false
	for f in 60 * 4:
		await tree.physics_frame
		beeped = beeped or game.vario.on
	check(game.sink_ticks >= 4, "ticks over the lake at y 10 (%d)" % game.sink_ticks)
	check(not beeped, "and the vario stays quiet over the water")
	var over_lake: int = game.sink_ticks
	plane.launch(Vector3(40.0, 15.0, -130.0), 0.0)  # open grass, in no air
	await physics_frames(60 * 4)
	check(game.sink_ticks == over_lake, "none over the grass")
	plane.launch(Course.DOWNDRAFT_ORIGIN + Vector3(0.0, Course.DOWNDRAFT_SIZE.y * 0.6, 3.0), PI * 0.5)
	await physics_frames(60 * 2)
	check(game.sink_ticks == over_lake, "none in the stair downdraft")
	# Skimming the water while sliding to a stop: quiet; a little higher: ticking.
	for case in [[0.5, false], [2.0, true]]:
		var before: int = game.sink_ticks
		plane.launch(Vector3(0.0, Course.LAKE_Y + case[0], -415.0), 0.0)
		for f in 60 * 2:
			await tree.physics_frame
			plane.global_position = Vector3(0.0, Course.LAKE_Y + case[0], -415.0 - f * 0.1)
			plane.model.position = plane.global_position
			plane.model.velocity = Vector3(0.0, 0.0, -6.0)
		check((game.sink_ticks > before) == case[1], "%.1f over the water: %s (%d ticks)" % [case[0], "ticks" if case[1] else "quiet", game.sink_ticks - before])


## The landmarks past the valley: the windmill's tower, the wall, the huts and the boathouse are
## solid; the sails, sheep, boat, flag and jetty are not. The sails turn, the boat sails round the
## lake clear of the island, and no bowl tree stands in the lift, the water or the way.
func test_the_landmarks_past_the_valley() -> void:
	var game := _start(func(_p: Flyer) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var course := game.get_node("Course") as Course
	var space := (game as Node3D).get_world_3d().direct_space_state
	var solid := func(p: Vector3) -> bool:
		var ray := PhysicsRayQueryParameters3D.create(p + Vector3(6.0, 0.0, 0.0), p - Vector3(6.0, 0.0, 0.0))
		ray.collision_mask = Flyer.WORLD_LAYER
		return not space.intersect_ray(ray).is_empty()
	var mill := CourseFar.WINDMILL
	var mill_y := Course.terrain_height(mill.x, mill.y)
	check(solid.call(Vector3(mill.x, mill_y + 5.0, mill.y)), "the windmill's tower is solid")
	var wall_x := (CourseFar.WALL_X.x + CourseFar.GATE_X.x) * 0.5
	var wall := Vector3(wall_x, Course.terrain_height(wall_x, CourseFar.WALL_Z) + 0.6, CourseFar.WALL_Z)
	var across := PhysicsRayQueryParameters3D.create(wall + Vector3(0.0, 0.0, 3.0), wall - Vector3(0.0, 0.0, 3.0))
	across.collision_mask = Flyer.WORLD_LAYER
	check(not space.intersect_ray(across).is_empty(), "the stone wall is solid")
	for hut in CourseFar.HUTS:
		check(solid.call(Vector3(hut.x, Course.terrain_height(hut.x, hut.y) + 1.2, hut.y)), "the beach hut at %s is solid" % hut)
	var house := CourseFar.BOATHOUSE
	check(solid.call(Vector3(house.x, Course.terrain_height(house.x, house.y) + 1.5, house.y)), "the boathouse is solid")
	var flag := Vector3(CourseFar.FLAG.x - 1.5, Course.terrain_height(CourseFar.FLAG.x, CourseFar.FLAG.y) + 7.4, CourseFar.FLAG.y)
	var jetty := Vector3(house.x, Course.LAKE_Y + 0.25, house.y + CourseFar.BOATHOUSE_SIZE.z * 0.5 + CourseFar.JETTY_LENGTH - 0.5)  # its far end, over the water
	for p in [flag, jetty]:
		check(not solid.call(p), "nothing solid at %s (the flag, the jetty)" % p)
	var sails := course.get_node("WindmillSails") as PropMotion
	var boat := course.get_node("Sailboat") as PropMotion
	var sails_then := sails.transform
	var boat_then := boat.global_position
	for f in 60 * 3:
		await tree.process_frame
	check(not sails.transform.is_equal_approx(sails_then), "the sails turn")
	check((sails.transform.basis * Vector3.RIGHT).normalized().is_equal_approx(CourseFar.WINDMILL_FACING.normalized()), "facing half toward the valley")
	check(boat.global_position.distance_to(boat_then) > 2.0, "the boat sails")
	check(boat.global_basis.y.x < -0.1, "heeled away from the breeze (mast lean %.2f)" % boat.global_basis.y.x)
	for k in 360:  # its whole circle, on open water and clear of the island
		var at := CourseFar.BOAT_CIRCLE + Vector2.from_angle(deg_to_rad(k)) * CourseFar.BOAT_RADIUS
		if Course.lake_reach(at.x, at.y) >= 0.9 or at.distance_to(Course.ISLAND) <= Course.ISLAND_RADIUS + 2.0:
			check(false, "the boat's circle leaves open water at %s" % at)
	var planted := 0
	for z in CourseFar.ORCHARD_Z:
		var x := CourseFar.ORCHARD_X.x
		while x <= CourseFar.ORCHARD_X.y:
			planted += 1 if CourseFar.bowl_tree_allowed(x, z) else 0
			x += CourseFar.ORCHARD_X.z
	for at in CourseFar.PINES:
		planted += 1 if CourseFar.bowl_tree_allowed(at.x, at.y) else 0
	print("        bowl trees: %d" % planted)
	check_between(planted, 18, 34, "bowl trees planted")
	check(not CourseFar.bowl_tree_allowed(Course.GAP_X, -370.0) and not CourseFar.bowl_tree_allowed(0.0, -420.0) and not CourseFar.bowl_tree_allowed(-60.0, -420.0), "none in the Gap's channel, the lake or the bluff's lift")


## Test pilots fly the routes past the valley (docs/phase4-plan.md, B6 and D) from the living
## room: along the ridge and through the Gap onto the island; up the barn, the ploughed field, the
## chalk pit and the beach's warm sand onto the island; and through the Gap, up the bluff and across to the beach.
## Each crosses the Gap low enough to earn its moment, and none crashes.
func test_routes_past_the_valley_land_where_they_aim() -> void:
	for route in [["gap", "island", 1], ["lake", "island", 0], ["bluff", "beach", 2]]:
		var pilot := Autopilot.new(Autopilot.downstairs_line(route[0]))
		pilot.orbits.assign(Autopilot.route(route[0])["orbits"])
		var game := _start_downstairs(pilot.fly)
		var plane := game.get_node("Plane") as Flyer
		var gulls := [0]  # an array: a lambda captures an int by value
		(game.gull as Gull).joined.connect(func() -> void: gulls[0] += 1)
		var frames := 0
		while not plane.is_ended() and frames < 200 * 60:
			await tree.physics_frame
			frames += 1
		var gap: Array = (game.scoring.moments as Array).filter(func(m: Scoring.Moment) -> bool: return m.id == &"gap")
		print("        %s: ended at %.1f s, %s, total %d" % [route[0], plane.flight_time, game.scoring.landing.get("title", "no landing spot"), game.scoring.total()])
		check(not plane.model.crashed and plane.is_ended(), "%s: lands, no crash (at %s)" % [route[0], plane.global_position])
		check(game.crossed_gap and (gap[0] as Scoring.Moment).award > 0, "%s: through the Gap, earning its moment" % route[0])
		check(game.scoring.landing.get("id", "") == route[1], "%s: lands on the %s" % [route[0], route[1]])
		check(gulls[0] == route[2], "%s: a gull joins on each ridge flown along (%d, expected %d)" % [route[0], gulls[0], route[2]])
		await cleanup()
