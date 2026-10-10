@tool
class_name Thermal
extends Node3D
## A zone of moving air. Rising air (radiator heat, kettle steam, a warm sunbeam) pushes the
## plane up; sinking air (a cool downdraft) pushes it down. The zone starts at this node's
## origin: either a vertical cylinder (`radius`, `height`) or a box (`size`, sitting on the
## origin and turning with the node). A sunbeam's box leans along `sun_direction`, so the
## lift is exactly where the light is.

enum Look { WARM_AIR, STEAM, SUNBEAM, DOWNDRAFT }
enum Shape { CYLINDER, BOX }

const COLUMN_SHADER := preload("res://shaders/thermal_column.gdshader")
const SHAFT_SHADER := preload("res://shaders/light_shaft.gdshader")

@export var shape := Shape.CYLINDER
@export var radius := 3.5
@export var height := 7.5
## Box size: width (x), height (y), depth (z). For a sunbeam this is the sunny patch on the
## floor and how high the beam's lift reaches.
@export var size := Vector3(4.0, 6.0, 4.0)
## Multiplies Tuning.thermal_strength (or Tuning.downdraft_strength for a downdraft).
@export var strength_scale := 1.0
## The downdraft look is sinking air; every other look rises.
@export var look := Look.WARM_AIR
## Pitch of the chime (or downdraft sound) played when the plane flies in.
@export var chime_pitch := 1.0
## Where the visible wisps start, relative to this node (e.g. a kettle spout).
@export var source_offset := Vector3.ZERO
## Sunbeam only: the direction the sunlight travels (down into the room), in local space.
@export var sun_direction := Vector3.DOWN
## Sunbeam only: how high the visible light reaches (0 = the zone's height), e.g. up to a
## skylight above the top of the lift.
@export var light_height := 0.0

var sinks: bool:
	get:
		return look == Look.DOWNDRAFT


## 0..1 strength at a point relative to a cylinder's base: full in the middle,
## soft toward the edge, the bottom and the top.
static func profile(local: Vector3, p_radius: float, p_height: float) -> float:
	if local.y < 0.0 or local.y > p_height:
		return 0.0
	var r := Vector2(local.x, local.z).length()
	if r >= p_radius:
		return 0.0
	var radial := 1.0 - smoothstep(p_radius * 0.55, p_radius, r)
	var bottom := smoothstep(0.0, 1.0, local.y)
	var top := 1.0 - smoothstep(p_height - 2.0, p_height, local.y)
	return radial * bottom * top


## 0..1 strength at a point relative to a box's bottom centre: full in the inner 60%,
## soft toward each side, the bottom and the top.
static func box_profile(local: Vector3, p_size: Vector3) -> float:
	var hx := p_size.x * 0.5
	var hz := p_size.z * 0.5
	if local.y < 0.0 or local.y > p_size.y or absf(local.x) >= hx or absf(local.z) >= hz:
		return 0.0
	var sides := (1.0 - smoothstep(hx * 0.6, hx, absf(local.x))) * (1.0 - smoothstep(hz * 0.6, hz, absf(local.z)))
	var bottom := smoothstep(0.0, minf(1.0, p_size.y * 0.2), local.y)
	var top_fade := minf(2.0, p_size.y * 0.25)
	var top := 1.0 - smoothstep(p_size.y - top_fade, p_size.y, local.y)
	return sides * bottom * top


## Where a point's sunbeam lands on the floor: follow the light down to height 0.
static func along_light_to_floor(local: Vector3, sun: Vector3) -> Vector3:
	var down := sun.normalized()
	var t := local.y / maxf(-down.y, 0.05)
	return Vector3(local.x + down.x * t, local.y, local.z + down.z * t)


## Strongest vertical air speed in this zone (always positive).
func peak_speed(tuning: Tuning) -> float:
	return (tuning.downdraft_strength if sinks else tuning.thermal_strength) * strength_scale


## Vertical air speed at a world position: positive rises, negative sinks.
func vertical_air_speed(world_pos: Vector3, tuning: Tuning) -> float:
	var local := global_transform.affine_inverse() * world_pos
	var amount := 0.0
	if shape == Shape.CYLINDER:
		amount = profile(local, radius, height)
	elif look == Look.SUNBEAM:
		amount = box_profile(along_light_to_floor(local, sun_direction), size)
	else:
		amount = box_profile(local, size)
	return peak_speed(tuning) * amount * (-1.0 if sinks else 1.0)


