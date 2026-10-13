# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name FlightGame
extends Node3D
## What every flight shares, whether the Course (game.gd) or Endless (endless_game.gd): the sky
## and light, the watercolour pass, the sounds (wind that rises with airspeed, the vario's beeps,
## the sigh when lift is lost, sink ticks, close-call whooshes, bumps), the hint, distance and
## pop-up labels, the end card's frame and buttons, the settings panel, About, and Back.
## Each kind of flight builds its own world, runs its own scoring and fills in the card.

const POST_SHADER := preload("res://shaders/watercolor.gdshader")
const INK := Color("5d5468")
const CREAM := Color("fbf6ee")
const LILAC := Color("c9b2d6")
const GOLD := Color("e0a63c")

@onready var plane: Flyer = $Plane
@onready var camera: FollowCamera = $Camera

var _ended := false
var _wind: AudioStreamPlayer
var _wind_db := -40.0  ## The wind's loudness from airspeed, before any swell on top.
var _swell_db := 0.0  ## A short swell of wind on top (bursting out of the window).
var _swell_fade := 1.0  ## Decibels per second the swell dies away.
var _chime: AudioStreamPlayer
var _tap: AudioStreamPlayer
var _crumple: AudioStreamPlayer
var _pop: AudioStreamPlayer
var _downdraft: AudioStreamPlayer
var _style_good: AudioStreamPlayer
var _style_perfect: AudioStreamPlayer
var _whoosh: AudioStreamPlayer
var _vario_beep: AudioStreamPlayer
var _sigh: AudioStreamPlayer
var _sink_tick: AudioStreamPlayer
var _splash: AudioStreamPlayer
var sink_ticks := 0  ## Sink ticks this flight.
var _sink_wait := 0.0
var vario: Vario
var vario_beeps := 0  ## Beeps this flight.
var sighs := 0  ## "Lift lost" sighs this flight.
var _last_sigh := -INF  ## Flight time of the last sigh.
var _near_query := PhysicsShapeQueryParameters3D.new()  ## Reused each tick for close calls.
var _close_call_wait := 0.0  ## Seconds until the next close call may sound.
enum Pass { CLEAR, CLOSE, SPOILED }  ## Clear of everything; rushing close past something; touched it.
var _pass := Pass.CLEAR
var _pass_touches := 0  ## The plane's touch count when the close pass began.
var close_calls := 0  ## Close calls this flight.
var _ui: Control
var _card: Control
var _card_title: Label
var _card_lines: Label
var _card_note: Label  ## A gold line under the card's lines, when there is news.
var _card_main: HBoxContainer  ## The big buttons: "Fly again", and any other mode's.
var _fly_again: Button
var _swap_look: Button
var _settings_button: Button
var _quit: Button
var _settings_panel: Control
var _sensitivity: HSlider
var _sensitivity_value: Label
var _sound: CheckButton
var _swap_pitch: CheckButton
var _about_button: Button
var _about: AboutPanel  ## Built the first time it is opened.
## The player's settings (PlayerSettings), as loaded and as changed on the settings panel.
var settings := {}
var _hint: Label
var _hint_tween: Tween
var _last_entry := {}  ## Air zone -> flight time the plane last flew into it.
var _hud: Label
var _popup: Label
var _popup_tween: Tween
var _fps: Label
var _fps_timer := 0.0
## Debug builds only: a line a second in the log (adb logcat -s godot) with the frame rate, the
## slowest frame and where the plane is, for checking the frame rate on a phone.
var _perf_time := 0.0
var _perf_frames := 0
var _perf_worst := 0.0
## Debug builds only: what F3 (or tapping the fps counter) shows and hides.
var _overlay: Node3D
var _smooth_frames := 0
var _waited := 0.0


# --- For each kind of flight to fill in ------------------------------------------

## The ground's height (as drawn and as it collides) under a point.
func ground_under(_x: float, _z: float) -> float:
	return -INF


## The height of open water at (x, z), or -INF where there is none.
func water_level(_x: float, _z: float) -> float:
	return -INF


## Whether a point is out in the open air (sink ticks and the like are outdoors only).
func is_outdoors(_at: Vector3) -> bool:
	return true


