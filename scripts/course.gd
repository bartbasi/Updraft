# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
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
const LAMP := Vector3(0.0, 5.5, -45.0)  ## Bottom centre of the hanging lamp shade.
const LAMP_SHADE_RADIUS := 1.7  ## At its bottom rim.
const DINING_TABLE_TOP := 2.8  ## The gap between table and shade is the lamp moment's dive.
const KETTLE := Vector3(7.0, 3.7, -69.0)
## The steam drifts toward the room, and reaches down low enough to catch planes coming in
## just over the counter (its top stays at y 11.2).
const KETTLE_THERMAL := Vector3(3.0, 3.0, -69.0)
const KETTLE_STEAM_HEIGHT := 8.2
const KETTLE_SPOUT_TIP := KETTLE + Vector3(-1.45, 0.95, 0.0)  ## Where the steam puffs come out.
## Outdoors (docs/outside-plan.md): a wide valley to explore, with a light breeze from the right
## (+X), so the left hillside, facing into it, is a ridge with rising air along it.
## The valley floor rises this much per unit away from the house.
const VALLEY_RISE := 0.03
## The left ridge: its face climbs RIDGE_HEIGHT between these x (near, far) to a flat plateau.
const RIDGE_FACE_X := Vector2(-26.0, -66.0)
const RIDGE_HEIGHT := 22.0
## Warm air outdoors: each thermal stands on the ground at its centre (x, z) and rises to `top`
## (y). `strength` scales Tuning.thermal_strength. Its ground cause is drawn under it.
## Each is in sight from the top of the one before (docs/outside-plan.md, section 2).
const HAY_FIELD := {"name": "HayHeat", "at": Vector2(-2.0, -118.0), "radius": 12.0, "top": 24.0, "strength": 0.9, "pitch": 0.9}
const BARN_ROOF := {"name": "BarnHeat", "at": Vector2(30.0, -165.0), "radius": 10.0, "top": 27.0, "strength": 0.8, "pitch": 0.95}
const PLOUGHED_FIELD := {"name": "FieldHeat", "at": Vector2(-12.0, -215.0), "radius": 10.0, "top": 29.0, "strength": 0.8, "pitch": 1.0}
const BONFIRE_SMOKE := {"name": "BonfireSmoke", "at": Vector2(30.0, -258.0), "radius": 10.0, "top": 29.0, "strength": 0.8, "pitch": 1.05}
## Past the valley (Phase 4): warm air off the chalk pit at the foot of the Downs, the last step
## up to the Gap, and off the sand at the north end of the beach in the bowl.
const CHALK_HEAT := {"name": "ChalkHeat", "at": Vector2(-14.0, -290.0), "radius": 10.0, "top": 27.0, "strength": 0.8, "pitch": 1.08}
const SAND_HEAT := {"name": "SandHeat", "at": Vector2(50.0, -392.0), "radius": 10.0, "top": 30.0, "strength": 0.85, "pitch": 1.12}
## The valley's thermals as first laid out: trees are still placed around these (see tree_spots()).
const VALLEY_THERMALS := [HAY_FIELD, BARN_ROOF, PLOUGHED_FIELD, BONFIRE_SMOKE]
const OUTDOOR_THERMALS := [HAY_FIELD, BARN_ROOF, PLOUGHED_FIELD, BONFIRE_SMOKE, CHALK_HEAT, SAND_HEAT]
## The chalk scar under ChalkHeat and the beach (x from/to, z near/far).
const CHALK_X := Vector2(-24.0, -4.0)
const CHALK_Z := Vector2(-282.0, -300.0)
const BEACH_X := Vector2(40.0, 58.0)
const BEACH_Z := Vector2(-380.0, -446.0)
## Ridge lift up the west bluff in the bowl: a box standing on y 0, like RIDGE_LIFT.
const BLUFF_LIFT := Vector3(-60.0, 0.0, -420.0)
const BLUFF_LIFT_SIZE := Vector3(24.0, 34.0, 100.0)
const BLUFF_LIFT_STRENGTH := 0.45
## Weak sinking air over the lake (scales Tuning.downdraft_strength): a box standing on its
## bottom centre.
const LAKE_SINK := Vector3(0.0, -1.0, -420.0)
const LAKE_SINK_SIZE := Vector3(72.0, 26.0, 54.0)
const LAKE_SINK_STRENGTH := 0.115
## Birds hanging on the breeze over the bluff (x, z), this far above its plateau.
const BLUFF_BIRDS: Array[Vector2] = [Vector2(-60.0, -385.0), Vector2(-61.0, -399.0), Vector2(-59.0, -413.0),
	Vector2(-60.0, -427.0), Vector2(-61.0, -441.0), Vector2(-59.0, -455.0)]
## The barn (centre x, z): solid walls and a pitched roof of dark slate that warms in the sun.
const BARN := Vector2(35.0, -163.0)
const BARN_SIZE := Vector3(10.0, 5.0, 7.0)  ## Width (x), wall height, depth (z).
const BARN_RIDGE := 8.5  ## Roof ridge height above the ground.
## The leaf bonfire whose smoke is the last thermal (not solid).
const BONFIRE := Vector2(32.0, -258.0)
## Rising air along the left ridge, where the breeze blows up the hillside: a box standing on
## y 0 (x, z centre), its size, and its strength (scales Tuning.thermal_strength).
const RIDGE_LIFT := Vector3(-38.0, 0.0, -195.0)
const RIDGE_LIFT_SIZE := Vector3(24.0, 33.0, 140.0)
const RIDGE_LIFT_STRENGTH := 0.4
## A picnic blanket on the plateau above the ridge (x from/to, z near/far): the expert's
## landing spot.
const PICNIC_X := Vector2(-75.0, -69.0)
const PICNIC_Z := Vector2(-202.5, -207.5)
## No trees this close to the blanket (plan view), so a full-bank circle down onto it is clear.
const PICNIC_CLEARANCE := 16.0
## Signs of rising air you can see from far away (looks only, nothing collides):
## a puffy cloud whose flat base sits this far above each thermal's top,
const CLOUD_ABOVE_TOP := 4.0
## birds hanging on the breeze over the ridge,
const RIDGE_BIRDS: Array[Vector3] = [Vector3(-40.0, 0.0, -150.0), Vector3(-41.0, 0.0, -168.0), Vector3(-39.0, 0.0, -186.0),
	Vector3(-40.0, 0.0, -204.0), Vector3(-41.0, 0.0, -222.0), Vector3(-39.0, 0.0, -240.0)]
