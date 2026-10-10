class_name CourseUpstairs
extends RefCounted
## Builds the upstairs part of the course into a Course: the kids' bedroom where the run
## starts, the upper landing and long gallery, and the two-storey stair hall down to the
## living room. All positions come from the layout constants at the top of course.gd.

const BEDROOM_WALL := Color("dde8f4")
const BEDROOM_BAND := Color("f2d9e4")
const GALLERY_WALL := Color("f4e6cf")
const CARPET := Color("eadbd0")
const DOOR := Color("f7f1e8")


static func build_bedroom(c: Course) -> void:
	var f := Course.UP_FLOOR
	var top := Course.UP_CEILING
	var lo := Course.BEDROOM_MIN
	var hi := Course.BEDROOM_MAX
	var t := Course.IN_WALL
	# Floor, ceiling and walls.
	c.span(Vector3(lo.x - t, f - 0.5, lo.y - t), Vector3(hi.x + t, f, hi.y + t), CARPET)
	c.span(Vector3(lo.x - t, top, lo.y - t), Vector3(hi.x + t, top + 0.5, hi.y + t), Course.CEILING_COLOR)
	c.span(Vector3(lo.x - t, f, lo.y), Vector3(lo.x, top, hi.y + t), BEDROOM_WALL)
	c.span(Vector3(hi.x, f, lo.y), Vector3(hi.x + t, top, hi.y + t), BEDROOM_WALL)
	c.span(Vector3(lo.x, f, hi.y), Vector3(hi.x, top, hi.y + t), BEDROOM_WALL)
	# Wallpaper band and skirting.
	for wall in [[Vector3(lo.x, 18.8, lo.y), Vector3(lo.x + 0.04, 19.4, hi.y)], [Vector3(hi.x - 0.04, 18.8, lo.y), Vector3(hi.x, 19.4, hi.y)], [Vector3(lo.x, 18.8, hi.y - 0.04), Vector3(hi.x, 19.4, hi.y)]]:
		c.span(wall[0], wall[1], BEDROOM_BAND, false)
	# South wall with the wide double door: bedroom colour inside, gallery colour outside.
	var door := Course.BEDROOM_DOOR_X
	var dtop := Course.BEDROOM_DOOR_TOP
	var jamb := Course.JAMB_RADIUS
	for layer in [[lo.y - t * 0.5, lo.y, BEDROOM_WALL], [lo.y - t, lo.y - t * 0.5, GALLERY_WALL]]:
		var za: float = layer[0]
		var zb: float = layer[1]
		var color: Color = layer[2]
		c.span(Vector3(lo.x - t, f, za), Vector3(door.x - jamb, top, zb), color, false)
		c.span(Vector3(door.y + jamb, f, za), Vector3(hi.x + t, top, zb), color, false)
		c.span(Vector3(door.x - jamb, dtop, za), Vector3(door.y + jamb, top, zb), color, false)
	c.solid_span(Vector3(lo.x - t, f, lo.y - t), Vector3(door.x - jamb, top, lo.y))
	c.solid_span(Vector3(door.y + jamb, f, lo.y - t), Vector3(hi.x + t, top, lo.y))
	c.solid_span(Vector3(door.x - jamb, dtop, lo.y - t), Vector3(door.y + jamb, top, lo.y))
	# Rounded door posts: a plane that clips the edge of the doorway is turned aside instead
	# of meeting the wall face square on. What you see is exactly what you hit.
	c.doorway_posts(door.x, door.y, lo.y - t * 0.5, f, dtop)
	var leaf := (door.y - door.x) * 0.5
	for side in [[door.x - leaf, door.x - 0.4], [door.y + 0.4, door.y + leaf]]:
		var xa: float = side[0]
		var xb: float = side[1]
		c.span(Vector3(xa, f + 0.1, lo.y + 0.12), Vector3(xb, dtop - 0.2, lo.y + 0.3), DOOR, false)
		for panel_y in [[f + 1.2, f + 4.2], [f + 5.2, dtop - 1.4]]:
			c.span(Vector3(xa + 0.6, panel_y[0], lo.y + 0.3), Vector3(xb - 0.6, panel_y[1], lo.y + 0.34), Color("ede4d8"), false)
	# A paper-plane drawing pinned to the left leaf.
	_drawing(c, Vector3((door.x - leaf + door.x - 0.4) * 0.5, 18.2, lo.y + 0.36))

	_build_loft_bed(c)
	_build_furniture(c)


