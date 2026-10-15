# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessGame
extends FlightGame
## Endless (docs/endless-plan.md, step 1): flying on into a country that never ends, built ahead
## of you from pieces (EndlessWorld). Height is your health: the run ends at a crash or the first
## touch of the ground. Score is distance and stars; stars go to your bank. The first start of a
## session looks back over the bowl, then lets you go; "Fly again" starts over in place in under
## a second. A tailwind carries you along (the flyer flies exactly as in the Course).

const SCENE := "res://scenes/endless.tscn"
const COURSE_SCENE := "res://scenes/main.tscn"
const MINT := Color("9cc48a")
const CORAL := Color("e8604c")
## The camera's spot for the look back over the bowl, from the flyer (ahead and above it).
const LOOK_BACK_EYE := Vector3(-6.0, 2.5, -9.0)  # aside, so the balloon sits clear of the lake and the Gap
## A touchdown is on ground flatter than this (normal.y; about 25 degrees), or a slide this long.
const LANDING_FLAT := 0.9
const LANDING_SLIDE := 0.5
const POINTS_PER_METRE := 10
## Where the freshening breeze is announced (metres), and how much louder the wind bed gets from
## the start's breeze to full (at 3 u/s).
const FRESHENING_AT: Array[float] = [250.0, 500.0, 1000.0]
const WIND_BED_DB := 2.0

## Something worth a line in a test pilot's log (piece entered, lift, stars, snags, the gull...).
signal note(text: String)
## An arc of stars has closed: all taken, or flown past (for test pilots' statistics).
signal arc_closed(arc: EndlessStars.Arc)
## A run is starting at `start` (before its first pieces are placed): a test pilot starts afresh.
signal run_started(start: Vector3)
## A two-line piece (its entry at world z `entry_z`) has chosen the line its stars show: at its
## choice point (see CHOICE_IN), by the height the flyer really has there. Test pilots follow it.
signal line_chosen(entry_z: float, high: bool)
## The road taken at the fork entered at `entry_z` ("low" or "high"), once the spine is between the
## roads (EndlessForks.road_at()).
signal road_chosen(entry_z: float, road: String)

## Debug builds: a steady wind chosen on the card for this session (negative: the rising wind).
static var debug_wind := -1.0
## The look back plays once a session; later starts and retries go straight to the chase camera.
static var looked_back := false

@onready var world: EndlessWorld = $World

var gull: Gull
## A test pilot's hands (tools and tests): func(flyer) -> Vector2, as Flyer.autopilot. Shipped
## code never names the test pilot itself (it lives in tests/, which isn't exported): a tool
## attaches one through run_started and EndlessWorld.placed (see Autopilot.fly_endless()).
var test_pilot := Callable()
## Seed for the next run (tests set it; otherwise random).
var next_seed := -1
## The next run (and, when set before the scene opens, the first) is the daily flight.
static var daily_next := false
## This run is the daily flight: today's country (Daily), its own best, and its bonus.
var daily := false
var daily_date := ""  ## The day this daily run began (a run crossing midnight keeps its day).
var daily_best_m := 0  ## Today's best, before this run.
var daily_reached := false  ## This run reached Daily.GOAL_M.
var _daily_pays := {}  ## Daily.reward() as this run began.
## For calibrating one piece (tools/endless_log.gd --calibrate): {"pieces": [ids], "d": d, "h": entry
## height}. The run then starts at the first piece's entry, at that height.
var calibration := {}
## For test pilots (tools/endless_log.gd --from): the run is flown as if it had begun this many
## metres along (the pieces' difficulty and the wind).
var start_m := 0.0
var run_seed := 0
## Stars this run: small stars, big stars and arc bonuses (before any multiplier).
var stars_run := 0
var arcs_full := 0
var snags := 0
var bumps := 0
## The furthest along the valley so far (the lowest z).
var furthest_z := EndlessWorld.START.z
var best_m := 0
var best_score := 0
## Why the run ended, for logs: "Touchdown over Cloud Street" and the like.
var ending := ""
var piece_name := ""
var _intro_left := 0.0  ## Seconds of the look back still to play, hands off.
var _streak := 0  ## Stars in a row on the current arc (the pickup sound rises).
var _streak_arc: EndlessStars.Arc
var _star: AudioStreamPlayer
var _flutter: AudioStreamPlayer
var _star_label: Label
var _star_tween: Tween
var _bar_track: ColorRect
var _bar_fill: ColorRect
var _fade: ColorRect
var _course: Button
var _daily_button: Button
var _endless_button: Button
var _day_button: Button
var _daily_tag: Label
var _wind_button: Button
var _hoop_side := {}  ## Hoop key -> which side of its ring the flyer was last tick.
var _hoop_snag := {}  ## Hoop key -> seconds until it may snag again.
var _snag_wait := {}  ## Washing key -> seconds until it may snag again.
var _arch_side := {}  ## Arch key -> which side of the viaduct the flyer was last tick.
var _overlay_lines: ImmediateMesh
var _overlay_label: Label
var _run_time := 0.0
var _piece_tile := -1  ## The furthest piece entered (its first tile).
## A two-line piece entered whose line isn't chosen yet (it is at its choice point), or null.
var _choosing: EndlessWorld.Piece
## Roads taken at forks this run, by the fork's first tile ("low" or "high"); and how many of each
## (for step 7's missions; not saved yet).
var roads := {}
var roads_low := 0
var roads_high := 0
## The first fork of a session explains itself (as the look back plays once a session).
static var fork_explained := false
## The first kitten of a session explains itself.
static var kitten_explained := false
## Kittens met this run, and what they did (for test pilots' statistics).
var kittens_met := 0
var kitten_lunges := 0
var kitten_misses := 0
var kitten_bats := 0
var _mrrp: AudioStreamPlayer
var _mew: AudioStreamPlayer
var _squeak: AudioStreamPlayer
var _purr: AudioStreamPlayer
var _met := {}  ## Kittens (by instance id) that have watched you this run.
## How far into a two-line piece its line is chosen: this far in and heading on (within
## CHOICE_HEADING of straight down the valley), or the second distance in whatever the flyer is
## doing. Not at the join: a pilot circling a thermal across it decides once it straightens out,
## at the height it really has (fun review 6: the Standing Stones' 0 of 9).
const CHOICE_IN := Vector2(6.0, 24.0)
const CHOICE_HEADING := 60.0
const FORK_FIT_BY := 12.0
## A flyer pinned against the ground this long (bumping, or under GROUND_HOLD over it) has touched
## down: nothing may hold a run in a trough for minutes.
const GROUND_HOLD_TIME := 3.0
const GROUND_HOLD := 0.6
var _graze := 0.0  ## Seconds touching ground lately (a long slide is a touchdown).
var _graze_wait := 0.0  ## Seconds until a graze may nudge you off again.
var _pinned := 0.0  ## Seconds in touch with the ground in a row (see GROUND_HOLD_TIME).
var _wrong_way_hint := 0.0  ## Seconds until the "fly on" hint may show again.
var _run_id := 0  ## Counts runs, so a card timer from an earlier run shows nothing.
## Pieces entered this run after the Rim.
var pieces_entered := 0
## The best distance when this run began (where the bunting hangs), and whether it's been passed.
var _best_at_start := 0
var passed_best := false
var _freshened := 0  ## How many of FRESHENING_AT this run has passed.


