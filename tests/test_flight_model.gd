extends TestCase
## Flight model behaviour, no scene needed.

const DT := 1.0 / 60.0


func _plane(speed := 6.0, height := 50.0) -> FlightModel:
	var m := FlightModel.new(Tuning.new())
	m.launch(Vector3(0.0, height, 0.0), 0.0, speed)
	return m


func _fly(m: FlightModel, seconds: float, wind := Vector3.ZERO) -> void:
	for i in int(seconds / DT):
		m.step(DT, wind)


func test_still_air_sinks_slowly() -> void:
	var m := _plane()
	_fly(m, 5.0)  # settle into a steady glide
	var y0 := m.position.y
	_fly(m, 10.0)
	var sink := (y0 - m.position.y) / 10.0
	check_between(sink, 0.2, 1.2, "still-air sink rate (units/s)")
	check(not m.stalled, "a hands-off glide should not stall")


func test_cannot_stay_up_forever_in_still_air() -> void:
	var m := _plane()
	for input in [-0.3, 0.0, 0.3, 1.0]:
		m.input_pitch = input
		_fly(m, 15.0)
	check(m.position.y < 50.0 - 10.0, "60 s without thermals should lose lots of height (y=%.1f)" % m.position.y)


func test_thermal_lifts_plane() -> void:
	var m := _plane()
	_fly(m, 3.0)
	var y0 := m.position.y
	# A wide test thermal so straight flight stays inside it.
	for i in int(5.0 / DT):
		var up := Tuning.new().thermal_strength * Thermal.profile(m.position - Vector3(0, 40, 0), 100.0, 30.0)
		m.step(DT, Vector3(0.0, up, 0.0))
	check(m.position.y > y0 + 5.0, "5 s in a thermal should climb well (gained %.2f)" % (m.position.y - y0))


func test_thermal_profile_has_soft_edges() -> void:
	check(Thermal.profile(Vector3(0, 3, 0), 3.5, 7.5) > 0.99, "full lift in the middle")
	check(Thermal.profile(Vector3(3.6, 3, 0), 3.5, 7.5) == 0.0, "no lift outside the radius")
	check(Thermal.profile(Vector3(0, 8, 0), 3.5, 7.5) == 0.0, "no lift above the top")
	var edge := Thermal.profile(Vector3(2.8, 3, 0), 3.5, 7.5)
	check(edge > 0.0 and edge < 1.0, "lift fades near the edge (%.2f)" % edge)


func test_below_stall_speed_nose_drops() -> void:
	var m := _plane(2.0)
	m.pitch = deg_to_rad(20.0)
	m.input_pitch = 1.0  # pilot keeps pulling up
	var pitch0 := m.pitch
	_fly(m, 0.5)
	check(m.stalled, "should be stalled below stall speed")
	check(m.pitch < pitch0 - deg_to_rad(20.0), "nose should drop in a stall (pitch %.1f deg)" % rad_to_deg(m.pitch))
	check(m.velocity.y < -1.0, "plane should fall while stalled (vy=%.2f)" % m.velocity.y)
	m.input_pitch = 0.0
	_fly(m, 3.0)
	check(not m.stalled, "plane should recover once it regains speed")
	check(m.airspeed() > m.tuning.stall_speed, "airspeed after recovery (%.2f)" % m.airspeed())


func test_holding_full_climb_eventually_stalls() -> void:
	var m := _plane()
	m.input_pitch = 1.0
	var stalled_once := false
	var y0 := m.position.y
	var max_y := y0
	for i in int(6.0 / DT):
		m.step(DT)
		max_y = maxf(max_y, m.position.y)
		stalled_once = stalled_once or m.stalled
	check(max_y > y0 + 0.3, "nose up should climb at first (gained %.2f)" % (max_y - y0))
	check(stalled_once, "holding the nose up should end in a stall")


func test_dive_gains_speed() -> void:
	var m := _plane()
	var y0 := m.position.y
	m.input_pitch = -1.0
	_fly(m, 2.0)
	check(m.airspeed() > 9.0, "diving should build speed (%.2f)" % m.airspeed())
	check(m.position.y < y0 - 3.0, "diving loses height")


