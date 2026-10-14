# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessPieces
extends RefCounted
## The pieces Endless's country is made of (docs/endless-plan.md §2 and §7): for each, what the
## generator needs to know (EndlessGenerator), its ground, and a kit with everything to place it:
## one mesh and one collision shape (ground, scenery and buildings), the zones of moving air, the
## star arcs, the ideal line a good pilot flies (and the circles on it), clouds, birds, kite hoops,
## arches and the ridge the gull meets you on.
##
## Piece-local coordinates: x across the valley (0 its middle, +x the pilot's right), y above the
## valley floor, z from 0 at the piece's entry edge to -96 at its exit (-192 for two tiles). The
## world puts tile i's origin at (0, EndlessWorld.FLOOR_Y, EndlessWorld.START_Z - 96 i).

const TILE := 96.0  ## Tile length (z).
const HALF := 96.0  ## Half the tile's width (x -96..96).
const STEP := 6.0  ## Ground grid, as the Course's.
const FLOOR := 28.0  ## Half-width of the flat valley floor.
const SIDE := 0.016  ## The sides rise as SIDE (|x| - FLOOR)^2.
const ROLL := 0.5  ## Soft rolls on the floor, faded to nothing near each piece's edges.
const EDGE_CALM := 12.0
const PAINT_LIFT := 0.05
## Difficulty is rounded to this step for a piece's layout, so its kit can be built once and kept.
const D_STEP := 0.25

const GRASS := Course.GRASS
const FLOWERS := Course.FLOWERS
const SLOPE_GRASS := [Color("aacd8f"), Color("9fc488"), Color("b4d49a")]
const HEDGE := Color("8fb47e")
const WATER := Color("a9cfe0")
const WATER_LIGHT := Color("b8d8e6")
const BARK := Color("a88b74")
const LEAF := [Color("9cc48a"), Color("b3d39b"), Color("8fbf9a")]
const WOOL := Color("fbf8f1")
const DARK := Color("5f5b70")
const STONE := Color("e9d7b6")
const STONE_DARK := Color("c9b393")
const CREAM := Color("f3ece2")

## What the generator knows about each piece: tiles long; lift (does it give the pilot height);
## rest (asks for no manoeuvre past an obstacle); min_m (the distance it may first come from);
## need (the lowest entry height that flies it with room to spare, at d 0 and d 1); and the
## height its ideal line leaves at: min(entry + add, cap), each at d 0 and d 1 (add INF: always
## cap). "fixed" pieces are placed by the opening, never chosen. "high_line": the piece's bold line
## dives to a low opening, out of reach from this entry height or above (see Kit.high_from). Outs are a little under what the
## skilled test pilot leaves at in the wind each difficulty brings (1.0 at d 0, 3.0 at d 1):
## tools/endless_log.gd --calibrate.
const TABLE := {
	&"rim": {"tiles": 1, "lift": false, "rest": true, "min_m": 0.0, "fixed": true, "need": Vector2(0.0, 0.0), "add": Vector2(INF, INF), "cap": Vector2(24.0, 24.0)},
	&"street": {"tiles": 1, "lift": true, "rest": true, "min_m": 0.0, "need": Vector2(4.0, 6.0), "add": Vector2(14.0, 8.5), "cap": Vector2(24.0, 24.0)},
	&"barley": {"tiles": 1, "lift": true, "rest": true, "min_m": 0.0, "need": Vector2(9.0, 9.0), "add": Vector2(INF, INF), "cap": Vector2(20.5, 17.5)},
	&"ridge": {"tiles": 2, "lift": true, "rest": true, "min_m": 40.0, "need": Vector2(11.0, 11.0), "add": Vector2(INF, INF), "cap": Vector2(26.5, 27.0)},
	&"hamlet": {"tiles": 1, "lift": true, "rest": false, "min_m": 30.0, "need": Vector2(11.0, 11.0), "add": Vector2(3.5, 3.5), "cap": Vector2(14.5, 14.5)},
	&"kites": {"tiles": 1, "lift": false, "rest": false, "min_m": 0.0, "need": Vector2(14.0, 14.0), "add": Vector2(INF, INF), "cap": Vector2(15.5, 15.5)},
	&"viaduct": {"tiles": 1, "lift": true, "rest": false, "min_m": 75.0, "need": Vector2(12.0, 12.0), "add": Vector2(INF, INF), "cap": Vector2(20.5, 19.5)},
	&"pasture": {"tiles": 1, "lift": true, "rest": false, "min_m": 30.0, "need": Vector2(9.0, 9.0), "add": Vector2(INF, INF), "cap": Vector2(13.0, 11.0)},
	&"washing": {"tiles": 1, "lift": true, "rest": false, "min_m": 60.0, "need": Vector2(10.0, 10.0), "add": Vector2(INF, INF), "cap": Vector2(18.5, 17.5), "high_line": true},
	&"poplars": {"tiles": 1, "lift": true, "rest": false, "min_m": 100.0, "need": Vector2(10.0, 10.0), "add": Vector2(INF, INF), "cap": Vector2(15.0, 13.0)},
	&"barn": {"tiles": 1, "lift": true, "rest": false, "min_m": 120.0, "need": Vector2(10.0, 10.0), "add": Vector2(INF, INF), "cap": Vector2(20.5, 19.5), "high_line": true},
	&"stones": {"tiles": 1, "lift": true, "rest": false, "min_m": 120.0, "need": Vector2(12.0, 12.0), "add": Vector2(INF, INF), "cap": Vector2(20.0, 19.5), "high_line": true},
	&"mere": {"tiles": 1, "lift": true, "rest": false, "min_m": 200.0, "need": Vector2(12.0, 12.0), "add": Vector2(INF, INF), "cap": Vector2(18.0, 19.0)},
}
## Where a run ended, for the end card ("Touchdown in the Hamlet").
const WHERE := {&"rim": "on the Rim", &"street": "under Cloud Street", &"barley": "in the Barley Field", &"ridge": "on the Long Ridge",
	&"hamlet": "in the Hamlet", &"kites": "in Kite Meadow", &"viaduct": "at the Viaduct", &"pasture": "in the Pasture",
	&"washing": "among the Washing Lines", &"poplars": "at Poplar Row", &"barn": "at the Dutch Barn", &"stones": "at the Standing Stones",
	&"mere": "on the Mere"}
const NAMES := {&"rim": "The Rim", &"street": "Cloud Street", &"barley": "Barley Field", &"ridge": "Long Ridge",
	&"hamlet": "Hamlet", &"kites": "Kite Meadow", &"viaduct": "Viaduct", &"pasture": "Pasture", &"washing": "Washing Lines",
	&"poplars": "Poplar Row", &"barn": "Dutch Barn", &"stones": "Standing Stones", &"mere": "Mere"}

## The Barley Field's thermal: centre x from d 0 to d 1, and its middle along the tile.
const BARLEY_X := Vector2(4.0, 12.0)
const BARLEY_Z := -44.0
## The Long Ridge's lift band, and its plateau's height.
const RIDGE_X := -36.0
const RIDGE_PLATEAU := 20.0
## The Hamlet's cottages (centres), each with a chimney at its far gable.
const COTTAGES: Array[Vector2] = [Vector2(-8.0, -20.0), Vector2(8.0, -46.0), Vector2(-8.0, -72.0)]
const COTTAGE := Vector3(6.0, 3.5, 8.0)  ## Width (x), wall height, depth (z).
const COTTAGE_ROOF := 2.5
const CHIMNEY_TOP := 8.0
const PLUME_HEIGHT := 11.0
const PLUME_PITCHES: Array[float] = [1.0, 1.12, 1.26]
## Kite Meadow's ring kites, and their colours.
## (The first is 20 u in, so there is room to line up with it from wherever the last piece ended.)
const HOOPS: Array[Vector3] = [Vector3(0.0, 20.0, -20.0), Vector3(5.0, 19.0, -36.0), Vector3(8.0, 18.0, -52.0), Vector3(4.0, 17.0, -68.0), Vector3(-2.0, 16.0, -84.0)]
const HOOP_COLORS: Array[Color] = [Color("e8604c"), Color("f6c66f"), Color("a9c8e8"), Color("b9a6dc"), Color("9cc48a")]
const HOOP_TUBE := 0.3
## The Viaduct: the middle of its 6 u thickness, its deck, and its arches' centres.
const VIADUCT_Z := -56.0
const VIADUCT_DEPTH := 6.0
const VIADUCT_DECK := 22.0
const VIADUCT_PARAPET := 1.2
const VIADUCT_HALF := 80.0
const ARCH_X: Array[float] = [-25.0, -12.5, 0.0, 12.5, 25.0]
const SHINGLE := Vector2(0.0, -82.0)
## Low warm layers (the Pasture, the gardens): strength at difficulty 0 and 1 (about 0.75 u/s up,
## roughly holding a glide level).
const WARM_LAYER := Vector2(0.16, 0.14)
## The Pasture's hedges: (z, height above the ground), their gates' x, how far they run, and the
## bonfire whose smoke you climb out on.
const PASTURE_HEDGES: Array[Vector2] = [Vector2(-32.0, 2.5), Vector2(-56.0, 3.0), Vector2(-80.0, 3.5)]
const PASTURE_GATES: Array[float] = [-6.0, 8.0, -2.0]
const PASTURE_FIRE := Vector2(7.0, -90.0)
## The hedge-hop's stars step across toward the bonfire: their x over each hedge.
const PASTURE_STAR_X: Array[float] = [0.0, 2.5, 5.0]
const HEDGE_HALF := 40.0
const HEDGE_THICK := 1.5
const HEDGE_DARK := Color("86ad74")
## The Washing Lines: cottages, lines across the way (z), posts either side, the line's height and
## where the sheets hang down to, and the washing copper.
const WASHING_COTTAGES: Array[Vector2] = [Vector2(-18.0, -30.0), Vector2(18.0, -48.0), Vector2(-18.0, -66.0)]
const WASHING_LINES_Z: Array[float] = [-36.0, -52.0, -68.0]
const WASHING_POST_X := 10.0
const WASHING_LINE_Y := 7.5
const WASHING_SHEET_BOTTOM := 6.0
const WASHING_COPPER := Vector2(9.0, -84.0)
## Poplar Row: the row's z, its gap's x and the height to thread it at, how far it runs, the
## spacing, crown radius (drawn and colliding) and crown from-to heights.
const POPLAR_Z := -50.0
const POPLAR_GAP_X := 6.0
const POPLAR_GAP_Y := 10.0
const POPLAR_HALF := 42.0
const POPLAR_SPACING := 4.0
const POPLAR_R := 1.6
const POPLAR_HIT_R := 1.4
const POPLAR_CROWN := Vector2(2.0, 14.0)
## The Dutch Barn: its near and far ends (z), half its width, its walls' and roof's heights, and
## the muck heap.
const BARN_Z := Vector2(-44.0, -64.0)
const BARN_HALF := 7.0
const BARN_WALL := 9.0
const BARN_ROOF := 12.0
const BARN_RED := Color("c1675a")
const BARN_HEAP := Vector2(0.0, -78.0)
## The barn doorways' round edges (radius).
const DOOR_ROUND := 0.6
## The Standing Stones: how many, the ring's middle and radius, each stone's size (across, deep),
## the height to fly through at, and how far out along the way out its thermal stands.
const STONE_COUNT := 11
const STONE_CENTRE := Vector2(0.0, -56.0)
const STONE_RING := 14.0
const STONE_SIZE := Vector2(2.0, 1.0)
const STONE_THROUGH := 5.5
const STONE_THERMAL_AT := 26.0
## The Mere: the water's middle, radii and level, the bed under it, the island and the lake's
## sinking air (strength at difficulty 0 and 1: 0.4 to 0.6 u/s at the default downdraft strength).
const MERE_CENTRE := Vector2(0.0, -50.0)
const MERE_RADII := Vector2(24.0, 34.0)
const MERE_WATER := -1.0
const MERE_BED := -1.6
const MERE_ISLAND := Vector2(-10.0, -58.0)
const MERE_ISLAND_R := 6.0
const MERE_SINK := Vector2(0.4 / 3.5, 0.6 / 3.5)
## Entering a piece at least this high (above the floor), the bold line's low opening is out of
## reach and its ideal line goes over the top instead (Kit.high_from).
const HIGH_FROM := 21.0
## The steepest dive (height lost per unit along) to a low opening a pilot is asked to make; any
## steeper and the high line is the one (see Kit.takes_high()).
const STEEPEST_DIVE := 0.35
## The best-distance marker's poles stand this far either side of the middle.
const MARKER_HALF := 34.0
## Collision holes are this much bigger than drawn on every side (docs/endless-plan.md §3.3).
const HOLE_GRACE := 0.3