const RIDGE_BIRDS_ABOVE_CREST := 3.0
## a windsock by the garden fence, pointing the way the breeze blows (-X),
const WINDSOCK := Vector2(14.0, -103.0)
## and a big kite flying over the ridge from the picnic, seen from the hay field's top.
const KITE := Vector3(-62.0, 36.0, -190.0)
const KITE_SIZE := 6.0  ## Top to bottom.
const KITE_COLOR := Color("e8604c")
## Round hay bales on the hay field (x, z): solid, lying on their sides, out at the sides of the
## field so a plane coming down the middle of the valley never meets one.
const HAY_BALES := [Vector2(-11.0, -110.0), Vector2(8.0, -109.0), Vector2(-10.5, -127.0), Vector2(8.5, -126.0), Vector2(-14.5, -119.0)]
const BALE_RADIUS := 1.0
const BALE_LENGTH := 1.5
## Trees stay this far (plan view) from the edge of every lift zone.
const TREE_CLEARANCE := 4.0
## A small stream across the valley, a beat to fly over between thermals.
const STREAM_Z := -150.0
const STREAM_X := Vector2(-28.0, 60.0)
## A lavender field where a good glide comes down (painted only). x left to right; z near
## edge (house side) to far edge.
const LAVENDER_X := Vector2(-14.0, 4.0)
const LAVENDER_Z := Vector2(-166.0, -196.0)
## A plane anywhere outside this box has left the world: the run ends as a landing.
const WORLD_BOUNDS := AABB(Vector3(-123.0, -10.0, -525.0), Vector3(246.0, 400.0, 686.0))

# Past the valley (docs/phase4-plan.md, part B): the Downs, a line of high hills along the old
# head wall, with one wide notch, the Gap; through it, a bowl with a lake, an island, a beach
# and a bluff.
## The Downs' crest line: the valley's ground up to here, the bowl's beyond.
const CREST_Z := -339.0
## The Gap: its centre line (x), the half-width of its flat floor, and the slope of its walls.
const GAP_X := 6.0
const GAP_HALF := 14.0
const GAP_WALL := 1.1
## Where the Gap is cut (z, from the valley side to the lake side).
const GAP_CUT_Z := Vector2(-285.0, -400.0)
## The Gap's highest point: its z and height.
const SADDLE := Vector2(-334.0, 13.0)
## The far side of the Downs falls to the bowl over this distance.
const DOWNS_FALL := 35.0
## The lake's water surface, centre (x, z) and radii (x, z).
const LAKE_Y := -1.0
const LAKE_CENTRE := Vector2(0.0, -420.0)
const LAKE_RADII := Vector2(40.0, 30.0)
const ISLAND := Vector2(-6.0, -424.0)
const ISLAND_RADIUS := 8.0
## The west bluff: where its face starts and ends (x), and its height.
const BLUFF_FACE_X := Vector2(-44.0, -84.0)
const BLUFF_HEIGHT := 24.0
## From the valley this close to the Downs (z), the Gap and the bowl beyond are in view.
const GAP_VIEW_Z := -300.0
## A wildflower meadow on the lake's far shore (z near, far).
const MEADOW_Z := Vector2(-455.0, -485.0)
## The bowl's grass is a second grid on the same lattice as the valley's, out to here (z).
const BOWL_END_Z := -528.0
## The hills are drawn, and collide, as a grid of triangles this size, starting here (x, z).
const TERRAIN_STEP := 6.0
const TERRAIN_ORIGIN := Vector2(-126.0, -30.0)
## Things painted on the hills (hay field, stream, lavender) sit this far above the grass. The plane's
## shadow sits higher than every painted floor layer (Flyer.SHADOW_LIFT).
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
		Vector3(0.0, 6.0, -280.0), Vector3(6.0, 18.0, -334.0), Vector3(4.0, 6.0, -400.0), Vector3(0.0, 4.0, -480.0),
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
		{"id": &"ridge_run", "title": "Ridge run", "path": PackedVector3Array([
			Vector3(-33, 20.0, -160), Vector3(-37, 26.0, -188), Vector3(-37, 30.5, -212)])},  # ends where the routes turn off
		# Low over the saddle and diving into the bowl: arriving at 21-22 means diving about 4 units
		# in the last 30, the outdoor answer to the stair dive. Gliding straight over high pays nothing.
		{"id": &"gap", "title": "Through the Gap", "path": PackedVector3Array([
			Vector3(6, 19.5, -318), Vector3(6, 17.5, -334), Vector3(6, 15.5, -350), Vector3(5, 13.5, -366)])},
	]


