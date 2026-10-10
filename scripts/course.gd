@tool
class_name Course
extends Node3D
## Builds the course in code. Upstairs (scripts/course_upstairs.gd): the kids' bedroom
## where the run starts, a sunny gallery and a stair hall. Downstairs: a living room
## (radiator thermal, a low lamp to dive under), a kitchen (kettle-steam thermal) and an
## open window onto hills. Everything is low-poly and vertex-coloured, packed into a few
## meshes. All layout numbers are in the constants below.
##
## Units: 4 units = 1 real metre. Y is up.

# --- Layout: the numbers that shape the flight --------------------------------
const CEILING := 12.0
const HALF_WIDTH := 9.0  ## Inner half-width of both rooms.
const BACK_Z := 14.0  ## Living-room back wall (inner face).
const DIVIDER_Z := -52.0  ## Centre of the wall between living room and kitchen.
const FAR_Z := -88.0  ## Kitchen far wall (inner face), with the open window.
const WALL := 1.0
const DOOR_HALF_WIDTH := 4.0
const DOOR_TOP := 7.0
const WINDOW_HALF_WIDTH := 4.5
const WINDOW_BOTTOM := 4.5
const WINDOW_TOP := 10.5
## Where the scripted tests start a flight of the downstairs part on its own.
const LIVING_ROOM_ENTRY := Vector3(-2.0, 8.5, 12.0)
const RADIATOR_THERMAL := Vector3(-5.0, 3.6, -22.0)
const LAMP := Vector3(0.0, 5.0, -45.0)  ## Bottom centre of the hanging lamp shade.
const KETTLE := Vector3(7.0, 3.7, -69.0)
const KETTLE_THERMAL := Vector3(3.0, 4.2, -69.0)  ## Steam drifts toward the room.
## Outdoors: a sun-warmed hay field past the garden fence, left of the line out of the window,
## with warm air rising over it (x, z; it stands on the ground). Seen through the kitchen window.
const MEADOW_THERMAL := Vector2(-6.0, -118.0)
const MEADOW_THERMAL_RADIUS := 6.0
const MEADOW_THERMAL_HEIGHT := 12.0
## No trees within this distance of the centre line closer than TREE_FREE_TO_Z, so a pilot can
## circle in the meadow thermal and glide on.
const TREE_FREE_HALF_WIDTH := 16.0
const TREE_FREE_TO_Z := -240.0
## A small stream across the valley, a beat to fly over after the thermal.
const STREAM_Z := -150.0
## The hills are drawn, and collide, as a grid of triangles this size, starting here (x, z).
const TERRAIN_STEP := 6.0
const TERRAIN_ORIGIN := Vector2(-126.0, -30.0)
## Things painted on the hills (hay field, stream) sit this far above the grass. The plane's
## shadow sits higher than every painted floor layer (PaperPlane.SHADOW_LIFT).
const PAINT_LIFT := 0.05

# Upstairs: the opening (see docs/opening-plan.md).
const UP_FLOOR := 12.5  ## Upstairs floor top.
const UP_CEILING := 26.5
const IN_WALL := 0.5  ## Upstairs interior wall thickness.
const BEDROOM_MIN := Vector2(90.0, 46.5)  ## Inner corners (x, z).
const BEDROOM_MAX := Vector2(108.0, 79.5)
const BEDROOM_DOOR_X := Vector2(94.5, 102.5)  ## Wide double door in the south wall.
const BEDROOM_DOOR_TOP := 22.5
## Radius of the rounded posts at the sides of new doorways (see doorway_posts()).
const JAMB_RADIUS := 0.6
## The kid kneeling on the loft bed: the first frame is seen from here.
const KID_EYE := Vector3(100.0, 21.9, 76.5)
## The plane starts in the air, just thrown, heading -Z toward the door.
const START := Vector3(100.0, 21.5, 74.5)
const START_HEADING := 0.0
## The upper landing outside the bedroom door, and the gallery running west from it.
const LANDING_EAST_X := 108.5
const LANDING_SOUTH_Z := 33.0
const GALLERY_Z := Vector2(37.0, 46.0)  ## South and north walls (inner faces).
## Sunlight from a tall window in the angled wall warms a patch of floor just past the turn.
const SUNBEAM_ORIGIN := Vector3(89.0, 12.5, 40.5)  ## Centre of the sunny patch on the floor.
const SUNBEAM_SIZE := Vector3(16.0, 12.0, 11.0)
const SUNBEAM_STRENGTH := 0.9
## The light falls steeply from the window (toward +Z and a little +X).
const SUNBEAM_SUN := Vector3(0.08, -0.95, 0.317)
## A skylight halfway down the gallery, over its right-hand (south) half: a small top-up.
const SKYLIGHT_ORIGIN := Vector3(45.0, 12.5, 39.5)
const SKYLIGHT_SIZE := Vector3(8.0, 12.0, 5.0)
const SKYLIGHT_STRENGTH := 0.7
## The two-storey stair hall at the gallery's west end (x, z inner corners).
const STAIR_HALL_MIN := Vector2(-7.5, 15.0)
const STAIR_HALL_MAX := Vector2(16.5, 46.0)
## Flight 1 runs from the gallery floor (x = STAIR_HALL_MAX.x) down to the landing at
## FLIGHT1_BOTTOM_X; the stairs turn right and flight 2 runs down to FLIGHT2_BOTTOM_Z.
const STAIR_LANDING_Y := 6.25
const FLIGHT1_BOTTOM_X := 1.5
const FLIGHT2_BOTTOM_Z := 22.0
const STAIR_STEPS := 12
const RAIL_HEIGHT := 3.6  ## Banister height above the stairs.
## Cool air sinking down over flight 1 from the high north window: it helps the dive.
const DOWNDRAFT_ORIGIN := Vector3(10.0, 13.0, 41.75)
const DOWNDRAFT_SIZE := Vector3(12.0, 13.5, 8.5)
const DOWNDRAFT_STRENGTH := 0.6
## The wide arch in the living-room back wall where the stairs come down (x from, x to).
const ARCH_X := Vector2(-7.0, 6.0)
const ARCH_TOP := 11.5
## A sloped header on the stair side of the arch: it rises from the arch top at 35 degrees,
## so a plane coming down the stairs too high glances down through the arch (a crash needs
## a hit steeper than 50 degrees).
const ARCH_HEADER_RISE := 6.0
const ARCH_HEADER_DEPTH := 8.6
## The tall window in the angled wall that the sunbeam comes through (x from/to, y from/to).
const SUNBEAM_WINDOW_X := Vector2(83.0, 93.5)
const SUNBEAM_WINDOW_Y := Vector2(14.7, 24.9)
## The landing's south wall angles back to the gallery's south wall along this line (x, z).
const TAPER_FROM := Vector2(94.0, LANDING_SOUTH_Z)
const TAPER_TO := Vector2(79.0, GALLERY_Z.x)

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
const BOOK_COLORS := ["f2b8a2", "a9c8e8", "f4dc9b", "b7d8b0", "e3b3cf", "9fb7d9", "f6cfa8"]
const GRASS := [Color("b9d79c"), Color("aed092"), Color("c6dfa8"), Color("a3c98f")]
const FLOWERS := [Color("f2c6d4"), Color("d5c6ea"), Color("f4e7a8")]

