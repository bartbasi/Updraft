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
	for zone in ["Sunbeam", "RadiatorHeat", "KettleSteam", "MeadowHeat"]:
		check(zones.has(zone), "flies through %s" % zone)
	check(sections.has("stair hall") and sections.has("living room"), "down the stairs into the living room: %s" % [sections])
	check(plane.flight_time >= 60.0, "a well-flown run lasts at least a minute (%.1f s)" % plane.flight_time)


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


## Past the window: warm air over the hay field lifts a plane that turns for it, and gives
## nothing to one that flies straight on down the middle.
func test_meadow_thermal_lifts_those_who_turn_for_it() -> void:
	for setup in [[Course.MEADOW_THERMAL.x, true], [Course.MEADOW_THERMAL.x + Course.MEADOW_THERMAL_RADIUS + 2.0, false]]:
		var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
		var plane := game.get_node("Plane") as PaperPlane
		var start := Vector3(float(setup[0]), 6.5, Course.MEADOW_THERMAL.y + 10.0)
		plane.launch(start, 0.0)
		var entered := [false]
		plane.entered_thermal.connect(func(z: Thermal) -> void: entered[0] = entered[0] or z.name == "MeadowHeat")
		var top := start.y
		var frames := 0
		while plane.global_position.z > Course.MEADOW_THERMAL.y - 8.0 and not plane.is_ended() and frames < 600:
			await tree.physics_frame
			frames += 1
			top = maxf(top, plane.global_position.y)
		var label := "through the meadow thermal" if setup[1] else "straight past it"
		if setup[1]:
			check(entered[0], "%s: the plane meets the warm air" % label)
			check(top > start.y + 2.0, "%s: and climbs (from y %.1f to %.1f)" % [label, start.y, top])
		else:
			check(not entered[0], "%s: no warm air" % label)
			check(top <= start.y + 0.05, "%s: and no climb (from y %.1f to %.1f)" % [label, start.y, top])
		await cleanup()


## From the window out past the meadow the middle of the valley is open: nothing to hit but the
## grass, so a pilot can circle in the thermal and glide on (the designer's numbers: 16 either
## side of the centre line, out to z -240).
func test_valley_is_clear_past_the_meadow() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = PaperPlane.RADIUS
	query.shape = ball
	query.collision_mask = PaperPlane.WORLD_LAYER
	var hits := []
	check(Course.TREE_FREE_HALF_WIDTH >= 16.0 and Course.TREE_FREE_TO_Z <= -240.0, "the tree-free valley is at least as big as the designer asked")
	var z := Course.FAR_Z - Course.WALL - 15.0  # past the garden fence
	while z > -240.0:
		var x := -15.0
		while x <= 15.0:
			for up in [1.0, 3.0, 6.0, 10.0]:
				var at := Vector3(x, Course.ground_height(x, z) + up, z)
				query.transform = Transform3D(Basis.IDENTITY, at)
				if not space.intersect_shape(query, 1).is_empty() and hits.size() < 5:
					hits.append(at)
			x += 2.0
		z -= 2.0
	check(hits.is_empty(), "nothing solid above the grass in the valley: %s" % [hits])


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
	for spot in [Vector2(Course.MEADOW_THERMAL.x, Course.MEADOW_THERMAL.y), Vector2(Course.MEADOW_THERMAL.x + 2.5, Course.MEADOW_THERMAL.y - 3.5), Vector2(stream_x, Course.STREAM_Z + 2.0 * sin(stream_x * 0.12))]:
		var ground := Course.terrain_height(spot.x, spot.y)
		plane.global_position = Vector3(spot.x, ground + 1.6, spot.y)
		plane._update_shadow()
		var shadow: MeshInstance3D = plane._shadow
		check(shadow.visible, "a shadow under the plane at %s" % spot)
		var painted := ground + Course.PAINT_LIFT
		check(shadow.global_position.y > painted + 0.05, "the shadow is above the painted ground at %s (%.3f vs %.3f)" % [spot, shadow.global_position.y, painted])
