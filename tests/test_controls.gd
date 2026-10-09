extends TestCase
## Tilt calibration and keyboard mapping.

const DT := 1.0 / 60.0


## Gravity as the phone reports it when its screen is tipped back `back_deg` from upright
## (top edge away from you) and its right edge is lowered by `right_down_deg`.
func _gravity(back_deg: float, right_down_deg := 0.0) -> Vector3:
	var b := deg_to_rad(back_deg)
	var r := deg_to_rad(right_down_deg)
	return Vector3(sin(r), -cos(r) * cos(b), -cos(r) * sin(b)) * 9.81


func _controls(sensitivity := 1.0) -> Controls:
	var t := Tuning.new()
	t.sensitivity = sensitivity
	var c := Controls.new(t)
	c.calibrate(_gravity(40.0))  # held comfortably, screen tipped back 40 degrees
	return c


func test_level_hold_gives_no_input() -> void:
	var c := _controls()
	check(c.tilt_input(_gravity(40.0)).length() < 0.001, "the calibrated angle is level")


func test_any_hold_angle_can_be_level() -> void:
	var c := Controls.new(Tuning.new())
	c.calibrate(_gravity(75.0))  # almost flat on a table
	check(c.tilt_input(_gravity(75.0)).length() < 0.001, "flat-ish hold is level after calibration")
	check(c.tilt_input(_gravity(90.0)).x < -0.4, "and tipping further away still dives")


func test_tilt_away_dives_and_toward_climbs() -> void:
	var c := _controls()
	check(c.tilt_input(_gravity(55.0)).x < -0.4, "top edge away from you = nose down")
	check(c.tilt_input(_gravity(25.0)).x > 0.4, "top edge toward you = nose up")


func test_tilt_sideways_banks() -> void:
	var c := _controls()
	check(c.tilt_input(_gravity(40.0, 15.0)).y > 0.4, "right edge down = bank right")
	check(c.tilt_input(_gravity(40.0, -15.0)).y < -0.4, "left edge down = bank left")
	check(absf(c.tilt_input(_gravity(40.0, 15.0)).x) < 0.1, "sideways tilt should not pitch")


func test_full_tilt_saturates() -> void:
	var c := _controls()
	check(is_equal_approx(c.tilt_input(_gravity(40.0, 40.0)).y, 1.0), "big tilts clamp to full input")


func test_dead_zone_ignores_tiny_tilts() -> void:
	var c := _controls()
	check(c.tilt_input(_gravity(41.5, 1.0)).length() < 0.001, "tilts inside the dead zone are ignored")


func test_sensitivity_scales_response() -> void:
	var normal := _controls(1.0).tilt_input(_gravity(40.0, 8.0)).y
	var double := _controls(2.0).tilt_input(_gravity(40.0, 8.0)).y
	check(double > normal * 1.8, "sensitivity 2 should roughly double the response (%.2f vs %.2f)" % [double, normal])


func test_first_reading_is_level() -> void:
	var c := Controls.new(Tuning.new())
	var out := Vector2.ZERO
	for i in 30:
		out = c.update(DT, _gravity(30.0, 5.0), Vector2.ZERO)
	check(c.is_calibrated(), "first reading calibrates")
	check(out.length() < 0.001, "holding still at the start angle gives no input")


func test_keyboard_matches_tilt() -> void:
	var c := Controls.new(Tuning.new())
	var out := Vector2.ZERO
	for i in 30:
		out = c.update(DT, Vector3.ZERO, Vector2(-1.0, 1.0))  # Up/W + Right/D
	check(is_equal_approx(out.x, -1.0) and is_equal_approx(out.y, 1.0), "Up/W dives, Right/D banks right (%s)" % out)