var builder: Art.Builder
var _body: StaticBody3D


func _ready() -> void:
	_build()


## The course's centre line. Distance is the furthest progress along it.
static func spine() -> PackedVector3Array:
	return PackedVector3Array([
		START, Vector3(100.0, 19.5, 47.5), Vector3(97.6, 19.2, 42.6), Vector3(94.5, 19.5, 41.5),
		Vector3(16.5, 21.0, 41.5), Vector3(7.0, 13.6, 41.5), Vector3(0.0, 11.4, 38.6),
		Vector3(-3.0, 8.5, 31.0), Vector3(-3.0, 7.5, 22.0), Vector3(-2.0, 8.5, 15.0),
		Vector3(-4.5, 8.0, -22.0), Vector3(0.0, 5.0, -45.0), Vector3(0.0, 5.5, -52.0),
		Vector3(2.5, 7.0, -69.0), Vector3(0.0, 7.5, -88.5), Vector3(0.0, 4.0, -130.0),
		Vector3(0.0, 6.0, -280.0),
	])


## The key moments and the optimal path through each (see docs/opening-plan.md).
## Points and corridor sizes are in Tuning.style_moments.
static func style_moment_defs() -> Array:
	return [
		{"id": &"bedroom_turn", "title": "Door turn", "path": PackedVector3Array([
			Vector3(100, 19.6, 51), Vector3(100, 19.3, 47), Vector3(98.4, 19.1, 43.1), Vector3(94.5, 19.0, 41.5), Vector3(90, 20.0, 41.5)])},
		{"id": &"sunbeam", "title": "Sunbeam", "path": PackedVector3Array([
			Vector3(95, 19.0, 41.5), Vector3(91, 20.7, 41.5), Vector3(87, 22.9, 41.5), Vector3(83, 23.5, 41.5), Vector3(79, 23.4, 41.5)])},
		{"id": &"stair_downdraft", "title": "Downdraft dive", "path": PackedVector3Array([
			Vector3(17, 20.5, 41.5), Vector3(13, 18.0, 41.5), Vector3(10, 15.8, 41.5), Vector3(7, 13.6, 41.5)])},
		{"id": &"landing_turn", "title": "Landing turn", "path": PackedVector3Array([
			Vector3(7, 13.6, 41.5), Vector3(3.5, 12.2, 40.6), Vector3(0, 11.4, 38.6), Vector3(-2.5, 9.8, 34.5), Vector3(-3, 7.5, 26), Vector3(-2, 8.5, 15.5)])},
		{"id": &"radiator", "title": "Radiator lift", "path": PackedVector3Array([
			Vector3(-3.5, 7.0, -12), Vector3(-4.5, 7.5, -18.5), Vector3(-5, 9.0, -22), Vector3(-5, 10.5, -25.5), Vector3(-4.5, 10.8, -30)])},
		{"id": &"lamp", "title": "Under the lamp", "path": PackedVector3Array([
			Vector3(-1.5, 6.5, -36), Vector3(0, 4.2, -42), Vector3(0, 4.05, -45), Vector3(0, 4.2, -48), Vector3(-0.5, 5.2, -52)])},
		{"id": &"kettle", "title": "Kettle steam", "path": PackedVector3Array([
			Vector3(0.5, 5.2, -58), Vector3(2.5, 5.5, -65), Vector3(3, 7.0, -69), Vector3(3, 9.0, -72), Vector3(2, 10.0, -76)])},
		{"id": &"window", "title": "Out the window", "path": PackedVector3Array([
			Vector3(1, 9.0, -79), Vector3(0.3, 8.0, -84), Vector3(0, 7.5, -88.5), Vector3(0, 7.2, -93)])},
	]


## Outdoors starts just beyond the window wall.
static func is_outside(pos: Vector3) -> bool:
	return pos.z < FAR_Z - WALL


## Which part of the course a position is in, for logs and tests.
static func section_at(pos: Vector3) -> String:
	if pos.y > UP_FLOOR - 0.5 and pos.x >= BEDROOM_MIN.x and pos.z >= BEDROOM_MIN.y:
		return "bedroom"
	if is_outside(pos):
		return "outside"
	if pos.z < DIVIDER_Z:
		return "kitchen"
	if pos.z < BACK_Z + WALL:
		return "living room"
	if pos.x < STAIR_HALL_MAX.x:
		return "stair hall"
	return "upstairs"


