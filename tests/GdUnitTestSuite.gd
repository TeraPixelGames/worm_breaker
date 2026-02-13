extends RefCounted
class_name GdUnitTestSuite

var _failures: Array[String] = []

func clear_failures() -> void:
	_failures.clear()

func consume_failures() -> Array[String]:
	var copy: Array[String] = _failures.duplicate()
	_failures.clear()
	return copy

func expect_true(value: bool, message: String = "Expected value to be true.") -> void:
	if not value:
		_failures.append(message)

func expect_false(value: bool, message: String = "Expected value to be false.") -> void:
	if value:
		_failures.append(message)

func expect_equal(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		var msg: String = message if message != "" else "Expected %s but got %s." % [str(expected), str(actual)]
		_failures.append(msg)

func expect_approx(actual: float, expected: float, epsilon: float = 0.0001, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		var msg: String = message if message != "" else "Expected %.6f but got %.6f." % [expected, actual]
		_failures.append(msg)