## A name for where a point is, for the PERF log line.
func section_name(_at: Vector3) -> String:
	return ""


func _on_fly_again() -> void:
	get_tree().reload_current_scene()


## Flies the other one next time (and every time after, until swapped back).
func _on_swap_look() -> void:
	save_other_look()
	get_tree().reload_current_scene()


## Called when the plane flies into a zone of rising air outdoors (after the chime).
func _on_entered_lift(_zone: Thermal) -> void:
	pass


# --- Each tick ----------------------------------------------------------------------

## Forgets everything one flight's sounds kept: the vario, the counts, a close pass under way, the
## sigh's and the ticks' waits, any swell of wind (a run starting over in place).
func reset_flight_sounds() -> void:
	vario = Vario.new(plane.tuning)
	_vario_beep.stop()
	vario_beeps = 0
	sighs = 0
	sink_ticks = 0
	close_calls = 0
	_pass = Pass.CLEAR
	_close_call_wait = 0.0
	_sink_wait = 0.0
	_last_sigh = -INF
	_swell_db = 0.0
	_last_entry.clear()


## The vario's beeps and sigh, and the sink ticks: call once a physics tick while flying.
func _tick_sounds(delta: float) -> void:
	if vario.tick(delta, plane.air_here().y, plane.model.velocity.y, plane.model.stalled, plane.lift_zone(), plane.global_position.y):
		_vario_beep.pitch_scale = vario.pitch()
		_vario_beep.volume_db = vario.volume_db()
		_vario_beep.play()
		vario_beeps += 1
	if vario.sigh:
		_play_sigh()
	_tick_in_sink(delta)


## Low ticks while sinking in the air over the lake (outdoors only), faster and louder the
## stronger the sink.
func _tick_in_sink(delta: float) -> void:
	var tune := plane.tuning
	var air := plane.air_here().y
	_sink_wait -= delta  # keeps counting down out of the sink too, so re-entering can't tick at once
	var at := plane.global_position
	var low := at.y - maxf(ground_under(at.x, at.z), water_level(at.x, at.z)) < 1.0  # sliding to a stop: quiet
	if air > tune.sink_tick_air or plane.model.grounded or low or not is_outdoors(at):
		return
	if _sink_wait > 0.0:
		return
	var k := clampf((tune.sink_tick_air - air) / maxf(tune.sink_tick_air - tune.sink_tick_air_full, 0.01), 0.0, 1.0)
	_sink_wait = lerpf(tune.sink_tick_interval_slow, tune.sink_tick_interval_fast, k)
	_sink_tick.volume_db = lerpf(tune.sink_tick_db_quiet, tune.sink_tick_db_loud, k)
	_sink_tick.play()
	sink_ticks += 1


## Lift lost: a soft sigh in the voice of the air just left, quieter if soon after the last one.
func _play_sigh() -> void:
	var tune := plane.tuning
	_sigh.pitch_scale = vario.zone.chime_pitch * 0.9
	var again := plane.flight_time - _last_sigh < tune.chime_repeat_window
	_sigh.volume_db = tune.lift_lost_db + (tune.chime_repeat_db if again else 0.0)
	_sigh.play()
	_last_sigh = plane.flight_time
	sighs += 1


## Rushing past something without touching it: a soft whoosh and a swell of wind, once the
## plane is clear again. A pass begins when the plane comes close to a surface at speed; any
## touch during it (bump, slide or crash) spoils it, since a touch is not a near miss (it gets
## the tap); and a spoiled pass ends quietly once the plane is clear.
func _check_close_call(delta: float) -> void:
	var tune := plane.tuning
	_close_call_wait = maxf(_close_call_wait - delta, 0.0)
	if _pass == Pass.CLEAR and (_close_call_wait > 0.0 or plane.model.velocity.length() < tune.close_call_speed):
		return  # no pass can begin: skip the query
	(_near_query.shape as SphereShape3D).radius = Flyer.RADIUS + tune.close_call_distance
	_near_query.transform = Transform3D(Basis.IDENTITY, plane.global_position)
	var near := not plane.get_world_3d().direct_space_state.intersect_shape(_near_query, 1).is_empty()
	match _pass:
		Pass.CLEAR:
			if near:
				_pass = Pass.CLOSE
				_pass_touches = plane.touches
		Pass.CLOSE:
			if plane.touches != _pass_touches:
				_pass = Pass.SPOILED
			elif not near:
				_pass = Pass.CLEAR
				close_calls += 1
				_close_call_wait = tune.close_call_cooldown
				swell(tune.close_call_db, tune.close_call_fade)
				_whoosh.play()
		Pass.SPOILED:
			if not near:
				_pass = Pass.CLEAR


