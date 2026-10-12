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
## Circles to fly on the way, in order: on coming within 1.3 radii of `centre` (x, z), the pilot
## circles it at `radius` until it has climbed (`up`) or come down to height `to_y`, or for
## `max_time` seconds at most, then flies on along the line. Lines that go out of the window get the outdoor circles (route("lavender")).
var orbits: Array[Dictionary] = []

var _orbit := 0  ## The next circle to fly.
var _orbiting := false
var _orbit_time := 0.0  ## Seconds into the current circle (the pilot flies every physics tick).
var _segment := -1  ## Where on the line the pilot is; -1 until it has looked.
var _last_heading := NAN
var _delayed: Array[Vector2] = []
var _shake := Vector2.ZERO


func _init(p_line: PackedVector3Array, p_seed := 1) -> void:
	line = p_line
	lengths = Scoring.arc_lengths(line)
	rng.seed = p_seed
	if line[line.size() - 1].z < Course.FAR_Z:
		orbits.assign(route("lavender")["orbits"])


## A pilot who flies the whole course and then the outdoor route `route_name` (see route()).
static func touring(route_name: String, p_seed := 1) -> Autopilot:
	var pilot := Autopilot.new(course_line(route_name), p_seed)
	pilot.orbits.assign(route(route_name)["orbits"])
	return pilot


## A good line from the throw in the bedroom to the hills: the course's own optimal paths
## through the opening, joined by the gallery, then the downstairs line.
static func course_line(route_name := "lavender") -> PackedVector3Array:
	var paths := _style_paths()
	var gallery := PackedVector3Array([Vector3(60.0, 23.0, 41.0), Vector3(45.0, 22.5, 40.0), Vector3(30.0, 21.5, 41.0)])  # through the skylight
	var line := PackedVector3Array([Course.START])
	for part in [paths["bedroom_turn"], paths["sunbeam"], gallery, paths["stair_downdraft"], paths["landing_turn"], downstairs_line(route_name)]:
		line = _join(line, part)
	return line


## The downstairs part along the course's own optimal paths, the lamp included, from
## Course.LIVING_ROOM_ENTRY. Threading the lamp needs a firm hand on the pitch (`pitch_gain`).
static func downstairs_style_line() -> PackedVector3Array:
	var paths := _style_paths()
	var out_of_window := PackedVector3Array([Vector3(0.0, 6.0, -100.0), Vector3(0.0, 2.0, -130.0)])
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


## A good line through the downstairs part, from Course.LIVING_ROOM_ENTRY, then outdoors
## along `route_name`.
static func downstairs_line(route_name := "lavender") -> PackedVector3Array:
	return PackedVector3Array([
		Course.LIVING_ROOM_ENTRY,
		Vector3(-4.5, 6.8, -18.0), Vector3(-5.0, 10.0, -25.0),  # through the radiator heat
		Vector3(-3.2, 6.2, -40.0), Vector3(-2.9, 6.0, -45.0),  # past the lamp on its left
		Vector3(-1.0, 5.6, -52.0),  # under the door frame
		Vector3(1.5, 6.5, -62.0), Vector3(2.6, 9.0, -69.0),  # up the kettle steam
		Vector3(1.0, 8.0, -80.0), Vector3(0.0, 7.5, -88.0),  # out of the window
		Vector3(-0.5, 7.0, -100.0),  # over the fence into the hay field's warm air
		Vector3(-1.0, 9.0, -112.0),
	]) + route(route_name)["line"]


