# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Flyer
extends CharacterBody3D
## What the player flies: a child's red balloon on a string (the game's default, see
## PlayerSettings) or a folded paper plane (`set_look`); only the looks differ, never how it
## flies. Reads the controls, runs the flight model, moves through the physics world, and reacts
## to bumps, crashes and thermals.

signal bumped(strength: float)
signal crashed
signal stopped
signal entered_thermal(thermal: Thermal)
signal snagged

const RADIUS := 0.3
const WORLD_LAYER := 1
## The kid coloured the wing tips with a felt pen, so the plane stands out on pale walls.
const FELT_PEN := Color("e88b7d")
## How far the felt-pen marks sit above the paper (enough to never flicker, too little to see).
const MARK_LIFT := 0.004
## The shadow sits this far above whatever it falls on: above every layer painted on a floor
## (rugs 0.08, the sunbeam's floor glow 0.12, Course.PAINT_LIFT outdoors), so none hides it.
const SHADOW_LIFT := 0.15
## The balloon: red rubber, about the collision sphere's size before Tuning.look_scale.
const BALLOON_RED := Color("e0484f")
const BALLOON_RADIUS := 0.27
const BALLOON_STRETCH := 1.15  ## Taller than wide.
## Where the knot is, below the balloon's centre (before Tuning.look_scale).
const KNOT := Vector3(0.0, -BALLOON_RADIUS * BALLOON_STRETCH - 0.06, 0.0)
const STRING_COLOR := Color("f4efe6")
const STRING_POINTS := 9
const STRING_WIDTH := 0.025
## Pull on the string (units/s^2): with the air's drag, the string trails back and down at about 30 degrees in a glide.
const STRING_GRAVITY := 30.0
## How much rising or sinking air carries the string with it (0..1).
const STRING_AIR_PULL := 0.5

@export var tuning: Tuning

var model: FlightModel
var controls: Controls
## Optional pilot for tests and the screenshot tool: func(plane) -> Vector2(pitch, roll).
var autopilot := Callable()
## Horizontal distance flown, in world units.
var distance := 0.0
var touches := 0  ## Every contact with the house or the hills so far: bounce, slide or crash.
## The surface last touched (its normal), for telling a landing from a graze.
var last_normal := Vector3.UP
var flight_time := 0.0
## The input used this physics tick: x = pitch, y = roll.
var input := Vector2.ZERO
## While held, the plane hangs still (waiting for the game to draw smoothly before the throw).
var held := false
## The world: a plane that leaves this box comes to a stop (the game sets the course's bounds).
var bounds := AABB(Vector3(-1e6, -40.0, -1e6), Vector3(2e6, 2e6, 2e6))
## Horizontal air moving the flyer along on top of its own flight (Endless's tailwind, u/s),
## fading out within `air_drift_ground_fade` of the ground. The flight model never sees it: only
## where the flyer goes changes. Zero in the Course.
var air_drift := Vector3.ZERO
var air_drift_ground_fade := 4.0
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
## True while it is drawn as the balloon.
var balloon := false
var _balloon: Node3D
var _balloon_body: MeshInstance3D
var _string_mesh: MeshInstance3D
var _string: ImmediateMesh
## The string's points in world space, from the knot down, and where they were a tick ago.
var string_points := PackedVector3Array()
var _string_prev := PackedVector3Array()
var _air := Vector3.ZERO  ## The rising or sinking air at the plane this tick.
var _lift_zone: Thermal  ## The zone giving the most lift this tick, or null.
var _ground_y := -INF  ## The ground under the plane (the string never sinks below it).
var _popped := false
var _scraps: Array[MeshInstance3D] = []


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
	# Undo any crash from a previous flight: a crumpled ball, or a popped balloon.
	_paper.scale = Vector3.ONE
	_ball.visible = false
	_popped = false
	_balloon_body.visible = true
	_ground_y = -INF
	for scrap in _scraps:
		scrap.queue_free()
	_scraps.clear()
	_update_visuals(0.0)
	_reset_string()
	reset_physics_interpolation()


