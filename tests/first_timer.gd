# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name FirstTimer
extends RefCounted
## Endless test pilots who don't know the ideal lines (the designer's, from fun review 6), for the
## novice and fair-failure marks:
##   chaser   : chases the nearest gold star it can see ahead; circles only when it hears beeps in
##              a big thermal (one way round, up to circle_max s, stopping once the beeps stop for
##              1.5 s); dives for the middle arch when it sees the viaduct's wall; otherwise drifts
##              toward the middle.
##   nocircle : as chaser, but never circles.
##   middle   : never chases stars or circles; flies the valley's middle; dives for the arch.
## Each draws its own reaction time, wobble, steering and eyesight from its seed.

const KINDS: Array[String] = ["chaser", "nocircle", "middle"]

var game: EndlessGame
var kind := "chaser"
var rng := RandomNumberGenerator.new()
var reaction := 0.25
var wobble := 0.25
var steer_gain := 2.0
var pitch_gain := 0.5
var sight := 60.0
var cone := 1.0
var circle_max := 6.0
var slow_in_lift := true
var react_wall := 50.0
var _circling := false
var _circle_time := 0.0
var _circle_dir := 1.0
var _circled := {}
var _beeps_off := 0.0
var _delayed: Array[Vector2] = []
var _shake := Vector2.ZERO
var _last_heading := NAN


## A pilot of `p_kind` flying `game` (call before the run starts).
static func fly_endless(p_game: EndlessGame, p_kind: String, p_seed: int) -> FirstTimer:
	var pilot := FirstTimer.new()
	pilot.game = p_game
	pilot.kind = p_kind
	pilot.rng.seed = p_seed * 7919 + 13
	pilot.reaction = pilot.rng.randf_range(0.15, 0.35)
	pilot.wobble = pilot.rng.randf_range(0.15, 0.35)
	pilot.steer_gain = pilot.rng.randf_range(1.2, 3.2)
	pilot.pitch_gain = pilot.rng.randf_range(0.3, 0.7)
	pilot.sight = pilot.rng.randf_range(45.0, 70.0)
	pilot.circle_max = pilot.rng.randf_range(4.0, 10.0)
	pilot.slow_in_lift = pilot.rng.randf() < 0.5
	pilot.react_wall = pilot.rng.randf_range(30.0, 70.0)
	p_game.test_pilot = pilot.fly
	return pilot


func fly(plane: Flyer) -> Vector2:
	var p := plane.global_position
	var v := plane.model.velocity
	if is_nan(_last_heading):
		_last_heading = plane.model.heading
	var turn_rate := wrapf(plane.model.heading - _last_heading, -PI, PI) * 60.0
	_last_heading = plane.model.heading
	var zone := plane.lift_zone()
	var on := game.vario.on
	var cmd := Vector2.ZERO
	if kind == "chaser" and not _circling and on and zone != null and zone.shape == Thermal.Shape.CYLINDER and zone.radius >= 8.0 and not _circled.has(zone.name):
		_circling = true
		_circle_time = 0.0
		_beeps_off = 0.0
		_circled[zone.name] = true
		_circle_dir = 1.0 if rng.randf() < 0.5 else -1.0
	var steering := true
	if _circling:
		_circle_time += 1.0 / 60.0
		_beeps_off = 0.0 if on else _beeps_off + 1.0 / 60.0
		if _circle_time > circle_max or _beeps_off > 1.5 or (zone != null and p.y > zone.top() - 2.5):
			_circling = false
		else:
			cmd = Vector2(0.15 if slow_in_lift else 0.0, 0.85 * _circle_dir)
			steering = false
	if steering:
		var aim := Vector3(p.x * 0.5, p.y, p.z - 30.0)
		var chase := false
		if kind != "middle":
			var t: Variant = _star_target(p)
			if t != null:
				aim = t
				chase = true
		var wall: Variant = _wall_aim(p)
		if wall != null and not chase:
			aim = wall
			chase = true
		var to := aim - p
		var want := atan2(-to.x, -to.z)
		var error := wrapf(want - plane.model.heading, -PI, PI)
		var roll := -error * steer_gain + turn_rate * 0.6
		var pitch := 0.0
		if chase:
			pitch = (aim.y - p.y) * pitch_gain - v.y * 0.15
		elif on and slow_in_lift:
			pitch = 0.15
		cmd = Vector2(clampf(pitch, -1.0, 0.3), clampf(roll, -1.0, 1.0))
	if wobble > 0.0:
		_shake = _shake.lerp(Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * wobble, 0.1)
		cmd += _shake
	_delayed.append(cmd)
	var lag := int(reaction * 60.0)
	cmd = _delayed[0] if _delayed.size() > lag else Vector2.ZERO
	while _delayed.size() > lag:
		_delayed.pop_front()
	return cmd.clamp(Vector2(-1, -1), Vector2(1, 1))


## The nearest star still to take ahead down the valley that it can see (drawn) and could
## plausibly reach.
func _star_target(p: Vector3) -> Variant:
	var stars := game.world.stars
	var best: Variant = null
	var best_ahead := INF
	for s: EndlessStars.Star in stars.stars:
		if s.taken or stars.arcs[s.arc].hidden:
			continue
		var q := s.position()
		var rel := q - p
		var ahead := -rel.z
		if ahead < 3.0 or ahead > sight:
			continue
		if absf(rel.x) > ahead * cone or absf(rel.y) > ahead * 0.8 + 2.0:
			continue
		if ahead < best_ahead:
			best_ahead = ahead
			best = q
	return best


## Seeing the viaduct's wall ahead while between its middle arch's crown and the deck: dive for
## that arch.
func _wall_aim(p: Vector3) -> Variant:
	for piece in game.world.pieces:
		if piece.kit == null or piece.kit.arches.is_empty():
			continue
		var a: Dictionary = piece.kit.arches[0]
		var face_z: float = piece.origin.z + float(a["z"]) + float(a["depth"]) * 0.5
		var dist := p.z - face_z
		if dist < 0.0 or dist > react_wall:
			continue
		var o: Dictionary = a["openings"][2]
		var crown: float = float(o["springing"]) + float(o["half_span"])
		var y := p.y - piece.origin.y
		if y > crown - 1.0 and y < 24.5:
			return Vector3(0.0, piece.origin.y + float(o["springing"]) + 0.5, face_z)
	return null
