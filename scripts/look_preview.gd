# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name LookPreview
extends SubViewportContainer
## A small live picture of the flyer in its Hangar looks: the balloon (on a gently swaying string)
## or the paper plane, flying a slow level circle in its own little world with its trail streaming
## out behind. No physics and no Flyer: only the same meshes. The title shows it without a trail,
## bobbing in place (`circling` off).

const RADIUS := 0.9  ## The circle flown.
const SIZE := 1.7  ## The flyer, larger than life so the look reads.
const SPEED := 3.0
## The speed the trail is told (faster than the little circle flown), so it streams as in flight.
const TRAIL_SPEED := 9.0
const BANK := 15.0  ## Degrees, for the balloon (which leans only a quarter of it).
const PLANE_BANK := 35.0  ## Banked well over, so a paper design shows rather than its edge.

var circling := true
var _viewport: SubViewport
var _camera: Camera3D
var _flyer: Node3D
var _body: MeshInstance3D
var _string: MeshInstance3D
var _trail: Trail
var _angle := 0.0
var _time := 0.0
var _hurry := 0.0  ## Seconds of a faster lap left (a purchase).
var _balloon := true


func _init(p_circling := true) -> void:
	circling = p_circling
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = not circling  # the Hangar's has the title's sky behind it
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	light.light_energy = 1.1
	_viewport.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_SKY if circling else Environment.BG_CLEAR_COLOR
	if circling:
		var sky := ProceduralSkyMaterial.new()
		sky.sky_top_color = TitleScreen.SKY_TOP
		sky.sky_horizon_color = TitleScreen.HORIZON
		sky.ground_horizon_color = TitleScreen.HORIZON  # below the horizon too: a pale haze, not a field
		sky.ground_bottom_color = TitleScreen.HORIZON
		sky.sun_angle_max = 0.0
		env.environment.sky = Sky.new()
		env.environment.sky.sky_material = sky
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("f6e1d3")
	env.environment.ambient_light_energy = 0.7
	_viewport.add_child(env)
	_camera = Camera3D.new()
	_camera.fov = 45.0 if circling else 30.0
	_viewport.add_child(_camera)
	_flyer = Node3D.new()
	_flyer.scale = Vector3.ONE * (SIZE if circling else 1.0)
	_viewport.add_child(_flyer)
	_body = MeshInstance3D.new()
	_flyer.add_child(_body)
	_string = MeshInstance3D.new()
	var line := BoxMesh.new()  # the string, hanging from the knot (a thin box is enough here)
	line.size = Vector3(0.012, 0.5, 0.012)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Flyer.STRING_COLOR
	line.material = mat
	_string.mesh = line
	_flyer.add_child(_string)
	if circling:
		_camera.position = Vector3(0.0, 0.9, 3.6)
		_camera.look_at_from_position(_camera.position, Vector3.ZERO)
	else:
		_camera.position = Vector3(0.0, -0.05, 2.0)
		_camera.look_at_from_position(_camera.position, Vector3(0.0, -0.08, 0.0))


## Shows look `wear` (slot -> id) on the balloon or the plane.
func show_look(wear: Dictionary, balloon: bool) -> void:
	_balloon = balloon
	var b: String = wear.get(HangarCatalogue.BALLOON, "red")
	var p: String = wear.get(HangarCatalogue.PAPER, "plain")
	_body.mesh = Looks.balloon_mesh(b) if balloon else Looks.paper_mesh(p)
	_body.material_override = Looks.balloon_material(b) if balloon else Looks.paper_material(p)
	_string.visible = balloon
	_string.position = Flyer.KNOT + Vector3(0.0, -0.25, 0.0)
	var t: String = wear.get(HangarCatalogue.TRAIL, "none")
	if _trail and (_trail.id != t or not circling):
		_trail.queue_free()
		_trail = null
	if circling and t != "none" and _trail == null:
		_trail = Trail.new(t, SIZE)
		_viewport.add_child(_trail)


## Only shown, it moves: hidden (the Hangar closed) it and its trail stop, and the viewport stops
## drawing (SubViewport updates only while visible).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_ENTER_TREE:
		var on := is_visible_in_tree() if is_inside_tree() else visible
		set_process(on)
		if _trail:
			_trail.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## One faster lap (a purchase's flourish).
func hurry() -> void:
	_hurry = 1.0


func _process(delta: float) -> void:
	_time += delta
	if not circling:
		_flyer.position = Vector3(0.0, 0.0, 0.0)
		_flyer.rotation = Vector3(0.0, 0.6 * sin(_time * 0.6), deg_to_rad(3.0) * sin(_time * TAU / 4.0 + 0.8))
		return
	var speed := SPEED * (2.5 if _hurry > 0.0 else 1.0)
	_hurry = maxf(_hurry - delta, 0.0)
	_angle += speed / RADIUS * delta
	var at := Vector3(cos(_angle) * RADIUS, 0.0, sin(_angle) * RADIUS)
	var heading := PI - _angle  # along the circle (the nose is -z)
	_flyer.position = at
	_flyer.rotation = Vector3(0.0, heading, deg_to_rad(BANK * 0.25 if _balloon else PLANE_BANK))  # the balloon only leans a little, as in flight
	_flyer.scale = Vector3.ONE * SIZE
	_string.rotation = Vector3(0.05 * sin(_time * 1.3), 0.0, 0.06 * sin(_time * 1.7))
	if _trail:
		var source := _flyer.transform * (Flyer.KNOT if _balloon else Vector3(0.0, 0.0, 0.4))  # (the transform carries SIZE)
		_trail.follow(source, TRAIL_SPEED * speed / SPEED, delta)
	_camera.fov = 36.0 if size.x > size.y * 1.5 else 45.0  # a wide preview: closer in
