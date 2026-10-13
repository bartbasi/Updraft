# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessWorld
extends Node3D
## Endless's country (docs/endless-plan.md §1.3, §2): the generator's pieces placed one after
## another down a valley that never ends, a few tiles ahead of the plane and one behind, each from
## its prebuilt kit (EndlessPieces). Also the bowl behind you at the start (drawn, not solid), a
## ring of far hills that keeps pace, the stars, clouds and birds, and the moving air: thermals
## drift with the wind once you reach them, and fade once they have drifted their life.
## The world keeps the Course's coordinates: the valley floor is at y FLOOR_Y, and tile i starts
## at z START_Z - 96 i, just past the bowl's far rim.

const START_Z := -528.0  ## Where tile 0 (the Rim) begins: the Course's far edge.
const FLOOR_Y := 40.0  ## The valley floor.
const START := Vector3(0.0, 72.0, -530.0)  ## Where the flyer is let go, just short of the Rim's crest.
## Flying back past this ends the run ("Wrong way!").
const WRONG_WAY_Z := -520.0
const TILE := EndlessPieces.TILE
## Pieces are placed (and their kits built in the background) this many tiles before they are drawn.
const PLACE_EARLY := 3
## Microseconds a physics tick may spend building kits (see EndlessPieces.pump()).
const BUILD_BUDGET_USEC := 3000

## A piece is in the world (spawned, in order, a few tiles ahead of the plane): its line and
## circles are known (line_for(), orbits_for()).
signal placed(piece: Piece)

## One piece placed in the world.
class Piece:
	var placement: EndlessGenerator.Placement
	var kit: EndlessPieces.Kit
	var node: Node3D
	var origin := Vector3.ZERO
	var zones := {}  ## Name in the kit -> Thermal.
	var spawned := false

	func first_tile() -> int:
		return placement.tile

	func last_tile() -> int:
		return placement.tile + EndlessPieces.tiles(placement.id) - 1

	func title() -> String:
		return EndlessPieces.NAMES[placement.id]

var tuning: Tuning
## The tailwind (u/s toward -Z); thermals drift with it.
var wind := 0.0
var generator: EndlessGenerator
var pieces: Array[Piece] = []
var stars: EndlessStars
var sky: EndlessSky
var _backdrop: Node3D
var _hills: Node3D
var _seed := 1


func setup(p_tuning: Tuning) -> void:
	tuning = p_tuning
	stars = EndlessStars.new()
	stars.name = "Stars"
	stars.tuning = tuning
	add_child(stars)
	sky = EndlessSky.new()
	sky.name = "Sky"
	sky.tuning = tuning
	add_child(sky)
	_hills = _build_far_hills()
	add_child(_hills)


## Starts a new country from `p_seed`: the old pieces go, and the first few are placed at once.
## `with_backdrop` draws the bowl behind the start (a fresh scene; a retry keeps what it has).
func reset(p_seed: int, with_backdrop: bool, forced: Array[StringName] = [], forced_d := -1.0, forced_h := 0.0) -> void:
	_seed = p_seed
	for p in pieces:
		if is_instance_valid(p.node):
			p.node.free()
	pieces.clear()
	stars.clear()
	sky.clear()
	generator = EndlessGenerator.new(tuning, p_seed)
	generator.forced = forced
	generator.forced_d = forced_d
	generator.forced_h = forced_h
	if with_backdrop and _backdrop == null:
		_backdrop = _build_backdrop()
		add_child(_backdrop)
	_place_hills(0)
	update(START, 0.0, true)


## The tile a world z is on (tile 0 is the Rim; negative before it).
static func tile_at(z: float) -> int:
	return floori((START_Z - z) / TILE)


static func tile_origin(tile: int) -> Vector3:
	return Vector3(0.0, FLOOR_Y, START_Z - TILE * tile)


## Metres along the valley from the start point (4 units to the metre).
static func metres(z: float) -> float:
	return maxf(START.z - z, 0.0) / 4.0


