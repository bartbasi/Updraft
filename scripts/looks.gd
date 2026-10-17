# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Looks
extends RefCounted
## How each Hangar look is drawn (HangarCatalogue lists them): the balloon's colours, bands, gores
## or painted pattern; the paper plane's colour or printed design; their colours for the pop's
## scraps and the crumpled ball; and the icons the Hangar shows. All drawn in code: vertex colours
## and small textures painted once into an Image, cached. Looks never change flying.

const BALLOON_SEGMENTS := 24
const BALLOON_RINGS := 16
const CREAM := Color("fbf6ee")
const INK := Color("5d5468")
const RAINBOW: Array[Color] = [Color("e0484f"), Color("f29a4a"), Color("f2c14e"), Color("8fd1a8"), Color("6fb3e0"), Color("7c86d0"), Color("b9a2dc")]
const BALLOON_SOLID := {"red": "e0484f", "sky": "6fb3e0", "sunflower": "f2b63c", "mint": "8fd1a8", "lilac": "b9a2dc", "bubblegum": "f29bb8"}
## Paper colours: [the paper, its crease].
const PAPER_SOLID := {"plain": ["fbf8f1", "eee8dd"], "pink": ["f6c3d3", "ebb0c2"], "skypaper": ["b9d8f0", "a6c8e4"], "lemon": ["f6e49a", "ead489"]}
## The ground colour of each printed paper (the crumpled ball takes it).
const PAPER_GROUND := {"notebook": "fbf8f1", "graph": "f1f6ec", "newspaper": "ece8df", "map": "ead9b3", "waves": "3f4e8c"}

static var _meshes := {}
static var _materials := {}
static var _textures := {}
static var _winding := 0  ## +1 or -1: how Godot's own meshes wind their outward faces.


# --- The balloon -------------------------------------------------------------------

## The balloon's body and knot for look `id`, centred on the origin (as Flyer.build_balloon_mesh).
static func balloon_mesh(id: String) -> ArrayMesh:
	var key := "balloon:" + id
	if not _meshes.has(key):
		_meshes[key] = _build_balloon(id)
	return _meshes[key]


## Glossy rubber, with the look's painted pattern if it has one.
static func balloon_material(id: String) -> StandardMaterial3D:
	var key := "balloon:" + (id if _texture_of(id) != null else "")
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
		m.roughness = 0.35
		m.metallic_specular = 0.6
		m.albedo_texture = _texture_of(id)
		_materials[key] = m
	return _materials[key]


## The balloon's main colours (one or two), for its pop's scraps and its icon.
static func balloon_colors(id: String) -> Array[Color]:
	match id:
		"twotone":
			return [Color("6fb3e0"), CREAM]
		"candy":
			return [Color("e0484f"), CREAM]
		"polka":
			return [Color("f29bb8"), CREAM]
		"smiley":
			return [Color("f2b63c")]
		"starry":
			return [Color("2c3a6b"), CREAM]
		"rainbow":
			return [RAINBOW[0], RAINBOW[2], RAINBOW[4]]
	return [Color(BALLOON_SOLID.get(id, "e0484f"))]


