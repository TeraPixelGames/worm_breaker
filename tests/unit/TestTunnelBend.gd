extends "res://tests/framework/TestCase.gd"

const LevelLoader: Script = preload("res://src/game/LevelLoader.gd")
const TunnelMath: Script = preload("res://src/game/TunnelMath.gd")
const GameController: Script = preload("res://src/game/GameController.gd")

func test_level_loader_defaults_tunnel_bend_disabled() -> void:
	var normalized: Dictionary = LevelLoader._normalize_level({"bricks": []}, 1)
	var bend: Dictionary = normalized.get("tunnel_bend", {})
	assert_equal(bend.get("enabled"), false, "Missing tunnel_bend should default to disabled")
	assert_equal(bend.get("amplitude"), 1.0, "Missing tunnel_bend amplitude should default to 1.0")
	assert_equal(bend.get("frequency"), 1.0, "Missing tunnel_bend frequency should default to 1.0")
	assert_equal(bend.get("speed"), 0.18, "Missing tunnel_bend speed should default to 0.18")
	assert_equal(bend.get("phase"), 0.0, "Missing tunnel_bend phase should default to 0.0")

func test_level_loader_normalizes_explicit_tunnel_bend() -> void:
	var normalized: Dictionary = LevelLoader._normalize_level({
		"bricks": [],
		"tunnel_bend": {
			"enabled": true,
			"amplitude": 1.75,
			"frequency": 0.6,
			"speed": 0.31,
			"phase": 2.4
		}
	}, 1)
	var bend: Dictionary = normalized.get("tunnel_bend", {})
	assert_equal(bend.get("enabled"), true, "Explicit tunnel_bend should enable bending")
	assert_equal(bend.get("amplitude"), 1.75, "Explicit amplitude should be preserved")
	assert_equal(bend.get("frequency"), 0.6, "Explicit frequency should be preserved")
	assert_equal(bend.get("speed"), 0.31, "Explicit speed should be preserved")
	assert_equal(bend.get("phase"), 2.4, "Explicit phase should be preserved")

func test_surface_to_world_disabled_matches_straight_tunnel() -> void:
	var theta := 0.43
	var z := 18.0
	var radius := 6.0
	var actual: Vector3 = TunnelMath.surface_to_world(theta, z, radius, {})
	var expected := Vector3(cos(theta) * radius, sin(theta) * radius, z)
	assert_true(actual.distance_to(expected) < 0.0001, "Disabled bend should return the straight cylinder coordinate exactly")

func test_enabled_bend_changes_centerline_and_preserves_radius() -> void:
	var profile := {
		"enabled": true,
		"amplitude": 1.0,
		"frequency": 1.0,
		"speed": 0.0,
		"phase": 0.4,
		"time": 0.0
	}
	var theta := 1.1
	var z := 22.0
	var radius := 6.0
	var center: Vector3 = TunnelMath.tube_center(z, profile)
	var pos: Vector3 = TunnelMath.surface_to_world(theta, z, radius, profile)
	var straight := Vector3(cos(theta) * radius, sin(theta) * radius, z)
	assert_true(absf(center.x) > 0.01, "Enabled bend should move the centerline")
	assert_true(pos.distance_to(straight) > 0.01, "Enabled bend should change world placement")
	assert_true(absf(pos.distance_to(center) - radius) < 0.0001, "Bent placement should preserve radius from the bent centerline")

func test_bend_axes_are_normalized_and_orthogonal() -> void:
	var profile := {
		"enabled": true,
		"amplitude": 1.2,
		"frequency": 0.85,
		"speed": 0.0,
		"phase": 1.1,
		"time": 0.0
	}
	var theta := 0.8
	var z := 31.0
	var forward: Vector3 = TunnelMath.tube_tangent(z, profile)
	var radial: Vector3 = TunnelMath.radial_from_angle(theta, z, profile)
	var around: Vector3 = TunnelMath.tangent_from_angle(theta, z, profile)
	assert_true(absf(forward.length() - 1.0) < 0.0001, "Bent forward axis should be normalized")
	assert_true(absf(radial.length() - 1.0) < 0.0001, "Bent radial axis should be normalized")
	assert_true(absf(around.length() - 1.0) < 0.0001, "Bent around axis should be normalized")
	assert_true(absf(forward.dot(radial)) < 0.0001, "Forward and radial axes should be orthogonal")
	assert_true(absf(forward.dot(around)) < 0.0001, "Forward and around axes should be orthogonal")
	assert_true(absf(radial.dot(around)) < 0.0001, "Radial and around axes should be orthogonal")

func test_bent_tunnel_uv_matches_straight_tunnel_scroll_direction() -> void:
	assert_equal(GameController.bent_tunnel_uv(0.25, 0.0), Vector2(0.25, 1.0), "Near bend rings should use the same scroll direction as the straight tunnel")
	assert_equal(GameController.bent_tunnel_uv(0.25, 1.0), Vector2(0.25, 0.0), "Far bend rings should invert generated depth before shader scroll")
