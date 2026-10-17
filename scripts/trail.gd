# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Trail
extends Node3D
## A Hangar trail streaming out behind the flyer, in world space so it stays where it was left:
## a ribbon (the last moments of the path, facing the camera with a gentle twist, longer the
## faster you go) or falling paper confetti or blossom petals. Each fades out near the camera so a
## straight glide (the trail running back toward the eye) never fills the view. Owner: the Flyer,
## or the Hangar's preview; either calls follow() every tick with where it comes from and how fast.

const FADE_NEAR := 0.8  ## Fully faded this close to the camera.
const FADE_FAR := 2.0  ## Fully shown from here.
const SLOW := 4.0  ## Speeds (u/s) for the slowest and fullest trail.
const FAST := 14.0
const MAX_POINTS := 64
## Confetti's five colours (no gold: that's the stars').
const CONFETTI: Array[Color] = [Color("e88b7d"), Color("6fb3e0"), Color("f29bb8"), Color("8fd1a8"), Color("b9a2dc")]

var id := "none"
var _ribbon: ImmediateMesh
var _ribbon_mesh: MeshInstance3D
var _particles: CPUParticles3D
var _points: Array[Vector3] = []
var _times: Array[float] = []
var _clock := 0.0
var _speed := 0.0
var _on := true
var _scale := 1.0  ## Drawn larger (the Hangar's preview shows a flyer larger than life).


func _init(p_id: String, p_scale := 1.0) -> void:
	id = p_id
	_scale = p_scale
	top_level = true  # world space
	match id:
		"ribbon", "rainbowtrail":
			_ribbon = ImmediateMesh.new()
			_ribbon_mesh = MeshInstance3D.new()
			_ribbon_mesh.mesh = _ribbon
			_ribbon_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_ribbon_mesh.material_override = _material(_rainbow_bands() if id == "rainbowtrail" else null)
			add_child(_ribbon_mesh)
		"confetti", "petals":
			_particles = _build_particles(id == "petals")
			add_child(_particles)


## Each tick: the trail comes from `at`, moving at `speed`.
func follow(at: Vector3, speed: float, delta: float) -> void:
	_clock += delta
	_speed = speed
	var more := remap(clampf(speed, SLOW, FAST), SLOW, FAST, 0.6, 1.6)  # a dive streams
	if _particles:
		_particles.global_position = at
		_particles.speed_scale = more  # (CPU particles have no emission ratio: the whole stream quickens)
		_particles.emitting = _on
	if _ribbon and _on:
		_points.append(at)
		_times.append(_clock)
		var keep := (0.6 if id == "rainbowtrail" else 0.5) * more
		while _times.size() > 2 and (_clock - _times[0] > keep or _points.size() > MAX_POINTS):
			_points.pop_front()
			_times.pop_front()


## Stops streaming (a crash); what's out fades away.
func stop() -> void:
	_on = false
	if _particles:
		_particles.emitting = false


## Starts afresh (a new flight).
func restart() -> void:
	_on = true
	_points.clear()
	_times.clear()
	if _particles:
		_particles.restart()


## How many particles at most (the budget is 48).
func particle_count() -> int:
	return _particles.amount if _particles else 0


func _process(delta: float) -> void:
	if not _ribbon:
		return
	if not _on and not _times.is_empty():  # after a crash it shrinks away
		_clock += delta
		while not _times.is_empty() and _clock - _times[0] > 0.5:
			_points.pop_front()
			_times.pop_front()
	_ribbon.clear_surfaces()
	if _points.size() < 2:
		return
	var camera := get_viewport().get_camera_3d()
	var eye := camera.global_position if camera else _points[-1] + Vector3.BACK * 10.0
	var rainbow := id == "rainbowtrail"
	var color := Color.WHITE if rainbow else Color("f29bb8")  # the rainbow's bands are its texture's, across the strip
	var half := (0.26 if rainbow else 0.10) * 0.5 * _scale
	var n := _points.size()
	_ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in n:
		var p := _points[i]
		var along := _points[mini(i + 1, n - 1)] - _points[maxi(i - 1, 0)]
		var side := along.cross(eye - p)
		side = side.normalized() if side.length_squared() > 1e-10 else Vector3.RIGHT
		if along.length_squared() > 1e-10:
			side = side.rotated(along.normalized(), deg_to_rad(20.0) * sin(_times[i] * 2.0))  # a gentle twist
		var fade := Color(color, 0.9 * i / (n - 1))  # transparent at the old end
		_ribbon.surface_set_color(fade)
		_ribbon.surface_set_uv(Vector2(0.0, 0.5))
		_ribbon.surface_add_vertex(p - side * half)
		_ribbon.surface_set_color(fade)
		_ribbon.surface_set_uv(Vector2(1.0, 0.5))
		_ribbon.surface_add_vertex(p + side * half)
	_ribbon.surface_end()


## A petal: a hard-edged oval (a soft dot would read as a thermal's mote).
static func _petal_shape() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for y in 32:
		for x in 32:
			if Vector2((x - 15.5) / 15.5, (y - 15.5) / 15.5).length_squared() <= 1.0:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)


## The rainbow's seven bands, across a strip.
static func _rainbow_bands() -> ImageTexture:
	var img := Image.create(Looks.RAINBOW.size(), 1, false, Image.FORMAT_RGBA8)
	for k in Looks.RAINBOW.size():
		img.set_pixel(k, 0, Looks.RAINBOW[k])
	return ImageTexture.create_from_image(img)


static func _material(texture: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.albedo_texture = texture
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # crisp bands
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = FADE_NEAR
	m.distance_fade_max_distance = FADE_FAR
	return m


## Squares of paper in five colours that tumble as they fall, or soft pink petals that flutter.
func _build_particles(petals: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.local_coords = false
	p.amount = 14 if petals else 13
	p.lifetime = 1.2 if petals else 0.9
	p.direction = Vector3.DOWN
	p.spread = 35.0 if petals else 20.0
	p.initial_velocity_min = 0.3 if petals else 0.5
	p.initial_velocity_max = 0.5 if petals else 0.7
	p.gravity = Vector3.ZERO
	p.angular_velocity_min = -120.0 if petals else -400.0
	p.angular_velocity_max = 120.0 if petals else 400.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	if petals:  # they drift down gently, slowing
		p.gravity = Vector3(0.0, 0.0, 0.0)
		p.damping_min = 0.1
		p.damping_max = 0.3
	var quad := QuadMesh.new()
	quad.size = (Vector2(0.13, 0.08) if petals else Vector2(0.06, 0.06)) * _scale
	var mat := _material(_petal_shape() if petals else null)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = mat
	p.mesh = quad
	# Pink petals and no gold confetti: pale specks read as thermal motes, and gold as stars.
	var palette := PackedColorArray([Color("f29bb8"), Color("f6c3d3")]) if petals else PackedColorArray(CONFETTI)
	var colors := Gradient.new()  # each particle takes one of the palette's colours (set as the thermals' are)
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.set_color(0, palette[0])
	colors.set_offset(1, float(palette.size() - 1) / palette.size())  # each colour an equal share
	colors.set_color(1, palette[palette.size() - 1])
	for k in range(1, palette.size() - 1):
		colors.add_point(float(k) / palette.size(), palette[k])
	p.color_initial_ramp = colors
	var fade := Gradient.new()  # whole for most of its life, then gone
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.7, Color.WHITE)
	p.color_ramp = fade
	return p