## Outdoor routes, each a line to follow from the hay field on and the circles to fly on the
## way (see `orbits`); every route starts by circling up the hay-field thermal.
##   "lavender": glide down the valley and circle down onto the lavender.
##   "chain":    the whole chain of thermals (barn, ploughed field, bonfire), then home to the lavender.
##   "ridge":    along the ridge, over the ploughed field, then home to the lavender.
##   "picnic":   along the ridge, then over the crest to land on the picnic blanket.
static func route(route_name: String) -> Dictionary:
	var hay := _climb(Course.HAY_FIELD)
	var lavender := Vector2((Course.LAVENDER_X.x + Course.LAVENDER_X.y) * 0.5, (Course.LAVENDER_Z.x + Course.LAVENDER_Z.y) * 0.5)
	var land := {"centre": lavender, "radius": 7.0, "to_y": Course.ground_height(lavender.x, lavender.y) + 0.5, "up": false, "max_time": 40.0}
	var home := PackedVector3Array([Vector3(-5.0, 4.0, -181.0), Vector3(-5.0, 1.0, -195.0)])
	var along_ridge := PackedVector3Array([Vector3(-20.0, 19.0, -140.0), Vector3(-35.0, 21.0, -160.0), Vector3(-37.0, 27.0, -190.0), Vector3(-37.0, 30.5, -212.0)])
	match route_name:
		"chain":
			return {"line": PackedVector3Array([
				Vector3(14.0, 20.0, -145.0), Vector3(30.0, 22.0, -160.0),  # to the barn
				Vector3(12.0, 25.0, -195.0), Vector3(-8.0, 24.0, -210.0),  # to the ploughed field
				Vector3(10.0, 26.0, -240.0), Vector3(30.0, 24.0, -262.0),  # to the bonfire
				Vector3(42.0, 23.0, -252.0), Vector3(25.0, 18.0, -215.0), Vector3(0.0, 12.0, -195.0)]) + home,  # round and home
				"orbits": [hay, _climb(Course.BARN_ROOF), _climb(Course.PLOUGHED_FIELD), _climb(Course.BONFIRE_SMOKE), land]}
		"ridge":
			return {"line": along_ridge + PackedVector3Array([Vector3(-20.0, 27.0, -215.0), Vector3(-8.0, 20.0, -200.0)]) + home,
				"orbits": [hay, _climb(Course.PLOUGHED_FIELD), land]}
		"picnic":
			var picnic := Vector3((Course.PICNIC_X.x + Course.PICNIC_X.y) * 0.5, 0.0, (Course.PICNIC_Z.x + Course.PICNIC_Z.y) * 0.5)
			picnic.y = Course.ground_height(picnic.x, picnic.z)
			# Over the crest, circle down over the blanket, then glide in onto it.
			var over_crest := PackedVector3Array([Vector3(-42.0, 30.5, -222.0), Vector3(-52.0, 29.5, -222.0), Vector3(-60.0, 28.0, -212.0)])  # a rounded turn
			return {"line": along_ridge + over_crest + PackedVector3Array([picnic + Vector3(0.0, -0.5, 0.0), picnic + Vector3(-15.0, -1.0, 0.0)]),
				"orbits": [hay, {"centre": Vector2(picnic.x, picnic.z), "radius": 6.0, "to_y": picnic.y + 2.5, "up": false, "max_time": 30.0}]}
	return {"line": PackedVector3Array([Vector3(-3.0, 17.0, -150.0)]) + home, "orbits": [hay, land]}


## Circle up a thermal to a little under its top.
static func _climb(thermal: Dictionary) -> Dictionary:
	return {"centre": thermal["at"], "radius": 6.0, "to_y": float(thermal["top"]) - 2.0, "up": true, "max_time": 25.0}


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


## While circling, a point a little way round the circle (turning right), a little above (or
## below) the plane. Starts and ends the circles.
func _orbit_aim(p: Vector3) -> Vector3:
	_orbit_time += 1.0 / 60.0
	if _orbit >= orbits.size():
		return p
	var o := orbits[_orbit]
	var centre: Vector2 = o["centre"]
	var radius: float = o["radius"]
	var to_y: float = o["to_y"]
	var off := Vector2(p.x, p.z) - centre
	if not _orbiting:
		if off.length() > radius * 1.3:
			return p
		_orbiting = true
		_orbit_time = 0.0
	var up: bool = o["up"]
	if (up and p.y >= to_y) or (not up and p.y <= to_y) or _orbit_time > float(o["max_time"]):
		if _orbit_time > float(o["max_time"]):
			push_warning("Autopilot gave up circling %s after %.0f s at y %.1f" % [centre, _orbit_time, p.y])
		_orbiting = false
		_orbit += 1
		_segment = -1  # find the line again from wherever the circle ended
		return p
	var around := off.angle() + 0.8
	var at := centre + Vector2.from_angle(around) * radius
	return Vector3(at.x, p.y + (1.5 if up else -1.0), at.y)


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
	var aim := _orbit_aim(p)
	if not _orbiting:
		# The first time, search the whole line (the pilot may start anywhere); then only nearby.
		var hit := Scoring.project(line, lengths, p) if _segment < 0 else Scoring.project(line, lengths, p, maxi(_segment - 1, 0), mini(_segment + 2, line.size() - 2))
		_segment = int(hit.z)
		var speed := plane.model.velocity.length()
		aim = point_at(hit.x + lookahead + speed * lookahead_time)

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