## Each physics tick: keeps pieces placed from one tile behind the plane to a few ahead (at most
## one new piece a tick, or all at once when `all_now`), lets the thermals drift, and drops the bowl
## behind once you're well on your way.
func update(plane_at: Vector3, delta: float, all_now := false) -> void:
	var here := maxi(tile_at(plane_at.z), 0)
	var ahead := here + tuning.endless_tiles_ahead
	# Placed (and their kits started in the background) a few tiles before they are drawn.
	while generator.next_tile() <= ahead + PLACE_EARLY:
		var p := Piece.new()
		p.placement = generator.next()
		p.origin = tile_origin(p.placement.tile)
		p.kit = EndlessPieces.kit_when_ready(p.placement.id, p.placement.d)
		pieces.append(p)
	EndlessPieces.pump(BUILD_BUDGET_USEC)
	for p in pieces:
		if p.spawned or p.first_tile() > ahead:
			continue
		if p.kit == null:  # a fresh run builds its first pieces now; later ones wait for their build
			p.kit = EndlessPieces.kit(p.placement.id, p.placement.d) if all_now else EndlessPieces.kit_when_ready(p.placement.id, p.placement.d)
			if p.kit == null:
				break
		_spawn(p)
		if not all_now:
			break
	var keep_from := here - tuning.endless_tiles_behind
	while not pieces.is_empty() and pieces[0].last_tile() < keep_from:
		var gone: Piece = pieces.pop_front()
		if is_instance_valid(gone.node):
			gone.node.queue_free()
		stars.remove_before(keep_from)
		sky.remove_before(keep_from)
	for p in pieces:
		for zone: Thermal in p.zones.values():
			if zone.drifts_with_wind:
				zone.drift_with_wind(delta, plane_at, wind, tuning)
	if _backdrop != null and here >= 2:
		_backdrop.queue_free()
		_backdrop = null
	_place_hills(here)


## The piece a world z is in, or null.
func piece_at(z: float) -> Piece:
	var t := tile_at(z)
	for p in pieces:
		if t >= p.first_tile() and t <= p.last_tile():
			return p
	return null


## The ground under a point, as drawn and as it collides (the bowl's before the Rim).
func terrain_height(x: float, z: float) -> float:
	if z > START_Z:
		return Course.terrain_height(x, z)
	var p := piece_at(z)
	if p == null:
		return FLOOR_Y + EndlessPieces.standard(x)
	return FLOOR_Y + EndlessPieces.grid_height(p.placement.id, x, z - p.origin.z)


## The ridge lifts placed so far (for the gull).
func ridge_lifts() -> Array[Thermal]:
	var out: Array[Thermal] = []
	for p in pieces:
		if p.spawned and p.kit.gull_lift != "" and p.zones.has(p.kit.gull_lift):
			out.append(p.zones[p.kit.gull_lift])
	return out


## A piece's ideal line in world coordinates.
func line_for(p: Piece) -> PackedVector3Array:
	var out := PackedVector3Array()
	for q in p.kit.line(p.placement.h_in):
		out.append(p.origin + q)
	return out


## A piece's circles for the test pilot, in world coordinates, following its zones by name.
func orbits_for(p: Piece) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in p.kit.orbits:
		var c: Vector2 = o["centre"]
		out.append({"centre": Vector2(c.x, c.y + p.origin.z), "zone": zone_name(p, o["zone"]), "radius": o["radius"],
			"to_y": float(o["to_y"]) + FLOOR_Y, "up": o["up"], "max_time": o["max_time"]})
	return out


static func zone_name(p: Piece, kit_name: String) -> String:
	return "T%d_%s" % [p.placement.tile, kit_name]


func _spawn(p: Piece) -> void:
	p.spawned = true
	p.node = Node3D.new()
	p.node.name = "T%d_%s" % [p.placement.tile, p.placement.id]
	p.node.position = p.origin
	add_child(p.node)
	var mi := MeshInstance3D.new()
	mi.mesh = p.kit.mesh
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = tuning.endless_tile_fade.x
	mi.visibility_range_end_margin = tuning.endless_tile_fade.y
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	p.node.add_child(mi)
	var body := StaticBody3D.new()
	for shape in p.kit.shapes:
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
	p.node.add_child(body)
	for spec in p.kit.zones:
		var t := Thermal.new()
		t.name = zone_name(p, spec["name"])
		t.shape = spec["shape"]
		t.look = spec["look"]
		t.strength_scale = spec["strength"]
		t.chime_pitch = spec["pitch"]
		t.outdoors = true
		t.position = spec["at"]
		if t.shape == Thermal.Shape.CYLINDER:
			t.radius = spec["radius"]
			t.height = spec["height"]
		else:
			t.size = spec["size"]
		if spec.has("seed_amount"):
			t.seed_amount = spec["seed_amount"]
			t.seed_centre_y = spec["seed_centre_y"]
			t.seed_half_height = spec["seed_half_height"]
		t.smoke_drift = Vector3(0.0, 0.0, -0.12)  # puffs lean downwind, toward -z
		if spec["drifts"]:
			t.drifts_with_wind = true
			t.life = lerpf(tuning.endless_thermal_life.x, tuning.endless_thermal_life.y, p.kit.d)
		p.node.add_child(t)
		p.zones[spec["name"]] = t
	stars.add_piece(p.placement.tile, p.kit.arcs, p.origin, p.zones, p.placement.h_in)
	sky.add_piece(p.placement.tile, p.kit.clouds, p.kit.birds, p.origin, p.zones)
	placed.emit(p)


