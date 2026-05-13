extends "res://tests/framework/TestCase.gd"

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
	assert_true(bool(hit.get("hit", false)), "Expected ball to overlap brick.")
	assert_equal(String(hit.get("axis", "")), "z", "Expected z-axis brick response.")

func test_paddle_hit_reflection_signs() -> void:
	var paddle_hit: bool = Collision.ball_vs_paddle(0.2, 3.0, 0.0, 1.0, 3.0)
	assert_true(paddle_hit, "Expected paddle overlap when ball is inside paddle arc.")

	var left_reflect: Dictionary = Collision.reflect_from_paddle(0.0, -8.0, -0.25, 0.0, 1.0, 1.6)
	var right_reflect: Dictionary = Collision.reflect_from_paddle(0.0, -8.0, 0.25, 0.0, 1.0, 1.6)
	assert_true(float(left_reflect.get("v_theta", 0.0)) < 0.0, "Left offset should add negative spin.")
	assert_true(float(right_reflect.get("v_theta", 0.0)) > 0.0, "Right offset should add positive spin.")
	assert_true(float(left_reflect.get("v_z", -1.0)) > 0.0, "Paddle reflection must flip z velocity positive.")

func test_paddle_hit_includes_ball_radius_at_visual_edge() -> void:
	var center_miss_without_radius := Collision.ball_vs_paddle(0.58, 3.0, 0.0, 1.0, 3.0)
	assert_true(not center_miss_without_radius, "Without ball radius, edge overlap should miss.")

	var edge_hit_with_radius := Collision.ball_vs_paddle(0.58, 3.0, 0.0, 1.0, 3.0, 0.12)
	assert_true(edge_hit_with_radius, "Expected ball radius to catch visible paddle edge overlap.")
