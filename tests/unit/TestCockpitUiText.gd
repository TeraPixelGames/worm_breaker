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

func test_powerup_tutorial_copy_explains_effects() -> void:
	assert_true(GameController.powerup_tutorial_text("WIDE").contains("stretch"), "Wide module tutorial should explain the stabilizer effect")
	assert_true(GameController.powerup_tutorial_text("SLOW").contains("reducing tunnel speed"), "Slow module tutorial should explain the speed effect")
	assert_true(GameController.powerup_tutorial_text("BLAST").contains("shatter"), "Blast module tutorial should explain the fragment effect")
	assert_true(GameController.powerup_tutorial_text("BLASTER").contains("auto-firing"), "Blaster module tutorial should explain the paddle weapon effect")

func test_powerup_tutorial_display_names_are_player_facing() -> void:
	assert_equal(GameController.powerup_display_name("WIDE"), "Wide", "Wide module title should be readable")
	assert_equal(GameController.powerup_display_name("SLOW"), "Slow", "Slow module title should be readable")
	assert_equal(GameController.powerup_display_name("BLAST"), "Prism Blast", "Blast module title should use the in-game name")
	assert_equal(GameController.powerup_display_name("BLASTER"), "Blaster", "Blaster module title should be readable")

func test_signal_gate_hit_strength_is_clamped() -> void:
	assert_equal(GameController.signal_gate_hit_strength(0.0), 0.0, "Expired gate hit should not emit a pulse")
	assert_equal(GameController.signal_gate_hit_strength(999.0), 1.0, "Fresh gate hit should clamp at full pulse strength")

func test_bricks_use_crystal_shader() -> void:
	assert_true(ResourceLoader.exists("res://src/shaders/crystal_block.gdshader"), "Crystal block shader should exist")
	var shader := load("res://src/shaders/crystal_block.gdshader") as Shader
	assert_true(shader != null, "Crystal block shader should load")