## Where a run can end with a landing bonus (points in Tuning.landing_bonus): the area seen
## from above (x, z) where the plane may come to rest, which includes room for its slide.
static func landing_spots() -> Array:
	var slide := 2.0
	return [
		{"id": "lavender", "title": "Lavender landing!", "area": Rect2(LAVENDER_X.x, LAVENDER_Z.y, LAVENDER_X.y - LAVENDER_X.x, LAVENDER_Z.x - LAVENDER_Z.y)},
		{"id": "picnic", "title": "Picnic landing!", "area": Rect2(PICNIC_X.x - slide, PICNIC_Z.y - slide, PICNIC_X.y - PICNIC_X.x + slide * 2.0, PICNIC_Z.x - PICNIC_Z.y + slide * 2.0)},
		# The island: its corners are at the shoreline, and a plane that slid into the water is a
		# splashdown, not an island landing (see on_water()).
		{"id": "island", "title": "Island landing!", "area": Rect2(ISLAND.x - 5.5, ISLAND.y - 5.5, 11.0, 11.0)},
		# The beach's south part (the warm sand's lift ends at its north end), clear of the waterline.
		{"id": "beach", "title": "Beach landing!", "area": Rect2(BEACH_X.x + 2.0, BEACH_Z.y, BEACH_X.y - BEACH_X.x - 2.0, 34.0)},
	]


## Resting in the water: the lake, or the inlet where the Gap's stream meets it.
static func on_water(pos: Vector3) -> bool:
	return pos.z < CREST_Z and terrain_height(pos.x, pos.z) < LAKE_Y - 0.05


## Over the lavender field (seen from above).
static func in_lavender(pos: Vector3) -> bool:
	return pos.x >= minf(LAVENDER_X.x, LAVENDER_X.y) and pos.x <= maxf(LAVENDER_X.x, LAVENDER_X.y) 		and pos.z <= maxf(LAVENDER_Z.x, LAVENDER_Z.y) and pos.z >= minf(LAVENDER_Z.x, LAVENDER_Z.y)


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


## The hills: the valley (see _valley()), and beyond the Downs' crest the bowl with its lake
## (see _bowl()), with the Gap cut through the Downs between them. Every edge of the world is
## high ground.
static func ground_height(x: float, z: float) -> float:
	var h := _valley(x, z) if z > CREST_Z else _bowl(x, z)
	if z < GAP_CUT_Z.x and z > GAP_CUT_Z.y:
		h = minf(h, _gap_floor(z) + GAP_WALL * maxf(0.0, absf(x - GAP_X) - GAP_HALF))
	return h


## The valley: a gently rising floor with soft rolls, the ridge and its plateau on the left,
## slopes on the right, a head wall at the far end (the Downs) and banks beside the house.
static func _valley(x: float, z: float, with_rolls := true) -> float:
	var d := maxf(0.0, FAR_Z - WALL - z)  # distance out from the window wall
	var h := -1.2 + VALLEY_RISE * d
	h += 0.015 * pow(maxf(0.0, d - 190.0), 2.0)  # head wall
	h += 0.006 * pow(maxf(0.0, x - 28.0), 2.0)  # right-hand slopes
	h += RIDGE_HEIGHT * smoothstep(-RIDGE_FACE_X.x, -RIDGE_FACE_X.y, -x)  # the ridge and its plateau
	h += 0.012 * pow(maxf(0.0, -x - 84.0), 2.0)  # behind the plateau, up to the edge
	h += 0.04 * pow(maxf(0.0, z + 64.0), 2.0) * smoothstep(12.0, 20.0, absf(x))  # banks beside the house
	if not with_rolls:
		return h
	return h + _rolls(x, z) * clampf(d / 25.0, 0.0, 1.0)


## The grass's soft rolls.
static func _rolls(x: float, z: float) -> float:
	return 0.6 * (1.4 * sin(x * 0.09 + z * 0.045) + 1.0 * sin(x * 0.05 - z * 0.08 + 1.3))


## The floor of the Gap: up from the valley to the saddle, then down a short valley to the shore.
static func _gap_floor(z: float) -> float:
	if z >= SADDLE.x:
		return lerpf(_valley(GAP_X, -290.0, false), SADDLE.y, smoothstep(290.0, -SADDLE.x, -z))
	return lerpf(SADDLE.y, LAKE_Y - 0.15, smoothstep(-SADDLE.x, 385.0, -z))  # down to the lake's bed


## How far out into the lake a point is: under 1 inside the ellipse.
static func lake_reach(x: float, z: float) -> float:
	return (Vector2(x - LAKE_CENTRE.x, z - LAKE_CENTRE.y) / LAKE_RADII).length()


