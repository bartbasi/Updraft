class_name FlightModel
extends RefCounted
## Paper-glider flight physics, kept free of nodes so it can be tested headless.
##
## The plane has a velocity, a nose pitch and a bank angle. Lift and drag depend on
## airspeed and angle of attack (the angle between the nose and the oncoming air).
## Thermals reach the model as wind: rising air the plane flies through.
## Every number comes from Tuning.

enum Contact { NONE, BOUNCE, SLIDE, CRASH }

var tuning: Tuning
var position := Vector3.ZERO
## Ground-relative velocity, units/s.
var velocity := Vector3.ZERO
## Nose angle above the horizon, radians.
var pitch := 0.0
## Bank angle, radians. Positive = right wing down.
var bank := 0.0
## Yaw, radians. 0 = flying toward -Z, positive = turned left.
var heading := 0.0
## -1 = full dive ... +1 = full climb.
var input_pitch := 0.0
## -1 = full left ... +1 = full right.
var input_roll := 0.0
var stalled := false
## True while resting or sliding on a floor-like surface.
var grounded := false
var crashed := false
var stopped := false
var _slow_time := 0.0


func _init(p_tuning: Tuning = null) -> void:
	tuning = p_tuning if p_tuning else Tuning.new()


func launch(p_position: Vector3, p_heading: float, speed: float) -> void:
	position = p_position
	heading = p_heading
	pitch = deg_to_rad(tuning.neutral_pitch_deg)
	bank = 0.0
	velocity = forward_flat() * speed
	stalled = false
	grounded = false
	crashed = false
	stopped = false
	_slow_time = 0.0


func is_ended() -> bool:
	return crashed or stopped


## Horizontal unit vector the plane is heading along.
func forward_flat() -> Vector3:
	return Vector3(-sin(heading), 0.0, -cos(heading))


func airspeed(wind := Vector3.ZERO) -> float:
	return (velocity - wind).length()


## Free flight with no surfaces: forces, then position. (The game moves the plane with
## the physics engine instead, calling integrate_forces() and resolve_contact().)
func step(dt: float, wind := Vector3.ZERO) -> void:
	integrate_forces(dt, wind)
	position += velocity * dt
	update_stop(dt)


func integrate_forces(dt: float, wind := Vector3.ZERO) -> void:
	if is_ended():
		return
	var t := tuning
	var max_bank := deg_to_rad(t.max_bank_deg)

	var target_bank := 0.0 if grounded else clampf(input_roll, -1.0, 1.0) * max_bank
	bank = move_toward(bank, target_bank, deg_to_rad(t.bank_rate_deg) * dt)

	var air := velocity - wind
	var speed := air.length()
	if stalled:
		stalled = speed < t.stall_recover_speed and not grounded
	else:
		stalled = speed < t.stall_speed and not grounded

	# The nose chases the pilot's input, except in a stall (it drops) or on the floor (it lies flat).
	var target_pitch := deg_to_rad(t.neutral_pitch_deg)
	var pitch_rate := deg_to_rad(t.pitch_rate_deg)
	if grounded:
		target_pitch = 0.0
	elif stalled:
		target_pitch = deg_to_rad(t.stall_nose_pitch_deg)
		pitch_rate = deg_to_rad(t.stall_pitch_rate_deg)
	else:
		var p := clampf(input_pitch, -1.0, 1.0)
		target_pitch += p * deg_to_rad(t.climb_pitch_deg if p > 0.0 else t.dive_pitch_deg)
	pitch = move_toward(pitch, target_pitch, pitch_rate * dt)

	var accel := Vector3(0.0, -t.gravity, 0.0)
	if speed > 0.01:
		var along := air / speed
		var path_angle := atan2(air.y, Vector2(air.x, air.z).length())
		var angle_of_attack := pitch - path_angle
		var cl := clampf(t.lift_per_radian * angle_of_attack, -0.5 * t.max_lift_coefficient, t.max_lift_coefficient)
		if stalled:
			cl *= t.stall_lift_factor
		# Lift is perpendicular to the oncoming air, in the vertical plane of the flight path.
		var side := along.cross(Vector3.UP)
		if side.length_squared() < 0.0001:
			side = forward_flat().cross(Vector3.UP)
		var lift_dir := side.normalized().cross(along)
		var q := speed * speed
		accel += lift_dir * (t.lift * q * cl * cos(bank))
		accel -= along * (q * (t.drag + t.induced_drag * cl * cl))
	velocity += accel * dt

	# Banking turns the flight path. Turn rate comes straight from the bank angle (fun over realism).
	if not grounded:
		var turn := -deg_to_rad(t.turn_rate_deg) * (bank / max_bank) * dt
		velocity = velocity.rotated(Vector3.UP, turn)
		heading = wrapf(heading + turn, -PI, PI)
	if velocity.length() > t.max_speed:
		velocity = velocity.normalized() * t.max_speed
	if Vector2(velocity.x, velocity.z).length() > 0.5:
		heading = atan2(-velocity.x, -velocity.z)


## Reacts to touching a surface with the given normal. Glancing touches bounce off and
## lose some speed; a hard, steep hit crashes; a gentle touch slides with friction.
func resolve_contact(normal: Vector3, dt: float) -> Contact:
	if is_ended():
		return Contact.NONE
	var t := tuning
	var into := -velocity.dot(normal)
	if into <= 0.0:
		return Contact.NONE
	var steepness := rad_to_deg(asin(clampf(into / velocity.length(), 0.0, 1.0)))
	if into >= t.crash_impact_speed and steepness >= t.head_on_angle_deg:
		crashed = true
		velocity = Vector3.ZERO
		return Contact.CRASH
	var along := velocity + normal * into
	if into >= t.bounce_min_impact:
		velocity = along * t.glance_speed_keep + normal * (into * t.bounce_restitution)
		return Contact.BOUNCE
	if normal.y > 0.7:
		grounded = true
	var slide_speed := along.length()
	if slide_speed > 0.0001:
		velocity = along * (maxf(slide_speed - t.slide_friction * dt, 0.0) / slide_speed)
	else:
		velocity = Vector3.ZERO
	return Contact.SLIDE


## Ends the run once the plane has been nearly motionless for a moment.
func update_stop(dt: float) -> void:
	if is_ended():
		return
	if velocity.length() < tuning.stop_speed:
		_slow_time += dt
		stopped = _slow_time >= tuning.stop_time
	else:
		_slow_time = 0.0