# --- Scenery beyond the pieces --------------------------------------------------------

## The bowl behind the start, coarse and not solid: its ground at a 12 u step from the Downs' crest
## to the far rim, the lake, and the windmill on the Gap's shoulder with its sails turning.
func _build_backdrop() -> Node3D:
	var root := Node3D.new()
	root.name = "Backdrop"
	var b := Art.Builder.new()
	var step := 12.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var z := -300.0
	while z > START_Z + 0.1:
		var zb := maxf(z - step, START_Z)
		var x := -126.0
		while x < 126.0 - 0.1:
			var xb := x + step
			var a := Vector3(x, Course.ground_height(x, z), z)
			var bb := Vector3(xb, Course.ground_height(xb, z), z)
			var c := Vector3(x, Course.ground_height(x, zb), zb)
			var d := Vector3(xb, Course.ground_height(xb, zb), zb)
			var color: Color = Course.GRASS[rng.randi() % Course.GRASS.size()]
			if Course.lake_reach((x + xb) * 0.5, (z + zb) * 0.5) < 1.0:
				color = Color("cbbfa6")  # the lake's bed, under the water
			b.triangle(a, c, bb, color)
			b.triangle(bb, c, d, color)
			x = xb
		z = zb
	# The lake's surface: an ellipse of water.
	var centre := Vector3(Course.LAKE_CENTRE.x, Course.LAKE_Y, Course.LAKE_CENTRE.y)
	for i in 24:
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		var p0 := centre + Vector3(cos(a0) * Course.LAKE_RADII.x, 0.0, sin(a0) * Course.LAKE_RADII.y)
		var p1 := centre + Vector3(cos(a1) * Course.LAKE_RADII.x, 0.0, sin(a1) * Course.LAKE_RADII.y)
		b.triangle(centre, p0, p1, Color("a9cfe0"))  # facing up
	var mill := Vector3(CourseFar.WINDMILL.x, Course.terrain_height(CourseFar.WINDMILL.x, CourseFar.WINDMILL.y), CourseFar.WINDMILL.y)
	b.cylinder(mill - Vector3(0, 0.5, 0), 2.0, 1.4, CourseFar.WINDMILL_TOWER + 0.5, Color("f3ece2"), 8)
	b.cylinder(mill + Vector3(0, CourseFar.WINDMILL_TOWER, 0), 1.7, 0.0, 2.2, Color("c1675a"), 8)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var sails := PropMotion.new()
	var sb := Art.Builder.new()
	for k in 4:
		var basis := Basis(Vector3.BACK, TAU * k / 4.0)
		sb.box(basis * Vector3(0.0, CourseFar.WINDMILL_SAIL * 0.5, 0.0), Vector3(0.9, CourseFar.WINDMILL_SAIL, 0.08), Color("f3ece2"), basis)
	sails.mesh = sb.commit()
	sails.material_override = Art.material(true)
	root.add_child(sails)
	sails.spin(mill + Vector3(0, CourseFar.WINDMILL_TOWER - 1.0, 0) + CourseFar.WINDMILL_FACING * 1.6, CourseFar.WINDMILL_FACING, CourseFar.WINDMILL_TURN, Basis.looking_at(-CourseFar.WINDMILL_FACING))
	return root


## Six low, pale hills 350-600 u out, which keep pace with the plane a tile at a time.
func _build_far_hills() -> Node3D:
	var b := Art.Builder.new()
	var spots := [Vector3(-380.0, 0.0, -150.0), Vector3(400.0, 0.0, -260.0), Vector3(-460.0, 0.0, -420.0),
		Vector3(520.0, 0.0, -520.0), Vector3(-260.0, 0.0, -600.0), Vector3(180.0, 0.0, -640.0)]
	var colors := [Color("c7dcb4"), Color("cfe0bd"), Color("bfd6ad")]
	for i in spots.size():
		var r := 110.0 + 30.0 * (i % 3)
		b.sphere(spots[i], r, colors[i % colors.size()], Vector3(1.0, 0.35, 0.8), 10, 4)
	var mi := MeshInstance3D.new()
	mi.name = "FarHills"
	mi.mesh = b.commit()
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return mi


func _place_hills(tile: int) -> void:
	_hills.position = Vector3(0.0, FLOOR_Y - 10.0, START_Z - TILE * tile)