func _ready() -> void:
	world.setup(plane.tuning)
	gull = Gull.new()
	gull.name = "Gull"
	add_child(gull)
	var no_ridges: Array[Thermal] = []
	gull.setup(plane, no_ridges)
	gull.ground_height = world.terrain_height
	gull.joined.connect(func() -> void: note.emit("gull joins"))
	world.placed.connect(_hang_best_marker)
	_setup_flight("Stay up as long as you can")
	_setup_endless_ui()
	var tune := plane.tuning
	_star = _player("res://audio/star.wav", tune.star_db)
	_flutter = _player("res://audio/flutter.wav", -10.0)
	_mrrp = _player("res://audio/mrrp.wav", tune.kitten_db)
	_mew = _player("res://audio/mew.wav", tune.kitten_db)
	_squeak = _player("res://audio/squeak.wav", tune.kitten_db)
	_purr = _player("res://audio/purr.wav", tune.kitten_db)
	plane.bumped.connect(_on_bumped)
	plane.crashed.connect(_on_crashed)
	plane.stopped.connect(_on_stopped)
	plane.snagged.connect(_on_snagged)
	plane.entered_thermal.connect(_on_entered_thermal)
	camera.target = plane
	var progress := Progress.load_all()
	best_m = progress["best_m"]
	best_score = progress["best_score"]
	if OS.is_debug_build():
		_build_overlay()
	start_run(not looked_back)


## The tailwind `metres` along: rising with distance (docs/endless-plan.md §2.3), unless a steady
## one was chosen on the card.
func wind(metres := 0.0) -> float:
	return debug_wind if debug_wind >= 0.0 else wind_at(plane.tuning, metres)


static func wind_at(tune: Tuning, metres: float) -> float:
	var full := maxf(tune.endless_full_distance_m, 1.0)
	if metres <= full:
		return lerpf(tune.endless_wind_start, tune.endless_wind_full, maxf(metres, 0.0) / full)
	return minf(tune.endless_wind_full + tune.endless_wind_rise * (metres - full) / 100.0, tune.endless_wind_max)


## Sets the tailwind for how far the run has come; the wind bed grows with it, and the freshening
## is felt (a gust and a word) at FRESHENING_AT.
func _set_wind(metres: float) -> void:
	var tune := plane.tuning
	world.wind = wind(metres)
	plane.air_drift = Vector3(0.0, 0.0, -world.wind)
	wind_bed_db = WIND_BED_DB * clampf((world.wind - tune.endless_wind_start) / maxf(tune.endless_wind_full - tune.endless_wind_start, 0.01), 0.0, 1.0)
	if debug_wind < 0.0 and _freshened < FRESHENING_AT.size() and metres >= FRESHENING_AT[_freshened]:
		_freshened += 1
		swell(3.0, 1.0)
		show_hint("The breeze is freshening", 2.0)
		note.emit("the breeze freshens (%.1f)" % world.wind)


