class_name Controls
extends RefCounted
## Turns phone tilt (or the keyboard) into flight input.
## Output: x = pitch (-1 dive ... +1 climb), y = roll (-1 left ... +1 right).
##
## Phone axes follow Godot's sensor convention for the current screen orientation:
## +X toward the right edge of the screen, +Y toward the top edge, +Z out of the screen.
## Tilting the top edge away from you dives; tilting it toward you climbs.

var tuning: Tuning
## The player's own settings (PlayerSettings), on top of the tuning: tilt sensitivity as a
## multiplier, and climb and dive swapped (tilt and keys alike).
var sensitivity_scale := 1.0
var swap_climb_dive := false
## Gravity direction recorded as "level" when the run started.
var level := Vector3.ZERO
var _tilt := Vector2.ZERO
var _keys := Vector2.ZERO


func _init(p_tuning: Tuning = null) -> void:
	tuning = p_tuning if p_tuning else Tuning.new()


func is_calibrated() -> bool:
	return level != Vector3.ZERO


func calibrate(gravity: Vector3) -> void:
	level = gravity.normalized()


## Phone angles in degrees: x = how far the top edge is tipped away from you,
## y = how far the right edge is tipped down.
static func tilt_angles(gravity: Vector3) -> Vector2:
	var g := gravity.normalized()
	return Vector2(rad_to_deg(atan2(-g.z, -g.y)), rad_to_deg(asin(clampf(g.x, -1.0, 1.0))))


## Unsmoothed input from tilt, relative to the calibrated level.
func tilt_input(gravity: Vector3) -> Vector2:
	if not is_calibrated() or gravity.length_squared() < 1.0:
		return Vector2.ZERO
	var delta := tilt_angles(gravity) - tilt_angles(level)
	delta.x = wrapf(delta.x, -180.0, 180.0)
	var pitch := -_shape(delta.x)
	var roll := _shape(delta.y)
	if tuning.invert_tilt_pitch:
		pitch = -pitch
	if tuning.invert_tilt_roll:
		roll = -roll
	return Vector2(pitch, roll)


func _shape(degrees: float) -> float:
	var full := tuning.full_tilt_deg / maxf(tuning.sensitivity * sensitivity_scale, 0.01)
	var dead := tuning.tilt_dead_zone_deg
	var amount := maxf(absf(degrees) - dead, 0.0) / maxf(full - dead, 0.01)
	return signf(degrees) * minf(amount, 1.0)


## Combined, smoothed input for this frame. Records "level" from the first valid tilt reading.
func update(dt: float, gravity: Vector3, keys: Vector2) -> Vector2:
	if not is_calibrated() and gravity.length_squared() >= 1.0:
		calibrate(gravity)
	_tilt = _tilt.lerp(tilt_input(gravity), 1.0 - exp(-tuning.tilt_smoothing * dt))
	_keys = _keys.move_toward(keys, tuning.key_response * dt)
	var input := (_tilt + _keys).clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
	if swap_climb_dive:
		input.x = -input.x
	return input


## Keyboard: Up/W dives, Down/S climbs, Left/A and Right/D bank.
static func read_keys() -> Vector2:
	var climb := Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var dive := Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	return Vector2(float(climb) - float(dive), float(right) - float(left))


## Phone gravity, falling back to the raw accelerometer on phones without a gravity sensor.
## Zero on desktop.
static func read_gravity() -> Vector3:
	var g := Input.get_gravity()
	if g.length_squared() < 1.0:
		g = Input.get_accelerometer()
	return g