## The first frames can stall while shaders compile, so the plane hangs in the air until
## the game is drawing smoothly (6 quick frames, or 2 s at most), then flies. The phone's
## angle then becomes "level".
func _throw_when_ready(delta: float) -> void:
	_waited += delta
	_smooth_frames = _smooth_frames + 1 if delta < 0.1 else 0
	if _smooth_frames >= 6 or _waited >= 2.0:
		plane.release()


## Wind rises and falls with airspeed, plus any swell on top; and the fps counter and PERF log
## in debug builds. Call once a frame.
func _update_wind_and_debug(delta: float) -> void:
	var tune := plane.tuning
	var span := maxf(tune.wind_loud_speed - tune.wind_quiet_speed, 0.01)
	var t := 0.0 if plane.is_ended() else clampf((plane.model.velocity.length() - tune.wind_quiet_speed) / span, 0.0, 1.0)
	# Never quite silent: -inf decibels would turn the smoothing below into NaN.
	var volume := linear_to_db(maxf(lerpf(tune.wind_quiet, tune.wind_loud, t), 0.001)) if not plane.is_ended() else -50.0
	_wind_db = lerpf(_wind_db, volume, 1.0 - exp(-tune.wind_swell_rate * delta))
	_swell_db = maxf(_swell_db - _swell_fade * delta, 0.0) if not plane.is_ended() else 0.0
	_wind.volume_db = minf(_wind_db + _swell_db, tune.wind_max_db)
	_wind.pitch_scale = lerpf(_wind.pitch_scale, lerpf(tune.wind_pitch_low, tune.wind_pitch_high, t), 1.0 - exp(-tune.wind_pitch_rate * delta))
	if _fps:
		_fps_timer -= delta
		if _fps_timer <= 0.0:
			_fps_timer = 0.5
			_fps.text = "%d fps" % Engine.get_frames_per_second()
		_log_perf(delta)


func _log_perf(delta: float) -> void:
	_perf_time += delta
	_perf_frames += 1
	_perf_worst = maxf(_perf_worst, delta)
	if _perf_time < 1.0:
		return
	var p := plane.global_position
	var air := ""
	for node in get_tree().get_nodes_in_group("thermals"):
		var zone := node as Thermal
		if zone.visible and absf(zone.vertical_air_speed(camera.global_position, plane.tuning)) > 0.0:
			air = " in " + zone.name  # the camera is inside this zone's column
	print("PERF t %.0f %s%s fps %.0f worst %.0f ms at (%.0f, %.0f, %.0f)" % [plane.flight_time, section_name(p), air, _perf_frames / _perf_time, _perf_worst * 1000.0, p.x, p.y, p.z])
	_perf_time = 0.0
	_perf_frames = 0
	_perf_worst = 0.0


## A swell of wind `db` louder, dying away over `seconds` (a bigger swell wins over a smaller one).
func swell(db: float, seconds: float) -> void:
	if db > _swell_db:
		_swell_db = db
		_swell_fade = db / maxf(seconds, 0.01)


# --- Events --------------------------------------------------------------------

## Escape steps back (see handle_back). Debug builds only: F3 shows the debug overlay.
func _unhandled_input(event: InputEvent) -> void:
	# Escape steps back like the phone's Back (see _notification), but never quits.
	if event.is_action_pressed("ui_cancel") and handle_back():
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if _overlay and key and key.pressed and not key.echo and key.keycode == KEY_F3:
		_overlay.visible = not _overlay.visible