func test_climb_trades_speed_for_height() -> void:
	var m := _plane(9.0)
	var y0 := m.position.y
	m.input_pitch = 0.6
	_fly(m, 1.0)
	check(m.position.y > y0 + 1.0, "nose up at speed should climb (gained %.2f)" % (m.position.y - y0))
	check(m.airspeed() < 9.0, "climbing should cost speed (%.2f)" % m.airspeed())


func test_bank_turns_plane() -> void:
	var m := _plane()
	m.input_roll = 1.0
	_fly(m, 1.0)
	check(m.bank > deg_to_rad(20.0), "plane should bank right")
	check(m.velocity.x > 1.0, "banking right should turn toward +X (vx=%.2f)" % m.velocity.x)
	m.input_roll = -1.0
	_fly(m, 2.0)
	check(m.velocity.x < 0.0, "banking left should turn back toward -X (vx=%.2f)" % m.velocity.x)


func test_glancing_hit_bounces_and_continues() -> void:
	var m := _plane()
	m.velocity = Vector3(1.5, 0.0, -6.0)  # skimming a wall on the right
	var speed0 := m.velocity.length()
	var result := m.resolve_contact(Vector3.LEFT, DT)
	check(result == FlightModel.Contact.BOUNCE, "glancing hit should bounce")
	check(not m.is_ended(), "glancing hit should not end the run")
	check(m.velocity.x < 0.0, "bounce should push the plane away from the wall")
	check(m.velocity.length() < speed0, "bounce should lose some speed")


func test_head_on_hit_crashes() -> void:
	var m := _plane()
	m.velocity = Vector3(0.0, -0.5, -6.0)
	var result := m.resolve_contact(Vector3.BACK, DT)
	check(result == FlightModel.Contact.CRASH, "hard head-on hit should crash")
	check(m.crashed and m.is_ended(), "crash should end the run")


func test_gentle_head_on_bump_does_not_crash() -> void:
	var m := _plane()
	m.velocity = Vector3(0.0, 0.0, -2.0)
	check(m.resolve_contact(Vector3.BACK, DT) == FlightModel.Contact.BOUNCE, "a soft bump is not hard enough to crash")
	check(not m.is_ended(), "soft bump keeps the run going")


func test_sliding_to_a_stop_ends_run() -> void:
	var m := _plane(4.0, 0.0)
	var seconds := 0.0
	while not m.is_ended() and seconds < 10.0:
		m.integrate_forces(DT)
		m.grounded = false
		m.position += m.velocity * DT
		if m.position.y < 0.0:
			m.position.y = 0.0
			m.resolve_contact(Vector3.UP, DT)
		m.update_stop(DT)
		seconds += DT
	check(m.stopped and not m.crashed, "plane should slide to a stop")
	check(seconds < 4.0, "stopping should not take long (%.1f s)" % seconds)


## The game steps physics at a fixed 60 Hz whatever the frame rate; the flight model must also
## stay stable and give nearly the same flight if the tick rate were different.
func test_flight_is_stable_and_consistent_at_different_tick_rates() -> void:
	var ends := []
	for rate in [30.0, 60.0, 120.0]:
		var m := _plane()
		var dt := 1.0 / float(rate)
		var t := 0.0
		while t < 12.0:
			m.input_pitch = -0.6 if t < 3.0 else (0.4 if t < 6.0 else 0.0)
			m.input_roll = 1.0 if t > 7.0 and t < 8.5 else 0.0
			m.step(dt)
			t += dt
		check(m.position.is_finite() and m.velocity.is_finite(), "no blow-ups at %d Hz" % int(rate))
		ends.append(m.position)
	check(ends[0].distance_to(ends[1]) < 2.0 and ends[2].distance_to(ends[1]) < 1.0, "30/60/120 Hz flights end close together: %s" % [ends])
	check(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")) == 60, "physics runs at a fixed 60 Hz")