## Starts a run: a new country, the flyer just short of the Rim's crest heading on. `look_back`
## plays the look back over the bowl first (once a session); otherwise the chase camera is
## already in place behind a short cream fade.
func start_run(look_back: bool) -> void:
	var tune := plane.tuning
	_ended = false
	_run_id += 1
	stars_run = 0
	arcs_full = 0
	snags = 0
	kittens_met = 0
	kitten_lunges = 0
	kitten_misses = 0
	kitten_bats = 0
	_met.clear()
	bumps = 0
	ending = ""
	piece_name = ""
	_streak = 0
	_streak_arc = null
	_hoop_side.clear()
	_hoop_snag.clear()
	_snag_wait.clear()
	_arch_side.clear()
	_run_time = 0.0
	_piece_tile = -1
	_choosing = null
	roads.clear()
	roads_low = 0
	roads_high = 0
	_graze = 0.0
	_graze_wait = 0.0
	_pinned = 0.0
	_wrong_way_hint = 0.0
	pieces_entered = 0
	daily = daily_next
	daily_next = false
	daily_reached = false
	if daily:
		daily_date = Daily.today()
		var progress := Progress.load_all()
		daily_best_m = int(progress["daily_best_m"]) if progress["daily_date"] == daily_date else 0
		_daily_pays = Daily.reward(progress, daily_date)
	_best_at_start = daily_best_m if daily else best_m
	if daily and _daily_pays["pays"] and daily_best_m < Daily.GOAL_M:
		_best_at_start = Daily.GOAL_M  # while the bonus is unpaid, the bunting marks its goal
	passed_best = false
	_freshened = FRESHENING_AT.filter(func(m: float) -> bool: return m <= start_m).size()  # (tools may start further on)
	reset_flight_sounds()
	run_seed = Daily.seed_for(daily_date) if daily else (next_seed if next_seed >= 0 else randi())
	next_seed = -1
	_set_wind(start_m)
	plane.air_drift_ground_fade = tune.endless_wind_ground_fade
	EndlessWorld.shift = 0.0  # (world.reset() below starts the country afresh too)
	var start := EndlessWorld.START
	if not calibration.is_empty():
		start = EndlessWorld.tile_origin(0) + Vector3(0.0, float(calibration["h"]), -0.5)
	furthest_z = start.z
	run_started.emit(start)
	if calibration.is_empty():
		world.reset(run_seed, look_back, [], -1.0, 0.0, start_m)
	else:
		var ids: Array[StringName] = []
		ids.assign(calibration["pieces"])
		world.reset(run_seed, false, ids, calibration["d"], calibration["h"])
	plane.autopilot = test_pilot
	plane.launch(start, 0.0)
	plane.held = true
	_smooth_frames = 0
	_waited = 0.0
	gull.reset()
	gull.set_lifts(world.ridge_lifts())
	_card.visible = false
	_settings_panel.visible = false
	if look_back:
		looked_back = true
		_intro_left = tune.endless_intro_seconds
		camera.start_intro(EndlessWorld.START + LOOK_BACK_EYE, tune.endless_intro_seconds)
		_fade.color.a = 0.0
	else:
		_intro_left = 0.0
		camera.snap()
		_fade.color.a = 1.0
		create_tween().tween_property(_fade, "color:a", 0.0, tune.endless_retry_fade)
	if daily:
		show_hint("Today's flight: the same country for everyone today", 2.5)
		if _daily_pays["pays"]:
			get_tree().create_timer(2.6).timeout.connect(func() -> void:
				if daily and not daily_reached and not _ended:
					show_hint("Reach %d m for %d stars" % [Daily.GOAL_M, _daily_pays["stars"]], 2.0))
	else:
		show_hint("Stay up as long as you can", 2.5)
	_daily_tag.visible = daily
	_update_hud()


# --- For FlightGame ----------------------------------------------------------------

func ground_under(x: float, z: float) -> float:
	return world.terrain_height(x, z)


func water_level(x: float, z: float) -> float:
	return world.water_level(x, z)


func section_name(at: Vector3) -> String:
	var p := world.piece_at(at.z)
	return "tile %d %s" % [EndlessWorld.tile_at(at.z), p.title() if p else "-"]


func _on_swap_look() -> void:
	save_other_look()
	plane.set_look(settings["look"])
	_swap_look.text = "Fly the paper plane" if plane.balloon else "Fly the balloon"
	start_run(false)


## Back: as in the Course (FlightGame handles it).


# --- Each tick ------------------------------------------------------------------------

func _process(delta: float) -> void:
	var tune := plane.tuning
	if plane.held:
		_throw_when_ready(delta)
		if not plane.held and _intro_left > 0.0 and not test_pilot.is_valid():
			plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2.ZERO  # hands off while looking back
	elif _intro_left > 0.0:
		_intro_left -= delta
		if _intro_left <= 0.0:
			_reveal()
	_update_hud()
	_update_height_bar(delta)
	if _overlay:
		_overlay_label.visible = _overlay.visible
		if _overlay.visible:
			_update_overlay()
	_update_wind_and_debug(delta)


## The end of the look back: control is yours (the phone's angle becomes level), a gust, a whoosh
## and the view opening up over the new country.
func _reveal() -> void:
	var tune := plane.tuning
	if not test_pilot.is_valid():
		plane.autopilot = Callable()
	plane.release()
	swell(tune.gap_gust_db, tune.gap_gust_fade)
	_whoosh.play()
	camera.kick_fov(tune.camera_fov_gap_kick)
	if Progress.load_all()["stars"] == 0:
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			if not _ended:
				show_hint("Catch the stars", 2.0))


