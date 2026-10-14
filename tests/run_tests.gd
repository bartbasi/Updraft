# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Headless test runner. From the project folder:
##   godot --headless --fixed-fps 60 -s res://tests/run_tests.gd
## Set TEST_ONLY=<text> to run only tests whose names contain <text>.
## Exits with code 1 if any test fails.

const SUITES := [
	"res://tests/test_flight_model.gd",
	"res://tests/test_controls.gd",
	"res://tests/test_plane_physics.gd",
	"res://tests/test_scoring.gd",
	"res://tests/test_opening.gd",
	"res://tests/test_course.gd",
	"res://tests/test_game_scoring.gd",
	"res://tests/test_balloon.gd",
	"res://tests/test_vario.gd",
	"res://tests/test_about.gd",
	"res://tests/test_progress.gd",
	"res://tests/test_endless.gd",
	"res://tests/test_endless_step2.gd",
	"res://tests/test_title.gd",
]


## Game-time seconds before a stuck run gives up and fails (under --fixed-fps every frame is
## 1/60 s, so this is the total flight time of the whole suite plus room to grow).
const TIME_LIMIT := 3600.0

var _errors := ErrorCatcher.new()


## Collects engine and script errors as they happen, so a test that hits one fails instead
## of quietly passing. (A GDScript runtime error just stops the test function.)
class ErrorCatcher extends Logger:
	var _mutex := Mutex.new()
	var _found := PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_found.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func take() -> PackedStringArray:
		_mutex.lock()
		var found := _found.duplicate()
		_found.clear()
		_mutex.unlock()
		return found


func _initialize() -> void:
	OS.add_logger(_errors)
	create_timer(TIME_LIMIT, true, false, true).timeout.connect(func() -> void:
		print("\nTIMED OUT after %d s" % TIME_LIMIT)
		quit(1))
	_run.call_deferred()


func _run() -> void:
	# Keep the player's real best score out of the tests (and each run its own files: two can run at once).
	BestScore.file_path = "user://test_best_score_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	# ...and their choice of plane or balloon.
	PlayerSettings.file_path = "user://test_settings_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlayerSettings.file_path))
	# ...and their Endless progress.
	Progress.file_path = "user://test_progress_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
	var passed := 0
	var failed := 0
	var only := OS.get_environment("TEST_ONLY")
	for path in SUITES:
		if not ResourceLoader.exists(path):
			continue
		print(path.get_file())
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed += 1
			print("  FAIL  could not load %s (script error)" % path.get_file())
			continue
		var suite: TestCase = script.new()
		suite.tree = self
		for method in suite.get_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_") or (only != "" and not test_name.contains(only)):
				continue
			suite.failures.clear()
			_errors.take()
			await suite.call(test_name)
			await suite.cleanup()
			# Whatever a test did to the player's settings or the sound, the next starts clean.
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PlayerSettings.file_path))
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
			Progress.unlocked_this_session = false
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
			for error in _errors.take():
				suite.failures.append("error during the test: " + error)
			if suite.failures.is_empty():
				passed += 1
				print("  ok    ", test_name)
			else:
				failed += 1
				print("  FAIL  ", test_name)
				for f in suite.failures:
					print("        ", f)
	print("\n%d passed, %d failed" % [passed, failed])
	for _i in 10:
		OS.delay_msec(20)
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BestScore.file_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlayerSettings.file_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
	quit(1 if failed > 0 else 0)
