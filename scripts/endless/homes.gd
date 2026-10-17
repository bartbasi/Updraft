# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessHomes
extends RefCounted
## Homes in the countryside (docs/hazards-plan.md §2): cottages, farmhouses and barns standing on
## the valley's side slopes now and then, and in some of them a kitten in the window behind open
## pink shutters (other windows' shutters are closed, sage or blue). Each piece's kit finds its
## home slots (slots()), always well clear of every line, lift and star; which slots have a home,
## of which kind, and which have a kitten and its coat, is a pure choice from the run's seed and
## the tile (plan()), apart from the generator, so homes change no piece and the daily flight's
## homes are the same for everyone.

const COTTAGE := "cottage"
const FARMHOUSE := "farmhouse"
const RED_BARN := "red_barn"
const STONE_BARN := "stone_barn"
## Footprint (x across its front, z deep), wall height, ridge height, and the kitten window's
## sill height (0: none).
const TYPES := {
	COTTAGE: {"size": Vector2(7.0, 9.0), "walls": 4.0, "ridge": 7.0, "sill": 2.9},
	FARMHOUSE: {"size": Vector2(9.0, 12.0), "walls": 6.5, "ridge": 10.0, "sill": 4.0},
	RED_BARN: {"size": Vector2(10.0, 16.0), "walls": 6.0, "ridge": 10.5, "sill": 5.5},
	STONE_BARN: {"size": Vector2(9.0, 14.0), "walls": 5.5, "ridge": 9.0, "sill": 0.0},
}
const SMALL: Array[String] = [COTTAGE, STONE_BARN]
const LARGE: Array[String] = [FARMHOUSE, RED_BARN]
const HOME_CHANCE := 0.25
const KITTEN_CHANCE := 0.3
const KITTEN_FROM_M := 40.0
const KITTEN_GAP_TILES := 5
const CLEAR_OF_LINE := 12.0
const CLEAR_OF_ZONE := 8.0
const CLEAR_OF_STAR := 4.0
## Pieces with no home slots: a village already, a fork's walls, the launch, the kitten's own farm.
const NO_SLOTS: Array[StringName] = [&"hamlet", &"rim", &"farmyard"]

static var _meshes := {}
static var _shapes := {}


## A piece's home slots: {at (x, z), side, yaw, large}: at most one each side, on the side slope
## where it is low enough, out of the joins, and clear of every line, lift and star.
static func slots(k: EndlessPieces.Kit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if k.id in NO_SLOTS or not k.fork.is_empty():
		return out
	var lines := k.all_lines(0.0)
	lines.append_array(k.all_lines(40.0))  # (low and high lines both)
	var length := EndlessPieces.length(k.id)
	for side in [-1.0, 1.0]:
		if k.id == &"ridge" and side < 0.0:
			continue  # the ridge itself
		var found := false
		var z := -length * 0.5
		var tries := 0
		while not found and tries < 14:
			var dz := (tries / 2 + 1) * 8.0 * (1.0 if tries % 2 == 0 else -1.0) if tries > 0 else 0.0
			tries += 1
			var zz := z + dz
			if zz > -20.0 or zz < -length + 12.0:
				continue
			for x: float in [40.0, 44.0, 48.0, 52.0]:
				var at := Vector2(side * x, zz)
				if EndlessPieces.ground(k.id, at.x, at.y) > 9.0:
					continue
				if _clear(k, lines, at):
					var large: bool = x <= 46.0
					out.append({"at": at, "side": side, "yaw": _yaw(side), "large": large})
					found = true
					break
	return out


## Facing the valley's middle, turned 30 degrees up the valley (so a window is seen three-quarters
## on from the approach).
static func _yaw(side: float) -> float:
	return -side * (PI * 0.5 - deg_to_rad(30.0))


static func _clear(k: EndlessPieces.Kit, lines: PackedVector3Array, at: Vector2) -> bool:
	for p in lines:
		if Vector2(p.x, p.z).distance_to(at) < CLEAR_OF_LINE:
			return false
	for i in lines.size() - 1:  # (and between the line's points)
		var a := Vector2(lines[i].x, lines[i].z)
		var b := Vector2(lines[i + 1].x, lines[i + 1].z)
		if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < CLEAR_OF_LINE:
			return false
	for zone in k.zones:
		var c: Vector3 = zone["at"]
		if zone["shape"] == Thermal.Shape.CYLINDER:
			if Vector2(c.x, c.z).distance_to(at) < float(zone["radius"]) + CLEAR_OF_ZONE:
				return false
		else:
			var size: Vector3 = zone["size"]
			if absf(at.x - c.x) < size.x * 0.5 + CLEAR_OF_ZONE and absf(at.y - c.z) < size.z * 0.5 + CLEAR_OF_ZONE:
				return false
	for arc in k.arcs:
		for s: Vector3 in arc["stars"]:
			if Vector2(s.x, s.z).distance_to(at) < CLEAR_OF_STAR + 8.0:
				return false
	return true


## Which of a piece's slots have homes: [{slot (index), type, palette, kitten (a coat or "")}],
## chosen from the run's seed and the tile only. `last_kitten_tile` is the tile of the last
## kitten placed before (placement order depends only on the seed); returns the plan and the new
## last kitten tile as {homes, last_kitten_tile}.
static func plan(run_seed: int, tile: int, piece_slots: Array[Dictionary], metres: float, last_kitten_tile: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, tile, "homes"])
	var homes: Array[Dictionary] = []
	for i in piece_slots.size():
		if rng.randf() >= HOME_CHANCE:
			continue
		var choices: Array[String] = LARGE if piece_slots[i]["large"] else SMALL
		var type: String = choices[rng.randi() % choices.size()]
		var home := {"slot": i, "type": type, "palette": rng.randi() % 2, "kitten": "", "seed": rng.randi()}
		var may := float(TYPES[type]["sill"]) > 0.0 and metres >= KITTEN_FROM_M and tile - last_kitten_tile >= KITTEN_GAP_TILES
		if may and rng.randf() < KITTEN_CHANCE:
			home["kitten"] = Kitten.COATS[rng.randi() % Kitten.COATS.size()]
			last_kitten_tile = tile
		homes.append(home)
	return {"homes": homes, "last_kitten_tile": last_kitten_tile}


