extends TestCase
## The variometer: soft beeps only while climbing in rising air, faster and higher the faster
## the climb.


func test_beeps_only_when_climbing_in_rising_air() -> void:
	var tune := Tuning.new()
	var v := Vario.new(tune)
	check(not v.tick(1.0 / 60.0, 3.0, 0.2, false), "climbing too slowly: silent")
	check(not v.tick(1.0 / 60.0, 0.3, 2.0, false), "climbing without rising air (a pull-up): silent")
	check(not v.tick(1.0 / 60.0, 3.0, 2.0, true), "stalled: silent")
	check(not v.tick(1.0 / 60.0, -3.0, -2.0, false), "sinking air: silent")
	check(v.tick(1.0 / 60.0, 3.0, 2.0, false), "climbing in rising air: the first beep comes at once")
	check(not v.tick(1.0 / 60.0, 3.0, 2.0, false), "and not again on the next tick")


func test_beeps_come_faster_and_higher_with_a_stronger_climb() -> void:
	var tune := Tuning.new()
	var gaps := []
	var pitches := []
	for climb in [0.5, 3.5]:
		var v := Vario.new(tune)
		var beeps := 0
		for i in 600:  # ten seconds
			if v.tick(1.0 / 60.0, 4.0, climb, false):
				beeps += 1
		gaps.append(10.0 / beeps)
		pitches.append(v.pitch())
	check(gaps[1] < gaps[0] * 0.5, "a strong climb beeps much faster (%.2f s vs %.2f s apart)" % [gaps[1], gaps[0]])
	check_between(gaps[1], tune.vario_interval_fast * 0.9, tune.vario_interval_fast * 1.2, "fastest gap (s)")
	check(pitches[1] > pitches[0], "and higher")


func test_beeping_stops_only_well_below_the_start() -> void:
	var tune := Tuning.new()
	var v := Vario.new(tune)
	v.tick(1.0 / 60.0, 3.0, 0.5, false)
	check(v.on, "on at 0.5")
	v.tick(1.0 / 60.0, 3.0, 0.2, false)
	check(v.on, "still on just under the start (0.2)")
	v.tick(1.0 / 60.0, 3.0, 0.05, false)
	check(not v.on, "off once the climb is nearly gone")


## A whole flight: beeps while climbing in the sunbeam, the radiator, the kettle and the hay
## field, and never in sinking air (the stair downdraft) or while not climbing.
func test_a_whole_flight_beeps_only_in_lift() -> void:
	var pilot := Autopilot.new(Autopilot.course_line())
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	var plane := game.get_node("Plane") as PaperPlane
	plane.autopilot = pilot.fly
	var last := 0
	var bad := []
	var zones_beeped := {}
	var frames := 0
	while not plane.is_ended() and frames < 150 * 60:
		await tree.physics_frame
		frames += 1
		if game.vario_beeps != last:
			last = game.vario_beeps
			if plane.air_here().y < plane.tuning.vario_air_min or plane.model.velocity.y < plane.tuning.vario_climb_stop or plane.model.stalled:
				bad.append("%.1f s at %s" % [plane.flight_time, plane.global_position])
			zones_beeped[Course.section_at(plane.global_position)] = true
	print("        vario: %d beeps, in %s" % [last, zones_beeped.keys()])
	check(bad.is_empty(), "no beep outside lift: %s" % [bad.slice(0, 5)])
	check(zones_beeped.has("outside") and zones_beeped.has("upstairs"), "beeps in the sunbeam and outdoors")