## PlayerSettings.PLANE or PlayerSettings.BALLOON. Changes only the looks.
func set_look(look: String) -> void:
	assert(_visual != null, "set_look() needs the plane to be in the tree")
	balloon = look == PlayerSettings.BALLOON
	_visual.visible = not balloon
	_balloon.visible = balloon
	_string_mesh.visible = balloon
	_reset_string()


func is_ended() -> bool:
	return model.is_ended()


## Lets go of a held plane. The phone's current angle becomes "level" for this run.
func release() -> void:
	held = false
	var gravity: Vector3 = read_gravity.call()
	if gravity.length_squared() >= 1.0:
		controls.calibrate(gravity)


func _physics_process(delta: float) -> void:
	if held:
		return
	if model.is_ended():
		_update_string(delta)  # a popped balloon's string still falls
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
	if air_drift != Vector3.ZERO:
		motion += air_drift * drift_weight() * delta
	for i in 4:
		var hit := move_and_collide(motion)
		if hit == null:
			break
		touches += 1
		var normal := hit.get_normal()
		last_normal = normal
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
	if not bounds.has_point(global_position):
		model.stopped = true  # Left the world; end the run rather than fall forever.
	model.update_stop(delta)
	_update_visuals(delta)
	if model.stopped:
		stopped.emit()


## How much of the air's drift carries the flyer: none on the ground, all of it from
## `air_drift_ground_fade` up (by the shadow's ground; all of it if no ground is in reach).
func drift_weight() -> float:
	if _ground_y == -INF:
		return 1.0
	return smoothstep(0.0, maxf(air_drift_ground_fade, 0.01), global_position.y - _ground_y)


## Caught on something that gives (a kite's ring, a wire, washing): keeps `keep` of its speed,
## wobbles, and never crashes.
func snag(keep: float) -> void:
	if model.is_ended():
		return
	model.velocity *= keep
	_wobble = 0.8
	touches += 1
	snagged.emit()


## The rising (or sinking) air at the plane as of this physics tick.
func air_here() -> Vector3:
	return _air


## The zone giving the plane the most lift as of this physics tick, or null if none does.
func lift_zone() -> Thermal:
	return _lift_zone


## Sum of the rising and sinking air at the plane. Emits entered_thermal when the plane
## flies into a thermal or a downdraft.
func _wind_here() -> Vector3:
	var up := 0.0
	var most := 0.0
	_lift_zone = null
	for node in get_tree().get_nodes_in_group("thermals"):
		var zone := node as Thermal
		var full := zone.peak_speed(tuning)
		var air := zone.vertical_air_speed(global_position, tuning)
		up += air
		if air > most:
			most = air
			_lift_zone = zone
		if absf(air) > 0.25 * full and not _inside.has(zone):
			_inside[zone] = true
			entered_thermal.emit(zone)
		elif absf(air) < 0.05 * full:
			_inside.erase(zone)
	_air = Vector3(0.0, up, 0.0)
	return _air


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
	_build_balloon()

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
	_visual_yaw = lerp_angle(_visual_yaw, model.heading, 1.0 - exp(-tuning.visual_turn_speed * delta)) if delta > 0.0 else model.heading
	_wobble_time += delta
	_wobble = maxf(_wobble - delta * tuning.bump_wobble_fade, 0.0)
	var jiggle := _wobble * sin(_wobble_time * tuning.bump_wobble_speed) * tuning.bump_wobble_angle
	var size := Vector3.ONE * tuning.look_scale
	_visual.basis = Basis.from_euler(Vector3(model.pitch, _visual_yaw, -model.bank + jiggle)).scaled(size)
	# The balloon leans only a little into turns and climbs, and sways gently on its own.
	var sway := Vector3(0.05 * sin(_wobble_time * 1.3), 0.0, 0.06 * sin(_wobble_time * 1.7 + 0.8))
	_balloon.basis = Basis.from_euler(Vector3(model.pitch * tuning.balloon_pitch_lean, _visual_yaw, (-model.bank + jiggle) * tuning.balloon_bank_lean) + sway).scaled(size)
	_update_shadow()
	_update_string(delta)