func _on_bumped(strength: float) -> void:
	var tune := plane.tuning
	_tap.pitch_scale = randf_range(tune.tap_pitch_min, tune.tap_pitch_max)
	_tap.volume_db = linear_to_db(clampf(strength / maxf(tune.tap_full_strength, 0.01), tune.tap_min_loudness, 1.0)) + tune.tap_volume_db
	_tap.play()
	camera.shake(tune.bump_shake)


func _on_entered_thermal(zone: Thermal) -> void:
	if zone.look == Thermal.Look.LAKE:
		return  # flying out over the water is silent; the sink ticks tell you
	var tune := plane.tuning
	var player := _downdraft if zone.sinks else _chime
	player.pitch_scale = zone.chime_pitch
	# Back into the same air soon after (a lap of a circle): a quieter chime.
	var again := _last_entry.has(zone) and plane.flight_time - float(_last_entry[zone]) < tune.chime_repeat_window
	_last_entry[zone] = plane.flight_time
	var base := tune.downdraft_volume_db if zone.sinks else tune.chime_volume_db
	player.volume_db = base + (tune.chime_repeat_db if again else 0.0)
	player.play()
	if zone.outdoors and not zone.sinks:
		_on_entered_lift(zone)
	if zone.look == Thermal.Look.RIDGE:
		swell(plane.tuning.ridge_swell_db, plane.tuning.ridge_swell_fade)  # the breeze up the hillside


## Coming down on the water at `water_y`: a splash, and a ring of droplets thrown up around the plane.
func _splash_at(at: Vector3, water_y: float) -> void:
	_splash.play()
	var drops := CPUParticles3D.new()
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.amount = 12
	drops.lifetime = 0.9
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	drops.emission_ring_axis = Vector3.UP
	drops.emission_ring_radius = 0.6
	drops.emission_ring_inner_radius = 0.5
	drops.emission_ring_height = 0.0
	drops.direction = Vector3.UP
	drops.spread = 25.0
	drops.initial_velocity_min = 2.5
	drops.initial_velocity_max = 3.5
	drops.gravity = Vector3(0.0, -9.0, 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.18)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = Art.soft_dot()
	mat.albedo_color = Color("dceef6")
	quad.material = mat
	drops.mesh = quad
	drops.position = Vector3(at.x, water_y + 0.05, at.z)
	add_child(drops)
	drops.finished.connect(drops.queue_free)
	drops.emitting = true


## A cheerful pop-up: gold and bigger for the best moments.
func show_popup(text: String, gold: bool) -> void:
	var tune := plane.tuning
	_popup.text = text
	_popup.add_theme_color_override("font_color", GOLD if gold else INK)
	_popup.pivot_offset = _popup.size * 0.5
	_popup.scale = Vector2.ONE * (tune.popup_perfect_start_scale if gold else tune.popup_start_scale)
	_popup.modulate.a = 1.0
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup, "scale", Vector2.ONE * (tune.popup_perfect_scale if gold else tune.popup_scale), tune.popup_grow_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_interval(tune.popup_perfect_hold if gold else tune.popup_hold)
	_popup_tween.tween_property(_popup, "modulate:a", 0.0, tune.popup_fade_time)


## Shows the end card with `title`, `lines` and a gold `note` (if any), fading in, with focus on
## `focus` (or "Fly again").
func show_card(title: String, lines: PackedStringArray, focus: Button = null, note := "") -> void:
	_card_title.text = title
	_card_lines.text = "\n".join(lines)
	_card_note.text = note
	_card_note.visible = note != ""
	_card.visible = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)
	(focus if focus else _fly_again).grab_focus()


## Closes the game (on a phone, the app).
func _on_quit() -> void:
	get_tree().quit()


## Saves the other look (plane or balloon) as the player's choice.
func save_other_look() -> void:
	settings["look"] = PlayerSettings.PLANE if plane.balloon else PlayerSettings.BALLOON
	if not PlayerSettings.save_all(settings):
		push_warning("Could not save the choice of plane or balloon; flying the same one again.")


## Puts the player's settings into effect: tilt sensitivity and climb/dive for this flight,
## and the sound.
func apply_settings() -> void:
	plane.controls.sensitivity_scale = settings["sensitivity"]
	plane.controls.swap_climb_dive = settings["invert_pitch"]
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not settings["sound"])


