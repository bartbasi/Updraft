extends TestCase
## The new opening: start in the bedroom, kid's-eye camera, tilt calibration at the throw.

const MAIN := preload("res://scenes/main.tscn")


func _game(pilot := Callable()) -> Node:
	var game := MAIN.instantiate()
	add_node(game)
	if pilot.is_valid():
		(game.get_node("Plane") as PaperPlane).autopilot = pilot
	return game


func _until_released(plane: PaperPlane) -> void:
	var frames := 0
	while plane.held and frames < 600:
		await tree.process_frame
		frames += 1


## Gravity as the phone reports it when its screen is tipped back `back_deg` from upright.
func _gravity(back_deg: float, right_down_deg := 0.0) -> Vector3:
	var b := deg_to_rad(back_deg)
	var r := deg_to_rad(right_down_deg)
	return Vector3(sin(r), -cos(r) * cos(b), -cos(r) * sin(b)) * 9.81


func test_run_starts_in_the_air_in_the_bedroom() -> void:
	var game := _game()
	var plane := game.get_node("Plane") as PaperPlane
	check(plane.held, "the plane waits until the game draws smoothly")
	check(plane.global_position.distance_to(Course.START) < 0.01, "starts at the throw point")
	check(Course.section_at(plane.global_position) == "bedroom", "starts in the bedroom")
	check(plane.global_position.y > Course.UP_FLOOR + 6.0, "starts well up in the air")
	var frames := 0
	while plane.held and frames < 600:
		await tree.process_frame
		frames += 1
	check(frames <= 40, "the plane is thrown within a few frames (%d)" % frames)
	check_between(plane.model.velocity.length(), 6.0, 7.0, "throw speed")
	check(plane.model.velocity.z < -6.0, "thrown toward the door (-Z)")


## Sideways tilt of the camera's view, in degrees.
func _camera_roll(camera: Camera3D) -> float:
	return rad_to_deg(asin(clampf(camera.global_basis.x.y, -1.0, 1.0)))


func test_opening_camera_eases_from_the_kids_eye_into_follow() -> void:
	# The player banks hard right away, so the camera's lean has to ease in too.
	var game := _game(func(_p: PaperPlane) -> Vector2: return Vector2(0.0, 1.0))
	var plane := game.get_node("Plane") as PaperPlane
	var camera := game.get_node("Camera") as FollowCamera
	await tree.process_frame
	check(camera.global_position.distance_to(Course.KID_EYE) < 0.01, "first frame is from the kid's eye (%s)" % camera.global_position)
	var to_plane := (plane.global_position - camera.global_position).normalized()
	check(-camera.global_basis.z.dot(to_plane) > 0.99, "and looks at the plane")
	var last := camera.global_position
	var last_roll := _camera_roll(camera)
	var biggest_step := 0.0
	var biggest_roll_step := 0.0
	var seconds := 1.0 / 60.0  # the first frame has been shown
	var intro_ended_at := -1.0
	var after := 0
	# Watch the whole shot and a few frames past its end, where a lean could snap on.
	while seconds < 3.0 and after < 3:
		await tree.process_frame
		biggest_step = maxf(biggest_step, camera.global_position.distance_to(last))
		biggest_roll_step = maxf(biggest_roll_step, absf(_camera_roll(camera) - last_roll))
		last = camera.global_position
		last_roll = _camera_roll(camera)
		seconds += 1.0 / 60.0
		if not camera.in_intro():
			if intro_ended_at < 0.0:
				intro_ended_at = seconds
			after += 1
	check(intro_ended_at > 0.0 and intro_ended_at <= 1.0, "from the first frame, the camera is in the follow position within a second (%.2f s)" % intro_ended_at)
	check(biggest_step < 0.4, "the move is smooth, no jumps (largest frame step %.2f)" % biggest_step)
	check(biggest_roll_step < 2.0, "the lean eases in, no sudden roll (largest %.1f deg in a frame)" % biggest_roll_step)
	var behind := plane.global_position - plane.model.forward_flat() * plane.tuning.camera_distance
	check(camera.global_position.distance_to(behind) < 2.5, "ends behind the plane (%.1f away)" % camera.global_position.distance_to(behind))


func test_tilt_calibrates_at_the_throw() -> void:
	var game := _game()
	var plane := game.get_node("Plane") as PaperPlane
	# The phone is held at 40 degrees at the moment of the throw, then tipped to 55 straight away.
	# Only calibrating at the throw (not at the first reading afterwards) turns that into a dive.
	var reads := [0]
	plane.read_gravity = func() -> Vector3:
		reads[0] += 1
		return _gravity(40.0) if reads[0] == 1 else _gravity(55.0)
	await _until_released(plane)
	check(plane.controls.is_calibrated(), "the throw records the phone's angle as level")
	await physics_frames(20)
	check(plane.input.x < -0.3, "tipping away from the angle held at the throw dives (%.2f)" % plane.input.x)
	var hold := [_gravity(40.0)]
	plane.read_gravity = func() -> Vector3: return hold[0]
	await physics_frames(20)
	check(absf(plane.input.x) < 0.05 and absf(plane.input.y) < 0.05, "back at the throw angle gives no input (%s)" % plane.input)
	hold[0] = _gravity(40.0, 15.0)  # lower the right edge
	await physics_frames(20)
	check(plane.input.y > 0.3, "lowering the right edge banks right (%.2f)" % plane.input.y)