func _physics_process(delta: float) -> void:
	if plane.held or _ended:
		return
	_run_time += delta
	if plane.global_position.z < plane.tuning.endless_recentre_z:
		_recentre()
	_set_wind(EndlessWorld.metres(furthest_z) + start_m)
	var at := plane.global_position
	plane.air_drift.x = _split_breeze(at)
	world.update(at, delta)
	var lifts := world.ridge_lifts()
	if lifts != gull.lifts:
		gull.set_lifts(lifts)
	world.sky.note_plane(at, vario.on)
	for pick in world.stars.check(at, plane.model.velocity):
		_on_star(pick)
	for arc in world.stars.closed_now:
		arc_closed.emit(arc)
	for arc in world.stars.closed_broken:
		note.emit("arc flown past (%d of %d)" % [arc.stars.filter(func(s: EndlessStars.Star) -> bool: return s.taken).size(), arc.stars.size()])
	_check_hoops(delta)
	_check_snags(delta)
	_check_arches()
	_step_kittens(delta)
	if _ended:
		return
	furthest_z = minf(furthest_z, at.z)
	if not passed_best and _best_at_start > 0 and EndlessWorld.metres(furthest_z) > _best_at_start:
		passed_best = true
		_chime.pitch_scale = 1.5
		_chime.volume_db = plane.tuning.chime_volume_db
		_chime.play()
		if not (daily and _best_at_start == Daily.GOAL_M and _daily_pays["pays"]):  # (the goal's own cheer follows)
			show_popup("Past today's best!" if daily else "Past your best!", true)
		note.emit("past your best (%d m)" % _best_at_start)
	if daily and not daily_reached and EndlessWorld.metres(furthest_z) >= Daily.GOAL_M:
		daily_reached = true
		if _daily_pays["pays"]:
			show_popup("Today's stars! +%d" % _daily_pays["stars"], true)
			_style_perfect.play()
			swell(3.0, 1.0)
			note.emit("daily reached")
	var p := world.piece_at(at.z)
	if p != null and p.spawned and p.placement.tile > _piece_tile:  # only onward (circling over a join doesn't count)
		_piece_tile = p.placement.tile
		piece_name = p.title()
		if p.kit.high_points.is_empty() and p.kit.fork.is_empty():
			world.stars.fit_to_entry(p.placement.tile, at.y)
		else:
			_choosing = p  # the stars show the line for your height (or a fork's fit it), chosen a little way in
		for q in world.pieces:  # the height a fork was left at, by road (for logs)
			if q.kit != null and not q.kit.fork.is_empty() and q.placement.tile + EndlessPieces.tiles(q.placement.id) == p.placement.tile:
				note.emit("fork out: %s road h %.1f" % [roads.get(q.placement.tile, "?"), at.y - q.origin.y])
		if not p.kit.fork.is_empty() and not fork_explained:
			fork_explained = true
			show_hint("Two ways: low road for stars, high road for height", 2.5)
		if p.placement.id != &"rim":
			pieces_entered += 1
		note.emit("enter %s (d %.2f, h %.1f)" % [piece_name, p.placement.d, p.placement.h_in])
	_choose_line(at)
	_choose_road(at)
	_check_close_call(delta)
	_tick_sounds(delta)
	_graze_wait = maxf(_graze_wait - delta, 0.0)
	_pinned = _pinned + delta if plane.model.grounded or at.y - world.terrain_height(at.x, at.z) < GROUND_HOLD else 0.0
	if _pinned >= GROUND_HOLD_TIME and not _ended:
		_finish("Touchdown", plane.tuning.endless_card_delay_touchdown, "pinned to the ground over %s" % piece_name)
	if plane.model.grounded:
		# Flat ground (or a long slide) is a touchdown; a graze of a slope nudges you off, like a bump.
		_graze += delta
		var water := world.water_level(at.x, at.z)
		if at.y - water < 0.8:
			_splash_at(at, water)
			_finish("Splashdown", plane.tuning.endless_card_delay_touchdown, "came down in the water at %s" % piece_name)
		elif plane.last_normal.y > LANDING_FLAT or _graze >= LANDING_SLIDE:
			_finish("Touchdown", plane.tuning.endless_card_delay_touchdown, "ran out of height over %s" % piece_name)
		elif _graze_wait <= 0.0:
			_graze_wait = 0.25
			plane.model.grounded = false
			plane.model.velocity = plane.model.velocity * plane.tuning.glance_speed_keep + plane.last_normal * 1.5
			_on_bumped(1.0)
	else:
		_graze = maxf(_graze - delta, 0.0)
	var course_z := EndlessWorld.unshifted(at.z)
	if not _ended and course_z > EndlessWorld.WRONG_WAY_Z:
		_finish("Wrong way!", plane.tuning.endless_card_delay_touchdown, "flew back past the start")
	elif course_z > EndlessWorld.WRONG_WAY_Z - 12.0 and _wrong_way_hint <= 0.0:
		var flat := Vector2(plane.model.velocity.x, plane.model.velocity.z)
		if flat.length() > 0.5 and flat.normalized().dot(Vector2(0.0, 1.0)) > 0.5:  # heading back upwind
			_wrong_way_hint = 4.0
			show_hint("The breeze is behind you: fly on!", 2.0)
	_wrong_way_hint = maxf(_wrong_way_hint - delta, 0.0)


## At a fork, once the spine stands between the roads (EndlessForks.road_at()), the road taken:
## the other road's stars dim and stop counting, a pop-up names it, and the wind swells.
func _choose_road(at: Vector3) -> void:
	for p in world.pieces:
		if p.kit == null or p.kit.fork.is_empty() or roads.has(p.placement.tile) or not p.spawned:
			continue
		var local := at - p.origin
		if local.z > 0.0 or local.z < -EndlessForks.LENGTH:
			continue
		var road := EndlessForks.road_at(p.placement.id, local)
		if road == "":
			continue
		roads[p.placement.tile] = road
		if road == "low":
			roads_low += 1
		else:
			roads_high += 1
		world.stars.choose_road(p.placement.tile, road)
		show_popup("Low road!" if road == "low" else "High road!", road == "low")
		swell(2.0, 0.6)
		note.emit("fork %s: %s road (z %.0f, h %.1f)" % [EndlessPieces.NAMES[p.placement.id], road, local.z, local.y])
		road_chosen.emit(p.origin.z, road)


## At a fork's nose the breeze splits round the hill: a flyer heading straight for it is eased
## toward the nearer road (it would otherwise bump off the nose and drift back down the valley).
func _split_breeze(at: Vector3) -> float:
	var p := world.piece_at(at.z)
	if p == null or p.kit == null or p.kit.fork.is_empty():
		return 0.0
	var local := at - p.origin
	var near := smoothstep(16.0, 34.0, -local.z) * (1.0 - smoothstep(70.0, 90.0, -local.z))
	var side := signf(local.x) if absf(local.x) > 0.5 else -EndlessForks.low_side(p.placement.id)  # (dead centre: the high road)
	return side * EndlessForks.SPLIT_BREEZE * near * (1.0 - smoothstep(4.0, 16.0, absf(local.x)))


## Where on a piece the flyer is, for the card ("in the Gorge"); a fork's before the road is taken
## is "at the fork".
func where(p: EndlessWorld.Piece) -> String:
	if p.kit != null and not p.kit.fork.is_empty() and roads.has(p.placement.tile):
		return p.kit.fork["where"][roads[p.placement.tile]]
	return EndlessPieces.WHERE[p.placement.id]


