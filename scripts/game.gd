extends Node3D
## Runs one flight: sets up the look and sound, starts the plane in the air in the bedroom
## (seen from the kid who threw it), and shows the end card with "Fly again".

const POST_SHADER := preload("res://shaders/watercolor.gdshader")
const INK := Color("5d5468")
const CREAM := Color("fbf6ee")
const LILAC := Color("c9b2d6")

@onready var course: Course = $Course
@onready var plane: PaperPlane = $Plane
@onready var camera: FollowCamera = $Camera

var reached_outside := false
var _ended := false
var _wind: AudioStreamPlayer
var _chime: AudioStreamPlayer
var _tap: AudioStreamPlayer
var _crumple: AudioStreamPlayer
var _downdraft: AudioStreamPlayer
var _ui: Control
var _card: Control
var _card_title: Label
var _card_distance: Label
var _fly_again: Button
var _hint: Label
var _fps: Label
var _fps_timer := 0.0


func _ready() -> void:
	_setup_world()
	_setup_post_fx()
	_setup_audio()
	_setup_ui()
	plane.bumped.connect(_on_bumped)
	plane.crashed.connect(_on_crashed)
	plane.stopped.connect(_on_stopped)
	plane.entered_thermal.connect(_on_entered_thermal)
	plane.launch(Course.START, Course.START_HEADING)
	plane.held = true
	camera.target = plane
	camera.start_intro(Course.KID_EYE)
	_throw_when_ready()


## The first frames can stall while shaders compile, so the plane hangs in the air until
## the game is drawing smoothly, then flies. The phone's angle then becomes "level".
func _throw_when_ready() -> void:
	var smooth_frames := 0
	var waited := 0.0
	while smooth_frames < 6 and waited < 2.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		smooth_frames = smooth_frames + 1 if get_process_delta_time() < 0.1 else 0
	plane.release()


func _process(delta: float) -> void:
	if not reached_outside and Course.is_outside(plane.global_position):
		reached_outside = true
	# Wind rises and falls with airspeed.
	var t := 0.0 if plane.is_ended() else clampf((plane.model.velocity.length() - 2.0) / 10.0, 0.0, 1.0)
	var volume := linear_to_db(lerpf(0.12, 0.7, t)) if not plane.is_ended() else -50.0
	_wind.volume_db = lerpf(_wind.volume_db, volume, 1.0 - exp(-4.0 * delta))
	_wind.pitch_scale = lerpf(_wind.pitch_scale, lerpf(0.8, 1.35, t), 1.0 - exp(-3.0 * delta))
	if _fps:
		_fps_timer -= delta
		if _fps_timer <= 0.0:
			_fps_timer = 0.5
			_fps.text = "%d fps" % Engine.get_frames_per_second()


func distance_meters() -> float:
	return plane.distance / plane.tuning.units_per_meter


# --- Events --------------------------------------------------------------------

func _on_bumped(strength: float) -> void:
	_tap.pitch_scale = randf_range(0.9, 1.15)
	_tap.volume_db = linear_to_db(clampf(strength / 4.0, 0.35, 1.0)) - 3.0
	_tap.play()
	camera.shake(0.04)


func _on_entered_thermal(zone: Thermal) -> void:
	var player := _downdraft if zone.sinks else _chime
	player.pitch_scale = zone.chime_pitch
	player.play()


func _on_crashed() -> void:
	_crumple.play()
	camera.shake(0.12)
	_finish("Crumpled!", 1.0)


func _on_stopped() -> void:
	_finish("You flew outside!" if reached_outside else "Touchdown", 0.6)


func _finish(title: String, delay: float) -> void:
	if _ended:
		return
	_ended = true
	await get_tree().create_timer(delay).timeout
	_card_title.text = title
	_card_distance.text = "Distance flown: %.1f m" % distance_meters()
	_card.visible = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.35)
	_fly_again.grab_focus()


func _on_fly_again() -> void:
	get_tree().reload_current_scene()


# --- Setup -----------------------------------------------------------------------

func _setup_world() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("9fc3e6")
	sky_mat.sky_horizon_color = Color("f6e1d3")
	sky_mat.ground_horizon_color = Color("f6e1d3")
	sky_mat.ground_bottom_color = Color("c9dcb8")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f1e7e4")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("eee6ee")
	env.fog_density = 0.0025
	env.fog_sky_affect = 0.0
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_color = Color("fff3e3")
	sun.light_energy = 0.9
	sun.shadow_enabled = false
	add_child(sun)
	# Soft bounce light from below so ceilings and undersides stay pastel, not grey.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(60.0, 150.0, 0.0)
	fill.light_color = Color("fde8dc")
	fill.light_energy = 0.5
	fill.shadow_enabled = false
	add_child(fill)


func _setup_post_fx() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = POST_SHADER
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _setup_audio() -> void:
	_wind = _player("res://audio/wind.wav", -40.0)
	_chime = _player("res://audio/chime.wav", -5.0)
	_tap = _player("res://audio/tap.wav", -3.0)
	_crumple = _player("res://audio/crumple.wav", -1.0)
	_downdraft = _player("res://audio/downdraft.wav", -4.0)
	var wind_stream := _wind.stream as AudioStreamWAV
	if wind_stream and wind_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wind_stream.loop_end = int(wind_stream.get_length() * wind_stream.mix_rate)
	_wind.play()


func _player(path: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		p.stream = load(path)
	p.volume_db = volume_db
	add_child(p)
	return p


func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = _make_theme()
	layer.add_child(_ui)

	_hint = Label.new()
	_hint.text = "Tilt to fly" if OS.has_feature("mobile") else "Arrow keys or WASD to fly"
	_hint.add_theme_font_size_override("font_size", 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position.y -= 90.0
	_ui.add_child(_hint)
	var fade := create_tween()
	fade.tween_interval(2.5)
	fade.tween_property(_hint, "modulate:a", 0.0, 1.0)

	if OS.is_debug_build():
		_fps = Label.new()
		_fps.add_theme_font_size_override("font_size", 18)
		_fps.position = Vector2(14, 10)
		_ui.add_child(_fps)

	_card = CenterContainer.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.visible = false
	_ui.add_child(_card)
	var panel := PanelContainer.new()
	_card.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 56)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)
	_card_title = Label.new()
	_card_title.add_theme_font_size_override("font_size", 52)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_card_title)
	_card_distance = Label.new()
	_card_distance.add_theme_font_size_override("font_size", 32)
	_card_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_card_distance)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	_fly_again = Button.new()
	_fly_again.text = "Fly again"
	_fly_again.custom_minimum_size = Vector2(340, 96)
	_fly_again.add_theme_font_size_override("font_size", 36)
	_fly_again.pressed.connect(_on_fly_again)
	box.add_child(_fly_again)


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_outline_color", "Label", Color(CREAM, 0.8))
	theme.set_constant("outline_size", "Label", 6)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(CREAM, 0.96)
	panel.set_corner_radius_all(28)
	panel.set_border_width_all(3)
	panel.border_color = LILAC
	panel.shadow_color = Color(0.3, 0.25, 0.35, 0.18)
	panel.shadow_size = 18
	theme.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": Color("f2c6d4"), "hover": Color("f5d2dd"), "pressed": Color("e8b3c4"), "focus": Color("f2c6d4")}[state]
		sb.set_corner_radius_all(48)
		if state == "focus":
			sb.draw_center = false
			sb.set_border_width_all(4)
			sb.border_color = LILAC
		theme.set_stylebox(state, "Button", sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "Button", INK)
	return theme
