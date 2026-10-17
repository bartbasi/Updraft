# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name CourseFar
extends RefCounted
## Builds the landmarks past the valley into a Course (docs/phase4-plan.md, part B3): the windmill
## on the Gap's right shoulder, the stone wall and sheep across the valley's far end, and in the bowl
## the stream down the Gap, the island, the sailboat, the beach huts, the boathouse and jetty, the
## bluff's flag and the trees. Generic downland countryside in the valley's pastel palette, all
## made in code. The positions come from the layout constants at the top of course.gd and here.

## On the Gap's right shoulder (the plan had the left, but from the window the chalk pit's cloud
## hid it there).
const WINDMILL := Vector2(36.0, -336.0)
const WINDMILL_TOWER := 10.0  ## Tower height; the sails' hub is at 9.
const WINDMILL_SAIL := 5.0  ## Sail length from the hub.
const WINDMILL_TURN := 0.5  ## Radians/second.
## The way the sails face (seen from above): turned from +Z 35 degrees toward +X, so they show
## their face to the valley rather than their edge.
const WINDMILL_FACING := Vector3(0.574, 0.0, 0.819)
const WALL_Z := -252.0
const WALL_X := Vector2(-28.0, 22.0)
const WALL_HEIGHT := 1.2
const GATE_X := Vector2(-4.0, 2.0)  ## The white gate's span (whole steps of the wall's 2 u stones).
const STREAM_TOP := Vector2(6.0, -346.0)  ## The spring.
const STREAM_END_Z := -385.0
const BOAT_CIRCLE := Vector2(14.0, -410.0)
const BOAT_RADIUS := 12.0
const BOAT_SPEED := 1.2  ## Units/s, anticlockwise seen from above.
const HUTS: Array[Vector2] = [Vector2(63.0, -398.0), Vector2(63.0, -405.0), Vector2(63.0, -412.0)]
const HUT_SIZE := Vector3(2.4, 2.4, 3.2)  ## Width (x), wall height, depth (z).
const HUT_COLORS: Array[Color] = [Color("a9c8e8"), Color("f4dc9b"), Color("f2b8a2")]
const BOATHOUSE := Vector2(-22.0, -452.0)
const BOATHOUSE_SIZE := Vector3(7.0, 3.5, 5.0)
## The jetty runs this far out from the boathouse, past the shallows to open water.
const JETTY_LENGTH := 13.0
const FLAG := Vector2(-88.0, -415.0)
## The orchard on the far rim slope (rows at these z, from x to x by step) and the bluff's pines.
const ORCHARD_Z: Array[float] = [-488.0, -498.0]
const ORCHARD_X := Vector3(-60.0, 60.0, 10.0)
const PINES: Array[Vector2] = [Vector2(-82.0, -392.0), Vector2(-90.0, -404.0), Vector2(-104.0, -398.0),
	Vector2(-86.0, -440.0), Vector2(-98.0, -452.0), Vector2(-108.0, -430.0)]
const STONE := Color("c9c2ba")
const WOOL := Color("fbf8f1")
const DARK := Color("5f5b70")


## Into the valley's mesh: the windmill's tower, the wall and the sheep. Moving parts are nodes.
static func build_valley(c: Course) -> void:
	_windmill(c)
	_wall_and_sheep(c)


## Into the bowl's mesh: everything beyond the Downs.
static func build_bowl(c: Course) -> void:
	_stream(c)
	_island(c)
	_sailboat(c)
	for i in HUTS.size():
		var at := HUTS[i]
		_gabled(c, Vector3(at.x, _floor_under(at, HUT_SIZE), at.y), HUT_SIZE, 1.3, HUT_COLORS[i], Course.TRIM)
	_boathouse(c)
	_flag(c)
	_trees(c)


