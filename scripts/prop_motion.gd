class_name PropMotion
extends MeshInstance3D
## A moving bit of scenery: turned about an axis (windmill sails) or carried round a circle
## (a sailboat). Moved every frame in _process, with physics interpolation off, like the birds.
## Looks only: nothing collides. (Not a tool script: in the editor it sits where it starts.)

var _centre := Vector3.ZERO
var _axis := Vector3.RIGHT
var _orient := Basis.IDENTITY  ## Turns the spinning mesh to face its way.
var _rate := 0.0  ## Radians/second.
var _radius := 0.0  ## 0 spins in place; more sails round a circle this big.
var _heel := 0.0
var _time := 0.0


func _init() -> void:
	material_override = Art.material(true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


## Turns about its own `axis` through `at`, at `rate` radians/second, the whole turned by `orient`.
func spin(at: Vector3, axis: Vector3, rate: float, orient := Basis.IDENTITY) -> void:
	_centre = at
	_orient = orient
	_axis = axis.normalized()
	_rate = rate
	_radius = 0.0
	_place()


## Sails round a circle about `centre` (anticlockwise seen from above) at `speed` units/second,
## nose along the way it's going, leaning `heel` radians toward -X (away from the breeze).
func sail_round(centre: Vector3, radius: float, speed: float, heel: float) -> void:
	_centre = centre
	_radius = radius
	_rate = speed / maxf(radius, 0.01)
	_heel = heel
	_place()


func _process(delta: float) -> void:
	_time += delta
	_place()


func _place() -> void:
	var a := _rate * _time
	if _radius <= 0.0:
		transform = Transform3D(_orient * Basis(_axis, a), _centre)
		return
	# Anticlockwise from above: from +X toward -Z. The nose (-Z in the mesh) points along the way round.
	var at := _centre + Vector3(cos(a), 0.0, -sin(a)) * _radius
	var along := Vector3(-sin(a), 0.0, -cos(a))
	var yaw := Basis(Vector3.UP, atan2(-along.x, -along.z))
	# Heel about its own length, toward -X: rolling about its nose by +heel leans it to its right.
	var lean := -_heel if yaw.x.x > 0.0 else _heel
	transform = Transform3D(yaw * Basis(Vector3.FORWARD, lean), at)
