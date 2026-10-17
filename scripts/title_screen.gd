# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TitleScreen
extends Control
## The title screen the game opens on: a painted sky (clouds drifting, motes rising in an updraft
## with the flyer riding it, in the looks it wears), the name, and the buttons. PLAY flies the mode
## flown last (Boot.first_scene(); a caption under it says which), INFO opens the player's guide
## and ABOUT the game's details, license and credits; once Endless is unlocked, DAILY flies
## today's flight (a gold badge shows its bonus while unpaid) and HANGAR spends the stars. A small,
## quiet Buy me a coffee button sits at the bottom, below them all. The
## phone's Back steps out of whatever is open, and on the title itself closes the game; Escape
## only ever steps back.

const SCENE := "res://scenes/title.tscn"
const TAGLINE := "Ride warm air through a house, down a valley and out over a lake."
const SKY_TOP := Color("9fc3e6")
const HORIZON := Color("f6e1d3")
const HORIZON_AT := 0.62  ## Of the height.
const UPDRAFT_X := 0.82  ## Of the width: the column of motes, with the flyer on top.
const FLYER_Y := 0.34  ## Of the height.

var play: Button
var daily: Button  ## DAILY and HANGAR: null until Endless is unlocked.
var hangar: Button
var info: Button
var about: Button
var coffee: Button  ## Buy me a coffee.
var daily_badge: Label
var caption: Label
## Where PLAY went (a scene path), once pressed. Tests turn opens_scenes off to see it without
## leaving.
var launched_to := ""
var opens_scenes := true
var _menu: Control
var _info: InfoPanel  ## Built the first time it is opened, as is About.
var _about: AboutPanel
var _hangar: HangarPanel
var _backdrop: Control
var _clouds: Array[Control] = []
var _motes: Motes
var _flyer: LookPreview
var _whoosh: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = FlightGame.make_theme()
	var settings := PlayerSettings.load_all()
	_build_sky()
	_build_menu(Progress.load_all()["unlocked"])
	_refresh()
	_setup_sound(settings["sound"])
	play.grab_focus()


## The caption, the daily badge and the flyer's looks, from the saves.
func _refresh() -> void:
	var progress := Progress.load_all()
	caption.text = caption_for(progress, BestScore.load_best())
	_flyer.show_look(progress["wear"], PlayerSettings.load_all()["look"] == PlayerSettings.BALLOON)
	if daily:
		var pays := Daily.reward(progress, Daily.today())
		daily_badge.text = "+%d" % pays["stars"]
		daily_badge.visible = pays["pays"]


## What PLAY will fly, as the caption under it says it.
static func caption_for(progress: Dictionary, course_best: int) -> String:
	if Boot.first_scene_for(progress) == EndlessGame.SCENE:
		return "Endless  ·  best %d m  ·  %d stars" % [progress["best_m"], progress["stars"]]
	var bank := "  ·  %d stars" % progress["stars"] if progress["unlocked"] else ""  # what the Hangar spends
	return "The Course" + ("  ·  best %d" % course_best if course_best > 0 else "") + bank


## PLAY: flies the mode flown last, once (the button then says so while the flight loads).
func on_play() -> void:
	_launch(Boot.first_scene(), play)


## DAILY: today's flight.
func on_daily() -> void:
	if launched_to == "":
		EndlessGame.daily_next = true
		Progress.note_mode(Progress.ENDLESS)
	_launch(EndlessGame.SCENE, daily)


func _launch(scene: String, pressed: Button) -> void:
	if launched_to != "":
		return
	launched_to = scene
	for b in [play, daily, hangar, info, about, coffee]:
		if b:
			b.disabled = true
	pressed.text = "Taking off..."
	play.scale = Vector2.ONE
	_whoosh.play()
	if not opens_scenes:
		return
	await get_tree().process_frame  # so "Taking off..." shows while the flight loads
	await get_tree().process_frame
	Boot.open(get_tree(), launched_to)


func show_info() -> void:
	if _info == null:
		_info = InfoPanel.new()
		_info.closed.connect(_on_closed.bind(info))
		add_child(_info)
	_menu.visible = false
	_info.open()


func show_hangar() -> void:
	if _hangar == null:
		_hangar = HangarPanel.new()
		_hangar.closed.connect(func() -> void:
			_refresh()
			_on_closed(hangar))
		add_child(_hangar)
	_menu.visible = false
	_hangar.open()


func show_about() -> void:
	if _about == null:
		_about = AboutPanel.new()
		_about.closed.connect(_on_closed.bind(about))
		add_child(_about)
	_menu.visible = false
	_about.open()


func _on_closed(opener: Button) -> void:
	_menu.visible = true
	opener.grab_focus()