## At a two-line piece's choice point (CHOICE_IN), fits its entry stars to the height the flyer
## has and shows the line for that height.
func _choose_line(at: Vector3) -> void:
	if _choosing == null:
		return
	var p := _choosing
	var into := p.origin.z - at.z
	var flat := Vector2(plane.model.velocity.x, plane.model.velocity.z)
	var onward := flat.length() > 0.5 and flat.normalized().dot(Vector2(0.0, -1.0)) >= cos(deg_to_rad(CHOICE_HEADING))
	var latest := FORK_FIT_BY if not p.kit.fork.is_empty() else CHOICE_IN.y  # (a fork's first signpost star is at -16)
	if not (into >= latest or (into >= CHOICE_IN.x and onward)):
		return
	_choosing = null
	world.stars.fit_to_entry(p.placement.tile, at.y)
	if p.kit.high_points.is_empty():
		return  # a fork: its signposts and dives fitted to the height you really have, a little way in
	var high := p.kit.takes_high(at - p.origin)
	world.stars.choose_line(p.placement.tile, high)
	note.emit("%s line" % ("high" if high else "low"))
	line_chosen.emit(p.origin.z, high)


## Moves the whole world (and the flyer, camera and gull with it) a whole number of tiles back
## toward +z, between two physics ticks, so positions stay small (docs/endless-plan.md §2.7).
## Nothing jumps: everything moves together, and distances allow for the shift.
func _recentre() -> void:
	var by := EndlessPieces.TILE * plane.tuning.endless_recentre_tiles
	var offset := Vector3(0.0, 0.0, by)
	world.recentre(by, plane.global_position.z + by)
	plane.shift_by(offset)
	camera.shift_by(offset)
	gull.shift_by(offset)
	furthest_z += by
	note.emit("recentred by %.0f" % by)


## Hangs the bunting where the best run ended, in the piece that holds that spot, once it's placed.
func _hang_best_marker(p: EndlessWorld.Piece) -> void:
	if _best_at_start <= 0:
		return
	var z := EndlessWorld.START.z - _best_at_start * 4.0 + EndlessWorld.shift
	var local := z - p.origin.z
	if local > 0.0 or local <= -EndlessPieces.length(p.placement.id):
		return
	var mi := MeshInstance3D.new()
	mi.name = "BestMarker"
	mi.mesh = EndlessPieces.best_marker(p.placement.id, local)
	mi.material_override = Art.material(true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.node.add_child(mi)


## Kite rings: touching one's ring snags (speed lost, never a crash); flying through one rings it.
func _check_hoops(delta: float) -> void:
	var at := plane.global_position
	for key in _hoop_snag.keys():
		_hoop_snag[key] = maxf(float(_hoop_snag[key]) - delta, 0.0)
	for p in world.pieces:
		if not p.spawned or p.kit.hoops.is_empty() or absf(at.z - (p.origin.z - EndlessPieces.TILE * 0.5)) > EndlessPieces.TILE:
			continue
		for h in p.kit.hoops:
			var key := "%d_%d" % [p.placement.tile, h["index"]]
			var centre: Vector3 = p.origin + h["centre"]
			var axis: Vector3 = h["axis"]
			var rel := at - centre
			var along := rel.dot(axis)
			var across := (rel - axis * along).length()
			var radius: float = h["radius"]
			var side := signf(along)
			if absf(along) < 3.0 and Vector2(across - radius - EndlessPieces.HOOP_TUBE, along).length() < EndlessPieces.HOOP_TUBE + Flyer.RADIUS \
					and float(_hoop_snag.get(key, 0.0)) <= 0.0:
				_hoop_snag[key] = 0.5
				plane.snag(plane.tuning.snag_speed_keep)
			if _hoop_side.has(key) and side > 0.0 and _hoop_side[key] < 0.0 and across < radius:
				_chime.pitch_scale = 1.0 + 0.12 * int(h["index"])
				_chime.volume_db = plane.tuning.chime_volume_db
				_chime.play()
				note.emit("through hoop %d" % (int(h["index"]) + 1))
			_hoop_side[key] = side


## Washing lines and sheets: touching one snags (speed lost, never a crash), and a sheet sends a
## sock tumbling to the grass.
func _check_snags(delta: float) -> void:
	var at := plane.global_position
	for key in _snag_wait.keys():
		_snag_wait[key] = maxf(float(_snag_wait[key]) - delta, 0.0)
	for p in world.pieces:
		if not p.spawned or p.kit.snags.is_empty() or absf(at.z - (p.origin.z - EndlessPieces.TILE * 0.5)) > EndlessPieces.TILE:
			continue
		var local := at - p.origin
		for i in p.kit.snags.size():
			var s: Dictionary = p.kit.snags[i]
			var key := "%d_%d" % [p.placement.tile, i]
			if float(_snag_wait.get(key, 0.0)) > 0.0:
				continue
			var nearest := Geometry3D.get_closest_point_to_segment(local, s["a"], s["b"])
			if local.distance_to(nearest) < float(s["radius"]) + Flyer.RADIUS:
				_snag_wait[key] = 0.6
				plane.snag(plane.tuning.snag_speed_keep)
				if s["sock"]:
					_throw_sock(p, nearest)


## Each kitten within Kitten.DRAW_RANGE watches, wiggles and lunges in the physics tick (the same
## flight, the same outcome); further ones are hidden and still.
func _step_kittens(delta: float) -> void:
	var at := plane.global_position
	var string := plane.string_points if plane.balloon else PackedVector3Array()
	for p in world.pieces:
		for kitten in p.kittens:
			var near := kitten.global_position.distance_to(at) < Kitten.DRAW_RANGE
			if kitten.is_processing() != near:
				kitten.set_process(near)
			if not near:
				continue
			var was := kitten.state
			var event := kitten.step(delta, at, plane.model.velocity, string)
			var dist := kitten.centre().distance_to(at)
			var loud := plane.tuning.kitten_db - 12.0 * clampf(dist / Kitten.NOTICE, 0.0, 1.0)
			if kitten.state == Kitten.State.LUNGE and was != Kitten.State.LUNGE:
				kitten_lunges += 1
				_kitten_sound(_mew, loud)
			match event:
				Kitten.WATCHING:
					_kitten_sound(_mrrp, loud)
					if not _met.has(kitten.get_instance_id()):
						_met[kitten.get_instance_id()] = true
						kittens_met += 1
					note.emit("kitten %s watching (%d u)" % [kitten.kitten_name(), roundi(dist)])
					if not kitten_explained:
						kitten_explained = true
						show_hint("A kitten! Don't fly too close", 2.5)
				Kitten.READY:
					_kitten_sound(_squeak, loud)
					note.emit("kitten ready (%d u)" % roundi(dist))
				Kitten.MISSED:
					kitten_misses += 1
					var tune := plane.tuning
					_whoosh.play()
					swell(4.0, 0.5)
					camera.kick_fov(tune.arch_pass_fov_kick)
					show_popup("Missed me!", false)
					note.emit("kitten lunged: missed by %.1f u, passed %.1f u from her (%s)" % [kitten.closest, kitten.nearest, kitten.kitten_name()])
				Kitten.BATTED:
					kitten_bats += 1
					plane.snag(0.75)
					note.emit("kitten batted the string")
				Kitten.CAUGHT:
					_caught(kitten, dist)
					return


func _kitten_sound(player: AudioStreamPlayer, db: float) -> void:
	player.volume_db = db
	player.play()


## Caught by a kitten: the run ends as a crash does, but with a hug, hearts and a purr instead of
## a pop (docs/hazards-plan.md §1.6).
func _caught(kitten: Kitten, dist: float) -> void:
	plane.caught(kitten.hug_point())
	kitten.hearts()
	_kitten_sound(_mew, plane.tuning.kitten_db)
	var run := _run_id
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if run == _run_id:
			_kitten_sound(_purr, plane.tuning.kitten_db))
	camera.hold_and_look(kitten.head(), 6.0)
	note.emit("caught by %s (%.1f u)" % [kitten.kitten_name(), dist])
	_finish("Caught by %s" % kitten.kitten_name(), plane.tuning.endless_card_delay_caught, "caught by the kitten, %.1f u from it, in %s" % [dist, piece_name])


