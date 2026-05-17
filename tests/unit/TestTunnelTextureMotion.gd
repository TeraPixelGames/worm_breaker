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

func test_audio_bpm_interval_maps_to_tempo() -> void:
	var bpm: float = GameController.audio_bpm_from_beat_interval(0.5)
	assert_true(absf(bpm - 120.0) < 0.01, "Half-second beat intervals should map to 120 BPM")

func test_audio_bpm_rejects_out_of_range_intervals() -> void:
	assert_equal(GameController.audio_bpm_from_beat_interval(0.2), 0.0, "Intervals above the BPM cap should be rejected")
	assert_equal(GameController.audio_bpm_from_beat_interval(2.0), 0.0, "Intervals below the BPM floor should be rejected")

func test_audio_bpm_accepts_skipped_beat_interval() -> void:
	var bpm: float = GameController.audio_bpm_from_beat_interval(1.0)
	assert_true(absf(bpm - 120.0) < 0.01, "Every-other-beat detections should still map to the song BPM")

func test_audio_bpm_recent_samples_weight_new_tempo() -> void:
	var samples: Array[float] = [100.0, 100.0, 100.0]
	samples = GameController.audio_bpm_samples_after_interval(samples, 112.0, 100.0)
	var bpm: float = GameController.audio_bpm_from_recent_samples(samples)
	assert_true(bpm > 100.0, "Recent sample weighting should move toward a changed tempo")
	assert_true(bpm < 112.0, "Small tempo drift should still be smoothed")

func test_audio_bpm_large_shift_relocks_quickly() -> void:
	var samples: Array[float] = [100.0, 100.0, 100.0]
	samples = GameController.audio_bpm_samples_after_interval(samples, 160.0, 100.0)
	assert_equal(samples.size(), 1, "Large tempo changes should drop stale BPM history")
	var bpm: float = GameController.smoothed_audio_bpm(100.0, GameController.audio_bpm_from_recent_samples(samples))
	assert_true(bpm > 140.0, "Large tempo changes should move the displayed BPM quickly")

func test_audio_bpm_onset_requires_sharp_pulse_rise() -> void:
	assert_true(GameController.audio_beat_onset(0.3, 0.1), "Sharp pulse rises should count as beat onsets")
	assert_true(not GameController.audio_beat_onset(0.3, 0.28), "Sustained pulse levels should not retrigger BPM")
	assert_true(not GameController.audio_beat_onset(0.07, 0.0), "Small pulse rises should stay below the BPM gate")
	assert_true(GameController.audio_beat_onset(0.05, 0.04, 0.04, 0.02), "Raw energy rises should count as beat onsets when smoothed pulse is muted")

func test_audio_bpm_confidence_attacks_and_decays() -> void:
	var attacked: float = GameController.audio_bpm_confidence_after_step(0.0, true, false, 1.0 / 60.0)
	var probing: float = GameController.audio_bpm_confidence_after_step(0.0, false, false, 1.0 / 60.0, true)
	var decayed: float = GameController.audio_bpm_confidence_after_step(0.8, false, true, 1.0)
	assert_true(attacked >= 0.5, "Valid beat intervals should make BPM confidence visible quickly")
	assert_true(probing > 0.05, "Detected onsets should make BPM visible while interval lock is warming up")
	assert_true(decayed < 0.8, "Timed-out beat tracking should decay BPM confidence")

func test_audio_beat_speed_kick_attacks_and_decays() -> void:
	var kicked: float = GameController.audio_beat_speed_kick_after_step(0.0, true, 1.0 / 60.0)
	var decayed: float = GameController.audio_beat_speed_kick_after_step(1.0, false, 0.25)
	assert_equal(kicked, 1.0, "Valid beat intervals should create an immediate speed kick")
	assert_true(decayed < 1.0, "Beat speed kick should decay after the beat")
	assert_true(decayed > 0.0, "Beat speed kick should fade rather than snap off")

func test_audio_bpm_can_raise_but_not_lower_tunnel_speed() -> void:
	var base_speed: float = GameController.tunnel_texture_speed_for_ball_velocity(8.0, 0.1)
	var synced_speed: float = GameController.tunnel_texture_speed_for_audio_bpm(base_speed, 170.0, 1.0, 0.5, 1.0)
	var quiet_speed: float = GameController.tunnel_texture_speed_for_audio_bpm(base_speed, 90.0, 1.0, 0.0)
	assert_true(synced_speed > base_speed + 0.6, "High-confidence fast BPM should visibly raise tunnel texture speed")
	assert_true(synced_speed <= 2.6, "BPM-driven tunnel texture speed should stay bounded")
	assert_true(quiet_speed >= base_speed, "BPM modulation should not slow the velocity-driven tunnel baseline")