func _ready() -> void:
	add_to_group("thermals")
	if look == Look.SUNBEAM and shape != Shape.BOX:
		push_warning("%s: a sunbeam must be a box zone; using a box" % name)
		shape = Shape.BOX
	if look == Look.SUNBEAM and sun_direction.normalized().y > -0.2:
		push_warning("%s: sun_direction must point down into the room; using straight down" % name)
		sun_direction = Vector3.DOWN
	match look:
		Look.WARM_AIR, Look.STEAM:
			_build_column(Color(1.0, 0.74, 0.52, 0.6) if look == Look.WARM_AIR else Color(0.93, 0.97, 1.0, 0.45), 1.0)
		Look.SUNBEAM:
			_build_sunbeam()
		Look.DOWNDRAFT:
			_build_column(Color(0.78, 0.88, 1.0, 0.35), -1.0)
	_build_wisps()


## Soft shimmering column (or open-ended box) of moving air. `direction` -1 makes the
## streaks fall.
func _build_column(tint: Color, direction: float) -> void:
	var mesh: Mesh
	var column_height := height
	if shape == Shape.CYLINDER:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = radius * 0.8
		cylinder.bottom_radius = radius * 0.7
		cylinder.height = height
		cylinder.radial_segments = 20
		cylinder.rings = 1
		cylinder.cap_top = false
		cylinder.cap_bottom = false
		mesh = cylinder
	else:
		column_height = size.y
		mesh = _open_box(size * Vector3(0.85, 1.0, 0.85))
	var mat := ShaderMaterial.new()
	mat.shader = COLUMN_SHADER
	mat.set_shader_parameter("height", column_height)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("direction", direction)
	var column := MeshInstance3D.new()
	column.mesh = mesh
	column.material_override = mat
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.position.y = column_height * 0.5
	add_child(column)


