# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessForks
extends RefCounted
## Endless's forks (docs/forks-plan.md): a 3-tile piece whose valley splits round a wooded spine
## too tall to fly over into two roads, which meet again beyond it. The low road has more than
## twice the stars and tight flying; the high road opens with a big thermal and leaves you higher.
## A fingerpost and two short lines of stars at the split show both ways (gold for stars, blue for
## lift, the same on every fork). Both roads are always built (a fork's kit uses no RNG beyond
## fixed seeds), so the daily flight's country is the same whichever road is flown.
##   F1 Gorge or Down: the Gorge (left, low: three footbridges, a lime kiln's smoke, the quarry's
##   thermal) or the High Down (right: the white scar's thermal, the brow's lift, the knoll's).
##   F2 River or Rail: the River (right, low: three humpback bridges over the water, a warm cliff,
##   the water meadow's thermal) or the Railway (left: the cinder yard's thermal, the embankment,
##   the brickworks' smoke, the engine's steam). The Viaduct always follows it.

const GORGE_DOWN := &"gorge_down"
const RIVER_RAIL := &"river_rail"
const LENGTH := 288.0
const SPLIT := 36.0  ## How far each road's middle moves out from the valley's.
const SPINE_TOP := 38.0
## Where on a fork the game decides your road: from this far in once the spine is too tall to
## cross from your height (by this much), and at the latest this far in.
const COMMIT_FROM := 40.0
const COMMIT_CLEAR := 2.0
const COMMIT_BY := 100.0
## How strongly the breeze splits round a fork's nose (u/s sideways, at the middle).
const SPLIT_BREEZE := 1.6
const BRIDGES_F1: Array[float] = [-112.0, -138.0, -164.0]
const BRIDGES_F2: Array[float] = [-100.0, -136.0, -172.0]
const GOLD := Color("f4c84a")
const SKY := Color("a9c8e8")
const RAIL_RED := Color("c1675a")
const CINDER := Color("8a8496")
const SANDSTONE := Color("e9c98a")


## Which side the low road takes (-1 left, +1 right).
static func low_side(id: StringName) -> float:
	return -1.0 if id == GORGE_DOWN else 1.0


## How far each road's middle is from the valley's at fork-local z.
static func split_x(z: float) -> float:
	return SPLIT * smoothstep(12.0, 72.0, -z) * (1.0 - smoothstep(204.0, 264.0, -z))


## The spine's crest height at fork-local z: rising from its nose's toe at -36, full from -100 to
## -196, gone by -236.
static func spine_h(z: float) -> float:
	return SPINE_TOP * smoothstep(36.0, 100.0, -z) * (1.0 - smoothstep(196.0, 236.0, -z))


## The middle of a road ("low" or "high") at fork-local z.
static func road_x(id: StringName, road: String, z: float) -> float:
	return split_x(z) * low_side(id) * (1.0 if road == "low" else -1.0)


## One road's cross-section, `u` from its middle, narrowing (and its sides steepening) as the
## split opens (`s` 0..1): the standard valley at s 0.
static func _section(u: float, s: float) -> float:
	return lerpf(EndlessPieces.SIDE, 0.04, s) * pow(maxf(absf(u) - lerpf(EndlessPieces.FLOOR, 14.0, s), 0.0), 2.0)


## A fork's ground (before rolls): the two roads' valleys, the spine between them, and each road's
## own shaping (the gorge and the brow; the river's cut, its cliff and the embankment).
static func ground(id: StringName, x: float, z: float) -> float:
	var X := split_x(z)
	var s := X / SPLIT
	var h := minf(_section(x + X, s), _section(x - X, s))
	h = maxf(h, spine_h(z) * (1.0 - smoothstep(6.0, 18.0, absf(x))))
	var side := low_side(id)
	var low_u := x - side * X
	var high_u := x + side * X
	if id == GORGE_DOWN:
		var g := gorge_walls(z)
		var a := absf(low_u)
		var wall := 0.0 if a <= 6.0 else (24.0 * (a - 6.0) / 6.0 if a <= 12.0 else (24.0 + 2.0 * minf(a - 12.0, 6.0) / 6.0))
		wall *= 1.0 - smoothstep(30.0, 36.0, -side * low_u)  # inward the rim meets the spine, and stops at the valley's middle
		h = maxf(h, wall * g)
		var brow := 10.0 * smoothstep(104.0, 140.0, -z) * (1.0 - smoothstep(160.0, 196.0, -z)) * smoothstep(8.0, 14.0, -side * x)  # (meets the spine's flank: no trough)
		h = maxf(h, brow)
	else:
		var cut := smoothstep(72.0, 88.0, -z) * (1.0 - smoothstep(192.0, 208.0, -z))
		h -= 3.0 * maxf(1.0 - absf(low_u) / 6.0, 0.0) * cut
		var cliff := 12.0 * smoothstep(7.0, 11.0, side * low_u) * smoothstep(92.0, 100.0, -z) * (1.0 - smoothstep(200.0, 208.0, -z))
		var bank := smoothstep(70.0, 84.0, -z) * (1.0 - smoothstep(200.0, 214.0, -z))
		var embankment := clampf(4.0 - maxf(absf(high_u) - 4.0, 0.0) * 0.7, 0.0, 4.0) * bank
		for rise in [cliff, embankment]:  # (only where they stand: elsewhere they'd fill the river's cut)
			if rise > 0.0:
				h = maxf(h, rise)
	return h


