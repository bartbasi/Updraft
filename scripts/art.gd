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


## Packs shapes into one flat-shaded mesh. Colours are sRGB and stored per vertex.
class Builder:
	var st := SurfaceTool.new()
	var faces := PackedVector3Array()  ## Triangles of every solid shape, for trimesh collision.

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)

	func add(mesh: PrimitiveMesh, xform: Transform3D, color: Color, solid := false) -> void:
		var arrays := mesh.get_mesh_arrays()
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		st.set_color(color)
		for i in indices:
			var v := xform * verts[i]
			st.add_vertex(v)
			if solid:
				faces.append(v)

	func box(center: Vector3, size: Vector3, color: Color, basis := Basis.IDENTITY) -> void:
		var m := BoxMesh.new()
		m.size = size
		add(m, Transform3D(basis, center), color)

	## Cylinder or cone standing on `base` (bottom centre).
	func cylinder(base: Vector3, bottom_radius: float, top_radius: float, height: float, color: Color, segments := 10, basis := Basis.IDENTITY) -> void:
		var m := CylinderMesh.new()
		m.bottom_radius = bottom_radius
		m.top_radius = top_radius
		m.height = height
		m.radial_segments = segments
		m.rings = 0
		add(m, Transform3D(basis, base + basis * Vector3(0.0, height * 0.5, 0.0)), color)

	func sphere(center: Vector3, radius: float, color: Color, stretch := Vector3.ONE, segments := 9, rings := 5) -> void:
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = segments
		m.rings = rings
		add(m, Transform3D(Basis.from_scale(stretch), center), color)

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
