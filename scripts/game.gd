# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends FlightGame
## Runs one flight of the Course: starts the plane in the air in the bedroom (seen from the kid
## who threw it), keeps score, and shows the end card with distance, style, total, best, "Fly
## again", Endless once it is unlocked, a button to swap between the balloon and the paper
## plane, settings and "Quit". What every flight shares (sounds, settings, About, Back) is in
## FlightGame.

@onready var course: Course = $Course

var reached_outside := false
var crossed_gap := false  ## Through the Gap's saddle this flight.
var scoring: Scoring
var best_score := 0
var _drifting: Array[Thermal] = []  ## The outdoor columns, which drift with the breeze.
var _clouds: Clouds
## The gull that joins you on each ridge (looks only).
var gull: Gull
## Has the "keep circling" hint been shown this run?
var circle_hint_shown := false
## The card's Endless button, once Endless is unlocked (or null).
var _endless: Button
## Endless was unlocked by this flight (the card says so).
var unlocked_endless := false


func _ready() -> void:
	scoring = Scoring.new(plane.tuning, Course.spine(), Course.style_moment_defs())
	scoring.style_awarded.connect(_on_style_awarded)
	best_score = BestScore.load_best()
	plane.bounds = Course.WORLD_BOUNDS
	for node in get_tree().get_nodes_in_group("thermals"):
		if (node as Thermal).drifts():
			_drifting.append(node)
	gull = Gull.new()
	gull.name = "Gull"
	add_child(gull)
	var ridges: Array[Thermal] = [course.get_node("RidgeLift"), course.get_node("BluffLift")]
	gull.setup(plane, ridges)
	_clouds = course.get_node_or_null("Clouds")
	if _clouds != null:
		_clouds.tuning = plane.tuning
	_setup_flight("Tilt to fly" if OS.has_feature("mobile") else "Arrow keys or WASD to fly")
	if Progress.load_all()["unlocked"]:
		_add_endless_button()
	plane.bumped.connect(_on_bumped)
	plane.crashed.connect(_on_crashed)
	plane.stopped.connect(_on_stopped)
	plane.entered_thermal.connect(_on_entered_thermal)
	plane.launch(Course.START, Course.START_HEADING)
	plane.held = true
	camera.target = plane
	camera.start_intro(Course.KID_EYE)
	if OS.is_debug_build():
		var overlay := DebugOverlay.new()
		add_child(overlay)
		overlay.build(scoring, Course.spine())
		_overlay = overlay


func ground_under(x: float, z: float) -> float:
	return Course.terrain_height(x, z)


func water_level(_x: float, _z: float) -> float:
	return Course.LAKE_Y


func is_outdoors(at: Vector3) -> bool:
	return Course.is_outside(at)


func section_name(at: Vector3) -> String:
	return Course.section_at(at)


func _physics_process(delta: float) -> void:
	if not plane.held and not plane.is_ended():
		scoring.update(plane.global_position)
		for zone in _drifting:
			zone.drift(delta, plane.global_position, plane.tuning)
		if _clouds != null:
			_clouds.note_plane(plane.global_position, vario.on)
		if Course.is_outside(plane.global_position) and not plane.model.grounded:
			scoring.add_airtime(delta)
		_check_close_call(delta)
		_tick_sounds(delta)


## Which air zones are drawn: indoor ones while the camera is in the house, outdoor ones from
## the kitchen on (they show through the window). Out of sight, they cost nothing to draw.
var _zones_seen := -1  ## See _show_zones_near_camera(): 0 indoors .. 4 in the bowl.


## The chalk pit's warm air shows from the valley and the bowl alike.
const CHALK_ZONE := &"ChalkHeat"
## At the Gap, the valley's zones nearer the house than this (z) are left undrawn: they are far
## behind, and their motes would only add to the bowl's.
const GAP_VALLEY_Z := -200.0


func _show_zones_near_camera() -> void:
	var p := camera.global_position
	var seen := 0
	if p.z < Course.CREST_Z:
		seen = 4  # in the bowl
	elif p.z < Course.GAP_VIEW_Z:
		seen = 3  # at the Gap, looking through
	elif Course.is_outside(p):
		seen = 2
	elif p.z < Course.DIVIDER_Z:
		seen = 1  # the kitchen, looking out of the window
	if seen == _zones_seen:
		return
	_zones_seen = seen
	for node in get_tree().get_nodes_in_group("thermals"):
		var zone := node as Thermal
		if not zone.outdoors:
			zone.set_shown(seen <= 1)
		elif zone.name == CHALK_ZONE:
			zone.set_shown(seen >= 1)
		elif zone.global_position.z < Course.CREST_Z:
			zone.set_shown(seen >= 3)  # the bowl's zones
		elif seen == 3:
			zone.set_shown(zone.global_position.z < GAP_VALLEY_Z)  # at the Gap: only the valley's far end
		else:
			zone.set_shown(seen >= 1 and seen <= 2)  # the valley's