## The bowl beyond the Downs: their far side falling away, dunes past the beach on the right, the
## bluff and its plateau on the left, the far rim, the lake (a flat bed just under the water) and
## the island.
static func _bowl(x: float, z: float) -> float:
	var e := CREST_Z - z  # distance beyond the crest
	var f := smoothstep(0.0, DOWNS_FALL, e)
	var q := lake_reach(x, z)
	var h := _valley(x, CREST_Z) * (1.0 - f)  # the Downs, falling away (meets the valley at the crest)
	h += 0.012 * pow(maxf(0.0, x - 58.0), 2.0) * f  # dunes and slopes beyond the beach
	h += BLUFF_HEIGHT * smoothstep(-BLUFF_FACE_X.x, -BLUFF_FACE_X.y, -x) * smoothstep(0.0, 30.0, e)  # the bluff and its plateau
	h += 0.03 * pow(maxf(0.0, -x - 96.0), 2.0) * smoothstep(0.0, 30.0, e)  # up to the west edge
	h += 0.013 * pow(maxf(0.0, e - 120.0), 2.0)  # the far rim (low enough that the bowl reads as open)
	h += _rolls(x, z) * f * smoothstep(1.0, 1.5, q) * (1.0 - smoothstep(40.0, 58.0, x))  # no rolls on the lake, shore or beach
	if q > 1.15:  # no ponds beyond the shore: the ground there stays above the water
		h = lerpf(h, maxf(h, LAKE_Y + 0.3), smoothstep(1.15, 1.35, q))
	var bed := LAKE_Y - 0.15
	if h > bed:
		h = bed + (h - bed) * smoothstep(0.85, 1.15, q)
	var island := Vector2(x, z).distance_to(ISLAND)
	return maxf(h, LAKE_Y + 1.2 - 3.0 * smoothstep(ISLAND_RADIUS - 2.0, ISLAND_RADIUS + 2.0, island))



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

	# Its own mesh, so it is culled when looking back toward the house.
	builder = Art.Builder.new()
	_build_bowl()
	_add_mesh("Bowl")

	_add_box_zone("Sunbeam", SUNBEAM_ORIGIN, SUNBEAM_SIZE, Thermal.Look.SUNBEAM, SUNBEAM_STRENGTH, 1.12, SUNBEAM_SUN)
	_add_box_zone("Skylight", SKYLIGHT_ORIGIN, SKYLIGHT_SIZE, Thermal.Look.SUNBEAM, SKYLIGHT_STRENGTH, 1.19, Vector3.DOWN, UP_CEILING - SKYLIGHT_ORIGIN.y)
	_add_box_zone("StairDowndraft", DOWNDRAFT_ORIGIN, DOWNDRAFT_SIZE, Thermal.Look.DOWNDRAFT, DOWNDRAFT_STRENGTH, 1.0)
	_add_thermal("RadiatorHeat", RADIATOR_THERMAL, 3.6, 7.6, Thermal.Look.WARM_AIR, 1.0, Vector3.ZERO)
	_add_thermal("KettleSteam", KETTLE_THERMAL, 3.4, KETTLE_STEAM_HEIGHT, Thermal.Look.STEAM, 1.26, KETTLE_SPOUT_TIP - KETTLE_THERMAL)
	var outdoor_zones: Array[Thermal] = []
	for t: Dictionary in OUTDOOR_THERMALS:
		var at: Vector2 = t["at"]
		var ground := ground_height(at.x, at.y)
		var base := Vector3(at.x, ground, at.y)
		var smoke: bool = t["name"] == BONFIRE_SMOKE["name"]
		var source := Vector3(BONFIRE.x, terrain_height(BONFIRE.x, BONFIRE.y) + 0.6, BONFIRE.y) - base if smoke else Vector3.ZERO
		outdoor_zones.append(_add_thermal(t["name"], base, t["radius"], float(t["top"]) - ground, Thermal.Look.STEAM if smoke else Thermal.Look.WARM_AIR, t["pitch"], source, t["strength"], true))
	_add_box_zone("RidgeLift", RIDGE_LIFT, RIDGE_LIFT_SIZE, Thermal.Look.RIDGE, RIDGE_LIFT_STRENGTH, 0.85, Vector3.DOWN, 0.0, true)
	# The bluff's seeds rise above its face (the hillside is up to y 19 at the uphill side), fewer
	# than the ridge's.
	var bluff := _add_box_zone("BluffLift", BLUFF_LIFT, BLUFF_LIFT_SIZE, Thermal.Look.RIDGE, BLUFF_LIFT_STRENGTH, 0.8, Vector3.DOWN, 0.0, true, false)
	bluff.seed_amount = 100
	bluff.seed_centre_y = 24.0
	bluff.seed_half_height = 5.0
	add_child(bluff)
	_add_box_zone("LakeSink", LAKE_SINK, LAKE_SINK_SIZE, Thermal.Look.LAKE, LAKE_SINK_STRENGTH, 1.0, Vector3.DOWN, 0.0, true)
	var birds := Birds.new()
	birds.name = "Birds"
	var crest := ground_height(RIDGE_FACE_X.y, RIDGE_LIFT.z)
	var hover: Array[Vector3] = []
	for b in RIDGE_BIRDS:
		hover.append(Vector3(b.x, crest + RIDGE_BIRDS_ABOVE_CREST, b.z))
	for b in BLUFF_BIRDS:
		hover.append(Vector3(b.x, BLUFF_HEIGHT + RIDGE_BIRDS_ABOVE_CREST, b.y))
	birds.setup(OUTDOOR_THERMALS, hover, outdoor_zones)
	add_child(birds)
	# A cumulus over each thermal, its base just above the top of the rising air.
	var clouds := Clouds.new()
	clouds.name = "Clouds"
	clouds.setup(OUTDOOR_THERMALS, outdoor_zones, CLOUD_ABOVE_TOP)
	add_child(clouds)


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


func _add_thermal(thermal_name: String, at: Vector3, radius: float, height: float, look: Thermal.Look, pitch: float, source: Vector3, strength := 1.0, outdoors := false) -> Thermal:
	var t := Thermal.new()
	t.strength_scale = strength
	t.outdoors = outdoors
	t.name = thermal_name
	t.radius = radius
	t.height = height
	t.look = look
	t.chime_pitch = pitch
	t.source_offset = source
	t.position = at
	add_child(t)
	return t


## Everything is set before add_child, because the zone builds its visuals in _ready (pass
## add false to set more first, then add it yourself).
func _add_box_zone(zone_name: String, at: Vector3, box: Vector3, look: Thermal.Look, strength: float, pitch: float, sun := Vector3.DOWN, light_height := 0.0, outdoors := false, add := true) -> Thermal:
	var zone := Thermal.new()
	zone.outdoors = outdoors
	zone.sun_direction = sun
	zone.light_height = light_height
	zone.name = zone_name
	zone.shape = Thermal.Shape.BOX
	zone.size = box
	zone.look = look
	zone.strength_scale = strength
	zone.chime_pitch = pitch
	zone.position = at
	if add:
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


