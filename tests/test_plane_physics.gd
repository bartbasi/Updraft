extends TestCase
## The plane node against real physics bodies.


func _plane(at: Vector3, heading: float, input := Vector2.ZERO) -> PaperPlane:
	var plane := PaperPlane.new()
	add_node(plane)
	plane.launch(at, heading)
	plane.autopilot = func(_p: PaperPlane) -> Vector2: return input
	return plane


func _wall(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_node(body)


func test_glancing_wall_hit_bounces_and_run_continues() -> void:
	_wall(Vector3(2.5, 5.0, -10.0), Vector3(1.0, 20.0, 40.0))
	var plane := _plane(Vector3(0.0, 5.0, 0.0), -0.25)  # angled slightly toward the wall
	var bumps := [0]
	plane.bumped.connect(func(_s: float) -> void: bumps[0] += 1)
	await physics_frames(120)
	check(bumps[0] >= 1, "plane should have bumped the wall")
	check(not plane.is_ended(), "a glancing hit must not end the run")
	check(plane.model.velocity.x <= 0.05, "plane should be deflected away from the wall (vx=%.2f)" % plane.model.velocity.x)
	check(plane.global_position.x < 2.0, "plane should stay on its side of the wall")


func test_head_on_wall_hit_crashes() -> void:
	_wall(Vector3(0.0, 5.0, -6.0), Vector3(20.0, 20.0, 1.0))
	var plane := _plane(Vector3(0.0, 5.0, 0.0), 0.0)
	var crashes := [0]
	plane.crashed.connect(func() -> void: crashes[0] += 1)
	await physics_frames(120)
	check(crashes[0] == 1, "plane should crash into the wall")
	check(plane.model.crashed, "model should be crashed")


func test_landing_slides_to_a_stop() -> void:
	_wall(Vector3(0.0, -0.5, 0.0), Vector3(200.0, 1.0, 200.0))
	var plane := _plane(Vector3(0.0, 1.0, 0.0), 0.0)
	var stops := [0]
	plane.stopped.connect(func() -> void: stops[0] += 1)
	await physics_frames(60 * 8)
	check(stops[0] == 1, "plane should land and slide to a stop")
	check(not plane.model.crashed, "a gentle landing is not a crash")
	check(plane.distance > 2.0, "plane should travel before stopping (%.1f)" % plane.distance)
