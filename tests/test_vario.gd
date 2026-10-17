# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
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
	var plane := game.get_node("Plane") as Flyer
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


## A tall outdoor column (or an indoor one) for the sigh tests: base at y 0, top at y 24.
func _column(outdoors := true) -> Thermal:
	var zone := Thermal.new()
	zone.radius = 12.0
	zone.height = 24.0
	zone.outdoors = outdoors
	return add_node(zone)


## Beeps for `seconds` in strong lift at `height`, then the lift fades to `air_after` with
## the plane sinking. Returns whether the vario sighed when the beeps stopped.
func _climb_then_leave(v: Vario, zone: Thermal, seconds: float, height: float, air_after := 1.0, climb_after := -0.5, stalled := false) -> bool:
	for i in int(seconds * 60.0):
		v.tick(1.0 / 60.0, 4.0, 2.0, false, zone, height)
	check(v.on, "beeping while climbing")
	v.tick(1.0 / 60.0, air_after, climb_after, stalled, null, height)
	check(not v.on, "the beeps stop")
	return v.sigh


func test_flying_out_of_the_side_of_a_column_outdoors_sighs_once() -> void:
	var v := Vario.new(Tuning.new())
	var zone := _column()
	check(_climb_then_leave(v, zone, 2.0, 10.0), "out of the side, halfway up: a sigh")
	check(v.zone == zone, "in that column's voice")
	v.tick(1.0 / 60.0, 0.5, -0.6, false, null, 10.0)
	check(not v.sigh, "just once")


func test_no_sigh_at_the_top_a_quick_pass_indoors_a_dive_or_a_stall() -> void:
	var tune := Tuning.new()
	var zone := _column()
	check(not _climb_then_leave(Vario.new(tune), zone, 2.0, 22.0), "near the top (22 of 24): topping out is silent")
	check(not _climb_then_leave(Vario.new(tune), zone, 1.2, 10.0), "beeping for only 1.2 s: silent")
	check(not _climb_then_leave(Vario.new(tune), _column(false), 2.0, 2.0), "indoors: silent")
	check(not _climb_then_leave(Vario.new(tune), zone, 2.0, 10.0, 4.0, -2.0), "diving in the middle of the lift: silent")
	check(not _climb_then_leave(Vario.new(tune), zone, 2.0, 10.0, 1.0, 0.0, true), "a stall: silent")


func test_sighs_wait_out_their_cooldown() -> void:
	var tune := Tuning.new()
	var v := Vario.new(tune)
	var zone := _column()
	check(_climb_then_leave(v, zone, 2.0, 10.0), "the first exit sighs")
	check(not _climb_then_leave(v, zone, 1.6, 10.0), "back in and out again 1.6 s later: silent")
	for i in int(tune.lift_lost_cooldown * 60.0):
		v.tick(1.0 / 60.0, 0.0, -0.6, false, null, 10.0)
	check(_climb_then_leave(v, zone, 2.0, 10.0), "after the cooldown it sighs again")


## A first-timer flying straight across the hay field low: beeps over the middle, then one
## sigh on the far side, in the hay field's voice, at the sigh's quiet volume.
func test_flying_straight_across_the_hay_field_sighs_on_the_far_side() -> void:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	var plane := game.get_node("Plane") as Flyer
	plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO
	await physics_frames(2)
	plane.launch(Vector3(-2.0, 8.0, -98.0), 0.0)
	var sigh_at := []
	var frames := 0
	while frames < 60 * 8 and not plane.is_ended():
		await tree.physics_frame
		frames += 1
		if game.sighs > sigh_at.size():
			sigh_at.append(plane.global_position)
	var hay: Vector2 = Course.HAY_FIELD["at"]
	check(game.vario_beeps > 0, "it beeps over the field (%d beeps)" % game.vario_beeps)
	check(sigh_at.size() == 1, "one sigh (%d)" % sigh_at.size())
	if sigh_at.size() == 1:
		check(sigh_at[0].z < hay.y, "past the middle of the field (z %.1f)" % sigh_at[0].z)
		check(is_equal_approx(game._sigh.pitch_scale, float(Course.HAY_FIELD["pitch"]) * 0.9), "in the hay field's voice")
		check(is_equal_approx(game._sigh.volume_db, plane.tuning.lift_lost_db), "at the sigh's volume")