func sphere(center: Vector3, radius: float, color: Color, solid := true, stretch := Vector3.ONE, segments := 9, rings := 5) -> void:
	builder.sphere(center, radius, color, stretch, segments, rings)
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
	span(Vector3(-3.0, DINING_TABLE_TOP - 0.3, -42.0), Vector3(3.0, DINING_TABLE_TOP, -48.0), Color("c8a283"))
	for leg in [Vector3(-2.7, 0, -42.3), Vector3(2.45, 0, -42.3), Vector3(-2.7, 0, -47.45), Vector3(2.45, 0, -47.45)]:
		span(leg, leg + Vector3(0.25, DINING_TABLE_TOP - 0.3, -0.25), Color("b8916f"))
	for side in [-1.0, 1.0]:
		for cz in [-43.5, -46.5]:
			var seat := Vector3(4.4 * side, 1.8, cz)
			box(seat, Vector3(1.6, 0.25, 1.6), Color("e9c6a0"))
			box(seat + Vector3(0.75 * side, 1.3, 0.0), Vector3(0.2, 2.6, 1.6), Color("e9c6a0"))
			for lx in [-0.6, 0.6]:
				for lz in [-0.6, 0.6]:
					box(Vector3(seat.x + lx, 0.9, cz + lz), Vector3(0.15, 1.8, 0.15), Color("d9b48f"), false)
	cylinder(LAMP, LAMP_SHADE_RADIUS, 0.7, 1.6, Color("f6c9b8"), true, 14)
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
	var x := -30.0
	while x <= 30.0:
		var gy := ground_height(x, fence_z)
		box(Vector3(x, gy + 1.0, fence_z), Vector3(0.35, 2.6, 0.35), TRIM)
		if x < 30.0:
			var mid_y := (gy + ground_height(x + 2.5, fence_z)) * 0.5
			for rail in [0.9, 1.8]:
				builder.box(Vector3(x + 1.25, mid_y + rail, fence_z), Vector3(2.5, 0.2, 0.15), Color("f3ece2"))
		x += 2.5

	# The hay field under the first thermal: golden rows and round bales, so the rising heat
	# has a visible cause.
	var hay: Vector2 = HAY_FIELD["at"]
	_ground_patch(hay.x - 12.0, hay.x + 12.0, hay.y + 12.0, hay.y - 12.0, 1.0, [Color("f4dc9b"), Color("e9c98a")])
	for bale: Vector2 in HAY_BALES:
		_hay_bale(bale)
	_build_barn()
	# The ploughed field: dark furrows that soak up the sun.
	var field: Vector2 = PLOUGHED_FIELD["at"]
	_ground_patch(field.x - 11.0, field.x + 11.0, field.y + 11.0, field.y - 11.0, 1.0, [Color("a88b74"), Color("94785f")])
	_build_bonfire()
	# The chalk pit at the foot of the Downs: a white scar that bakes in the sun.
	_ground_patch(CHALK_X.x, CHALK_X.y, CHALK_Z.x, CHALK_Z.y, 1.0, [Color("efe9df"), Color("e4ddd0")])
	# The picnic blanket on the plateau, in red and white stripes.
	_ground_patch(PICNIC_X.x, PICNIC_X.y, PICNIC_Z.x, PICNIC_Z.y, 1.5, [Color("f19e8f"), Color("fbf7f0")])

	# A stream across the valley with a few flat stepping stones.
	var bank := 1.3
	var sx := STREAM_X.x
	while sx < STREAM_X.y:
		var za := STREAM_Z + 2.0 * sin(sx * 0.12)
		var zb := STREAM_Z + 2.0 * sin((sx + 1.0) * 0.12)
		var water := Color("a9cfe0") if int(sx / 2.0) % 2 == 0 else Color("b8d8e6")
		for half in [1.0, 0.0]:  # in two strips across, so the water follows the grass closely
			_ground_quad(Vector3(sx, 0.0, za + bank * half), Vector3(sx + 1.0, 0.0, zb + bank * half), Vector3(sx, 0.0, za + bank * (half - 1.0)), Vector3(sx + 1.0, 0.0, zb + bank * (half - 1.0)), water)
		sx += 1.0
	for stone_x in [-3.4, -1.2, 1.1, 3.3]:
		var sz := STREAM_Z + 2.0 * sin(stone_x * 0.12)
		builder.sphere(Vector3(stone_x, terrain_height(stone_x, sz) + 0.2, sz + 0.3 * sin(stone_x * 2.0)), 0.55, Color("c9c2ba"), Vector3(1.0, 0.25, 0.8), 8, 3)

	# The lavender field, in rows with grass between.
	_ground_patch(LAVENDER_X.x, LAVENDER_X.y, LAVENDER_Z.x, LAVENDER_Z.y, 1.0, [Color("b9a6dc"), Color("d3c6ea"), Color("aed092")])

	# Trees only on the right-hand slopes, the plateau and the head wall: the valley floor and
	# the ridge face stay open to fly over.
	var trng := RandomNumberGenerator.new()
	trng.seed = 21
	for spot in tree_spots():
		if not gap_tree(spot):
			_tree(spot, trng)

	_build_windsock()
	_build_kite()
	CourseFar.build_valley(self)
	# Wind-bent grass up the ridge face: pale tufts leaning with the breeze, all along the lift.
	var grng := RandomNumberGenerator.new()
	grng.seed = 8
	for i in 260:
		var gx := grng.randf_range(-52.0, -28.0)
		var gz := grng.randf_range(RIDGE_LIFT.z - RIDGE_LIFT_SIZE.z * 0.5, RIDGE_LIFT.z + RIDGE_LIFT_SIZE.z * 0.5)
		var foot := Vector3(gx, terrain_height(gx, gz), gz)
		var tip := foot + Vector3(-1.35, 1.65, grng.randf_range(-0.3, 0.3))
		for s in [-1.0, 1.0]:
			builder.triangle(foot + Vector3(0.0, 0.0, -0.25 * s), tip, foot + Vector3(0.0, 0.0, 0.25 * s), Color("d4e6b5"))

	# Far hills and clouds (no collision), softened by the fog.
	var hills := [[-220.0, -620.0, 90.0, Color("a9c9a4")], [-60.0, -700.0, 130.0, Color("b5cfb0")], [120.0, -660.0, 110.0, Color("a7c4b8")],
		[260.0, -580.0, 80.0, Color("b9d3c2")], [10.0, -780.0, 170.0, Color("bcd2dc")], [-330.0, -540.0, 70.0, Color("b3cdb6")]]
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