func test_bedroom_glide_is_clear() -> void:
	var game := _game(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as PaperPlane
	var bumps := [0]
	plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
	await _until_released(plane)
	await physics_frames(int(3.5 * 60))
	check(bumps[0] == 0 and not plane.is_ended(), "nothing to hit on the way to the door")
	check(Course.section_at(plane.global_position) == "bedroom", "still in the bedroom after 3.5 s")
	check_between(plane.global_position.y, 18.0, 21.5, "height approaching the door")
	check(plane.global_position.z < Course.START.z - 18.0, "well on the way to the door (z %.1f)" % plane.global_position.z)


func test_clipping_either_door_post_is_a_bump_not_a_crash() -> void:
	var door := Course.BEDROOM_DOOR_X
	# Fly straight through with the plane's sphere 0.2 units over each jamb line.
	for x in [door.x + PaperPlane.RADIUS - 0.2, door.y - PaperPlane.RADIUS + 0.2]:
		for speed in [6.5, 9.5]:
			var game := _game()
			var plane := game.get_node("Plane") as PaperPlane
			plane.launch(Vector3(x, 19.5, 52.0), 0.0)
			plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2.ZERO
			var bumps := [0]
			plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
			await _until_released(plane)
			plane.model.velocity = Vector3(0.0, 0.0, -speed)
			await physics_frames(90)
			check(bumps[0] >= 1, "x %.1f at %.1f u/s: the plane touches the door post" % [x, speed])
			check(not plane.model.crashed, "x %.1f at %.1f u/s: clipping the edge of the doorway must not crash" % [x, speed])
			await cleanup()


func test_cones_collide_exactly_as_drawn() -> void:
	var game := _game()
	await physics_frames(2)
	var space := (game as Node3D).get_world_3d().direct_space_state
	var probe := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = PaperPlane.RADIUS
	probe.shape = ball
	probe.collision_mask = PaperPlane.WORLD_LAYER
	# The play tent: a six-sided cone 2.2 across at the floor, coming to a point 5.2 up. Probe
	# toward each drawn corner and across the middle of each drawn face.
	var axis := Vector3(105.6, Course.UP_FLOOR, 68.5)
	var sides := 6
	for h in [1.0, 2.5, 4.0]:
		var corner := 2.2 - 2.15 * float(h) / 5.2
		for k in sides * 2:
			var a := TAU * k / (sides * 2)
			var reach := corner if k % 2 == 0 else corner * cos(PI / sides)  # corner, then face
			var dir := Vector3(sin(a), 0.0, cos(a))
			probe.transform = Transform3D(Basis.IDENTITY, axis + Vector3(0.0, h, 0.0) + dir * (reach + PaperPlane.RADIUS + 0.12))
			check(space.intersect_shape(probe).is_empty(), "nothing to hit just outside the tent (height %.1f, %d deg)" % [h, int(rad_to_deg(a))])
			probe.transform = Transform3D(Basis.IDENTITY, axis + Vector3(0.0, h, 0.0) + dir * (reach + PaperPlane.RADIUS - 0.15))
			check(not space.intersect_shape(probe).is_empty(), "but the tent itself is solid (height %.1f, %d deg)" % [h, int(rad_to_deg(a))])


func _flight_through_turn(pilot: Callable, seconds: float) -> Dictionary:
	var game := _game(pilot)
	var plane := game.get_node("Plane") as PaperPlane
	var result := {"bumps": 0, "crashed": false, "turned": false, "plane": plane}
	plane.bumped.connect(func(_s: float) -> void: result["bumps"] += 1)
	await _until_released(plane)
	var frames := 0
	while frames < int(seconds * 60.0) and not plane.is_ended():
		await tree.physics_frame
		frames += 1
		if plane.global_position.x < 85.0 and plane.global_position.z < Course.GALLERY_Z.y:
			result["turned"] = true
			break
	result["crashed"] = plane.model.crashed
	return result


func test_scripted_turn_clears_the_doorway() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var r := await _flight_through_turn(pilot.fly, 12.0)
	check(r["turned"], "the good line makes the turn into the gallery")
	check(r["bumps"] == 0 and not r["crashed"], "without touching anything (%d bumps)" % r["bumps"])


func test_flying_straight_on_ends_at_the_landing_wall() -> void:
	var r := await _flight_through_turn(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO, 15.0)
	var plane: PaperPlane = r["plane"]
	check(not r["turned"], "no input means no turn")
	check(plane.is_ended() and plane.model.crashed, "the run ends at the landing wall instead of getting stuck")
	check(absf(plane.global_position.z - (Course.LANDING_SOUTH_Z + PaperPlane.RADIUS)) < 0.2, "right at the landing's wall (z %.2f)" % plane.global_position.z)


func test_most_first_time_pilots_make_the_turn() -> void:
	var made_it := 0
	var runs := 20
	for i in runs:
		var pilot := Autopilot.novice(Autopilot.course_line(), i + 100)
		var r := await _flight_through_turn(pilot.fly, 12.0)
		if r["turned"] and not r["crashed"]:
			made_it += 1
		await cleanup()
	print("        novices through the turn: %d/%d" % [made_it, runs])
	check(made_it >= int(runs * 0.6), "a first-time player gets through the door turn most of the time (%d/%d)" % [made_it, runs])


func _probe(game: Node, at: Vector3) -> bool:
	var space := (game as Node3D).get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = PaperPlane.RADIUS
	query.shape = ball
	query.collision_mask = PaperPlane.WORLD_LAYER
	query.transform = Transform3D(Basis.IDENTITY, at)
	return not space.intersect_shape(query).is_empty()


func test_taper_wall_collides_exactly_as_drawn() -> void:
	var game := _game()
	await physics_frames(2)
	var a := Course.TAPER_FROM
	var b := Course.TAPER_TO
	var dir := Vector2(b.x - a.x, b.y - a.y).normalized()
	var inward := Vector3(dir.y, 0.0, -dir.x)
	if inward.z < 0.0:
		inward = -inward
	for i in range(1, 10):
		var on_line := Vector3(lerpf(a.x, b.x, i / 10.0), 0.0, lerpf(a.y, b.y, i / 10.0))
		for y in [14.0, 19.0, 24.0]:
			var face := on_line + Vector3(0.0, y, 0.0)
			check(not _probe(game, face + inward * (PaperPlane.RADIUS + 0.06)), "clear just in front of the taper at %s" % [face])
			check(_probe(game, face + inward * (PaperPlane.RADIUS - 0.1)), "solid at the taper's face at %s" % [face])


func test_north_wall_has_no_gaps() -> void:
	var game := _game()
	await physics_frames(2)
	var x := Course.STAIR_HALL_MAX.x + 0.5
	while x < Course.LANDING_EAST_X:
		var in_door := x > Course.BEDROOM_DOOR_X.x - 1.0 and x < Course.BEDROOM_DOOR_X.y + 1.0
		if not in_door:
			for y in [14.0, 19.5, 25.0]:
				check(_probe(game, Vector3(x, y, Course.GALLERY_Z.y + 0.05)), "the north wall is solid at x %.1f, y %.1f" % [x, y])
		x += 1.0


func test_late_turns_scrape_the_taper_but_do_not_crash() -> void:
	# Late turners: half bank starting after the door, or full bank starting later still.
	for setup in [[0.5, 46.0, 6.5], [0.5, 44.0, 6.5], [1.0, 40.0, 6.5], [0.5, 46.0, 9.0]]:
		var bank: float = setup[0]
		var start_z: float = setup[1]
		var speed: float = setup[2]
		var game := _game(func(p: PaperPlane) -> Vector2: return Vector2(0.0, -bank if p.global_position.z < start_z and p.model.heading < PI / 2.0 - 0.05 else 0.0))
		var plane := game.get_node("Plane") as PaperPlane
		plane.launch(Vector3(100.0, 19.5, 52.0), 0.0)  # near the door, so the speed is the speed at the turn
		var taper_bumps := [0]
		plane.bumped.connect(func(_s: float) -> void:
			if plane.global_position.x < Course.TAPER_FROM.x + 0.5:
				taper_bumps[0] += 1)
		await _until_released(plane)
		plane.model.velocity = Vector3(0.0, 0.0, -speed)
		var through := false
		var frames := 0
		while frames < 600 and not plane.is_ended():
			await tree.physics_frame
			frames += 1
			if plane.global_position.x < 85.0:
				through = true
				break
		var label := "bank %.1f from z < %.0f at %.1f u/s" % [bank, start_z, speed]
		check(taper_bumps[0] >= 1, "%s: scrapes the angled wall (%d bumps)" % [label, taper_bumps[0]])
		check(not plane.model.crashed and through, "%s: and carries on into the gallery" % label)
		await cleanup()


## The late pilot's lag makes it weave after the turn; some of those weaves end on the angled
## wall in the sunbeam (see docs/build-notes.md). This test is about the door turn itself:
## "made it" means through the door and banked round into the gallery direction.
func test_late_first_time_pilots_mostly_make_the_turn() -> void:
	var made_it := 0
	var scraped := 0
	var runs := 20
	for i in runs:
		var pilot := Autopilot.late_novice(Autopilot.course_line(), i + 300)
		var r := await _flight_through_turn(pilot.fly, 15.0)
		# Made it = didn't crash: through the turn, or still flying after a scrape when time ran out.
		if not r["crashed"] and (r["turned"] or not (r["plane"] as PaperPlane).is_ended()):
			made_it += 1
		if int(r["bumps"]) > 0:
			scraped += 1
		await cleanup()
	print("        late first-timers through the turn: %d/%d (%d scraped a wall)" % [made_it, runs, scraped])
	check(made_it >= int(runs * 0.6), "late first-time players still get through most of the time (%d/%d)" % [made_it, runs])
	check(scraped >= 2, "and some of them really are late (%d scraped a wall)" % scraped)


func test_sunbeam_is_the_first_lift_within_six_seconds_and_lifts_the_plane() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := _game(pilot.fly)
	var plane := game.get_node("Plane") as PaperPlane
	var entered := [-1.0, 0.0]
	plane.entered_thermal.connect(func(z: Thermal) -> void:
		if entered[0] < 0.0:
			entered[0] = plane.flight_time
			entered[1] = plane.global_position.y
			check(z.name == "Sunbeam", "the first lift is the sunbeam, not %s" % z.name))
	await _until_released(plane)
	var top := 0.0
	var climb := 0.0
	while plane.flight_time < 12.0 and not plane.is_ended() and plane.global_position.x > 76.0:
		await tree.physics_frame
		top = maxf(top, plane.global_position.y)
		if entered[0] > 0.0:
			climb = maxf(climb, plane.model.velocity.y)
	print("        sunbeam at %.1f s, y %.1f -> %.1f, climbing at up to %.1f u/s" % [entered[0], entered[1], top, climb])
	check(entered[0] > 0.0 and entered[0] <= 6.5, "the sunbeam is reached within about 6 s (%.1f)" % entered[0])
	check(top >= entered[1] + 4.0, "the sunbeam lifts the plane well (+%.1f)" % (top - entered[1]))
	check(climb >= 3.0, "with a real lift, not a drift (peak climb %.1f u/s)" % climb)
	check(not plane.is_ended(), "and the plane carries on")


func test_sunbeam_light_and_motes_lean_with_the_sun() -> void:
	var game := _game()
	var beam := game.get_node("Course/Sunbeam") as Thermal
	var sun := Course.SUNBEAM_SUN.normalized()
	check(beam.sun_direction.is_equal_approx(Course.SUNBEAM_SUN), "the sunbeam has the course's sun direction")
	var lean := -sun * (beam.size.y / -sun.y)
	var shaft: MeshInstance3D = null
	var motes: CPUParticles3D = null
	for child in beam.get_children():
		if child is MeshInstance3D:
			shaft = child
		elif child is CPUParticles3D:
			motes = child
	check(shaft != null and motes != null, "the sunbeam has a light shaft and motes")
	if shaft == null or motes == null:
		return
	var arrays := shaft.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var floor_corners := []
	for i in verts.size():
		if uvs[i].y < 0.5 and not floor_corners.any(func(c: Vector3) -> bool: return c.is_equal_approx(verts[i])):
			floor_corners.append(verts[i])
	var top_corners := []
	for i in verts.size():
		if uvs[i].y > 0.5 and not top_corners.any(func(c: Vector3) -> bool: return c.is_equal_approx(verts[i])):
			top_corners.append(verts[i])
	check(floor_corners.size() == 4 and top_corners.size() == 4, "the shaft runs from four floor corners to four top corners")
	for corner in floor_corners:
		var up: Vector3 = corner + lean
		check(top_corners.any(func(c: Vector3) -> bool: return c.distance_to(up) < 0.01), "every floor corner has its top corner straight up the light (%s)" % [corner])
	check(motes.direction.is_equal_approx(-sun), "the motes rise along the light (%s)" % [motes.direction])


func test_gallery_is_a_clear_glide_with_a_skylight_top_up() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := _game(pilot.fly)
	var plane := game.get_node("Plane") as PaperPlane
	var bumps := [0]
	plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
	var zones := []
	plane.entered_thermal.connect(func(z: Thermal) -> void: zones.append(String(z.name)))
	await _until_released(plane)
	var entered_gallery := -1.0
	while plane.flight_time < 40.0 and not plane.is_ended() and plane.global_position.x > Course.STAIR_HALL_MAX.x + 1.0:
		await tree.physics_frame
		if entered_gallery < 0.0 and plane.global_position.x < Course.TAPER_TO.x:
			entered_gallery = plane.flight_time
	var gallery_time := plane.flight_time - entered_gallery
	print("        gallery: %.1f s from x %.0f to %.0f, zones %s, height %.1f at the stairs" % [gallery_time, Course.TAPER_TO.x, Course.STAIR_HALL_MAX.x, zones, plane.global_position.y])
	check(bumps[0] == 0 and not plane.is_ended(), "the good line glides the whole gallery untouched")
	check(zones.has("Skylight"), "and catches the skylight on the way")
	check_between(gallery_time, 8.0, 16.0, "seconds to glide the gallery")
	check(plane.global_position.y > Course.UP_FLOOR + 5.0, "arriving at the stairs with height to dive (y %.1f)" % plane.global_position.y)


func test_gallery_walls_floor_and_ceiling_are_solid_and_the_corridor_is_clear() -> void:
	var game := _game()
	await physics_frames(2)
	var gz := Course.GALLERY_Z
	var x := Course.STAIR_HALL_MAX.x + 0.5
	while x < Course.TAPER_TO.x:
		for y in [14.0, 19.5, 25.0]:
			check(_probe(game, Vector3(x, y, gz.x - 0.05)), "the south wall is solid at x %.1f, y %.1f" % [x, y])
		check(_probe(game, Vector3(x, Course.UP_FLOOR + 0.25, 41.5)), "the floor is solid at x %.1f" % x)
		check(not _probe(game, Vector3(x, Course.UP_FLOOR + 0.4, 41.5)), "and nothing lies on it at x %.1f" % x)
		check(_probe(game, Vector3(x, Course.UP_CEILING - 0.25, 41.5)), "the ceiling is solid at x %.1f" % x)
		x += 1.0
	# Nothing solid anywhere in the flying space above the furniture.
	var clear := [
		[Vector3(Course.STAIR_HALL_MAX.x + 0.5, 16.3, gz.x + 0.3), Vector3(Course.TAPER_TO.x, 26.2, 43.8)],
		[Vector3(Course.STAIR_HALL_MAX.x + 0.5, 16.3, 43.8), Vector3(26.0, 26.2, gz.y - 0.3)],
		[Vector3(34.0, 16.3, 43.8), Vector3(Course.TAPER_TO.x, 26.2, gz.y - 0.3)],
	]
	for region in clear:
		check(not _box_hits(game, region[0], region[1]), "nothing protrudes into the gallery between %s and %s" % [region[0], region[1]])


func _box_hits(game: Node, lo: Vector3, hi: Vector3) -> bool:
	var space := (game as Node3D).get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = hi - lo
	query.shape = box
	query.collision_mask = PaperPlane.WORLD_LAYER
	query.transform = Transform3D(Basis.IDENTITY, (lo + hi) * 0.5)
	return not space.intersect_shape(query).is_empty()


func test_skylight_tops_up_a_level_glide() -> void:
	var heights := []
	for with_skylight in [true, false]:
		var game := _game(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
		var plane := game.get_node("Plane") as PaperPlane
		if not with_skylight:
			(game.get_node("Course/Skylight") as Thermal).remove_from_group("thermals")
		plane.launch(Vector3(56.0, 20.6, 39.5), PI / 2.0)  # heading -X along the skylight side
		await _until_released(plane)
		var start := plane.global_position.y
		while plane.global_position.x > 38.0 and not plane.is_ended():
			await tree.physics_frame
		heights.append(plane.global_position.y - start)
		await cleanup()
	print("        skylight: %+.1f with it, %+.1f without" % [heights[0], heights[1]])
	check(heights[0] >= 1.0, "a level glide gains height under the skylight (%+.1f)" % heights[0])
	check(heights[0] > heights[1] + 1.5, "much more than without it (%+.1f vs %+.1f)" % [heights[0], heights[1]])


## Height of the stairs' collision ramps under a point, or -INF if not over a flight.
func _stair_surface(p: Vector3) -> float:
	var lo := Course.STAIR_HALL_MIN
	var hi := Course.STAIR_HALL_MAX
	var gz := Course.GALLERY_Z
	if p.z > gz.x and p.z < gz.y and p.x > Course.FLIGHT1_BOTTOM_X and p.x < hi.x:
		return Course.STAIR_LANDING_Y + (Course.UP_FLOOR - Course.STAIR_LANDING_Y) * (p.x - Course.FLIGHT1_BOTTOM_X) / (hi.x - Course.FLIGHT1_BOTTOM_X)
	if p.x > lo.x and p.x < Course.FLIGHT1_BOTTOM_X and p.z > gz.x:
		return Course.STAIR_LANDING_Y
	if p.x > lo.x and p.x < Course.FLIGHT1_BOTTOM_X and p.z > Course.FLIGHT2_BOTTOM_Z and p.z < gz.x:
		return Course.STAIR_LANDING_Y * (p.z - Course.FLIGHT2_BOTTOM_Z) / (gz.x - Course.FLIGHT2_BOTTOM_Z)
	return -INF


## Flies the stairs with `pilot` and checks every tick that the plane never sinks into the
## steps, slips through a banister or leaves the stair hall through a wall.
func _fly_stairs(pilot: Callable, stop_at_bottom := true) -> Dictionary:
	var game := _game()
	var plane := game.get_node("Plane") as PaperPlane
	plane.launch(Vector3(24.0, 20.5, 41.5), PI / 2.0)  # in the gallery, heading -X
	plane.autopilot = pilot
	var out := {"clipped": "", "bumps": 0, "crashed": false, "max_speed": 0.0, "reached_bottom": false}
	plane.bumped.connect(func(_s: float) -> void: out["bumps"] += 1)
	await _until_released(plane)
	var lo := Course.STAIR_HALL_MIN
	var hi := Course.STAIR_HALL_MAX
	var rail_z := Course.GALLERY_Z.x
	var last := plane.global_position
	while plane.flight_time < 12.0 and not plane.is_ended():
		await tree.physics_frame
		var p := plane.global_position
		out["max_speed"] = maxf(out["max_speed"], plane.model.velocity.length())
		if p.y < _stair_surface(p) + PaperPlane.RADIUS - 0.05 and out["clipped"] == "":
			out["clipped"] = "into the stairs at %s" % p
		# Crossing the flight 1 banister's line below its handrail means passing through it.
		var rail_top := _stair_surface(Vector3(p.x, 0.0, rail_z + 0.1)) + Course.RAIL_HEIGHT
		if last.z > rail_z and p.z <= rail_z and p.x > Course.FLIGHT1_BOTTOM_X and p.y < rail_top and out["clipped"] == "":
			out["clipped"] = "through the flight 1 banister at %s" % p
		last = p
		var past_east := p.x > hi.x - PaperPlane.RADIUS + 0.05 and p.z < Course.GALLERY_Z.x
		if (p.x < lo.x + PaperPlane.RADIUS - 0.05 or p.z > hi.y - PaperPlane.RADIUS + 0.05 or past_east) and out["clipped"] == "":
			out["clipped"] = "through a wall at %s" % p
		if p.z < Course.FLIGHT2_BOTTOM_Z:
			out["reached_bottom"] = true
			if stop_at_bottom:
				break
	out["crashed"] = plane.model.crashed
	return out


func test_stair_dive_and_landing_turn_on_the_good_line() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var r := await _fly_stairs(pilot.fly)
	print("        good line: top speed %.1f, %d bumps" % [r["max_speed"], r["bumps"]])
	check(r["reached_bottom"] and not r["crashed"], "the good line makes it down both flights")
	check(r["clipped"] == "", "never inside the stairs, banisters or walls: %s" % r["clipped"])
	check(r["max_speed"] > 8.5, "the stair dive builds real speed (%.1f)" % r["max_speed"])


func test_hard_dives_down_the_stairs_never_clip_through() -> void:
	for dive in [-0.6, -0.8, -1.0]:
		for turn_at in [12.0, 6.0, 2.0]:
			var steer := func(plane: PaperPlane) -> Vector2:
				var p := plane.global_position
				var roll := 1.0 if p.x < turn_at and plane.model.heading > 0.05 else 0.0
				return Vector2(dive if p.x < 18.0 else 0.0, roll)
			var r := await _fly_stairs(steer)
			check(r["clipped"] == "", "dive %.1f, turn at x %.0f: %s" % [dive, turn_at, r["clipped"]])
			await cleanup()


func test_full_speed_hits_never_tunnel_through_thin_parts() -> void:
	var t := Tuning.new()
	# Shots at top speed into the thinnest solid parts: [start, direction].
	var shots := [
		[Vector3(9.0, 11.5, 30.0), Vector3(0, 0, 1)],  # into the flight 1 banister board (z 37)
		[Vector3(9.0, 5.5, 30.0), Vector3(-1, 0, 0)],  # from the well into the flight 2 banister board (x 1.5)
		[Vector3(9.0, 13.0, 41.5), Vector3(-0.5, -1.0, 0.0)],  # diving steeply into flight 1's steps
		[Vector3(-3.0, 4.5, 30.0), Vector3(0.0, -1.0, 0.3)],  # diving into flight 2's steps
		[Vector3(9.0, 5.5, 30.0), Vector3(0, 0, 1)],  # from the well into the side of flight 1
	]
	for shot in shots:
		var game := _game()
		var plane := game.get_node("Plane") as PaperPlane
		var dir: Vector3 = (shot[1] as Vector3).normalized()
		plane.launch(shot[0], atan2(-dir.x, -dir.z))
		plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2.ZERO
		var touched := [false]
		plane.bumped.connect(func(_s: float) -> void: touched[0] = true)
		plane.crashed.connect(func() -> void: touched[0] = true)
		await _until_released(plane)
		# No lift or drag: the plane flies like a thrown stone, straight at the part.
		plane.tuning.lift = 0.0
		plane.tuning.drag = 0.0
		plane.global_position = shot[0]
		plane.model.velocity = dir * t.max_speed
		var start := plane.global_position
		var lowest_gap := INF
		for i in 40:
			await tree.physics_frame
			var p := plane.global_position
			lowest_gap = minf(lowest_gap, p.y - _stair_surface(p))
		var end := plane.global_position
		check(touched[0], "a full-speed shot from %s should hit something" % [start])
		check(lowest_gap > PaperPlane.RADIUS - 0.05, "never sinks into the stairs (gap %.2f)" % lowest_gap)
		var dir_v: Vector3 = shot[1]
		if dir_v.z > 0.9:
			check(end.z < Course.GALLERY_Z.x, "no tunnelling into flight 1 from the well (z %.2f)" % end.z)
		if dir_v.x < -0.9:
			check(end.x > Course.FLIGHT1_BOTTOM_X, "no tunnelling through the flight 2 banister (x %.2f)" % end.x)
		await cleanup()


func test_the_stairs_are_solid_underneath_and_banisters_have_upright_ends() -> void:
	var game := _game()
	await physics_frames(2)
	var gz := Course.GALLERY_Z
	var r := PaperPlane.RADIUS
	# Just inside each face of the stairs that faces the well: solid all the way down.
	var x := Course.FLIGHT1_BOTTOM_X + 0.6
	while x < Course.STAIR_HALL_MAX.x - 0.4:
		var surface := _stair_surface(Vector3(x, 0.0, gz.x + 0.5))
		var y := 0.5
		while y < surface - 0.5:
			check(_probe(game, Vector3(x, y, gz.x + r - 0.1)), "flight 1 is solid underneath at x %.1f, y %.1f" % [x, y])
			y += 1.0
		x += 1.5
	var z := Course.FLIGHT2_BOTTOM_Z + 0.6
	while z < gz.x - 0.4:
		var surface := _stair_surface(Vector3(0.0, 0.0, z))
		var y := 0.5
		while y < surface - 0.5:
			check(_probe(game, Vector3(Course.FLIGHT1_BOTTOM_X - r + 0.1, y, z)), "flight 2 is solid underneath at z %.1f, y %.1f" % [z, y])
			y += 1.0
		z += 1.5
	# The banister boards are upright at their ends: no notch by the top newels, and no
	# invisible wedge beyond the landing newel.
	check(_probe(game, Vector3(15.8, 15.3, gz.x)), "the top of flight 1's banister is solid up to the rail")
	check(_probe(game, Vector3(Course.FLIGHT1_BOTTOM_X, 9.2, gz.x - 0.7)), "the top of flight 2's banister is solid up to the rail")
	check(not _probe(game, Vector3(0.5, 9.25, gz.x)), "nothing invisible beyond the landing newel")
	check(not _probe(game, Vector3(Course.FLIGHT1_BOTTOM_X, 2.5, Course.FLIGHT2_BOTTOM_Z - 1.1)), "nothing invisible beyond the bottom newel")


func test_newel_balls_are_solid() -> void:
	var t := Tuning.new()
	var game := _game()
	var plane := game.get_node("Plane") as PaperPlane
	# Just above the banister's top, so only the landing newel's ball can be hit.
	var newel := Vector3(Course.FLIGHT1_BOTTOM_X, 0.0, Course.GALLERY_Z.x)
	plane.launch(Vector3(newel.x, 11.2, newel.z + 3.0), 0.0)
	plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2.ZERO
	var hit_at := [Vector3.INF]
	plane.bumped.connect(func(_s: float) -> void: hit_at[0] = plane.global_position)
	plane.crashed.connect(func() -> void: hit_at[0] = plane.global_position)
	await _until_released(plane)
	plane.tuning.lift = 0.0
	plane.global_position = Vector3(newel.x, 11.2, newel.z + 3.0)
	plane.model.velocity = Vector3(0.0, 0.0, -t.max_speed)
	await physics_frames(20)
	var p: Vector3 = hit_at[0]
	check(p != Vector3.INF, "the shot hits the newel's ball")
	if p != Vector3.INF:
		check(Vector2(p.x - newel.x, p.z - newel.z).length() < 0.75, "right at the newel (%s)" % [p])


func test_over_turning_in_the_well_never_clips_into_the_stairs() -> void:
	# A novice who keeps the bank on after the landing circles round in the stair hall.
	for dive in [-0.3, -0.6]:
		for turn_from in [10.0, 6.0]:
			var banking := [false]  # once the bank goes on, it stays on
			var steer := func(plane: PaperPlane) -> Vector2:
				banking[0] = banking[0] or plane.global_position.x < turn_from
				return Vector2(dive if plane.global_position.x < 18.0 else 0.0, 1.0 if banking[0] else 0.0)
			var r := await _fly_stairs(steer, false)  # keep circling until the run ends
			check(r["clipped"] == "", "dive %.1f, full right bank from x %.0f: %s" % [dive, turn_from, r["clipped"]])
			await cleanup()


func test_stairwell_downdraft_pushes_the_plane_down() -> void:
	var heights := []
	var speeds := []
	for with_downdraft in [true, false]:
		var game := _game()
		var plane := game.get_node("Plane") as PaperPlane
		if not with_downdraft:
			var zone := game.get_node("Course/StairDowndraft") as Thermal
			zone.remove_from_group("thermals")
		plane.launch(Vector3(19.0, 21.0, 41.5), PI / 2.0)
		plane.autopilot = func(_p: PaperPlane) -> Vector2: return Vector2(-0.3, 0.0)
		var sinks := [0]
		var heard := []
		plane.entered_thermal.connect(func(z: Thermal) -> void:
			if z.sinks:
				sinks[0] += 1
				heard.append([game._downdraft.playing, game._chime.playing]))
		await _until_released(plane)
		while plane.global_position.x > 8.0 and not plane.is_ended():
			await tree.physics_frame
		var label := "with the downdraft" if with_downdraft else "without it"
		check(not plane.is_ended(), "%s, the plane is still flying at the bottom of flight 1 (%s)" % [label, plane.global_position])
		heights.append(plane.global_position.y)
		speeds.append(plane.model.velocity.length())
		if with_downdraft:
			check(sinks[0] == 1, "the downdraft is announced once (%d)" % sinks[0])
			check(heard.size() == 1 and heard[0][0] and not heard[0][1], "with its own sound, not the thermal chime (downdraft, chime playing: %s)" % [heard])
		await cleanup()
	print("        bottom of flight 1: y %.1f at %.1f u/s with the downdraft, y %.1f at %.1f u/s without" % [heights[0], speeds[0], heights[1], speeds[1]])
	check(heights[0] < heights[1] - 1.5, "the downdraft pulls the plane down the stairs (y %.1f vs %.1f without)" % [heights[0], heights[1]])
	check(speeds[0] > speeds[1] + 0.2, "and adds speed to the dive (%.1f vs %.1f u/s without)" % [speeds[0], speeds[1]])


## Climbing in warm air, the camera rises with the plane and looks down on it (not edge-on), and
## motes near the camera fade away (fun review 2, item 2).
func test_camera_looks_down_on_the_plane_in_rising_air() -> void:
	var game := _game(func(p: PaperPlane) -> Vector2:
		var to := Vector3(Course.RADIATOR_THERMAL.x, 0.0, Course.RADIATOR_THERMAL.z - 6.0) - p.global_position
		return Vector2(0.2, clampf(-wrapf(atan2(-to.x, -to.z) - p.model.heading, -PI, PI) * 2.0, -1.0, 1.0)))
	var plane := game.get_node("Plane") as PaperPlane
	var camera := game.get_node("Camera") as FollowCamera
	plane.launch(Vector3(Course.RADIATOR_THERMAL.x, 6.5, Course.RADIATOR_THERMAL.z + 8.0), 0.0)
	camera.snap()
	await _until_released(plane)
	var lowest := 90.0  # the shallowest the camera looks down on the plane while it climbs
	var climbing := 0
	var frames := 0
	while frames < 60 * 4 and not plane.is_ended():
		await tree.process_frame
		frames += 1
		if plane.model.velocity.y > 2.0:
			climbing += 1
			var to_plane := plane.global_position - camera.global_position
			lowest = minf(lowest, rad_to_deg(asin(-to_plane.normalized().y)))
	check(climbing > 20, "the plane climbs in the radiator's warm air (%d frames)" % climbing)
	check(lowest >= 5.0, "and the camera keeps looking down on it, never edge-on (at least %.1f degrees)" % lowest)
	var zones := _nodes_in_group_under(game, "thermals")
	check(zones.size() >= 6, "every air zone is checked (%d)" % zones.size())
	for zone in zones:
		for child in zone.get_children():
			if child is CPUParticles3D:
				var mat := ((child as CPUParticles3D).mesh as QuadMesh).material as StandardMaterial3D
				check(mat.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA and mat.distance_fade_min_distance < mat.distance_fade_max_distance,
					"%s: its motes fade out as they come close to the camera" % zone.name)
	await cleanup()


func _nodes_in_group_under(root_node: Node, group: String) -> Array[Node]:
	var found: Array[Node] = []
	for node in tree.get_nodes_in_group(group):
		if root_node.is_ancestor_of(node):
			found.append(node)
	return found
