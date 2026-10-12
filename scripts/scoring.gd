class_name Scoring
extends RefCounted
## Distance and style points for one run.
##
## Distance is progress along the course's centre line (the furthest point reached), so it
## never goes backward and circling in a thermal doesn't pad it. Style points come from key
## moments: each has an optimal path and a corridor around it. A moment is graded on the
## plane's average distance from the path, measured along the whole path: any stretch the
## plane skipped counts as far off. Close to the path earns more, the award falls smoothly
## to zero at the corridor edge, and each moment pays at most once per run. Outdoors, time in
## the air pays too (up to a cap), and coming to rest on a landing spot pays a bonus. Point
## values, corridor sizes and the grading curve are in Tuning.

signal style_awarded(moment_id: StringName, title: String, points: int, quality: float)

## A key moment on the course.
class Moment:
	var id: StringName
	var title: String
	var path: PackedVector3Array
	var lengths: PackedFloat32Array  ## Arc length at each path point.
	var points := 0
	var radius := 1.0
	var engaged := false
	var finished := false
	var offset_area := 0.0  ## Sum of (distance from the path x distance along it).
	var covered := 0.0  ## How much of the path was flown while engaged.
	var last_along := 0.0
	var award := 0
	var quality := 0.0

var tuning: Tuning
var moments: Array[Moment] = []
var style_points := 0
## Seconds in the air outdoors (counted up to Tuning.airtime_max_seconds).
var airtime := 0.0
## The landing spot the run ended on ({} if none) and its bonus.
var landing := {}
var landing_points := 0
var _spine := PackedVector3Array()
var _spine_lengths := PackedFloat32Array()
var _spine_segment := 0
var _progress := 0.0
var _last_pos := Vector3.INF


## `spine` is the course centre line from the start point onward. Each entry of
## `moment_defs` is {"id": StringName, "title": String, "path": PackedVector3Array}.
func _init(p_tuning: Tuning, spine: PackedVector3Array, moment_defs: Array) -> void:
	tuning = p_tuning
	_spine = spine
	_spine_lengths = arc_lengths(spine)
	for def in moment_defs:
		var m := Moment.new()
		m.id = def["id"]
		m.title = def["title"]
		m.path = def["path"]
		m.lengths = arc_lengths(m.path)
		var values: Dictionary = tuning.style_moments.get(String(m.id), {})
		m.points = int(values.get("points", 0))
		m.radius = maxf(float(values.get("radius", 1.0)), 0.01)
		moments.append(m)


## Call once per physics tick with the plane's position.
func update(pos: Vector3) -> void:
	_update_distance(pos)
	for m in moments:
		_update_moment(m, pos)


func distance_meters() -> float:
	return _progress / tuning.units_per_meter


func distance_points() -> int:
	return roundi(distance_meters() * tuning.points_per_meter)


## Whole seconds in the air outdoors, as paid and shown.
func airtime_seconds() -> int:
	return floori(minf(airtime, tuning.airtime_max_seconds) + 0.0001)


func airtime_points() -> int:
	return roundi(airtime_seconds() * tuning.airtime_points_per_second)


func total() -> int:
	return distance_points() + style_points + airtime_points() + landing_points


## Counts `delta` seconds in the air outdoors.
func add_airtime(delta: float) -> void:
	airtime = minf(airtime + delta, tuning.airtime_max_seconds)


## The run came to rest at `pos` (not a crash): a landing bonus if it is on a landing spot.
## Pays at most once.
func land(pos: Vector3, spots: Array) -> void:
	if not landing.is_empty():
		return
	for spot: Dictionary in spots:
		if (spot["area"] as Rect2).has_point(Vector2(pos.x, pos.z)):
			landing = spot
			landing_points = int(tuning.landing_bonus.get(spot["id"], 0))
			return


## 1 on the optimal path, falling smoothly to 0 at the corridor edge. `offset` is the
## average distance from the path as a fraction of the corridor radius.
static func grade(offset: float, t: Tuning) -> float:
	if offset >= 1.0:
		return 0.0
	var q := 1.0 - smoothstep(t.style_full_fraction, 1.0, maxf(offset, 0.0))
	return pow(q, t.style_curve_power)


static func arc_lengths(path: PackedVector3Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var total_length := 0.0
	for i in path.size():
		if i > 0:
			total_length += path[i].distance_to(path[i - 1])
		out.append(total_length)
	return out


## Closest point to `p` on segments first..last of a polyline. Returns
## Vector3(arc length there, distance to it, segment index). The arc length extends past
## the ends of the path (negative before the start, beyond the length after the end).
static func project(path: PackedVector3Array, lengths: PackedFloat32Array, p: Vector3, first := 0, last := -1) -> Vector3:
	if last < 0:
		last = path.size() - 2
	var best := Vector3(0.0, INF, first)
	for i in range(first, last + 1):
		var a := path[i]
		var ab := path[i + 1] - a
		var raw := (p - a).dot(ab) / maxf(ab.length_squared(), 0.000001)
		var t := clampf(raw, 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best.y:
			var along := t
			if (i == 0 and raw < 0.0) or (i == path.size() - 2 and raw > 1.0):
				along = raw
			best = Vector3(lengths[i] + along * ab.length(), d, i)
	return best


func _update_distance(pos: Vector3) -> void:
	if _spine.size() < 2:
		return
	# Only look at the current and neighbouring segments, and never advance faster than the
	# plane actually moves, so passing close to another part of the house can't make the
	# distance jump.
	var first := maxi(_spine_segment - 1, 0)
	var last := mini(_spine_segment + 1, _spine.size() - 2)
	var hit := project(_spine, _spine_lengths, pos, first, last)
	_spine_segment = int(hit.z)
	var reached := clampf(hit.x, 0.0, _spine_lengths[_spine_lengths.size() - 1])
	if _last_pos != Vector3.INF:
		reached = minf(reached, _progress + pos.distance_to(_last_pos) * 1.25)
	_last_pos = pos
	_progress = maxf(_progress, reached)


func _update_moment(m: Moment, pos: Vector3) -> void:
	if m.finished or m.path.size() < 2:
		return
	var hit := project(m.path, m.lengths, pos)
	var along := hit.x
	var offset := hit.y
	var capture := m.radius * tuning.style_capture_factor
	if along < 0.0:
		return
	var length := m.lengths[m.lengths.size() - 1]
	if along <= length:
		if not m.engaged and offset <= capture:
			m.engaged = true
			m.last_along = along
		if m.engaged:
			_cover(m, along, minf(offset, capture))
		return
	if m.engaged:
		_cover(m, length, minf(offset, capture))
		_finish(m, capture)


## Credits the stretch of path from the last point reached to `along` at `offset`.
## Going backward along the path earns nothing extra.
func _cover(m: Moment, along: float, offset: float) -> void:
	var step := along - m.last_along
	if step > 0.0:
		m.offset_area += offset * step
		m.covered += step
		m.last_along = along


func _finish(m: Moment, capture: float) -> void:
	m.finished = true
	var length := m.lengths[m.lengths.size() - 1]
	var skipped := maxf(length - m.covered, 0.0)
	var average := (m.offset_area + skipped * capture) / maxf(length, 0.0001)
	m.quality = grade(average / m.radius, tuning)
	m.award = roundi(m.points * m.quality)
	if m.award > 0:
		style_points += m.award
		style_awarded.emit(m.id, m.title, m.award, m.quality)