## A white tapered tower with a red cap on the Gap's right shoulder; its four lattice sails face
## half toward the valley and turn slowly, high above any flight line. The tower is solid; the
## sails aren't.
static func _windmill(c: Course) -> void:
	# It stands on the Gap's steep side: its foot goes down to the lowest grass under it.
	var foot := Vector3(WINDMILL.x, _floor_under(WINDMILL, Vector3(4.0, 0.0, 4.0)) - 0.3, WINDMILL.y)
	var tower := Course.terrain_height(WINDMILL.x, WINDMILL.y) + WINDMILL_TOWER - foot.y
	c.cylinder(foot, 2.0, 1.4, tower, Course.TRIM, true, 12)
	foot.y += tower - WINDMILL_TOWER - 0.5  # the cap and sails sit as high as on level ground
	c.builder.sphere(foot + Vector3(0.0, WINDMILL_TOWER + 0.5, 0.0), 1.6, Color("b5524a"), Vector3(1.0, 0.7, 1.0), 10, 4)
	# The sails are built facing +X, then turned to face WINDMILL_FACING.
	var face := Basis(Vector3.UP, atan2(-WINDMILL_FACING.z, WINDMILL_FACING.x))
	var hub := foot + Vector3(0.0, 9.5, 0.0) + WINDMILL_FACING * 1.9
	c.builder.box(hub - WINDMILL_FACING * 0.35, Vector3(1.9, 0.5, 0.5), Color("7a6a5e"), face)  # the axle, out to the sails
	var sails := Art.Builder.new()
	var lattice := Color("7a6a5e")
	for k in 4:
		var turn := Basis(Vector3.RIGHT, k * PI * 0.5)
		sails.box(turn * Vector3(0.0, WINDMILL_SAIL * 0.5, 0.0), Vector3(0.15, WINDMILL_SAIL, 0.2), lattice, turn)  # the stock
		for rung in 5:  # the lattice: crossbars, and a rail along the trailing edge
			var y := 1.2 + rung * (WINDMILL_SAIL - 1.4) / 4.0
			sails.box(turn * Vector3(0.0, y, 0.5), Vector3(0.08, 0.1, 1.1), lattice, turn)
		sails.box(turn * Vector3(0.0, (WINDMILL_SAIL + 1.2) * 0.5, 1.05), Vector3(0.08, WINDMILL_SAIL - 1.2, 0.1), lattice, turn)
		sails.box(turn * Vector3(-0.02, (WINDMILL_SAIL + 1.2) * 0.5, 0.55), Vector3(0.03, WINDMILL_SAIL - 1.2, 1.0), Color("efe6d8"), turn)  # the sailcloth
	var mover := PropMotion.new()
	mover.name = "WindmillSails"
	mover.mesh = sails.commit()
	mover.spin(hub + WINDMILL_FACING * 0.6, Vector3.RIGHT, WINDMILL_TURN, face)
	c.add_child(mover)