# --- The bowl beyond the Gap --------------------------------------------------------

func _build_bowl() -> void:
	# The grass: the valley's grid carried on. Squares wholly under the water aren't drawn (its
	# surface covers them) but are still solid: the lake's flat bed.
	var step := TERRAIN_STEP
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var z_start := TERRAIN_ORIGIN.y - 52 * step
	for ix in 42:
		for iz in int((z_start - BOWL_END_Z) / step):
			var xa := TERRAIN_ORIGIN.x + ix * step
			var xb := xa + step
			var za := z_start - iz * step
			var zb := za - step
			var p00 := Vector3(xa, ground_height(xa, za), za)
			var p10 := Vector3(xb, ground_height(xb, za), za)
			var p01 := Vector3(xa, ground_height(xa, zb), zb)
			var p11 := Vector3(xb, ground_height(xb, zb), zb)
			if maxf(maxf(p00.y, p10.y), maxf(p01.y, p11.y)) < LAKE_Y:
				# Every corner inside the lake's ellipse: the water sheet (a 32-gon at 1.05 times its
				# radii, which holds the whole ellipse) covers the square.
				if maxf(maxf(lake_reach(xa, za), lake_reach(xb, za)), maxf(lake_reach(xa, zb), lake_reach(xb, zb))) < 1.0:
					builder.faces.append_array([p00, p01, p10, p10, p01, p11])
					continue
				# Low ground just outside the water sheet (where the Gap's stream meets the lake):
				# an inlet of water, level with the lake.
				var inlet := Color("a9cfe0")
				builder.triangle(Vector3(xa, LAKE_Y, za), Vector3(xa, LAKE_Y, zb), Vector3(xb, LAKE_Y, za), inlet)
				builder.triangle(Vector3(xb, LAKE_Y, za), Vector3(xa, LAKE_Y, zb), Vector3(xb, LAKE_Y, zb), inlet)
				builder.faces.append_array([p00, p01, p10, p10, p01, p11])
				continue
			builder.triangle(p00, p01, p10, _shore_or_grass(p00, p01, p10, rng), true)
			builder.triangle(p10, p01, p11, _shore_or_grass(p10, p01, p11, rng), true)
	_build_lake()
	# The beach: pale sand at the lake's east side, warm enough at its north end to rise.
	_ground_patch(BEACH_X.x, BEACH_X.y, BEACH_Z.x, BEACH_Z.y, 1.0, [Color("f1e3c4"), Color("ead8b0")])
	CourseFar.build_bowl(self)
	# Wind-bent grass up the bluff face, like the ridge's.
	var grng := RandomNumberGenerator.new()
	grng.seed = 9
	for i in 180:
		var gx := grng.randf_range(-70.0, -46.0)
		var gz := grng.randf_range(BLUFF_LIFT.z - BLUFF_LIFT_SIZE.z * 0.5, BLUFF_LIFT.z + BLUFF_LIFT_SIZE.z * 0.5)
		var foot := Vector3(gx, terrain_height(gx, gz), gz)
		var tip := foot + Vector3(-1.35, 1.65, grng.randf_range(-0.3, 0.3))
		for s in [-1.0, 1.0]:
			builder.triangle(foot + Vector3(0.0, 0.0, -0.25 * s), tip, foot + Vector3(0.0, 0.0, 0.25 * s), Color("d4e6b5"))


## Pale sand where the grass meets the water, so the shore follows the real waterline; a
## wildflower meadow on the far shore.
func _shore_or_grass(a: Vector3, b: Vector3, c: Vector3, rng: RandomNumberGenerator) -> Color:
	var grass := _grass(rng)
	if a.z < MEADOW_Z.x and a.z > MEADOW_Z.y and rng.randf() < 0.05:
		grass = FLOWERS[rng.randi() % FLOWERS.size()]  # with _grass()'s own 2.5%, about three times the flowers
	if minf(a.y, minf(b.y, c.y)) < LAKE_Y + 0.1 and maxf(a.y, maxf(b.y, c.y)) > LAKE_Y:  # it crosses the waterline
		return Color("efe2c6") if rng.randf() < 0.5 else Color("e6d6b4")
	return grass


## The lake: a flat sheet of water a little wider than the shoreline (looks only: the bed under it
## is what's solid) and lighter ripple stripes running with the breeze.
func _build_lake() -> void:
	var segments := 32
	var radii := LAKE_RADII * 1.05
	var centre := Vector3(LAKE_CENTRE.x, LAKE_Y, LAKE_CENTRE.y)
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		builder.triangle(centre, centre + Vector3(cos(a0) * radii.x, 0.0, sin(a0) * radii.y), centre + Vector3(cos(a1) * radii.x, 0.0, sin(a1) * radii.y), Color("a9cfe0"))
	for k in 6:
		var z := LAKE_CENTRE.y - LAKE_RADII.y * 0.75 + k * LAKE_RADII.y * 0.3
		var half := LAKE_RADII.x * sqrt(maxf(0.0, 1.0 - pow((z - LAKE_CENTRE.y) / LAKE_RADII.y, 2.0))) * 0.7
		var x0 := LAKE_CENTRE.x - half + (k % 2) * 4.0
		var x1 := LAKE_CENTRE.x + half - ((k + 1) % 2) * 4.0
		var y := LAKE_Y + PAINT_LIFT
		builder.triangle(Vector3(x0, y, z + 0.3), Vector3(x0, y, z - 0.3), Vector3(x1, y, z + 0.3), Color("c4e0ec"))
		builder.triangle(Vector3(x1, y, z + 0.3), Vector3(x0, y, z - 0.3), Vector3(x1, y, z - 0.3), Color("c4e0ec"))


