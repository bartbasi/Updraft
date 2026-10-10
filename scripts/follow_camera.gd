class_name FollowCamera
extends Camera3D
## Chase camera behind and a little above the plane. Smoothed so it never jerks, and
## pulled in toward the plane whenever a wall would get in between. Its feel (distance,
## height, smoothing, lean, opening shot) comes from the plane's Tuning.

var target: PaperPlane
var _follow := Vector3.ZERO  ## Where the chase camera would be, smoothed.
var _look := Vector3.ZERO
var _shake := 0.0
var _intro_eye := Vector3.ZERO
var _intro_time := -1.0  ## Seconds into the opening shot; negative when not in it.


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	near = 0.05
	far = 900.0


func _t() -> Tuning:
	return target.tuning


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Jumps straight to the resting spot behind the plane.
func snap() -> void:
	fov = _t().camera_fov
	var p := target.global_position
	_follow = _unblocked(p, _resting_spot(p))
	global_position = _follow
	_look = _look_point(p)
	_intro_time = -1.0
	_aim(_t().camera_lean)


## Starts the opening shot: looking at the plane from `eye` (the thrower), then easing into
## the chase camera once the plane is flying.
func start_intro(eye: Vector3) -> void:
	snap()
	_intro_eye = eye
	_intro_time = 0.0
	global_position = eye
	_look = target.global_position
	_aim(0.0)


func in_intro() -> bool:
	return _intro_time >= 0.0


func _process(delta: float) -> void:
	if target == null:
		return
	fov = _t().camera_fov
	var p := target.get_global_transform_interpolated().origin
	var want := _unblocked(p, _resting_spot(p))
	_follow = _unblocked(p, _follow.lerp(want, 1.0 - exp(-_t().camera_follow_speed * delta)))
	var look_goal := _look_point(p)
	if in_intro():
		if not target.held:
			_intro_time += delta
		var k := smoothstep(0.0, 1.0, _intro_time / _t().camera_intro_duration) if _t().camera_intro_duration > 0.0 else 1.0
		global_position = _intro_eye.lerp(_follow, k)
		_look = p.lerp(look_goal, k)
		_aim(_t().camera_lean * k)  # no lean from the thrower's eye, easing in with the move
		if _intro_time >= _t().camera_intro_duration:
			_intro_time = -1.0
	else:
		global_position = _follow
		_look = _look.lerp(look_goal, 1.0 - exp(-_t().camera_look_speed * delta))
		_aim(_t().camera_lean)
	if _shake > 0.0:
		h_offset = randf_range(-_shake, _shake)
		v_offset = randf_range(-_shake, _shake)
		_shake = maxf(_shake - delta * _t().shake_fade, 0.0)
	else:
		h_offset = 0.0
		v_offset = 0.0


func _aim(lean_amount := 0.0) -> void:
	if global_position.distance_squared_to(_look) > 0.0001:
		look_at(_look, Vector3.UP)
		rotate_object_local(Vector3.BACK, -target.model.bank * lean_amount)


func _resting_spot(p: Vector3) -> Vector3:
	return p - target.model.forward_flat() * _t().camera_distance + Vector3.UP * _t().camera_height


func _look_point(p: Vector3) -> Vector3:
	return p + target.model.forward_flat() * _t().camera_look_ahead + Vector3.UP * _t().camera_look_above


## Moves `spot` toward the plane if a wall is between them.
func _unblocked(p: Vector3, spot: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(p, spot, PaperPlane.WORLD_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return spot
	var hit_at: Vector3 = hit["position"]
	var dir := (spot - p).normalized()
	return p + dir * maxf(p.distance_to(hit_at) - 0.3, 0.4)
