extends SceneTree

const TEST_SUITES: PackedStringArray = [
	"res://tests/test_tunnel_math.gd",
	"res://tests/test_collision.gd"
]

var _total_tests: int = 0
var _failed_tests: int = 0

func _initialize() -> void:
	for suite_path in TEST_SUITES:
		_run_suite(suite_path)

	if _failed_tests == 0:
		print("All tests passed (%d)." % _total_tests)
		quit(0)
		return

	printerr("Tests failed: %d/%d." % [_failed_tests, _total_tests])
	quit(1)

func _run_suite(suite_path: String) -> void:
	var script: Script = load(suite_path) as Script
	if script == null:
		_failed_tests += 1
		_total_tests += 1
		printerr("Failed to load suite: %s" % suite_path)
		return

	var suite: Variant = script.new()
	if suite == null:
		_failed_tests += 1
		_total_tests += 1
		printerr("Suite does not extend GdUnitTestSuite: %s" % suite_path)
		return

	for method_info in script.get_script_method_list():
		var method_name: String = String(method_info.get("name", ""))
		if not method_name.begins_with("test_"):
			continue
		_total_tests += 1
		suite.clear_failures()
		suite.call(method_name)
		var failures: Array[String] = suite.consume_failures()
		if failures.is_empty():
			print("PASS %s::%s" % [suite_path, method_name])
			continue

		_failed_tests += 1
		for failure in failures:
			printerr("FAIL %s::%s -> %s" % [suite_path, method_name, failure])
