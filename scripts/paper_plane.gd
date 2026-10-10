class_name PaperPlane
extends CharacterBody3D
## The player's paper plane. Reads the controls, runs the flight model, moves through the
## physics world, and reacts to bumps, crashes and thermals.

signal bumped(strength: float)
signal crashed
signal stopped
signal entered_thermal(thermal: Thermal)

const RADIUS := 0.3
const WORLD_LAYER := 1

@export var tuning: Tuning

var model: FlightModel
var controls: Controls
## Optional pilot for tests and the screenshot tool: func(plane) -> Vector2(pitch, roll).
var autopilot := Callable()
## Horizontal distance flown, in world units.
var distance := 0.0
var flight_time := 0.0
## The input used this physics tick: x = pitch, y = roll.
var input := Vector2.ZERO
## While held, the plane hangs still (waiting for the game to draw smoothly before the throw).
var held := false
## Where the phone's gravity reading comes from (tests replace this).
var read_gravity := func() -> Vector3: return Controls.read_gravity()

var _inside := {}
var _visual: Node3D
var _paper: MeshInstance3D
var _ball: MeshInstance3D
var _shadow: MeshInstance3D
var _shadow_mat: StandardMaterial3D
var _visual_yaw := 0.0
var _wobble := 0.0
var _wobble_time := 0.0


func _ready() -> void:
	if tuning == null:
		tuning = Tuning.new()
	model = FlightModel.new(tuning)
	controls = Controls.new(tuning)
	collision_layer = 2
	collision_mask = WORLD_LAYER
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	_build_visuals()


func launch(at: Vector3, heading: float) -> void:
	global_position = at
	model.launch(at, heading, tuning.launch_speed)
	distance = 0.0
	flight_time = 0.0
	_visual_yaw = heading
	_update_visuals(0.0)
	reset_physics_interpolation()


func is_ended() -> bool:
	return model.is_ended()


## Lets go of a held plane. The phone's current angle becomes "level" for this run.
func release() -> void:
	held = false
	var gravity: Vector3 = read_gravity.call()
	if gravity.length_squared() >= 1.0:
		controls.calibrate(gravity)


func _physics_process(delta: float) -> void:
	if model.is_ended() or held:
		return
	if autopilot.is_valid():
		input = autopilot.call(self)
	else:
		input = controls.update(delta, read_gravity.call(), Controls.read_keys())
	model.input_pitch = input.x
	model.input_roll = input.y
	model.integrate_forces(delta, _wind_here())

	# Move, letting each surface we touch bounce, slide or crash the plane.
	model.grounded = false
	var start := global_position
	var motion := model.velocity * delta
	for i in 4:
		var hit := move_and_collide(motion)
		if hit == null:
			break
		var normal := hit.get_normal()
		var into := -model.velocity.dot(normal)
		var contact := model.resolve_contact(normal, delta)
		if contact == FlightModel.Contact.CRASH:
			_crumple()
			crashed.emit()
			return
		if contact == FlightModel.Contact.BOUNCE:
			_wobble = clampf(into / 4.0, 0.3, 1.0)
			bumped.emit(into)
		motion = hit.get_remainder().slide(normal)

	model.position = global_position
	var moved := global_position - start
	distance += Vector2(moved.x, moved.z).length()
	flight_time += delta
	if global_position.y < -40.0:
		model.stopped = true  # Fell out of the world; end the run rather than get stuck.
	model.update_stop(delta)
	_update_visuals(delta)
	if model.stopped:
		stopped.emit()


## Sum of the rising and sinking air at the plane. Emits entered_thermal when the plane
## flies into a thermal or a downdraft.
func _wind_here() -> Vector3:
	var up := 0.0
	for node in get_tree().get_nodes_in_group("thermals"):
		var zone := node as Thermal
		var full := zone.peak_speed(tuning)
		var air := zone.vertical_air_speed(global_position, tuning)
		up += air
		if absf(air) > 0.25 * full and not _inside.has(zone):
			_inside[zone] = true
			entered_thermal.emit(zone)
		elif absf(air) < 0.05 * full:
			_inside.erase(zone)
	return Vector3(0.0, up, 0.0)