func _process(delta: float) -> void:
	_show_zones_near_camera()
	if plane.held:
		_throw_when_ready(delta)
	var tune := plane.tuning
	if not reached_outside and Course.is_outside(plane.global_position):
		reached_outside = true
		swell(tune.window_gust_db, tune.window_gust_fade)
		_whoosh.play()
	var at := plane.global_position
	if not crossed_gap and at.z < Course.SADDLE.x and absf(at.x - Course.GAP_X) < 30.0 and not plane.is_ended():
		crossed_gap = true  # the reveal: a gust, a whoosh and the view opening up
		swell(tune.gap_gust_db, tune.gap_gust_fade)
		_whoosh.play()
		camera.kick_fov(tune.camera_fov_gap_kick)
	_hud.text = "%.0f m" % scoring.distance_meters()  # rounded the same way as on the end card
	_update_wind_and_debug(delta)


func distance_meters() -> float:
	return scoring.distance_meters()


# --- Events --------------------------------------------------------------------

func _on_entered_lift(zone: Thermal) -> void:
	var tune := plane.tuning
	if zone.look != Thermal.Look.RIDGE and not circle_hint_shown and plane.global_position.y < tune.circle_hint_below:
		circle_hint_shown = true
		show_hint("Keep circling to climb", tune.circle_hint_seconds)


## A cheerful pop-up and sound for style points; a near-perfect pass gets a bigger, golden
## pop-up and a brighter sparkle.
func _on_style_awarded(_id: StringName, title: String, points: int, quality: float) -> void:
	var perfect := quality >= plane.tuning.style_perfect_quality
	(_style_perfect if perfect else _style_good).play()
	show_popup(("Perfect %s!  +%d" % [title.to_lower(), points]) if perfect else ("%s  +%d" % [title, points]), perfect)


func _on_crashed() -> void:
	(_pop if plane.balloon else _crumple).play()
	camera.shake(plane.tuning.crash_shake)
	_finish("Crumpled!", plane.tuning.card_delay_crash)


func _on_stopped() -> void:
	if _ended:
		return
	var p := plane.global_position
	var splashed := Course.on_water(p)
	if p.y - Course.terrain_height(p.x, p.z) < 1.0 and not splashed:  # resting on the grass, not up in a tree
		scoring.land(p, Course.landing_spots())
	var title := "You flew outside!" if reached_outside else "Touchdown"
	if crossed_gap:
		title = "Through the Gap!"  # past the saddle, where the gust blew
	if splashed:
		title = "Splashdown!"  # not a crash: the airtime counts, there's just no bonus
		_splash_at(p, Course.LAKE_Y)
	if not scoring.landing.is_empty():
		title = scoring.landing["title"]
	if reached_outside:
		_unlock_endless()
	_finish(title, plane.tuning.card_delay_landed)


## A flight that comes to rest outdoors, not crashed, unlocks Endless (saved at once).
func _unlock_endless() -> void:
	if Progress.unlock():
		unlocked_endless = true
		_add_endless_button()


func _add_endless_button() -> void:
	if _endless != null:
		return
	_endless = card_button("Endless")
	_endless.pressed.connect(_on_endless)


func _on_endless() -> void:
	if get_tree().change_scene_to_file(EndlessGame.SCENE) == OK:
		Progress.note_mode(Progress.ENDLESS)


func _finish(title: String, delay: float) -> void:
	if _ended:
		return
	_ended = true
	_vario_beep.stop()
	var total := scoring.total()
	var new_best := total > best_score
	if new_best:
		best_score = total
		if not BestScore.save_best(total):
			push_warning("Could not save the best score; it is kept until the game closes.")
	# A timer signal rather than `await`: if the scene goes away first, nothing is left waiting.
	get_tree().create_timer(delay).timeout.connect(_show_card.bind(title, total, new_best))


func _show_card(title: String, total: int, new_best: bool) -> void:
	var hit := scoring.moments.filter(func(m: Scoring.Moment) -> bool: return m.award > 0).size()
	var lines := PackedStringArray([
		"Distance  %.0f m = %d" % [scoring.distance_meters(), scoring.distance_points()],
		"Style  %d   (%d of %d moments)" % [scoring.style_points, hit, scoring.moments.size()],
	])
	if scoring.airtime_points() > 0:
		lines.append("Airtime  %d s = %d" % [scoring.airtime_seconds(), scoring.airtime_points()])
	if scoring.landing_points > 0:
		lines.append("%s  +%d" % [String(scoring.landing["title"]).trim_suffix("!"), scoring.landing_points])
	lines.append("Total  %d" % total)
	lines.append("%s  %d" % ["New best!" if new_best else "Best", best_score])
	if unlocked_endless:
		_style_perfect.play()  # the sparkle, the first time only
	show_card(title, lines, _endless if unlocked_endless else _fly_again, "Endless unlocked!" if unlocked_endless else "")
