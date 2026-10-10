class_name Autopilot
extends RefCounted
## A scripted test pilot. It follows a 3D line through the course (pure pursuit): it aims at
## a point a little way ahead on the line, banks toward it, and pitches to match its height.
## Skill settings turn it into a sloppier first-time pilot: slow reactions, wobbly hands and
## over- or under-steering. Used by the course tests, the flight log and the screenshot tool.

var line: PackedVector3Array
var lengths: PackedFloat32Array
## How far ahead on the line to aim (units), plus this many seconds of travel.
var lookahead := 3.0
var lookahead_time := 0.4
## Seconds between the situation changing and the pilot reacting.
var reaction := 0.0
## Random wobble added to inputs (0 = steady hands).
var wobble := 0.0
## Steering strength; above ~2 over-steers, below ~1.5 under-steers.
var steer_gain := 2.0
## Largest nose-up input the pilot will use (it avoids stalling on purpose).
var max_climb := 0.3
## How firmly it pitches toward the height of its aim point (per unit of height).
var pitch_gain := 0.3
var rng := RandomNumberGenerator.new()

var _segment := -1  ## Where on the line the pilot is; -1 until it has looked.
var _last_heading := NAN
var _delayed: Array[Vector2] = []
var _shake := Vector2.ZERO


func _init(p_line: PackedVector3Array, p_seed := 1) -> void:
	line = p_line
	lengths = Scoring.arc_lengths(line)
	rng.seed = p_seed


## A good line from the throw in the bedroom to the hills: the course's own optimal paths
## through the opening, joined by the gallery, then the downstairs line.
static func course_line() -> PackedVector3Array:
	var paths := _style_paths()
	var gallery := PackedVector3Array([Vector3(60.0, 23.0, 41.0), Vector3(45.0, 22.5, 40.0), Vector3(30.0, 21.5, 41.0)])  # through the skylight
	var line := PackedVector3Array([Course.START])
	for part in [paths["bedroom_turn"], paths["sunbeam"], gallery, paths["stair_downdraft"], paths["landing_turn"], downstairs_line()]:
		line = _join(line, part)
	return line


## The downstairs part along the course's own optimal paths, the lamp included, from
## Course.LIVING_ROOM_ENTRY. Threading the lamp needs a firm hand on the pitch (`pitch_gain`).
static func downstairs_style_line() -> PackedVector3Array:
	var paths := _style_paths()
	var out_of_window := PackedVector3Array([Vector3(0.0, 6.0, -100.0), Vector3(0.0, 2.0, -180.0)])
	var line := PackedVector3Array([Course.LIVING_ROOM_ENTRY])
	for part in [paths["radiator"], paths["lamp"], paths["kettle"], paths["window"], out_of_window]:
		line = _join(line, part)
	return line


static func _style_paths() -> Dictionary:
	var paths := {}
	for def in Course.style_moment_defs():
		paths[String(def["id"])] = def["path"]
	return paths


## Appends `part` to `line`, skipping points that lie behind the line's current end (where
## one moment's path overlaps the next), so the line never doubles back.
static func _join(line: PackedVector3Array, part: PackedVector3Array) -> PackedVector3Array:
	var out := line.duplicate()
	for p in part:
		if out.size() >= 2:
			var last := out[out.size() - 1]
			if (p - last).dot(last - out[out.size() - 2]) <= 0.5:
				continue
		out.append(p)
	return out


## A good line through the downstairs part, from Course.LIVING_ROOM_ENTRY.
static func downstairs_line() -> PackedVector3Array:
	return PackedVector3Array([
		Course.LIVING_ROOM_ENTRY,
		Vector3(-4.5, 9.0, -18.0), Vector3(-5.0, 10.0, -25.0),  # through the radiator heat
		Vector3(-3.2, 6.2, -40.0), Vector3(-2.9, 6.0, -45.0),  # past the lamp on its left
		Vector3(-1.0, 5.6, -52.0),  # under the door frame
		Vector3(1.5, 6.5, -62.0), Vector3(2.6, 9.0, -69.0),  # up the kettle steam
		Vector3(1.0, 8.0, -80.0), Vector3(0.0, 7.5, -88.0),  # out of the window
		Vector3(0.0, 6.0, -100.0), Vector3(0.0, 2.0, -180.0),
	])


## A first-time player who reacts really late, so some of them turn only after the door.
static func late_novice(p_line: PackedVector3Array, p_seed: int) -> Autopilot:
	var pilot := novice(p_line, p_seed)
	pilot.reaction = pilot.rng.randf_range(0.3, 0.9)
	pilot.lookahead = pilot.rng.randf_range(1.0, 2.5)
	pilot.lookahead_time = 0.0
	return pilot


## A first-time player: late, wobbly and a bit heavy-handed.
static func novice(p_line: PackedVector3Array, p_seed: int) -> Autopilot:
	var pilot := Autopilot.new(p_line, p_seed)
	pilot.reaction = pilot.rng.randf_range(0.15, 0.35)
	pilot.wobble = pilot.rng.randf_range(0.15, 0.35)
	pilot.steer_gain = pilot.rng.randf_range(1.2, 3.2)
	pilot.lookahead = pilot.rng.randf_range(2.0, 4.0)
	pilot.lookahead_time = pilot.rng.randf_range(0.1, 0.4)
	pilot.max_climb = 0.5
	return pilot


## The point `s` units along the line (clamped to its ends).
func point_at(s: float) -> Vector3:
	var total := lengths[lengths.size() - 1]
	s = clampf(s, 0.0, total)
	for i in range(1, lengths.size()):
		if lengths[i] >= s:
			var seg := lengths[i] - lengths[i - 1]
			return line[i - 1].lerp(line[i], (s - lengths[i - 1]) / maxf(seg, 0.0001))
	return line[line.size() - 1]


func fly(plane: PaperPlane) -> Vector2:
	var p := plane.global_position
	# The first time, search the whole line (the pilot may start anywhere); then only nearby.
	var hit := Scoring.project(line, lengths, p) if _segment < 0 else Scoring.project(line, lengths, p, maxi(_segment - 1, 0), mini(_segment + 2, line.size() - 2))
	_segment = int(hit.z)
	var speed := plane.model.velocity.length()
	var aim := point_at(hit.x + lookahead + speed * lookahead_time)

	var to := aim - p
	var want := atan2(-to.x, -to.z)
	var error := wrapf(want - plane.model.heading, -PI, PI)
	if is_nan(_last_heading):
		_last_heading = plane.model.heading
	var turn_rate := wrapf(plane.model.heading - _last_heading, -PI, PI) * 60.0
	_last_heading = plane.model.heading
	var roll := -error * steer_gain + turn_rate * 0.6
	var pitch := (aim.y - p.y) * pitch_gain - plane.model.velocity.y * 0.15
	var command := Vector2(clampf(pitch, -1.0, max_climb), clampf(roll, -1.0, 1.0))

	if wobble > 0.0:
		_shake = _shake.lerp(Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * wobble, 0.1)
		command += _shake
	if reaction > 0.0:
		_delayed.append(command)
		var lag := int(reaction * 60.0)
		command = _delayed[0] if _delayed.size() > lag else Vector2.ZERO
		while _delayed.size() > lag:
			_delayed.pop_front()
	return command.clamp(Vector2(-1, -1), Vector2(1, 1))
