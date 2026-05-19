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
	assert_equal(Results.run_style_result_text("signal_sync"), "Signal Sync", "Results should name the music-interaction mode")

func test_run_style_display_names_are_player_facing() -> void:
	assert_equal(GameController.run_style_display_text("stability"), "STABILITY", "Stability should keep the cockpit mode name")
	assert_equal(GameController.run_style_display_text("overdrive"), "OVERDRIVE", "Overdrive should keep the cockpit mode name")
	assert_equal(GameController.run_style_display_text("signal_sync"), "SIGNAL SYNC", "Music mode should have a readable cockpit name")

func test_powerup_tutorial_copy_explains_effects() -> void:
	assert_true(GameController.powerup_tutorial_text("WIDE").contains("stretch"), "Wide module tutorial should explain the stabilizer effect")
	assert_true(GameController.powerup_tutorial_text("SLOW").contains("reducing tunnel speed"), "Slow module tutorial should explain the speed effect")
	assert_true(GameController.powerup_tutorial_text("BLAST").contains("shatter"), "Blast module tutorial should explain the fragment effect")

func test_powerup_tutorial_display_names_are_player_facing() -> void:
	assert_equal(GameController.powerup_display_name("WIDE"), "Wide", "Wide module title should be readable")
	assert_equal(GameController.powerup_display_name("SLOW"), "Slow", "Slow module title should be readable")
	assert_equal(GameController.powerup_display_name("BLAST"), "Prism Blast", "Blast module title should use the in-game name")

func test_signal_gate_hit_strength_is_clamped() -> void:
	assert_equal(GameController.signal_gate_hit_strength(0.0), 0.0, "Expired gate hit should not emit a pulse")
	assert_equal(GameController.signal_gate_hit_strength(999.0), 1.0, "Fresh gate hit should clamp at full pulse strength")

func test_signal_sync_band_picks_loudest_frequency_group() -> void:
	assert_equal(GameController.signal_sync_band_from_levels(0.8, 0.3, 0.2), "bass", "Bass should own sync gates when it is strongest")
	assert_equal(GameController.signal_sync_band_from_levels(0.1, 0.7, 0.5), "mid", "Mids should own sync gates when they are strongest")
	assert_equal(GameController.signal_sync_band_from_levels(0.1, 0.2, 0.9), "treble", "Treble should own sync gates when it is strongest")

func test_signal_sync_gate_hit_uses_wrapped_theta_window() -> void:
	var lane_theta: float = GameController.signal_sync_lane_theta(0)
	assert_true(GameController.signal_sync_gate_hit(lane_theta + 0.1, lane_theta, 1.0), "Nearby lane contact should hit a sync gate")
	assert_true(not GameController.signal_sync_gate_hit(lane_theta + 1.4, lane_theta, 1.0), "Distant lane contact should miss a sync gate")

func test_signal_sync_gate_score_rises_with_music_confidence() -> void:
	var quiet: int = GameController.signal_sync_gate_score(0, 0.0, 0.0)
	var locked: int = GameController.signal_sync_gate_score(4, 0.8, 1.0)
	assert_true(locked > quiet, "Stronger pulse and BPM confidence should increase sync gate score")
