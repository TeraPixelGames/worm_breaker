extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")

func test_tunnel_texture_speed_increases_with_ball_speed() -> void:
	var slow_speed: float = GameController.tunnel_texture_speed_for_ball_velocity(7.0, 0.1)
	var fast_speed: float = GameController.tunnel_texture_speed_for_ball_velocity(18.0, 1.2)
	assert_true(fast_speed > slow_speed, "Tunnel texture speed should increase with ball speed")

func test_tunnel_texture_speed_is_bounded() -> void:
	var speed: float = GameController.tunnel_texture_speed_for_ball_velocity(100.0, 100.0)
	assert_true(speed <= 2.6, "Tunnel texture speed should stay within the readable range")
	assert_true(speed >= 0.62, "Tunnel texture speed should keep visible depth motion")

func test_tunnel_texture_speed_smooths_changes() -> void:
	var next_speed: float = GameController.smoothed_tunnel_texture_speed(0.62, 2.6, 1.0 / 60.0)
	assert_true(next_speed > 0.62, "Tunnel texture speed should accelerate toward target")
	assert_true(next_speed < 2.6, "Tunnel texture speed should not snap to target")