## Rolling hills that climb away from the house and up to both sides, so every
## flight outside ends on the grass within a few seconds.
static func ground_height(x: float, z: float) -> float:
	var d := maxf(0.0, FAR_Z - WALL - z)
	var rise := d * 0.085 + x * x * 0.004
	var rolls := (1.4 * sin(x * 0.09 + z * 0.045) + 1.0 * sin(x * 0.05 - z * 0.08 + 1.3)) * clampf(d / 25.0, 0.0, 1.0)
	return -1.2 + rise + rolls


## The height of the grass as drawn and as it collides: the triangle grid through
## ground_height(), which can sit a little above or below the smooth curve between grid points.
static func terrain_height(x: float, z: float) -> float:
	var u := (x - TERRAIN_ORIGIN.x) / TERRAIN_STEP
	var v := (TERRAIN_ORIGIN.y - z) / TERRAIN_STEP
	var xa := TERRAIN_ORIGIN.x + floorf(u) * TERRAIN_STEP
	var za := TERRAIN_ORIGIN.y - floorf(v) * TERRAIN_STEP
	u -= floorf(u)
	v -= floorf(v)
	var h00 := ground_height(xa, za)
	var h10 := ground_height(xa + TERRAIN_STEP, za)
	var h01 := ground_height(xa, za - TERRAIN_STEP)
	var h11 := ground_height(xa + TERRAIN_STEP, za - TERRAIN_STEP)
	# Each grid square is split along the diagonal from (xa, zb) to (xb, za).
	if u + v <= 1.0:
		return h00 + u * (h10 - h00) + v * (h01 - h00)
	return h11 + (1.0 - u) * (h01 - h11) + (1.0 - v) * (h10 - h11)


func _build() -> void:
	for child in get_children():
		child.free()
	_body = StaticBody3D.new()
	_body.name = "Collision"
	add_child(_body)

	builder = Art.Builder.new()
	CourseUpstairs.build_bedroom(self)
	CourseUpstairs.build_landing(self)
	CourseUpstairs.build_gallery(self)
	CourseUpstairs.build_stair_hall(self)
	_add_mesh("Upstairs")

	builder = Art.Builder.new()
	_build_shell()
	_build_living_room()
	_build_dining_corner()
	_build_kitchen()
	_build_window()
	_add_mesh("House")

	builder = Art.Builder.new()
	_build_outside()
	_add_mesh("Outside")

	_add_box_zone("Sunbeam", SUNBEAM_ORIGIN, SUNBEAM_SIZE, Thermal.Look.SUNBEAM, SUNBEAM_STRENGTH, 1.12, SUNBEAM_SUN)
	_add_box_zone("Skylight", SKYLIGHT_ORIGIN, SKYLIGHT_SIZE, Thermal.Look.SUNBEAM, SKYLIGHT_STRENGTH, 1.19, Vector3.DOWN, UP_CEILING - SKYLIGHT_ORIGIN.y)
	_add_box_zone("StairDowndraft", DOWNDRAFT_ORIGIN, DOWNDRAFT_SIZE, Thermal.Look.DOWNDRAFT, DOWNDRAFT_STRENGTH, 1.0)
	_add_thermal("RadiatorHeat", RADIATOR_THERMAL, 3.6, 7.6, Thermal.Look.WARM_AIR, 1.0, Vector3.ZERO)
	_add_thermal("KettleSteam", KETTLE_THERMAL, 3.4, 7.0, Thermal.Look.STEAM, 1.26, Vector3(2.55, 0.45, 0.0))
	var meadow := Vector3(MEADOW_THERMAL.x, ground_height(MEADOW_THERMAL.x, MEADOW_THERMAL.y), MEADOW_THERMAL.y)
	_add_thermal("MeadowHeat", meadow, MEADOW_THERMAL_RADIUS, MEADOW_THERMAL_HEIGHT, Thermal.Look.WARM_AIR, 0.9, Vector3.ZERO)