## A soft dark spot on whatever is below the plane, so you can judge height.
func _update_shadow() -> void:
	if not is_inside_tree():
		return
	var from := global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 40.0, WORLD_LAYER, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_shadow.visible = false
		_ground_y = -INF
		return
	var normal: Vector3 = hit["normal"]
	_ground_y = (hit["position"] as Vector3).y
	var height := from.y - _ground_y
	_shadow.visible = not _popped
	_shadow.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, normal)).scaled(Vector3.ONE * (1.0 + height * 0.06) * tuning.look_scale), (hit["position"] as Vector3) + normal * SHADOW_LIFT)
	_shadow_mat.albedo_color.a = clampf(0.45 - height * 0.03, 0.08, 0.45)


func _crumple() -> void:
	if balloon:
		_pop()
		return
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
		var floor_y: float = (hit["position"] as Vector3).y + 0.28 * tuning.look_scale
		var drop := global_position.y - floor_y
		tween.tween_property(self, "global_position:y", floor_y, clampf(sqrt(drop) * 0.35, 0.2, 1.2)).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(0.1)


# --- The balloon ----------------------------------------------------------------

func _build_balloon() -> void:
	_balloon = Node3D.new()
	_balloon.visible = false
	add_child(_balloon)
	_balloon_body = MeshInstance3D.new()
	_balloon_body.mesh = build_balloon_mesh()
	_balloon_body.material_override = _balloon_material()
	_balloon.add_child(_balloon_body)

	_string = ImmediateMesh.new()
	_string_mesh = MeshInstance3D.new()
	_string_mesh.mesh = _string
	_string_mesh.top_level = true  # drawn in world space, straight from the string's points
	_string_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_string_mesh.visible = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = STRING_COLOR
	_string_mesh.material_override = mat
	add_child(_string_mesh)


## Glossy rubber: the same vertex colours, with a soft shine.
static func _balloon_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	m.roughness = 0.35
	m.metallic_specular = 0.6
	return m


## A round red balloon, a little taller than wide, centred on the origin, with its knot below.
static func build_balloon_mesh() -> ArrayMesh:
	var b := Art.Builder.new()
	b.sphere(Vector3.ZERO, BALLOON_RADIUS, BALLOON_RED, Vector3(1.0, BALLOON_STRETCH, 1.0), 14, 8)
	# The neck and knot, tapering down to where the string is tied.
	var bottom := -BALLOON_RADIUS * BALLOON_STRETCH
	b.cylinder(Vector3(0.0, bottom - 0.02, 0.0), 0.025, 0.06, 0.05, BALLOON_RED.darkened(0.12), 8)
	b.sphere(Vector3(0.0, KNOT.y + 0.015, 0.0), 0.035, BALLOON_RED.darkened(0.2), Vector3.ONE, 6, 3)
	return b.commit()


## Where the string is tied, in world space.
func knot_position() -> Vector3:
	return _balloon.global_transform * KNOT


## The string hangs straight down from the knot.
func _reset_string() -> void:
	if _balloon == null:
		return
	var segment := tuning.balloon_string_length * tuning.look_scale / (STRING_POINTS - 1)
	var top := knot_position()
	string_points.resize(STRING_POINTS)
	for i in STRING_POINTS:
		string_points[i] = top + Vector3.DOWN * segment * i
	_string_prev = string_points.duplicate()


