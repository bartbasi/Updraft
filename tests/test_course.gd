extends TestCase
## The demo course in the real scene: layout checks and whole flights.

const MAIN := preload("res://scenes/main.tscn")


func _start(pilot: Callable) -> Node:
	var game := MAIN.instantiate()
	add_node(game)
	(game.get_node("Plane") as PaperPlane).autopilot = pilot
	return game


## Starts a flight of the downstairs part on its own, entering the living room.
func _start_downstairs(pilot: Callable) -> Node:
	var game := _start(pilot)
	var plane := game.get_node("Plane") as PaperPlane
	plane.launch(Course.LIVING_ROOM_ENTRY, 0.0)
	(game.get_node("Camera") as FollowCamera).snap()
	return game


func _fly_until_end(plane: PaperPlane, max_seconds: float) -> void:
	var frames := 0
	while not plane.is_ended() and frames < int(max_seconds * 60.0):
		await tree.physics_frame
		frames += 1


func test_radiator_thermal_is_within_reach_of_the_living_room_line() -> void:
	var gap := absf(Course.RADIATOR_THERMAL.x - Course.LIVING_ROOM_ENTRY.x) - 3.6
	check_between(gap, -1.0, 3.0, "the entry line passes at or just inside the radiator thermal's edge")


func test_scene_has_the_downstairs_thermals() -> void:
	_start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var names := tree.get_nodes_in_group("thermals").map(func(n: Node) -> String: return n.name)
	check(names.has("RadiatorHeat") and names.has("KettleSteam"), "radiator and kettle thermals exist: %s" % [names])


func test_autopilot_flies_the_downstairs_course() -> void:
	var pilot := Autopilot.new(Autopilot.downstairs_line())
	var game := _start_downstairs(pilot.fly)
	var plane := game.get_node("Plane") as PaperPlane
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
	var plane := game.get_node("Plane") as PaperPlane
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
	var game := _start_downstairs(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as PaperPlane
	await _fly_until_end(plane, 60.0)
	print("        hands-off: ended at %.1f s, %s, crashed=%s" % [plane.flight_time, plane.global_position, plane.model.crashed])
	check(plane.is_ended(), "a flight with no input must end on its own")


func test_diving_flight_ends() -> void:
	var game := _start_downstairs(func(_p: PaperPlane) -> Vector2: return Vector2(-1.0, 0.0))
	var plane := game.get_node("Plane") as PaperPlane
	await _fly_until_end(plane, 30.0)
	check(plane.is_ended(), "a nose-dive must end the run")


## Heights here are where non-divers arrive once the stairwell downdraft has pulled them
## down; the header itself must also never crash a level or climbing plane.
func test_a_plane_that_never_dives_glances_down_through_the_arch() -> void:
	for setup in [[13.0, 7.0, 0.0], [15.0, 7.0, 0.0], [17.0, 9.5, 0.0], [13.0, 9.5, 0.0], [12.5, 7.0, 10.0], [14.5, 9.5, 10.0], [16.0, 7.0, 10.0]]:
		var climb_input := 0.3 if float(setup[2]) > 0.0 else 0.0
		var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2(climb_input, 0.0))
		var plane := game.get_node("Plane") as PaperPlane
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
	var plane := game.get_node("Plane") as PaperPlane
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
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var probe := func(at: Vector3) -> bool:
		var query := PhysicsShapeQueryParameters3D.new()
		var ball := SphereShape3D.new()
		ball.radius = PaperPlane.RADIUS
		query.shape = ball
		query.collision_mask = PaperPlane.WORLD_LAYER
		query.transform = Transform3D(Basis.IDENTITY, at)
		return not space.intersect_shape(query).is_empty()
	var wall := Course.STAIR_HALL_MIN.y
	var r := PaperPlane.RADIUS
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
				var steer := func(plane: PaperPlane) -> Vector2:
					var p := plane.global_position
					if not turned[0]:
						turned[0] = p.x < float(turn_x) and plane.model.heading <= 0.05
						return Vector2(climb, bank if p.x < float(turn_x) else 0.0)
					# After the turn: aim for the middle of the bright arch, still never diving.
					var to := Vector3(-0.5, 0.0, Course.BACK_Z) - p
					var error := wrapf(atan2(-to.x, -to.z) - plane.model.heading, -PI, PI)
					return Vector2(climb, clampf(-error * 2.0, -1.0, 1.0))
				var game := _start(steer)
				var plane := game.get_node("Plane") as PaperPlane
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
		[34.0, -268.0, 4.4], [0.0, -320.0, 30.9], [-38.0, -200.0, 6.9], [-46.0, -200.0, 13.1], [-56.0, -200.0, 20.7], [-75.0, -200.0, 24.1]]
	for row: Array in table:
		var h := Course.ground_height(row[0], row[1]) - float(rolls.call(row[0], row[1]))
		check(absf(h - float(row[2])) <= 0.15, "ground at (%.0f, %.0f) is %.2f, planned %.1f" % [row[0], row[1], h, row[2]])
	# Every edge of the world is high ground.
	for x in range(-120, 121, 12):
		check(Course.ground_height(x, -336.0) > 40.0, "the head wall is high at x %d" % x)
	for z in range(-40, -331, -10):
		var low := minf(Course.ground_height(-126.0, z), Course.ground_height(126.0, z))
		check(low > 38.0, "both sides are high at z %d (%.1f)" % [z, low])


