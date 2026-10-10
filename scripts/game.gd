extends Node3D
## Runs one flight: sets up the look and sound, starts the plane in the air in the bedroom
## (seen from the kid who threw it), keeps score, and shows the end card with distance,
## style, total, best and "Fly again".

const POST_SHADER := preload("res://shaders/watercolor.gdshader")
const INK := Color("5d5468")
const CREAM := Color("fbf6ee")
const LILAC := Color("c9b2d6")
const GOLD := Color("e0a63c")

@onready var course: Course = $Course
@onready var plane: PaperPlane = $Plane
@onready var camera: FollowCamera = $Camera

var reached_outside := false
var scoring: Scoring
var best_score := 0
var _ended := false
var _wind: AudioStreamPlayer
var _chime: AudioStreamPlayer
var _tap: AudioStreamPlayer
var _crumple: AudioStreamPlayer
var _downdraft: AudioStreamPlayer
var _style_good: AudioStreamPlayer
var _style_perfect: AudioStreamPlayer
var _ui: Control
var _card: Control
var _card_title: Label
var _card_lines: Label
var _fly_again: Button
var _hint: Label
var _hud: Label
var _popup: Label
var _popup_tween: Tween
var _fps: Label
var _fps_timer := 0.0
var _overlay: DebugOverlay
var _smooth_frames := 0
var _waited := 0.0


func _ready() -> void:
	process_physics_priority = 10  # score after the plane has moved this tick
	scoring = Scoring.new(plane.tuning, Course.spine(), Course.style_moment_defs())
	scoring.style_awarded.connect(_on_style_awarded)
	best_score = BestScore.load_best()
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
	if OS.is_debug_build():
		_overlay = DebugOverlay.new()
		add_child(_overlay)
		_overlay.build(scoring, Course.spine())


## The first frames can stall while shaders compile, so the plane hangs in the air until
## the game is drawing smoothly (6 quick frames, or 2 s at most), then flies. The phone's
## angle then becomes "level".
func _throw_when_ready(delta: float) -> void:
	_waited += delta
	_smooth_frames = _smooth_frames + 1 if delta < 0.1 else 0
	if _smooth_frames >= 6 or _waited >= 2.0:
		plane.release()


func _physics_process(_delta: float) -> void:
	if not plane.held and not plane.is_ended():
		scoring.update(plane.global_position)


## Debug builds only: F3 shows the style paths.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _overlay and key and key.pressed and not key.echo and key.keycode == KEY_F3:
		_overlay.visible = not _overlay.visible


func _process(delta: float) -> void:
	if plane.held:
		_throw_when_ready(delta)
	if not reached_outside and Course.is_outside(plane.global_position):
		reached_outside = true
	# Wind rises and falls with airspeed.
	var t := 0.0 if plane.is_ended() else clampf((plane.model.velocity.length() - 2.0) / 10.0, 0.0, 1.0)
	var volume := linear_to_db(lerpf(0.12, 0.7, t)) if not plane.is_ended() else -50.0
	_wind.volume_db = lerpf(_wind.volume_db, volume, 1.0 - exp(-4.0 * delta))
	_wind.pitch_scale = lerpf(_wind.pitch_scale, lerpf(0.8, 1.35, t), 1.0 - exp(-3.0 * delta))
	_hud.text = "%.0f m" % scoring.distance_meters()  # rounded the same way as on the end card
	if _fps:
		_fps_timer -= delta
		if _fps_timer <= 0.0:
			_fps_timer = 0.5
			_fps.text = "%d fps" % Engine.get_frames_per_second()


func distance_meters() -> float:
	return scoring.distance_meters()


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


## A cheerful pop-up and sound for style points; a near-perfect pass gets a bigger, golden
## pop-up and a brighter sparkle.
func _on_style_awarded(_id: StringName, title: String, points: int, quality: float) -> void:
	var perfect := quality >= plane.tuning.style_perfect_quality
	(_style_perfect if perfect else _style_good).play()
	_popup.text = ("Perfect %s!  +%d" % [title.to_lower(), points]) if perfect else ("%s  +%d" % [title, points])
	_popup.add_theme_color_override("font_color", GOLD if perfect else INK)
	_popup.pivot_offset = _popup.size * 0.5
	_popup.scale = Vector2.ONE * (0.5 if perfect else 0.7)
	_popup.modulate.a = 1.0
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup, "scale", Vector2.ONE * (1.25 if perfect else 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_interval(0.9 if perfect else 0.7)
	_popup_tween.tween_property(_popup, "modulate:a", 0.0, 0.35)


func _on_crashed() -> void:
	_crumple.play()
	camera.shake(0.12)
	_finish("Crumpled!", 0.45)


func _on_stopped() -> void:
	_finish("You flew outside!" if reached_outside else "Touchdown", 0.4)


func _finish(title: String, delay: float) -> void:
	if _ended:
		return
	_ended = true
	var total := scoring.total()
	var new_best := total > best_score
	if new_best:
		best_score = total
		if not BestScore.save_best(total):
			push_warning("Could not save the best score; it is kept until the game closes.")
	# A timer signal rather than `await`: if the scene goes away first, nothing is left waiting.
	get_tree().create_timer(delay).timeout.connect(_show_card.bind(title, total, new_best))


func _show_card(title: String, total: int, new_best: bool) -> void:
	_card_title.text = title
	var hit := scoring.moments.filter(func(m: Scoring.Moment) -> bool: return m.award > 0).size()
	_card_lines.text = "Distance  %.0f m = %d\nStyle  %d   (%d of %d moments)\nTotal  %d\n%s  %d" % [scoring.distance_meters(), scoring.distance_points(), scoring.style_points, hit, scoring.moments.size(), total, "New best!" if new_best else "Best", best_score]
	_card.visible = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)
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
	_style_good = _player("res://audio/style_good.wav", -6.0)
	_style_perfect = _player("res://audio/style_perfect.wav", -4.0)
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

	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 22)
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hud.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hud.position += Vector2(-24, 12)
	_ui.add_child(_hud)

	_popup = Label.new()
	_popup.add_theme_font_size_override("font_size", 40)
	# A full-width strip with centred text: titles of any length stay centred, and it grows from the middle.
	_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_popup.position.y += 70.0
	_popup.modulate.a = 0.0
	_ui.add_child(_popup)

	if OS.is_debug_build():
		_fps = Label.new()
		_fps.add_theme_font_size_override("font_size", 18)
		_fps.position = Vector2(14, 10)
		# Debug builds only: tap the fps counter to show the style paths.
		_fps.mouse_filter = Control.MOUSE_FILTER_STOP
		_fps.gui_input.connect(_on_fps_tapped)
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
	_card_lines = Label.new()
	_card_lines.add_theme_font_size_override("font_size", 30)
	_card_lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_card_lines)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	_fly_again = Button.new()
	_fly_again.text = "Fly again"
	_fly_again.custom_minimum_size = Vector2(340, 96)
	_fly_again.add_theme_font_size_override("font_size", 36)
	_fly_again.pressed.connect(_on_fly_again)
	box.add_child(_fly_again)


func _on_fps_tapped(event: InputEvent) -> void:
	var tap := event as InputEventMouseButton
	if _overlay and tap and tap.pressed:
		_overlay.visible = not _overlay.visible


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
