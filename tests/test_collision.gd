extends "res://tests/GdUnitTestSuite.gd"

const Collision = preload("res://src/game/Collision.gd")

func test_ball_brick_hit_detection() -> void:
	var brick: Dictionary = {
		"theta_center": 0.08,
		"z_center": 10.0,
		"theta_size": 0.5,
		"z_size": 1.0,
		"ball_theta_radius": 0.1,
		"ball_z_radius": 0.3
	}
	var hit: Dictionary = Collision.ball_vs_brick(0.12, 10.72, brick)
	expect_true(bool(hit.get("hit", false)), "Expected ball to overlap brick.")
	expect_equal(String(hit.get("axis", "")), "z")

func test_paddle_hit_reflection_signs() -> void:
	var paddle_hit: bool = Collision.ball_vs_paddle(0.2, 3.0, 0.0, 1.0, 3.0)
	expect_true(paddle_hit, "Expected paddle overlap when ball is inside paddle arc.")

	var left_reflect: Dictionary = Collision.reflect_from_paddle(0.0, -8.0, -0.25, 0.0, 1.0, 1.6)
	var right_reflect: Dictionary = Collision.reflect_from_paddle(0.0, -8.0, 0.25, 0.0, 1.0, 1.6)
	expect_true(float(left_reflect.get("v_theta", 0.0)) < 0.0, "Left offset should add negative spin.")
	expect_true(float(right_reflect.get("v_theta", 0.0)) > 0.0, "Right offset should add positive spin.")
	expect_true(float(left_reflect.get("v_z", -1.0)) > 0.0, "Paddle reflection must flip z velocity positive.")
