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
	print("        ended at %.1f s, %.1f m, %d bumps" % [plane.flight_time, game.distance_meters(), bumps[0]])
	check(not plane.model.crashed, "autopilot should not crash (at %s)" % plane.global_position)
	check(game.reached_outside, "autopilot should fly out of the window")
	check(plane.is_ended() and Course.is_outside(plane.global_position), "flight should end on the grass outside")
	check(thermals[0] >= 2, "both thermals should be flown through (%d)" % thermals[0])
	check_between(plane.flight_time, 22.0, 40.0, "flight time (s)")


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
	for zone in ["Sunbeam", "RadiatorHeat", "KettleSteam"]:
		check(zones.has(zone), "flies through %s" % zone)
	check(sections.has("stair hall") and sections.has("living room"), "down the stairs into the living room: %s" % [sections])
	check(plane.flight_time >= 45.0, "a well-flown run lasts a good while (%.1f s)" % plane.flight_time)


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
