class_name FollowCamera
extends Camera3D
## Chase camera behind and a little above the plane. Smoothed so it never jerks, and
## pulled in toward the plane whenever a wall would get in between.

@export var distance := 3.4
@export var height := 1.0
@export var look_ahead := 3.0
@export var follow_speed := 3.5
@export var look_speed := 6.0
## Fraction of the plane's bank the camera leans with.
@export var lean := 0.25

var target: PaperPlane
var _look := Vector3.ZERO
var _shake := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fov = 70.0
	near = 0.05
	far = 900.0


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Jumps straight to the resting spot behind the plane.
func snap() -> void:
	var p := target.global_position
	global_position = _unblocked(p, _resting_spot(p))
	_look = _look_point(p)
	_aim()


func _process(delta: float) -> void:
	if target == null:
		return
	var p := target.get_global_transform_interpolated().origin
	var want := _unblocked(p, _resting_spot(p))
	global_position = _unblocked(p, global_position.lerp(want, 1.0 - exp(-follow_speed * delta)))
	_look = _look.lerp(_look_point(p), 1.0 - exp(-look_speed * delta))
	_aim()
	if _shake > 0.0:
		h_offset = randf_range(-_shake, _shake)
		v_offset = randf_range(-_shake, _shake)
		_shake = maxf(_shake - delta * 0.8, 0.0)
	else:
		h_offset = 0.0
		v_offset = 0.0


func _aim() -> void:
	if global_position.distance_squared_to(_look) > 0.0001:
		look_at(_look, Vector3.UP)
		rotate_object_local(Vector3.BACK, -target.model.bank * lean)


func _resting_spot(p: Vector3) -> Vector3:
	return p - target.model.forward_flat() * distance + Vector3.UP * height


func _look_point(p: Vector3) -> Vector3:
	return p + target.model.forward_flat() * look_ahead + Vector3.UP * 0.3


## Moves `spot` toward the plane if a wall is between them.
func _unblocked(p: Vector3, spot: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(p, spot, PaperPlane.WORLD_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return spot
	var hit_at: Vector3 = hit["position"]
	var dir := (spot - p).normalized()
	return p + dir * maxf(p.distance_to(hit_at) - 0.3, 0.4)
