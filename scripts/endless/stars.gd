# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessStars
extends Node3D
## Endless's stars (docs/endless-plan.md §4), in two draw calls: small stars (1 ★) and big stars
## (10 ★), spinning gold, laid in arcs along the ideal lines. Flying within the pickup radius takes
## a star. Taking every star of an arc is a full arc (a bonus, once); taking a star while an
## earlier one of its arc was missed, or flying on past an arc's end, breaks it, and its missed
## stars dim. Stars in a drifting thermal ride its air. Looks and bookkeeping only: the game plays
## the sounds and keeps the score.

const GOLD := Color("f4c84a")
const RIM := Color("fbf3d6")
const DIM := Color(0.86, 0.83, 0.74, 1.0)  ## A missed star's colour, multiplied in.
const SMALL_SIZE := 0.9
const BIG_SIZE := 2.2
const SPIN := 2.4  ## Radians/second.
## An arc closes once the plane is this far past its last star (along the course).
const CLOSE_PAST := 10.0
const SMALL_CAPACITY := 512
const BIG_CAPACITY := 64

## One star: where it is (world, or relative to its zone's home if it rides a thermal), its arc,
## whether it is big, taken, or missed.
class Star:
	var at := Vector3.ZERO
	var zone: Thermal
	var arc := 0
	var big := false
	var taken := false
	var missed := false
	var tile := 0
	var phase := 0.0
	var shown_from := Vector3.ZERO  ## Where it was drawn when it last moved (it slides from there).
	var slide := 1.0  ## 0..1 through that slide.

	func position() -> Vector3:
		return at + (zone.drift_offset if is_instance_valid(zone) else Vector3.ZERO)


## One arc: its stars in order, its bonus pop-up, whether a full arc pays a bonus, and its state.
class Arc:
	var name := ""  ## The kit's name for it, for logs.
	var stars: Array[Star] = []
	var title := ""
	var bonus := true
	var broken := false
	var closed := false
	var end_z := 0.0  ## The furthest along (most negative z) of its stars, before any drift.
	var tile := 0
	## An alternative line (the viaduct's deck): not counted in the share of stars taken.
	var alt := false
	## A spiral round a thermal ({radius, rise, step (degrees), top (world y)}), or empty. It is laid
	## where the pilot starts circling (see _watch_spiral()).
	var spiral := {}
	var anchored := false


## What happened at one pickup check.
class Pickup:
	var star: Star
	var arc: Arc
	var first := false  ## The first star taken of its arc.
	var full_arc := false  ## This star finished a full arc (and it pays a bonus).
	var broke := false  ## This star broke its arc (an earlier one was missed).

var tuning: Tuning
var arcs: Array[Arc] = []
var stars: Array[Star] = []
## Arcs flown past with stars missed since the last check (for the log).
var closed_broken: Array[Arc] = []
## Every arc that closed (finished, or flown past) at the last check.
var closed_now: Array[Arc] = []
## Stars taken and missed this run (each star counts once, big or small).
var taken_total := 0
var missed_total := 0
var _small: MultiMeshInstance3D
var _big: MultiMeshInstance3D
var _time := 0.0
var _ticks := 0  ## check() calls: physics ticks.
## A spiral is laid once the pilot has turned this far (radians) inside its thermal.
const SPIRAL_TURN := 2.094
## Its next star is laid this far (units of arc) ahead of the pilot: beyond the pickup reach.
const SPIRAL_LEAD := 4.5
## At most one spiral star in this many physics ticks (0.25 s).
const SPIRAL_GAP_TICKS := 15


func _ready() -> void:
	_small = _multimesh(build_star_mesh(SMALL_SIZE), SMALL_CAPACITY)
	_big = _multimesh(build_star_mesh(BIG_SIZE), BIG_CAPACITY)