static func ids() -> Array:
	return TABLE.keys()


static func info(id: StringName) -> Dictionary:
	return TABLE[id]


static func tiles(id: StringName) -> int:
	return int(TABLE[id]["tiles"])


static func length(id: StringName) -> float:
	return tiles(id) * TILE


## The lowest entry height (above the floor) that flies `id` well at difficulty d.
static func need_in(id: StringName, d: float) -> float:
	var need: Vector2 = TABLE[id]["need"]
	return lerpf(need.x, need.y, d)


## The height the ideal line leaves `id` at, entering at h.
static func out(id: StringName, d: float, h: float) -> float:
	var add: Vector2 = TABLE[id]["add"]
	var cap: Vector2 = TABLE[id]["cap"]
	return minf(h + lerpf(add.x, add.y, d), lerpf(cap.x, cap.y, d))


## Difficulty rounded for a piece's layout.
static func layout_d(d: float) -> float:
	return clampf(snappedf(d, D_STEP), 0.0, 1.0)


# --- Ground -----------------------------------------------------------------------

## The valley's standard cross-section, the same at every piece's edges.
static func standard(x: float) -> float:
	return SIDE * pow(maxf(absf(x) - FLOOR, 0.0), 2.0)


## Soft rolls on the floor only, gone within EDGE_CALM of a piece's edges so the edges always meet.
static func rolls(x: float, z: float, piece_length: float) -> float:
	var calm := smoothstep(0.0, EDGE_CALM, -z) * smoothstep(0.0, EDGE_CALM, z + piece_length)
	var on_floor := 1.0 - smoothstep(FLOOR - 8.0, FLOOR, absf(x))
	return ROLL * sin(x * 0.11 + z * 0.07) * sin(z * 0.05 - x * 0.03 + 0.7) * calm * on_floor


## The Rim's ground at its entry edge: the Course's far rim, in the valley's terms.
static func rim_base(x: float) -> float:
	return Course.ground_height(x, EndlessWorld.START_Z) - EndlessWorld.FLOOR_Y


## The ground of piece `id` (as a smooth curve; the drawn and solid ground is the grid through it).
static func ground(id: StringName, x: float, z: float) -> float:
	var h := standard(x)
	match id:
		&"rim":
			# Up 4 more from the Course's rim to a rounded crest, then down to the standard section.
			var base := rim_base(x)
			var crest := base + 4.0
			if z > -6.0:
				return lerpf(base, crest, smoothstep(0.0, 6.0, -z))
			return lerpf(crest, h, smoothstep(6.0, 72.0, -z))
		&"ridge":
			var w := smoothstep(0.0, 12.0, -z) * (1.0 - smoothstep(180.0, 192.0, -z))
			h = maxf(h, RIDGE_PLATEAU * smoothstep(24.0, 60.0, -x) * w)
		&"barn":
			# The barn's floor and yard are flat.
			var yard := (1.0 - smoothstep(BARN_HALF + 2.0, BARN_HALF + 8.0, absf(x))) * (1.0 - smoothstep(14.0, 20.0, absf(z - (BARN_Z.x + BARN_Z.y) * 0.5)))
			return h + rolls(x, z, length(id)) * (1.0 - yard)
		&"mere":
			var normal := h + rolls(x, z, length(id))
			var lake := lerpf(MERE_BED, normal, smoothstep(0.8, 1.15, mere_reach(x, z)))
			var island := lerpf(0.8, MERE_BED, smoothstep(3.5, MERE_ISLAND_R + 1.0, Vector2(x, z).distance_to(MERE_ISLAND)))
			return maxf(lake, island)
	return h + rolls(x, z, length(id))


## The ground as drawn and as it collides: the triangle grid through ground(), split as the
## Course's is (Course.terrain_height()).
static func grid_height(id: StringName, x: float, z: float) -> float:
	var u := (x + HALF) / STEP
	var v := -z / STEP
	var xa := -HALF + floorf(u) * STEP
	var za := -floorf(v) * STEP
	u -= floorf(u)
	v -= floorf(v)
	var h00 := ground(id, xa, za)
	var h10 := ground(id, xa + STEP, za)
	var h01 := ground(id, xa, za - STEP)
	var h11 := ground(id, xa + STEP, za - STEP)
	if u + v <= 1.0:
		return h00 + u * (h10 - h00) + v * (h01 - h00)
	return h11 + (1.0 - u) * (h01 - h11) + (1.0 - v) * (h10 - h11)


# --- Kits ---------------------------------------------------------------------------

## Everything to place one piece at one (rounded) difficulty. Positions are piece-local.
class Kit:
	var id: StringName
	var d := 0.0
	var mesh: ArrayMesh
	## Its collision, in a few shapes (each built in its own step).
	var shapes: Array[ConcavePolygonShape3D] = []
	## {name, shape (Thermal.Shape), at (base, local), radius, height, size, look, strength,
	##  pitch, drifts, and for ridges seed_amount, seed_centre_y, seed_half_height}.
	var zones: Array[Dictionary] = []
	## {stars: PackedVector3Array, big: Array of bool (one per star), zone: name or "" (stars
	##  that ride a drifting thermal are relative to its home), title: the bonus pop-up, bonus: bool}.
	var arcs: Array[Dictionary] = []
	## The ideal line after the entry; its first point may use the entry height (see line()).
	var line_points: Array[Dictionary] = []
	## {centre: Vector2, zone, radius, to_y (local), up, max_time}.
	var orbits: Array[Dictionary] = []
	## {at: Vector3 (the middle of its flat base), radius, puffs, zone: name or ""}.
	var clouds: Array[Dictionary] = []
	## Circling: {zone, below_top}; hovering: {at}.
	var birds: Array[Dictionary] = []
	## {centre, axis (along the line), radius, color, index}.
	var hoops: Array[Dictionary] = []
	## The arch openings a pass through is felt: {z, depth, openings: [{x, half_span, springing}]}.
	var arches: Array[Dictionary] = []
	## The ridge lift's zone name, if the gull may join you here.
	var gull_lift := ""
	## Things that snag but never crash (washing lines and sheets): capsules {a, b, radius}, and
	## whether a sock flies off.
	var snags: Array[Dictionary] = []
	## Moving scenery: {kind ("sailboat"), centre, radius, speed}.
	var movers: Array[Dictionary] = []
	## Water to splash down on: {centre (x, z), radii, y}, or empty.
	var water := {}
	## Pieces whose line dives to a low opening: entering at `high_from` or above, there's no room
	## to get down to it, so the ideal line is `high_points` instead (over the top).
	var high_points: Array[Dictionary] = []
	var high_from := INF

	## Whether a pilot at `at` (piece-local, near the entry) is on the high line: at or above
	## high_from, or too high to dive to the low line's lowest point ahead at STEEPEST_DIVE.
	func takes_high(at: Vector3) -> bool:
		if high_points.is_empty():
			return false
		if at.y >= high_from:
			return true
		var lowest := Vector3(0.0, INF, 0.0)
		for q in line(at.y):
			if q.z < at.z and q.y < lowest.y:
				lowest = q
		return lowest.y < INF and at.y - lowest.y > EndlessPieces.STEEPEST_DIVE * (at.z - lowest.z)

	## The ideal line for an entry at height `h_in`: points given as Vector3, or {x, z, dy} meaning
	## "the entry height plus dy" (a point held at whatever height the pilot came in at), no higher
	## than "max" if it has one.
	func line(h_in: float) -> PackedVector3Array:
		var out := PackedVector3Array()
		for p: Dictionary in (high_points if h_in >= high_from and not high_points.is_empty() else line_points):
			if p.has("at"):
				out.append(p["at"])
			else:
				out.append(Vector3(p["x"], minf(h_in + float(p["dy"]), float(p.get("max", INF))), p["z"]))
		return out


## Built kits by key ("id:d"), and the builds under way (key -> KitBuild, oldest first).
## A kit takes tens of milliseconds to build on a phone, too long for one frame. So once a piece is
## placed (a few tiles before it is needed) its kit is built a step at a time, a few milliseconds
## each physics tick (pump()), on the main thread. (Building in a worker thread corrupted the
## engine's shared strings and hung.) A run's first pieces are built at once (kit()).
static var _kits := {}
static var _builds := {}


static func _key(id: StringName, d: float) -> String:
	return "%s:%.2f" % [id, layout_d(d)]


## The kit for `id` at difficulty `d` (rounded to D_STEP), built once and kept. If it isn't built
## yet, this builds it now (finishing a build under way): for the first pieces of a run.
static func kit(id: StringName, d: float) -> Kit:
	var key := _key(id, d)
	if _kits.has(key):
		return _kits[key]
	var build: KitBuild = _builds.get(key)
	if build == null:
		build = KitBuild.new(id, layout_d(d))
	while not build.step():
		pass
	_builds.erase(key)
	_kits[key] = build.kit
	return build.kit


## The kit if it is built; otherwise queues its build (see pump()) and returns null.
static func kit_when_ready(id: StringName, d: float) -> Kit:
	var key := _key(id, d)
	if _kits.has(key):
		return _kits[key]
	if not _builds.has(key):
		_builds[key] = KitBuild.new(id, layout_d(d))
	return null


## Works on the queued builds, oldest first, for about `budget_usec` microseconds (always at least
## one step, so builds never stall).
static func pump(budget_usec: int) -> void:
	var start := Time.get_ticks_usec()
	while not _builds.is_empty():
		var key: String = _builds.keys()[0]
		var build: KitBuild = _builds[key]
		if build.step():
			_builds.erase(key)
			_kits[key] = build.kit
		if Time.get_ticks_usec() - start >= budget_usec:
			return


## True while a build is queued or under way.
static func building() -> bool:
	return not _builds.is_empty()


## Forgets the built kits and any builds under way (tests use this to time a build).
static func clear_kits() -> void:
	_builds.clear()
	_kits.clear()


## One kit being built, a step at a time: the piece's own things, then the ground a few rows at a
## time, then where the trees go and the sheep, then the trees a few at a time, then the mesh, then
## the collision shapes a chunk at a time.
class KitBuild:
	const ROWS_PER_STEP := 4
	const TREES_PER_STEP := 4
	const FACES_PER_SHAPE := 4500  ## vertices: 1500 triangles a collision shape
	var kit := Kit.new()
	var look := Art.Builder.new()  ## drawn
	var solid := PackedVector3Array()  ## collides
	var _grid := PackedVector3Array()
	var _paint_rng := RandomNumberGenerator.new()
	var _spots: Array[Dictionary] = []
	var _step := 0
	var _row := 0
	var _next := 0  ## the next tree, or the next face for a collision shape

	func _init(id: StringName, d: float) -> void:
		kit.id = id
		kit.d = d
		_paint_rng.seed = hash(String(id)) + 17

	## Does the next step; true once the kit is complete.
	func step() -> bool:
		var cells_z := int(EndlessPieces.length(kit.id) / STEP)
		match _step:
			0:
				EndlessPieces._content(kit, look, solid)
				_step += 1
			1:
				_grid = EndlessPieces._ground_grid(kit.id)
				_step += 1
			2:
				var to := mini(_row + ROWS_PER_STEP, cells_z)
				EndlessPieces._ground_rows(kit, look, solid, _grid, _row, to, _paint_rng)
				_row = to
				if _row >= cells_z:
					_step += 1
			3:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash(String(kit.id))
				_spots = EndlessPieces._tree_spots(kit, rng)
				EndlessPieces._sheep(kit, look, rng)
				_next = 0
				_step += 1
			4:
				var to := mini(_next + TREES_PER_STEP, _spots.size())
				for i in range(_next, to):
					EndlessPieces._tree(look, solid, _spots[i])
				_next = to
				if _next >= _spots.size():
					_next = 0
					_step += 1
			5:
				kit.mesh = look.commit()
				_step += 1
			6:
				var to := mini(_next + FACES_PER_SHAPE, solid.size())
				var shape := ConcavePolygonShape3D.new()
				shape.set_faces(solid.slice(_next, to))
				shape.backface_collision = true  # some faces (the arches' spandrels) are single sheets
				kit.shapes.append(shape)
				_next = to
				if _next >= solid.size():
					_step += 1
		return _step > 6


## A kit built all at once (tests and tools).
static func _build(id: StringName, d: float) -> Kit:
	var build := KitBuild.new(id, d)
	while not build.step():
		pass
	return build.kit


