@tool
class_name Course
extends Node3D
## Builds the demo course in code: a living room (launch shelf, radiator thermal, a low
## lamp to dive under), a kitchen (kettle-steam thermal) and an open window onto hills.
## Everything is low-poly and vertex-coloured, packed into two meshes.
##
## Units: 4 units = 1 real metre. The plane launches toward -Z along x = 0.

# --- Layout: the numbers that shape the flight --------------------------------
const CEILING := 12.0
const HALF_WIDTH := 9.0  ## Inner half-width of both rooms.
const BACK_Z := 14.0  ## Living-room back wall (inner face).
const SHELF_BACK := 10.0  ## The launch bookcase stands out from the wall, leaving room for the camera.
const DIVIDER_Z := -52.0  ## Centre of the wall between living room and kitchen.
const FAR_Z := -88.0  ## Kitchen far wall (inner face), with the open window.
const WALL := 1.0
const DOOR_HALF_WIDTH := 4.0
const DOOR_TOP := 7.0
const WINDOW_HALF_WIDTH := 4.5
const WINDOW_BOTTOM := 4.5
const WINDOW_TOP := 10.5
const SHELF_TOP := 9.0
const LAUNCH := Vector3(0.0, 9.6, 8.6)
const RADIATOR_THERMAL := Vector3(-5.0, 3.6, -22.0)
const LAMP := Vector3(0.0, 5.0, -45.0)  ## Bottom centre of the hanging lamp shade.
const KETTLE := Vector3(7.0, 3.7, -69.0)
const KETTLE_THERMAL := Vector3(3.0, 4.2, -69.0)  ## Steam drifts toward the room.

# --- Palette (sRGB pastels) ------------------------------------------------------
const LIVING_WALL := Color("f2e3d5")
const KITCHEN_WALL := Color("e3eedf")
const CEILING_COLOR := Color("f8f3ec")
const WOOD_A := Color("dcc3a6")
const WOOD_B := Color("d3b898")
const TILE_A := Color("f3eee4")
const TILE_B := Color("cfe0d8")
const TRIM := Color("fbf7f0")
const GLASS := Color("cfe6f5")
const SKY_PANE := Color("dcecf7")
const SHELF := Color("c9b2d6")
const BOOK_COLORS := ["f2b8a2", "a9c8e8", "f4dc9b", "b7d8b0", "e3b3cf", "9fb7d9", "f6cfa8"]
const GRASS := [Color("b9d79c"), Color("aed092"), Color("c6dfa8"), Color("a3c98f")]
const FLOWERS := [Color("f2c6d4"), Color("d5c6ea"), Color("f4e7a8")]

var _b: Art.Builder
var _body: StaticBody3D


func _ready() -> void:
	_build()


## Outdoors starts just beyond the window wall.
static func is_outside(pos: Vector3) -> bool:
	return pos.z < FAR_Z - WALL


## Rolling hills that climb away from the house and up to both sides, so every
## flight outside ends on the grass within a few seconds.
static func ground_height(x: float, z: float) -> float:
	var d := maxf(0.0, FAR_Z - WALL - z)
	var rise := d * 0.085 + x * x * 0.004
	var rolls := (1.4 * sin(x * 0.09 + z * 0.045) + 1.0 * sin(x * 0.05 - z * 0.08 + 1.3)) * clampf(d / 25.0, 0.0, 1.0)
	return -1.2 + rise + rolls


func _build() -> void:
	for child in get_children():
		child.free()
	_body = StaticBody3D.new()
	_body.name = "Collision"
	add_child(_body)

	_b = Art.Builder.new()
	_build_shell()
	_build_living_room()
	_build_dining_corner()
	_build_kitchen()
	_build_window()
	_add_mesh("House")

	_b = Art.Builder.new()
	_build_outside()
	_add_mesh("Outside")

	_add_thermal("RadiatorHeat", RADIATOR_THERMAL, 3.6, 7.6, Thermal.Look.WARM_AIR, 1.0, Vector3.ZERO)
	_add_thermal("KettleSteam", KETTLE_THERMAL, 3.4, 7.0, Thermal.Look.STEAM, 1.26, Vector3(2.55, 0.45, 0.0))