func _on_setting_changed(_value: Variant = null) -> void:
	settings["sensitivity"] = _sensitivity.value
	settings["sound"] = _sound.button_pressed
	settings["invert_pitch"] = _swap_pitch.button_pressed
	settings = PlayerSettings.clean(settings)
	_sensitivity_value.text = "%.2fx" % settings["sensitivity"]
	apply_settings()
	if not PlayerSettings.save_all(settings):
		push_warning("Could not save the settings; they last until the game closes.")


## The phone's Back (button or gesture): steps back out of About's pages, then out of About,
## then closes the settings; with none of them open, it closes the game, as Android's Back does
## (project setting quit_on_go_back is off so this can step back first).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not handle_back():
		get_tree().quit()


## Steps back one screen (About's page, About, or the settings) and returns true, or returns
## false if none of them is open.
func handle_back() -> bool:
	if _about and _about.visible:
		_about.go_back()
		return true
	if _settings_panel and _settings_panel.visible:
		show_settings(false)
		return true
	return false


func show_settings(on: bool) -> void:
	_settings_panel.visible = on
	_card.visible = not on
	(_sensitivity if on else _settings_button).grab_focus()


## About Updraft, over the settings; closing it goes back to the settings.
func show_about() -> void:
	if _about == null:
		_about = AboutPanel.new()
		_about.closed.connect(_on_about_closed)
		_ui.add_child(_about)
	_settings_panel.visible = false
	_about.open()


func _on_about_closed() -> void:
	_settings_panel.visible = true
	_about_button.grab_focus()


# --- Setup -----------------------------------------------------------------------

## What every flight sets up, in the order it needs: scoring after the plane has moved each tick
## (physics priority); the player's settings and look before the settings panel is built; then the
## sky and light, the watercolour pass, the sounds and the screens. `hint` is shown at the start.
func _setup_flight(hint: String) -> void:
	process_physics_priority = 10  # after the plane has moved this tick
	settings = PlayerSettings.load_all()
	plane.set_look(settings["look"])
	apply_settings()
	_setup_world()
	_setup_post_fx()
	_setup_audio()
	_setup_ui(hint)


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
	var tune := plane.tuning
	_chime = _player("res://audio/chime.wav", tune.chime_volume_db)
	_tap = _player("res://audio/tap.wav", tune.tap_volume_db)
	_crumple = _player("res://audio/crumple.wav", tune.crumple_volume_db)
	_pop = _player("res://audio/pop.wav", tune.pop_volume_db)
	_downdraft = _player("res://audio/downdraft.wav", tune.downdraft_volume_db)
	_style_good = _player("res://audio/style_good.wav", tune.style_good_volume_db)
	_style_perfect = _player("res://audio/style_perfect.wav", tune.style_perfect_volume_db)
	_whoosh = _player("res://audio/whoosh.wav", tune.whoosh_volume_db)
	_vario_beep = _player("res://audio/vario.wav", tune.vario_db_quiet)
	_sigh = _player("res://audio/sigh.wav", tune.lift_lost_db)
	_sink_tick = _player("res://audio/sink_tick.wav", tune.sink_tick_db_quiet)
	_splash = _player("res://audio/splash.wav", tune.splash_db)
	vario = Vario.new(tune)
	_near_query.shape = SphereShape3D.new()
	_near_query.collision_mask = Flyer.WORLD_LAYER
	_near_query.exclude = [plane.get_rid()]
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