## A sock off the line, tumbling down to the grass under it (it stays there).
func _throw_sock(p: EndlessWorld.Piece, from: Vector3) -> void:
	var b := Art.Builder.new()
	var rng := RandomNumberGenerator.new()  # (its own, so a seeded run stays the same)
	rng.seed = hash(from)
	var color: Color = [Color("e8604c"), Color("f6c66f"), Color("a9c8e8"), Color("b9a6dc")][rng.randi() % 4]
	b.box(Vector3(0.0, 0.0, 0.0), Vector3(0.22, 0.5, 0.2), color)
	b.box(Vector3(0.0, -0.3, -0.15), Vector3(0.22, 0.18, 0.45), color)
	b.box(Vector3(0.0, 0.2, 0.0), Vector3(0.24, 0.1, 0.22), Color("fbf8f1"))
	var sock := MeshInstance3D.new()
	sock.name = "Sock"
	sock.mesh = b.commit()
	sock.material_override = Art.material()
	sock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sock.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.node.add_child(sock)
	sock.position = from
	var land := from + Vector3(rng.randf_range(-1.0, 1.0), 0.0, -1.5)
	land.y = EndlessPieces.grid_height(p.placement.id, land.x, land.z) + 0.15
	var fall := clampf(sqrt(maxf(from.y - land.y, 0.0)) * 0.45, 0.4, 1.4)
	var tween := sock.create_tween().set_parallel()
	tween.tween_property(sock, "position", land, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sock, "rotation", Vector3(rng.randf_range(2.0, 5.0), rng.randf_range(-2.0, 2.0), PI * 0.5), fall)


## Through an arch at speed: a whoosh, a swell of wind and the view widening for a moment.
func _check_arches() -> void:
	var at := plane.global_position
	var tune := plane.tuning
	for p in world.pieces:
		if not p.spawned:
			continue
		for a in p.kit.arches:
			var key := "%d_%s" % [p.placement.tile, a["z"]]
			var z: float = p.origin.z + float(a["z"])
			var side := signf(at.z - z)
			if _arch_side.has(key) and side < 0.0 and _arch_side[key] > 0.0:
				var y := at.y - p.origin.y
				for o in a["openings"]:
					var dx := at.x - float(o["x"])
					var half: float = o["half_span"]
					if absf(dx) < half and y < float(o["springing"]) + sqrt(maxf(half * half - dx * dx, 0.0)):
						note.emit("through the arch at x %.1f, %.1f u/s" % [at.x, plane.model.velocity.length()])
						if plane.model.velocity.length() >= float(a.get("pass_speed", tune.arch_pass_speed)):
							swell(5.0, 0.5)
							_whoosh.play()
							camera.kick_fov(tune.arch_pass_fov_kick)
						break
			_arch_side[key] = side


# --- Events ------------------------------------------------------------------------

func _on_star(pick: EndlessStars.Pickup) -> void:
	var tune := plane.tuning
	if pick.arc != _streak_arc or pick.broke:
		_streak = 0
	_streak_arc = pick.arc
	var value := tune.big_star_value if pick.star.big else 1
	stars_run += value
	_star.pitch_scale = pow(2.0, mini(_streak, tune.star_pitch_steps) / 12.0) * (1.5 if pick.star.big else 1.0)
	_star.play()
	_streak += 1
	_pop_star_label()
	if pick.first and pick.arc.stars.size() > 1:
		note.emit("arc started")
	if pick.star.big:
		_style_perfect.play()
		show_popup("Big star!  +%d" % value, true)
		note.emit("big star")
	if pick.full_arc:
		stars_run += tune.arc_bonus
		arcs_full += 1
		_style_perfect.play()
		show_popup("%s  +%d" % [pick.arc.title, tune.arc_bonus], true)
		note.emit("full arc (%s)" % pick.arc.title)
	elif pick.broke:
		note.emit("arc broken")


func _on_bumped(strength: float) -> void:
	super(strength)
	bumps += 1
	world.stars.break_current()
	note.emit("bump %.1f" % strength)


func _on_snagged() -> void:
	snags += 1
	_flutter.play()
	camera.shake(plane.tuning.bump_shake * 0.5)
	world.stars.break_current()
	note.emit("snag")


