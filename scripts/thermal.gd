@tool
class_name Thermal
extends Node3D
## A column of rising warm air (radiator heat, kettle steam...). Inside it the plane is
## pushed upward. The column starts at this node's origin and rises `height` units.

enum Look { WARM_AIR, STEAM }

const COLUMN_SHADER := preload("res://shaders/thermal_column.gdshader")

@export var radius := 3.5
@export var height := 7.5
## Multiplies Tuning.thermal_strength for this thermal.
@export var strength_scale := 1.0
@export var look := Look.WARM_AIR
## Pitch of the chime played when the plane flies in.
@export var chime_pitch := 1.0
## Where the visible wisps start, relative to this node (e.g. a kettle spout).
@export var source_offset := Vector3.ZERO


## 0..1 lift at a point relative to the column base: full in the middle,
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


## Upward air speed at a world position.
func updraft_at(world_pos: Vector3, base_strength: float) -> float:
	return base_strength * strength_scale * profile(world_pos - global_position, radius, height)


func _ready() -> void:
	add_to_group("thermals")
	_build_column()
	_build_wisps()


func _build_column() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.8
	mesh.bottom_radius = radius * 0.7
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 1
	mesh.cap_top = false
	mesh.cap_bottom = false
	var mat := ShaderMaterial.new()
	mat.shader = COLUMN_SHADER
	mat.set_shader_parameter("height", height)
	mat.set_shader_parameter("tint", Color(1.0, 0.74, 0.52, 0.6) if look == Look.WARM_AIR else Color(0.93, 0.97, 1.0, 0.45))
	var column := MeshInstance3D.new()
	column.mesh = mesh
	column.material_override = mat
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.position.y = height * 0.5
	add_child(column)


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
	if look == Look.WARM_AIR:
		# Drifting dust motes and heat haze across the whole column.
		p.amount = 110
		p.lifetime = 4.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(radius * 0.6, 0.3, radius * 0.6)
		p.position = Vector3(0.0, 0.6, 0.0)
		p.spread = 10.0
		p.initial_velocity_min = 1.0
		p.initial_velocity_max = 1.9
		p.gravity = Vector3(0.0, 0.25, 0.0)
		quad.size = Vector2(0.45, 0.45)
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.2
		fade.set_color(0, Color(1.0, 0.9, 0.7, 0.0))
		fade.set_color(1, Color(1.0, 0.95, 0.85, 0.0))
		fade.add_point(0.2, Color(1.0, 0.88, 0.62, 0.9))
		fade.add_point(0.75, Color(1.0, 0.92, 0.75, 0.6))
	else:
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
	p.color_ramp = fade
	add_child(p)
