# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## Progress (the Endless save) and unlocking Endless from the Course.


func _fresh(best := 0) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	if best > 0:
		BestScore.save_best(best)
	Progress.unlocked_this_session = false


func _write(text: String) -> void:
	var f := FileAccess.open(Progress.file_path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_bad_progress_files_load_as_defaults() -> void:
	_fresh()
	var bad := ["", "{", "[]", "null", "\"text\"", "{\"unlocked\": \"yes\", \"stars\": -3, \"best_m\": 3.5, \"best_score\": 1e400, \"last_mode\": \"moon\"}",
		"{\"unlocked\": 1, \"stars\": 100000001, \"best_m\": [], \"best_score\": {}, \"last_mode\": 7}", "{\"stars\": 1e300}"]
	for text: String in bad:
		_write(text)
		var p := Progress.load_all()
		check(p == Progress.DEFAULTS, "%s loads as the defaults: %s" % [text.left(40), p])
	_write("{\"stars\": 5, \"pad\": \"%s\"}" % "x".repeat(Progress.MAX_BYTES))
	check(Progress.load_all()["stars"] == 0, "an oversized file is ignored")
	_write("{\"stars\": 5, \"cheat\": true}")
	check(not Progress.load_all().has("cheat"), "unknown fields are dropped")


func test_progress_saves_and_loads_back() -> void:
	_fresh()
	var p := {"unlocked": true, "stars": 1204, "best_m": 412, "best_score": 4750, "last_mode": Progress.ENDLESS}
	check(Progress.save_all(p), "saved")
	check(Progress.load_all() == p, "loads back exactly: %s" % Progress.load_all())
	Progress.note_mode(Progress.COURSE)
	check(Progress.load_all()["last_mode"] == Progress.COURSE and Progress.load_all()["stars"] == 1204, "noting the mode keeps the rest")


## Decision 9: a Course best of 1500 or more from before Endless existed unlocks it, checked once,
## the first time there is no progress file. Afterwards only flying unlocks it.
func test_an_old_high_best_unlocks_once_when_there_is_no_file() -> void:
	_fresh(1600)
	check(Progress.load_all()["unlocked"], "a first launch with a best of 1600 is unlocked")
	check(FileAccess.file_exists(Progress.file_path), "and the file is started")
	_fresh(1400)
	check(not Progress.load_all()["unlocked"], "a best of 1400 is not")
	# A new player whose file was started locked, who then crashes with a big score: still locked.
	BestScore.save_best(1600)
	check(not Progress.load_all()["unlocked"], "a big score after the file exists unlocks nothing by itself")
	_fresh()


func _game() -> Node:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	return game


func test_coming_to_rest_outdoors_unlocks_endless_with_a_gold_line() -> void:
	_fresh()
	var game: Node = await _game()
	check(game._endless == null, "no Endless button before it is unlocked")
	var lone: Button = game._fly_again
	game._card.visible = true
	await tree.process_frame
	check(lone.size.x > 600.0, "a lone Fly again fills the card's width (%.0f)" % lone.size.x)
	game._card.visible = false
	game.reached_outside = true
	game._on_stopped()
	check(Progress.load_all()["unlocked"], "unlocked and saved at once")
	check(game.unlocked_endless and game._endless != null, "the card gets an Endless button")
	await tree.create_timer(game.plane.tuning.card_delay_landed + 0.2).timeout
	check(game._card_note.visible and game._card_note.text == "Endless unlocked!", "with the gold line")
	check(game._endless.has_focus(), "and Endless is the button to press")
	check(game._endless.size.x >= 340.0 and game._fly_again.size.x >= 340.0, "two big buttons share the row")


func test_a_crash_or_staying_indoors_does_not_unlock() -> void:
	_fresh()
	var game: Node = await _game()
	game.reached_outside = true
	game._on_crashed()
	game._on_stopped()  # a crashed run never gets here in play; even so, it is over
	check(not Progress.load_all()["unlocked"], "a crash outdoors unlocks nothing")
	await cleanup()
	_fresh()
	game = await _game()
	game._on_stopped()  # at rest, but never outside
	check(not Progress.load_all()["unlocked"], "coming to rest in the house unlocks nothing")


func test_once_unlocked_the_button_is_always_there_and_the_line_shows_once() -> void:
	_fresh()
	Progress.save_all({"unlocked": true})
	var game: Node = await _game()
	check(game._endless != null, "an unlocked player always has Endless on the card")
	game.reached_outside = true
	game._on_stopped()
	check(not game.unlocked_endless, "landing again is not news")
	await tree.create_timer(game.plane.tuning.card_delay_landed + 0.2).timeout
	check(not game._card_note.visible, "no gold line")
	check(game._fly_again.has_focus(), "focus on the mode just flown")