## Steps back one screen (a page of About, About, or Info) and returns true, or returns false on
## the title itself.
func handle_back() -> bool:
	if _info and _info.visible:
		_info.go_back()
		return true
	if _about and _about.visible:
		_about.go_back()
		return true
	if _hangar and _hangar.visible:
		_hangar.go_back()
		return true
	return false


## The phone's Back: steps back, or on the title closes the game.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not handle_back():
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back()  # never quits
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _menu.visible:
		return  # Info or About covers the sky
	_time += delta
	if launched_to == "":  # PLAY breathes until it's pressed
		play.pivot_offset = play.size * 0.5
		play.scale = Vector2.ONE * (1.015 + 0.015 * sin(_time * TAU / 1.6))
	var w := size.x
	for c in _clouds:
		c.position.x += c.get_meta("speed") * delta
		if c.position.x > w + 40.0:
			c.position.x = -c.size.x - 40.0
		c.position.y = c.get_meta("y") * size.y
	_motes.advance(delta)
	_flyer.position = Vector2(UPDRAFT_X * w, FLYER_Y * size.y + 10.0 * sin(_time * TAU / 4.0)) - _flyer.size * 0.5


# --- Building ----------------------------------------------------------------------

func _build_sky() -> void:
	_backdrop = Backdrop.new()
	add_child(_backdrop)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 5:
		var c := Cloud.new()
		c.puff_seed = i
		c.set_meta("speed", rng.randf_range(8.0, 14.0))
		c.set_meta("y", rng.randf_range(0.06, 0.4))
		c.position.x = rng.randf_range(0.0, 1800.0)
		add_child(c)
		_clouds.append(c)
	_motes = Motes.new()
	_motes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_motes)
	_flyer = LookPreview.new(false)  # the flyer in its looks, bobbing on the updraft
	_flyer.size = Vector2(150, 150)
	add_child(_flyer)


func _build_menu(unlocked: bool) -> void:
	_menu = Control.new()  # the column and the version, hidden together under Info and About
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(centre)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	centre.add_child(box)
	var title := _label("Updraft", 112)
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)
	box.add_child(_label(TAGLINE, 28))
	box.add_child(_gap(36))
	play = _button("PLAY", Vector2(440, 128), 60)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(on_play)
	box.add_child(play)
	box.add_child(_gap(6))
	caption = _label("", 26)
	caption.add_theme_constant_override("outline_size", 8)
	box.add_child(caption)
	box.add_child(_gap(24))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20 if unlocked else 24)
	var size_ := Vector2(250, 96) if unlocked else Vector2(260, 96)
	var font := 36 if unlocked else 38
	if unlocked:
		daily = _button("DAILY", size_, font)
		daily.pressed.connect(on_daily)
		daily_badge = _label("", 22)  # today's bonus, while unpaid
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color("f4c84a")
		pill.set_corner_radius_all(16)
		pill.content_margin_left = 10
		pill.content_margin_right = 10
		daily_badge.add_theme_stylebox_override("normal", pill)
		daily_badge.add_theme_constant_override("outline_size", 0)
		daily_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		daily_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		daily_badge.position += Vector2(8, -14)
		daily.add_child(daily_badge)
		hangar = _button("HANGAR", size_, font)
		hangar.pressed.connect(show_hangar)
		row.add_child(daily)
		row.add_child(hangar)
	info = _button("INFO", size_, font)
	info.pressed.connect(show_info)
	about = _button("ABOUT", size_, font)
	about.pressed.connect(show_about)
	row.add_child(info)
	row.add_child(about)
	box.add_child(row)
	var first: Button = daily if unlocked else info
	play.focus_neighbor_bottom = play.get_path_to(first)
	# Buy me a coffee: small and unboxed, at the bottom centre, so it never competes with PLAY.
	var bottom := CenterContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -72.0
	bottom.offset_bottom = -12.0
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(bottom)
	coffee = Links.coffee_button(22, Vector2(0, 52))
	coffee.flat = true
	coffee.add_theme_constant_override("outline_size", 6)
	coffee.add_theme_color_override("font_outline_color", Color(FlightGame.CREAM, 0.8))
	bottom.add_child(coffee)
	for b in row.get_children():
		(b as Button).focus_neighbor_top = (b as Button).get_path_to(play)
		(b as Button).focus_neighbor_bottom = (b as Button).get_path_to(coffee)
	coffee.focus_neighbor_top = coffee.get_path_to(about)
	var version := _label("Version %s" % AboutPanel.version(), 18)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.position -= Vector2(24, 24)
	_menu.add_child(version)


