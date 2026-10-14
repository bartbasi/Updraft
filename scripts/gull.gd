# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Gull
extends Node3D
## A gull that joins the player along a ridge, once for each ridge's lift a run (the valley's
## ridge and the bowl's bluff): after a moment flying along the
## ridge lift it hangs ahead, eases into a spot just off the wing on the hill side, soars there
## for a few seconds, then banks away over the crest. Looks and one call only: nothing collides,
## and it changes nothing about the flight or the score. Numbers are in Tuning ("Lift feel").

signal joined

enum State { WAITING, ARRIVING, ESCORTING, LEAVING, GONE }

const BODY_COLOR := Color("fbf8f1")
const WING_COLOR := Color("9aa3ad")
const TIP_COLOR := Color("5f5b70")
const WINGSPAN := 2.4
## Within this angle of the ridge's length (±Z) counts as flying along it.
const ALONG_RIDGE := deg_to_rad(40.0)
const ARRIVE_SECONDS := 2.5
const LEAVE_SECONDS := 3.0
## On arrival it hangs this far ahead of the plane and this far up (plus `gull_side` to the side).
const ARRIVE_AHEAD := 25.0
const ARRIVE_UP := 4.0
const NEAREST := 1.5  ## Never closer to the plane than this.
const BOB := 0.3
const BOB_PERIOD := 2.5
const LEAVE_CLIMB := 2.0  ## Units/s up while leaving.
const LEAVE_SPEED := 7.0  ## Units/s over the crest while leaving.
const LEAVE_BEATS := 3
const GONE_DISTANCE := 40.0
## The hill-side spot must clear the ground by this much more than `gull_min_ground` before a gull
## on the valley side moves back, so it doesn't flick between the two.
const SIDE_HYSTERESIS := 0.5
## Heading this nearly across the ridge, which side is the hill is unclear: keep the last one.
const ACROSS_RIDGE := 0.3

var state := State.WAITING
var plane: Flyer
## The ridge lifts a gull can join you in, and the one it is in now (or last was).
var lifts: Array[Thermal] = []
var lift: Thermal
var _met := {}  ## The lifts where a gull has already joined you this run.
## The ground's height under a point (the Course's hills unless the game says otherwise).
var ground_height := func(x: float, z: float) -> float: return Course.terrain_height(x, z)
var _along := 0.0  ## Seconds flying along the ridge lift so far.
var _time := 0.0  ## Seconds in the current state.
var _start := Vector3.ZERO  ## Where it hung on arrival.
var _side := 1.0  ## Which side of the plane: +1 the hill side, -1 the valley side (see _choose_side()).
var _hill := Vector3.LEFT  ## Across the plane's heading toward the hill, as last known.
var _leave_dir := Vector3.LEFT
var _wings: Array[MeshInstance3D] = []
var _call: AudioStreamPlayer


func setup(p_plane: Flyer, p_lifts: Array[Thermal]) -> void:
	plane = p_plane
	lifts = p_lifts
	var body := MeshInstance3D.new()
	body.mesh = _build_body()
	add_child(body)
	for s in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		wing.mesh = _build_wing(s)
		add_child(wing)
		_wings.append(wing)
	for child in get_children():
		var mi := child as MeshInstance3D
		mi.material_override = Art.material(true)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_call = AudioStreamPlayer.new()
	_call.stream = load("res://audio/gull.wav")
	_call.bus = &"Master"
	add_child(_call)
	visible = false