## A home's node: its building (drawn and solid) on a plinth to the ground, at `slot`, with a
## kitten in its window if it has one (a Kitten node, returned in "kitten"; else null).
static func build(id: StringName, slot: Dictionary, home: Dictionary) -> Dictionary:
	var type: String = home["type"]
	var info: Dictionary = TYPES[type]
	var size: Vector2 = info["size"]
	var at: Vector2 = slot["at"]
	var node := Node3D.new()
	node.name = "Home"
	var basis := Basis(Vector3.UP, float(slot["yaw"]))
	var low := INF
	var high := -INF
	for cx in [-0.5, 0.5]:
		for cz in [-0.5, 0.5]:
			var off := basis * Vector3(cx * size.x, 0.0, cz * size.y)
			var c := at + Vector2(off.x, off.z)
			var g := EndlessPieces.ground(id, c.x, c.y)
			low = minf(low, g)
			high = maxf(high, g)
	node.position = Vector3(at.x, high, at.y)
	node.basis = basis
	var key := "%s:%d:%s" % [type, home["palette"], home["kitten"] != ""]
	if not _meshes.has(key):
		_build_type(type, int(home["palette"]), key, home["kitten"] != "")
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 400.0
	node.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = _shapes[key]
	body.add_child(cs)
	node.add_child(body)
	var plinth := high - low + 0.5  # down to the lowest corner, so it never floats
	var pb := Art.Builder.new()
	pb.box(Vector3(0.0, -plinth * 0.5, 0.0), Vector3(size.x + 0.4, plinth, size.y + 0.4), Color("d8cfc2"))
	var pm := MeshInstance3D.new()
	pm.mesh = pb.commit()
	pm.material_override = Art.material()
	pm.visibility_range_end = 400.0
	node.add_child(pm)
	var kitten: Kitten = null
	if home["kitten"] != "":
		kitten = Kitten.new(home["kitten"], int(home["seed"]))
		kitten.position = Vector3(0.0, float(info["sill"]), size.y * 0.5 + 0.8)  # in the front's window
		node.add_child(kitten)
	return {"node": node, "kitten": kitten}


