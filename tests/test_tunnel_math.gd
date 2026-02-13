extends "res://tests/GdUnitTestSuite.gd"

const TunnelMath = preload("res://src/game/TunnelMath.gd")

func test_wrap_angle() -> void:
	expect_approx(TunnelMath.wrap_angle(0.0), 0.0, 0.0001)
	expect_approx(TunnelMath.wrap_angle(PI * 1.5), -PI * 0.5, 0.0001)
	expect_approx(TunnelMath.wrap_angle(-PI * 1.5), PI * 0.5, 0.0001)

func test_theta_overlap_seam_case() -> void:
	var a_center: float = PI - 0.08
	var b_center: float = -PI + 0.05
	expect_true(TunnelMath.theta_overlap(a_center, 0.12, b_center, 0.12), "Expected seam overlap across -PI/PI.")
	expect_false(TunnelMath.theta_overlap(a_center, 0.02, b_center, 0.02), "Expected seam non-overlap for narrow arcs.")