## A plane that ignores the warm air outdoors lands after about ten seconds.
func test_a_glide_with_no_lift_lands_in_about_ten_seconds() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	for zone in tree.get_nodes_in_group("thermals"):
		if zone.name == "HayHeat":
			zone.remove_from_group("thermals")
	var plane := game.get_node("Plane") as PaperPlane
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
		var game := _start(func(p: PaperPlane) -> Vector2:
			if not circling or p.global_position.z > hay.y:
				return Vector2.ZERO
			return Vector2(0.0, -roll))  # full bank left once near the middle
		var plane := game.get_node("Plane") as PaperPlane
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
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = PaperPlane.RADIUS
	query.shape = ball
	query.collision_mask = PaperPlane.WORLD_LAYER
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
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2(0.0, -1.0))  # full bank left
	var plane := game.get_node("Plane") as PaperPlane
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
	var game := _start(func(p: PaperPlane) -> Vector2:
		var err := wrapf(atan2(-(-37.0 - p.global_position.x), 8.0) - p.model.heading, -PI, PI)
		return Vector2(0.0, clampf(-err * 2.0, -1.0, 1.0)))
	var plane := game.get_node("Plane") as PaperPlane
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
	ray.collision_mask = PaperPlane.WORLD_LAYER
	check(not space.intersect_ray(ray).is_empty(), "the barn's wall is solid")
	ray = PhysicsRayQueryParameters3D.create(Vector3(Course.BARN.x + 2.0, barn_ground + 20.0, Course.BARN.y), Vector3(Course.BARN.x + 2.0, barn_ground - 1.0, Course.BARN.y))
	ray.collision_mask = PaperPlane.WORLD_LAYER
	var roof := space.intersect_ray(ray)
	check(not roof.is_empty() and (roof["position"] as Vector3).y > barn_ground + Course.BARN_SIZE.y, "the barn's roof is solid, above its walls")
	# Nothing can fly in under the roof, along the barn, at any height up to the ridge.
	var ball := SphereShape3D.new()
	ball.radius = PaperPlane.RADIUS
	for up in [5.5, 6.5, 7.5, 8.0]:
		var sweep := PhysicsShapeQueryParameters3D.new()
		sweep.shape = ball
		sweep.collision_mask = PaperPlane.WORLD_LAYER
		sweep.transform = Transform3D(Basis.IDENTITY, Vector3(Course.BARN.x, barn_ground + up, Course.BARN.y + 8.0))
		sweep.motion = Vector3(0.0, 0.0, -16.0)
		check(space.cast_motion(sweep)[0] < 1.0, "a plane %.1f up meets the barn's gable instead of flying through its attic" % up)
	var fire := Vector3(Course.BONFIRE.x, Course.terrain_height(Course.BONFIRE.x, Course.BONFIRE.y) + 0.5, Course.BONFIRE.y)
	ray = PhysicsRayQueryParameters3D.create(fire + Vector3(0.0, 5.0, 0.0), fire)
	ray.collision_mask = PaperPlane.WORLD_LAYER
	check(space.intersect_ray(ray).is_empty(), "the bonfire is not solid")
	for zone in tree.get_nodes_in_group("thermals"):
		if zone.name == "BonfireSmoke":
			check((zone as Thermal).look == Thermal.Look.STEAM and (zone as Thermal).outdoors, "the bonfire's thermal looks like smoke")