func _grass(rng: RandomNumberGenerator) -> Color:
	if rng.randf() < 0.025:
		return FLOWERS[rng.randi() % FLOWERS.size()]
	return GRASS[rng.randi() % GRASS.size()]


## Trees that stood on the old head wall where the Gap now goes, or by the chalk pit: left out.
## (Trees are still placed by the old rules, then these are dropped, so the rest stay put.)
static func gap_tree(spot: Vector3) -> bool:
	if spot.z < GAP_CUT_Z.x and absf(spot.x - GAP_X) < GAP_HALF + 12.0:
		return true
	return Vector2(spot.x, spot.z).distance_to(CHALK_HEAT["at"]) < float(CHALK_HEAT["radius"]) * 1.5 + 4.0


## Where the trees stand (bases on the ground), the same every time.
static func tree_spots() -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var spots: Array[Vector3] = []
	var tries := 0
	while spots.size() < 40 and tries < 5000:
		tries += 1
		var area := rng.randi() % 3
		var x: float
		var z: float
		if area == 0:  # right-hand slopes
			x = rng.randf_range(45.0, 110.0)
			z = rng.randf_range(-100.0, -300.0)
		elif area == 1:  # the plateau behind the ridge
			x = rng.randf_range(-115.0, -72.0)
			z = rng.randf_range(-100.0, -300.0)
		else:  # the head wall
			x = rng.randf_range(-100.0, 100.0)
			z = rng.randf_range(-295.0, -330.0)
		if tree_allowed(x, z):
			spots.append(Vector3(x, ground_height(x, z), z))
	return spots


## Trees keep clear of every valley lift zone, the ridge face, the barn, the bonfire and the
## picnic. (The valley's thermals as first laid out, so the trees stay where they were; the ones
## by the chalk pit are dropped afterwards, see gap_tree().)
static func tree_allowed(x: float, z: float) -> bool:
	for t: Dictionary in VALLEY_THERMALS:
		if Vector2(x, z).distance_to(t["at"]) < float(t["radius"]) + TREE_CLEARANCE:
			return false
	for spot in [BARN, BONFIRE]:
		if Vector2(x, z).distance_to(spot) < 8.0:
			return false
	# Room to circle down onto the picnic blanket.
	if Vector2(x, z).distance_to(Vector2((PICNIC_X.x + PICNIC_X.y) * 0.5, (PICNIC_Z.x + PICNIC_Z.y) * 0.5)) < PICNIC_CLEARANCE:
		return false
	if x > RIDGE_FACE_X.y and x < RIDGE_FACE_X.x + 2.0 and z < -120.0 and z > -270.0:
		return false
	return true


## The barn under the second thermal: rose walls, a dark slate roof and a bare earth yard.
func _build_barn() -> void:
	var ground := ground_height(BARN.x, BARN.y)
	# Its floor sits at the lowest corner, so no wall floats above the slope.
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		ground = minf(ground, terrain_height(BARN.x + c.x * BARN_SIZE.x * 0.5, BARN.y + c.y * BARN_SIZE.z * 0.5))
	_ground_patch(BARN.x - 8.0, BARN.x + 8.0, BARN.y + 8.0, BARN.y - 8.0, 2.0, [Color("b8a68c"), Color("c2b195")])
	var base := Vector3(BARN.x, ground, BARN.y)
	box(base + Vector3(0.0, BARN_SIZE.y * 0.5, 0.0), BARN_SIZE, Color("d98b7a"))
	# Gable ends: a triangle of wall at each end, drawn both ways round (the roof is solid above).
	var gable := BARN_RIDGE - BARN_SIZE.y
	var half := BARN_SIZE.x * 0.5
	for z in [-BARN_SIZE.z * 0.5, BARN_SIZE.z * 0.5]:
		var l := base + Vector3(-half, BARN_SIZE.y, z)
		var r := base + Vector3(half, BARN_SIZE.y, z)
		var top := base + Vector3(0.0, BARN_RIDGE, z)
		builder.triangle(l, top, r, Color("d98b7a"))
		builder.triangle(r, top, l, Color("d98b7a"))
	# The attic between the gables is solid (a plane can't fly in under the roof).
	var attic := ConvexPolygonShape3D.new()
	var prism := PackedVector3Array()
	for z in [-BARN_SIZE.z * 0.5, BARN_SIZE.z * 0.5]:
		prism.append_array([Vector3(-half, BARN_SIZE.y, z), Vector3(half, BARN_SIZE.y, z), Vector3(0.0, BARN_RIDGE, z)])
	attic.points = prism
	solid_shape(attic, Transform3D(Basis.IDENTITY, base))
	# The two roof slopes, overhanging the walls a little.
	var slope := atan2(gable, half)
	var length := sqrt(half * half + gable * gable) + 0.6
	for s in [-1.0, 1.0]:
		var basis := Basis(Vector3.BACK, -s * slope)
		var mid := base + Vector3(s * half * 0.5, BARN_SIZE.y + gable * 0.5, 0.0) + basis * Vector3(0.0, 0.15, 0.0)
		box(mid, Vector3(length, 0.3, BARN_SIZE.z + 0.8), Color("5f5b70"), true, basis)
	# A white door on the side facing the house.
	box(base + Vector3(0.0, 1.6, BARN_SIZE.z * 0.5 + 0.03), Vector3(2.6, 3.2, 0.05), TRIM, false)


