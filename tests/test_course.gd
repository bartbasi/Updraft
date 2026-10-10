extends TestCase
## The demo course in the real scene: layout checks and whole flights.

const MAIN := preload("res://scenes/main.tscn")


func _start(pilot: Callable) -> Node:
	var game := MAIN.instantiate()
	add_node(game)
	(game.get_node("Plane") as PaperPlane).autopilot = pilot
	return game


func _fly_until_end(plane: PaperPlane, max_seconds: float) -> void:
	var frames := 0
	while not plane.is_ended() and frames < int(max_seconds * 60.0):
		await tree.physics_frame
		frames += 1


func test_first_thermal_sits_beside_path_within_six_seconds() -> void:
	var gap := absf(Course.RADIATOR_THERMAL.x) - 3.6
	check_between(gap, 0.0, 3.0, "gap between the straight flight path and the first thermal")
	var seconds := (Course.LAUNCH.z - Course.RADIATOR_THERMAL.z) / Tuning.new().launch_speed
	check_between(seconds, 4.0, 6.0, "seconds of straight flight to reach the first thermal")


func test_scene_has_two_thermals() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	await physics_frames(2)
	var thermals := tree.get_nodes_in_group("thermals")
	check(thermals.size() == 2, "expected the radiator and kettle thermals, found %d" % thermals.size())
	check(game.get_node("Plane").global_position.distance_to(Course.LAUNCH) < 1.0, "plane starts on the shelf")


func test_autopilot_flies_the_whole_course() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game := _start(pilot.fly)
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


func test_hands_off_flight_ends_without_getting_stuck() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2.ZERO)
	var plane := game.get_node("Plane") as PaperPlane
	await _fly_until_end(plane, 60.0)
	print("        hands-off: ended at %.1f s, %s, crashed=%s" % [plane.flight_time, plane.global_position, plane.model.crashed])
	check(plane.is_ended(), "a flight with no input must end on its own")


func test_diving_flight_ends() -> void:
	var game := _start(func(_p: PaperPlane) -> Vector2: return Vector2(-1.0, 0.0))
	var plane := game.get_node("Plane") as PaperPlane
	await _fly_until_end(plane, 30.0)
	check(plane.is_ended(), "a nose-dive must end the run")
