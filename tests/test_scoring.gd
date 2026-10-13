# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Distance and style scoring, best-score saving, and air-zone shapes.

const DT := 1.0 / 60.0


func _scoring(path: PackedVector3Array, points := 100, radius := 2.0) -> Scoring:
	var t := Tuning.new()
	t.style_moments = {"test": {"points": points, "radius": radius}}
	var spine := PackedVector3Array([Vector3(0, 0, 10), Vector3(0, 0, -100)])
	return Scoring.new(t, spine, [{"id": &"test", "title": "Test", "path": path}])


## Flies from z=+5 to z=-25 with a fixed sideways offset from a straight path along -Z.
func _fly_offset(s: Scoring, offset: float) -> void:
	var z := 5.0
	while z > -25.0:
		s.update(Vector3(offset, 4.0, z))
		z -= 0.1


func _straight_path() -> PackedVector3Array:
	return PackedVector3Array([Vector3(0, 4, 0), Vector3(0, 4, -10), Vector3(0, 4, -20)])


func test_on_the_optimal_path_earns_full_points() -> void:
	var s := _scoring(_straight_path())
	_fly_offset(s, 0.0)
	check(s.style_points == 100, "on-path flight should earn all 100 points, got %d" % s.style_points)


func test_halfway_to_corridor_edge_earns_less() -> void:
	var s := _scoring(_straight_path())
	_fly_offset(s, 1.0)  # radius 2: halfway to the edge
	check(s.style_points > 0 and s.style_points < 100, "halfway should earn some but not all (%d)" % s.style_points)


func test_outside_the_corridor_earns_nothing() -> void:
	var s := _scoring(_straight_path())
	_fly_offset(s, 3.0)  # radius 2, still within the capture zone
	check(s.style_points == 0, "outside the corridor should earn nothing (%d)" % s.style_points)
	var far := _scoring(_straight_path())
	_fly_offset(far, 30.0)
	check(far.style_points == 0, "far away should earn nothing (%d)" % far.style_points)


func test_grading_falls_smoothly_to_zero() -> void:
	var t := Tuning.new()
	check(is_equal_approx(Scoring.grade(0.0, t), 1.0), "full marks on the path")
	check(is_equal_approx(Scoring.grade(t.style_full_fraction, t), 1.0), "full marks inside the perfect zone")
	check(Scoring.grade(1.0, t) == 0.0, "zero at the corridor edge")
	var last := 1.0
	var x := 0.0
	while x <= 1.0:
		var g := Scoring.grade(x, t)
		check(g <= last + 0.000001, "grade must never rise with distance (%.2f)" % x)
		last = g
		x += 0.05


func test_a_moment_pays_only_once() -> void:
	var s := _scoring(_straight_path())
	_fly_offset(s, 0.0)
	_fly_offset(s, 0.0)
	check(s.style_points == 100, "flying the moment twice must not pay twice (%d)" % s.style_points)


func test_joining_the_path_only_near_its_end_earns_nothing() -> void:
	var s := _scoring(_straight_path())
	# Fly well off to the side (beyond the capture zone), then join for the last 2 units.
	var z := 5.0
	while z > -25.0:
		s.update(Vector3(10.0 if z > -18.0 else 0.0, 4.0, z))
		z -= 0.1
	check(s.style_points == 0, "skipping most of a moment should earn nothing (%d)" % s.style_points)


func test_flying_beside_the_lamp_scores_nothing() -> void:
	var t := Tuning.new()
	var path := PackedVector3Array([Vector3(-1.5, 6.5, -36), Vector3(0, 4.2, -42), Vector3(0, 4.05, -45), Vector3(0, 4.2, -48), Vector3(-0.5, 5.2, -52)])
	var spine := PackedVector3Array([Vector3(0, 6, -30), Vector3(0, 6, -60)])
	var s := Scoring.new(t, spine, [{"id": &"lamp", "title": "Under the lamp", "path": path}])
	var z := -30.0
	while z > -56.0:
		s.update(Vector3(-4.8 if z > -50.0 else -0.5, 6.0 if z > -50.0 else 5.2, z))  # beside the lamp, rejoin at the door
		z -= 0.1
	check(s.style_points == 0, "passing beside the lamp should score nothing (%d)" % s.style_points)