## How far the gorge's walls have risen at fork-local z (0..1): over 40 u at its mouth, so they
## glance a flyer off rather than stop it.
static func gorge_walls(z: float) -> float:
	return smoothstep(68.0, 108.0, -z) * (1.0 - smoothstep(180.0, 196.0, -z))


## Whether a flyer at fork-local `at` has had its road decided, and which: "" (not yet), "low" or
## "high". From COMMIT_FROM in, once the spine there stands COMMIT_CLEAR above it (it can't cross
## any more), or at COMMIT_BY whatever: by the side it is on.
static func road_at(id: StringName, at: Vector3) -> String:
	if -at.z < COMMIT_FROM:
		return ""
	if -at.z < COMMIT_BY and spine_h(at.z) < at.y + COMMIT_CLEAR:
		return ""
	return "low" if signf(at.x) == low_side(id) else "high"  # (dead centre: the high road, as the breeze splits)


## The fork's things: the frame both forks share, then its two roads.
static func content(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	for part in PARTS:
		content_part(k, look, solid, d, part)


## A fork's things are built in PARTS steps (a kit is built a step at a time: a fork's whole
## content at once took 15 ms on the PC, a stall on a phone): the frame, the low road, the high
## road, and then its lines and circles.
const PARTS := 5


static func content_part(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float, part: int) -> void:
	var side := low_side(k.id)
	match part:
		0:
			k.fork = {"low_side": side, "lines": {"low": [], "high": []}, "orbits": {"low": [], "high": []}}
			k.fork["where"] = {"low": "in the Gorge", "high": "on the High Down"} if k.id == GORGE_DOWN else {"low": "on the River", "high": "on the Railway"}
			_frame(k, look, solid, side)
		1:
			if k.id == GORGE_DOWN:
				_gorge(k, look, solid, d)
			else:
				_river_water(k, look, solid, d)
		2:
			if k.id == RIVER_RAIL:
				_river(k, look, solid, d)
		3:
			if k.id == GORGE_DOWN:
				_high_down(k, look, solid, d)
			else:
				_railway(k, look, solid, d)
		4:
			k.line_points.assign(k.fork["lines"]["low"])  # (a fork's line() is its low road's; see Kit.fork)
			k.orbits.assign(k.fork["orbits"]["low"] + k.fork["orbits"]["high"])


# --- The frame ---------------------------------------------------------------------

## The spine's woods, the fingerpost at the split and the two signpost lines of stars.
static func _frame(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, side: float) -> void:
	for i in 28:  # beech and pine along the crest, solid as usual: a wooded hill, not a ramp
		var x := (-1.0 if i % 2 == 0 else 1.0) * (3.0 + float((i * 7) % 6))  # staggered across x 3..8
		var z := -84.0 - i * 4.0
		var spot := {"base": Vector3(x, EndlessPieces.grid_height(k.id, x, z), z), "s": 1.0 + 0.25 * sin(i * 1.7), "pine": i % 3 == 1}
		if not spot["pine"]:
			spot["leaf"] = EndlessPieces.LEAF[i % 2]
		EndlessPieces._tree(look, solid, spot)
	# The fingerpost on the nose's toe (looks only): a gold arm to the low road, a blue one to the high.
	var foot := Vector3(0.0, EndlessPieces.grid_height(k.id, 0.0, -40.0), -40.0)
	look.cylinder(foot, 0.22, 0.18, 11.0, EndlessPieces.CREAM, 6)
	for road in ["low", "high"]:
		var dir := side * (1.0 if road == "low" else -1.0)
		var arm := Basis(Vector3.UP, -dir * deg_to_rad(55.0))  # 35 degrees forward of straight across
		var mid := foot + Vector3(0.0, 9.5 if road == "low" else 10.5, 0.0) + arm * Vector3(dir * 2.75, 0.0, 0.0)
		look.box(mid, Vector3(5.5, 1.0, 0.2), GOLD if road == "low" else SKY, arm)
		for j in 3:
			var on := mid + arm * Vector3(dir * (j - 1) * 1.5, 0.0, 0.14)
			if road == "low":
				look.sphere(on, 0.17, EndlessPieces.CREAM, Vector3(1.0, 1.0, 0.4), 5, 3)  # little stars
			else:
				look.sphere(on + Vector3(0, 0.05 * j, 0), 0.24 - 0.04 * j, Color.WHITE, Vector3(1.0, 0.8, 0.4), 6, 3)  # a cloud puff
	for road in ["low", "high"]:
		var dir := side * (1.0 if road == "low" else -1.0)
		# (a gentle lean, about 30 degrees off straight on: still a choice at the first star, and
		# one a pilot carried fast by a strong breeze can make)
		var stars := PackedVector3Array([Vector3(dir * 3.0, 17.0, -16.0), Vector3(dir * 7.0, 16.5, -23.0), Vector3(dir * 11.0, 16.0, -30.0)])
		if road == "high":  # on toward the high road's thermal, so its line leads somewhere
			stars.append_array([Vector3(dir * 16.0, 15.5, -36.0), Vector3(dir * 21.0, 15.0, -42.0)])
		k.arcs.append({"name": "signpost %s" % road, "stars": stars, "big": EndlessPieces._no_big(stars.size()), "zone": "", "title": "Full arc!",
			"bonus": true, "road": road, "follow_entry": 0.5})  # (at the height you really come in at: see EndlessStars)
		var line: Array = k.fork["lines"][road]
		line.append({"x": 0.0, "z": -6.0, "dy": 0.0})
		for j in stars.size():
			line.append({"x": stars[j].x, "z": stars[j].z, "dy": -1.0 - 0.5 * j, "max": stars[j].y})


## A thermal of a fork's road: its zone, cloud and birds, a spiral of stars if `spiral` stars, and
## the pilot's circle (to `to_y`, or near its top).
static func _road_thermal(k: EndlessPieces.Kit, road: String, zone: String, c: Vector2, radius: float, strength: float, top: float, spiral: int, d: float, to_y := -1.0, spiral_from := 9.0) -> void:
	var floor_y := ground(k.id, c.x, c.y)
	k.zones.append({"name": zone, "shape": Thermal.Shape.CYLINDER, "at": Vector3(c.x, floor_y, c.y), "radius": radius,
		"height": top - floor_y, "look": Thermal.Look.WARM_AIR, "strength": strength, "pitch": 1.0, "drifts": true})
	k.clouds.append({"at": Vector3(c.x, top + 4.0, c.y), "radius": radius * 0.7, "puffs": 4, "zone": zone})
	k.birds.append({"zone": zone, "below_top": 4.0})
	if spiral > 0:
		EndlessPieces._spiral(k, "%s spiral" % zone.to_lower(), zone, c, spiral_from, top, spiral, d)
		k.arcs[-1]["road"] = road
	(k.fork["orbits"][road] as Array).append({"centre": c, "zone": zone, "radius": 6.0, "to_y": to_y if to_y > 0.0 else top - 2.0, "up": true, "max_time": 25.0, "road": road})


static func _arc(k: EndlessPieces.Kit, road: String, arc_name: String, stars: PackedVector3Array, big: Array, title := "Full arc!") -> void:
	k.arcs.append({"name": arc_name, "stars": stars, "big": big, "zone": "", "title": title, "bonus": true, "road": road})


static func _line(k: EndlessPieces.Kit, road: String, points: Array) -> void:
	for p in points:
		(k.fork["lines"][road] as Array).append(p if p is Dictionary else {"at": p})


## A painted triangle lying on the ground (looks only).
static func _paint(k: EndlessPieces.Kit, look: Art.Builder, pts: Array[Vector2], color: Color) -> void:
	var v: Array[Vector3] = []
	for p in pts:
		v.append(Vector3(p.x, EndlessPieces.grid_height(k.id, p.x, p.y) + EndlessPieces.PAINT_LIFT * 2.0, p.y))
	look.triangle(v[0], v[1], v[2], color)
	look.triangle(v[0], v[2], v[1], color)  # (both faces: the slopes face every way)


# --- F1 Gorge or Down ----------------------------------------------------------------

## The Gorge (the low road): dive in and fly under three footbridges (a big star under the middle
## one), held up low by the breeze between the walls; the lime kiln's smoke lifts you out, and the
## quarry's thermal follows.
static func _gorge(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var x := -SPLIT
	var under := lerpf(8.0, 6.5, d)
	var bridges := PackedVector3Array()
	var big: Array = []
	for i in BRIDGES_F1.size():
		var z: float = BRIDGES_F1[i]
		var span := 9.0 + (under / 24.0) * 6.0 + 1.0  # wall to wall where the walls reach the deck
		look.box(Vector3(x, under + 0.5, z), Vector3(span * 2.0, 1.0, 2.0), Color("b8946f"))
		EndlessPieces._box_faces(solid, Vector3(x, under + 0.5 + EndlessPieces.HOLE_GRACE * 0.5, z), Vector3(span * 2.0, 1.0 - EndlessPieces.HOLE_GRACE, 2.0))
		for edge in [-1.0, 1.0]:  # rounded leading and trailing edges, so a clip glances
			var xf := Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(x, under + 0.5 + EndlessPieces.HOLE_GRACE, z + edge))
			look.add_triangles(Art.cylinder_triangles(0.5, 0.5, span * 2.0, 8), xf, Color("a8835f"))
			EndlessPieces._faces(solid, Art.cylinder_triangles(0.5, 0.5, span * 2.0, 8), xf)
			look.box(Vector3(x, under + 1.5, z + edge * 0.9), Vector3(span * 2.0, 1.0, 0.12), RAIL_RED)
		k.arches.append({"z": z, "depth": 2.0, "openings": [{"x": x, "half_span": 6.0, "springing": under - 6.0}], "pass_speed": 6.3})
		var y := lerpf(4.5, 4.0, d)
		for dz in [4.0, 0.0, -4.0]:
			bridges.append(Vector3(x, y, z + dz))
			big.append(i == 1 and dz == 0.0)
	for i in 7:  # dark boulders on the walls' lower slopes
		var bz := -100.0 - i * 13.0
		var bx := x + (7.5 if i % 2 == 0 else -7.5)
		look.sphere(Vector3(bx, EndlessPieces.grid_height(k.id, bx, bz) + 0.4, bz), 0.9 + 0.2 * (i % 3), Color("8f887c"), Vector3(1.3, 0.8, 1.1), 7, 4)
	# The breeze up the gorge holds a low glide level (as the warm layers do).
	EndlessPieces._warm_layer(k, "Gorge", Vector3(x, 0.0, -136.0), Vector3(12.0, 9.0, 88.0), d)
	# The lime kiln, built into the outer wall, and its smoke over the gorge floor.
	var kiln := Vector3(x - 9.0, 0.0, -184.0)
	look.box(kiln + Vector3(-1.0, 4.0, 0.0), Vector3(5.0, 8.0, 7.0), EndlessPieces.STONE_DARK)
	look.box(kiln + Vector3(1.6, 1.4, 0.0), Vector3(0.3, 2.2, 2.0), Color("f19e5f"))  # its glowing draw arch
	k.zones.append({"name": "Kiln", "shape": Thermal.Shape.CYLINDER, "at": Vector3(x, 2.0, -186.0), "radius": lerpf(4.5, 4.0, d), "height": 19.0,
		"look": Thermal.Look.STEAM, "strength": lerpf(1.3, 1.2, d), "pitch": 1.08, "drifts": false})
	var dive := PackedVector3Array()
	for i in 7:
		var t := i / 6.0
		dive.append(Vector3(lerpf(-22.0, x, smoothstep(0.0, 1.0, t)), lerpf(14.5, 6.5, t), lerpf(-50.0, -86.0, t)))
	_arc(k, "low", "into the gorge", dive, EndlessPieces._no_big(7))
	k.arcs[-1]["from_entry"] = 6  # down from the height you really bring (the signpost costs a few)
	k.arcs[-1]["fit_below"] = 4.0
	_arc(k, "low", "footbridges", bridges, big, "Under the bridges!")
	var smoke := PackedVector3Array()
	for i in 4:  # up the smoke as a pilot rises through it: less steeply when the breeze carries it faster
		smoke.append(Vector3(x - 1.0 + 0.4 * i, 5.5 + lerpf(1.2, 0.85, d) * i, -183.0 - lerpf(2.4, 3.0, d) * i))
	_arc(k, "low", "kiln", smoke, EndlessPieces._no_big(4))
	var quarry := Vector2(-20.0, -224.0)
	for i in 6:  # the quarry's pale face on the spine's tail (looks)
		var zq := -216.0 - i * 3.0
		_paint(k, look, [Vector2(-8.0, zq), Vector2(-4.0, zq - 3.0), Vector2(-9.5, zq - 3.0)], Color("ece4d4"))
	_line(k, "low", [{"x": -22.0, "z": -50.0, "dy": -4.0, "max": 14.5}])
	_line(k, "low", Array(dive).slice(1))
	_line(k, "low", [Vector3(x, 4.5, -104.0)])
	_line(k, "low", Array(bridges))
	_line(k, "low", [Vector3(x, 4.5, -176.0)])
	_line(k, "low", Array(smoke))
	_line(k, "low", [Vector3(-34.0, 10.5, -192.0), Vector3(quarry.x, 8.0, quarry.y + 9.0)])
	var top := lerpf(24.0, 22.0, d)
	_road_thermal(k, "low", "Quarry", quarry, lerpf(11.0, 10.0, d), lerpf(0.85, 0.75, d), top, 6, d)
	_line(k, "low", [Vector3(-10.0, top - 4.0, -256.0), Vector3(-4.0, top - 5.0, -LENGTH)])


## The High Down (the high road): the white scar's thermal at its mouth, lift along the brow's
## windward face (the gull joins you), and the knoll's thermal; a chalk figure on the slope.
static func _high_down(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var scar := Vector2(30.0, -60.0)
	# The white scar: a patch of bare chalk on the outer slope beside the thermal.
	_paint(k, look, [Vector2(52.0, -50.0), Vector2(57.0, -54.0), Vector2(53.0, -66.0)], Color("f6f1e6"))
	_paint(k, look, [Vector2(57.0, -54.0), Vector2(58.0, -68.0), Vector2(53.0, -66.0)], Color("f6f1e6"))
	# A paper plane cut in the chalk of the far slope, nose down the valley: pure delight.
	var nose := Vector2(70.0, -40.0)
	var fold := Vector2(70.0, -55.0)
	_paint(k, look, [nose, Vector2(63.0, -58.0), fold], Color("f6f1e6"))
	_paint(k, look, [nose, fold, Vector2(77.0, -58.0)], Color("eee8dd"))
	var top := lerpf(28.0, 26.0, d)
	_line(k, "high", [{"x": 28.0, "z": -48.0, "dy": -3.0, "max": 17.0}])
	_road_thermal(k, "high", "Scar", scar, lerpf(12.0, 10.5, d), lerpf(0.9, 0.8, d), top, 0, d)
	k.zones.append({"name": "Brow", "shape": Thermal.Shape.BOX, "at": Vector3(SPLIT, 0.0, -122.0), "size": Vector3(24.0, 28.0, 36.0),
		"look": Thermal.Look.RIDGE, "strength": lerpf(0.4, 0.35, d), "pitch": 0.85, "drifts": false,
		"seed_amount": 60, "seed_centre_y": 18.0, "seed_half_height": 5.0})
	k.gull_lift = "Brow"
	var brow := PackedVector3Array()
	for i in 6:
		brow.append(Vector3(34.0, lerpf(25.0, 24.0, d), -136.0 - 6.0 * i))
	_arc(k, "high", "brow", brow, EndlessPieces._no_big(6))
	_line(k, "high", [Vector3(34.0, 25.0, -104.0)])
	_line(k, "high", Array(brow))
	var knoll := Vector2(22.0, -228.0)
	for i in 10:  # gorse ringing the knoll
		var a := TAU * i / 10.0
		var at := knoll + Vector2(cos(a), sin(a)) * 13.0
		look.sphere(Vector3(at.x, EndlessPieces.grid_height(k.id, at.x, at.y) + 0.2, at.y), 0.8, Color("e9c33c"), Vector3(1.3, 0.6, 1.0), 6, 3)
	_line(k, "high", [Vector3(knoll.x, 12.0, knoll.y + 10.0)])
	var knoll_top := lerpf(29.5, 29.0, d)  # (the high road leaves at least 4 over the low: calibrated)
	_road_thermal(k, "high", "Knoll", knoll, lerpf(11.0, 10.0, d), lerpf(0.85, 0.75, d), knoll_top, 3, d, -1.0, 20.0)
	_line(k, "high", [Vector3(12.0, knoll_top - 4.0, -258.0), Vector3(6.0, knoll_top - 5.0, -LENGTH)])


# --- F2 River or Rail ----------------------------------------------------------------

## The River (the low road): down to the water and under three humpback bridges (a big star under
## the last), rising between them in the warm cliff's lift, then the water meadow's thermal.
## Touching the water is a splashdown.
static func _river_water(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var side := low_side(k.id)
	var centre := func(z: float) -> float: return road_x(k.id, "low", z)
	# The water: drawn and solid from -80 to -200 (where the cut holds it), then a painted stream
	# curving back to the valley's middle and on into the Viaduct's river.
	var water := PackedVector3Array()
	var step := 4.0
	for i in 30:
		var za := -80.0 - i * step
		var zb := za - step
		var ca: float = centre.call(za)
		var cb: float = centre.call(zb)
		var pts := [Vector3(ca - 4.0, -1.0, za), Vector3(ca + 4.0, -1.0, za), Vector3(cb - 4.0, -1.0, zb), Vector3(cb + 4.0, -1.0, zb)]
		look.triangle(pts[0], pts[2], pts[1], EndlessPieces.WATER if i % 2 else EndlessPieces.WATER_LIGHT)
		look.triangle(pts[1], pts[2], pts[3], EndlessPieces.WATER if i % 2 else EndlessPieces.WATER_LIGHT)
		water.append_array([pts[0], pts[2], pts[1], pts[1], pts[2], pts[3]])
	solid.append_array(water)
	k.water = {"river": true, "side": side, "from": 80.0, "to": 200.0, "half": 4.0, "y": -1.0}
	EndlessPieces._strip(k, look, centre, 4.0, -200.0, -LENGTH, [EndlessPieces.WATER, EndlessPieces.WATER_LIGHT])
	EndlessPieces._strip(k, look, centre, 2.5, -10.0, -80.0, [EndlessPieces.WATER, EndlessPieces.WATER_LIGHT])
	# The sandstone cliff's face on the outer bank, and sand martins at it.
	for z in range(-100, -204, -8):
		var cx: float = centre.call(z) + side * 9.5
		look.box(Vector3(cx, 6.0, z - 4.0), Vector3(1.2, 11.0, 8.0), SANDSTONE.darkened(0.08 * (abs(z) / 8 % 2)))
	for z in range(-100, -204, -8):  # rose bands across it, and bushes along its top
		var cx: float = centre.call(z) + side * 9.4
		for band in [3.5, 7.5]:
			look.box(Vector3(cx, band, z - 4.0), Vector3(1.25, 1.0, 8.0), Color("dba58e"))
		if (z / 8) % 2 == 0:
			look.sphere(Vector3(cx + side * 1.6, 12.3, z - 4.0), 1.1, EndlessPieces.LEAF[0], Vector3(1.3, 0.8, 1.2), 7, 4)
	for z in [-120.0, -150.0, -180.0]:
		k.birds.append({"at": Vector3(SPLIT + side * 8.0, 9.0, z)})
	k.zones.append({"name": "Cliff", "shape": Thermal.Shape.BOX, "at": Vector3(side * 39.0, 0.0, -150.0), "size": Vector3(10.0, 18.0, 104.0),
		"look": Thermal.Look.RIDGE, "strength": lerpf(0.5, 0.4, d), "pitch": 0.9, "drifts": false,
		"seed_amount": 50, "seed_centre_y": 6.0, "seed_half_height": 4.0})


## The River's bridges, stars, line and thermal (after its water: see _river_water()).
static func _river(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var side := low_side(k.id)
	var centre := func(z: float) -> float: return road_x(k.id, "low", z)
	# Humpback bridges: a stone arch over the water, each built in slices across.
	var crown := lerpf(5.5, 4.0, d)
	var under := PackedVector3Array()
	var big: Array = []
	var low_y := lerpf(2.5, 1.75, d)
	for i in BRIDGES_F2.size():
		var z: float = BRIDGES_F2[i]
		var cx: float = centre.call(z)
		for j in 20:
			var dx := -10.0 + j * 1.0 + 0.5
			var arch := -1.0 + (crown + 1.0) * sqrt(maxf(1.0 - pow(dx / 6.0, 2.0), 0.0)) if absf(dx) < 6.0 else EndlessPieces.grid_height(k.id, cx + dx, z) - 1.0
			var deck := crown + 1.2 - maxf(absf(dx) - 3.0, 0.0) * 0.25
			if deck - arch < 0.4:
				continue
			look.box(Vector3(cx + dx, (arch + deck) * 0.5, z), Vector3(1.0, deck - arch, 3.0), EndlessPieces.STONE_DARK if j % 4 == 0 else EndlessPieces.STONE)
			var hole := arch + (EndlessPieces.HOLE_GRACE if absf(dx) < 6.0 else 0.0)  # the hole a little bigger
			EndlessPieces._box_faces(solid, Vector3(cx + dx, (hole + deck) * 0.5, z), Vector3(1.0, deck - hole, 3.0))
		k.arches.append({"z": z, "depth": 3.0, "openings": [{"x": cx, "half_span": 6.0, "springing": -1.0}]})
		for dz in [3.5, 0.0, -3.5]:
			under.append(Vector3(cx, low_y, z + dz))
			big.append(i == 2 and dz == 0.0)
		if i < 2:
			under.append(Vector3(cx, 5.5, z - 18.0))  # the bank star at the top of the rise between
			big.append(false)
	var down := PackedVector3Array()
	for i in 8:
		var t := i / 7.0
		down.append(Vector3(side * lerpf(18.0, SPLIT, smoothstep(0.0, 1.0, t)), lerpf(14.0, 5.0, t), lerpf(-42.0, -84.0, t)))
	_arc(k, "low", "down to the river", down, EndlessPieces._no_big(8))
	k.arcs[-1]["from_entry"] = 7  # down from the height you really bring
	k.arcs[-1]["fit_below"] = 4.0
	_arc(k, "low", "humpbacks", under, big, "Under the bridges!")
	_line(k, "low", [{"x": down[0].x, "z": down[0].z, "dy": -4.0, "max": down[0].y}])
	_line(k, "low", Array(down).slice(1))
	_line(k, "low", Array(under))
	var meadow := Vector2(side * 16.0, -222.0)
	_line(k, "low", [Vector3(side * 34.0, 7.5, -202.0), Vector3(meadow.x + side * 6.0, 6.5, -213.0)])
	var top := lerpf(25.0, 23.0, d)
	_road_thermal(k, "low", "Meadow", meadow, lerpf(11.0, 10.0, d), lerpf(0.85, 0.75, d), top, 6, d)
	_line(k, "low", [Vector3(side * 6.0, top - 4.0, -258.0), Vector3(side * 2.0, top - 5.0, -LENGTH)])


## The Railway (the high road): the cinder yard's thermal, along the embankment, over the
## brickworks chimney through its smoke, and up the standing engine's steam at the station.
static func _railway(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var side := -low_side(k.id)
	var track := func(z: float) -> float: return road_x(k.id, "high", z)
	var yard := Vector2(side * 30.0, -60.0)
	for i in 4:  # coal heaps on the cinder yard
		var at := yard + Vector2(side * (8.0 + i * 2.5), -8.0 + i * 5.0)
		look.sphere(Vector3(at.x, EndlessPieces.grid_height(k.id, at.x, at.y), at.y), 1.4, CINDER.darkened(0.3), Vector3(1.2, 0.6, 1.0), 6, 3)
	var top := lerpf(28.0, 26.0, d)
	_line(k, "high", [{"x": side * 28.0, "z": -48.0, "dy": -3.0, "max": 17.0}])
	_road_thermal(k, "high", "Cinders", yard, lerpf(12.0, 10.5, d), lerpf(0.9, 0.8, d), top, 0, d)
	# Rails and sleepers along the embankment, and telegraph poles beside it.
	for i in 30:
		var z := -82.0 - i * 4.0
		var x: float = track.call(z)
		look.box(Vector3(x, 4.08, z), Vector3(2.6, 0.16, 0.5), Color("8b6f5a"))
	EndlessPieces._strip(k, look, func(z: float) -> float: return float(track.call(z)) - 0.7, 0.18, -82.0, -200.0, [Color("6f6a78")])
	EndlessPieces._strip(k, look, func(z: float) -> float: return float(track.call(z)) + 0.7, 0.18, -82.0, -200.0, [Color("6f6a78")])
	for i in 10:
		var z := -86.0 - i * 12.0
		var x: float = float(track.call(z)) + side * 6.0
		look.cylinder(Vector3(x, EndlessPieces.grid_height(k.id, x, z) - 0.2, z), 0.14, 0.12, 6.0, Color("8b6f5a"), 5)
		look.box(Vector3(x, 5.6, z), Vector3(1.6, 0.14, 0.14), Color("8b6f5a"))
	var along := PackedVector3Array()
	for i in 5:
		along.append(Vector3(side * SPLIT, lerpf(20.0, 18.0, i / 4.0), -102.0 - 6.0 * i))
	_arc(k, "high", "along the line", along, EndlessPieces._no_big(5))
	_line(k, "high", [Vector3(side * 35.5, 20.0, -100.0)])
	_line(k, "high", Array(along))
	# The brickworks chimney (solid) and its smoke; the line crosses over its top.
	var stack := Vector2(side * 30.0, -164.0)
	var stack_base := Vector3(stack.x, EndlessPieces.grid_height(k.id, stack.x, stack.y) - 0.3, stack.y)
	EndlessPieces._solid_cylinder(look, solid, stack_base, 1.2, 1.0, 12.0 - stack_base.y, Color("b4674f"), 8)
	look.box(Vector3(side * 24.0, 1.5, -164.0), Vector3(6.0, 3.0, 8.0), Color("c98f6b"))  # the kiln shed (looks)
	k.zones.append({"name": "Chimney", "shape": Thermal.Shape.CYLINDER, "at": Vector3(stack.x, 12.0, stack.y), "radius": lerpf(4.5, 4.0, d), "height": 16.0,
		"look": Thermal.Look.STEAM, "strength": lerpf(1.3, 1.2, d), "pitch": 1.06, "drifts": false})
	var smoke := PackedVector3Array()
	for i in 4:
		smoke.append(Vector3(stack.x - side * 1.0 + side * 0.4 * i, 16.5 + 1.2 * i, -161.0 - 2.4 * i))
	_arc(k, "high", "brickworks", smoke, EndlessPieces._no_big(4))
	_line(k, "high", [Vector3(stack.x, 17.5, -150.0)])
	_line(k, "high", Array(smoke))
	# The station: its house, the platform, and the engine standing at it, steam rising wide enough
	# to circle in (above everything solid).
	look.box(Vector3(side * 40.0, 2.5, -213.0), Vector3(6.0, 5.0, 8.0), Color("f2e3d5"))
	EndlessPieces._box_faces(solid, Vector3(side * 40.0, 2.5, -213.0), Vector3(6.0, 5.0, 8.0))
	look.box(Vector3(side * 40.0, 5.6, -213.0), Vector3(7.0, 1.2, 9.0), EndlessPieces.CREAM.darkened(0.25))
	EndlessPieces._solid_box(look, solid, Vector3(side * 32.0, 0.5, -213.0), Vector3(4.0, 1.0, 22.0), Color("d8cfc2"))
	var engine := Vector3(side * 26.0, 0.0, -216.0)
	EndlessPieces._solid_box(look, solid, engine + Vector3(0, 2.6, 2.5), Vector3(2.6, 3.0, 3.0), Color("4f6b5a"))  # the cab
	var boiler := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), engine + Vector3(0, 2.0, -2.0))
	look.add_triangles(Art.cylinder_triangles(1.2, 1.2, 6.0, 10), boiler, Color("3f5a4b"))
	EndlessPieces._faces(solid, Art.cylinder_triangles(1.2, 1.2, 6.0, 10), boiler)
	EndlessPieces._solid_cylinder(look, solid, engine + Vector3(0, 2.8, -4.4), 0.4, 0.5, 1.6, Color("2f3b35"), 6)
	var steam := Vector2(side * 24.0, -220.0)
	var steam_top := lerpf(29.5, 29.0, d)  # (the high road leaves at least 4 over the low: calibrated)
	k.zones.append({"name": "Steam", "shape": Thermal.Shape.CYLINDER, "at": Vector3(steam.x, 9.0, steam.y), "radius": lerpf(10.0, 9.0, d),
		"height": steam_top - 9.0, "look": Thermal.Look.STEAM, "strength": lerpf(0.9, 0.8, d), "pitch": 1.04, "drifts": true})
	k.clouds.append({"at": Vector3(steam.x, steam_top + 4.0, steam.y), "radius": 6.0, "puffs": 4, "zone": "Steam"})
	EndlessPieces._spiral(k, "steam spiral", "Steam", steam, 19.5, steam_top, 3, d)  # a short climb at the end of the high road
	k.arcs[-1]["road"] = "high"
	_line(k, "high", [Vector3(side * 24.0, 20.0, -210.0)])
	(k.fork["orbits"]["high"] as Array).append({"centre": steam, "zone": "Steam", "radius": 6.0, "to_y": steam_top - 2.0, "up": true, "max_time": 25.0, "road": "high"})
	_line(k, "high", [Vector3(side * 8.0, steam_top - 4.0, -258.0), Vector3(side * 4.0, steam_top - 5.0, -LENGTH)])