## The piece's own things: its buildings and props, zones, stars, line, clouds and birds.
static func _content(k: Kit, look: Art.Builder, solid: PackedVector3Array) -> void:
	match k.id:
		&"rim": _rim(k, look, solid, k.d)
		&"street": _street(k, look, solid, k.d)
		&"barley": _barley(k, look, solid, k.d)
		&"ridge": _ridge(k, look, solid, k.d)
		&"hamlet": _hamlet(k, look, solid, k.d)
		&"kites": _kites(k, look, solid, k.d)
		&"viaduct": _viaduct(k, look, solid, k.d)
		&"pasture": _pasture(k, look, solid, k.d)
		&"washing": _washing(k, look, solid, k.d)
		&"poplars": _poplars(k, look, solid, k.d)
		&"barn": _barn(k, look, solid, k.d)
		&"stones": _stones(k, look, solid, k.d)
		&"mere": _mere(k, look, solid, k.d)


## The ground's corners: every one once, (cells across + 1) per row, (cells along + 1) rows.
static func _ground_grid(id: StringName) -> PackedVector3Array:
	var cells_z := int(length(id) / STEP)
	var cells_x := int(HALF * 2.0 / STEP)
	var grid := PackedVector3Array()
	for iz in cells_z + 1:
		for ix in cells_x + 1:
			var x := -HALF + ix * STEP
			var z := -iz * STEP
			grid.append(Vector3(x, ground(id, x, z), z))
	return grid


## Rows `from` to `to` of the ground's cells, each coloured by the piece's paint (fields, the
## green, a shingle bank).
static func _ground_rows(k: Kit, look: Art.Builder, solid: PackedVector3Array, grid: PackedVector3Array, from: int, to: int, rng: RandomNumberGenerator) -> void:
	var cells_x := int(HALF * 2.0 / STEP)
	var row := cells_x + 1
	for iz in range(from, to):
		for ix in cells_x:
			var a := grid[iz * row + ix]
			var b := grid[iz * row + ix + 1]
			var c := grid[(iz + 1) * row + ix]
			var e := grid[(iz + 1) * row + ix + 1]
			var color := _paint(k, (a.x + b.x) * 0.5, (a.z + c.z) * 0.5, rng)
			look.triangle(a, c, b, color)
			look.triangle(b, c, e, color.darkened(0.03) if absf(a.y - e.y) > 1.0 else color)
			solid.append_array([a, c, b, b, c, e])


## The colour of the ground cell centred on (x, z).
static func _paint(k: Kit, x: float, z: float, rng: RandomNumberGenerator) -> Color:
	var on_slope := absf(x) > FLOOR + 4.0
	var base: Color = SLOPE_GRASS[rng.randi() % SLOPE_GRASS.size()] if on_slope else GRASS[rng.randi() % GRASS.size()]
	if not on_slope and rng.randf() < 0.025:
		base = base.lerp(FLOWERS[rng.randi() % FLOWERS.size()], 0.35)  # a whole cell of flowers, softly
	match k.id:
		&"street":
			# A patchwork of four fields, with hedgerows between them.
			if absf(x) < FLOOR:
				if absf(x) < 3.0 or absf(z + 48.0) < 3.0:
					return HEDGE
				var field := (0 if x < 0.0 else 1) + (0 if z > -48.0 else 2)
				return [Color("f4dc9b"), Color("c6dfa8"), Color("e9c98a"), Color("b9d79c")][field].darkened(rng.randf() * 0.03)
		&"hamlet":
			if absf(x) < 15.0 and z < -18.0 and z > -78.0:
				return Color("c9e2ae").darkened(rng.randf() * 0.03)  # the village green
		&"kites":
			if absf(x) < FLOOR and rng.randf() < 0.2:
				return base.lerp(FLOWERS[rng.randi() % FLOWERS.size()], 0.5)  # a festival meadow
		&"viaduct":
			if Vector2(x, z).distance_to(SHINGLE) < 10.0:
				return Color("e6ddcf").darkened(rng.randf() * 0.05)  # the shingle bank
		&"pasture":
			if absf(x) < 18.0 and z < -26.0 and z > -86.0:
				return base.lerp(Color("f4dc9b"), 0.4)  # warm air low over it
			if absf(x) < FLOOR:
				return Color("b9d79c").darkened(rng.randf() * 0.04) if int(floorf(-z / 26.0)) % 2 == 0 else Color("c6dfa8").darkened(rng.randf() * 0.04)
		&"washing":
			if absf(x) < 12.0 and z < -30.0 and z > -74.0:
				return base.lerp(Color("f4dc9b"), 0.4)  # warm air low over the gardens
			if absf(x) < 14.0:
				return Color("c9e2ae") if int(floorf((x + 14.0) / 3.0)) % 2 == 0 else Color("bcd9a0")  # mown stripes
		&"barn":
			if absf(x) < BARN_HALF + 3.0 and absf(z - (BARN_Z.x + BARN_Z.y) * 0.5) < 14.0:
				return Color("e9d7a6").darkened(rng.randf() * 0.05)  # straw on the floor and yard
		&"stones":
			if Vector2(x, z).distance_to(STONE_CENTRE) < STONE_RING + 3.0:
				return Color("cfe0b4").darkened(rng.randf() * 0.04)  # close-cropped down
		&"mere":
			var q := mere_reach(x, z)
			if Vector2(x, z).distance_to(MERE_ISLAND) < MERE_ISLAND_R:
				return Color("eadcb8")  # the island's warm sand
			if q < 0.95:
				return Color("cbbfa6")  # the bed, under the water
			if q < 1.2:
				return Color("e6ddcf").darkened(rng.randf() * 0.05)  # the shore
	return base


## Painted strips on the ground (a stream, a lane, a river): drawn just above it, not solid.
## `centre(z)` gives the strip's middle across the valley along the piece.
static func _strip(k: Kit, look: Art.Builder, centre: Callable, width: float, z0: float, z1: float, colors: Array) -> void:
	var step := 3.0
	var n := maxi(1, ceili(absf(z1 - z0) / step))
	for i in n:
		var za := lerpf(z0, z1, float(i) / n)
		var zb := lerpf(z0, z1, float(i + 1) / n)
		var ca: float = centre.call(za)
		var cb: float = centre.call(zb)
		var pts: Array[Vector3] = []
		for p in [Vector2(ca - width * 0.5, za), Vector2(ca + width * 0.5, za), Vector2(cb - width * 0.5, zb), Vector2(cb + width * 0.5, zb)]:
			pts.append(Vector3(p.x, grid_height(k.id, p.x, p.y) + PAINT_LIFT, p.y))
		var color: Color = colors[i % colors.size()]
		look.triangle(pts[0], pts[2], pts[1], color)
		look.triangle(pts[1], pts[2], pts[3], color)