static func _build_loft_bed(c: Course) -> void:
	var f := Course.UP_FLOOR
	var x0 := 96.0
	var x1 := 104.0
	var z0 := 75.9
	var z1 := Course.BEDROOM_MAX.y
	var wood := Color("e4c9a8")
	for corner in [Vector2(x0, z0), Vector2(x1 - 0.4, z0), Vector2(x0, z1 - 0.4), Vector2(x1 - 0.4, z1 - 0.4)]:
		c.span(Vector3(corner.x, f, corner.y), Vector3(corner.x + 0.4, 20.6, corner.y + 0.4), wood)
	c.span(Vector3(x0, 17.4, z0), Vector3(x1, 18.2, z1), wood, false)
	c.span(Vector3(x0 + 0.2, 18.2, z0 + 0.2), Vector3(x1 - 0.2, 18.9, z1), Color("bcd3ec"), false)
	c.span(Vector3(x0 + 0.3, 18.9, z0 + 0.5), Vector3(x1 - 2.4, 19.15, z1 - 0.3), Color("f6dfa0"), false)
	c.span(Vector3(x1 - 2.2, 18.9, z0 + 0.8), Vector3(x1 - 0.5, 19.5, z1 - 0.6), Color("fbf3ea"), false)
	c.solid_span(Vector3(x0, 17.4, z0), Vector3(x1, 19.9, z1))
	# Guard rail on the open side, where the kid kneels.
	c.span(Vector3(x0, 19.5, z0), Vector3(x1, 19.9, z0 + 0.25), wood)
	for rx in [x0 + 2.0, x0 + 4.0, x0 + 6.0]:
		c.span(Vector3(rx, 18.9, z0), Vector3(rx + 0.2, 19.5, z0 + 0.2), wood, false)
	# Ladder up the east end.
	for ry in [13.6, 14.9, 16.2, 17.5]:
		c.span(Vector3(x1, ry, z0 + 0.4), Vector3(x1 + 0.25, ry + 0.2, z0 + 2.4), wood, false)
	c.span(Vector3(x1, f, z0 + 0.2), Vector3(x1 + 0.25, 19.9, z0 + 0.45), wood, false)
	c.span(Vector3(x1, f, z0 + 2.4), Vector3(x1 + 0.25, 19.9, z0 + 2.65), wood, false)
	# A cosy den under the loft: beanbag and a string of paper stars.
	c.sphere(Vector3(99.0, f + 1.0, 77.8), 1.4, Color("f2b8a2"), false, Vector3(1.2, 0.7, 1.0))
	for i in 7:
		c.sphere(Vector3(x0 + 0.8 + i * 1.05, 16.9 - absf(i - 3) * 0.15, z0 + 0.3), 0.18, Color("f4dc9b"), false)