## A plane that somehow leaves the world comes to a stop instead of falling forever.
func test_leaving_the_world_ends_the_run() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2(-1.0, 0.0))
	var plane := game.get_node("Plane") as PaperPlane
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
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var worst := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 60:
		var x := rng.randf_range(-40.0, 40.0)
		var z := rng.randf_range(-105.0, -260.0)
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, 60.0, z), Vector3(x, -20.0, z), PaperPlane.WORLD_LAYER)
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
	check(PaperPlane.SHADOW_LIFT > 0.12 + 0.02, "the shadow sits above the sunbeam's floor glow and the rugs")
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as PaperPlane
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
			var game := _start(func(p: PaperPlane) -> Vector2:
				var goal := Vector3(Course.KETTLE_THERMAL.x, 0.0, Course.KETTLE_THERMAL.z) if p.global_position.z > Course.KETTLE_THERMAL.z else Vector3(0.0, 0.0, Course.FAR_Z - 7.0)
				var to := goal - p.global_position
				return Vector2(0.0, clampf(-wrapf(atan2(-to.x, -to.z) - p.model.heading, -PI, PI) * 2.0, -1.0, 1.0)))
			var plane := game.get_node("Plane") as PaperPlane
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
## outside, outdoor ones until it reaches the kitchen (they show through the window from there).
func test_only_air_zones_in_sight_are_drawn() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as PaperPlane
	var camera := game.get_node("Camera") as FollowCamera
	await physics_frames(3)
	for where in [["bedroom", Course.START, false, true], ["kitchen", Vector3(0.0, 7.0, -70.0), true, true], ["outside", Vector3(0.0, 15.0, -130.0), true, false]]:
		plane.launch(where[1], 0.0)
		camera.snap()
		await physics_frames(3)
		for zone in tree.get_nodes_in_group("thermals"):
			var t := zone as Thermal
			var want: bool = where[2] if t.outdoors else where[3]
			check(t.visible == want and t._wisps.emitting == want, "%s: %s is %s" % [where[0], t.name, "shown" if want else "hidden"])


## Signs of rising air outdoors: three birds circle just under the top of each thermal (inside
## it, so they mark it), three hang over the ridge, and none of the cues is solid.
func test_birds_mark_the_lift_and_cues_are_not_solid() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var birds := (game.get_node("Course") as Course).get_node("Birds") as Birds
	check(birds.multimesh.instance_count == Course.OUTDOOR_THERMALS.size() * 3 + Course.RIDGE_BIRDS.size(), "3 birds per thermal and the ridge's birds")
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
		ray.collision_mask = PaperPlane.WORLD_LAYER
		check(space.intersect_ray(ray).is_empty(), "nothing solid at %s (windsock, kite, its string, a cloud)" % p)
	var down := PhysicsRayQueryParameters3D.create(sock, sock + Vector3.DOWN * 10.0)
	down.collision_mask = PaperPlane.WORLD_LAYER
	check(not space.intersect_ray(down).is_empty(), "(and the same rays do meet the merged grass mesh)")
	var ridge_x := Vector2(Course.RIDGE_LIFT.x - Course.RIDGE_LIFT_SIZE.x * 0.5, Course.RIDGE_LIFT.x + Course.RIDGE_LIFT_SIZE.x * 0.5)
	for i in range(Course.OUTDOOR_THERMALS.size() * 3, birds.multimesh.instance_count):
		var at := birds.bird_transform(i, 1.0).origin
		check(at.x > ridge_x.x and at.x < ridge_x.y, "ridge bird %d hangs over the ridge's rising air (x %.0f)" % [i, at.x])