## One kind of building, drawn and solid (its collision shared by every one of its kind).
static func _build_type(type: String, palette: int, key: String, kitten: bool) -> void:
	var info: Dictionary = TYPES[type]
	var size: Vector2 = info["size"]
	var walls: float = info["walls"]
	var ridge: float = info["ridge"]
	var b := Art.Builder.new()
	var wall_colors := {COTTAGE: [Color("f2e3d5"), Color("f4dc9b")], FARMHOUSE: [Color("f1d4cc"), Color("f2e3d5")],
		RED_BARN: [Color("c1675a"), Color("b85f52")], STONE_BARN: [Color("e9d7b6"), Color("dcc9a6")]}
	var roof_colors := {COTTAGE: [Color("c1675a"), Color("5f5b70")], FARMHOUSE: [Color("5f5b70"), Color("c1675a")],
		RED_BARN: [Color("6f6a78"), Color("8a8496")], STONE_BARN: [Color("5f5b70"), Color("6f6a78")]}
	var wall: Color = wall_colors[type][palette]
	var roof: Color = roof_colors[type][palette]
	var faces := PackedVector3Array()
	var solid_box := func(c: Vector3, s: Vector3, color: Color) -> void:
		b.box(c, s, color)
		for v in Art.box_triangles(s):
			faces.append(c + v)
	solid_box.call(Vector3(0.0, walls * 0.5, 0.0), Vector3(size.x, walls, size.y), wall)
	# The roof: a gable along z (a gambrel for the red barn), each slope a pair of triangles.
	var half := size.x * 0.5 + 0.4
	var deep := size.y * 0.5 + 0.4
	var profile: Array[Vector2] = [Vector2(-half, walls), Vector2(0.0, ridge), Vector2(half, walls)]
	if type == RED_BARN:
		profile = [Vector2(-half, walls), Vector2(-half * 0.55, walls + (ridge - walls) * 0.7), Vector2(0.0, ridge), Vector2(half * 0.55, walls + (ridge - walls) * 0.7), Vector2(half, walls)]
	for i in profile.size() - 1:
		var p0 := Vector3(profile[i].x, profile[i].y, deep)
		var p1 := Vector3(profile[i + 1].x, profile[i + 1].y, deep)
		var q0 := Vector3(profile[i].x, profile[i].y, -deep)
		var q1 := Vector3(profile[i + 1].x, profile[i + 1].y, -deep)
		for tri in [[p0, q0, q1], [p0, q1, p1], [p0, q1, q0], [p0, p1, q1]]:  # (both faces)
			b.triangle(tri[0], tri[1], tri[2], roof)
		faces.append_array([p0, q0, q1, p0, q1, p1])
	for end in [-1.0, 1.0]:  # the gable ends, wall-coloured
		for i in profile.size() - 2 + 1:
			var a := Vector3(profile[0].x + 0.4, walls, end * size.y * 0.5)
			var bb := Vector3(profile[i].x * 0.92, profile[i].y, end * size.y * 0.5)
			var c := Vector3(profile[i + 1].x * 0.92, profile[i + 1].y, end * size.y * 0.5)
			b.triangle(a, bb, c, wall)
			b.triangle(a, c, bb, wall)
	# Details: a chimney (homes), windows with closed shutters, a door (or the barn's big doors).
	if type in [COTTAGE, FARMHOUSE]:
		solid_box.call(Vector3(-size.x * 0.3, ridge * 0.95, -size.y * 0.35), Vector3(0.9, 2.2, 0.9), Color("b4674f"))
		for x in ([-1.8, 1.8] if type == COTTAGE else [-2.6, 2.6]):  # (the middle upstairs is the kitten's window)
			for row in ([1.6] if type == COTTAGE or kitten else [1.6, 4.3]):  # (upstairs, the kitten's shutters would hide them)
				b.box(Vector3(x, row, size.y * 0.5 + 0.05), Vector3(1.0, 1.1, 0.1), Color("6e8fa8"))
				var shutter := Color("a8c49a") if palette == 0 else Color("a9c8e8")
				b.box(Vector3(x - 0.75, row, size.y * 0.5 + 0.08), Vector3(0.45, 1.2, 0.08), shutter)
				b.box(Vector3(x + 0.75, row, size.y * 0.5 + 0.08), Vector3(0.45, 1.2, 0.08), shutter)
		b.box(Vector3(size.x * 0.32, 1.1, size.y * 0.5 + 0.05), Vector3(1.1, 2.2, 0.1), Color("8b6f5a"))
	elif type == RED_BARN:
		b.box(Vector3(0.0, 2.2, size.y * 0.5 + 0.05), Vector3(4.4, 4.4, 0.1), Color("a8534a"))
		for d in [-1.0, 1.0]:  # white cross-braces
			b.box(Vector3(0.0, 2.2, size.y * 0.5 + 0.1), Vector3(5.6, 0.25, 0.08), Color("fbf6ee"), Basis(Vector3.BACK, d * 0.78))
	else:
		b.box(Vector3(0.0, 1.8, size.y * 0.5 + 0.05), Vector3(3.4, 3.6, 0.1), Color("8b6f5a"))
	_meshes[key] = b.commit()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	_shapes[key] = shape