func _physics_process(delta: float) -> void:
	if plane == null or lifts.is_empty() or state == State.GONE:
		return
	var tune := plane.tuning
	_time += delta
	match state:
		State.WAITING:
			var along := _ridge_flown_along()
			if along != lift:
				lift = along
				_along = 0.0
			_along = _along + delta if lift != null else 0.0
			if _along >= tune.gull_wait and not plane.is_ended():
				_choose_side()
				_start = plane.global_position + _forward() * ARRIVE_AHEAD + _hill_side() * _side * _spacing().x + Vector3.UP * ARRIVE_UP
				global_position = _start
				_set_state(State.ARRIVING)
				visible = true
				reset_physics_interpolation()
				_call.volume_db = tune.gull_call_db
				_call.play()
				_met[lift] = true
				joined.emit()
		State.ARRIVING:
			_choose_side()
			var k := smoothstep(0.0, 1.0, _time / ARRIVE_SECONDS)
			global_position = _start.lerp(slot(), k)
			_keep_clear()
			_keep_above_ground()  # last, so the floor always holds
			_face(_forward(), plane.model.bank * k)
			if not is_instance_valid(lift) or not lift.contains(plane.global_position) or plane.is_ended():
				_leave()
			elif _time >= ARRIVE_SECONDS:
				_set_state(State.ESCORTING)
		State.ESCORTING:
			_choose_side()
			var target := slot() + Vector3.UP * sin(TAU * _time / BOB_PERIOD) * BOB
			global_position += (target - global_position) * (1.0 - exp(-tune.gull_follow * delta))
			_keep_clear()
			_keep_above_ground()  # last, so the floor always holds
			_face(_forward(), plane.model.bank)
			if _time >= tune.gull_stay or not is_instance_valid(lift) or not lift.contains(plane.global_position) or plane.is_ended():
				_leave()
		State.LEAVING:
			global_position += (_leave_dir * LEAVE_SPEED + Vector3.UP * LEAVE_CLIMB) * delta
			_keep_clear()
			_keep_above_ground()  # last, so the floor always holds
			_face(_leave_dir.lerp(_forward(), 0.3).normalized(), -0.5 * _side)
			var beat := sin(TAU * LEAVE_BEATS * minf(_time / 1.2, 1.0)) * 0.6 if _time < 1.2 else 0.0
			_flap(beat)
			if _time >= LEAVE_SECONDS or global_position.distance_to(plane.global_position) > GONE_DISTANCE:
				visible = false
				if _met.size() < lifts.size():
					_set_state(State.WAITING)  # another ridge still to meet one on
					_along = 0.0
					lift = null
				else:
					_set_state(State.GONE)
					set_physics_process(false)


## Endless: the ridge lifts placed now. A gull that had met every ridge comes back for a new one.
func set_lifts(p_lifts: Array[Thermal]) -> void:
	lifts = p_lifts
	for l in _met.keys():
		if not is_instance_valid(l):
			_met.erase(l)
	if state == State.GONE and lifts.any(func(l: Thermal) -> bool: return not _met.has(l)):
		_set_state(State.WAITING)
		_along = 0.0
		lift = null
		set_physics_process(true)


## Moves the gull by `offset` (Endless recentring its world).
func shift_by(offset: Vector3) -> void:
	global_position += offset
	_start += offset
	reset_physics_interpolation()


## Forgets every ridge met (a new run) and goes back to waiting, out of sight.
func reset() -> void:
	_met.clear()
	lift = null
	_along = 0.0
	visible = false
	_set_state(State.WAITING)
	set_physics_process(true)


## The spot off the plane's wing it soars in, on the side _choose_side() picked: a little up and
## a little ahead.
func slot() -> Vector3:
	var gap := _spacing()
	return plane.global_position + Vector3.UP * gap.y + _forward() * gap.z + _hill_side() * gap.x * _side


## The hill side, unless the spot there would be too near the ground: then the valley side, until
## the hill side is clear again by a margin. Leaving reads the side chosen last.
func _choose_side() -> void:
	var gap := _spacing()
	var hill := plane.global_position + Vector3.UP * gap.y + _forward() * gap.z + _hill_side() * gap.x
	var clearance: float = hill.y - ground_height.call(hill.x, hill.z) - plane.tuning.gull_min_ground
	if _side > 0.0 and clearance < 0.0:
		_side = -1.0
	elif _side < 0.0 and clearance >= SIDE_HYSTERESIS:
		_side = 1.0


## Side, up and ahead of the slot, a little wider around the balloon.
func _spacing() -> Vector3:
	var tune := plane.tuning
	var scale := tune.gull_balloon_scale if plane.balloon else 1.0
	return Vector3(tune.gull_side, tune.gull_up, tune.gull_ahead) * scale


