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
	var behind := plane.global_position - plane.model.forward_flat() * camera.distance
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
	var x := Course.TAPER_TO.x + 0.5
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
