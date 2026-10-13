# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Drawing the plane bigger, and as a balloon: only the looks change, never the flight.


func _plane(at: Vector3, look: String, input := Vector2(0.3, 0.4)) -> Flyer:
	var plane := Flyer.new()
	add_node(plane)
	plane.set_look(look)
	plane.launch(at, 0.0)
	plane.autopilot = func(_p: Flyer) -> Vector2: return input
	return plane


func _floor(y: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0.0, y - 0.5, 0.0)
	add_node(body)


func test_plane_is_drawn_bigger_but_collides_the_same() -> void:
	var plane := _plane(Vector3(0.0, 10.0, 0.0), PlayerSettings.PLANE)
	await physics_frames(2)
	var shape := (plane.get_child(0) as CollisionShape3D).shape as SphereShape3D
	check(is_equal_approx(shape.radius, Flyer.RADIUS), "the collision sphere keeps its size (%.2f)" % shape.radius)
	check_between(plane._visual.basis.get_scale().x, 1.29, 1.31, "the plane's drawn scale")


func test_balloon_flies_exactly_like_the_plane() -> void:
	_floor(0.0)
	var a := _plane(Vector3(0.0, 12.0, 0.0), PlayerSettings.PLANE)
	var b := _plane(Vector3(30.0, 12.0, 0.0), PlayerSettings.BALLOON)
	for i in 240:
		await physics_frames(1)
		var gap := b.global_position - a.global_position - Vector3(30.0, 0.0, 0.0)
		if gap.length() > 1e-4:
			check(false, "tick %d: the balloon drifted %.5f from the plane's path (allowed: 1e-4, float rounding 30 units apart)" % [i, gap.length()])
			return
	check(a.model.velocity.is_equal_approx(b.model.velocity), "same speed after 4 s")
	check(a.balloon == false and b.balloon == true, "looks as set")
	check(not a._balloon.visible and a._visual.visible, "the plane shows the paper dart only")
	check(b._balloon.visible and not b._visual.visible and b._string_mesh.visible, "the balloon shows the balloon and its string")


func test_balloon_string_keeps_its_length_and_trails_behind() -> void:
	var plane := _plane(Vector3(0.0, 20.0, 0.0), PlayerSettings.BALLOON, Vector2.ZERO)
	await physics_frames(60)
	for t in 4:  # and it stays that way, without whipping about
		await physics_frames(15)
		var trail := plane.string_points[Flyer.STRING_POINTS - 1] - plane.string_points[0]
		check(trail.z > 0.8 and trail.y < -0.3, "%.2f s: the string trails back and down (%s)" % [1.0 + t * 0.25, trail])
	var pts := plane.string_points
	var tune := plane.tuning
	var segment := tune.balloon_string_length * tune.look_scale / (Flyer.STRING_POINTS - 1)
	check(pts[0].is_equal_approx(plane.knot_position()), "the string is tied to the knot")
	for i in range(1, pts.size()):
		check_between(pts[i].distance_to(pts[i - 1]), segment * 0.99, segment * 1.01, "segment %d" % i)
	var end := pts[pts.size() - 1]
	check(end.y < pts[0].y, "the string hangs below the knot")
	check(end.z > pts[0].z + 0.3, "flying toward -Z, the string trails behind (+Z): %.2f" % (end.z - pts[0].z))


func test_crashed_balloon_pops_and_its_string_falls_to_the_floor() -> void:
	_floor(0.0)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 20.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 5.0, -6.0)
	add_node(wall)
	var plane := _plane(Vector3(0.0, 5.0, 0.0), PlayerSettings.BALLOON, Vector2.ZERO)
	await physics_frames(60)
	check(plane.model.crashed, "flew into the wall")
	check(not plane._balloon_body.visible, "the balloon popped")
	await physics_frames(180)
	for p in plane.string_points:
		check(p.y >= 0.0 and p.y < 0.2, "the string lies on the floor (y %.2f)" % p.y)


func test_look_choice_is_saved_and_bad_files_mean_the_balloon() -> void:
	var path := "user://test_look_%d.json" % OS.get_process_id()
	check(PlayerSettings.save_look(PlayerSettings.BALLOON, path), "saves")
	check(PlayerSettings.load_look(path) == PlayerSettings.BALLOON, "balloon comes back")
	check(PlayerSettings.save_look(PlayerSettings.PLANE, path), "saves")
	check(PlayerSettings.load_look(path) == PlayerSettings.PLANE, "plane comes back")
	for junk in ["", "{", "[1,2]", "{\"look\": 7}", "{\"look\": \"rocket\"}", "x".repeat(2000)]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(junk)
		f.close()
		check(PlayerSettings.load_look(path) == PlayerSettings.BALLOON, "junk %s... falls back to the balloon" % junk.left(12))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(PlayerSettings.load_look(path) == PlayerSettings.BALLOON, "no file means the balloon, the default")