## A dry-stone wall across the valley's far end with a white gate in it, and sheep grazing on the
## house side. The wall is solid (it is only 1.2 tall, where the valley is flown at 20 and up);
## the sheep aren't.
static func _wall_and_sheep(c: Course) -> void:
	var x := WALL_X.x
	while x < WALL_X.y:
		var x1 := minf(x + 2.0, WALL_X.y)
		if x1 <= GATE_X.x or x >= GATE_X.y:
			var mid := (x + x1) * 0.5
			var ground := minf(Course.terrain_height(x, WALL_Z), Course.terrain_height(x1, WALL_Z))
			c.box(Vector3(mid, ground + (WALL_HEIGHT - 0.3) * 0.5, WALL_Z), Vector3(x1 - x + 0.05, WALL_HEIGHT + 0.3, 0.7), STONE)
			c.builder.box(Vector3(mid, ground + WALL_HEIGHT - 0.25, WALL_Z), Vector3(x1 - x, 0.25, 0.8), Color("bdb5ac"))  # coping stones
		x = x1
	var gate_ground := Course.terrain_height((GATE_X.x + GATE_X.y) * 0.5, WALL_Z)
	for post_x in [GATE_X.x + 0.15, GATE_X.y - 0.15]:
		var post_ground := Course.terrain_height(post_x, WALL_Z)
		c.box(Vector3(post_x, post_ground + 0.65, WALL_Z), Vector3(0.3, 1.5, 0.3), Course.TRIM)
	for rail in [0.35, 0.75, 1.1]:
		c.box(Vector3((GATE_X.x + GATE_X.y) * 0.5, gate_ground + rail, WALL_Z), Vector3(GATE_X.y - GATE_X.x, 0.12, 0.1), Course.TRIM, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 8:
		var at := Vector2(rng.randf_range(-24.0, 18.0), rng.randf_range(-236.0, -248.0))
		var facing := 0.0 if rng.randf() < 0.5 else PI  # along the valley, one way or the other, like their bodies
		var ground := Course.terrain_height(at.x, at.y)
		var body := Vector3(at.x, ground + 0.75, at.y)
		var ahead := Vector3(-sin(facing), 0.0, -cos(facing))
		c.builder.sphere(body, 0.65, WOOL, Vector3(0.9, 0.8, 1.3), 6, 3)
		c.builder.sphere(body + ahead * 0.85 + Vector3(0.0, 0.05, 0.0), 0.28, DARK, Vector3(0.8, 0.9, 1.2), 4, 2)
		for leg: Vector2 in [Vector2(-0.3, -0.4), Vector2(0.3, -0.4), Vector2(-0.3, 0.4), Vector2(0.3, 0.4)]:
			var foot := body + Vector3(leg.x, -0.75, 0.0) + ahead * leg.y
			c.builder.box(foot + Vector3(0.0, 0.25, 0.0), Vector3(0.12, 0.5, 0.12), DARK)


## The stream down the Gap's lake side: a painted ribbon from a spring to the water.
static func _stream(c: Course) -> void:
	var z := STREAM_TOP.y
	while z > STREAM_END_Z:
		var z1 := z - 1.0
		var xa := STREAM_TOP.x + 1.5 * sin(z * 0.2)
		var xb := STREAM_TOP.x + 1.5 * sin(z1 * 0.2)
		var water := Color("a9cfe0") if int(-z / 2.0) % 2 == 0 else Color("b8d8e6")
		c._ground_quad(Vector3(xa - 1.0, 0.0, z), Vector3(xa + 1.0, 0.0, z), Vector3(xb - 1.0, 0.0, z1), Vector3(xb + 1.0, 0.0, z1), water)
		z = z1


## The island: a grassy top, a little red pennant on a thin pole at its north edge, and a rowing
## boat pulled up on its south shore. None of it is solid but the ground.
static func _island(c: Course) -> void:
	var at := Course.ISLAND
	var r := Course.ISLAND_RADIUS - 2.5
	var step := 1.5
	var x := at.x - r
	while x < at.x + r:
		var z := at.y + r
		while z > at.y - r:
			if Vector2(x + step * 0.5, z - step * 0.5).distance_to(at) < r:
				c._ground_quad(Vector3(x, 0.0, z), Vector3(x + step, 0.0, z), Vector3(x, 0.0, z - step), Vector3(x + step, 0.0, z - step), Color("c6dfa8"))
			z -= step
		x += step
	var pole := Vector3(at.x, Course.terrain_height(at.x, at.y - 5.0), at.y - 5.0)
	c.builder.cylinder(pole, 0.06, 0.06, 3.2, Course.TRIM, 6)
	c.builder.triangle(pole + Vector3(0.0, 3.1, 0.0), pole + Vector3(-1.2, 2.8, 0.0), pole + Vector3(0.0, 2.5, 0.0), Color("e8604c"))
	c.builder.triangle(pole + Vector3(0.0, 3.1, 0.0), pole + Vector3(0.0, 2.5, 0.0), pole + Vector3(-1.2, 2.8, 0.0), Color("e8604c"))
	var boat := Vector3(at.x + 1.0, Course.terrain_height(at.x + 1.0, at.y + 5.5) + 0.2, at.y + 5.5)
	var b := Basis(Vector3.UP, 0.6)
	c.builder.box(boat, Vector3(1.0, 0.35, 2.4), Color("b5524a"), b)
	c.builder.box(boat + Vector3(0.0, 0.2, 0.0), Vector3(0.8, 0.08, 2.0), Color("e9d7b6"), b)


## A small sailboat circling slowly on the lake, heeled away from the breeze.
static func _sailboat(c: Course) -> void:
	var mover := PropMotion.new()
	mover.name = "Sailboat"
	mover.mesh = boat_mesh()
	mover.sail_round(Vector3(BOAT_CIRCLE.x, Course.LAKE_Y, BOAT_CIRCLE.y), BOAT_RADIUS, BOAT_SPEED, deg_to_rad(10.0))
	c.add_child(mover)


## The sailboat's mesh (nose toward -Z; the material must be double-sided for the sail). Endless's
## Mere has one too.
static func boat_mesh() -> ArrayMesh:
	var m := Art.Builder.new()
	m.box(Vector3(0.0, 0.2, 0.0), Vector3(1.1, 0.5, 3.2), Course.TRIM)
	m.box(Vector3(0.0, 0.05, 0.0), Vector3(1.15, 0.15, 3.25), Color("a9c8e8"))
	m.cylinder(Vector3(0.0, 0.4, -0.3), 0.05, 0.05, 3.6, Color("7a6a5e"), 6)
	m.triangle(Vector3(0.0, 0.6, -0.2), Vector3(0.0, 3.9, -0.25), Vector3(0.0, 0.7, 1.4), Color("fbf8f1"))  # the sail (the material is double-sided)
	m.box(Vector3(-0.3, 4.0, -0.3), Vector3(0.6, 0.15, 0.03), Color("f19e8f"))  # the pennant
	return m.commit()


## The boathouse on the far shore, with a jetty out over the water (the jetty isn't solid).
static func _boathouse(c: Course) -> void:
	var base := Vector3(BOATHOUSE.x, _floor_under(BOATHOUSE, BOATHOUSE_SIZE), BOATHOUSE.y)
	_gabled(c, base, BOATHOUSE_SIZE, 2.2, Color("e9d7b6"), Color("c1675a"))
	# The deck steps down the bank from the door, then runs level just above the water.
	var start := BOATHOUSE.y + BOATHOUSE_SIZE.z * 0.5
	for k in int(JETTY_LENGTH):
		var z := start + k + 0.5
		var deck := maxf(Course.LAKE_Y + 0.2, Course.terrain_height(BOATHOUSE.x, z) + 0.15)
		c.builder.box(Vector3(BOATHOUSE.x, deck, z), Vector3(1.2, 0.15, 1.02), Color("c9b393"))
		if k % 4 == 3:  # posts under the deck, a pair every few planks
			for side in [-0.55, 0.55]:
				var ground := Course.terrain_height(BOATHOUSE.x + side, z)
				c.builder.cylinder(Vector3(BOATHOUSE.x + side, ground - 0.3, z), 0.08, 0.08, deck - ground + 0.3, Color("7a6a5e"), 5)


## A tall flag on the bluff's plateau, streaming away from the breeze.
static func _flag(c: Course) -> void:
	var foot := Vector3(FLAG.x, Course.terrain_height(FLAG.x, FLAG.y), FLAG.y)
	c.builder.cylinder(foot, 0.1, 0.08, 8.0, Course.TRIM, 6)
	var top := foot + Vector3(0.0, 7.9, 0.0)
	var red := Color("e8604c")
	for s in [1.0, -1.0]:
		var a := top
		var b := top + Vector3(-3.0, -0.5, 0.2)
		var cc := top + Vector3(0.0, -1.2, 0.0)
		if s > 0.0:
			c.builder.triangle(a, b, cc, red)
		else:
			c.builder.triangle(a, cc, b, red)


## An orchard of round trees on the far rim slope and wind-bent pines on the bluff's plateau,
## each kept clear of the lift, the lake, the beach, the boathouse and the Gap's channel.
static func _trees(c: Course) -> void:
	for z in ORCHARD_Z:
		var x := ORCHARD_X.x
		while x <= ORCHARD_X.y:
			if bowl_tree_allowed(x, z):
				var base := Vector3(x, Course.terrain_height(x, z), z)
				c.cylinder(base - Vector3(0, 0.5, 0), 0.35, 0.28, 2.8, Color("a88b74"), true, 5)
				c.sphere(base + Vector3(0.0, 3.4, 0.0), 1.9, Color("9cc48a") if int(x / 10.0) % 2 == 0 else Color("b3d39b"), true, Vector3(1.0, 0.85, 1.0), 6, 3)
			x += ORCHARD_X.z
	for at in PINES:
		if not bowl_tree_allowed(at.x, at.y):
			continue
		var base := Vector3(at.x, Course.terrain_height(at.x, at.y), at.y)
		c.cylinder(base - Vector3(0, 0.5, 0), 0.4, 0.3, 4.5, Color("a88b74"), true, 5)
		c.cylinder(base + Vector3(-1.0, 2.8, 0.0), 2.4, 0.0, 6.0, Color("8fbf9a"), true, 6)  # its crown blown a little downwind


## Bowl trees keep 4 units clear of every lift zone's edge (thermals counted at 1.5 times their
## radius), out of the lake (and a margin round it), the beach, the boathouse and the Gap's channel.
static func bowl_tree_allowed(x: float, z: float) -> bool:
	for t: Dictionary in Course.OUTDOOR_THERMALS:
		if Vector2(x, z).distance_to(t["at"]) < float(t["radius"]) * 1.5 + 4.0:
			return false
	var bluff_x := Vector2(Course.BLUFF_LIFT.x - Course.BLUFF_LIFT_SIZE.x * 0.5, Course.BLUFF_LIFT.x + Course.BLUFF_LIFT_SIZE.x * 0.5)
	var bluff_z := Vector2(Course.BLUFF_LIFT.z - Course.BLUFF_LIFT_SIZE.z * 0.5, Course.BLUFF_LIFT.z + Course.BLUFF_LIFT_SIZE.z * 0.5)
	if x > bluff_x.x - 4.0 and x < bluff_x.y + 4.0 and z > bluff_z.x - 4.0 and z < bluff_z.y + 4.0:
		return false
	if Course.lake_reach(x, z) < 1.1:
		return false
	if x > Course.BEACH_X.x - 2.0 and x < Course.BEACH_X.y + 2.0 and z < Course.BEACH_Z.x + 2.0 and z > Course.BEACH_Z.y - 2.0:
		return false
	if Vector2(x, z).distance_to(BOATHOUSE) < 8.0:
		return false
	return not (absf(x - Course.GAP_X) < Course.GAP_HALF + 4.0 and z > Course.GAP_CUT_Z.y)


## A little gabled building (ridge along z): walls, gable ends, a solid attic and two roof slopes.
static func _gabled(c: Course, base: Vector3, size: Vector3, roof_rise: float, wall: Color, roof: Color) -> void:
	c.box(base + Vector3(0.0, size.y * 0.5, 0.0), size, wall)
	var half := size.x * 0.5
	for z in [-size.z * 0.5, size.z * 0.5]:
		var l := base + Vector3(-half, size.y, z)
		var r := base + Vector3(half, size.y, z)
		var top := base + Vector3(0.0, size.y + roof_rise, z)
		c.builder.triangle(l, top, r, wall)
		c.builder.triangle(r, top, l, wall)
	var attic := ConvexPolygonShape3D.new()
	var prism := PackedVector3Array()
	for z in [-size.z * 0.5, size.z * 0.5]:
		prism.append_array([Vector3(-half, size.y, z), Vector3(half, size.y, z), Vector3(0.0, size.y + roof_rise, z)])
	attic.points = prism
	c.solid_shape(attic, Transform3D(Basis.IDENTITY, base))
	var slope := atan2(roof_rise, half)
	var length := sqrt(half * half + roof_rise * roof_rise) + 0.3
	for s in [-1.0, 1.0]:
		var basis := Basis(Vector3.BACK, -s * slope)
		var mid := base + Vector3(s * half * 0.5, size.y + roof_rise * 0.5, 0.0) + basis * Vector3(0.0, 0.1, 0.0)
		c.box(mid, Vector3(length, 0.2, size.z + 0.4), roof, true, basis)


## The lowest grass under a building's footprint, so no wall floats above a slope.
static func _floor_under(at: Vector2, size: Vector3) -> float:
	var low := INF
	for k in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		low = minf(low, Course.terrain_height(at.x + k.x * size.x * 0.5, at.y + k.y * size.z * 0.5))
	return low