func _multimesh(mesh: ArrayMesh, capacity: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = capacity
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Art.material(true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mi


## Adds a piece's arcs: `kit_arcs` as EndlessPieces.Kit.arcs, placed at `origin`; `zones` maps a
## zone name to its Thermal (for stars that ride a drifting thermal).
func add_piece(tile: int, kit_arcs: Array[Dictionary], origin: Vector3, zones: Dictionary, h_in := INF) -> void:
	for a in kit_arcs:
		var arc := Arc.new()
		arc.name = a.get("name", "")
		arc.title = a["title"]
		arc.bonus = a["bonus"]
		arc.alt = a.get("alt", false)
		arc.tile = tile
		if a.has("spiral"):
			arc.spiral = (a["spiral"] as Dictionary).duplicate()
			arc.spiral["top"] = origin.y + float(arc.spiral["top"])
		arc.end_z = INF
		var zone: Thermal = zones.get(a["zone"]) if a["zone"] != "" else null
		var points: PackedVector3Array = a["stars"]
		if a.has("entry_rise") and h_in < float(a["entry_below"]):  # a low entry: the line rises from it
			points = points.duplicate()
			for i in points.size():
				points[i].y = minf(float(a["entry_top"]), h_in - 1.0 + float(a["entry_rise"]) * i)
		var bigs: Array = a["big"]
		for i in points.size():
			var s := Star.new()
			s.at = origin + points[i]
			s.zone = zone
			s.arc = arcs.size()
			s.big = bigs[i]
			s.tile = tile
			s.phase = fmod(points[i].x * 0.37 + points[i].z * 0.21, TAU)
			arc.stars.append(s)
			stars.append(s)
			arc.end_z = minf(arc.end_z, s.at.z)
		arcs.append(arc)


## Forgets every star of the tiles before `tile` (left behind).
func remove_before(tile: int) -> void:
	arcs = arcs.filter(func(a: Arc) -> bool: return a.tile >= tile)
	stars.clear()
	for i in arcs.size():
		for s in arcs[i].stars:
			s.arc = i
			stars.append(s)


func clear() -> void:
	arcs.clear()
	stars.clear()
	taken_total = 0
	missed_total = 0


## Takes any star within reach of `at` (the plane, moving at `velocity`) and closes arcs flown
## past. Returns what was taken, in order.
func check(at: Vector3, velocity := Vector3.ZERO) -> Array[Pickup]:
	var out: Array[Pickup] = []
	closed_now.clear()
	_ticks += 1
	for arc in arcs:
		if not arc.spiral.is_empty() and not arc.anchored:
			_watch_spiral(arc, at, velocity)
	var small_r := tuning.star_pickup_radius if tuning else 1.4
	var big_r := tuning.big_star_pickup_radius if tuning else 1.5
	var spiral_r := tuning.spiral_pickup_radius if tuning else 3.0
	for s in stars:
		if s.taken:
			continue
		var p := s.position()
		var reach := big_r if s.big else (spiral_r if not arcs[s.arc].spiral.is_empty() else small_r)
		if absf(p.z - at.z) > reach or p.distance_squared_to(at) > reach * reach:
			continue
		if not arcs[s.arc].spiral.is_empty() and _ticks - int(arcs[s.arc].spiral.get("taken_at", -1000)) < SPIRAL_GAP_TICKS:
			continue  # one spiral star at a time
		s.taken = true
		var arc := arcs[s.arc]
		if not arc.alt:
			taken_total += 1
		var pick := Pickup.new()
		pick.star = s
		pick.arc = arc
		pick.first = arc.stars.filter(func(o: Star) -> bool: return o.taken).size() == 1
		if not arc.spiral.is_empty():
			# A spiral keeps no order; once laid, the rest re-form ahead at every star, so only
			# flying away misses them.
			arc.spiral["taken_at"] = _ticks
			if arc.anchored:
				_lay_spiral(arc, at, velocity)
		else:
			for other in arc.stars:  # an earlier star of this arc left behind breaks it
				if other == s:
					break
				if not other.taken and not other.missed:
					other.missed = true
					if not arc.alt:
						missed_total += 1
					if not arc.broken:
						arc.broken = true
						pick.broke = true
		if not arc.broken and not arc.closed and arc.stars.all(func(o: Star) -> bool: return o.taken):
			arc.closed = true
			closed_now.append(arc)
			pick.full_arc = arc.bonus and arc.stars.size() > 1
		out.append(pick)
	closed_broken.clear()
	for arc in arcs:
		# (an arc in a drifting thermal moves with it, and so does a pilot circling there)
		var drift := arc.stars[0].zone.drift_offset.z if not arc.stars.is_empty() and is_instance_valid(arc.stars[0].zone) else 0.0
		if not arc.closed and at.z < arc.end_z + drift - CLOSE_PAST:
			arc.closed = true
			closed_now.append(arc)
			var was_broken := arc.broken
			for s in arc.stars:
				if not s.taken and not s.missed:
					s.missed = true
					if not arc.alt:
						missed_total += 1
					arc.broken = true
			if arc.broken and not was_broken:
				closed_broken.append(arc)
	return out


## A spiral is laid only once the pilot is really circling its thermal: turned at least
## SPIRAL_TURN of heading while inside its air (plan view), below the top. Until then the drawn
## helix waits low on its near side, as the invitation. (A helix laid in advance only suits a pilot
## who arrives at exactly its start, height and place: climbing at the same rate, anyone else stays
## out of step all the way up; and laying it on any pass by let a straight fly-past take them all.)
func _watch_spiral(arc: Arc, at: Vector3, velocity: Vector3) -> void:
	var zone := arc.stars[0].zone if not arc.stars.is_empty() else null
	if not is_instance_valid(zone):
		return
	var flat := Vector2(velocity.x, velocity.z)
	var off := Vector2(at.x - zone.global_position.x, at.z - zone.global_position.z)
	if off.length() > zone.radius or flat.length() < 1.0 or at.y > float(arc.spiral["top"]) - 3.0:
		arc.spiral["turned"] = 0.0
		arc.spiral.erase("heading")
		return
	var heading := flat.angle()
	if arc.spiral.has("heading"):
		arc.spiral["turned"] = float(arc.spiral.get("turned", 0.0)) + wrapf(heading - float(arc.spiral["heading"]), -PI, PI)  # signed: weaving cancels out
	arc.spiral["heading"] = heading
	if absf(float(arc.spiral.get("turned", 0.0))) >= SPIRAL_TURN:
		arc.anchored = true
		_lay_spiral(arc, at, velocity)


## Which way the plane is going round `zone`: +1 with the angle (as Vector2(x, z).angle()) rising,
## -1 the other way (+1 if it can't tell).
static func _turning(zone: Thermal, at: Vector3, velocity: Vector3) -> float:
	if not is_instance_valid(zone):
		return 1.0
	var from_centre := Vector2(at.x - zone.global_position.x, at.z - zone.global_position.z)
	var flat := Vector2(velocity.x, velocity.z)
	if from_centre.length() < 0.1 or flat.length() < 0.1:
		return 1.0
	return -1.0 if from_centre.normalized().cross(flat) < 0.0 else 1.0


## Lays the spiral's stars not yet taken ahead of the plane, judged afresh each time from how it
## is flying now: the way round, its distance from the thermal's middle, and its climb. The next
## star is SPIRAL_LEAD of arc ahead (out of reach, so one star never takes the next), each after it
## a step further round, as high again as the plane climbs in a step, the last below where climbs
## end. A re-lay that would move no star more than 1 u is skipped, so the spiral reads as forming
## ahead of you rather than jumping.
func _lay_spiral(arc: Arc, at: Vector3, velocity: Vector3) -> void:
	var zone := arc.stars[0].zone
	if not is_instance_valid(zone):
		return
	var left := arc.stars.filter(func(s: Star) -> bool: return not s.taken and not s.missed)
	if left.is_empty():
		return
	var top: float = arc.spiral["top"]
	var home := zone.global_position - zone.drift_offset
	var off := Vector2(at.x - zone.global_position.x, at.z - zone.global_position.z)
	var radius := clampf(off.length(), 4.5, maxf(zone.radius - 1.0, 4.5))  # where the pilot is circling
	var dir := _turning(zone, at, velocity)
	var speed := maxf(Vector2(velocity.x, velocity.z).length(), 1.0)
	var climb := maxf(velocity.y, 0.0)
	var step := deg_to_rad(float(arc.spiral["step"]))
	var lead := SPIRAL_LEAD / radius
	var rise := clampf(climb * step * radius / speed, 0.5, float(arc.spiral["rise"]))
	var first := at.y + climb * lead * radius / speed
	if left.size() > 1:
		rise = minf(rise, maxf((top - 2.5 - first) / (left.size() - 1), 0.0))
	var spots: Array[Vector3] = []
	var moves := 0.0
	for i in left.size():
		var a := off.angle() + dir * (lead + step * i)
		var spot := Vector3(home.x + cos(a) * radius, minf(first + rise * i, maxf(top - 2.5, first)), home.z + sin(a) * radius)
		spots.append(spot)
		moves = maxf(moves, spot.distance_to((left[i] as Star).at))
	if moves <= 1.0:
		return
	for i in left.size():
		var s: Star = left[i]
		s.shown_from = s.position()
		s.slide = 0.0
		s.at = spots[i]
	arc.end_z = INF
	for s in arc.stars:
		arc.end_z = minf(arc.end_z, s.at.z)


## Breaks the arc in progress (a bump or a snag): the arc whose last-taken star is the most
## recent, if it isn't finished. Returns true if one was broken.
func break_current() -> bool:
	for i in range(arcs.size() - 1, -1, -1):
		var arc := arcs[i]
		if arc.closed or arc.broken:
			continue
		if arc.stars.any(func(s: Star) -> bool: return s.taken):
			arc.broken = true
			for s in arc.stars:
				if not s.taken and not s.missed:
					s.missed = true
					if not arc.alt:
						missed_total += 1
			return true
	return false


## Stars still to take, for tests and the debug overlay.
func remaining() -> int:
	return stars.filter(func(s: Star) -> bool: return not s.taken).size()


func _process(delta: float) -> void:
	_time += delta
	_place(delta)


func _place(delta: float) -> void:
	var small := 0
	var big := 0
	var spin := Basis(Vector3.UP, _time * SPIN)
	for s in stars:
		if s.taken:
			continue
		var mm := _big.multimesh if s.big else _small.multimesh
		var i := big if s.big else small
		if i >= mm.instance_count:
			continue
		var at := s.position()
		if s.slide < 1.0:  # sliding to a new place
			s.slide = minf(s.slide + delta / 0.5, 1.0)
			at = s.shown_from.lerp(at, smoothstep(0.0, 1.0, s.slide))
		mm.set_instance_transform(i, Transform3D(spin.rotated(Vector3.UP, s.phase), at))
		mm.set_instance_color(i, DIM if s.missed or arcs[s.arc].broken else Color.WHITE)  # a broken line dims
		if s.big:
			big += 1
		else:
			small += 1
	_small.multimesh.visible_instance_count = small
	_big.multimesh.visible_instance_count = big


## A plump five-pointed star `size` across, standing upright: gold faces and a pale rim.
static func build_star_mesh(size: float) -> ArrayMesh:
	var b := Art.Builder.new()
	var outer := size * 0.5
	var inner := outer * 0.45
	var depth := size * 0.14
	var points: Array[Vector3] = []
	for i in 10:
		var a := PI * 0.5 + TAU * i / 10.0
		var r := outer if i % 2 == 0 else inner
		points.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
	var front := Vector3(0, 0, depth)
	var back := Vector3(0, 0, -depth)
	for i in 10:
		var a := points[i]
		var c := points[(i + 1) % 10]
		var tip := RIM if i % 2 == 0 else GOLD  # pale toward each point
		b.triangle(front, c, a, GOLD.lerp(tip, 0.3))  # front, toward +z: a low pyramid
		b.triangle(back, a, c, GOLD.darkened(0.06))  # back
	return b.commit()