# --- Looks -------------------------------------------------------------------

func _build_visuals() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_paper = MeshInstance3D.new()
	_paper.mesh = build_paper_mesh()
	_paper.material_override = Art.material(true)
	_visual.add_child(_paper)
	_ball = MeshInstance3D.new()
	_ball.mesh = build_crumple_mesh()
	_ball.material_override = Art.material()
	_ball.visible = false
	_visual.add_child(_ball)

	_shadow = MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(1.4, 1.4)
	_shadow_mat = StandardMaterial3D.new()
	_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.albedo_texture = Art.soft_dot()
	_shadow_mat.albedo_color = Color(0.35, 0.28, 0.4, 0.4)
	quad.material = _shadow_mat
	_shadow.mesh = quad
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.top_level = true
	add_child(_shadow)


func _update_visuals(delta: float) -> void:
	_visual_yaw = lerp_angle(_visual_yaw, model.heading, 1.0 - exp(-14.0 * delta)) if delta > 0.0 else model.heading
	_wobble_time += delta
	_wobble = maxf(_wobble - delta * 2.5, 0.0)
	var jiggle := _wobble * sin(_wobble_time * 32.0) * 0.35
	_visual.basis = Basis.from_euler(Vector3(model.pitch, _visual_yaw, -model.bank + jiggle))
	_update_shadow()


## A soft dark spot on whatever is below the plane, so you can judge height.
func _update_shadow() -> void:
	if not is_inside_tree():
		return
	var from := global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 40.0, WORLD_LAYER, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_shadow.visible = false
		return
	var normal: Vector3 = hit["normal"]
	var height := from.y - (hit["position"] as Vector3).y
	_shadow.visible = true
	_shadow.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, normal)).scaled(Vector3.ONE * (1.0 + height * 0.06)), (hit["position"] as Vector3) + normal * 0.03)
	_shadow_mat.albedo_color.a = clampf(0.45 - height * 0.03, 0.08, 0.45)


func _crumple() -> void:
	_ball.visible = true
	_ball.scale = Vector3.ONE * 0.2
	var tween := create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_paper, "scale", Vector3.ONE * 0.05, 0.15)
	tween.tween_property(_ball, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_ball, "rotation", Vector3(2.2, 1.4, 0.8), 0.9)
	# Drop the crumpled ball onto whatever is below.
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 40.0, WORLD_LAYER, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var floor_y: float = (hit["position"] as Vector3).y + 0.28
		var drop := global_position.y - floor_y
		tween.tween_property(self, "global_position:y", floor_y, clampf(sqrt(drop) * 0.35, 0.2, 1.2)).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(0.1)


## A folded paper dart, nose toward -Z, about one unit across.
static func build_paper_mesh() -> ArrayMesh:
	var b := Art.Builder.new()
	var white := Color("fbf8f1")
	var crease := Color("eee8dd")
	var keel := Color("e0d9cd")
	var nose := Vector3(0.0, 0.02, -0.62)
	var tail := Vector3(0.0, 0.0, 0.4)
	var keel_low := Vector3(0.0, -0.13, 0.34)
	for s in [-1.0, 1.0]:
		var tip := Vector3(0.5 * s, 0.08, 0.4)
		var fold := Vector3(0.2 * s, 0.025, 0.42)
		b.triangle(nose, fold, tail, crease)
		b.triangle(nose, tip, fold, white)
		b.triangle(nose, tail, keel_low, keel)
	return b.commit()


## A lumpy paper ball for crashes.
static func build_crumple_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	sphere.radial_segments = 9
	sphere.rings = 6
	var arrays := sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Push each distinct vertex position in or out by a fixed random amount (shared seams stay shut).
	var offsets := {}
	for i in verts.size():
		var key := verts[i].snapped(Vector3.ONE * 0.001)
		if not offsets.has(key):
			offsets[key] = rng.randf_range(0.7, 1.15)
		verts[i] *= offsets[key]
	var b := Art.Builder.new()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0, indices.size(), 3):
		b.triangle(verts[indices[i]], verts[indices[i + 1]], verts[indices[i + 2]], Color("f4efe6"))
	return b.commit()