## The four sides of a box centred on the origin, with no top or bottom (those would only
## add see-through overdraw). UV.x runs around the sides, UV.y from top to bottom.
static func _open_box(box: Vector3) -> ArrayMesh:
	var h := box * 0.5
	var corners := [Vector3(-h.x, 0, -h.z), Vector3(h.x, 0, -h.z), Vector3(h.x, 0, h.z), Vector3(-h.x, 0, h.z)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in 4:
		var a: Vector3 = corners[side]
		var b: Vector3 = corners[(side + 1) % 4]
		var u0 := side / 4.0
		var u1 := (side + 1) / 4.0
		for v in [[a, u0, 1.0], [b, u1, 1.0], [b, u1, 0.0], [a, u0, 1.0], [b, u1, 0.0], [a, u0, 0.0]]:
			st.set_uv(Vector2(v[1], v[2]))
			st.add_vertex(v[0] + Vector3(0.0, (0.5 - v[2]) * box.y, 0.0))
	st.generate_normals()
	return st.commit()


## A warm patch of sunlight on the floor and a soft shaft of light rising from it back
## toward the sun, leaning the same way as the lift.
func _build_sunbeam() -> void:
	# Drawn 0.2 inside the zone so the light never lies exactly on a wall face.
	var hx := size.x * 0.5 - 0.2
	var hz := size.z * 0.5 - 0.2
	var reach := light_height if light_height > 0.0 else size.y
	var lean := -sun_direction.normalized() * (reach / maxf(-sun_direction.normalized().y, 0.05))
	# Just above the floor and any rug on it (rugs are at most 0.1 thick).
	var floor_corners := [Vector3(-hx, 0.12, -hz), Vector3(hx, 0.12, -hz), Vector3(hx, 0.12, hz), Vector3(-hx, 0.12, hz)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_uv(Vector2(0.5, 0.0))
		st.add_vertex(floor_corners[i])
	for side in 4:
		var a: Vector3 = floor_corners[side]
		var b: Vector3 = floor_corners[(side + 1) % 4]
		for v in [[a, 0.0], [b, 0.0], [b + lean, 1.0], [a, 0.0], [b + lean, 1.0], [a + lean, 1.0]]:
			st.set_uv(Vector2(0.5, v[1]))
			st.add_vertex(v[0])
	st.generate_normals()
	var mat := ShaderMaterial.new()
	mat.shader = SHAFT_SHADER
	var shaft := MeshInstance3D.new()
	shaft.mesh = st.commit()
	shaft.material_override = mat
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft)


func _build_wisps() -> void:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = Art.soft_dot()
	quad.material = mat
	p.mesh = quad
	p.direction = Vector3.UP
	p.local_coords = false
	var fade := Gradient.new()
	match look:
		Look.WARM_AIR, Look.SUNBEAM:
			# Drifting dust motes across the whole zone; in a sunbeam they rise along the light.
			var sunny := look == Look.SUNBEAM
			# Sunbeam motes scale with the sunny patch (about one per square unit, at most 80).
			p.amount = clampi(int(size.x * size.z), 24, 80) if sunny else 110
			p.lifetime = 4.0
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = Vector3(size.x * 0.4, 0.3, size.z * 0.4) if shape == Shape.BOX else Vector3(radius * 0.6, 0.3, radius * 0.6)
			p.position = Vector3(0.0, 0.6, 0.0)
			p.direction = -sun_direction.normalized() if sunny else Vector3.UP
			p.spread = 10.0
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 1.9
			p.gravity = Vector3(0.0, 0.25, 0.0)
			quad.size = Vector2(0.35, 0.35) if sunny else Vector2(0.45, 0.45)
			p.scale_amount_min = 0.5
			p.scale_amount_max = 1.2
			fade.set_color(0, Color(1.0, 0.9, 0.7, 0.0))
			fade.set_color(1, Color(1.0, 0.95, 0.85, 0.0))
			fade.add_point(0.2, Color(1.0, 0.9, 0.6, 1.0) if sunny else Color(1.0, 0.88, 0.62, 0.9))
			fade.add_point(0.75, Color(1.0, 0.94, 0.75, 0.7) if sunny else Color(1.0, 0.92, 0.75, 0.6))
		Look.STEAM:
			# Soft steam puffs from the source that spread as they rise.
			p.amount = 56
			p.lifetime = 3.6
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 0.3
			p.position = source_offset
			p.spread = 16.0
			p.initial_velocity_min = 1.8
			p.initial_velocity_max = 2.6
			# Drift from the source toward the middle of the column as the steam rises.
			p.gravity = Vector3(-source_offset.x, 0.0, -source_offset.z) * 0.45 + Vector3(0.0, 0.3, 0.0)
			p.damping_min = 0.2
			p.damping_max = 0.4
			quad.size = Vector2(1.3, 1.3)
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.1
			var grow := Curve.new()
			grow.add_point(Vector2(0.0, 0.35))
			grow.add_point(Vector2(1.0, 2.2))
			p.scale_amount_curve = grow
			fade.set_color(0, Color(1, 1, 1, 0.0))
			fade.set_color(1, Color(1, 1, 1, 0.0))
			fade.add_point(0.15, Color(1, 1, 1, 0.6))
			fade.add_point(0.6, Color(0.97, 0.98, 1.0, 0.35))
		Look.DOWNDRAFT:
			# Pale, cool wisps drifting down from the top of the zone, fading out before
			# they reach its bottom.
			var zone_height := size.y if shape == Shape.BOX else height
			p.amount = 60
			p.lifetime = 3.2
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = Vector3(size.x * 0.4, 0.4, size.z * 0.4) if shape == Shape.BOX else Vector3(radius * 0.6, 0.4, radius * 0.6)
			p.position = Vector3(0.0, zone_height - 0.6, 0.0)
			p.direction = Vector3.DOWN
			p.spread = 8.0
			p.initial_velocity_min = zone_height / 3.2 * 0.55
			p.initial_velocity_max = zone_height / 3.2 * 0.8
			p.gravity = Vector3(0.0, -0.1, 0.0)
			quad.size = Vector2(0.5, 1.5)
			p.scale_amount_min = 0.7
			p.scale_amount_max = 1.2
			fade.set_color(0, Color(0.8, 0.9, 1.0, 0.0))
			fade.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
			fade.add_point(0.2, Color(0.78, 0.88, 1.0, 0.65))
			fade.add_point(0.7, Color(0.82, 0.9, 1.0, 0.45))
	p.color_ramp = fade
	add_child(p)