func _add_mesh(mesh_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = builder.commit()
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if not builder.faces.is_empty():
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(builder.faces)
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


## Everything is set before add_child, because the zone builds its visuals in _ready.
func _add_box_zone(zone_name: String, at: Vector3, box: Vector3, look: Thermal.Look, strength: float, pitch: float, sun := Vector3.DOWN, light_height := 0.0) -> Thermal:
	var zone := Thermal.new()
	zone.sun_direction = sun
	zone.light_height = light_height
	zone.name = zone_name
	zone.shape = Thermal.Shape.BOX
	zone.size = box
	zone.look = look
	zone.strength_scale = strength
	zone.chime_pitch = pitch
	zone.position = at
	add_child(zone)
	return zone


# --- Shape helpers: draw into the current mesh, optionally with collision ---------

func box(center: Vector3, size: Vector3, color: Color, solid := true, basis := Basis.IDENTITY) -> void:
	builder.box(center, size, color, basis)
	if solid:
		solid_box(center, size, basis)


## Box between two opposite corners.
func span(a: Vector3, b: Vector3, color: Color, solid := true) -> void:
	box((a + b) * 0.5, (b - a).abs(), color, solid)


## Invisible collision box between two opposite corners.
func solid_span(a: Vector3, b: Vector3) -> void:
	solid_box((a + b) * 0.5, (b - a).abs())


func solid_box(center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_collider(shape, Transform3D(basis, center))


func cylinder(base: Vector3, r_bottom: float, r_top: float, height: float, color: Color, solid := true, segments := 10) -> void:
	builder.cylinder(base, r_bottom, r_top, height, color, segments)
	if not solid:
		return
	if is_equal_approx(r_bottom, r_top):
		var shape := CylinderShape3D.new()
		shape.radius = r_bottom
		shape.height = height
		_collider(shape, Transform3D(Basis.IDENTITY, base + Vector3(0.0, height * 0.5, 0.0)))
		return
	# A cone or tapered shape collides exactly as drawn: the hull is made from the very same
	# mesh points, so there is no invisible bulge.
	var drawn := CylinderMesh.new()
	drawn.bottom_radius = r_bottom
	drawn.top_radius = r_top
	drawn.height = height
	drawn.radial_segments = segments
	drawn.rings = 0
	var hull := ConvexPolygonShape3D.new()
	hull.points = drawn.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	_collider(hull, Transform3D(Basis.IDENTITY, base + Vector3(0.0, height * 0.5, 0.0)))


func sphere(center: Vector3, radius: float, color: Color, solid := true, stretch := Vector3.ONE) -> void:
	builder.sphere(center, radius, color, stretch)
	if solid:
		var shape := SphereShape3D.new()
		shape.radius = radius * minf(stretch.x, minf(stretch.y, stretch.z))
		_collider(shape, Transform3D(Basis.IDENTITY, center))


## Rounded posts either side of an opening in a wall that runs along X (centred on `z`),
## plus a casing across the top. A plane that clips the edge of the opening glances off a
## post instead of hitting the wall face square on.
func doorway_posts(x_left: float, x_right: float, z: float, bottom: float, top: float) -> void:
	for x in [x_left - JAMB_RADIUS, x_right + JAMB_RADIUS]:
		cylinder(Vector3(x, bottom, z), JAMB_RADIUS, JAMB_RADIUS, top - bottom, TRIM, true, 12)
	box(Vector3((x_left + x_right) * 0.5, top + 0.18, z), Vector3(x_right - x_left + JAMB_RADIUS * 4.0, 0.4, JAMB_RADIUS * 2.0), TRIM, false)


## An invisible solid shape (for shapes drawn some other way).
func solid_shape(shape: Shape3D, xform: Transform3D) -> void:
	_collider(shape, xform)


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
	span(Vector3(-w - WALL, -3.0, BACK_Z + WALL), Vector3(w + WALL, -0.5, FAR_Z - WALL), Color("d9cfc4"), false)
	for i in range(int(2 * w)):
		var x := -w + i
		span(Vector3(x, -0.5, BACK_Z), Vector3(x + 1, 0.0, living_end), WOOD_A if i % 2 == 0 else WOOD_B, false)
	for ix in 6:
		for iz in 12:
			var x0 := -w + ix * 3.0
			var z0 := kitchen_start - iz * 3.0
			span(Vector3(x0, -0.5, z0), Vector3(x0 + 3.0, 0.0, maxf(z0 - 3.0, FAR_Z)), TILE_A if (ix + iz) % 2 == 0 else TILE_B, false)
	solid_span(Vector3(-w - WALL, -3.0, BACK_Z + WALL), Vector3(w + WALL, 0.0, FAR_Z - WALL))
	span(Vector3(-w - WALL, CEILING, BACK_Z + WALL), Vector3(w + WALL, CEILING + 0.5, FAR_Z - WALL), CEILING_COLOR)

	# Outer walls.
	span(Vector3(-w - WALL, 0, BACK_Z), Vector3(-w, CEILING, DIVIDER_Z), LIVING_WALL)
	span(Vector3(w, 0, BACK_Z), Vector3(w + WALL, CEILING, DIVIDER_Z), LIVING_WALL)
	span(Vector3(-w - WALL, 0, DIVIDER_Z), Vector3(-w, CEILING, FAR_Z), KITCHEN_WALL)
	span(Vector3(w, 0, DIVIDER_Z), Vector3(w + WALL, CEILING, FAR_Z), KITCHEN_WALL)
	# Back wall, with the arch the stairs come down through.
	var arch_left := ARCH_X.x - JAMB_RADIUS
	var arch_right := ARCH_X.y + JAMB_RADIUS
	span(Vector3(-w - WALL, 0, BACK_Z), Vector3(arch_left, CEILING, BACK_Z + WALL), LIVING_WALL)
	span(Vector3(arch_right, 0, BACK_Z), Vector3(w + WALL, CEILING, BACK_Z + WALL), LIVING_WALL)
	span(Vector3(arch_left, ARCH_TOP, BACK_Z), Vector3(arch_right, CEILING, BACK_Z + WALL), LIVING_WALL)
	doorway_posts(ARCH_X.x, ARCH_X.y, BACK_Z + WALL * 0.5, 0.0, ARCH_TOP)

	# Divider wall with a wide doorway, painted to match each room.
	var dw := DOOR_HALF_WIDTH
	for half in [[DIVIDER_Z, living_end, LIVING_WALL], [kitchen_start, DIVIDER_Z, KITCHEN_WALL]]:
		var za: float = half[0]
		var zb: float = half[1]
		var color: Color = half[2]
		span(Vector3(-w, 0, za), Vector3(-dw, CEILING, zb), color)
		span(Vector3(dw, 0, za), Vector3(w, CEILING, zb), color)
		span(Vector3(-dw, DOOR_TOP, za), Vector3(dw, CEILING, zb), color)
	var t0 := living_end + 0.1
	var t1 := kitchen_start - 0.1
	span(Vector3(-dw - 0.3, 0, t0), Vector3(-dw + 0.03, DOOR_TOP + 0.3, t1), TRIM, false)
	span(Vector3(dw - 0.03, 0, t0), Vector3(dw + 0.3, DOOR_TOP + 0.3, t1), TRIM, false)
	span(Vector3(-dw - 0.3, DOOR_TOP - 0.03, t0), Vector3(dw + 0.3, DOOR_TOP + 0.3, t1), TRIM, false)

	# Far wall around the open window.
	var ww := WINDOW_HALF_WIDTH
	span(Vector3(-w - WALL, 0, FAR_Z), Vector3(-ww, CEILING, FAR_Z - WALL), KITCHEN_WALL)
	span(Vector3(ww, 0, FAR_Z), Vector3(w + WALL, CEILING, FAR_Z - WALL), KITCHEN_WALL)
	span(Vector3(-ww, 0, FAR_Z), Vector3(ww, WINDOW_BOTTOM, FAR_Z - WALL), KITCHEN_WALL)
	span(Vector3(-ww, WINDOW_TOP, FAR_Z), Vector3(ww, CEILING, FAR_Z - WALL), KITCHEN_WALL)

	# Baseboards in the living room.
	span(Vector3(-w, 0, BACK_Z), Vector3(-w + 0.15, 0.6, living_end), Color("e6d2c0"), false)
	span(Vector3(w - 0.15, 0, BACK_Z), Vector3(w, 0.6, living_end), Color("e6d2c0"), false)


func _build_living_room() -> void:
	var w := HALF_WIDTH
	# Radiator under a side window: the first thermal.
	var rz0 := RADIATOR_THERMAL.z - 4.0
	var rz1 := RADIATOR_THERMAL.z + 4.0
	span(Vector3(-w, 0.5, rz0), Vector3(-w + 0.9, 3.5, rz1), Color("f6efe9"))
	var z := rz0 + 0.3
	while z < rz1 - 0.2:
		span(Vector3(-w + 0.85, 0.7, z), Vector3(-w + 1.05, 3.3, z + 0.35), Color("efe4dc"), false)
		z += 0.6
	for fz in [rz0 + 0.4, rz1 - 0.4]:
		span(Vector3(-w + 0.2, 0.0, fz - 0.2), Vector3(-w + 0.7, 0.5, fz + 0.2), Color("e6d9cf"), false)
	_wall_window(-w, 5.0, 10.2, rz0 - 0.5, rz1 + 0.5)
	span(Vector3(-w, 4.6, rz1 + 0.6), Vector3(-w + 0.4, 10.8, rz1 + 2.0), Color("f4c7c3"), false)
	span(Vector3(-w, 4.6, rz0 - 2.0), Vector3(-w + 0.4, 10.8, rz0 - 0.6), Color("f4c7c3"), false)

	# Rug, sofa, coffee table and armchair.
	span(Vector3(-5.5, 0.0, -14.0), Vector3(5.5, 0.06, -32.0), Color("e7b9b5"), false)
	span(Vector3(-4.8, 0.0, -14.7), Vector3(4.8, 0.08, -31.3), Color("eccac4"), false)
	var sofa := Color("a9c4e2")
	span(Vector3(4.6, 0.0, -16.0), Vector3(w, 1.8, -30.0), sofa)
	span(Vector3(7.6, 1.8, -16.0), Vector3(w, 4.2, -30.0), sofa)
	span(Vector3(4.6, 1.8, -16.0), Vector3(7.6, 2.8, -17.0), sofa)
	span(Vector3(4.6, 1.8, -29.0), Vector3(7.6, 2.8, -30.0), sofa)
	for cz in [-17.2, -21.4, -25.6]:
		span(Vector3(4.8, 1.8, cz), Vector3(7.5, 2.35, cz - 3.8), Color("bcd3ec"), false)
		span(Vector3(7.0, 2.2, cz - 0.3), Vector3(7.6, 3.9, cz - 3.5), Color("c8dbef"), false)
	span(Vector3(-0.5, 1.3, -19.5), Vector3(3.0, 1.6, -26.5), Color("d8b896"))
	for leg in [Vector3(-0.3, 0, -19.7), Vector3(2.55, 0, -19.7), Vector3(-0.3, 0, -26.05), Vector3(2.55, 0, -26.05)]:
		span(leg, leg + Vector3(0.25, 1.3, -0.25), Color("c9a684"), false)
	cylinder(Vector3(1.0, 1.6, -22.0), 0.35, 0.3, 0.7, Color("a9c8e8"), false)
	sphere(Vector3(1.0, 2.6, -22.0), 0.45, Color("f2c6d4"), false)
	var chair := Color("f2d79b")
	span(Vector3(-w, 0.0, -2.0), Vector3(-5.0, 1.9, -6.5), chair)
	span(Vector3(-w, 1.9, -2.0), Vector3(-7.9, 4.6, -6.5), chair)
	span(Vector3(-7.9, 1.9, -2.0), Vector3(-5.0, 3.0, -2.8), chair)
	span(Vector3(-7.9, 1.9, -5.7), Vector3(-5.0, 3.0, -6.5), chair)
	# Floor lamp and a corner plant.
	cylinder(Vector3(-7.5, 0.0, -9.0), 0.6, 0.6, 0.2, Color("b9a28f"), false)
	cylinder(Vector3(-7.5, 0.2, -9.0), 0.08, 0.08, 5.8, Color("b9a28f"))
	cylinder(Vector3(-7.5, 6.0, -9.0), 1.1, 0.6, 1.3, Color("fbe3c2"))
	cylinder(Vector3(7.0, 0.0, 6.5), 0.8, 1.0, 1.8, Color("e2a888"))
	sphere(Vector3(7.0, 3.0, 6.5), 1.3, Color("9cc48a"), true, Vector3(1.0, 1.25, 1.0))
	sphere(Vector3(6.4, 4.2, 6.9), 0.8, Color("b3d39b"), false)
	# Pictures on the walls and a clock over the doorway.
	_picture(Vector3(w, 7.5, -8.0), -1.0, Color("f4dc9b"), Color("a9c8e8"))
	_picture(Vector3(w, 7.0, -40.0), -1.0, Color("e3b3cf"), Color("b7d8b0"))
	_picture(Vector3(-w, 7.0, -40.0), 1.0, Color("a9c8e8"), Color("f6cfa8"))
	var clock_z := DIVIDER_Z + WALL * 0.5
	var face_forward := Basis(Vector3.RIGHT, PI / 2.0)
	builder.cylinder(Vector3(0.0, 9.6, clock_z), 1.0, 1.0, 0.15, Color("d9a5a6"), 16, face_forward)
	builder.cylinder(Vector3(0.0, 9.6, clock_z + 0.15), 0.85, 0.85, 0.05, TRIM, 16, face_forward)
	box(Vector3(0.0, 9.9, clock_z + 0.24), Vector3(0.08, 0.6, 0.04), Color("6f6478"), false)
	box(Vector3(0.2, 9.6, clock_z + 0.24), Vector3(0.45, 0.07, 0.04), Color("6f6478"), false)


## Dining table and chairs under a low hanging lamp, just before the doorway: the dive.
func _build_dining_corner() -> void:
	var w := HALF_WIDTH
	span(Vector3(-3.0, 2.8, -42.0), Vector3(3.0, 3.1, -48.0), Color("c8a283"))
	for leg in [Vector3(-2.7, 0, -42.3), Vector3(2.45, 0, -42.3), Vector3(-2.7, 0, -47.45), Vector3(2.45, 0, -47.45)]:
		span(leg, leg + Vector3(0.25, 2.8, -0.25), Color("b8916f"))
	for side in [-1.0, 1.0]:
		for cz in [-43.5, -46.5]:
			var seat := Vector3(4.4 * side, 1.8, cz)
			box(seat, Vector3(1.6, 0.25, 1.6), Color("e9c6a0"))
			box(seat + Vector3(0.75 * side, 1.3, 0.0), Vector3(0.2, 2.6, 1.6), Color("e9c6a0"))
			for lx in [-0.6, 0.6]:
				for lz in [-0.6, 0.6]:
					box(Vector3(seat.x + lx, 0.9, cz + lz), Vector3(0.15, 1.8, 0.15), Color("d9b48f"), false)
	cylinder(LAMP, 2.0, 0.7, 1.6, Color("f6c9b8"), true, 14)
	cylinder(LAMP + Vector3(0, 1.6, 0), 0.7, 0.3, 0.4, Color("f6c9b8"), false, 14)
	cylinder(LAMP + Vector3(0, 2.0, 0), 0.05, 0.05, CEILING - LAMP.y - 2.0, Color("9b8fa6"), false, 6)
	sphere(LAMP + Vector3(0, 0.3, 0), 0.45, Color("fff4d6"), false)
	# A sideboard with a vase on the left wall.
	span(Vector3(-w, 0.0, -38.0), Vector3(-7.4, 3.4, -48.0), Color("cfe0d8"))
	cylinder(Vector3(-8.2, 3.4, -41.0), 0.4, 0.25, 1.4, Color("f4dc9b"), false)
	sphere(Vector3(-8.2, 5.1, -41.0), 0.5, Color("f2b8a2"), false)


func _build_kitchen() -> void:
	var w := HALF_WIDTH
	var counter := Color("b9d8cb")
	var top := Color("f5f0e6")
	var ink := Color("6f6478")
	# Counters along the right wall, with the stove and kettle: the second thermal.
	span(Vector3(5.4, 0.0, -55.0), Vector3(w, 3.4, -85.4), counter)
	span(Vector3(5.3, 3.4, -55.0), Vector3(w, 3.7, -85.4), top)
	var dz := -55.4
	while dz > -85.0:
		span(Vector3(5.36, 0.4, dz), Vector3(5.4, 3.1, dz - 2.8), Color("a8cbbd"), false)
		dz -= 3.2
	span(Vector3(5.6, 3.7, KETTLE.z + 3.0), Vector3(8.8, 3.75, KETTLE.z - 3.0), Color("8f8aa0"), false)
	for bz in [KETTLE.z + 1.5, KETTLE.z - 1.5]:
		cylinder(Vector3(6.6, 3.75, bz), 0.6, 0.6, 0.04, ink, false, 12)
	cylinder(KETTLE, 0.85, 0.65, 1.2, Color("f19e8f"), true, 12)
	cylinder(KETTLE + Vector3(0, 1.2, 0), 0.5, 0.2, 0.3, Color("f19e8f"), false, 12)
	sphere(KETTLE + Vector3(0, 1.6, 0), 0.15, ink, false)
	box(KETTLE + Vector3(0.0, 1.55, 0.0), Vector3(0.12, 0.12, 1.3), ink, false)
	builder.cylinder(KETTLE + Vector3(-0.7, 0.45, 0), 0.18, 0.1, 0.9, Color("f19e8f"), 8, Basis(Vector3.BACK, PI * 0.32))
	# Upper cabinets, leaving the stove clear for the steam.
	span(Vector3(7.2, 7.6, -55.0), Vector3(w, 11.4, -62.0), Color("c7e0d6"))
	span(Vector3(7.2, 7.6, -76.0), Vector3(w, 11.4, -85.4), Color("c7e0d6"))
	# Counter under the window, with a sink and herbs.
	span(Vector3(-w, 0.0, -85.4), Vector3(5.4, 3.4, FAR_Z), counter)
	span(Vector3(-w, 3.4, -85.4), Vector3(w, 3.7, FAR_Z), top)
	span(Vector3(-2.0, 3.7, -85.8), Vector3(2.0, 3.73, -87.6), Color("c4d3dc"), false)
	for hx in [-3.6, 3.6]:
		cylinder(Vector3(hx, 3.7, -86.7), 0.35, 0.45, 0.6, Color("e2a888"), false)
		sphere(Vector3(hx, 4.6, -86.7), 0.5, Color("9cc48a"), false)
	# Fridge, a small round table and stools.
	span(Vector3(-w, 0.0, -53.0), Vector3(-5.8, 8.6, -59.0), Color("c9e2ea"))
	span(Vector3(-5.8, 3.6, -53.6), Vector3(-5.65, 6.4, -53.9), TRIM, false)
	span(Vector3(-5.8, 5.0, -53.0), Vector3(-5.78, 5.05, -59.0), Color("b5d2dc"), false)
	cylinder(Vector3(-4.8, 0.0, -73.0), 1.0, 0.3, 0.3, Color("d9b48f"))
	cylinder(Vector3(-4.8, 0.3, -73.0), 0.2, 0.2, 2.5, Color("d9b48f"))
	cylinder(Vector3(-4.8, 2.8, -73.0), 2.0, 2.0, 0.25, Color("e9c6a0"), true, 16)
	cylinder(Vector3(-4.8, 3.05, -73.0), 0.7, 0.9, 0.35, Color("a9c8e8"), false, 12)
	for fruit in [Vector3(-5.0, 3.55, -72.8), Vector3(-4.5, 3.55, -73.2), Vector3(-4.8, 3.75, -73.0)]:
		sphere(fruit, 0.28, Color("f6cfa8"), false)
	for sz in [-69.8, -76.2]:
		cylinder(Vector3(-4.8, 0.0, sz), 0.6, 0.6, 1.9, Color("f4dc9b"), true, 10)


## The open window: frame, sill, curtains, and two sashes swung wide outside.
func _build_window() -> void:
	var ww := WINDOW_HALF_WIDTH
	var inner := FAR_Z + 0.1
	var outer := FAR_Z - WALL - 0.1
	span(Vector3(-ww - 0.3, WINDOW_BOTTOM - 0.3, FAR_Z + 0.4), Vector3(ww + 0.3, WINDOW_BOTTOM + 0.05, outer - 0.1), TRIM)
	span(Vector3(-ww - 0.3, WINDOW_TOP - 0.03, inner), Vector3(ww + 0.3, WINDOW_TOP + 0.3, outer), TRIM, false)
	span(Vector3(-ww - 0.3, WINDOW_BOTTOM, inner), Vector3(-ww + 0.03, WINDOW_TOP, outer), TRIM, false)
	span(Vector3(ww - 0.03, WINDOW_BOTTOM, inner), Vector3(ww + 0.3, WINDOW_TOP, outer), TRIM, false)
	var height := WINDOW_TOP - WINDOW_BOTTOM
	for side in [-1.0, 1.0]:
		span(Vector3(side * (ww + 0.25), 4.0, FAR_Z + 0.6), Vector3(side * (ww + 2.0), 11.6, FAR_Z + 0.2), Color("f4c7c3"), false)
		var hinge := Vector3(side * ww, WINDOW_BOTTOM + height * 0.5, FAR_Z - WALL)
		var sash := Basis(Vector3.UP, -side * deg_to_rad(115.0))
		var mid := hinge + sash * Vector3(-side * ww * 0.5, 0.0, 0.0)
		box(mid, Vector3(ww, height, 0.2), TRIM, true, sash)
		box(mid + sash * Vector3(0, 0, 0.06), Vector3(ww - 0.5, height - 0.5, 0.12), GLASS, false, sash)
		box(mid + sash * Vector3(0, 0, -0.06), Vector3(ww - 0.5, height - 0.5, 0.12), GLASS, false, sash)
	span(Vector3(-ww - 2.2, 11.7, FAR_Z + 0.5), Vector3(ww + 2.2, 11.85, FAR_Z + 0.3), Color("b9a28f"), false)


## A bright window painted on the left wall (facing +X), with frame and cross bars.
func _wall_window(x: float, y0: float, y1: float, z0: float, z1: float) -> void:
	span(Vector3(x, y0, z0), Vector3(x + 0.08, y1, z1), TRIM, false)
	span(Vector3(x + 0.08, y0 + 0.3, z0 + 0.3), Vector3(x + 0.1, y1 - 0.3, z1 - 0.3), SKY_PANE, false)
	var mz := (z0 + z1) * 0.5
	var my := (y0 + y1) * 0.5
	span(Vector3(x + 0.1, y0 + 0.3, mz - 0.1), Vector3(x + 0.14, y1 - 0.3, mz + 0.1), TRIM, false)
	span(Vector3(x + 0.1, my - 0.1, z0 + 0.3), Vector3(x + 0.14, my + 0.1, z1 - 0.3), TRIM, false)


## A framed picture on a side wall. `facing` is +1 on the left wall, -1 on the right wall.
func _picture(wall_point: Vector3, facing: float, sky: Color, land: Color) -> void:
	var at := wall_point + Vector3(facing * 0.1, 0, 0)
	box(at, Vector3(0.2, 3.0, 4.0), Color("b9a28f"), false)
	var face := at + Vector3(facing * 0.11, 0, 0)
	box(face + Vector3(0, 0.5, 0), Vector3(0.02, 1.0, 3.4), sky, false)
	box(face + Vector3(0, -0.6, 0), Vector3(0.02, 1.2, 3.4), land, false)
	box(face + Vector3(facing * 0.01, 0.55, 0.9), Vector3(0.02, 0.4, 0.4), Color("fbf3d6"), false)


# --- Outside ------------------------------------------------------------------------

func _build_outside() -> void:
	# Terrain: a gently rising valley of pastel grass.
	var step := TERRAIN_STEP
	var x0 := TERRAIN_ORIGIN.x
	var z0 := TERRAIN_ORIGIN.y
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
			builder.triangle(p00, p01, p10, _grass(rng), true)
			builder.triangle(p10, p01, p11, _grass(rng), true)

	# A low garden fence across the view.
	var fence_z := -101.0
	var x := -40.0
	while x <= 40.0:
		var gy := ground_height(x, fence_z)
		box(Vector3(x, gy + 1.0, fence_z), Vector3(0.35, 2.6, 0.35), TRIM)
		if x < 40.0:
			var mid_y := (gy + ground_height(x + 2.5, fence_z)) * 0.5
			for rail in [0.9, 1.8]:
				builder.box(Vector3(x + 1.25, mid_y + rail, fence_z), Vector3(2.5, 0.2, 0.15), Color("f3ece2"))
		x += 2.5

	# The hay field under the meadow thermal: golden rows, so the rising heat has a visible cause.
	var hay := MEADOW_THERMAL
	_ground_patch(hay.x - 6.0, hay.x + 6.0, hay.y + 6.0, hay.y - 6.0, 1.0, [Color("f4dc9b"), Color("e9c98a")])

	# A stream across the valley with a few flat stepping stones.
	var bank := 1.3
	var sx := -60.0
	while sx < 60.0:
		var za := STREAM_Z + 2.0 * sin(sx * 0.12)
		var zb := STREAM_Z + 2.0 * sin((sx + 1.0) * 0.12)
		var water := Color("a9cfe0") if int(sx / 2.0) % 2 == 0 else Color("b8d8e6")
		for half in [1.0, 0.0]:  # in two strips across, so the water follows the grass closely
			_ground_quad(Vector3(sx, 0.0, za + bank * half), Vector3(sx + 1.0, 0.0, zb + bank * half), Vector3(sx, 0.0, za + bank * (half - 1.0)), Vector3(sx + 1.0, 0.0, zb + bank * (half - 1.0)), water)
		sx += 1.0
	for stone_x in [-3.4, -1.2, 1.1, 3.3]:
		var sz := STREAM_Z + 2.0 * sin(stone_x * 0.12)
		builder.sphere(Vector3(stone_x, terrain_height(stone_x, sz) + 0.2, sz + 0.3 * sin(stone_x * 2.0)), 0.55, Color("c9c2ba"), Vector3(1.0, 0.25, 0.8), 8, 3)

	# Trees on the slopes, kept clear of the flight path from the window out past the meadow.
	var trng := RandomNumberGenerator.new()
	trng.seed = 21
	var placed := 0
	while placed < 26:
		var tx := trng.randf_range(-90.0, 90.0)
		var tz := trng.randf_range(-105.0, -300.0)
		if absf(tx) < TREE_FREE_HALF_WIDTH and tz > TREE_FREE_TO_Z:
			continue
		_tree(Vector3(tx, ground_height(tx, tz), tz), trng)
		placed += 1

	# Far hills and clouds (no collision), softened by the fog.
	var hills := [[-220.0, -380.0, 90.0, Color("a9c9a4")], [-60.0, -430.0, 120.0, Color("b5cfb0")], [120.0, -400.0, 100.0, Color("a7c4b8")],
		[260.0, -360.0, 80.0, Color("b9d3c2")], [10.0, -520.0, 160.0, Color("bcd2dc")], [-330.0, -300.0, 70.0, Color("b3cdb6")]]
	for h in hills:
		builder.sphere(Vector3(h[0], -12.0, h[1]), h[2], h[3], Vector3(1.6, 0.42, 1.0), 14, 7)
	for c in [Vector3(-80, 70, -320), Vector3(40, 85, -420), Vector3(170, 65, -300), Vector3(-200, 90, -450)]:
		for i in 3:
			builder.sphere(c + Vector3(i * 14.0 - 14.0, (i % 2) * 4.0, 0.0), 13.0 - (i % 2) * 3.0, Color("fdfbf8"), Vector3(1.4, 0.55, 1.0), 10, 5)


## Paints a patch on the hills between x0..x1 and z0..z1 (either order), in stripes of the given
## colours along x. Use a step that divides TERRAIN_STEP so it follows the grass exactly.
func _ground_patch(x0: float, x1: float, z0: float, z1: float, step: float, colors: Array) -> void:
	var xs := [minf(x0, x1), maxf(x0, x1)]
	var zs := [maxf(z0, z1), minf(z0, z1)]  # nearer the house first, so the faces point up
	x0 = xs[0]
	x1 = xs[1]
	z0 = zs[0]
	z1 = zs[1]
	var nx := maxi(1, ceili((x1 - x0) / step))
	var nz := maxi(1, ceili((z0 - z1) / step))
	for ix in nx:
		for iz in nz:
			var xa := lerpf(x0, x1, float(ix) / nx)
			var xb := lerpf(x0, x1, float(ix + 1) / nx)
			var za := lerpf(z0, z1, float(iz) / nz)
			var zb := lerpf(z0, z1, float(iz + 1) / nz)
			_ground_quad(Vector3(xa, 0.0, za), Vector3(xb, 0.0, za), Vector3(xa, 0.0, zb), Vector3(xb, 0.0, zb), colors[ix % colors.size()])


## One painted quad on the hills, PAINT_LIFT above the grass: corners given by x and z, a and b
## nearer the house than c and d, heights from the grass as drawn. Drawn only: the grass collides.
func _ground_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	var corners: Array[Vector3] = []
	for p: Vector3 in [a, b, c, d]:
		corners.append(Vector3(p.x, terrain_height(p.x, p.z) + PAINT_LIFT, p.z))
	builder.triangle(corners[0], corners[2], corners[1], color)
	builder.triangle(corners[1], corners[2], corners[3], color)


func _grass(rng: RandomNumberGenerator) -> Color:
	if rng.randf() < 0.025:
		return FLOWERS[rng.randi() % FLOWERS.size()]
	return GRASS[rng.randi() % GRASS.size()]


func _tree(base: Vector3, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.8, 1.4)
	cylinder(base - Vector3(0, 0.5, 0), 0.45 * s, 0.35 * s, 4.0 * s, Color("a88b74"), true, 7)
	if rng.randf() < 0.5:
		cylinder(base + Vector3(0, 2.5 * s, 0), 2.6 * s, 0.0, 7.0 * s, Color("8fbf9a"), true, 8)
	else:
		var leaf := Color("9cc48a") if rng.randf() < 0.5 else Color("b3d39b")
		sphere(base + Vector3(0, 5.2 * s, 0), 2.6 * s, leaf, true, Vector3(1.0, 0.9, 1.0))
		sphere(base + Vector3(1.2 * s, 4.4 * s, 0.6 * s), 1.6 * s, leaf.lightened(0.08), false)