## The ridge lift, not yet visited by a gull, that the plane is flying along now, or null.
func _ridge_flown_along() -> Thermal:
	if plane.held or plane.is_ended():
		return null
	var flat := Vector2(plane.model.velocity.x, plane.model.velocity.z)
	if flat.length() < 0.5:
		return null
	if absf(flat.angle_to(Vector2(0.0, -1.0))) > ALONG_RIDGE and absf(flat.angle_to(Vector2(0.0, 1.0))) > ALONG_RIDGE:
		return null
	for l in lifts:
		if is_instance_valid(l) and not _met.has(l) and l.contains(plane.global_position):
			return l
	return null


## The plane's flat heading.
func _forward() -> Vector3:
	var v := Vector3(plane.model.velocity.x, 0.0, plane.model.velocity.z)
	return v.normalized() if v.length() > 0.1 else Vector3.FORWARD


## Across the plane's heading, toward the hill (-X: the ridge and the bluff both rise that way). Flying nearly
## across the ridge, it keeps the last answer (remembered in `_hill`) rather than flipping from
## wing to wing.
func _hill_side() -> Vector3:
	var across := _forward().cross(Vector3.UP)
	if absf(across.x) >= ACROSS_RIDGE:
		_hill = across if across.x < 0.0 else -across
	else:
		_hill = across if across.dot(_hill) >= 0.0 else -across
	return _hill


## Never lower than `gull_min_ground` over the grass.
func _keep_above_ground() -> void:
	var floor_y: float = ground_height.call(global_position.x, global_position.z) + plane.tuning.gull_min_ground
	global_position.y = maxf(global_position.y, floor_y)


func _keep_clear() -> void:
	var away := global_position - plane.global_position
	if away.length() < NEAREST:
		global_position = plane.global_position + (away.normalized() if away.length() > 0.01 else Vector3.UP) * NEAREST


## Away on the side it flew: over the crest from the hill side, out over the valley from the other.
func _leave() -> void:
	_leave_dir = (_hill_side() * _side * 0.8 + _forward() * 0.6).normalized()
	_set_state(State.LEAVING)


func _set_state(s: State) -> void:
	state = s
	_time = 0.0


## Nose along `dir`, banked by `bank` (radians, like the plane's).
func _face(dir: Vector3, bank: float) -> void:
	var yaw := atan2(-dir.x, -dir.z)
	basis = Basis.from_euler(Vector3(0.0, yaw, -bank))


## Wing beat: both wings raised (+) or lowered (-) about the body.
func _flap(angle: float) -> void:
	_wings[0].basis = Basis(Vector3.FORWARD, angle)
	_wings[1].basis = Basis(Vector3.FORWARD, -angle)


static func _build_body() -> ArrayMesh:
	var b := Art.Builder.new()
	b.sphere(Vector3.ZERO, 0.22, BODY_COLOR, Vector3(0.8, 0.7, 2.2), 8, 4)
	b.sphere(Vector3(0.0, 0.08, -0.45), 0.13, BODY_COLOR, Vector3.ONE, 6, 3)  # head
	return b.commit()


## One wing, nose toward -Z, `s` -1 for the left and +1 for the right: grey on top, a dark tip,
## held in a soft gull's "M" (the elbow up, the tip down).
static func _build_wing(s: float) -> ArrayMesh:
	var b := Art.Builder.new()
	var half := WINGSPAN * 0.5
	var root_front := Vector3(s * 0.12, 0.05, -0.2)
	var root_back := Vector3(s * 0.12, 0.05, 0.25)
	var elbow_front := Vector3(s * half * 0.45, 0.2, -0.15)
	var elbow_back := Vector3(s * half * 0.45, 0.2, 0.3)
	var tip := Vector3(s * half, 0.02, 0.35)
	var tip_back := Vector3(s * half * 0.8, 0.06, 0.4)
	var inner := [root_front, elbow_front, elbow_back, root_back]
	var outer := [elbow_front, tip, tip_back, elbow_back]
	for quad in [[inner, WING_COLOR], [outer, TIP_COLOR]]:
		var q: Array = quad[0]
		var c: Color = quad[1]
		if s > 0.0:
			b.triangle(q[0], q[1], q[2], c)
			b.triangle(q[0], q[2], q[3], c)
		else:
			b.triangle(q[0], q[2], q[1], c)
			b.triangle(q[0], q[3], q[2], c)
	return b.commit()