## The hint, the distance label, the pop-up, the fps counter (debug builds), the end card and
## the settings. `hint` is shown low in the middle for the first seconds.
func _setup_ui(hint: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = _make_theme()
	layer.add_child(_ui)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH  # longer hints stay centred
	_hint.position.y -= 90.0
	_ui.add_child(_hint)
	show_hint(hint, 2.5)

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
		# Debug builds only: tap the fps counter to show the debug overlay.
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
	_card_note = Label.new()
	_card_note.add_theme_font_size_override("font_size", 32)
	_card_note.add_theme_color_override("font_color", GOLD)
	_card_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_note.visible = false
	box.add_child(_card_note)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	_card_main = HBoxContainer.new()
	_card_main.add_theme_constant_override("separation", 14)
	_card_main.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_card_main)
	_fly_again = card_button("Fly again")
	_fly_again.pressed.connect(_on_fly_again)
	_swap_look = Button.new()
	_swap_look.text = "Fly the paper plane" if plane.balloon else "Fly the balloon"
	_swap_look.custom_minimum_size = Vector2(340, 64)
	_swap_look.add_theme_font_size_override("font_size", 26)
	_swap_look.pressed.connect(_on_swap_look)
	_settings_button = Button.new()
	_settings_button.text = "Settings"
	_settings_button.custom_minimum_size = Vector2(200, 64)
	_settings_button.add_theme_font_size_override("font_size", 26)
	_settings_button.pressed.connect(show_settings.bind(true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_quit = Button.new()
	_quit.text = "Quit"
	_quit.custom_minimum_size = Vector2(160, 64)
	_quit.add_theme_font_size_override("font_size", 26)
	_quit.pressed.connect(_on_quit)
	row.add_child(_swap_look)
	row.add_child(_settings_button)
	row.add_child(_quit)
	box.add_child(row)
	_build_settings_panel()


## A big button (340 x 96) in the end card's top row, after "Fly again".
func card_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 96)
	b.add_theme_font_size_override("font_size", 36)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # one fills the card's width, two share it
	_card_main.add_child(b)
	return b


## Settings: tilt sensitivity, sound, and swapping climb and dive. Changes save at once. Also
## the way to About.
func _build_settings_panel() -> void:
	_settings_panel = CenterContainer.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_ui.add_child(_settings_panel)
	var panel := PanelContainer.new()
	_settings_panel.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 56)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sens_row := HBoxContainer.new()
	sens_row.add_theme_constant_override("separation", 16)
	var sens_label := Label.new()
	sens_label.text = "Tilt sensitivity"
	sens_label.add_theme_font_size_override("font_size", 28)
	sens_row.add_child(sens_label)
	_sensitivity = HSlider.new()
	_sensitivity.min_value = PlayerSettings.SENSITIVITY_MIN
	_sensitivity.max_value = PlayerSettings.SENSITIVITY_MAX
	_sensitivity.step = PlayerSettings.SENSITIVITY_STEP
	_sensitivity.custom_minimum_size = Vector2(320, 48)
	_sensitivity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sens_row.add_child(_sensitivity)
	_sensitivity_value = Label.new()
	_sensitivity_value.add_theme_font_size_override("font_size", 28)
	_sensitivity_value.custom_minimum_size = Vector2(80, 0)
	sens_row.add_child(_sensitivity_value)
	box.add_child(sens_row)

	_sound = CheckButton.new()
	_sound.text = "Sound"
	_swap_pitch = CheckButton.new()
	_swap_pitch.text = "Swap climb and dive"
	for check in [_sound, _swap_pitch]:
		check.add_theme_font_size_override("font_size", 28)
		box.add_child(check)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_about_button = Button.new()
	_about_button.text = "About"
	_about_button.custom_minimum_size = Vector2(200, 80)
	_about_button.add_theme_font_size_override("font_size", 32)
	_about_button.pressed.connect(show_about)
	row.add_child(_about_button)
	var done := Button.new()
	done.text = "Done"
	done.custom_minimum_size = Vector2(340, 80)
	done.add_theme_font_size_override("font_size", 32)
	done.pressed.connect(show_settings.bind(false))
	row.add_child(done)
	box.add_child(row)

	_sensitivity.set_value_no_signal(settings["sensitivity"])
	_sound.set_pressed_no_signal(settings["sound"])
	_swap_pitch.set_pressed_no_signal(settings["invert_pitch"])
	_sensitivity_value.text = "%.2fx" % settings["sensitivity"]
	_sensitivity.value_changed.connect(_on_setting_changed)
	_sound.toggled.connect(_on_setting_changed)
	_swap_pitch.toggled.connect(_on_setting_changed)


## Shows a hint low in the middle of the screen for `seconds`, then fades it out.
func show_hint(text: String, seconds: float) -> void:
	_hint.text = text
	_hint.modulate.a = 1.0
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(seconds)
	_hint_tween.tween_property(_hint, "modulate:a", 0.0, 1.0)


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