static func _build_balloon(id: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var textured := _texture_of(id) != null
	var r := Flyer.BALLOON_RADIUS
	var point := func(i: int, j: int) -> Vector3:
		var theta := PI * i / BALLOON_RINGS
		var phi := TAU * j / BALLOON_SEGMENTS - PI  # j at the middle faces +z: the camera's side
		return Vector3(sin(theta) * sin(phi) * r, cos(theta) * r * Flyer.BALLOON_STRETCH, sin(theta) * cos(phi) * r)
	for i in BALLOON_RINGS:
		for j in BALLOON_SEGMENTS:
			var color := Color.WHITE if textured else _balloon_color(id, i, j)
			var a := Vector2i(i, j)
			var b := Vector2i(i, j + 1)
			var c := Vector2i(i + 1, j + 1)
			var d := Vector2i(i + 1, j)
			for tri: Array in [[a, b, c], [a, c, d]]:
				var pts: Array[Vector3] = []
				for k: Vector2i in tri:
					pts.append(point.call(k.x, k.y))
				if (pts[1] - pts[0]).cross(pts[2] - pts[0]).length_squared() < 1e-12:
					continue  # at a pole
				if signf((pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(pts[0] + pts[1] + pts[2])) != _outward_winding():
					tri = [tri[0], tri[2], tri[1]]
				st.set_color(color)
				for k: Vector2i in tri:
					st.set_uv(Vector2(float(k.y) / BALLOON_SEGMENTS, float(k.x) / BALLOON_RINGS))
					st.add_vertex(point.call(k.x, k.y))
	# The neck and knot, tapering down to where the string is tied (as Flyer's).
	var base := Color(0.8, 0.8, 0.8) if textured else balloon_colors(id)[0]
	var bottom := -r * Flyer.BALLOON_STRETCH
	var neck := Art.cylinder_triangles(0.025, 0.06, 0.05, 8)
	var neck_at := Transform3D(Basis.IDENTITY, Vector3(0.0, bottom - 0.02 + 0.025, 0.0))
	var knot := Art.sphere_triangles(0.035, 0.07, 6, 3)
	var knot_at := Transform3D(Basis.IDENTITY, Vector3(0.0, Flyer.KNOT.y + 0.015, 0.0))
	for part: Array in [[neck, neck_at, base.darkened(0.12)], [knot, knot_at, base.darkened(0.2)]]:
		st.set_color(part[2])
		var tris: PackedVector3Array = part[0]
		for t in range(0, tris.size(), 3):
			if (tris[t + 1] - tris[t]).cross(tris[t + 2] - tris[t]).length_squared() < 1e-14:
				continue  # a pole's triangle of no size has no normal: it would draw black
			for k in 3:
				st.set_uv(Vector2(0.5, 1.0))
				st.add_vertex(part[1] * tris[t + k])
	st.generate_normals()
	return st.commit()


## A plain or banded or gored balloon's colour at ring `i`, segment `j`.
static func _balloon_color(id: String, i: int, j: int) -> Color:
	match id:
		"twotone":
			return Color("6fb3e0") if i < 8 else (Color("f2b63c") if i == 8 else CREAM)
		"rainbow":
			return RAINBOW[mini(i * RAINBOW.size() / BALLOON_RINGS, RAINBOW.size() - 1)]
		"candy":
			return Color("e0484f") if (j * 8 / BALLOON_SEGMENTS) % 2 == 0 else CREAM
	return Color(BALLOON_SOLID.get(id, "e0484f"))


## +1 or -1: the sign of (b - a) x (c - a) . outward on the faces of Godot's own SphereMesh, so
## ours face the same way.
static func _outward_winding() -> float:
	if _winding == 0:
		var tris := Art.sphere_triangles(1.0, 2.0, 8, 4)
		for t in range(0, tris.size(), 3):
			var n := (tris[t + 1] - tris[t]).cross(tris[t + 2] - tris[t])
			if n.length_squared() > 1e-8:
				_winding = int(signf(n.dot(tris[t] + tris[t + 1] + tris[t + 2])))
				break
	return float(_winding)


# --- The paper plane ---------------------------------------------------------------

## The paper dart for look `id`: as Flyer.build_paper_mesh, with the look's colours and UVs
## mapped from above for a printed design.
static func paper_mesh(id: String) -> ArrayMesh:
	var key := "paper:" + id
	if not _meshes.has(key):
		_meshes[key] = _build_paper(id)
	return _meshes[key]


static func paper_material(id: String) -> StandardMaterial3D:
	var texture := _texture_of(id)
	var key := "paper:" + (id if texture != null else "")
	if not _materials.has(key):
		var m := Art.material(true).duplicate() as StandardMaterial3D
		m.albedo_texture = texture  # multiplied by the vertex colours, so the crease stays shaded
		_materials[key] = m
	return _materials[key]


## The paper's ground colour (the crumpled ball takes it).
static func paper_color(id: String) -> Color:
	if PAPER_GROUND.has(id):
		return Color(PAPER_GROUND[id])
	return Color(PAPER_SOLID.get(id, PAPER_SOLID["plain"])[0])


static func _build_paper(id: String) -> ArrayMesh:
	var colors: Array = PAPER_SOLID.get(id, PAPER_SOLID["plain"])
	var white := Color(colors[0])
	var crease := Color(colors[1])
	var tips := PAPER_SOLID.has(id)  # the felt-pen tips: on plain and coloured papers only
	var keel := Color("b8acc9")
	var lift := Vector3(0.0, Flyer.MARK_LIFT, 0.0)
	var nose := Vector3(0.0, 0.02, -0.62)
	var tail := Vector3(0.0, 0.0, 0.4)
	var keel_low := Vector3(0.0, -0.13, 0.34)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var tri := func(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
		st.set_color(color)
		for v in [a, b, c]:
			st.set_uv(Vector2(v.x + 0.5, (v.z + 0.62) / 1.04))
			st.add_vertex(v)
	for s in [-1.0, 1.0]:
		var tip := Vector3(0.5 * s, 0.08, 0.4)
		var fold := Vector3(0.2 * s, 0.025, 0.42)
		tri.call(nose, fold, tail, crease)
		tri.call(nose, tip, fold, white)
		if tips:
			tri.call(tip + lift, fold + lift, tip.lerp(nose, 0.3) + lift, Flyer.FELT_PEN)
		tri.call(nose, tail, keel_low, keel)
	st.generate_normals()
	return st.commit()


# --- Painted patterns --------------------------------------------------------------

## The look's painted texture, or null for one drawn with vertex colours.
static func _texture_of(id: String) -> ImageTexture:
	if not id in ["polka", "smiley", "starry", "notebook", "graph", "newspaper", "map", "waves"]:
		return null
	if not _textures.has(id):
		var img: Image
		match id:
			"polka": img = _paint_polka()
			"smiley": img = _paint_smiley()
			"starry": img = _paint_starry()
			"notebook": img = _paint_notebook()
			"graph": img = _paint_graph()
			"newspaper": img = _paint_newspaper()
			"map": img = _paint_map()
			_: img = _paint_waves()
		img.generate_mipmaps()
		_textures[id] = ImageTexture.create_from_image(img)
	return _textures[id]


static func _canvas(w: int, h: int, ground: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(ground)
	return img


## Fills an ellipse (radii in texels), wrapping round in x (the balloon's seam).
static func _ellipse(img: Image, at: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(floori(at.y - radius.y), ceili(at.y + radius.y) + 1):
		for x in range(floori(at.x - radius.x), ceili(at.x + radius.x) + 1):
			var d := Vector2((x - at.x) / radius.x, (y - at.y) / radius.y)
			if d.length_squared() <= 1.0 and y >= 0 and y < img.get_height():
				var px := posmod(x, img.get_width())
				img.set_pixel(px, y, img.get_pixel(px, y).lerp(Color(color, 1.0), color.a))


static func _rect(img: Image, rect: Rect2i, color: Color) -> void:
	img.fill_rect(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size())), color)


## A thick line from `a` to `b`.
static func _line(img: Image, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var steps := maxi(1, int(a.distance_to(b)))
	for k in steps + 1:
		_ellipse(img, a.lerp(b, float(k) / steps), Vector2.ONE * width * 0.5, color)


## A circle's arc from angle `from` to `to` (radians, 0 along +x, y down).
static func _arc(img: Image, centre: Vector2, radius: float, from: float, to: float, width: float, color: Color) -> void:
	var steps := maxi(4, int(radius * absf(to - from)))
	for k in steps + 1:
		var a := lerpf(from, to, float(k) / steps)
		_ellipse(img, centre + Vector2(cos(a), sin(a)) * radius, Vector2.ONE * width * 0.5, color)


## A five-pointed star of outer radius `radius` (texels), x stretched by `stretch`.
static func _star(img: Image, at: Vector2, radius: float, stretch: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI * 0.5 + PI * k / 5.0
		var rr := radius if k % 2 == 0 else radius * 0.45
		pts.append(at + Vector2(cos(a) * rr * stretch, sin(a) * rr))
	for y in range(floori(at.y - radius), ceili(at.y + radius) + 1):
		for x in range(floori(at.x - radius * stretch), ceili(at.x + radius * stretch) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), pts) and y >= 0 and y < img.get_height():
				img.set_pixel(posmod(x, img.get_width()), y, color)


## Undoes the sphere's stretch near the poles: how much wider a texel-round spot must be at row y.
static func _widen(img: Image, y: float) -> float:
	return 1.0 / maxf(sin(PI * y / img.get_height()), 0.25)


static func _paint_polka() -> Image:
	var img := _canvas(128, 64, Color("f29bb8"))
	for row in 3:
		for k in 6:
			var at := Vector2((k + 0.5 * (row % 2)) * 128.0 / 6.0, 18.0 + row * 14.0)
			_ellipse(img, at, Vector2(4.5 * _widen(img, at.y), 4.5), CREAM)
	return img


static func _paint_smiley() -> Image:
	var img := _canvas(128, 64, Color("f2b63c"))
	var mid := Vector2(64.0, 30.0)
	for side in [-1.0, 1.0]:
		_ellipse(img, mid + Vector2(7.0 * side, -5.0), Vector2(2.2, 3.4), INK)
		_ellipse(img, mid + Vector2(14.0 * side, 5.0), Vector2(3.5, 2.5), Color(Color("f29bb8"), 0.4))
	_arc(img, mid + Vector2(0.0, -1.0), 9.0, 0.35, PI - 0.35, 3.0, INK)
	return img


static func _paint_starry() -> Image:
	var img := _canvas(256, 128, Color("2c3a6b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for k in 14:
		var at := Vector2(rng.randf_range(0.0, 256.0), rng.randf_range(24.0, 104.0))
		if absf(at.x - 128.0) < 24.0 and at.y < 60.0:
			at.x += 48.0  # clear of the moon
		_star(img, at, rng.randf_range(4.5, 7.5), _widen(img, at.y), CREAM)
	var moon := Vector2(128.0, 44.0)
	_ellipse(img, moon, Vector2(13.0 * _widen(img, moon.y), 13.0), CREAM)
	_ellipse(img, moon + Vector2(6.0, -3.0), Vector2(11.0 * _widen(img, moon.y), 11.0), Color("2c3a6b"))
	return img


static func _paint_notebook() -> Image:
	var img := _canvas(128, 128, Color("fbf8f1"))
	for k in 7:
		_rect(img, Rect2i(0, 14 + k * 16, 128, 3), Color("9fc3e6"))
	_rect(img, Rect2i(14, 0, 3, 128), Color("e88b7d"))
	return img


static func _paint_graph() -> Image:
	var img := _canvas(128, 128, Color("f1f6ec"))
	for k in 11:
		var w := 4 if k % 4 == 0 else 2
		_rect(img, Rect2i(k * 12, 0, w, 128), Color("b7cfa0"))
		_rect(img, Rect2i(0, k * 12, 128, w), Color("b7cfa0"))
	return img


static func _paint_newspaper() -> Image:
	var img := _canvas(128, 128, Color("ece8df"))
	var ink := Color(INK, 0.45)
	_rect(img, Rect2i(10, 10, 108, 10), INK)  # the headline
	_rect(img, Rect2i(72, 28, 44, 34), Color("b8b2a8"))  # a picture
	for col in 3:
		var x := 10 + col * 38
		for k in 11:
			var y := 28 + k * 8
			if col == 2 and y < 66:
				continue
			_rect(img, Rect2i(x, y, 32 - (k * 7) % 9, 3), ink)
	return img


static func _paint_map() -> Image:
	var img := _canvas(128, 128, Color("ead9b3"))
	var coast := Color("7f93a8")
	var last := Vector2(0.0, 60.0)
	for x in range(4, 132, 4):
		var p := Vector2(x, 60.0 + 14.0 * sin(x * 0.07) + 6.0 * sin(x * 0.19))
		_line(img, last, p, 3.0, coast)
		last = p
	for k in 12:
		var t := float(k) / 11.0
		_ellipse(img, Vector2(lerpf(20.0, 104.0, t), lerpf(96.0, 100.0, t) - 18.0 * sin(t * PI)), Vector2(1.6, 1.6), Color("e88b7d"))
	var x_at := Vector2(108.0, 104.0)
	_line(img, x_at + Vector2(-6, -6), x_at + Vector2(6, 6), 3.0, Color("e88b7d"))
	_line(img, x_at + Vector2(-6, 6), x_at + Vector2(6, -6), 3.0, Color("e88b7d"))
	return img


static func _paint_waves() -> Image:
	var img := _canvas(128, 128, Color("3f4e8c"))
	for row in 8:
		var y := 12.0 + row * 16.0
		for k in 9:
			var centre := Vector2(k * 16.0 + (8.0 if row % 2 else 0.0), y)
			if row % 2 == 1:
				_ellipse(img, centre + Vector2(0, -2), Vector2(6.0, 4.0), Color("6fb3e0"))
			_arc(img, centre, 7.0, PI, TAU, 3.0, CREAM)
	return img


# --- Icons (the Hangar's cards) ----------------------------------------------------

## A flat picture of a balloon or paper look, laid out as its texture is (u around, v down):
## its painted pattern, or its vertex colours painted into a small image.
static func icon_texture(id: String) -> Texture2D:
	var painted := _texture_of(id)
	if painted != null:
		return painted
	var key := "icon:" + id
	if not _textures.has(key):
		var img: Image
		if HangarCatalogue.slot_of(id) == HangarCatalogue.BALLOON:
			img = Image.create(BALLOON_SEGMENTS, BALLOON_RINGS, false, Image.FORMAT_RGBA8)
			for i in BALLOON_RINGS:
				for j in BALLOON_SEGMENTS:
					img.set_pixel(j, i, _balloon_color(id, i, j))
		else:
			img = _canvas(1, 1, paper_color(id))
		_textures[key] = ImageTexture.create_from_image(img)
	return _textures[key]