static func _build_furniture(c: Course) -> void:
	var f := Course.UP_FLOOR
	var lo := Course.BEDROOM_MIN
	var hi := Course.BEDROOM_MAX
	# Rug in the middle of the room.
	c.span(Vector3(93.0, f, 55.0), Vector3(105.0, f + 0.05, 71.0), Color("f3c9d0"), false)
	c.span(Vector3(94.0, f, 56.0), Vector3(104.0, f + 0.08, 70.0), Color("f8e1c9"), false)
	c.span(Vector3(96.5, f, 58.5), Vector3(101.5, f + 0.1, 67.5), Color("cfe0d8"), false)
	# Second bed along the east wall.
	c.span(Vector3(102.6, f, 52.0), Vector3(hi.x, f + 1.7, 61.0), Color("e4c9a8"))
	c.span(Vector3(102.8, f + 1.7, 52.2), Vector3(hi.x, f + 2.4, 61.0), Color("cfe0d8"), false)
	c.span(Vector3(102.7, f + 2.4, 54.5), Vector3(hi.x, f + 2.6, 61.0), Color("e3b3cf"), false)
	for stripe in [56.0, 58.0, 60.0]:
		c.span(Vector3(102.65, f + 2.45, stripe), Vector3(hi.x, f + 2.65, stripe + 0.6), Color("f4dc9b"), false)
	c.span(Vector3(104.2, f + 2.4, 52.4), Vector3(107.6, f + 3.0, 54.2), Color("fbf3ea"), false)
	c.span(Vector3(102.6, f, 51.6), Vector3(hi.x, f + 4.0, 52.0), Color("e4c9a8"))
	# Window, curtains and desk on the west wall.
	_wall_window_west(c, lo.x, 16.5, 23.5, 60.0, 68.0)
	c.span(Vector3(lo.x, 15.8, 58.4), Vector3(lo.x + 0.4, 24.4, 59.8), Color("f4c7c3"), false)
	c.span(Vector3(lo.x, 15.8, 68.2), Vector3(lo.x + 0.4, 24.4, 69.6), Color("f4c7c3"), false)
	c.span(Vector3(lo.x, f + 3.3, 60.5), Vector3(lo.x + 3.2, f + 3.6, 67.5), Color("f6efe6"))
	for leg in [Vector2(lo.x + 2.8, 60.7), Vector2(lo.x + 2.8, 67.1)]:
		c.span(Vector3(leg.x, f, leg.y), Vector3(leg.x + 0.2, f + 3.3, leg.y + 0.2), Color("e4c9a8"), false)
	c.cylinder(Vector3(lo.x + 1.0, f + 3.6, 62.0), 0.35, 0.3, 0.8, Color("a9c8e8"), false)
	c.span(Vector3(lo.x + 0.8, f + 3.6, 64.0), Vector3(lo.x + 2.4, f + 3.75, 66.2), Color("fbf8f1"), false)
	c.span(Vector3(lo.x + 3.6, f, 62.6), Vector3(lo.x + 5.2, f + 2.2, 64.4), Color("f2d79b"))
	c.span(Vector3(lo.x + 4.95, f + 2.2, 62.6), Vector3(lo.x + 5.2, f + 4.6, 64.4), Color("f2d79b"))
	# Toy shelf near the loft, with blocks and a ball.
	c.span(Vector3(lo.x, f, 70.0), Vector3(lo.x + 1.8, f + 4.4, 75.0), Color("c9b2d6"))
	for i in 5:
		c.box(Vector3(lo.x + 1.0, f + 4.75, 70.6 + i * 0.95), Vector3(0.7, 0.7, 0.7), Color(Course.BOOK_COLORS[i]))
	c.sphere(Vector3(lo.x + 2.6, f + 0.7, 73.0), 0.7, Color("f19e8f"), false)
	# Play tent in the corner by the second bed.
	c.cylinder(Vector3(105.6, f, 68.5), 2.2, 0.05, 5.2, Color("f6cfa8"), true, 6)
	c.span(Vector3(104.0, f, 66.6), Vector3(105.0, f + 2.4, 66.7), Color("e9b892"), false)
	# Posters, and a mobile of paper birds hanging high in the middle of the room. The birds
	# are soft paper on strings, so the plane brushes through them (no collision).
	_poster(c, Vector3(hi.x - 0.05, 20.5, 56.5), -1.0, Color("a9c8e8"), Color("f4dc9b"))
	_poster(c, Vector3(lo.x + 0.05, 20.0, 72.5), 1.0, Color("e3b3cf"), Color("b7d8b0"))
	var mobile := Vector3(99.0, Course.UP_CEILING, 63.0)
	c.cylinder(mobile + Vector3(0, -1.6, 0), 0.03, 0.03, 1.6, Color("9b8fa6"), false, 4)
	c.box(mobile + Vector3(0, -1.65, 0), Vector3(3.0, 0.06, 0.06), Color("b9a28f"), false)
	for bird in [Vector3(-1.4, -2.4, 0.0), Vector3(1.4, -2.2, 0.0), Vector3(0.0, -2.5, 0.0)]:
		c.box(mobile + bird, Vector3(0.6, 0.05, 0.35), Color("fbf8f1"), false, Basis(Vector3.UP, 0.4))