func test_game_flies_the_saved_look_and_the_card_swaps_it() -> void:
	# A player who chose the paper plane gets it, though the balloon is the default.
	PlayerSettings.save_look(PlayerSettings.PLANE)
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	check(not (game.plane as Flyer).balloon, "the saved paper plane is flown")
	check(game._swap_look.text == "Fly the balloon", "the card offers the balloon back")
	game.save_other_look()
	check(PlayerSettings.load_look() == PlayerSettings.BALLOON, "the button swaps the saved choice to the balloon")
	# A plane crash crumples it, with the paper crumple and not the pop.
	(game.plane as Flyer).crashed.emit()
	check(game._crumple.playing and not game._pop.playing, "a plane crash plays the crumple")
	await cleanup()
	# With nothing saved, the balloon is flown, and a crash pops it.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlayerSettings.file_path))
	var fresh: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	check((fresh.plane as Flyer).balloon, "a first-timer flies the balloon")
	check(fresh._swap_look.text == "Fly the paper plane", "and the card offers the plane")
	(fresh.plane as Flyer).crashed.emit()
	check(fresh._pop.playing and not fresh._crumple.playing, "a balloon crash plays the pop")


func test_relaunching_a_popped_balloon_restores_it() -> void:
	_floor(0.0)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 20.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 5.0, -6.0)
	add_node(wall)
	var plane := _plane(Vector3(0.0, 5.0, 0.0), PlayerSettings.BALLOON, Vector2.ZERO)
	await physics_frames(60)
	check(plane.model.crashed and not plane._balloon_body.visible, "popped")
	plane.launch(Vector3(0.0, 5.0, 10.0), PI)  # away from the wall
	await physics_frames(10)
	check(plane._balloon_body.visible and plane._scraps.is_empty(), "a new flight has a whole balloon and no scraps")
	check(plane.string_points[0].distance_to(plane.knot_position()) < 0.01, "the string is tied on again")


## Settings: each setting is checked on load, and bad or missing ones fall back to defaults.
func test_settings_are_checked_and_bad_values_fall_back() -> void:
	var path := "user://test_settings_all_%d.json" % OS.get_process_id()
	check(PlayerSettings.save_all({"look": "balloon", "sensitivity": 1.5, "sound": false, "invert_pitch": true}, path), "saves")
	var s := PlayerSettings.load_all(path)
	check(s["look"] == "balloon" and is_equal_approx(s["sensitivity"], 1.5) and s["sound"] == false and s["invert_pitch"] == true, "everything comes back: %s" % s)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string('{"look": 3, "sensitivity": 99, "sound": "yes", "invert_pitch": 1, "cheat": true}')
	f.close()
	s = PlayerSettings.load_all(path)
	check(s == {"look": "balloon", "sensitivity": PlayerSettings.SENSITIVITY_MAX, "sound": true, "invert_pitch": false}, "bad values fall back or are clamped, unknown keys dropped: %s" % s)
	PlayerSettings.save_look("plane", path)
	check(PlayerSettings.load_all(path)["look"] == "plane" and PlayerSettings.load_all(path)["sensitivity"] == PlayerSettings.SENSITIVITY_MAX, "changing the look keeps the other settings")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## The settings panel changes the flight at once and saves: sensitivity, sound, swapped climb.
func test_settings_panel_applies_and_saves() -> void:
	PlayerSettings.save_all(PlayerSettings.DEFAULTS)
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	var plane := game.plane as Flyer
	game.show_settings(true)
	check(game._settings_panel.visible and not game._card.visible, "the panel opens")
	game._sensitivity.value = 1.5
	game._sound.button_pressed = false
	game._swap_pitch.button_pressed = true
	var master := AudioServer.get_bus_index("Master")
	check(is_equal_approx(plane.controls.sensitivity_scale, 1.5) and plane.controls.swap_climb_dive, "tilt settings apply")
	check(AudioServer.is_bus_mute(master), "sound off mutes the game")
	var saved := PlayerSettings.load_all()
	check(is_equal_approx(saved["sensitivity"], 1.5) and saved["sound"] == false and saved["invert_pitch"] == true, "and they are saved: %s" % saved)
	var keys_dive := plane.controls.update(1.0, Vector3.ZERO, Vector2(-1.0, 0.0))  # Up/W, normally a dive
	check(keys_dive.x > 0.0, "swapped: the dive key climbs (%.2f)" % keys_dive.x)
	game.show_settings(false)
	check(not game._settings_panel.visible, "Done closes it")
	PlayerSettings.save_all(PlayerSettings.DEFAULTS)
	game.settings = PlayerSettings.DEFAULTS.duplicate()
	game.apply_settings()
	check(not AudioServer.is_bus_mute(master), "(sound back on for the other tests)")
