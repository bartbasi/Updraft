# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name DebugOverlay
extends MeshInstance3D
## Testing aid for debug builds only: draws each style moment's optimal path (pink), its
## corridor (rings at the corridor edge, with an inner ring where full marks end) and the
## course centre line used for distance (blue). Hidden until toggled.

const PATH_COLOR := Color(0.95, 0.3, 0.6)
const EDGE_COLOR := Color(0.95, 0.55, 0.75)
const PERFECT_COLOR := Color(1.0, 0.85, 0.2)
const SPINE_COLOR := Color(0.3, 0.55, 0.95)


func build(scoring: Scoring, spine: PackedVector3Array) -> void:
	visible = false
	if spine.size() < 2 and scoring.moments.is_empty():
		return
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in spine.size() - 1:
		_line(lines, spine[i], spine[i + 1], SPINE_COLOR)
	for m in scoring.moments:
		for i in m.path.size() - 1:
			_line(lines, m.path[i], m.path[i + 1], PATH_COLOR)
		for i in m.path.size():
			var along := m.path[mini(i + 1, m.path.size() - 1)] - m.path[maxi(i - 1, 0)]
			_ring(lines, m.path[i], along, m.radius, EDGE_COLOR)
			_ring(lines, m.path[i], along, m.radius * scoring.tuning.style_full_fraction, PERFECT_COLOR)
	lines.surface_end()
	mesh = lines
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _line(lines: ImmediateMesh, a: Vector3, b: Vector3, color: Color) -> void:
	lines.surface_set_color(color)
	lines.surface_add_vertex(a)
	lines.surface_set_color(color)
	lines.surface_add_vertex(b)


## A circle of `radius` around `center`, facing along `along`.
func _ring(lines: ImmediateMesh, center: Vector3, along: Vector3, radius: float, color: Color) -> void:
	var forward := along.normalized() if along.length_squared() > 0.0001 else Vector3.FORWARD
	var side := forward.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = forward.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(forward).normalized()
	var segments := 20
	for i in segments:
		var a := TAU * i / segments
		var b := TAU * (i + 1) / segments
		_line(lines, center + (side * cos(a) + up * sin(a)) * radius, center + (side * cos(b) + up * sin(b)) * radius, color)