func test_lingering_does_not_change_the_grade() -> void:
	var fast := _scoring(_straight_path())
	var slow := _scoring(_straight_path())
	for step in 300:
		var z := 5.0 - step * 0.1
		fast.update(Vector3(1.0, 4.0, z))
		slow.update(Vector3(1.0, 4.0, z))
		if step == 150:
			for i in 200:  # hover far off the line without moving along it
				slow.update(Vector3(3.5, 4.0, z))
	check(fast.style_points > 0, "the steady pass scores (%d)" % fast.style_points)
	check(fast.style_points == slow.style_points, "hovering in place should not weight the grade (%d vs %d)" % [fast.style_points, slow.style_points])


func test_skipping_the_end_pays_nothing() -> void:
	var s := _scoring(_straight_path())
	var z := 5.0
	while z > -12.0:
		s.update(Vector3(0, 4, z))
		z -= 0.1
	check(s.style_points == 0, "a moment only pays once it is completed")


func test_style_award_signal_reports_quality() -> void:
	var s := _scoring(_straight_path())
	var got := []
	s.style_awarded.connect(func(id: StringName, _title: String, points: int, quality: float) -> void: got.append([id, points, quality]))
	_fly_offset(s, 0.0)
	check(got.size() == 1 and got[0][0] == &"test" and got[0][1] == 100 and got[0][2] > 0.99, "one award with full quality: %s" % [got])


func test_distance_never_goes_backward() -> void:
	var t := Tuning.new()
	var spine := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, -40), Vector3(-40, 0, -40)])
	var s := Scoring.new(t, spine, [])
	var last := 0.0
	var positions := []
	for i in 200:
		positions.append(Vector3(0, 3, -i * 0.3))
	for i in 100:
		positions.append(Vector3(0, 3, -60 + i * 0.3))  # fly back toward the start
	for p in positions:
		s.update(p)
		check(s.distance_meters() >= last, "distance went backward at %s" % p)
		last = s.distance_meters()
	check_between(s.distance_meters(), 9.9, 15.1, "metres reached before turning back")


func test_distance_does_not_jump_to_far_parts_of_the_course() -> void:
	var t := Tuning.new()
	# A U-shaped course: the far leg passes right beside the start.
	var spine := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, -40), Vector3(6, 0, -40), Vector3(6, 0, 0)])
	var s := Scoring.new(t, spine, [])
	s.update(Vector3(0, 0, -2))
	s.update(Vector3(4, 0, -2))  # wander next to the far leg
	check(s.distance_meters() < 1.0, "progress must not jump to the far leg (%.1f m)" % s.distance_meters())


func test_distance_points_and_total() -> void:
	var t := Tuning.new()
	var s := Scoring.new(t, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -100)]), [])
	s.update(Vector3(0, 0, -40))
	check(s.distance_points() == roundi(10.0 * t.points_per_meter), "40 units = 10 m (%d points)" % s.distance_points())
	check(s.total() == s.distance_points() + s.style_points, "total = distance + style")


func test_best_score_round_trip_and_bad_files() -> void:
	var path := "user://test_best_score_%d.json" % OS.get_process_id()
	check(BestScore.save_best(1234, path), "saving should work")
	check(BestScore.load_best(path) == 1234, "saved best should load back")
	var huge := "{\"best\": 5, \"pad\": \"%s\"}" % "x".repeat(2000)
	for bad in ["", "not json", "[1,2]", "{\"best\": -5}", "{\"best\": \"9\"}", "{\"best\": 1e99}", "{\"best\": 12.5}", "{\"other\": 3}", "{\"best\": null}", huge]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(bad)
		f.close()
		check(BestScore.load_best(path) == 0, "bad file %s should give 0, got %d" % [bad.left(40), BestScore.load_best(path)])
	check(BestScore.save_best(77, path) and BestScore.load_best(path) == 77, "saving over a bad file works")
	check(not FileAccess.file_exists(path + ".tmp"), "no temporary file left behind")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(BestScore.load_best(path) == 0, "a missing file gives 0")


func test_box_zone_profile() -> void:
	var size := Vector3(6, 8, 4)
	check(Thermal.box_profile(Vector3(0, 4, 0), size) > 0.99, "full strength in the middle")
	check(Thermal.box_profile(Vector3(3.1, 4, 0), size) == 0.0, "nothing outside the sides")
	check(Thermal.box_profile(Vector3(0, 8.1, 0), size) == 0.0, "nothing above the top")
	check(Thermal.box_profile(Vector3(0, -0.1, 0), size) == 0.0, "nothing below the bottom")
	var edge := Thermal.box_profile(Vector3(2.6, 4, 0), size)
	check(edge > 0.0 and edge < 1.0, "soft near the sides (%.2f)" % edge)


