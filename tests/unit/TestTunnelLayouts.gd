extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")

func test_default_tunnel_layout_lineup_rotates_by_level() -> void:
	var lineup: PackedStringArray = GameController.default_tunnel_layout_lineup()
	assert_equal(GameController.tunnel_layout_for_level(1, {}, lineup), "projectm_grid", "First level should use the current projectM grid layout")
	assert_equal(GameController.tunnel_layout_for_level(2, {}, lineup), "amber_mesh", "Second level should rotate to the amber mesh layout")
	assert_equal(GameController.tunnel_layout_for_level(3, {}, lineup), "signal_lattice", "Third level should rotate to the signal lattice layout")
	assert_equal(GameController.tunnel_layout_for_level(4, {}, lineup), "projectm_grid", "Tunnel lineup should wrap after the last preset")

func test_tunnel_layout_level_data_overrides_lineup() -> void:
	var lineup: PackedStringArray = GameController.normalized_tunnel_layout_lineup("projectm_grid,amber_mesh")
	var level_data: Dictionary = {"tunnel_layout": "signal_lattice"}
	assert_equal(GameController.tunnel_layout_for_level(1, level_data, lineup), "signal_lattice", "Level data should be able to pin a specific tunnel layout")

func test_tunnel_layout_lineup_parser_filters_unknown_entries() -> void:
	var lineup: PackedStringArray = GameController.normalized_tunnel_layout_lineup(" signal_lattice,unknown,amber_mesh,signal_lattice ")
	assert_equal(lineup.size(), 2, "Tunnel lineup should ignore unknown and duplicate layout ids")
	assert_equal(lineup[0], "signal_lattice", "Parser should preserve the first known layout order")
	assert_equal(lineup[1], "amber_mesh", "Parser should keep later known layouts")

func test_tunnel_layout_transition_blend_is_smooth_and_bounded() -> void:
	assert_equal(GameController.tunnel_layout_transition_blend(-1.0, 1.0), 0.0, "Layout transition should clamp negative time")
	var middle: float = GameController.tunnel_layout_transition_blend(0.5, 1.0)
	assert_true(middle > 0.0, "Layout transition should start moving before halfway")
	assert_true(middle < 1.0, "Layout transition should not finish before the duration")
	assert_equal(GameController.tunnel_layout_transition_blend(2.0, 1.0), 1.0, "Layout transition should clamp after the duration")