## Moves the string one physics tick (`balloon_string_damping` is the swing lost per 1/60 s,
## whatever the tick rate): each point keeps most of its swing, sags, is carried a
## little by rising or sinking air, and is then pulled back to its length from the point above
## (the top one is tied to the knot, until the balloon pops). It never sinks below the ground.
func _update_string(delta: float) -> void:
	if not balloon or string_points.size() != STRING_POINTS or delta <= 0.0:
		return
	var segment := tuning.balloon_string_length * tuning.look_scale / (STRING_POINTS - 1)
	var keep := pow(1.0 - tuning.balloon_string_damping, delta * 60.0)
	var push := Vector3.DOWN * STRING_GRAVITY * delta * delta + _air * STRING_AIR_PULL * delta * (1.0 - keep)
	var floor_y := _ground_y + 0.03
	for i in STRING_POINTS:
		if i == 0 and not _popped:
			_string_prev[0] = string_points[0]
			string_points[0] = knot_position()
			continue
		var p := string_points[i]
		var step := (p - _string_prev[i]) * keep + push
		_string_prev[i] = p
		p += step
		if i > 0:
			var from := string_points[i - 1]
			var along := p - from
			p = from + (along.normalized() if along.length_squared() > 1e-8 else Vector3.DOWN) * segment
		p.y = maxf(p.y, floor_y)
		string_points[i] = p


## Draws the string as a thin ribbon facing the camera, between its last two physics ticks
## (as physics interpolation draws the balloon), so it glides smoothly at any frame rate.
func _process(_delta: float) -> void:
	if not balloon or string_points.size() != STRING_POINTS:
		return
	var f := Engine.get_physics_interpolation_fraction()
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var eye := camera.global_position if camera else string_points[0] + Vector3.BACK * 10.0
	var width := STRING_WIDTH * tuning.look_scale
	_string.clear_surfaces()
	_string.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in STRING_POINTS:
		var p := _string_prev[i].lerp(string_points[i], f)
		var along := string_points[mini(i + 1, STRING_POINTS - 1)] - string_points[maxi(i - 1, 0)]
		var side := along.cross(eye - p)
		side = side.normalized() * width * 0.5 if side.length_squared() > 1e-10 else Vector3.RIGHT * width * 0.5
		_string.surface_add_vertex(p - side)
		_string.surface_add_vertex(p + side)
	_string.surface_end()


## A crash pops the balloon: it vanishes in a burst of red scraps that flutter down, and the
## string drops.
func _pop() -> void:
	_popped = true
	_balloon_body.visible = false
	_shadow.visible = false
	var floor_y := global_position.y - 40.0
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 40.0, WORLD_LAYER, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		floor_y = (hit["position"] as Vector3).y + 0.03
	_ground_y = floor_y - 0.03
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var scrap := BoxMesh.new()
	scrap.size = Vector3(0.12, 0.015, 0.09) * tuning.look_scale
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = BALLOON_RED
	rubber.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 8:
		var piece := MeshInstance3D.new()
		piece.mesh = scrap
		piece.material_override = rubber
		piece.top_level = true
		add_child(piece)
		_scraps.append(piece)
		piece.global_position = global_position
		var out := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.2, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * rng.randf_range(0.4, 0.8) * tuning.look_scale
		var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(piece, "global_position", global_position + out, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(piece, "global_position:y", floor_y, clampf(sqrt(maxf(global_position.y + out.y - floor_y, 0.0)) * 0.6, 0.3, 2.0)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		var spin := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		spin.tween_property(piece, "rotation", Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0)), 1.5)


## A folded paper dart, nose toward -Z, about one unit across.
static func build_paper_mesh() -> ArrayMesh:
	var b := Art.Builder.new()
	var white := Color("fbf8f1")
	var crease := Color("eee8dd")
	var keel := Color("b8acc9")  # lilac grey
	var lift := Vector3(0.0, MARK_LIFT, 0.0)
	var nose := Vector3(0.0, 0.02, -0.62)
	var tail := Vector3(0.0, 0.0, 0.4)
	var keel_low := Vector3(0.0, -0.13, 0.34)
	for s in [-1.0, 1.0]:
		var tip := Vector3(0.5 * s, 0.08, 0.4)
		var fold := Vector3(0.2 * s, 0.025, 0.42)
		b.triangle(nose, fold, tail, crease)
		b.triangle(nose, tip, fold, white)
		b.triangle(tip + lift, fold + lift, tip.lerp(nose, 0.3) + lift, FELT_PEN)
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