func _on_entered_thermal(zone: Thermal) -> void:
	super(zone)
	note.emit("into %s" % zone.name)


func _on_crashed() -> void:
	(_pop if plane.balloon else _crumple).play()
	camera.shake(plane.tuning.crash_shake)
	_finish("Popped!" if plane.balloon else "Crumpled!", plane.tuning.card_delay_crash, "crashed in %s" % piece_name)


func _on_stopped() -> void:
	_finish("Touchdown", plane.tuning.endless_card_delay_touchdown, "came to rest over %s" % piece_name)


## The run is over: stars go to the bank, bests are kept, and the card comes up after `delay`.
func _finish(title: String, delay: float, why: String) -> void:
	if _ended:
		return
	_ended = true
	ending = why
	_vario_beep.stop()
	var where_piece := world.piece_at(plane.global_position.z)
	if where_piece != null and title != "Wrong way!":
		title = "%s %s" % [title, where(where_piece)]  # "Touchdown in the Hamlet"
	var metres := int(EndlessWorld.metres(furthest_z))
	var score := metres * POINTS_PER_METRE + stars_run * plane.tuning.points_per_star
	var progress := Progress.load_all()
	var bank_before := int(progress["stars"])
	var paid := _bank_run(progress)
	var new_daily_best := false
	if daily:
		if progress["daily_date"] != daily_date:
			progress["daily_date"] = daily_date
			progress["daily_best_m"] = 0
		new_daily_best = metres > int(progress["daily_best_m"])
		progress["daily_best_m"] = maxi(int(progress["daily_best_m"]), metres)
	var new_best := metres > best_m
	best_m = maxi(best_m, metres)
	best_score = maxi(best_score, score)
	progress["best_m"] = best_m
	progress["best_score"] = best_score
	if not Progress.save_all(progress):
		push_warning("Could not save the stars and bests; they last until the game closes.")
	note.emit("ended: %s (%s) at %d m, %d stars" % [title, why, metres, stars_run])
	var news := {"bank": int(progress["stars"]), "new_best": new_best, "new_daily_best": new_daily_best, "paid": paid,
		"daily_best": int(progress["daily_best_m"]), "afford": _newly_affordable(bank_before, int(progress["stars"]), progress["owned"])}
	get_tree().create_timer(delay).timeout.connect(_show_card.bind(title, metres, score, news, _run_id))


## Adds the run's stars to `progress` (not saved here), and the daily bonus if this daily run
## reached its goal and the day hasn't been paid (checked afresh against the save). Returns the
## bonus paid.
func _bank_run(progress: Dictionary) -> int:
	var paid := 0
	if daily and daily_reached:
		var pays := Daily.reward(progress, daily_date)
		if pays["pays"]:
			paid = pays["stars"]
			progress["daily_paid"] = daily_date
			progress["daily_steps"] = pays["steps"]
	progress["stars"] = mini(int(progress["stars"]) + stars_run + paid, Progress.MAX_STARS)
	return paid


## The cheapest look not owned, if this run's banking has just made it affordable; otherwise "".
static func _newly_affordable(before: int, after: int, owned: Array) -> String:
	var id := HangarCatalogue.cheapest_unowned(owned)
	if id != "" and before < HangarCatalogue.price(id) and after >= HangarCatalogue.price(id):
		return id
	return ""


## Leaving for the title mid-run still banks the run's stars (the guide promises every star is
## kept, however the run ends); the run's distance doesn't count.
func go_to_title() -> void:
	if not _ended and (stars_run > 0 or (daily and daily_reached)):
		var progress := Progress.load_all()
		_bank_run(progress)
		stars_run = 0  # banked once
		daily_reached = false
		if not Progress.save_all(progress):
			push_warning("Could not save the stars; they last until the game closes.")
	super()


func _show_card(title: String, metres: int, score: int, news: Dictionary, run: int) -> void:
	if run != _run_id or not _ended:
		return  # a new run has already started
	var lines := PackedStringArray([
		"%d m" % metres,
		"Stars  %d   (bank %d)" % [stars_run, news["bank"]],
		"Score  %d" % score,
	])
	var note := "New best!" if news["new_best"] else ""
	if daily:
		if news["paid"] > 0:
			lines.append("Today's stars  +%d" % news["paid"])
		elif _daily_pays["pays"]:
			lines.append("Reach %d m for %d stars" % [Daily.GOAL_M, _daily_pays["stars"]])
		else:
			lines.append("Today's stars: paid today")
		lines.append("Today's best  %d m" % news["daily_best"])
		if note == "" and news["new_daily_best"]:
			note = "Today's best!"
	lines.append("Best  %d m" % best_m)
	if news["afford"] != "":
		lines.append("Enough for %s in the Hangar!" % HangarCatalogue.name_of(news["afford"]))
	_refresh_card_buttons()
	show_card(title, lines, _fly_again, note)


## Today's flight while its bonus is unpaid (normal runs); from a daily run, back to Endless.
func _refresh_card_buttons() -> void:
	var pays := Daily.reward(Progress.load_all(), Daily.today())
	_daily_button.text = "Daily +%d" % pays["stars"]
	_daily_button.visible = not daily and pays["pays"]
	_endless_button.visible = daily
	_course.visible = not daily


func _on_daily() -> void:
	daily_next = true
	start_run(false)


func _on_endless() -> void:
	start_run(false)


func _on_fly_again() -> void:
	daily_next = daily  # the daily's own card flies today's flight again
	start_run(false)


## Debug builds: the daily as if it were tomorrow.
func _on_next_day() -> void:
	var day := Daily.today()
	Daily.today_override = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(day + "T00:00:00") + 86400)
	_day_button.text = "Day +1 (%s)" % Daily.today_override.right(5)
	_refresh_card_buttons()


func _on_course() -> void:
	if get_tree().change_scene_to_file(COURSE_SCENE) == OK:
		Progress.note_mode(Progress.COURSE)


func _on_wind_button() -> void:
	var winds := [-1.0, 0.0, 1.5, 3.0]
	debug_wind = winds[(winds.find(debug_wind) + 1) % winds.size()]
	_wind_button.text = _wind_label()