## A bright window painted on a west wall (facing +X), with frame and cross bars.
static func _wall_window_west(c: Course, x: float, y0: float, y1: float, z0: float, z1: float) -> void:
	c.span(Vector3(x, y0, z0), Vector3(x + 0.08, y1, z1), Course.TRIM, false)
	c.span(Vector3(x + 0.08, y0 + 0.3, z0 + 0.3), Vector3(x + 0.1, y1 - 0.3, z1 - 0.3), Course.SKY_PANE, false)
	var mz := (z0 + z1) * 0.5
	var my := (y0 + y1) * 0.5
	c.span(Vector3(x + 0.1, y0 + 0.3, mz - 0.1), Vector3(x + 0.14, y1 - 0.3, mz + 0.1), Course.TRIM, false)
	c.span(Vector3(x + 0.1, my - 0.1, z0 + 0.3), Vector3(x + 0.14, my + 0.1, z1 - 0.3), Course.TRIM, false)


## A simple poster: a sky, a hill and a sun. `facing` is +1 on a west wall, -1 on an east wall.
static func _poster(c: Course, wall_point: Vector3, facing: float, sky: Color, sun: Color) -> void:
	var at := wall_point + Vector3(facing * 0.05, 0, 0)
	c.box(at, Vector3(0.05, 3.2, 2.6), Course.TRIM, false)
	c.box(at + Vector3(facing * 0.04, 0.3, 0), Vector3(0.03, 2.4, 2.2), sky, false)
	c.box(at + Vector3(facing * 0.06, -0.9, 0), Vector3(0.03, 0.8, 2.2), Color("b7d8b0"), false)
	c.box(at + Vector3(facing * 0.07, 0.8, 0.6), Vector3(0.03, 0.6, 0.6), sun, false)


## A child's drawing of a paper plane, pinned up (facing +Z).
static func _drawing(c: Course, at: Vector3) -> void:
	c.box(at, Vector3(2.4, 1.8, 0.04), Color("fbf8f1"), false)
	c.box(at + Vector3(-0.3, 0.1, 0.03), Vector3(1.2, 0.12, 0.02), Color("a9c8e8"), false, Basis(Vector3.BACK, 0.35))
	c.box(at + Vector3(0.1, -0.05, 0.03), Vector3(0.9, 0.12, 0.02), Color("a9c8e8"), false, Basis(Vector3.BACK, -0.25))
	c.box(at + Vector3(0.7, 0.55, 0.03), Vector3(0.35, 0.35, 0.02), Color("f4dc9b"), false)
	c.box(at + Vector3(0.0, 0.92, 0.03), Vector3(0.12, 0.25, 0.02), Color("f19e8f"), false)


