extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")

func test_portal_animation_speed_increases_with_ball_speed() -> void:
	var slow_speed: float = GameController.portal_animation_speed_for_ball_velocity(7.0, 0.1)
	var fast_speed: float = GameController.portal_animation_speed_for_ball_velocity(15.0, 1.2)
	assert_true(fast_speed > slow_speed, "Portal animation speed should increase as ball velocity increases")

func test_portal_animation_speed_is_bounded_for_mobile_shader() -> void:
	var speed: float = GameController.portal_animation_speed_for_ball_velocity(100.0, 100.0)
	assert_true(speed <= 1.85, "Portal animation speed should stay within the shader's mobile-safe range")
	assert_true(speed >= 0.46, "Portal animation speed should not drop below the visible motion floor")

func test_portal_animation_speed_smooths_jolting_changes() -> void:
	var current_speed: float = 0.46
	var target_speed: float = 1.85
	var next_speed: float = GameController.smoothed_portal_animation_speed(current_speed, target_speed, 1.0 / 60.0)
	assert_true(next_speed > current_speed, "Portal animation speed should accelerate toward the target")
	assert_true(next_speed < target_speed, "Portal animation speed should not snap to sudden target changes")