## Where 8-12 trees a tile stand on the side slopes, clear of every lift zone and the ideal line
## by 6 u, and their sizes and kinds (built by _tree()). Crowns collide a little inside how they
## are drawn; trunks as drawn.
static func _tree_spots(k: Kit, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var spots: Array[Dictionary] = []
	var count := rng.randi_range(8, 12) * tiles(k.id)
	var line := k.line(20.0)
	var tries := 0
	while spots.size() < count and tries < count * 20:
		tries += 1
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var x := side * rng.randf_range(40.0, 90.0)
		var z := rng.randf_range(-length(k.id) + 4.0, -4.0)
		if not _clear_of_air_and_line(k, line, x, z, 6.0):
			continue
		var spot := {"base": Vector3(x, grid_height(k.id, x, z), z), "s": rng.randf_range(0.8, 1.3)}
		spot["pine"] = rng.randf() < 0.45
		if not spot["pine"]:
			spot["leaf"] = LEAF[rng.randi() % 2]
		spots.append(spot)
	return spots


## One tree (see _tree_spots()): a pine or a round crown on a trunk.
static func _tree(look: Art.Builder, solid: PackedVector3Array, spot: Dictionary) -> void:
	var base: Vector3 = spot["base"]
	var s: float = spot["s"]
	_solid_cylinder(look, solid, base - Vector3(0, 0.5, 0), 0.4 * s, 0.3 * s, 4.0 * s, BARK, 5)
	if spot["pine"]:
		look.cylinder(base + Vector3(0, 2.5 * s, 0), 2.6 * s, 0.0, 7.0 * s, LEAF[2], 6)
		_cone_faces(solid, base + Vector3(0, 2.5 * s, 0), 2.6 * s * 0.8, 7.0 * s * 0.9)
	else:
		look.sphere(base + Vector3(0, 5.2 * s, 0), 2.5 * s, spot["leaf"], Vector3(1.0, 0.9, 1.0), 6, 3)
		_sphere_faces(solid, base + Vector3(0, 5.2 * s, 0), 2.5 * s * 0.8)


static func _clear_of_air_and_line(k: Kit, line: PackedVector3Array, x: float, z: float, room: float) -> bool:
	for zone in k.zones:
		var at: Vector3 = zone["at"]
		if zone["shape"] == Thermal.Shape.CYLINDER:
			if Vector2(x - at.x, z - at.z).length() < float(zone["radius"]) + room:
				return false
		else:
			var size: Vector3 = zone["size"]
			if absf(x - at.x) < size.x * 0.5 + room and absf(z - at.z) < size.z * 0.5 + room:
				return false
	for p in line:
		if Vector2(x - p.x, z - p.z).length() < room:
			return false
	return true


## A few sheep grazing on the floor, off the line (looks only).
static func _sheep(k: Kit, look: Art.Builder, rng: RandomNumberGenerator) -> void:
	if k.id in [&"hamlet", &"viaduct", &"washing", &"mere"]:
		return
	var line := k.line(20.0)
	for i in rng.randi_range(2, 5) * tiles(k.id):
		var x := (-1.0 if rng.randf() < 0.5 else 1.0) * rng.randf_range(12.0, 30.0)
		var z := rng.randf_range(-length(k.id) + 8.0, -8.0)
		if not _clear_of_air_and_line(k, line, x, z, 4.0):
			continue
		var base := Vector3(x, grid_height(k.id, x, z), z)
		var turn := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		look.sphere(base + Vector3(0, 0.75, 0), 0.7, WOOL, Vector3(1.0, 0.8, 1.35), 6, 3)
		look.sphere(base + turn * Vector3(0.0, 0.85, -0.95), 0.32, DARK, Vector3.ONE, 5, 3)


# --- Solid shapes -----------------------------------------------------------------------

## A drawn and solid box.
static func _solid_box(look: Art.Builder, solid: PackedVector3Array, centre: Vector3, size: Vector3, color: Color, basis := Basis.IDENTITY) -> void:
	look.box(centre, size, color, basis)
	_box_faces(solid, centre, size, basis)


static func _box_faces(solid: PackedVector3Array, centre: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var m := BoxMesh.new()
	m.size = size
	_mesh_faces(solid, m, Transform3D(basis, centre))


static func _solid_cylinder(look: Art.Builder, solid: PackedVector3Array, base: Vector3, r_bottom: float, r_top: float, height: float, color: Color, segments := 8) -> void:
	look.cylinder(base, r_bottom, r_top, height, color, segments)
	var m := CylinderMesh.new()
	m.bottom_radius = r_bottom
	m.top_radius = r_top
	m.height = height
	m.radial_segments = segments
	m.rings = 0
	_mesh_faces(solid, m, Transform3D(Basis.IDENTITY, base + Vector3(0.0, height * 0.5, 0.0)))


static func _cone_faces(solid: PackedVector3Array, base: Vector3, radius: float, height: float) -> void:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = 0.0
	m.height = height
	m.radial_segments = 6
	m.rings = 0
	_mesh_faces(solid, m, Transform3D(Basis.IDENTITY, base + Vector3(0.0, height * 0.5, 0.0)))


static func _sphere_faces(solid: PackedVector3Array, centre: Vector3, radius: float) -> void:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 6
	m.rings = 3
	_mesh_faces(solid, m, Transform3D(Basis.IDENTITY, centre))


static func _mesh_faces(solid: PackedVector3Array, mesh: PrimitiveMesh, xform: Transform3D) -> void:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i: int in arrays[Mesh.ARRAY_INDEX]:
		solid.append(xform * verts[i])


## A gabled cottage or tent, ridge along z: walls, gable ends and roof, all solid.
static func _gabled(look: Art.Builder, solid: PackedVector3Array, base: Vector3, size: Vector3, roof_rise: float, wall: Color, roof: Color) -> void:
	_solid_box(look, solid, base + Vector3(0.0, size.y * 0.5, 0.0), size, wall)
	var half := size.x * 0.5
	for z in [-size.z * 0.5, size.z * 0.5]:
		var l := base + Vector3(-half, size.y, z)
		var r := base + Vector3(half, size.y, z)
		var top := base + Vector3(0.0, size.y + roof_rise, z)
		look.triangle(l, top, r, wall)
		look.triangle(r, top, l, wall)
	var slope := atan2(roof_rise, half)
	var length_ := sqrt(half * half + roof_rise * roof_rise) + 0.3
	for s in [-1.0, 1.0]:
		var basis := Basis(Vector3.BACK, -s * slope)
		var mid := base + Vector3(s * half * 0.5, size.y + roof_rise * 0.5, 0.0) + basis * Vector3(0.0, 0.1, 0.0)
		_solid_box(look, solid, mid, Vector3(length_, 0.2, size.z + 0.4), roof, basis)


# --- The pieces (docs/endless-plan.md §7.2) ----------------------------------------------

## L0 The Rim: from the Course's far rim up to a rounded crest, then a long grassy fall into the
## new country, with a gentle S of "Welcome" stars down it.
static func _rim(k: Kit, look: Art.Builder, solid: PackedVector3Array, _d: float) -> void:
	var post := Vector3(-12.0, ground(&"rim", -12.0, -6.0), -6.0)  # aside, out of the look back's view
	_solid_cylinder(look, solid, post - Vector3(0, 0.3, 0), 0.15, 0.15, 3.0, CREAM, 6)
	look.box(post + Vector3(0.0, 2.6, -0.9), Vector3(0.12, 0.35, 1.8), CREAM)  # its arm points on
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 9:  # gorse, off the line
		var x := (-1.0 if i % 2 == 0 else 1.0) * rng.randf_range(10.0, 26.0)
		var z := rng.randf_range(-20.0, -88.0)
		look.sphere(Vector3(x, grid_height(&"rim", x, z) + 0.4, z), 1.1, Color("c9c27a"), Vector3(1.2, 0.7, 1.0), 6, 3)
	var stars := PackedVector3Array()
	for i in 8:
		var z := -22.0 - 6.5 * i
		stars.append(Vector3(2.5 * sin(PI * (-z - 22.0) / 19.5) * (1.0 - smoothstep(4.0, 7.0, i)), lerpf(30.3, 26.5, i / 7.0), z))
	k.arcs.append({"name": "welcome", "stars": stars, "big": _no_big(8), "zone": "", "title": "Full arc!", "bonus": true})
	for p in stars:
		k.line_points.append({"at": p})
	k.line_points.append({"at": Vector3(0.0, 24.2, -96.0)})


## P1 Cloud Street: a ribbon of lift under a line of clouds, and a ribbon of stars down it.
static func _street(k: Kit, look: Art.Builder, _solid: PackedVector3Array, d: float) -> void:
	_strip(k, look, func(_z: float) -> float: return -14.0, 2.4, -2.0, -94.0, [WATER, WATER_LIGHT])
	k.zones.append({"name": "Street", "shape": Thermal.Shape.BOX, "at": Vector3(0.0, 0.0, -48.0), "size": Vector3(16.0, 26.0, 80.0),
		"look": Thermal.Look.STREET, "strength": lerpf(0.4, 0.32, d), "pitch": 0.9, "drifts": false})
	for z in [-8.0, -26.0, -44.0, -62.0, -80.0]:
		k.clouds.append({"at": Vector3(0.0, 30.0, z), "radius": 5.5, "puffs": 3, "zone": ""})
	var stars := PackedVector3Array()
	for i in 12:
		stars.append(Vector3(0.0, 22.0 + 3.0 * i / 11.0, -12.0 - 6.5 * i))
	k.arcs.append({"name": "street", "stars": stars, "big": _no_big(12), "zone": "", "title": "Full arc!", "bonus": true,
		"entry_rise": lerpf(1.4, 1.0, d), "entry_below": 23.0, "entry_top": 25.0})
	k.line_points.append({"x": 0.0, "z": -12.0, "dy": 0.0, "max": 22.0})  # down to the stars if high; else held, and up with the lift
	k.line_points.append({"at": Vector3(0.0, 25.0, -84.0)})
	k.line_points.append({"at": Vector3(0.0, 25.0, -96.0)})


## P2 Barley Field: a thermal over a golden field, with a spiral of stars to circle up.
static func _barley(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var c := Vector2(lerpf(BARLEY_X.x, BARLEY_X.y, d), BARLEY_Z)
	for ix in 8:  # the field, 24 x 24 in 3 u squares
		for iz in 8:
			var xa := c.x - 12.0 + ix * 3.0
			var za := c.y + 12.0 - iz * 3.0
			var pts: Array[Vector3] = []
			for p in [Vector2(xa, za), Vector2(xa + 3.0, za), Vector2(xa, za - 3.0), Vector2(xa + 3.0, za - 3.0)]:
				pts.append(Vector3(p.x, grid_height(&"barley", p.x, p.y) + PAINT_LIFT, p.y))
			var color := Color("f4dc9b") if (ix + iz) % 2 == 0 else Color("e9c98a")
			look.triangle(pts[0], pts[2], pts[1], color)
			look.triangle(pts[1], pts[2], pts[3], color)
	for at in [Vector2(c.x - 12.0, -32.0), Vector2(c.x + 12.0, -32.0), Vector2(c.x - 12.0, -56.0), Vector2(c.x + 12.0, -56.0)]:
		var base := Vector3(at.x, grid_height(&"barley", at.x, at.y), at.y)
		var roll := Basis(Vector3.BACK, PI * 0.5)
		var bale := CylinderMesh.new()
		bale.top_radius = 1.0
		bale.bottom_radius = 1.0
		bale.height = 1.5
		bale.radial_segments = 10
		bale.rings = 0
		var xf := Transform3D(roll, base + Vector3(0.0, 1.0, 0.0))
		look.add(bale, xf, Color("e9c98a"))
		_mesh_faces(solid, bale, xf)
	var radius := lerpf(12.0, 10.0, d)
	var top := lerpf(26.0, 23.0, d)
	var floor_y := ground(&"barley", c.x, c.y)
	k.zones.append({"name": "Barley", "shape": Thermal.Shape.CYLINDER, "at": Vector3(c.x, floor_y, c.y), "radius": radius,
		"height": top - floor_y, "look": Thermal.Look.WARM_AIR, "strength": lerpf(0.9, 0.7, d), "pitch": 1.0, "drifts": true})
	k.clouds.append({"at": Vector3(c.x, top + 4.0, c.y), "radius": radius * 0.7, "puffs": 4, "zone": "Barley"})
	k.birds.append({"zone": "Barley", "below_top": 4.0})
	# A helix round the thermal's live centre, from its near side, turning the way the test
	# pilots circle, rising as fast as a full-bank climb.
	var stars := PackedVector3Array()
	var rise := lerpf(2.5, 2.0, d)
	for i in 6:
		var a := PI * 0.5 + deg_to_rad(40.0) * i
		stars.append(Vector3(c.x + 6.0 * cos(a), 9.0 + rise * i, c.y + 6.0 * sin(a)))
	k.arcs.append({"name": "spiral", "stars": stars, "big": _no_big(6), "zone": "Barley", "title": "Full spiral!", "bonus": true,
		"spiral": {"radius": 6.0, "rise": 3.0, "step": 40.0, "top": top}})
	# Down into the air's lower part at the circle's near edge (the spiral forms where you start
	# circling), then round and up.
	k.line_points.append({"at": Vector3(c.x, 9.0, c.y + 6.0)})
	k.orbits.append({"centre": c, "zone": "Barley", "radius": 6.0, "to_y": top - 2.0, "up": true, "max_time": 25.0})
	k.line_points.append({"at": Vector3(c.x * 0.5, top - 4.0, -72.0)})
	k.line_points.append({"at": Vector3(0.0, top - 5.0, -96.0)})


## P3 Long Ridge: the left side rises into a ridge; soar its face, with the gull.
static func _ridge(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var tor := Vector3(-46.0, grid_height(&"ridge", -46.0, -124.0) - 1.0, -124.0)
	_solid_box(look, solid, tor + Vector3(0.0, 3.5, 0.0), Vector3(5.0, 7.0, 5.0), Color("b9b2aa"), Basis(Vector3.UP, 0.4))
	look.box(tor + Vector3(0.6, 7.4, 0.3), Vector3(3.4, 1.2, 3.0), Color("c9c2ba"), Basis(Vector3.UP, 0.9))
	_diamond_kite(look, Vector3(-58.0, 34.0, -176.0), Vector3(-58.0, RIDGE_PLATEAU, -170.0), Color("e8604c"))
	k.zones.append({"name": "Ridge", "shape": Thermal.Shape.BOX, "at": Vector3(RIDGE_X, 0.0, -96.0), "size": Vector3(20.0, 30.0, 176.0),
		"look": Thermal.Look.RIDGE, "strength": lerpf(0.45, 0.35, d), "pitch": 0.85, "drifts": false,
		"seed_amount": 120, "seed_centre_y": 16.0, "seed_half_height": 6.0})
	k.gull_lift = "Ridge"
	for z in [-30.0, -70.0, -110.0, -150.0]:
		k.birds.append({"at": Vector3(-54.0, 23.0, z)})
	var ridge := PackedVector3Array()
	for i in 10:
		ridge.append(Vector3(RIDGE_X, lerpf(15.0, 21.5, i / 9.0), lerpf(-40.0, -88.0, i / 9.0)))
	k.arcs.append({"name": "ridge", "stars": ridge, "big": _no_big(10), "zone": "", "title": "Full arc!", "bonus": true})
	var crest := PackedVector3Array()
	for i in 6:
		crest.append(Vector3(RIDGE_X, lerpf(26.5, 29.0, i / 5.0), -120.0 - 6.0 * i))
	k.arcs.append({"name": "crest", "stars": crest, "big": _no_big(6), "zone": "", "title": "Full arc!", "bonus": true})
	k.arcs.append({"name": "ridge big star", "stars": PackedVector3Array([Vector3(RIDGE_X, 29.0, -170.0)]), "big": [true], "zone": "", "title": "", "bonus": false})
	k.line_points.append({"x": -20.0, "z": -18.0, "dy": -1.5})
	for p in [Vector3(RIDGE_X, 15.0, -40.0), Vector3(RIDGE_X, 21.5, -88.0), Vector3(RIDGE_X, 26.5, -120.0), Vector3(RIDGE_X, 29.0, -150.0),
			Vector3(RIDGE_X, 29.0, -176.0), Vector3(-14.0, 27.5, -192.0)]:
		k.line_points.append({"at": p})


## P4 Hamlet: three cottages whose chimney smoke rises in plumes to weave through, and a church.
static func _hamlet(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	_strip(k, look, func(z: float) -> float: return 3.0 * sin(-z * 0.07) + 14.0, 2.2, -2.0, -94.0, [CREAM])  # the lane
	var walls: Array[Color] = [Color("f2e3d5"), Color("e3eedf"), Color("f4dc9b")]
	var roofs: Array[Color] = [Color("c1675a"), Color("5f5b70"), Color("c1675a")]
	var plume_r := lerpf(4.0, 3.5, d)
	var stars := PackedVector3Array()
	for i in COTTAGES.size():
		var at := COTTAGES[i]
		var base := Vector3(at.x, _lowest(&"hamlet", at, COTTAGE), at.y)
		_gabled(look, solid, base, COTTAGE, COTTAGE_ROOF, walls[i], roofs[i])
		var chimney := Vector3(at.x, base.y, at.y - COTTAGE.z * 0.5 + 0.5)
		_solid_box(look, solid, Vector3(chimney.x, (CHIMNEY_TOP + base.y) * 0.5, chimney.z), Vector3(1.0, CHIMNEY_TOP - base.y, 1.0), Color("b8877a"))
		k.zones.append({"name": "Plume%d" % i, "shape": Thermal.Shape.CYLINDER, "at": Vector3(chimney.x, CHIMNEY_TOP, chimney.z),
			"radius": plume_r, "height": PLUME_HEIGHT, "look": Thermal.Look.STEAM, "strength": lerpf(1.2, 1.1, d),
			"pitch": PLUME_PITCHES[i], "drifts": false})
		var plume_base: float = [15.0, 13.0, 14.0][i]  # the first high enough to reach from a usual entry
		for j in 3:
			stars.append(Vector3(chimney.x, plume_base + 0.5 * j, chimney.z + 5.0 - 2.0 * j))
	k.arcs.append({"name": "chimneys", "stars": stars, "big": _no_big(9), "zone": "", "title": "Full arc!", "bonus": true})
	var church := Vector3(lerpf(18.0, 14.0, d), 0.0, -62.0)
	church.y = _lowest(&"hamlet", Vector2(church.x, church.z), Vector3(5.0, 0.0, 5.0))
	_solid_box(look, solid, church + Vector3(0.0, 5.5, 0.0), Vector3(5.0, 11.0, 5.0), Color("e8e0d2"))
	_solid_cylinder(look, solid, church + Vector3(0.0, 11.0, 0.0), 3.0, 0.0, 8.0, Color("8a8496"), 4)
	for p in [Vector3(-8.0, 15.0, -16.0), Vector3(-8.0, 16.0, -27.0), Vector3(8.0, 13.0, -44.0), Vector3(8.0, 14.0, -53.0),
			Vector3(-8.0, 14.0, -70.0), Vector3(-8.0, 15.0, -79.0), Vector3(0.0, 15.0, -96.0)]:
		k.line_points.append({"at": p})


## P5 Kite Meadow: a slalom of ring kites over a festival meadow. Touching a ring snags.
static func _kites(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	for at in [Vector2(-22.0, -20.0), Vector2(22.0, -20.0), Vector2(-22.0, -70.0), Vector2(22.0, -70.0)]:
		var base := Vector3(at.x, _lowest(&"kites", at, Vector3(4.0, 0.0, 4.0)), at.y)
		_gabled(look, solid, base, Vector3(4.0, 3.0, 4.0), 1.5, Color("f6e1d3"), Color("e8604c") if at.y > -40.0 else Color("a9c8e8"))
	k.zones.append({"name": "Meadow", "shape": Thermal.Shape.BOX, "at": Vector3(0.0, 0.0, -48.0), "size": Vector3(18.0, 26.0, 84.0),
		"look": Thermal.Look.STREET, "strength": lerpf(0.28, 0.22, d), "pitch": 0.92, "drifts": false})
	for z in [-20.0, -52.0, -84.0]:
		k.clouds.append({"at": Vector3(-6.0 + z * 0.1, 30.0, z), "radius": 3.5, "puffs": 3, "zone": ""})
	var radius := lerpf(3.0, 2.2, d)
	var holder_x: Array[float] = [-14.0, 18.0, 22.0, 17.0, -15.0]
	var shirts: Array[Color] = [Color("e8604c"), Color("a9c8e8"), Color("f6c66f")]
	var stars := PackedVector3Array()
	var big := []
	for i in HOOPS.size():
		var c := HOOPS[i]
		var prev: Vector3 = HOOPS[i - 1] if i > 0 else Vector3(0.0, 20.0, 0.0)
		var next: Vector3 = HOOPS[i + 1] if i < HOOPS.size() - 1 else Vector3(-4.0, 16.0, -96.0)
		var axis := (next - prev).normalized()
		k.hoops.append({"centre": c, "axis": axis, "radius": radius, "color": HOOP_COLORS[i], "index": i})
		_hoop_mesh(look, c, axis, radius, HOOP_COLORS[i])
		# Its string down to a kid on the meadow, who holds it.
		var kid := Vector3(holder_x[i], 0.0, c.z + 6.0)
		kid.y = grid_height(&"kites", kid.x, kid.z)
		look.cylinder(kid, 0.35, 0.3, 1.0, shirts[i % shirts.size()], 6)
		look.sphere(kid + Vector3(0, 1.3, 0), 0.3, Color("f2d3bd"), Vector3.ONE, 6, 3)
		var hang := c - Vector3(0, radius + HOOP_TUBE, 0)
		_line(look, kid + Vector3(0, 1.0, 0), hang, Color("f4efe6"), 0.04)
		_ribbon(look, hang, HOOP_COLORS[i])
		if i == HOOPS.size() - 1 and d >= 0.4:
			stars.append(c)
			big.append(true)
		else:
			for s in [-1.2, 0.0, 1.2]:
				stars.append(c + axis * s)
				big.append(false)
	k.arcs.append({"name": "hoops", "stars": stars, "big": big, "zone": "", "title": "Hoop run!", "bonus": true})
	k.line_points.append({"at": Vector3(0.0, 20.0, -4.0)})
	for c in HOOPS:
		k.line_points.append({"at": c})
	k.line_points.append({"at": Vector3(-4.0, 16.0, -96.0)})


## P6 Viaduct: a stone viaduct across the valley; dive through its middle arch into a thermal
## over the shingle bank, or go over the deck.
static func _viaduct(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	_strip(k, look, func(z: float) -> float: return 2.0 * sin(-z * 0.06), 6.0, -2.0, -94.0, [WATER, WATER_LIGHT])
	var span := lerpf(10.0, 7.5, d)
	var springing := lerpf(11.0, 9.0, d)
	_viaduct_wall(look, PackedVector3Array(), span, springing, true)
	_viaduct_wall(look, solid, span + HOLE_GRACE * 2.0, springing, false)  # the holes a little bigger
	var openings := []
	for x in ARCH_X:
		openings.append({"x": x, "half_span": span * 0.5, "springing": springing})
	k.arches.append({"z": VIADUCT_Z, "depth": VIADUCT_DEPTH, "openings": openings})
	var radius := lerpf(11.0, 10.0, d)
	var top := lerpf(24.0, 22.0, d)
	var floor_y := ground(&"viaduct", SHINGLE.x, SHINGLE.y)
	k.zones.append({"name": "Shingle", "shape": Thermal.Shape.CYLINDER, "at": Vector3(SHINGLE.x, floor_y, SHINGLE.y), "radius": radius,
		"height": top - floor_y, "look": Thermal.Look.WARM_AIR, "strength": lerpf(0.85, 0.7, d), "pitch": 1.05, "drifts": true})
	k.clouds.append({"at": Vector3(SHINGLE.x, top + 4.0, SHINGLE.y), "radius": radius * 0.7, "puffs": 4, "zone": "Shingle"})
	k.birds.append({"zone": "Shingle", "below_top": 4.0})
	var dive := PackedVector3Array()
	for i in 6:
		dive.append(Vector3(0.0, lerpf(19.0, 9.0, i / 5.0), -16.0 - 6.0 * i))
	k.arcs.append({"name": "dive", "stars": dive, "big": _no_big(6), "zone": "", "title": "Full arc!", "bonus": true})
	k.arcs.append({"name": "arch big star", "stars": PackedVector3Array([Vector3(0.0, 8.5, VIADUCT_Z)]), "big": [true], "zone": "", "title": "", "bonus": false})
	k.arcs.append({"name": "deck", "stars": PackedVector3Array([Vector3(0.0, 25.5, -52.0), Vector3(0.0, 25.5, -56.0), Vector3(0.0, 25.5, -60.0)]),
		"big": _no_big(3), "zone": "", "title": "Full arc!", "bonus": true, "alt": true})
	for p in [Vector3(0.0, 19.0, -16.0), Vector3(0.0, 9.0, -46.0), Vector3(0.0, 8.5, VIADUCT_Z), Vector3(0.0, 8.0, -70.0)]:
		k.line_points.append({"at": p})
	k.orbits.append({"centre": SHINGLE, "zone": "Shingle", "radius": 6.0, "to_y": top - 2.0, "up": true, "max_time": 25.0})
	k.line_points.append({"at": Vector3(0.0, top - 4.0, -96.0)})


## The viaduct's wall: piers with rounded cutwaters, arches (semicircles on their springing) with
## spandrels up to the deck, parapets, and solid wall running into the hillsides. Drawn into
## `look` (drawn true), or its faces collected into `solid` (the caller widens the openings).
static func _viaduct_wall(look: Art.Builder, solid: PackedVector3Array, span: float, springing: float, drawn: bool) -> void:
	var z0 := VIADUCT_Z + VIADUCT_DEPTH * 0.5  # upstream face
	var z1 := VIADUCT_Z - VIADUCT_DEPTH * 0.5
	var half := span * 0.5
	var segments := 10
	var faces := PackedVector3Array()
	# Each arch: the spandrel above its curve on both faces, and the curved underside.
	for xc in ARCH_X:
		for i in segments:
			var a0 := PI * float(i) / segments
			var a1 := PI * float(i + 1) / segments
			var p0 := Vector2(xc - half * cos(a0), springing + half * sin(a0))
			var p1 := Vector2(xc - half * cos(a1), springing + half * sin(a1))
			for zf in [z0, z1]:
				faces.append_array([Vector3(p0.x, p0.y, zf), Vector3(p0.x, VIADUCT_DECK, zf), Vector3(p1.x, VIADUCT_DECK, zf),
					Vector3(p0.x, p0.y, zf), Vector3(p1.x, VIADUCT_DECK, zf), Vector3(p1.x, p1.y, zf)])
			faces.append_array([Vector3(p0.x, p0.y, z0), Vector3(p1.x, p1.y, z0), Vector3(p1.x, p1.y, z1),
				Vector3(p0.x, p0.y, z0), Vector3(p1.x, p1.y, z1), Vector3(p0.x, p0.y, z1)])
	var boxes: Array[AABB] = []
	var edges := [-VIADUCT_HALF]
	for xc in ARCH_X:
		edges.append(xc - half)
		edges.append(xc + half)
	edges.append(VIADUCT_HALF)
	var down := -12.0  # well below the floor and the slopes' feet
	for i in range(0, edges.size(), 2):  # piers, up to the springing
		boxes.append(AABB(Vector3(edges[i], down, z1), Vector3(edges[i + 1] - edges[i], springing - down, VIADUCT_DEPTH)))
	for i in ARCH_X.size() - 1:  # between neighbouring arches, up to the deck
		var l: float = ARCH_X[i] + half
		var r: float = ARCH_X[i + 1] - half
		if r - l > 0.01:
			boxes.append(AABB(Vector3(l, springing, z1), Vector3(r - l, VIADUCT_DECK - springing, VIADUCT_DEPTH)))
	var outer: float = ARCH_X[ARCH_X.size() - 1] + half
	for side in [-1.0, 1.0]:  # beyond the outer arches, up to the deck
		var x0: float = outer if side > 0.0 else -VIADUCT_HALF
		boxes.append(AABB(Vector3(x0, springing, z1), Vector3(VIADUCT_HALF - outer, VIADUCT_DECK - springing, VIADUCT_DEPTH)))
	boxes.append(AABB(Vector3(-VIADUCT_HALF, VIADUCT_DECK, z1 - 0.3), Vector3(VIADUCT_HALF * 2.0, 0.3, VIADUCT_DEPTH + 0.6)))  # the deck
	for zf in [z0 - 0.3, z1 + 0.3]:  # parapets, on the deck's edges
		boxes.append(AABB(Vector3(-VIADUCT_HALF, VIADUCT_DECK, zf - 0.3), Vector3(VIADUCT_HALF * 2.0, VIADUCT_PARAPET, 0.6)))
	for b in boxes:
		if drawn:
			look.box(b.get_center(), b.size, STONE)
		else:
			_box_faces(solid, b.get_center(), b.size)
	# Each inner pier's rounded cutwater on its upstream face, so a clipped pier glances off.
	for i in range(2, edges.size() - 2, 2):
		var r: float = (edges[i + 1] - edges[i]) * 0.5
		var m := CylinderMesh.new()
		m.top_radius = r
		m.bottom_radius = r
		m.height = springing - down
		m.radial_segments = 10
		m.rings = 0
		var xf := Transform3D(Basis.IDENTITY, Vector3((edges[i] + edges[i + 1]) * 0.5, (springing + down) * 0.5, z0))
		if drawn:
			look.add(m, xf, STONE_DARK)
		else:
			_mesh_faces(solid, m, xf)
	if drawn:
		for i in range(0, faces.size(), 3):  # both ways round: these faces are seen from both sides
			look.triangle(faces[i], faces[i + 1], faces[i + 2], STONE)
			look.triangle(faces[i], faces[i + 2], faces[i + 1], STONE)
	else:
		solid.append_array(faces)


## A sun-warmed layer of air low over a piece's floor: the bold line skimming the hedges or
## ducking the washing is carried level; above the layer's top the safe line sinks as usual.
static func _warm_layer(k: Kit, name: String, at: Vector3, size: Vector3, d: float) -> void:
	k.zones.append({"name": name, "shape": Thermal.Shape.BOX, "at": at, "size": size, "look": Thermal.Look.STREET,
		"strength": lerpf(WARM_LAYER.x, WARM_LAYER.y, d), "pitch": 0.94, "drifts": false})


## A hedge across the floor at `z`, `height` tall above the ground under it, with a rounded top
## and a field gate `gate` wide at `gate_x` (two posts and an open gap). All solid.
static func _hedge(k: Kit, look: Art.Builder, solid: PackedVector3Array, z: float, height: float, gate_x: float, gate: float) -> void:
	var runs: Array[Vector2] = [Vector2(-HEDGE_HALF, gate_x - gate * 0.5), Vector2(gate_x + gate * 0.5, HEDGE_HALF)]
	for run in runs:
		var n := maxi(1, ceili((run.y - run.x) / 4.0))
		for i in n:
			var x0 := lerpf(run.x, run.y, float(i) / n)
			var x1 := lerpf(run.x, run.y, float(i + 1) / n)
			var g := minf(grid_height(k.id, x0, z), grid_height(k.id, x1, z))
			var top := maxf(grid_height(k.id, x0, z), grid_height(k.id, x1, z)) + height
			var r := HEDGE_THICK * 0.5
			var box_top := top - r
			_solid_box(look, solid, Vector3((x0 + x1) * 0.5, (g - 0.8 + box_top) * 0.5, z), Vector3(x1 - x0, box_top - g + 0.8, HEDGE_THICK), HEDGE_DARK)
			var cap := CylinderMesh.new()  # the rounded top, along x
			cap.top_radius = r
			cap.bottom_radius = r
			cap.height = x1 - x0
			cap.radial_segments = 8
			cap.rings = 0
			var xf := Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3((x0 + x1) * 0.5, box_top, z))
			look.add(cap, xf, HEDGE)
			_mesh_faces(solid, cap, xf)
	for side in [-1.0, 1.0]:  # the gate's posts
		var x: float = gate_x + side * (gate * 0.5 + 0.15)
		_solid_box(look, solid, Vector3(x, grid_height(k.id, x, z) + 0.6, z), Vector3(0.3, 2.0, 0.3), CREAM)


## The ground under hedge `i`'s line at x 0, plus its height: where the hedge's top is.
static func _hedge_top(i: int) -> float:
	return grid_height(&"pasture", 0.0, PASTURE_HEDGES[i].x) + PASTURE_HEDGES[i].y


## P7 Pasture: three hedgerows across the floor to hop low and fast, each with a field gate, and a
## garden bonfire's smoke to climb out on.
static func _pasture(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var gate := lerpf(6.0, 4.5, d)
	var skim := lerpf(3.0, 2.25, d)
	var stars := PackedVector3Array()
	for i in PASTURE_HEDGES.size():
		var h := PASTURE_HEDGES[i]
		_hedge(k, look, solid, h.x, h.y, PASTURE_GATES[i], gate)
		var y := _hedge_top(i) + skim
		for dz in ([0.0, -4.0] if i == 0 else [4.0, 0.0, -4.0]):  # (from the usual entry, a star before the first is out of reach)
			stars.append(Vector3(PASTURE_STAR_X[i], y, h.x + dz))
	_warm_layer(k, "Warm", Vector3(0.0, 0.0, -56.0), Vector3(36.0, 9.0, 60.0), d)
	var fire := Vector3(PASTURE_FIRE.x, grid_height(&"pasture", PASTURE_FIRE.x, PASTURE_FIRE.y), PASTURE_FIRE.y)
	look.sphere(fire + Vector3(0, 0.3, 0), 1.3, Color("b5835a"), Vector3(1.0, 0.5, 1.0), 7, 3)  # the heap of clippings
	look.sphere(fire + Vector3(0, 0.7, 0), 0.6, Color("f19e5f"), Vector3(1.0, 0.8, 1.0), 6, 3)  # its glow
	k.zones.append({"name": "Bonfire", "shape": Thermal.Shape.CYLINDER, "at": fire + Vector3(0, 1.0, 0), "radius": 5.5, "height": 20.0,
		"look": Thermal.Look.STEAM, "strength": lerpf(1.5, 1.4, d), "pitch": 1.08, "drifts": false})
	k.arcs.append({"name": "hedge-hop", "stars": stars, "big": _no_big(stars.size()), "zone": "", "title": "Hedge-hop!", "bonus": true})
	var smoke := PackedVector3Array()  # up the smoke, as a pilot rises through it
	for i in 4:
		smoke.append(Vector3(PASTURE_FIRE.x - 1.0 + 0.4 * i, 6.6 + 1.65 * i, PASTURE_FIRE.y + 3.0 - 2.4 * i))  # (traced)
	k.arcs.append({"name": "bonfire", "stars": smoke, "big": _no_big(4), "zone": "", "title": "Full arc!", "bonus": true})
	k.line_points.append({"x": 0.0, "z": -8.0, "dy": 0.0})
	for p in stars:
		k.line_points.append({"at": p})
	for p in smoke:
		k.line_points.append({"at": p})
	k.line_points.append({"at": Vector3(PASTURE_FIRE.x, 14.0, -96.0)})


## P8 Washing Lines: three cottage gardens with washing hung across the way. Duck under the sheets
## (they snag, and a sock flies off) or hop over the lines; a washing copper's steam lifts you on.
static func _washing(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var walls: Array[Color] = [Color("f2e3d5"), Color("e3eedf"), Color("f4dc9b")]
	var roofs: Array[Color] = [Color("c1675a"), Color("5f5b70"), Color("c1675a")]
	for i in WASHING_COTTAGES.size():
		var at := WASHING_COTTAGES[i]
		_gabled(look, solid, Vector3(at.x, _lowest(&"washing", at, COTTAGE), at.y), COTTAGE, COTTAGE_ROOF, walls[i], roofs[i])
	var sheet_colors: Array[Color] = [Color("fbf8f1"), Color("a9c8e8"), Color("f19e8f"), Color("f6e1d3"), Color("c6dfa8"), Color("b9a6dc")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var low := lerpf(4.5, 4.0, d)
	var stars := PackedVector3Array()
	for li in WASHING_LINES_Z.size():
		var z := WASHING_LINES_Z[li]
		for side in [-1.0, 1.0]:
			var x: float = side * WASHING_POST_X
			_solid_cylinder(look, solid, Vector3(x, grid_height(&"washing", x, z) - 0.4, z), 0.15, 0.12, WASHING_LINE_Y + 0.7, Color("a88b74"), 6)
		var a := Vector3(-WASHING_POST_X, WASHING_LINE_Y, z)
		var b := Vector3(WASHING_POST_X, WASHING_LINE_Y, z)
		_line(look, a, b, Color("f4efe6"), 0.06)
		k.snags.append({"a": a, "b": b, "radius": 0.1, "sock": false})
		# Sheets and shirts along the line, with gaps; each snags as a soft bar at its middle.
		var x := -WASHING_POST_X + 1.0
		while x < WASHING_POST_X - 2.0:
			var w := rng.randf_range(1.4, 2.6)
			if x + w > WASHING_POST_X - 0.8:
				break
			var color: Color = sheet_colors[rng.randi() % sheet_colors.size()]
			var drop := WASHING_LINE_Y - WASHING_SHEET_BOTTOM - rng.randf_range(0.0, 0.3)
			var sway := rng.randf_range(-0.12, 0.12)
			var top_l := Vector3(x, WASHING_LINE_Y, z)
			var top_r := Vector3(x + w, WASHING_LINE_Y, z)
			var bottom_l := Vector3(x, WASHING_LINE_Y - drop, z - sway)
			var bottom_r := Vector3(x + w, WASHING_LINE_Y - drop, z - sway)
			for side in [color, color.darkened(0.05)]:  # both ways round: seen from either side
				look.triangle(top_l, bottom_l, top_r, side)
				look.triangle(top_r, bottom_l, bottom_r, side)
				var swap := top_l
				top_l = top_r
				top_r = swap
				swap = bottom_l
				bottom_l = bottom_r
				bottom_r = swap
			k.snags.append({"a": Vector3(x + 0.4, WASHING_LINE_Y - drop * 0.5, z), "b": Vector3(x + w - 0.4, WASHING_LINE_Y - drop * 0.5, z),
				"radius": drop * 0.5, "sock": true})
			for peg in [x + 0.15, x + w - 0.15]:
				look.box(Vector3(peg, WASHING_LINE_Y, z), Vector3(0.08, 0.25, 0.1), Color("e8604c"))
			x += w + rng.randf_range(0.6, 1.6)
		var y := low - 0.5 * li
		for dz in [3.0, 0.0, -3.0]:
			stars.append(Vector3(1.5 * li, y, z + dz))
	_warm_layer(k, "Gardens", Vector3(0.0, 0.0, -52.0), Vector3(24.0, 7.0, 44.0), d)
	# The wash-house, and its copper steaming in the yard.
	var house := Vector2(-11.0, WASHING_COPPER.y - 2.0)
	_gabled(look, solid, Vector3(house.x, _lowest(&"washing", house, Vector3(5.0, 0.0, 4.0)), house.y), Vector3(5.0, 2.6, 4.0), 1.6, CREAM, Color("8a8496"))
	var copper := Vector3(WASHING_COPPER.x, grid_height(&"washing", WASHING_COPPER.x, WASHING_COPPER.y), WASHING_COPPER.y)
	_solid_cylinder(look, solid, copper - Vector3(0, 0.3, 0), 0.9, 0.8, 1.3, Color("b8877a"), 8)
	look.cylinder(copper + Vector3(0, 1.0, 0), 0.7, 0.7, 0.05, Color("dceef6"), 8)
	var top := lerpf(22.0, 20.0, d)
	k.zones.append({"name": "Copper", "shape": Thermal.Shape.CYLINDER, "at": copper + Vector3(0, 1.0, 0), "radius": 10.0, "height": top - copper.y - 1.0,
		"look": Thermal.Look.STEAM, "strength": lerpf(0.9, 0.8, d), "pitch": 1.12, "drifts": true})
	k.arcs.append({"name": "washing", "stars": stars, "big": _no_big(9), "zone": "", "title": "Under the washing!", "bonus": true, "line": "low"})
	_spiral(k, "copper", "Copper", WASHING_COPPER, 7.0, top, 6, d)
	var over := PackedVector3Array()
	for z in WASHING_LINES_Z:
		over.append(Vector3(0.0, WASHING_LINE_Y + 5.0 - over.size(), z))  # 12.5, 11.5, 10.5
	k.arcs.append({"name": "over the washing", "stars": over, "big": _no_big(3), "zone": "", "title": "Full arc!", "bonus": true, "line": "high"})
	k.line_points.append({"x": 0.0, "z": -10.0, "dy": 0.0, "max": 9.0})
	for p in stars:
		k.line_points.append({"at": p})
	k.high_from = HIGH_FROM
	k.high_points.append({"x": 0.0, "z": -10.0, "dy": 0.0})
	for p in over:
		k.high_points.append({"at": p})
	for points: Array[Dictionary] in [k.line_points, k.high_points]:
		points.append({"at": Vector3(WASHING_COPPER.x, 7.0, WASHING_COPPER.y + 6.0)})
		points.append({"at": Vector3(0.0, top - 4.0, -96.0)})
	k.orbits.append({"centre": WASHING_COPPER, "zone": "Copper", "radius": 5.0, "to_y": top - 2.0, "up": true, "max_time": 25.0})


## P9 Poplar Row: a wall of tall poplars across the valley with one gap. Climb in the cloud street
## before it, then thread the gap (or go over); another street lifts you on beyond.
static func _poplars(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var gap := lerpf(8.0, 5.6, d)
	# Every 4 u out from the gap's two sides, so the gap is the only way through.
	var flank := gap * 0.5 + POPLAR_R
	var xs: Array[float] = []
	var x := POPLAR_GAP_X - flank
	while x >= -POPLAR_HALF:
		xs.append(x)
		x -= POPLAR_SPACING
	x = POPLAR_GAP_X + flank
	while x <= POPLAR_HALF:
		xs.append(x)
		x += POPLAR_SPACING
	for tx in xs:
		var base := Vector3(tx, grid_height(&"poplars", tx, POPLAR_Z), POPLAR_Z)
		_solid_cylinder(look, solid, base - Vector3(0, 0.4, 0), 0.3, 0.25, POPLAR_CROWN.x + 0.6, BARK, 5)
		var mid := (POPLAR_CROWN.x + POPLAR_CROWN.y) * 0.5
		var half := (POPLAR_CROWN.y - POPLAR_CROWN.x) * 0.5
		look.sphere(base + Vector3(0, mid, 0), POPLAR_R, LEAF[int(absf(tx)) % 3], Vector3(1.0, half / POPLAR_R, 1.0), 7, 5)
		var crown := CylinderMesh.new()
		crown.top_radius = POPLAR_HIT_R * 0.6
		crown.bottom_radius = POPLAR_HIT_R
		crown.height = POPLAR_CROWN.y - POPLAR_CROWN.x - 0.5
		crown.radial_segments = 6
		crown.rings = 0
		_mesh_faces(solid, crown, Transform3D(Basis.IDENTITY, base + Vector3(0, POPLAR_CROWN.x + crown.height * 0.5, 0)))
	var strength := lerpf(0.36, 0.32, d)
	for street in [["StreetIn", -24.0, 32.0], ["StreetOut", -76.0, 32.0]]:
		k.zones.append({"name": street[0], "shape": Thermal.Shape.BOX, "at": Vector3(POPLAR_GAP_X, 0.0, street[1]), "size": Vector3(10.0, 24.0, street[2]),
			"look": Thermal.Look.STREET, "strength": strength, "pitch": 0.9 if street[0] == "StreetIn" else 0.95, "drifts": false})
	for z in [-14.0, -32.0, -70.0, -88.0]:
		k.clouds.append({"at": Vector3(POPLAR_GAP_X, 28.0, z), "radius": 5.0, "puffs": 3, "zone": ""})
	var stars := PackedVector3Array()
	for z in [-38.0, -44.0, -50.0, -56.0, -62.0]:
		stars.append(Vector3(POPLAR_GAP_X, POPLAR_GAP_Y + (1.0 if z == -38.0 else (0.5 if z == -44.0 else 0.0)), z))
	k.arcs.append({"name": "poplar gap", "stars": stars, "big": _no_big(5), "zone": "", "title": "Threaded!", "bonus": true, "from_entry": 2})
	if d >= 0.5:
		k.arcs.append({"name": "poplar big star", "stars": PackedVector3Array([Vector3(POPLAR_GAP_X, POPLAR_GAP_Y + 0.5, -70.0)]), "big": [true], "zone": "", "title": "", "bonus": false})
	k.line_points.append({"x": POPLAR_GAP_X, "z": -10.0, "dy": 0.0})
	k.line_points.append({"x": POPLAR_GAP_X, "z": -28.0, "dy": 0.0, "max": POPLAR_GAP_Y + 2.0})
	for p in stars:
		k.line_points.append({"at": p})
	k.line_points.append({"at": Vector3(POPLAR_GAP_X, POPLAR_GAP_Y + 1.0, -70.0)})
	k.line_points.append({"at": Vector3(POPLAR_GAP_X, 17.0, -96.0)})


## P10 Dutch Barn: a big open barn across the way. In one door and out the other (dark, fast, the
## hay and the lanterns going by), into the muck heap's warm air; or over its roof.
static func _barn(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var door := Vector2(lerpf(8.0, 6.5, d), lerpf(8.0, 6.5, d))
	_barn_shell(look, PackedVector3Array(), door, true)
	# The solid doorways are cut bigger by the rounding, which their round edges then take back.
	_barn_shell(look, solid, door + Vector2((HOLE_GRACE + DOOR_ROUND) * 2.0, HOLE_GRACE + DOOR_ROUND), false)
	_door_edges(look, solid, door, door + Vector2(HOLE_GRACE * 2.0, HOLE_GRACE))
	for side in [-1.0, 1.0]:  # hay bales stacked along the inside walls
		for i in 6:
			var z := BARN_Z.x - 2.5 - 3.0 * i
			for level in 2:
				_solid_box(look, solid, Vector3(side * (BARN_HALF - 1.1), 0.6 + 1.2 * level, z), Vector3(1.6, 1.15, 2.6), Color("e9c98a") if (i + level) % 2 == 0 else Color("f4dc9b"))
	for at in [Vector3(-3.5, 7.4, BARN_Z.x - 6.0), Vector3(3.5, 7.4, BARN_Z.y + 6.0)]:  # lanterns
		look.box(at, Vector3(0.35, 0.5, 0.35), Color("f6c66f"))
		_line(look, at + Vector3(0, 0.25, 0), at + Vector3(0, 1.2, 0), DARK, 0.04)
	var heap := Vector3(BARN_HEAP.x, grid_height(&"barn", BARN_HEAP.x, BARN_HEAP.y), BARN_HEAP.y)
	look.sphere(heap, 3.0, Color("9a7a5e"), Vector3(1.3, 0.35, 1.0), 8, 3)
	var radius := 10.0
	var top := lerpf(24.0, 22.0, d)
	k.zones.append({"name": "Heap", "shape": Thermal.Shape.CYLINDER, "at": heap, "radius": radius, "height": top - heap.y,
		"look": Thermal.Look.WARM_AIR, "strength": lerpf(0.8, 0.7, d), "pitch": 0.98, "drifts": true})
	k.clouds.append({"at": Vector3(heap.x, top + 4.0, heap.z), "radius": radius * 0.7, "puffs": 4, "zone": "Heap"})
	k.birds.append({"zone": "Heap", "below_top": 4.0})
	var through := lerpf(4.2, 3.6, d)
	var dive := PackedVector3Array()
	for i in 6:
		dive.append(Vector3(0.0, lerpf(15.0, through + 0.5, i / 5.0), lerpf(-12.0, BARN_Z.x + 6.0, i / 5.0)))  # into the door's middle
	k.arcs.append({"name": "barn dive", "stars": dive, "big": _no_big(6), "zone": "", "title": "Full arc!", "bonus": true, "from_entry": 5, "line": "low"})
	k.arcs.append({"name": "barn big star", "stars": PackedVector3Array([Vector3(0.0, through, (BARN_Z.x + BARN_Z.y) * 0.5)]), "big": [true], "zone": "", "title": "", "bonus": false, "line": "low"})
	_spiral(k, "heap spiral", "Heap", BARN_HEAP, 6.0, top, 6, d)
	var roof := PackedVector3Array()
	for z in [BARN_Z.x - 4.0, BARN_Z.x - 10.0, BARN_Z.x - 16.0]:
		roof.append(Vector3(0.0, BARN_ROOF + 3.5, z))
	k.arcs.append({"name": "barn roof", "stars": roof, "big": _no_big(3), "zone": "", "title": "Full arc!", "bonus": true, "line": "high"})
	k.line_points.append({"x": 0.0, "z": -6.0, "dy": 0.0, "max": 16.0})
	for i in dive.size() - 1:
		k.line_points.append({"x": 0.0, "z": dive[i].z, "dy": 0.0, "max": dive[i].y})
	for p in [dive[dive.size() - 1], Vector3(0.0, through, BARN_Z.x - 2.0), Vector3(0.0, through, BARN_Z.y + 2.0), Vector3(0.0, 5.0, BARN_HEAP.y + 6.0)]:
		k.line_points.append({"at": p})
	k.high_from = HIGH_FROM
	k.high_points.append({"x": 0.0, "z": -8.0, "dy": 0.0})
	for p in roof:
		k.high_points.append({"at": p})
	for points: Array[Dictionary] in [k.line_points, k.high_points]:
		points.append({"at": Vector3(0.0, top - 4.0, -96.0)})
	k.orbits.append({"centre": BARN_HEAP, "zone": "Heap", "radius": 6.0, "to_y": top - 2.0, "up": true, "max_time": 25.0})


## Round edges to both doorways (jambs and lintel), so a pass that clips one glances off it rather
## than meeting a square corner head-on (docs/endless-plan.md §3.4): solid cylinders standing just
## outside the opening `hole` (the doorway as it collides: never smaller than as drawn), and a cream
## frame drawn round the doorway `door`.
static func _door_edges(look: Art.Builder, solid: PackedVector3Array, door: Vector2, hole: Vector2) -> void:
	var t := 0.5  # wall thickness
	for zc in [BARN_Z.x - t * 0.5, BARN_Z.y + t * 0.5]:
		for side in [-1.0, 1.0]:
			var jamb := CylinderMesh.new()
			jamb.top_radius = DOOR_ROUND
			jamb.bottom_radius = DOOR_ROUND
			jamb.height = hole.y + DOOR_ROUND + 0.8
			jamb.radial_segments = 8
			jamb.rings = 0
			_mesh_faces(solid, jamb, Transform3D(Basis.IDENTITY, Vector3(side * (hole.x * 0.5 + DOOR_ROUND), (hole.y + DOOR_ROUND - 0.8) * 0.5, zc)))
			look.box(Vector3(side * (door.x * 0.5 + 0.12), door.y * 0.5, zc), Vector3(0.24, door.y, t + 0.1), CREAM)
		var lintel := CylinderMesh.new()
		lintel.top_radius = DOOR_ROUND
		lintel.bottom_radius = DOOR_ROUND
		lintel.height = hole.x + DOOR_ROUND * 2.0
		lintel.radial_segments = 8
		lintel.rings = 0
		_mesh_faces(solid, lintel, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, hole.y + DOOR_ROUND, zc)))
		look.box(Vector3(0.0, door.y + 0.12, zc), Vector3(door.x + 0.48, 0.24, t + 0.1), CREAM)


## The barn: side walls, a barrel roof, and gable ends with a doorway `door` (width, height)
## through each. Drawn into `look` (drawn true), or its faces collected into `solid`.
static func _barn_shell(look: Art.Builder, solid: PackedVector3Array, door: Vector2, drawn: bool) -> void:
	var boxes: Array[AABB] = []
	var t := 0.5  # wall thickness
	for side in [-1.0, 1.0]:
		var x0: float = BARN_HALF - t if side > 0.0 else -BARN_HALF
		boxes.append(AABB(Vector3(x0, -0.8, BARN_Z.y), Vector3(t, BARN_WALL + 0.8, BARN_Z.x - BARN_Z.y)))
	for zf in [BARN_Z.x - t, BARN_Z.y]:
		boxes.append(AABB(Vector3(-BARN_HALF, -0.8, zf), Vector3(BARN_HALF - door.x * 0.5, BARN_WALL + 0.8, t)))
		boxes.append(AABB(Vector3(door.x * 0.5, -0.8, zf), Vector3(BARN_HALF - door.x * 0.5, BARN_WALL + 0.8, t)))
		boxes.append(AABB(Vector3(-door.x * 0.5, door.y, zf), Vector3(door.x, BARN_WALL - door.y, t)))
	for b in boxes:
		if drawn:
			look.box(b.get_center(), b.size, BARN_RED)
		else:
			_box_faces(solid, b.get_center(), b.size)
	# The barrel roof, and the gables under it at both ends.
	var segments := 10
	var faces := PackedVector3Array()
	var roof := PackedVector3Array()
	var over := 0.5
	for i in segments:
		var a0 := PI * float(i) / segments
		var a1 := PI * float(i + 1) / segments
		var p0 := Vector2(-(BARN_HALF + 0.3) * cos(a0), BARN_WALL + (BARN_ROOF - BARN_WALL) * sin(a0))
		var p1 := Vector2(-(BARN_HALF + 0.3) * cos(a1), BARN_WALL + (BARN_ROOF - BARN_WALL) * sin(a1))
		roof.append_array([Vector3(p0.x, p0.y, BARN_Z.x + over), Vector3(p1.x, p1.y, BARN_Z.x + over), Vector3(p1.x, p1.y, BARN_Z.y - over),
			Vector3(p0.x, p0.y, BARN_Z.x + over), Vector3(p1.x, p1.y, BARN_Z.y - over), Vector3(p0.x, p0.y, BARN_Z.y - over)])
		for zf in [BARN_Z.x, BARN_Z.y]:
			faces.append_array([Vector3(p0.x, BARN_WALL, zf), Vector3(p0.x, p0.y, zf), Vector3(p1.x, p1.y, zf),
				Vector3(p0.x, BARN_WALL, zf), Vector3(p1.x, p1.y, zf), Vector3(p1.x, BARN_WALL, zf)])
	if drawn:
		for i in range(0, faces.size(), 3):
			look.triangle(faces[i], faces[i + 1], faces[i + 2], BARN_RED.lightened(0.06))
			look.triangle(faces[i], faces[i + 2], faces[i + 1], BARN_RED.lightened(0.06))
		for i in range(0, roof.size(), 3):
			look.triangle(roof[i], roof[i + 1], roof[i + 2], DARK)
			look.triangle(roof[i], roof[i + 2], roof[i + 1], DARK.darkened(0.2))
	else:
		solid.append_array(faces)
		solid.append_array(roof)


## P11 Standing Stones: a ring of old stones on the down. Fly in through one gap, over the big
## star in the middle, and out through the far side, to a thermal off the ring.
static func _stones(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var step := TAU / STONE_COUNT
	for i in STONE_COUNT:
		var a := step * (i + 0.5)  # gates at whole steps, from straight ahead (+z)
		var at := Vector2(STONE_CENTRE.x + sin(a) * STONE_RING, STONE_CENTRE.y + cos(a) * STONE_RING)
		var height := rng.randf_range(6.0, 8.0)
		var base := _lowest(&"stones", at, Vector3(2.0, 0.0, 2.0))
		var basis := Basis(Vector3.UP, a) * Basis(Vector3.BACK, rng.randf_range(-0.05, 0.05))
		_solid_box(look, solid, Vector3(at.x, base + height * 0.5 - 0.6, at.y), Vector3(STONE_SIZE.x, height + 1.2, STONE_SIZE.y),
			Color("b9b2aa") if i % 2 == 0 else Color("c9c2ba"), basis)
	var exit := _stones_exit()
	var thermal := STONE_CENTRE + exit * STONE_THERMAL_AT
	var floor_y := ground(&"stones", thermal.x, thermal.y)
	var radius := 9.0
	var top := lerpf(24.0, 22.0, d)
	k.zones.append({"name": "Down", "shape": Thermal.Shape.CYLINDER, "at": Vector3(thermal.x, floor_y, thermal.y), "radius": radius,
		"height": top - floor_y, "look": Thermal.Look.WARM_AIR, "strength": lerpf(0.85, 0.75, d), "pitch": 1.02, "drifts": true})
	k.clouds.append({"at": Vector3(thermal.x, top + 4.0, thermal.y), "radius": radius * 0.7, "puffs": 4, "zone": "Down"})
	k.birds.append({"zone": "Down", "below_top": 4.0})
	var into := PackedVector3Array()
	for i in 4:
		into.append(Vector3(0.0, lerpf(8.5, STONE_THROUGH + 0.5, i / 3.0), lerpf(-28.0, STONE_CENTRE.y + STONE_RING, i / 3.0)))
	var away := PackedVector3Array()
	for i in 4:
		var p := STONE_CENTRE + exit * (STONE_RING + 4.0 * i)
		away.append(Vector3(p.x, STONE_THROUGH + 0.5 * i, p.y))
	var stars := into.duplicate()
	stars.append(Vector3(STONE_CENTRE.x, STONE_THROUGH, STONE_CENTRE.y))
	stars.append_array(away)
	var big := _no_big(stars.size())
	big[4] = true
	k.arcs.append({"name": "stones", "stars": stars, "big": big, "zone": "", "title": "Through the stones!", "bonus": true, "from_entry": 4, "line": "low"})
	k.line_points.append({"x": 0.0, "z": -10.0, "dy": 0.0, "max": 9.5})
	for i in stars.size():
		if i == 5:  # lined up with the way out before reaching its gate
			var lined := STONE_CENTRE + exit * (STONE_RING - 4.0)
			k.line_points.append({"at": Vector3(lined.x, STONE_THROUGH, lined.y)})
		k.line_points.append({"at": stars[i]})
	# Entering high, over the stones (the tallest is 8) and down into the thermal beyond.
	k.high_from = HIGH_FROM
	k.high_points.append({"x": 0.0, "z": -10.0, "dy": 0.0})
	k.high_points.append({"x": 0.0, "z": STONE_CENTRE.y, "dy": -5.0, "max": 13.0})
	k.high_points.append({"at": Vector3(thermal.x, 9.0, thermal.y + 6.0)})
	for points: Array[Dictionary] in [k.line_points, k.high_points]:
		points.append({"at": Vector3(thermal.x * 0.5, top - 4.0, -96.0)})
	k.orbits.append({"centre": thermal, "zone": "Down", "radius": 5.5, "to_y": top - 2.0, "up": true, "max_time": 25.0})


## A spiral of `count` stars round zone `zone` (its home at `centre`), starting low on its near
## side at `start_y`: laid as the pilot starts circling (see EndlessStars._watch_spiral()).
static func _spiral(k: Kit, arc_name: String, zone: String, centre: Vector2, start_y: float, top: float, count: int, d: float) -> void:
	var stars := PackedVector3Array()
	var rise := lerpf(2.5, 2.0, d)
	for i in count:
		var a := PI * 0.5 + deg_to_rad(40.0) * i
		stars.append(Vector3(centre.x + 6.0 * cos(a), minf(start_y + rise * i, top - 2.5), centre.y + 6.0 * sin(a)))
	k.arcs.append({"name": arc_name, "stars": stars, "big": _no_big(count), "zone": zone, "title": "Full spiral!", "bonus": true,
		"spiral": {"radius": 6.0, "rise": 3.0, "step": 40.0, "top": top}})


## The way out of the stone ring (plan view, x and z), through the gate nearest straight ahead
## on the left (with an odd number of stones, straight across from a gate is a stone).
static func _stones_exit() -> Vector2:
	var a := PI + PI / STONE_COUNT
	return Vector2(sin(a), cos(a))


## P12 Mere: a lake across the floor whose cool air sinks under you, and an island with a
## warm-sand thermal to spiral up on; a sailboat goes round it.
static func _mere(k: Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	var water := PackedVector3Array()
	var c := Vector3(MERE_CENTRE.x, MERE_WATER, MERE_CENTRE.y)
	for i in 32:
		var a0 := TAU * i / 32.0
		var a1 := TAU * (i + 1) / 32.0
		var p0 := c + Vector3(cos(a0) * MERE_RADII.x * 1.04, 0.0, sin(a0) * MERE_RADII.y * 1.04)
		var p1 := c + Vector3(cos(a1) * MERE_RADII.x * 1.04, 0.0, sin(a1) * MERE_RADII.y * 1.04)
		look.triangle(c, p0, p1, WATER)  # facing up
		water.append_array([c, p0, p1])
	solid.append_array(water)  # the water is solid: touching it is a splashdown
	k.water = {"centre": MERE_CENTRE, "radii": MERE_RADII * 1.04, "y": MERE_WATER}
	for i in 14:  # reeds round the island's edge
		var a := TAU * i / 14.0 + 0.2
		var at := MERE_ISLAND + Vector2(cos(a), sin(a)) * (MERE_ISLAND_R - 0.5)
		look.cylinder(Vector3(at.x, grid_height(&"mere", at.x, at.y) - 0.2, at.y), 0.12, 0.04, 1.3, Color("8fb47e"), 4)
	k.zones.append({"name": "Lake", "shape": Thermal.Shape.BOX, "at": Vector3(MERE_CENTRE.x, MERE_WATER, MERE_CENTRE.y), "size": Vector3(MERE_RADII.x * 1.9, 27.0, MERE_RADII.y * 1.9),
		"look": Thermal.Look.LAKE, "strength": lerpf(MERE_SINK.x, MERE_SINK.y, d), "pitch": 1.0, "drifts": false})
	var floor_y := ground(&"mere", MERE_ISLAND.x, MERE_ISLAND.y)
	var radius := 10.0
	var top := 24.0
	k.zones.append({"name": "Island", "shape": Thermal.Shape.CYLINDER, "at": Vector3(MERE_ISLAND.x, floor_y, MERE_ISLAND.y), "radius": radius,
		"height": top - floor_y, "look": Thermal.Look.WARM_AIR, "strength": 0.8, "pitch": 1.04, "drifts": true})
	k.clouds.append({"at": Vector3(MERE_ISLAND.x, top + 4.0, MERE_ISLAND.y), "radius": radius * 0.7, "puffs": 4, "zone": "Island"})
	k.birds.append({"zone": "Island", "below_top": 4.0})
	k.movers.append({"kind": "sailboat", "centre": Vector3(MERE_ISLAND.x, MERE_WATER, MERE_ISLAND.y), "radius": 13.0, "speed": 1.2})
	var across := PackedVector3Array()
	for i in 7:
		across.append(Vector3(lerpf(0.0, MERE_ISLAND.x, i / 6.0), lerpf(15.0, 10.0, i / 6.0), lerpf(-22.0, MERE_ISLAND.y + 9.0, i / 6.0)))
	k.arcs.append({"name": "mere", "stars": across, "big": _no_big(7), "zone": "", "title": "Full arc!", "bonus": true, "from_entry": 6})
	var helix := PackedVector3Array()
	var rise := lerpf(2.5, 2.0, d)
	for i in 10:
		var a := PI * 0.5 + deg_to_rad(40.0) * i
		helix.append(Vector3(MERE_ISLAND.x + 6.0 * cos(a), minf(9.0 + rise * i, top - 2.5), MERE_ISLAND.y + 6.0 * sin(a)))
	k.arcs.append({"name": "island spiral", "stars": helix, "big": _no_big(10), "zone": "Island", "title": "Full spiral!", "bonus": true,
		"spiral": {"radius": 6.0, "rise": 3.0, "step": 40.0, "top": top}})
	k.line_points.append({"x": 0.0, "z": -10.0, "dy": 0.0, "max": 15.5})
	for p in across:
		k.line_points.append({"at": p})
	k.line_points.append({"at": Vector3(MERE_ISLAND.x, 9.0, MERE_ISLAND.y + 6.0)})
	k.orbits.append({"centre": MERE_ISLAND, "zone": "Island", "radius": 6.0, "to_y": top - 2.0, "up": true, "max_time": 25.0})
	k.line_points.append({"at": Vector3(MERE_ISLAND.x * 0.5, top - 4.0, -80.0)})
	k.line_points.append({"at": Vector3(0.0, top - 5.0, -96.0)})


## How far out into the Mere a point is (piece-local x, z): under 1 inside the water's edge.
static func mere_reach(x: float, z: float) -> float:
	return (Vector2(x - MERE_CENTRE.x, z - MERE_CENTRE.y) / MERE_RADII).length()


# --- The best-distance marker --------------------------------------------------------

## Bunting across the valley where your best run ended (docs/endless-plan.md §10.2): two tall
## poles beside the floor and a sagging line of pennants between them, at piece-local `z` on piece
## `id`. Looks only: flying through it does nothing but cheer.
static func best_marker(id: StringName, z: float) -> ArrayMesh:
	var b := Art.Builder.new()
	var colors: Array[Color] = [Color("e8604c"), Color("f6c66f"), Color("a9c8e8"), Color("9cc48a"), Color("b9a6dc")]
	var top := 24.0
	var sag := 4.0
	for side in [-1.0, 1.0]:
		var x: float = side * MARKER_HALF
		var foot := Vector3(x, grid_height(id, x, z) - 0.5, z)
		b.cylinder(foot, 0.25, 0.2, top - foot.y + 0.5, CREAM, 6)
		b.sphere(Vector3(x, top + 0.2, z), 0.4, Color("f6c66f"), Vector3.ONE, 6, 3)
	var n := 24
	var prev := Vector3(-MARKER_HALF, top, z)
	for i in range(1, n + 1):
		var t := float(i) / n
		var at := Vector3(lerpf(-MARKER_HALF, MARKER_HALF, t), top - sag * 4.0 * t * (1.0 - t), z)
		_line(b, prev, at, Color("f4efe6"), 0.08)
		var mid := (prev + at) * 0.5
		var color := colors[i % colors.size()]
		b.triangle(mid + Vector3(-0.7, 0.0, 0.0), mid + Vector3(0.7, 0.0, 0.0), mid + Vector3(0.0, -1.5, -0.15), color)
		b.triangle(mid + Vector3(0.7, 0.0, 0.0), mid + Vector3(-0.7, 0.0, 0.0), mid + Vector3(0.0, -1.5, -0.15), color.darkened(0.08))
		prev = at
	return b.commit()


# --- Small things ----------------------------------------------------------------------

static func _no_big(n: int) -> Array:
	var out := []
	out.resize(n)
	out.fill(false)
	return out


## The lowest ground under a footprint, so nothing floats above a slope.
static func _lowest(id: StringName, at: Vector2, size: Vector3) -> float:
	var low := INF
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		low = minf(low, grid_height(id, at.x + c.x * size.x * 0.5, at.y + c.y * size.z * 0.5))
	return low


## A ring kite: a torus facing along `axis`. It never collides; touching it snags, which the game
## checks.
static func _hoop_mesh(look: Art.Builder, centre: Vector3, axis: Vector3, radius: float, color: Color) -> void:
	var m := TorusMesh.new()
	m.inner_radius = radius
	m.outer_radius = radius + HOOP_TUBE * 2.0
	m.rings = 20
	m.ring_segments = 6
	var basis := Basis(Quaternion(Vector3.UP, axis.normalized()))  # the torus's hole looks along its local y
	look.add(m, Transform3D(basis, centre), color)


## A bow-tied ribbon tail hanging below a hoop, blowing a little downwind.
static func _ribbon(look: Art.Builder, top: Vector3, color: Color) -> void:
	var p := top
	for i in 6:
		var next := p + Vector3(0.15 * sin(i * 1.7), -0.55, -0.25)
		_line(look, p, next, color.lightened(0.2), 0.06)
		look.box(next, Vector3(0.35, 0.12, 0.12), color, Basis(Vector3.BACK, 0.4 * (1.0 if i % 2 == 0 else -1.0)))
		p = next


## A thin straight line (a string), drawn as a narrow box.
static func _line(look: Art.Builder, a: Vector3, b: Vector3, color: Color, width: float) -> void:
	var along := b - a
	if along.length() < 0.001:
		return
	var dir := along.normalized()
	var basis := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT)
	look.box((a + b) * 0.5, Vector3(width, width, along.length()), color, basis)


## A diamond kite on a long string from `anchor`.
static func _diamond_kite(look: Art.Builder, at: Vector3, anchor: Vector3, color: Color) -> void:
	var up := Vector3(0, 1.8, 0)
	var side := Vector3(0, 0, 1.2)
	look.triangle(at + up, at + side, at - up * 1.4, color)
	look.triangle(at + up, at - up * 1.4, at + side, color)
	look.triangle(at + up, at - up * 1.4, at - side, color.lightened(0.15))
	look.triangle(at + up, at - side, at - up * 1.4, color.lightened(0.15))
	_line(look, anchor, at - up * 1.4, Color("f4efe6"), 0.05)
	_ribbon(look, at - up * 1.4, color)
