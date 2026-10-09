extends SceneTree
## Headless test runner. From the project folder:
##   godot --headless --fixed-fps 60 -s res://tests/run_tests.gd
## Set TEST_ONLY=<text> to run only tests whose names contain <text>.
## Exits with code 1 if any test fails.

const SUITES := [
	"res://tests/test_flight_model.gd",
	"res://tests/test_controls.gd",
	"res://tests/test_plane_physics.gd",
	"res://tests/test_course.gd",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var passed := 0
	var failed := 0
	var only := OS.get_environment("TEST_ONLY")
	for path in SUITES:
		if not ResourceLoader.exists(path):
			continue
		print(path.get_file())
		var suite: TestCase = load(path).new()
		suite.tree = self
		for method in suite.get_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_") or (only != "" and not test_name.contains(only)):
				continue
			suite.failures.clear()
			await suite.call(test_name)
			await suite.cleanup()
			if suite.failures.is_empty():
				passed += 1
				print("  ok    ", test_name)
			else:
				failed += 1
				print("  FAIL  ", test_name)
				for f in suite.failures:
					print("        ", f)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