func test_downdraft_pushes_down_and_thermal_pushes_up() -> void:
	var t := Tuning.new()
	var down := Thermal.new()
	down.shape = Thermal.Shape.BOX
	down.size = Vector3(6, 10, 6)
	down.look = Thermal.Look.DOWNDRAFT
	add_node(down)
	var plain := Thermal.new()
	check(down.sinks and not plain.sinks, "only the downdraft look sinks")
	plain.free()
	var up := Thermal.new()
	up.shape = Thermal.Shape.BOX
	up.size = Vector3(6, 10, 6)
	up.look = Thermal.Look.SUNBEAM
	up.position = Vector3(50, 0, 0)
	add_node(up)
	check(down.vertical_air_speed(Vector3(0, 5, 0), t) < -t.downdraft_strength * 0.99, "downdraft air sinks at full strength")
	check(up.vertical_air_speed(Vector3(50, 5, 0), t) > t.thermal_strength * 0.99, "sunbeam air rises at full strength")
	# A gliding plane loses height faster inside the downdraft.
	var free := FlightModel.new(t)
	free.launch(Vector3(0, 50, 0), 0.0, 6.0)
	var sinking := FlightModel.new(t)
	sinking.launch(Vector3(0, 50, 0), 0.0, 6.0)
	for i in 60:
		free.step(DT)
		sinking.step(DT, Vector3(0, -t.downdraft_strength, 0))
	check(sinking.position.y < free.position.y - 1.5, "a second in sinking air drops the plane (%.2f vs %.2f)" % [sinking.position.y, free.position.y])
	check(sinking.airspeed() > free.airspeed(), "sinking air adds speed for a dive")


func _box_zone(at: Vector3, box: Vector3, look: Thermal.Look, sun := Vector3.DOWN) -> Thermal:
	var zone := Thermal.new()
	zone.sun_direction = sun  # set before the zone enters the tree and builds its visuals
	zone.shape = Thermal.Shape.BOX
	zone.size = box
	zone.look = look
	zone.position = at
	add_node(zone)
	return zone


func _glider(at: Vector3) -> Flyer:
	var plane := Flyer.new()
	add_node(plane)
	plane.launch(at, 0.0)
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	return plane


func test_plane_sinks_faster_in_a_downdraft_and_hears_it_once() -> void:
	_box_zone(Vector3(0, 0, -20), Vector3(12, 40, 30), Thermal.Look.DOWNDRAFT)
	var inside := _glider(Vector3(0, 20, -6))
	var outside := _glider(Vector3(200, 20, -6))
	var entries := [0]
	inside.entered_thermal.connect(func(z: Thermal) -> void: entries[0] += 1 if z.sinks else 0)
	await physics_frames(150)
	check(entries[0] == 1, "flying into a downdraft fires the event once (%d)" % entries[0])
	check(inside.global_position.y < outside.global_position.y - 2.0, "the downdraft pulls the plane down (%.1f vs %.1f)" % [inside.global_position.y, outside.global_position.y])
	check(inside.model.velocity.length() > outside.model.velocity.length(), "and adds speed")


func test_rising_and_sinking_air_add_up() -> void:
	var t := Tuning.new()
	var up := _box_zone(Vector3(0, 0, 0), Vector3(10, 20, 10), Thermal.Look.WARM_AIR)
	var down := _box_zone(Vector3(0, 0, 0), Vector3(10, 20, 10), Thermal.Look.DOWNDRAFT)
	var plane := _glider(Vector3(0, 10, 0))
	var expected := up.vertical_air_speed(Vector3(0, 10, 0), t) + down.vertical_air_speed(Vector3(0, 10, 0), t)
	check(is_equal_approx(plane._wind_here().y, expected), "the plane feels the sum of overlapping zones (%.2f vs %.2f)" % [plane._wind_here().y, expected])
	check(is_equal_approx(expected, t.thermal_strength - t.downdraft_strength), "full lift minus full sink in the middle")


func test_sunbeam_lift_follows_the_slanted_light() -> void:
	var t := Tuning.new()
	var beam := _box_zone(Vector3.ZERO, Vector3(10, 12, 6), Thermal.Look.SUNBEAM, Vector3(0.0, -1.0, 0.5))  # light travels +Z as it falls
	# Halfway up, the light (and the lift) has moved 3 units back toward the sun (-Z).
	check(beam.vertical_air_speed(Vector3(0, 6, -3), t) > t.thermal_strength * 0.99, "full lift in the middle of the slanted beam")
	check(beam.vertical_air_speed(Vector3(0, 6, 3), t) == 0.0, "no lift where the light isn't")
