# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## The plane node against real physics bodies.


func _plane(at: Vector3, heading: float, input := Vector2.ZERO) -> Flyer:
	var plane := Flyer.new()
	add_node(plane)
	plane.launch(at, heading)
	plane.autopilot = func(_p: Flyer) -> Vector2: return input
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


## The kid's felt-pen marks: coral on the back of both wings, lifted just off the paper so they
## show from above and behind, where the camera is (not sunk into the wing, which would flicker,
## nor under it, where the camera never looks).
func test_plane_has_coral_wing_marks_on_both_wings() -> void:
	var arrays := Flyer.build_paper_mesh().surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	# The white wing triangles (nose, tip, fold), to measure how far each mark sits above them.
	var wings := []
	for i in range(0, verts.size(), 3):
		if colors[i].is_equal_approx(Color("fbf8f1")):
			wings.append([Plane(verts[i], verts[i + 1], verts[i + 2]), signf(verts[i].x + verts[i + 1].x + verts[i + 2].x)])
	var marked := {}
	for i in verts.size():
		if not colors[i].is_equal_approx(Flyer.FELT_PEN):
			continue
		var side := signf(verts[i].x)
		marked[side] = true
		check(verts[i].z >= 0.0, "the marks are on the back of the wing (%s)" % verts[i])
		for entry: Array in wings:
			var wing: Plane = entry[0]
			if entry[1] == side:
				var above := absf(wing.distance_to(verts[i]))
				var up := (wing.project(verts[i]) - verts[i]).y < 0.0  # the mark is above, not under, the paper
				check(up and above > 0.0005 and above < 0.01, "the mark sits just above its wing at %s (%.4f, above: %s)" % [verts[i], above, up])
	check(marked.has(1.0) and marked.has(-1.0), "both wings carry a felt-pen mark")