## A striped windsock on a pole by the garden fence, blown out toward -X by the breeze.
func _build_windsock() -> void:
	var foot := Vector3(WINDSOCK.x, terrain_height(WINDSOCK.x, WINDSOCK.y), WINDSOCK.y)
	builder.cylinder(foot, 0.08, 0.08, 5.0, TRIM, 6)
	var blow := Basis(Vector3.BACK, PI * 0.5 + 0.15)  # its axis points along -X, drooping a little
	var mouth := foot + Vector3(0.0, 4.8, 0.0)
	var radii := [0.45, 0.38, 0.31, 0.24]
	for i in 3:
		builder.cylinder(mouth + blow * Vector3(0.0, 0.7 * i, 0.0), radii[i], radii[i + 1], 0.7, Color("f19e8f") if i % 2 == 0 else TRIM, 8, blow)


## A big diamond kite high over the ridge, with a long ribbon tail and its string down to the
## picnic, turned to face the valley.
func _build_kite() -> void:
	var tilt := Basis(Vector3.UP, -0.9) * Basis(Vector3.RIGHT, -0.4)
	var k := KITE_SIZE / 3.0
	var top := KITE + tilt * Vector3(0.0, 1.4 * k, 0.0)
	var bottom := KITE + tilt * Vector3(0.0, -1.6 * k, 0.0)
	var left := KITE + tilt * Vector3(-1.1 * k, 0.4 * k, 0.0)
	var right := KITE + tilt * Vector3(1.1 * k, 0.4 * k, 0.0)
	for c in [[top, left, right, KITE_COLOR], [left, bottom, right, Color("f6c66f")]]:
		builder.triangle(c[0], c[1], c[2], c[3])
		builder.triangle(c[0], c[2], c[1], c[3])
	for i in 8:  # the tail's bows, 10 units of ribbon
		var at := bottom + Vector3(0.4 * i, -1.25 * (i + 1), 0.2 * sin(i))
		builder.box(at, Vector3(0.7, 0.25, 0.08), Color("b9a6dc"))
	var hold := Vector3((PICNIC_X.x + PICNIC_X.y) * 0.5, ground_height((PICNIC_X.x + PICNIC_X.y) * 0.5, (PICNIC_Z.x + PICNIC_Z.y) * 0.5) + 0.3, (PICNIC_Z.x + PICNIC_Z.y) * 0.5)
	var span := KITE - hold
	builder.box(hold + span * 0.5, Vector3(0.04, span.length(), 0.04), TRIM, Basis(Quaternion(Vector3.UP, span.normalized())))


## The leaf bonfire under the last thermal: a ring of stones, crossed logs and small flames.
func _build_bonfire() -> void:
	var base := Vector3(BONFIRE.x, terrain_height(BONFIRE.x, BONFIRE.y), BONFIRE.y)
	for i in 9:
		var a := TAU * i / 9.0
		builder.sphere(base + Vector3(cos(a) * 1.2, 0.1, sin(a) * 1.2), 0.3, Color("c9c2ba"), Vector3(1.0, 0.7, 1.0), 7, 3)
	for a in [0.3, 1.9, 3.4]:
		builder.cylinder(base + Vector3(cos(a) * 0.7, 0.05, sin(a) * 0.7), 0.12, 0.12, 1.5, Color("a88b74"), 6, Basis(Vector3(sin(a), 0.0, -cos(a)), 1.1))
	for f in [[Vector3(0.0, 0.0, 0.0), 1.1, Color("f4a46a")], [Vector3(0.3, 0.0, 0.2), 0.8, Color("f6c66f")], [Vector3(-0.3, 0.0, -0.1), 0.7, Color("ef8a6a")]]:
		builder.cylinder(base + f[0], 0.35, 0.0, f[1], f[2], 6)


## A round hay bale lying on its side, solid.
func _hay_bale(at: Vector2) -> void:
	var ground := terrain_height(at.x, at.y)
	var basis := Basis(Vector3.UP, at.x * 0.3) * Basis(Vector3.BACK, PI * 0.5)
	var centre := Vector3(at.x, ground + BALE_RADIUS * 0.9, at.y)
	builder.cylinder(centre - basis * Vector3(0.0, BALE_LENGTH * 0.5, 0.0), BALE_RADIUS, BALE_RADIUS, BALE_LENGTH, Color("e3c27e"), 10, basis)
	var shape := CylinderShape3D.new()
	shape.radius = BALE_RADIUS
	shape.height = BALE_LENGTH
	solid_shape(shape, Transform3D(basis, centre))


func _tree(base: Vector3, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.8, 1.4)
	cylinder(base - Vector3(0, 0.5, 0), 0.45 * s, 0.35 * s, 4.0 * s, Color("a88b74"), true, 7)
	if rng.randf() < 0.5:
		cylinder(base + Vector3(0, 2.5 * s, 0), 2.6 * s, 0.0, 7.0 * s, Color("8fbf9a"), true, 8)
	else:
		var leaf := Color("9cc48a") if rng.randf() < 0.5 else Color("b3d39b")
		sphere(base + Vector3(0, 5.2 * s, 0), 2.6 * s, leaf, true, Vector3(1.0, 0.9, 1.0))
		sphere(base + Vector3(1.2 * s, 4.4 * s, 0.6 * s), 1.6 * s, leaf.lightened(0.08), false)