## Test pilots fly each outdoor route from the living room (docs/outside-plan.md, section 7):
## the whole chain of thermals (arriving well above the ground at each, and landing a good
## while after the window), the ridge, and over the crest onto the picnic blanket.
func test_outdoor_routes_fly_the_chain_the_ridge_and_the_picnic() -> void:
	for route in ["chain", "ridge", "picnic"]:
		var pilot := Autopilot.new(Autopilot.downstairs_line(route))
		pilot.orbits.assign(Autopilot.route(route)["orbits"])
		var game := _start_downstairs(pilot.fly)
		var plane := game.get_node("Plane") as PaperPlane
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
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
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
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var tune := (game.get_node("Plane") as PaperPlane).tuning
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
	check_between(start.x - barn.position.x, 0.25 * 2.0 - 0.02, 0.25 * 2.0 + 0.02, "drift after 2 s (units)")
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
## reaches near the top within 12 s, faster than one who keeps circling where it first was, who
## still climbs. (A climb takes about 8 s, so the air slides only about 2 units: a gentle nudge.
## The plan asked for entry at y 18, 20% faster and sighs telling the pilots apart; from y 18 the
## climb is a 3 s zoom and neither pilot sighs, so this checks the gentler effect; see build-notes.)
func test_re_centring_climbs_a_drifting_thermal_faster() -> void:
	var times := {}
	var sighs := {}
	var barn: Dictionary = Course.BARN_ROOF
	var at: Vector2 = barn["at"]
	var top := float(barn["top"])
	for naive in [false, true]:
		var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
		var plane := game.get_node("Plane") as PaperPlane
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
	check(times[false] <= times[true] * 0.9, "at least 10%% faster than circling the old spot (%.1f vs %.1f s)" % [times[false], times[true]])
	check(sighs[false] == 0, "re-centring never loses the lift (%d sighs)" % sighs[false])


## Climb to the top of the hay field's air and its cloud shrinks, frays and fades over 8 s;
## the other clouds stay full, and the hay field's lift is just as strong as before.
func test_a_climbed_thermals_cloud_thins() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var plane := game.get_node("Plane") as PaperPlane
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
	var plane := game.get_node("Plane") as PaperPlane
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
	print("        chain route thinned: %s" % [thinned])
	check(plane.is_ended(), "the flight finished")
	check(thinned.size() == Course.OUTDOOR_THERMALS.size(), "every cloud the chain climbs thins (%s)" % [thinned])


## The ridge route: a gull joins about 1.5 s after the pilot starts along the ridge lift, soars
## beside it for about 6 s and leaves, once a run. On every frame of the visit it keeps clear of
## the plane, stays above the hillside and stays out of the middle of the screen.
func test_a_gull_joins_once_along_the_ridge_and_keeps_its_distance() -> void:
	for look in [PlayerSettings.PLANE, PlayerSettings.BALLOON]:
		var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
		var plane := game.get_node("Plane") as PaperPlane
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
	var plane := game.get_node("Plane") as PaperPlane
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
		var plane := game.get_node("Plane") as PaperPlane
		plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2.ZERO
		var tune := plane.tuning
		var gull := game.gull as Gull
		await physics_frames(2)
		var x: float = case[0]
		var z := -140.0
		plane.launch(Vector3(x, Course.terrain_height(x, z) + case[1], z), 0.0)
		var lowest := INF
		var nearest := INF
		var frames := 0
		while gull.state != Gull.State.GONE and frames < 20 * 60:
			await tree.physics_frame
			frames += 1
			# Hold the plane on its line: case[1] above the face, heading along the ridge.
			z -= 6.0 / 60.0
			plane.global_position = Vector3(x, Course.terrain_height(x, z) + case[1], z)
			plane.model.position = plane.global_position
			plane.model.velocity = Vector3(0.0, 0.0, -6.0)
			if gull.visible:
				var g := gull.global_position
				lowest = minf(lowest, g.y - Course.terrain_height(g.x, g.z))
				nearest = minf(nearest, g.distance_to(plane.global_position))
		var tag := "x %d, %.1f up" % [x, case[1]]
		check(gull.state == Gull.State.GONE, "%s: the gull came and went" % tag)
		check(lowest >= tune.gull_min_ground - 0.05, "%s: never nearer the grass than %.1f (%.2f)" % [tag, tune.gull_min_ground, lowest])
		check(nearest >= Gull.NEAREST - 0.05, "%s: never nearer the plane than %.1f (%.2f)" % [tag, Gull.NEAREST, nearest])
		await cleanup()