func _wind_label() -> String:
	return "Wind rising" if debug_wind < 0.0 else "Wind %.1f" % debug_wind


# --- Screens ------------------------------------------------------------------------

func _setup_endless_ui() -> void:
	_daily_button = card_button("Daily")
	_daily_button.pressed.connect(_on_daily)
	_endless_button = card_button("Endless")
	_endless_button.pressed.connect(_on_endless)
	_course = card_button("Course")
	_course.pressed.connect(_on_course)
	if OS.is_debug_build():
		_day_button = Button.new()
		_day_button.text = "Day +1"
		_day_button.custom_minimum_size = Vector2(180, 64)
		_day_button.add_theme_font_size_override("font_size", 26)
		_day_button.pressed.connect(_on_next_day)
		_menu.get_parent().add_child(_day_button)
	if OS.is_debug_build():
		_wind_button = Button.new()
		_wind_button.text = _wind_label()
		_wind_button.custom_minimum_size = Vector2(180, 64)
		_wind_button.add_theme_font_size_override("font_size", 26)
		_wind_button.pressed.connect(_on_wind_button)
		_menu.get_parent().add_child(_wind_button)
	# The stars this run: a drawn star (not a glyph: phones' fonts may lack one) and the count.
	var stars_row := HBoxContainer.new()
	stars_row.add_theme_constant_override("separation", 6)
	stars_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	stars_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	stars_row.position += Vector2(-24, 42)
	stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(stars_row)
	var icon := StarIcon.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stars_row.add_child(icon)
	_star_label = Label.new()
	_star_label.add_theme_font_size_override("font_size", 22)
	_star_label.add_theme_color_override("font_color", Color("b8862a"))
	stars_row.add_child(_star_label)
	_daily_tag = Label.new()  # under the stars, in a daily run
	_daily_tag.text = "Daily"
	_daily_tag.add_theme_font_size_override("font_size", 18)
	_daily_tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_daily_tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_daily_tag.position += Vector2(-24, 70)
	_daily_tag.visible = false
	_ui.add_child(_daily_tag)
	_bar_track = ColorRect.new()
	_bar_track.color = Color(CREAM, 0.55)
	_bar_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_track.anchor_top = 0.25
	_bar_track.anchor_bottom = 0.75
	_bar_track.offset_left = 18.0
	_bar_track.offset_right = 28.0
	_ui.add_child(_bar_track)
	_bar_fill = ColorRect.new()
	_bar_fill.color = MINT
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_fill.anchor_left = 0.0
	_bar_fill.anchor_right = 1.0
	_bar_fill.anchor_bottom = 1.0
	_bar_track.add_child(_bar_fill)
	_fade = ColorRect.new()
	_fade.color = Color(CREAM, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_fade)
	_ui.move_child(_fade, 0)


func _update_hud() -> void:
	_hud.text = "%d m" % int(EndlessWorld.metres(furthest_z))
	if daily and _daily_pays.get("pays", false) and not daily_reached:  # gold until the daily's goal
		_hud.add_theme_color_override("font_color", Color("b8862a"))
	else:
		_hud.remove_theme_color_override("font_color")
	_star_label.text = str(stars_run)


func _pop_star_label() -> void:
	_star_label.pivot_offset = _star_label.size * Vector2(0.0, 0.5)
	_star_label.scale = Vector2.ONE * 1.15
	if _star_tween:
		_star_tween.kill()
	_star_tween = create_tween()
	_star_tween.tween_property(_star_label, "scale", Vector2.ONE, 0.15)


## The height bar: mint, filling with height over the ground below (up to height_bar_full);
## coral and pulsing below height_bar_warn.
func _update_height_bar(_delta: float) -> void:
	var tune := plane.tuning
	var at := plane.global_position
	var height := at.y - world.terrain_height(at.x, at.z)
	var k := clampf(height / maxf(tune.height_bar_full, 0.01), 0.0, 1.0)
	_bar_fill.anchor_top = 1.0 - k
	var low := height < tune.height_bar_warn and not plane.held
	_bar_fill.color = CORAL if low else MINT
	_bar_fill.modulate.a = (0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 1000.0 * PI * 2.0))) if low else 1.0


## A small gold five-pointed star, drawn.
class StarIcon extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var points := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + TAU * i / 10.0
			points.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
		draw_colored_polygon(points, EndlessStars.GOLD)
		points.append(points[0])
		draw_polyline(points, Color("b8862a"), 1.5, true)


# --- Debug overlay (F3, or tap the fps counter) -----------------------------------------------

func _build_overlay() -> void:
	var mi := MeshInstance3D.new()
	_overlay_lines = ImmediateMesh.new()
	mi.mesh = _overlay_lines
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("e86a9a")
	mat.no_depth_test = true
	mi.material_override = mat
	mi.visible = false
	add_child(mi)
	_overlay = mi
	_overlay_label = Label.new()
	_overlay_label.add_theme_font_size_override("font_size", 18)
	_overlay_label.position = Vector2(14, 34)
	_ui.add_child(_overlay_label)


func _update_overlay() -> void:
	_overlay_lines.clear_surfaces()
	for p in world.pieces:
		if not p.spawned:
			continue
		var line := world.line_for(p)
		if line.size() < 2:
			continue
		_overlay_lines.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for q in line:
			_overlay_lines.surface_add_vertex(q)
		_overlay_lines.surface_end()
	var p := world.piece_at(plane.global_position.z)
	_overlay_label.text = "tile %d  %s  d %.2f  need %.1f  out %.1f  h %.1f  wind %.1f" % [
		EndlessWorld.tile_at(plane.global_position.z), p.title() if p else "-", p.placement.d if p else 0.0,
		EndlessPieces.need_in(p.placement.id, p.placement.d) if p else 0.0, p.placement.h_out if p else 0.0,
		plane.global_position.y - EndlessWorld.FLOOR_Y, world.wind] if p else ""