## Upper landing outside the bedroom door, where the player banks left into the gallery.
## Its south wall angles away at 15 degrees so a late turner scrapes rather than crashes.
static func build_landing(c: Course) -> void:
	var f := Course.UP_FLOOR
	var top := Course.UP_CEILING
	var t := Course.IN_WALL
	var east := Course.LANDING_EAST_X
	var south := Course.LANDING_SOUTH_Z
	var taper_from := Course.TAPER_FROM
	var taper_to := Course.TAPER_TO
	var north := Course.GALLERY_Z.y
	# Floor and ceiling over the landing and the taper.
	_planks(c, taper_to.x, east + t, south - t, north)
	c.solid_span(Vector3(taper_to.x, f - 0.5, south - t), Vector3(east + t, f, north))
	c.span(Vector3(taper_to.x, top, south - t), Vector3(east + t, top + 0.5, north), Course.CEILING_COLOR)
	# East end wall, the landing's south wall, and the north wall from the bedroom's corner
	# back to where the gallery starts.
	c.span(Vector3(east, f, south - t), Vector3(east + t, top, north), GALLERY_WALL)
	c.span(Vector3(taper_to.x, f, north), Vector3(Course.BEDROOM_MIN.x - t, top, north + t), GALLERY_WALL)
	c.span(Vector3(taper_to.x, f, north - 0.12), Vector3(Course.BEDROOM_MIN.x - t, f + 0.6, north), Color("e8d6bc"), false)
	c.span(Vector3(taper_from.x, f, south - t), Vector3(east + t, top, south), GALLERY_WALL)
	# The taper: a straight wall from the landing's corner back to the gallery's south wall.
	var along := Vector3(taper_to.x - taper_from.x, 0.0, taper_to.y - taper_from.y)
	var length := along.length()
	var dir := along / length
	var inward := Vector3(dir.z, 0.0, -dir.x)
	if inward.z < 0.0:
		inward = -inward
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	var mid := Vector3((taper_from.x + taper_to.x) * 0.5, (f + top) * 0.5, (taper_from.y + taper_to.y) * 0.5) - inward * t * 0.5
	# Lengthened only at the landing end (to seal that corner); the gallery end stops flush.
	mid -= dir * t * 0.25
	c.box(mid, Vector3(length + t * 0.5, top - f, t), GALLERY_WALL, true, basis)
	c.box(mid + inward * 0.27 + Vector3(0, f + 0.3 - (f + top) * 0.5, 0), Vector3(length, 0.6, 0.04), Color("e8d6bc"), false, basis)
	# The tall window the sunbeam comes through, set into the angled wall.
	# Painted flush on the wall with no collision, so a late turner still scrapes a flat wall.
	var wx := Course.SUNBEAM_WINDOW_X
	var wy := Course.SUNBEAM_WINDOW_Y
	var along_t := ((wx.x + wx.y) * 0.5 - taper_from.x) / (taper_to.x - taper_from.x)
	var window_mid := Vector3(lerpf(taper_from.x, taper_to.x, along_t), (wy.x + wy.y) * 0.5, lerpf(taper_from.y, taper_to.y, along_t)) + inward * 0.03
	var width := (wx.y - wx.x) / absf(dir.x)
	var tall := wy.y - wy.x
	c.box(window_mid, Vector3(width, tall, 0.06), Course.TRIM, false, basis)
	c.box(window_mid + inward * 0.04, Vector3(width - 0.6, tall - 0.6, 0.04), Color("fff4d6"), false, basis)
	for bar in [-0.25, 0.0, 0.25]:
		c.box(window_mid + inward * 0.07 + dir * width * bar, Vector3(0.18, tall - 0.6, 0.04), Course.TRIM, false, basis)
	c.box(window_mid + inward * 0.07 + Vector3(0, tall * 0.15, 0), Vector3(width - 0.6, 0.18, 0.04), Course.TRIM, false, basis)
	# Skirting along the landing.
	c.span(Vector3(taper_from.x, f, south), Vector3(east, f + 0.6, south + 0.12), Color("e8d6bc"), false)
	c.span(Vector3(east - 0.12, f, south), Vector3(east, f + 0.6, north), Color("e8d6bc"), false)
	# A low laundry basket and a picture on the end wall; nothing tall near the turn.
	c.cylinder(Vector3(106.6, f, 36.0), 1.0, 1.1, 1.8, Color("e9d7b6"), true, 10)
	c.span(Vector3(105.8, f + 1.6, 35.4), Vector3(107.2, f + 2.1, 36.6), Color("a9c8e8"), false)
	_poster(c, Vector3(east - 0.05, 19.5, 39.5), -1.0, Color("f6cfa8"), Color("f19e8f"))


## Floor boards running along the gallery (x), between two x and two z values.
static func _planks(c: Course, x0: float, x1: float, z0: float, z1: float) -> void:
	var z := z0
	var i := 0
	while z < z1:
		var z_next := minf(z + 1.0, z1)
		c.span(Vector3(x0, Course.UP_FLOOR - 0.5, z), Vector3(x1, Course.UP_FLOOR, z_next), Color("e3c8a5") if i % 2 == 0 else Color("dcc09b"), false)
		z = z_next
		i += 1