func _add_mesh(mesh_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = _b.commit()
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if not _b.faces.is_empty():
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(_b.faces)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		_body.add_child(cs)


func _add_thermal(thermal_name: String, at: Vector3, radius: float, height: float, look: Thermal.Look, pitch: float, source: Vector3) -> void:
	var t := Thermal.new()
	t.name = thermal_name
	t.radius = radius
	t.height = height
	t.look = look
	t.chime_pitch = pitch
	t.source_offset = source
	t.position = at
	add_child(t)


# --- Shape helpers: draw into the current mesh, optionally with collision ---------

func _box(center: Vector3, size: Vector3, color: Color, solid := true, basis := Basis.IDENTITY) -> void:
	_b.box(center, size, color, basis)
	if solid:
		_solid_box(center, size, basis)


## Box between two opposite corners.
func _span(a: Vector3, b: Vector3, color: Color, solid := true) -> void:
	_box((a + b) * 0.5, (b - a).abs(), color, solid)


## Invisible collision box between two opposite corners.
func _solid_span(a: Vector3, b: Vector3) -> void:
	_solid_box((a + b) * 0.5, (b - a).abs())


func _solid_box(center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_collider(shape, Transform3D(basis, center))


func _cylinder(base: Vector3, r_bottom: float, r_top: float, height: float, color: Color, solid := true, segments := 10) -> void:
	_b.cylinder(base, r_bottom, r_top, height, color, segments)
	if solid:
		var shape := CylinderShape3D.new()
		shape.radius = maxf(r_bottom, r_top)
		shape.height = height
		_collider(shape, Transform3D(Basis.IDENTITY, base + Vector3(0.0, height * 0.5, 0.0)))


func _sphere(center: Vector3, radius: float, color: Color, solid := true, stretch := Vector3.ONE) -> void:
	_b.sphere(center, radius, color, stretch)
	if solid:
		var shape := SphereShape3D.new()
		shape.radius = radius * minf(stretch.x, minf(stretch.y, stretch.z))
		_collider(shape, Transform3D(Basis.IDENTITY, center))


func _collider(shape: Shape3D, xform: Transform3D) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.transform = xform
	_body.add_child(cs)


# --- The house --------------------------------------------------------------------

func _build_shell() -> void:
	var w := HALF_WIDTH
	var living_end := DIVIDER_Z + WALL * 0.5
	var kitchen_start := DIVIDER_Z - WALL * 0.5
	# Foundation, plank and tile floors (drawn piece by piece, collided as one), ceiling.
	_span(Vector3(-w - WALL, -3.0, BACK_Z + WALL), Vector3(w + WALL, -0.5, FAR_Z - WALL), Color("d9cfc4"), false)
	for i in range(int(2 * w)):
		var x := -w + i
		_span(Vector3(x, -0.5, BACK_Z), Vector3(x + 1, 0.0, living_end), WOOD_A if i % 2 == 0 else WOOD_B, false)
	for ix in 6:
		for iz in 12:
			var x0 := -w + ix * 3.0
			var z0 := kitchen_start - iz * 3.0
			_span(Vector3(x0, -0.5, z0), Vector3(x0 + 3.0, 0.0, maxf(z0 - 3.0, FAR_Z)), TILE_A if (ix + iz) % 2 == 0 else TILE_B, false)
	_solid_span(Vector3(-w - WALL, -3.0, BACK_Z + WALL), Vector3(w + WALL, 0.0, FAR_Z - WALL))
	_span(Vector3(-w - WALL, CEILING, BACK_Z + WALL), Vector3(w + WALL, CEILING + 0.5, FAR_Z - WALL), CEILING_COLOR)

	# Outer walls.
	_span(Vector3(-w - WALL, 0, BACK_Z), Vector3(-w, CEILING, DIVIDER_Z), LIVING_WALL)
	_span(Vector3(w, 0, BACK_Z), Vector3(w + WALL, CEILING, DIVIDER_Z), LIVING_WALL)
	_span(Vector3(-w - WALL, 0, DIVIDER_Z), Vector3(-w, CEILING, FAR_Z), KITCHEN_WALL)
	_span(Vector3(w, 0, DIVIDER_Z), Vector3(w + WALL, CEILING, FAR_Z), KITCHEN_WALL)
	_span(Vector3(-w - WALL, 0, BACK_Z), Vector3(w + WALL, CEILING, BACK_Z + WALL), LIVING_WALL)

	# Divider wall with a wide doorway, painted to match each room.
	var dw := DOOR_HALF_WIDTH
	for half in [[DIVIDER_Z, living_end, LIVING_WALL], [kitchen_start, DIVIDER_Z, KITCHEN_WALL]]:
		var za: float = half[0]
		var zb: float = half[1]
		var color: Color = half[2]
		_span(Vector3(-w, 0, za), Vector3(-dw, CEILING, zb), color)
		_span(Vector3(dw, 0, za), Vector3(w, CEILING, zb), color)
		_span(Vector3(-dw, DOOR_TOP, za), Vector3(dw, CEILING, zb), color)
	var t0 := living_end + 0.1
	var t1 := kitchen_start - 0.1
	_span(Vector3(-dw - 0.3, 0, t0), Vector3(-dw + 0.03, DOOR_TOP + 0.3, t1), TRIM, false)
	_span(Vector3(dw - 0.03, 0, t0), Vector3(dw + 0.3, DOOR_TOP + 0.3, t1), TRIM, false)
	_span(Vector3(-dw - 0.3, DOOR_TOP - 0.03, t0), Vector3(dw + 0.3, DOOR_TOP + 0.3, t1), TRIM, false)

	# Far wall around the open window.
	var ww := WINDOW_HALF_WIDTH
	_span(Vector3(-w - WALL, 0, FAR_Z), Vector3(-ww, CEILING, FAR_Z - WALL), KITCHEN_WALL)
	_span(Vector3(ww, 0, FAR_Z), Vector3(w + WALL, CEILING, FAR_Z - WALL), KITCHEN_WALL)
	_span(Vector3(-ww, 0, FAR_Z), Vector3(ww, WINDOW_BOTTOM, FAR_Z - WALL), KITCHEN_WALL)
	_span(Vector3(-ww, WINDOW_TOP, FAR_Z), Vector3(ww, CEILING, FAR_Z - WALL), KITCHEN_WALL)

	# Baseboards in the living room.
	_span(Vector3(-w, 0, BACK_Z), Vector3(-w + 0.15, 0.6, living_end), Color("e6d2c0"), false)
	_span(Vector3(w - 0.15, 0, BACK_Z), Vector3(w, 0.6, living_end), Color("e6d2c0"), false)


func _build_living_room() -> void:
	var w := HALF_WIDTH
	# Tall freestanding bookcase: the launch shelf. Solid as one block.
	var front := SHELF_BACK - 2.2
	_solid_span(Vector3(-3.2, 0, front), Vector3(3.2, SHELF_TOP, SHELF_BACK))
	_span(Vector3(-3.2, 0, SHELF_BACK - 0.3), Vector3(3.2, SHELF_TOP, SHELF_BACK), Color("b7a0c6"), false)
	_span(Vector3(-3.2, 0, front), Vector3(-2.9, SHELF_TOP, SHELF_BACK - 0.3), SHELF, false)
	_span(Vector3(2.9, 0, front), Vector3(3.2, SHELF_TOP, SHELF_BACK - 0.3), SHELF, false)
	_span(Vector3(-3.2, SHELF_TOP - 0.3, front), Vector3(3.2, SHELF_TOP, SHELF_BACK - 0.3), SHELF, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for shelf in 4:
		var y := 0.3 + shelf * 2.15
		_span(Vector3(-2.9, y - 0.25, front), Vector3(2.9, y, SHELF_BACK - 0.3), SHELF, false)
		var x := -2.75
		while x < 2.5:
			var bw := rng.randf_range(0.25, 0.5)
			var bh := rng.randf_range(1.1, 1.75)
			var color := Color(BOOK_COLORS[rng.randi() % BOOK_COLORS.size()])
			_box(Vector3(x + bw * 0.5, y + bh * 0.5, front + 0.9), Vector3(bw * 0.9, bh, 1.4), color, false)
			x += bw + rng.randf_range(0.0, 0.12)
	# A potted plant and a few books on top of the bookcase.
	_cylinder(Vector3(-2.6, SHELF_TOP, front + 0.7), 0.3, 0.4, 0.55, Color("e2a888"), false)
	_sphere(Vector3(-2.6, SHELF_TOP + 0.95, front + 0.7), 0.5, Color("9cc48a"), false)
	_box(Vector3(2.4, SHELF_TOP + 0.12, front + 0.8), Vector3(1.0, 0.24, 0.8), Color("f2b8a2"), false)
	_box(Vector3(2.4, SHELF_TOP + 0.33, front + 0.8), Vector3(0.85, 0.18, 0.7), Color("a9c8e8"), false)

	# Radiator under a side window: the first thermal.
	var rz0 := RADIATOR_THERMAL.z - 4.0
	var rz1 := RADIATOR_THERMAL.z + 4.0
	_span(Vector3(-w, 0.5, rz0), Vector3(-w + 0.9, 3.5, rz1), Color("f6efe9"))
	var z := rz0 + 0.3
	while z < rz1 - 0.2:
		_span(Vector3(-w + 0.85, 0.7, z), Vector3(-w + 1.05, 3.3, z + 0.35), Color("efe4dc"), false)
		z += 0.6
	for fz in [rz0 + 0.4, rz1 - 0.4]:
		_span(Vector3(-w + 0.2, 0.0, fz - 0.2), Vector3(-w + 0.7, 0.5, fz + 0.2), Color("e6d9cf"), false)
	_wall_window(-w, 5.0, 10.2, rz0 - 0.5, rz1 + 0.5)
	_span(Vector3(-w, 4.6, rz1 + 0.6), Vector3(-w + 0.4, 10.8, rz1 + 2.0), Color("f4c7c3"), false)
	_span(Vector3(-w, 4.6, rz0 - 2.0), Vector3(-w + 0.4, 10.8, rz0 - 0.6), Color("f4c7c3"), false)

	# Rug, sofa, coffee table and armchair.
	_span(Vector3(-5.5, 0.0, -14.0), Vector3(5.5, 0.06, -32.0), Color("e7b9b5"), false)
	_span(Vector3(-4.8, 0.0, -14.7), Vector3(4.8, 0.08, -31.3), Color("eccac4"), false)
	var sofa := Color("a9c4e2")
	_span(Vector3(4.6, 0.0, -16.0), Vector3(w, 1.8, -30.0), sofa)
	_span(Vector3(7.6, 1.8, -16.0), Vector3(w, 4.2, -30.0), sofa)
	_span(Vector3(4.6, 1.8, -16.0), Vector3(7.6, 2.8, -17.0), sofa)
	_span(Vector3(4.6, 1.8, -29.0), Vector3(7.6, 2.8, -30.0), sofa)
	for cz in [-17.2, -21.4, -25.6]:
		_span(Vector3(4.8, 1.8, cz), Vector3(7.5, 2.35, cz - 3.8), Color("bcd3ec"), false)
		_span(Vector3(7.0, 2.2, cz - 0.3), Vector3(7.6, 3.9, cz - 3.5), Color("c8dbef"), false)
	_span(Vector3(-0.5, 1.3, -19.5), Vector3(3.0, 1.6, -26.5), Color("d8b896"))
	for leg in [Vector3(-0.3, 0, -19.7), Vector3(2.55, 0, -19.7), Vector3(-0.3, 0, -26.05), Vector3(2.55, 0, -26.05)]:
		_span(leg, leg + Vector3(0.25, 1.3, -0.25), Color("c9a684"), false)
	_cylinder(Vector3(1.0, 1.6, -22.0), 0.35, 0.3, 0.7, Color("a9c8e8"), false)
	_sphere(Vector3(1.0, 2.6, -22.0), 0.45, Color("f2c6d4"), false)
	var chair := Color("f2d79b")
	_span(Vector3(-w, 0.0, -2.0), Vector3(-5.0, 1.9, -6.5), chair)
	_span(Vector3(-w, 1.9, -2.0), Vector3(-7.9, 4.6, -6.5), chair)
	_span(Vector3(-7.9, 1.9, -2.0), Vector3(-5.0, 3.0, -2.8), chair)
	_span(Vector3(-7.9, 1.9, -5.7), Vector3(-5.0, 3.0, -6.5), chair)
	# Floor lamp and a corner plant.
	_cylinder(Vector3(-7.5, 0.0, -9.0), 0.6, 0.6, 0.2, Color("b9a28f"), false)
	_cylinder(Vector3(-7.5, 0.2, -9.0), 0.08, 0.08, 5.8, Color("b9a28f"))
	_cylinder(Vector3(-7.5, 6.0, -9.0), 1.1, 0.6, 1.3, Color("fbe3c2"))
	_cylinder(Vector3(7.0, 0.0, 6.5), 0.8, 1.0, 1.8, Color("e2a888"))
	_sphere(Vector3(7.0, 3.0, 6.5), 1.3, Color("9cc48a"), true, Vector3(1.0, 1.25, 1.0))
	_sphere(Vector3(6.4, 4.2, 6.9), 0.8, Color("b3d39b"), false)
	# Pictures on the walls and a clock over the doorway.
	_picture(Vector3(w, 7.5, -8.0), -1.0, Color("f4dc9b"), Color("a9c8e8"))
	_picture(Vector3(w, 7.0, -40.0), -1.0, Color("e3b3cf"), Color("b7d8b0"))
	_picture(Vector3(-w, 7.0, -40.0), 1.0, Color("a9c8e8"), Color("f6cfa8"))
	var clock_z := DIVIDER_Z + WALL * 0.5
	var face_forward := Basis(Vector3.RIGHT, PI / 2.0)
	_b.cylinder(Vector3(0.0, 9.6, clock_z), 1.0, 1.0, 0.15, Color("d9a5a6"), 16, face_forward)
	_b.cylinder(Vector3(0.0, 9.6, clock_z + 0.15), 0.85, 0.85, 0.05, TRIM, 16, face_forward)
	_box(Vector3(0.0, 9.9, clock_z + 0.24), Vector3(0.08, 0.6, 0.04), Color("6f6478"), false)
	_box(Vector3(0.2, 9.6, clock_z + 0.24), Vector3(0.45, 0.07, 0.04), Color("6f6478"), false)


## Dining table and chairs under a low hanging lamp, just before the doorway: the dive.
func _build_dining_corner() -> void:
	var w := HALF_WIDTH
	_span(Vector3(-3.0, 2.8, -42.0), Vector3(3.0, 3.1, -48.0), Color("c8a283"))
	for leg in [Vector3(-2.7, 0, -42.3), Vector3(2.45, 0, -42.3), Vector3(-2.7, 0, -47.45), Vector3(2.45, 0, -47.45)]:
		_span(leg, leg + Vector3(0.25, 2.8, -0.25), Color("b8916f"))
	for side in [-1.0, 1.0]:
		for cz in [-43.5, -46.5]:
			var seat := Vector3(4.4 * side, 1.8, cz)
			_box(seat, Vector3(1.6, 0.25, 1.6), Color("e9c6a0"))
			_box(seat + Vector3(0.75 * side, 1.3, 0.0), Vector3(0.2, 2.6, 1.6), Color("e9c6a0"))
			for lx in [-0.6, 0.6]:
				for lz in [-0.6, 0.6]:
					_box(Vector3(seat.x + lx, 0.9, cz + lz), Vector3(0.15, 1.8, 0.15), Color("d9b48f"), false)
	_cylinder(LAMP, 2.0, 0.7, 1.6, Color("f6c9b8"), true, 14)
	_cylinder(LAMP + Vector3(0, 1.6, 0), 0.7, 0.3, 0.4, Color("f6c9b8"), false, 14)
	_cylinder(LAMP + Vector3(0, 2.0, 0), 0.05, 0.05, CEILING - LAMP.y - 2.0, Color("9b8fa6"), false, 6)
	_sphere(LAMP + Vector3(0, 0.3, 0), 0.45, Color("fff4d6"), false)
	# A sideboard with a vase on the left wall.
	_span(Vector3(-w, 0.0, -38.0), Vector3(-7.4, 3.4, -48.0), Color("cfe0d8"))
	_cylinder(Vector3(-8.2, 3.4, -41.0), 0.4, 0.25, 1.4, Color("f4dc9b"), false)
	_sphere(Vector3(-8.2, 5.1, -41.0), 0.5, Color("f2b8a2"), false)


func _build_kitchen() -> void:
	var w := HALF_WIDTH
	var counter := Color("b9d8cb")
	var top := Color("f5f0e6")
	var ink := Color("6f6478")
	# Counters along the right wall, with the stove and kettle: the second thermal.
	_span(Vector3(5.4, 0.0, -55.0), Vector3(w, 3.4, -85.4), counter)
	_span(Vector3(5.3, 3.4, -55.0), Vector3(w, 3.7, -85.4), top)
	var dz := -55.4
	while dz > -85.0:
		_span(Vector3(5.36, 0.4, dz), Vector3(5.4, 3.1, dz - 2.8), Color("a8cbbd"), false)
		dz -= 3.2
	_span(Vector3(5.6, 3.7, KETTLE.z + 3.0), Vector3(8.8, 3.75, KETTLE.z - 3.0), Color("8f8aa0"), false)
	for bz in [KETTLE.z + 1.5, KETTLE.z - 1.5]:
		_cylinder(Vector3(6.6, 3.75, bz), 0.6, 0.6, 0.04, ink, false, 12)
	_cylinder(KETTLE, 0.85, 0.65, 1.2, Color("f19e8f"), true, 12)
	_cylinder(KETTLE + Vector3(0, 1.2, 0), 0.5, 0.2, 0.3, Color("f19e8f"), false, 12)
	_sphere(KETTLE + Vector3(0, 1.6, 0), 0.15, ink, false)
	_box(KETTLE + Vector3(0.0, 1.55, 0.0), Vector3(0.12, 0.12, 1.3), ink, false)
	_b.cylinder(KETTLE + Vector3(-0.7, 0.45, 0), 0.18, 0.1, 0.9, Color("f19e8f"), 8, Basis(Vector3.BACK, PI * 0.32))
	# Upper cabinets, leaving the stove clear for the steam.
	_span(Vector3(7.2, 7.6, -55.0), Vector3(w, 11.4, -62.0), Color("c7e0d6"))
	_span(Vector3(7.2, 7.6, -76.0), Vector3(w, 11.4, -85.4), Color("c7e0d6"))
	# Counter under the window, with a sink and herbs.
	_span(Vector3(-w, 0.0, -85.4), Vector3(5.4, 3.4, FAR_Z), counter)
	_span(Vector3(-w, 3.4, -85.4), Vector3(w, 3.7, FAR_Z), top)
	_span(Vector3(-2.0, 3.7, -85.8), Vector3(2.0, 3.73, -87.6), Color("c4d3dc"), false)
	for hx in [-3.6, 3.6]:
		_cylinder(Vector3(hx, 3.7, -86.7), 0.35, 0.45, 0.6, Color("e2a888"), false)
		_sphere(Vector3(hx, 4.6, -86.7), 0.5, Color("9cc48a"), false)
	# Fridge, a small round table and stools.
	_span(Vector3(-w, 0.0, -53.0), Vector3(-5.8, 8.6, -59.0), Color("c9e2ea"))
	_span(Vector3(-5.8, 3.6, -53.6), Vector3(-5.65, 6.4, -53.9), TRIM, false)
	_span(Vector3(-5.8, 5.0, -53.0), Vector3(-5.78, 5.05, -59.0), Color("b5d2dc"), false)
	_cylinder(Vector3(-4.8, 0.0, -73.0), 1.0, 0.3, 0.3, Color("d9b48f"))
	_cylinder(Vector3(-4.8, 0.3, -73.0), 0.2, 0.2, 2.5, Color("d9b48f"))
	_cylinder(Vector3(-4.8, 2.8, -73.0), 2.0, 2.0, 0.25, Color("e9c6a0"), true, 16)
	_cylinder(Vector3(-4.8, 3.05, -73.0), 0.7, 0.9, 0.35, Color("a9c8e8"), false, 12)
	for fruit in [Vector3(-5.0, 3.55, -72.8), Vector3(-4.5, 3.55, -73.2), Vector3(-4.8, 3.75, -73.0)]:
		_sphere(fruit, 0.28, Color("f6cfa8"), false)
	for sz in [-69.8, -76.2]:
		_cylinder(Vector3(-4.8, 0.0, sz), 0.6, 0.6, 1.9, Color("f4dc9b"), true, 10)


## The open window: frame, sill, curtains, and two sashes swung wide outside.
func _build_window() -> void:
	var ww := WINDOW_HALF_WIDTH
	var inner := FAR_Z + 0.1
	var outer := FAR_Z - WALL - 0.1
	_span(Vector3(-ww - 0.3, WINDOW_BOTTOM - 0.3, FAR_Z + 0.4), Vector3(ww + 0.3, WINDOW_BOTTOM + 0.05, outer - 0.1), TRIM)
	_span(Vector3(-ww - 0.3, WINDOW_TOP - 0.03, inner), Vector3(ww + 0.3, WINDOW_TOP + 0.3, outer), TRIM, false)
	_span(Vector3(-ww - 0.3, WINDOW_BOTTOM, inner), Vector3(-ww + 0.03, WINDOW_TOP, outer), TRIM, false)
	_span(Vector3(ww - 0.03, WINDOW_BOTTOM, inner), Vector3(ww + 0.3, WINDOW_TOP, outer), TRIM, false)
	var height := WINDOW_TOP - WINDOW_BOTTOM
	for side in [-1.0, 1.0]:
		_span(Vector3(side * (ww + 0.25), 4.0, FAR_Z + 0.6), Vector3(side * (ww + 2.0), 11.6, FAR_Z + 0.2), Color("f4c7c3"), false)
		var hinge := Vector3(side * ww, WINDOW_BOTTOM + height * 0.5, FAR_Z - WALL)
		var sash := Basis(Vector3.UP, -side * deg_to_rad(115.0))
		var mid := hinge + sash * Vector3(-side * ww * 0.5, 0.0, 0.0)
		_box(mid, Vector3(ww, height, 0.2), TRIM, true, sash)
		_box(mid + sash * Vector3(0, 0, 0.06), Vector3(ww - 0.5, height - 0.5, 0.12), GLASS, false, sash)
		_box(mid + sash * Vector3(0, 0, -0.06), Vector3(ww - 0.5, height - 0.5, 0.12), GLASS, false, sash)
	_span(Vector3(-ww - 2.2, 11.7, FAR_Z + 0.5), Vector3(ww + 2.2, 11.85, FAR_Z + 0.3), Color("b9a28f"), false)


## A bright window painted on the left wall (facing +X), with frame and cross bars.
func _wall_window(x: float, y0: float, y1: float, z0: float, z1: float) -> void:
	_span(Vector3(x, y0, z0), Vector3(x + 0.08, y1, z1), TRIM, false)
	_span(Vector3(x + 0.08, y0 + 0.3, z0 + 0.3), Vector3(x + 0.1, y1 - 0.3, z1 - 0.3), SKY_PANE, false)
	var mz := (z0 + z1) * 0.5
	var my := (y0 + y1) * 0.5
	_span(Vector3(x + 0.1, y0 + 0.3, mz - 0.1), Vector3(x + 0.14, y1 - 0.3, mz + 0.1), TRIM, false)
	_span(Vector3(x + 0.1, my - 0.1, z0 + 0.3), Vector3(x + 0.14, my + 0.1, z1 - 0.3), TRIM, false)


## A framed picture on a side wall. `facing` is +1 on the left wall, -1 on the right wall.
func _picture(wall_point: Vector3, facing: float, sky: Color, land: Color) -> void:
	var at := wall_point + Vector3(facing * 0.1, 0, 0)
	_box(at, Vector3(0.2, 3.0, 4.0), Color("b9a28f"), false)
	var face := at + Vector3(facing * 0.11, 0, 0)
	_box(face + Vector3(0, 0.5, 0), Vector3(0.02, 1.0, 3.4), sky, false)
	_box(face + Vector3(0, -0.6, 0), Vector3(0.02, 1.2, 3.4), land, false)
	_box(face + Vector3(facing * 0.01, 0.55, 0.9), Vector3(0.02, 0.4, 0.4), Color("fbf3d6"), false)


# --- Outside ------------------------------------------------------------------------

func _build_outside() -> void:
	# Terrain: a gently rising valley of pastel grass.
	var step := 6.0
	var x0 := -126.0
	var z0 := -30.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for ix in 42:
		for iz in 52:
			var xa := x0 + ix * step
			var xb := xa + step
			var za := z0 - iz * step
			var zb := za - step
			var p00 := Vector3(xa, ground_height(xa, za), za)
			var p10 := Vector3(xb, ground_height(xb, za), za)
			var p01 := Vector3(xa, ground_height(xa, zb), zb)
			var p11 := Vector3(xb, ground_height(xb, zb), zb)
			_b.triangle(p00, p01, p10, _grass(rng), true)
			_b.triangle(p10, p01, p11, _grass(rng), true)

	# A low garden fence across the view.
	var fence_z := -101.0
	var x := -40.0
	while x <= 40.0:
		var gy := ground_height(x, fence_z)
		_box(Vector3(x, gy + 1.0, fence_z), Vector3(0.35, 2.6, 0.35), TRIM)
		if x < 40.0:
			var mid_y := (gy + ground_height(x + 2.5, fence_z)) * 0.5
			for rail in [0.9, 1.8]:
				_b.box(Vector3(x + 1.25, mid_y + rail, fence_z), Vector3(2.5, 0.2, 0.15), Color("f3ece2"))
		x += 2.5

	# Trees on the slopes, kept clear of the flight path near the window.
	var trng := RandomNumberGenerator.new()
	trng.seed = 21
	var placed := 0
	while placed < 26:
		var tx := trng.randf_range(-90.0, 90.0)
		var tz := trng.randf_range(-105.0, -300.0)
		if absf(tx) < 16.0 and tz > -170.0:
			continue
		_tree(Vector3(tx, ground_height(tx, tz), tz), trng)
		placed += 1

	# Far hills and clouds (no collision), softened by the fog.
	var hills := [[-220.0, -380.0, 90.0, Color("a9c9a4")], [-60.0, -430.0, 120.0, Color("b5cfb0")], [120.0, -400.0, 100.0, Color("a7c4b8")],
		[260.0, -360.0, 80.0, Color("b9d3c2")], [10.0, -520.0, 160.0, Color("bcd2dc")], [-330.0, -300.0, 70.0, Color("b3cdb6")]]
	for h in hills:
		_b.sphere(Vector3(h[0], -12.0, h[1]), h[2], h[3], Vector3(1.6, 0.42, 1.0), 14, 7)
	for c in [Vector3(-80, 70, -320), Vector3(40, 85, -420), Vector3(170, 65, -300), Vector3(-200, 90, -450)]:
		for i in 3:
			_b.sphere(c + Vector3(i * 14.0 - 14.0, (i % 2) * 4.0, 0.0), 13.0 - (i % 2) * 3.0, Color("fdfbf8"), Vector3(1.4, 0.55, 1.0), 10, 5)


func _grass(rng: RandomNumberGenerator) -> Color:
	if rng.randf() < 0.025:
		return FLOWERS[rng.randi() % FLOWERS.size()]
	return GRASS[rng.randi() % GRASS.size()]


func _tree(base: Vector3, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.8, 1.4)
	_cylinder(base - Vector3(0, 0.5, 0), 0.45 * s, 0.35 * s, 4.0 * s, Color("a88b74"), true, 7)
	if rng.randf() < 0.5:
		_cylinder(base + Vector3(0, 2.5 * s, 0), 2.6 * s, 0.0, 7.0 * s, Color("8fbf9a"), true, 8)
	else:
		var leaf := Color("9cc48a") if rng.randf() < 0.5 else Color("b3d39b")
		_sphere(base + Vector3(0, 5.2 * s, 0), 2.6 * s, leaf, true, Vector3(1.0, 0.9, 1.0))
		_sphere(base + Vector3(1.2 * s, 4.4 * s, 0.6 * s), 1.6 * s, leaf.lightened(0.08), false)