func _setup_sound(on: bool) -> void:
	_whoosh = AudioStreamPlayer.new()
	_whoosh.stream = load("res://audio/whoosh.wav")
	_whoosh.volume_db = -8.0
	add_child(_whoosh)
	_wind = AudioStreamPlayer.new()
	var wind_stream := load("res://audio/wind.wav") as AudioStreamWAV
	if wind_stream and wind_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:  # as the flight loops it
		wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wind_stream.loop_end = int(wind_stream.get_length() * wind_stream.mix_rate)
	_wind.stream = wind_stream
	_wind.volume_db = -24.0
	add_child(_wind)
	if on:
		_wind.play()
	else:
		_whoosh.volume_db = -80.0


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(text: String, min_size: Vector2, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	return gap


# --- The painted sky ---------------------------------------------------------------

## The sky's gradient, three bands of hills and a little cottage: drawn once (and again on a
## resize, when the phone is folded or unfolded).
class Backdrop:
	extends Control

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var horizon := HORIZON_AT * h
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, horizon), Vector2(0, horizon)]),
			PackedColorArray([SKY_TOP, SKY_TOP, HORIZON, HORIZON]))
		draw_rect(Rect2(0, horizon, w, h - horizon), HORIZON)
		var far := FlightGame.LILAC.lerp(HORIZON, 0.5)
		_hills(far, horizon - 0.02 * h, 0.035 * h, 0.004, 0.6)
		var middle_top := _hills(Color("b7cfa0"), horizon + 0.06 * h, 0.04 * h, 0.006, 2.1)
		_cottage(Vector2(0.22 * w, middle_top.call(0.22 * w)))
		_hills(Color("c9dcb8"), horizon + 0.17 * h, 0.05 * h, 0.0045, 4.0)

	## A band of rolling hills from `base` down; returns its top's height at an x.
	func _hills(color: Color, base: float, amp: float, freq: float, phase: float) -> Callable:
		var top := func(x: float) -> float: return base - amp * (0.6 * sin(x * freq + phase) + 0.4 * sin(x * freq * 2.3 + phase * 1.7))
		var pts := PackedVector2Array()
		var steps := 48
		for i in steps + 1:
			var x := size.x * i / steps
			pts.append(Vector2(x, top.call(x)))
		pts.append(Vector2(size.x, size.y))
		pts.append(Vector2(0, size.y))
		draw_colored_polygon(pts, color)
		return top

	func _cottage(ground: Vector2) -> void:
		var body := Rect2(ground.x - 23.0, ground.y - 26.0, 46.0, 30.0)
		draw_rect(body, Color("fbf6ee"))
		draw_colored_polygon(PackedVector2Array([Vector2(body.position.x - 5.0, body.position.y), Vector2(ground.x, body.position.y - 18.0),
			Vector2(body.end.x + 5.0, body.position.y)]), Color("e8b3c4"))
		draw_rect(Rect2(ground.x + 6.0, ground.y - 18.0, 9.0, 9.0), Color("f4dc9b"))  # the open window, lit


## A soft cream cloud of a few overlapping puffs.
class Cloud:
	extends Control
	var puff_seed := 0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(150, 60)

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = puff_seed + 100
		var color := Color(FlightGame.CREAM, 0.9)
		for i in rng.randi_range(3, 4):
			var r := rng.randf_range(18.0, 30.0)
			var at := Vector2(30.0 + i * 30.0 + rng.randf_range(-6.0, 6.0), 36.0 - rng.randf_range(0.0, 14.0))
			draw_set_transform(at, 0.0, Vector2(1.4, 1.0))
			draw_circle(Vector2.ZERO, r, color)
		draw_set_transform(Vector2.ZERO)


## Small cream dots rising up the updraft under the flyer, fading as they near it.
class Motes:
	extends Control
	const COUNT := 14
	var _at: Array[Vector2] = []  ## Each mote's x offset (px) and height (0 at the horizon, 1 at the flyer).
	var _speed: Array[float] = []

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in COUNT:
			_at.append(Vector2(rng.randf_range(-36.0, 36.0), float(i) / COUNT))
			_speed.append(rng.randf_range(20.0, 30.0))

	func advance(delta: float) -> void:
		var rise := (HORIZON_AT - FLYER_Y) * size.y
		for i in COUNT:
			_at[i].y += _speed[i] * delta / maxf(rise, 1.0)
			if _at[i].y > 1.0:
				_at[i].y -= 1.0
		queue_redraw()

	func _draw() -> void:
		var bottom := HORIZON_AT * size.y
		var top := FLYER_Y * size.y + 50.0
		for p in _at:
			var y := lerpf(bottom, top, p.y)
			draw_circle(Vector2(UPDRAFT_X * size.x + p.x * (1.0 - 0.4 * p.y), y), 3.0, Color(FlightGame.CREAM, 0.75 * (1.0 - p.y)))
