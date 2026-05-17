extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")

class DummyAnalyzer:
	extends RefCounted

	var available := true
	var energy := 0.0
	var pulse := 0.0

	func is_available() -> bool:
		return available

	func get_energy() -> float:
		return energy

	func get_pulse() -> float:
		return pulse

func test_device_audio_low_energy_stays_neutral() -> void:
	var target: float = GameController.device_audio_pulse_target(0.001, 0.0008)
	assert_true(target <= 0.001, "Low system audio energy should not trigger tunnel pulse")

func test_device_audio_energy_rise_triggers_bounded_pulse() -> void:
	var target: float = GameController.device_audio_pulse_target(0.15, 0.02)
	assert_true(target > 0.0, "Sudden system audio energy should trigger tunnel pulse")
	assert_true(target <= 1.0, "System audio pulse target should stay bounded")

func test_device_audio_pulse_decays_smoothly() -> void:
	var next_pulse: float = GameController.smoothed_device_audio_pulse(1.0, 0.0, 1.0 / 60.0)
	assert_true(next_pulse < 1.0, "System audio pulse should decay toward silence")
	assert_true(next_pulse > 0.0, "System audio pulse should not snap off in one frame")

func test_missing_device_audio_analyzer_returns_neutral_pulse() -> void:
	var state: Dictionary = GameController.device_audio_pulse_for_analyzer(null, 0.5, 0.2, 1.0 / 60.0)
	assert_equal(float(state.get("energy", -1.0)), 0.0, "Missing analyzer should report neutral energy")
	assert_true(float(state.get("pulse", 0.0)) < 0.5, "Missing analyzer should decay current pulse")

func test_available_device_audio_analyzer_uses_energy_and_native_pulse() -> void:
	var analyzer := DummyAnalyzer.new()
	analyzer.energy = 0.08
	analyzer.pulse = 0.65
	var state: Dictionary = GameController.device_audio_pulse_for_analyzer(analyzer, 0.0, 0.01, 1.0 / 60.0)
	assert_equal(float(state.get("energy", 0.0)), 0.08, "Analyzer energy should be surfaced to the pulse state")
	assert_true(float(state.get("pulse", 0.0)) > 0.0, "Available analyzer pulse should affect the tunnel")

func test_device_audio_debug_text_reports_levels() -> void:
	var text: String = GameController.device_audio_debug_text(true, 0.12345, 0.678)
	assert_equal(text, "SYS AUDIO ON  E 0.1235  P 0.68", "Debug readout should expose analyzer state and levels")

func test_game_audio_debug_text_reports_fallback_source() -> void:
	var text: String = GameController.device_audio_debug_text(true, 0.2, 0.4, GameController.DEVICE_AUDIO_SOURCE_GAME)
	assert_equal(text, "GAME AUDIO ON  E 0.2000  P 0.40", "Debug readout should identify the mobile game-audio fallback")

func test_game_audio_magnitude_maps_to_bounded_energy() -> void:
	var energy: float = GameController.game_audio_energy_from_magnitude(Vector2(0.5, 0.5))
	assert_true(energy > 0.0, "Game audio magnitude should produce fallback energy")
	assert_true(energy <= 1.0, "Game audio fallback energy should stay bounded")

func test_mic_audio_debug_text_reports_fallback_source() -> void:
	var text: String = GameController.device_audio_debug_text(true, 0.1, 0.3, GameController.DEVICE_AUDIO_SOURCE_MIC)
	assert_equal(text, "MIC AUDIO ON  E 0.1000  P 0.30", "Debug readout should identify the microphone fallback")

func test_mic_audio_frames_map_to_bounded_energy() -> void:
	var frames := PackedVector2Array([Vector2(0.25, -0.25), Vector2(-0.5, 0.5)])
	var energy: float = GameController.mic_audio_energy_from_frames(frames)
	assert_true(energy > 0.0, "Mic frames should produce fallback energy")
	assert_true(energy <= 1.0, "Mic fallback energy should stay bounded")

func test_quiet_mic_audio_still_registers_small_energy() -> void:
	var frames := PackedVector2Array([Vector2(0.01, 0.0), Vector2(0.0, -0.012)])
	var energy: float = GameController.mic_audio_energy_from_frames(frames)
	assert_true(energy > 0.02, "Quiet mic input should be scaled high enough to show in the debug meter")