## The long sunny gallery from the landing to the stair hall: a straight glide with
## something to see every few seconds (a closed door, pictures, a hall table, the skylight).
static func build_gallery(c: Course) -> void:
	var f := Course.UP_FLOOR
	var top := Course.UP_CEILING
	var t := Course.IN_WALL
	var x0 := Course.STAIR_HALL_MAX.x  # west end, where the gallery floor becomes the stairs
	var x1 := Course.TAPER_TO.x
	var south := Course.GALLERY_Z.x
	var north := Course.GALLERY_Z.y
	_planks(c, x0, x1, south - t, north)
	c.solid_span(Vector3(x0, f - 0.5, south - t), Vector3(x1, f, north))
	c.span(Vector3(x0, top, south - t), Vector3(x1, top + 0.5, north + t), Course.CEILING_COLOR)
	# Long walls: they meet the landing's north wall and the taper at x1.
	c.span(Vector3(x0, f, north), Vector3(x1, top, north + t), GALLERY_WALL)
	c.span(Vector3(x0, f, south - t), Vector3(x1, top, south), GALLERY_WALL)
	c.span(Vector3(x0, f, north - 0.12), Vector3(x1, f + 0.6, north), Color("e8d6bc"), false)
	c.span(Vector3(x0, f, south), Vector3(x1, f + 0.6, south + 0.12), Color("e8d6bc"), false)
	# Striped runner down the middle: the stripes stream past and show your speed.
	var stripe := x0
	var i := 0
	while stripe < x1:
		var next := minf(stripe + 2.0, x1)
		c.span(Vector3(stripe, f, 39.6), Vector3(next, f + 0.04, 43.4), Color("f3c9d0") if i % 2 == 0 else Color("f8efe0"), false)
		stripe = next
		i += 1
	# Beat 1 (x 66): a sibling's closed door with light under it, and a big picture opposite.
	c.span(Vector3(63.6, f, north - 0.2), Vector3(68.4, f + 9.6, north), Course.TRIM, false)
	c.span(Vector3(64.0, f + 0.25, north - 0.28), Vector3(68.0, f + 9.2, north - 0.18), Color("c7e0d6"), false)
	c.span(Vector3(64.2, f, north - 0.3), Vector3(67.8, f + 0.22, north - 0.25), Color("fff3cf"), false)
	c.sphere(Vector3(67.3, f + 4.6, north - 0.4), 0.18, Color("e0a63c"), false)
	_picture_south(c, Vector3(66.0, 18.5, south), 6.0, 4.0, Color("a9c8e8"), Color("b7d8b0"))
	# Beat 2 (x 30): a hall table with a plant, and a row of family photos opposite.
	# Everything on and under the table is solid: what you see is what you hit.
	c.span(Vector3(26.5, f + 3.2, north - 2.0), Vector3(33.5, f + 3.5, north), Color("e4c9a8"))
	for leg in [26.7, 33.1]:
		c.span(Vector3(leg, f, north - 1.8), Vector3(leg + 0.2, f + 3.2, north - 1.6), Color("d3b898"))
	c.cylinder(Vector3(28.5, f + 3.5, north - 1.0), 0.45, 0.6, 0.9, Color("e2a888"))
	c.sphere(Vector3(28.5, f + 5.0, north - 1.0), 0.9, Color("9cc48a"), true, Vector3(1.0, 1.1, 1.0))
	c.box(Vector3(31.5, f + 4.2, north - 0.9), Vector3(1.2, 1.4, 0.15), Color("f6cfa8"))
	for k in 5:
		_picture_south(c, Vector3(20.0 + k * 3.5, 19.0 + (k % 2) * 0.8, south), 2.2, 1.8, Color(Course.BOOK_COLORS[k]), Color("fbf3ea"))
	# Skylight halfway along: a bright square in the ceiling over the right-hand half.
	var sky := Course.SKYLIGHT_ORIGIN
	var sky_size := Course.SKYLIGHT_SIZE
	# The pane matches the light shaft below it (the zone, 0.2 in from each side).
	var pane := Vector2(sky_size.x * 0.5 - 0.2, sky_size.z * 0.5 - 0.2)
	c.span(Vector3(sky.x - pane.x, top - 0.06, sky.z - pane.y), Vector3(sky.x + pane.x, top, sky.z + pane.y), Course.SKY_PANE, false)
	c.span(Vector3(sky.x - pane.x - 0.3, top - 0.1, sky.z - 0.1), Vector3(sky.x + pane.x + 0.3, top - 0.04, sky.z + 0.1), Course.TRIM, false)


## A framed picture hung on the gallery's south wall (facing +Z).
static func _picture_south(c: Course, wall_point: Vector3, width: float, height: float, sky: Color, land: Color) -> void:
	var at := wall_point + Vector3(0, 0, 0.08)
	c.box(at, Vector3(width, height, 0.12), Color("b9a28f"), false)
	c.box(at + Vector3(0, height * 0.12, 0.07), Vector3(width - 0.5, height * 0.55, 0.02), sky, false)
	c.box(at + Vector3(0, -height * 0.29, 0.07), Vector3(width - 0.5, height * 0.24, 0.02), land, false)
