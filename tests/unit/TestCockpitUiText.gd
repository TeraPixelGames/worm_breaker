extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")
const Results: Script = preload("res://src/ui/Results.gd")

func test_hud_uses_signal_cockpit_terms() -> void:
	assert_equal(GameController.hud_signal_text(1250), "SIGNAL CHARGE 1250", "HUD score should read as signal charge")
	assert_equal(GameController.hud_depth_text(2, 3), "TUNNEL DEPTH 2/3", "HUD layer should read as tunnel depth")
	assert_equal(GameController.hud_pulse_text(4), "PULSE x4", "HUD chain should read as pulse multiplier")

func test_rival_pressure_reads_as_gauge() -> void:
	assert_equal(GameController.hud_pressure_text(600, 1200), "RIVAL PRESSURE 50%  /  1200", "Rival target should read as a pressure gauge")
	assert_equal(GameController.hud_pressure_text(1800, 1200), "RIVAL PRESSURE 100%  /  1200", "Pressure gauge should cap at full pressure")

func test_results_titles_match_signal_story() -> void:
	assert_equal(Results.results_title_text(true), "SPIRAL CLEAR", "Win result should use payoff chamber language")
	assert_equal(Results.results_title_text(false), "SIGNAL LOST", "Loss result should use signal story language")
