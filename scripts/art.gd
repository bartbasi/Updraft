# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Art
extends RefCounted
## Shared look: materials, a soft-dot texture, and a builder that packs low-poly,
## flat-shaded, vertex-coloured shapes into a single mesh (one draw call).

static var _materials := {}
static var _soft_dot: GradientTexture2D


## Material for vertex-coloured meshes: soft wrap lighting, no shine.
static func material(double_sided := false) -> StandardMaterial3D:
	if not _materials.has(double_sided):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.roughness = 1.0
		if double_sided:
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[double_sided] = m
	return _materials[double_sided]


## A white dot that fades to transparent at the edge; used for particles and soft shadows.
static func soft_dot() -> GradientTexture2D:
	if _soft_dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.55))
		_soft_dot = GradientTexture2D.new()
		_soft_dot.gradient = g
		_soft_dot.fill = GradientTexture2D.FILL_RADIAL
		_soft_dot.fill_from = Vector2(0.5, 0.5)
		_soft_dot.fill_to = Vector2(1.0, 0.5)
		_soft_dot.width = 64
		_soft_dot.height = 64
	return _soft_dot


## Unit shapes' triangles (see triangles()), by kind and segments.
static var _units := {}


## A primitive mesh's triangles, a vertex per corner, as get_mesh_arrays() and its indices give
## them, but without asking the renderer: get_mesh_arrays() builds the mesh on the rendering server
## and reads it back, a round trip that costs a phone milliseconds a shape. Boxes, cylinders (no
## rings) and spheres are scaled from a unit shape made once; tori are made once per size; anything
## else is made each time.
static func triangles(mesh: PrimitiveMesh) -> PackedVector3Array:
	if mesh is BoxMesh and mesh.subdivide_width == 0 and mesh.subdivide_height == 0 and mesh.subdivide_depth == 0:
		return box_triangles(mesh.size)
	if mesh is CylinderMesh and mesh.rings == 0 and mesh.cap_top and mesh.cap_bottom:
		return cylinder_triangles(mesh.bottom_radius, mesh.top_radius, mesh.height, mesh.radial_segments)
	if mesh is SphereMesh and not mesh.is_hemisphere:
		return sphere_triangles(mesh.radius, mesh.height, mesh.radial_segments, mesh.rings)
	if mesh is TorusMesh:
		return torus_triangles(mesh.inner_radius, mesh.outer_radius, mesh.rings, mesh.ring_segments)
	return _expand(mesh)


static func box_triangles(size: Vector3) -> PackedVector3Array:
	var out := _unit(&"box", 0, 0).duplicate()
	for i in out.size():
		out[i] *= size
	return out


## Side and caps, as CylinderMesh makes them; a cap of no radius is left out, as are the side's
## triangles that come to nothing at a point.
static func cylinder_triangles(bottom_radius: float, top_radius: float, height: float, segments: int) -> PackedVector3Array:
	var unit := _unit(&"cylinder", segments, 0)
	var out := PackedVector3Array()
	out.resize(unit.size())
	var n := 0
	var corner: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	for t in range(0, unit.size(), 3):
		for c in 3:
			var v := unit[t + c]
			var r := top_radius if v.y > 0.0 else bottom_radius
			corner[c] = Vector3(v.x * r, v.y * height, v.z * r)
		if corner[0] == corner[1] or corner[1] == corner[2] or corner[0] == corner[2]:
			continue
		for c in 3:
			out[n] = corner[c]
			n += 1
	out.resize(n)
	return out


## A torus is made once for each size (making a mesh at all asks the renderer). The array returned
## is the cached one: read it, never change it.
static func torus_triangles(inner_radius: float, outer_radius: float, rings: int, ring_segments: int) -> PackedVector3Array:
	var key := "torus:%s:%s:%d:%d" % [inner_radius, outer_radius, rings, ring_segments]
	if not _units.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner_radius
		m.outer_radius = outer_radius
		m.rings = rings
		m.ring_segments = ring_segments
		_units[key] = _expand(m)
	return _units[key]


static func sphere_triangles(radius: float, height: float, segments: int, rings: int) -> PackedVector3Array:
	var out := _unit(&"sphere", segments, rings).duplicate()
	var scale := Vector3(radius, height * 0.5, radius)
	for i in out.size():
		out[i] *= scale
	return out


## A unit box (size 1), cylinder (radii 1, height 1) or sphere (radius 1, height 2).
static func _unit(kind: StringName, segments: int, rings: int) -> PackedVector3Array:
	var key := "%s:%d:%d" % [kind, segments, rings]
	if not _units.has(key):
		var m: PrimitiveMesh
		match kind:
			&"box":
				m = BoxMesh.new()
				m.size = Vector3.ONE
			&"cylinder":
				m = CylinderMesh.new()
				m.top_radius = 1.0
				m.bottom_radius = 1.0
				m.height = 1.0
				m.radial_segments = segments
				m.rings = 0
			&"sphere":
				m = SphereMesh.new()
				m.radius = 1.0
				m.height = 2.0
				m.radial_segments = segments
				m.rings = rings
		_units[key] = _expand(m)
	return _units[key]


static func _expand(mesh: PrimitiveMesh) -> PackedVector3Array:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var out := PackedVector3Array()
	for i: int in arrays[Mesh.ARRAY_INDEX]:
		out.append(verts[i])
	return out


## Packs shapes into one flat-shaded mesh. Colours are sRGB and stored per vertex.
class Builder:
	var st := SurfaceTool.new()
	var faces := PackedVector3Array()  ## Triangles of every solid shape, for trimesh collision.

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)

	func add(mesh: PrimitiveMesh, xform: Transform3D, color: Color, solid := false) -> void:
		add_triangles(Art.triangles(mesh), xform, color, solid)

	## Triangles, a vertex per corner (see Art.triangles()).
	func add_triangles(tris: PackedVector3Array, xform: Transform3D, color: Color, solid := false) -> void:
		st.set_color(color)
		for v0 in tris:
			var v := xform * v0
			st.add_vertex(v)
			if solid:
				faces.append(v)

	func box(center: Vector3, size: Vector3, color: Color, basis := Basis.IDENTITY) -> void:
		add_triangles(Art.box_triangles(size), Transform3D(basis, center), color)

	## Cylinder or cone standing on `base` (bottom centre).
	func cylinder(base: Vector3, bottom_radius: float, top_radius: float, height: float, color: Color, segments := 10, basis := Basis.IDENTITY) -> void:
		add_triangles(Art.cylinder_triangles(bottom_radius, top_radius, height, segments), Transform3D(basis, base + basis * Vector3(0.0, height * 0.5, 0.0)), color)

	func sphere(center: Vector3, radius: float, color: Color, stretch := Vector3.ONE, segments := 9, rings := 5) -> void:
		add_triangles(Art.sphere_triangles(radius, radius * 2.0, segments, rings), Transform3D(Basis.from_scale(stretch), center), color)

	## Godot treats clockwise triangles as front-facing.
	func triangle(a: Vector3, b: Vector3, c: Vector3, color: Color, solid := false) -> void:
		st.set_color(color)
		for v in [a, b, c]:
			st.add_vertex(v)
			if solid:
				faces.append(v)

	func commit() -> ArrayMesh:
		st.generate_normals()
		return st.commit()
