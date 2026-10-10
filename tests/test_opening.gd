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
