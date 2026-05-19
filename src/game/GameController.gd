extends Node3D

const BRICK_SCENE: PackedScene = preload("res://src/scenes/Brick.tscn")
const TunnelMath = preload("res://src/game/TunnelMath.gd")
const Collision = preload("res://src/game/Collision.gd")
const LevelLoader = preload("res://src/game/LevelLoader.gd")
const FRACTAL_SHADERS: Array[Shader] = [
	preload("res://src/shaders/fractals/sierpinski_triangle.gdshader"),
	preload("res://src/shaders/fractals/sierpinski_carpet.gdshader"),
	preload("res://src/shaders/fractals/koch_curve.gdshader"),
	preload("res://src/shaders/fractals/mandelbrot_set.gdshader"),
	preload("res://src/shaders/fractals/julia_set.gdshader")
]
const SIGNAL_GATE_SHADER: Shader = preload("res://src/shaders/signal_gate.gdshader")
const TUNNEL_LIGHT_PORTAL_SHADER: Shader = preload("res://src/shaders/tunnel_light_portal.gdshader")
const TUNNEL_FRACTAL_SHADER: Shader = preload("res://src/shaders/fractals/tunnel_fractal_wrap.gdshader")
const SHADERTOY_ENERGY_BALL_SHADER: Shader = preload("res://src/shaders/shadertoy_energy_ball.gdshader")
const TUNNEL_FORWARD: Vector3 = Vector3(0.0, 0.0, 1.0)
const BALL_THETA_RADIUS: float = 0.12
const BALL_Z_RADIUS: float = 0.34
const BALL_WORLD_RADIUS: float = 0.23
const PADDLE_SEGMENT_COUNT: int = 11
const PADDLE_SURFACE_INSET: float = 0.24
const PADDLE_VISUAL_ARC_SCALE: float = 1.15
const COMBO_RESET_TIME: float = 1.2
const BALL_TRAIL_SEGMENT_COUNT: int = 14
const BALL_GUIDE_SEGMENT_COUNT: int = 4
const IMPACT_PARTICLE_COUNT: int = 16
const IMPACT_PARTICLE_LIFETIME: float = 0.34
const HAPTIC_MIN_INTERVAL: float = 0.055
const CAMERA_BASE_INWARD_DISTANCE: float = 2.4
const CAMERA_BASE_BACK_DISTANCE: float = 7.2
const CAMERA_BASE_LOOK_AHEAD: float = 10.0
const CAMERA_BASE_FOV: float = 82.0
const CAMERA_MOBILE_FOV: float = 92.0
const POWERUP_PICKUP_CHANCE: float = 0.34
const POWERUP_Z_SPEED: float = 7.6
const POWERUP_COLLECT_Z_WINDOW: float = 0.48
const POWERUP_WIDE_DURATION: float = 7.0
const POWERUP_SLOW_DURATION: float = 5.0
const POWERUP_SLOW_MIN_Z_SPEED: float = 5.4
const PORTAL_BREACH_DURATION: float = 1.18
const SIGNAL_GATE_HIT_DURATION: float = 0.62
const SIGNAL_GATE_SHARD_COUNT: int = 18
const PADDLE_FLASH_DURATION: float = 0.18
const HUD_DOCK_SAFE_MARGIN: float = 24.0
const HUD_DOCK_MIN_WIDTH: float = 304.0
const HUD_DOCK_MAX_WIDTH: float = 420.0
const HUD_DOCK_HEIGHT: float = 154.0
const HUD_MESSAGE_HEIGHT: float = 62.0
const PORTAL_BASE_ANIMATION_SPEED: float = 0.46
const PORTAL_MAX_ANIMATION_SPEED: float = 1.85
const PORTAL_SPEED_ACCELERATION: float = 0.85
const TUNNEL_TEXTURE_BASE_SPEED: float = 0.62
const TUNNEL_TEXTURE_MAX_SPEED: float = 2.6
const TUNNEL_TEXTURE_SPEED_ACCELERATION: float = 1.1
const TUNNEL_LAYOUT_TRANSITION_DURATION: float = 1.15
const TUNNEL_LAYOUT_LINEUP_ENV := "WORM_BREAKER_TUNNEL_LINEUP"
const TUNNEL_LAYOUT_DEFAULT := "projectm_grid"
const TUNNEL_LAYOUT_DEFAULT_LINEUP: Array[String] = ["projectm_grid", "amber_mesh", "signal_lattice"]
const PORTAL_LIGHT_DEFAULT := "radiant_core"
const PORTAL_LIGHT_DEFAULT_LINEUP: Array[String] = ["radiant_core", "flowing_wires", "hex_bloom"]
const PORTAL_LIGHT_PRESETS: Dictionary = {
	"radiant_core": {
		"variant": 0,
		"primary_color": Color(0.08, 1.0, 0.9, 1.0),
		"secondary_color": Color(1.0, 0.12, 0.82, 1.0),
		"accent_color": Color(1.0, 0.92, 0.24, 1.0),
		"ray_density": 18.0,
		"ring_density": 8.0,
		"wire_strength": 0.18,
		"grid_strength": 0.12
	},
	"flowing_wires": {
		"variant": 1,
		"primary_color": Color(0.12, 0.42, 1.0, 1.0),
		"secondary_color": Color(0.0, 1.0, 0.82, 1.0),
		"accent_color": Color(1.0, 0.16, 0.92, 1.0),
		"ray_density": 11.0,
		"ring_density": 12.0,
		"wire_strength": 0.78,
		"grid_strength": 0.18
	},
	"hex_bloom": {
		"variant": 2,
		"primary_color": Color(1.0, 0.24, 0.08, 1.0),
		"secondary_color": Color(0.15, 0.2, 1.0, 1.0),
		"accent_color": Color(1.0, 0.88, 0.18, 1.0),
		"ray_density": 9.0,
		"ring_density": 15.0,
		"wire_strength": 0.24,
		"grid_strength": 0.72
	}
}
const TUNNEL_LAYOUT_PRESETS: Dictionary = {
	"projectm_grid": {
		"base_color": Color(0.018, 0.0, 0.055, 1.0),
		"hue_origin": 0.76,
		"hue_motion": 0.08,
		"near_offset": 0.48,
		"far_offset": 0.12,
		"near_saturation": 0.74,
		"far_saturation": 0.92,
		"projectm_overlay_strength": 0.32,
		"depth_scale": 18.0,
		"angle_repeats": 9.0,
		"spoke_repeats": 12.0,
		"kaleido_segments": 12.0,
		"circuit_density": 40.0,
		"ring_frequency": 0.72
	},
	"amber_mesh": {
		"base_color": Color(0.055, 0.014, 0.0, 1.0),
		"hue_origin": 0.08,
		"hue_motion": 0.045,
		"near_offset": 0.08,
		"far_offset": 0.21,
		"near_saturation": 0.86,
		"far_saturation": 0.78,
		"projectm_overlay_strength": 0.24,
		"depth_scale": 14.0,
		"angle_repeats": 6.0,
		"spoke_repeats": 8.0,
		"kaleido_segments": 8.0,
		"circuit_density": 26.0,
		"ring_frequency": 0.58
	},
	"signal_lattice": {
		"base_color": Color(0.0, 0.018, 0.04, 1.0),
		"hue_origin": 0.43,
		"hue_motion": 0.06,
		"near_offset": 0.02,
		"far_offset": 0.62,
		"near_saturation": 0.82,
		"far_saturation": 0.88,
		"projectm_overlay_strength": 0.38,
		"depth_scale": 23.0,
		"angle_repeats": 13.0,
		"spoke_repeats": 18.0,
		"kaleido_segments": 16.0,
		"circuit_density": 54.0,
		"ring_frequency": 0.94
	}
}
const AUDIO_BPM_DEFAULT: float = 120.0
const AUDIO_BPM_MIN: float = 70.0
const AUDIO_BPM_MAX: float = 180.0
const AUDIO_BPM_ONSET_PULSE_MIN: float = 0.08
const AUDIO_BPM_ONSET_PULSE_RISE: float = 0.025
const AUDIO_BPM_ONSET_ENERGY_MIN: float = 0.018
const AUDIO_BPM_ONSET_ENERGY_RISE: float = 0.006
const AUDIO_BPM_MIN_INTERVAL: float = 60.0 / AUDIO_BPM_MAX
const AUDIO_BPM_MAX_INTERVAL: float = 60.0 / AUDIO_BPM_MIN
const AUDIO_BPM_BLEND: float = 0.28
const AUDIO_BPM_SHIFT_BLEND: float = 0.68
const AUDIO_BPM_SHIFT_THRESHOLD: float = 16.0
const AUDIO_BPM_HISTORY_SIZE: int = 4
const AUDIO_BPM_CONFIDENCE_ATTACK: float = 0.5
const AUDIO_BPM_CONFIDENCE_PROBE: float = 0.14
const AUDIO_BPM_CONFIDENCE_DECAY: float = 0.35
const AUDIO_BPM_TIMEOUT: float = 2.4
const AUDIO_BPM_TUNNEL_BLEND: float = 0.85
const AUDIO_BPM_PULSE_SPEED_BOOST: float = 0.55
const AUDIO_BPM_BEAT_SPEED_KICK: float = 0.42
const AUDIO_BPM_BEAT_KICK_DECAY: float = 7.5
const DEVICE_AUDIO_ANALYZER_CLASS := "WindowsSystemAudioAnalyzer"
const ANDROID_SYSTEM_AUDIO_SINGLETON := "AndroidSystemAudioCapture"
const DEVICE_AUDIO_DISABLE_ENV := "WORM_BREAKER_DISABLE_SYSTEM_AUDIO_PULSE"
const DEVICE_AUDIO_PULSE_THRESHOLD: float = 0.003
const DEVICE_AUDIO_PULSE_ONSET_THRESHOLD: float = 0.002
const DEVICE_AUDIO_PULSE_LEVEL_GAIN: float = 14.0
const DEVICE_AUDIO_PULSE_LEVEL_MAX: float = 0.18
const DEVICE_AUDIO_PULSE_ONSET_GAIN: float = 32.0
const DEVICE_AUDIO_PULSE_ATTACK: float = 32.0
const DEVICE_AUDIO_PULSE_DECAY: float = 6.8
const DEVICE_AUDIO_PULSE_MAX: float = 1.0
const DEVICE_AUDIO_SOURCE_SYSTEM := "SYS AUDIO"
const DEVICE_AUDIO_SOURCE_WEB := "WEB AUDIO"
const DEVICE_AUDIO_SOURCE_MIC := "MIC AUDIO"
const DEVICE_AUDIO_SOURCE_GAME := "GAME AUDIO"
const GAME_AUDIO_SPECTRUM_BUS := "Master"
const GAME_AUDIO_SPECTRUM_MIN_HZ: float = 40.0
const GAME_AUDIO_SPECTRUM_MAX_HZ: float = 190.0
const GAME_AUDIO_ENERGY_GAIN: float = 1.65
const MIC_AUDIO_CAPTURE_BUS := "MicCapture"
const MIC_AUDIO_RMS_GAIN: float = 9.0
const MIC_AUDIO_PEAK_GAIN: float = 3.5
const MIC_AUDIO_PULSE_BOOST: float = 1.8
const ANDROID_SYSTEM_AUDIO_FALLBACK_DELAY: float = 2.5
const STYLE_STABILITY := "stability"
const STYLE_OVERDRIVE := "overdrive"
const POWERUP_WIDE := "WIDE"
const POWERUP_SLOW := "SLOW"
const POWERUP_BLAST := "BLAST"

@onready var tunnel: MeshInstance3D = $World/Tunnel
@onready var paddle_root: Node3D = $World/PaddleRoot
@onready var ball_mesh: MeshInstance3D = $World/Ball
@onready var brick_root: Node3D = $World/BrickRoot
@onready var camera: Camera3D = $World/CameraRig/Camera3D
@onready var key_light: DirectionalLight3D = $World/KeyLight
@onready var fill_light: OmniLight3D = $World/FillLight
@onready var rot_input: Node = $RotInput
@onready var combo_sfx: AudioStreamPlayer = $ComboSfx
@onready var hud_panel: PanelContainer = $HUD/Panel
@onready var score_label: Label = $HUD/Panel/VBox/ScoreLabel
@onready var level_label: Label = $HUD/Panel/VBox/LevelLabel
@onready var objective_label: Label = $HUD/Panel/VBox/ObjectiveLabel
@onready var style_label: Label = $HUD/Panel/VBox/StyleLabel
@onready var phase_label: Label = $HUD/Panel/VBox/PhaseLabel
@onready var combo_label: Label = $HUD/Panel/VBox/ComboLabel
@onready var message_label: Label = $HUD/MessageLabel

var _level_data: Dictionary = {}
var _level_index: int = 1
var _play_radius: float = 5.75
var _paddle_theta: float = 0.0
var _paddle_width: float = 0.95
var _paddle_z: float = 3.0
var _z_fail: float = 1.7
var _level_end_z: float = 30.0

var _ball_theta: float = 0.0
var _ball_z: float = 5.0
var _ball_v_theta: float = 0.25
var _ball_v_z: float = 8.0

var _chain_combo: int = 0
var _combo_timeout: float = 0.0
var _pending_transition: bool = false
var _transition_mode: String = ""
var _transition_time: float = 0.0

var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_amount: float = 0.0
var _visual_time: float = 0.0
var _haptic_cooldown: float = 0.0
var _paddle_flash_timer: float = 0.0

var _paddle_segments: Array[MeshInstance3D] = []
var _bricks: Array = []
var _initial_brick_count: int = 0
var _run_style: String = STYLE_STABILITY
var _rival_target: int = 1200
var _tunnel_material: ShaderMaterial
var _tunnel_texture_phase: float = 0.0
var _tunnel_texture_speed: float = TUNNEL_TEXTURE_BASE_SPEED
var _tunnel_layout_lineup: PackedStringArray = PackedStringArray()
var _current_tunnel_layout_id: String = TUNNEL_LAYOUT_DEFAULT
var _previous_tunnel_layout_id: String = TUNNEL_LAYOUT_DEFAULT
var _target_tunnel_layout_id: String = TUNNEL_LAYOUT_DEFAULT
var _tunnel_layout_transition_time: float = TUNNEL_LAYOUT_TRANSITION_DURATION
var _device_audio_analyzer: Object
var _device_audio_available: bool = false
var _device_audio_energy: float = 0.0
var _device_audio_pulse: float = 0.0
var _device_audio_bass: float = 0.0
var _device_audio_mid: float = 0.0
var _device_audio_treble: float = 0.0
var _device_audio_debug_label: Label
var _web_audio_connect_button: Button
var _device_audio_source_label: String = DEVICE_AUDIO_SOURCE_SYSTEM
var _audio_bpm: float = AUDIO_BPM_DEFAULT
var _audio_bpm_confidence: float = 0.0
var _audio_beat_time: float = 0.0
var _audio_last_beat_time: float = -1.0
var _audio_beat_speed_kick: float = 0.0
var _audio_bpm_samples: Array[float] = []
var _android_system_audio_wait_time: float = 0.0
var _mic_audio_player: AudioStreamPlayer
var _mic_audio_capture_effect_index: int = -1
var _mic_audio_mute_effect_index: int = -1
var _mic_audio_capture_instance: AudioEffectCapture
var _game_audio_spectrum_effect_index: int = -1
var _game_audio_spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var _ball_material: ShaderMaterial
var _paddle_materials: Array[StandardMaterial3D] = []
var _ball_trail_root: Node3D
var _ball_trail_points: Array[Vector3] = []
var _ball_trail_segments: Array[MeshInstance3D] = []
var _ball_guide_segments: Array[MeshInstance3D] = []
var _ball_trail_materials: Array[StandardMaterial3D] = []
var _ball_guide_materials: Array[StandardMaterial3D] = []
var _impact_particle_root: Node3D
var _impact_particles: Array[Dictionary] = []
var _powerup_root: Node3D
var _powerups: Array[Dictionary] = []
var _wide_timer: float = 0.0
var _slow_timer: float = 0.0
var _portal_cap: MeshInstance3D
var _portal_material: ShaderMaterial
var _portal_fractal_cap: MeshInstance3D
var _portal_fractal_material: ShaderMaterial
var _portal_light_lineup: PackedStringArray = PackedStringArray()
var _current_portal_light_id: String = PORTAL_LIGHT_DEFAULT
var _portal_phase: float = 0.0
var _portal_animation_speed: float = PORTAL_BASE_ANIMATION_SPEED
var _signal_gate_hit_timer: float = 0.0
var _signal_gate_break_progress: float = 0.0
var _signal_gate_shards: Array[Dictionary] = []
var _fractal_layer: CanvasLayer
var _fractal_overlay: ColorRect
var _fractal_overlay_material: ShaderMaterial
var _fractal_shader_index := 0
var _tutorial_enabled: bool = false
var _tutorial_rotate_seen: bool = false
var _tutorial_catch_seen: bool = false
var _tutorial_fragment_seen: bool = false
var _tutorial_powerups_seen: Dictionary = {}
var _tutorial_pause_active: bool = false
var _tutorial_pause_kind: String = ""
var _tutorial_focus: String = ""
var _tutorial_overlay: PanelContainer
var _tutorial_title_label: Label
var _tutorial_body_label: Label
var _tutorial_continue_button: Button
var _tutorial_disable_check: CheckBox
var _message_serial: int = 0

func _ready() -> void:
	MusicManager.play_game()
	_run_style = str(RunManager.run_style).to_lower()
	_rival_target = SaveStore.refresh_rival_target()
	_apply_hud_style()
	_layout_hud()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_layout_hud):
		viewport.size_changed.connect(_layout_hud)
	_build_fractal_overlay()
	_apply_psychedelic_lighting()
	_setup_ball_visual()
	_build_ball_tracers()
	_build_impact_particles()
	_build_powerup_root()
	_build_tutorial_overlay()
	_build_tunnel_end_portal()
	_build_device_audio_debug_label()
	_build_web_audio_connect_button()
	_setup_device_audio_analyzer()
	_tunnel_layout_lineup = _resolve_tunnel_layout_lineup()
	_portal_light_lineup = _resolve_portal_light_lineup()
	_build_paddle_segments()
	_load_level(max(1, RunManager.current_level_index))
	_update_hud()

func _exit_tree() -> void:
	if _device_audio_analyzer != null and not OS.has_feature("web") and _analyzer_has_method(_device_audio_analyzer, "stop"):
		_device_audio_analyzer.call("stop")
	_teardown_mic_audio_fallback()
	_teardown_game_audio_spectrum_fallback()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout_hud()

func _physics_process(delta: float) -> void:
	_visual_time += delta
	_haptic_cooldown = maxf(_haptic_cooldown - delta, 0.0)
	_signal_gate_hit_timer = maxf(_signal_gate_hit_timer - delta, 0.0)
	_step_portal_motion(delta)
	_step_device_audio_pulse(delta)
	_step_tunnel_texture_motion(delta)
	_step_tunnel_layout_transition(delta)
	_update_psychedelic_materials()
	_update_fractal_overlay()
	_update_impact_particles(delta)
	if _tutorial_pause_active:
		_step_tutorial_pause(delta)
		_update_ball_visual()
		_update_paddle_visual()
		_update_camera(delta)
		_update_hud()
		return
	_step_powerups(delta)
	if _pending_transition:
		_step_transition(delta)
		_update_ball_visual()
		_update_paddle_visual()
		_update_camera(delta)
		_update_hud()
		return

	_step_combo(delta)
	_step_powerup_timers(delta)
	_paddle_flash_timer = maxf(_paddle_flash_timer - delta, 0.0)
	_step_paddle(delta)
	_step_ball(delta)
	_update_ball_visual()
	_update_paddle_visual()
	_update_camera(delta)
	_update_hud()

func _step_combo(delta: float) -> void:
	if _combo_timeout <= 0.0:
		return
	_combo_timeout = max(_combo_timeout - delta, 0.0)
	if _combo_timeout == 0.0:
		_chain_combo = 0

func _step_paddle(delta: float) -> void:
	var angular_velocity: float = 0.0
	if rot_input != null and rot_input.has_method("get_angular_velocity"):
		angular_velocity = float(rot_input.get_angular_velocity())
	_paddle_theta = TunnelMath.wrap_angle(_paddle_theta + angular_velocity * delta)

func _step_ball(delta: float) -> void:
	var prev_z: float = _ball_z

	_ball_theta = TunnelMath.wrap_angle(_ball_theta + _ball_v_theta * delta)
	_ball_z += _ball_v_z * delta

	if _ball_z > _level_end_z:
		_ball_z = _level_end_z
		_ball_v_z = -absf(_ball_v_z)
		_hit_signal_gate()
		_pulse_haptic(18, 0.28)

	if _ball_v_z < 0.0 and prev_z >= _paddle_z and _ball_z <= _paddle_z:
		var paddle_hit: bool = Collision.ball_vs_paddle(_ball_theta, _paddle_z, _paddle_theta, _paddle_collision_width(), _paddle_z, BALL_THETA_RADIUS)
		if paddle_hit:
			var bounce: Dictionary = Collision.reflect_from_paddle(
				_ball_v_theta,
				_ball_v_z,
				_ball_theta,
				_paddle_theta,
				_paddle_collision_width(),
				1.9
			)
			_ball_v_theta = float(bounce.get("v_theta", _ball_v_theta))
			_ball_v_z = float(bounce.get("v_z", absf(_ball_v_z)))
			_ball_z = _paddle_z + 0.02
			_spawn_ball_impact_burst(TunnelMath.surface_to_world(_ball_theta, _ball_z, _play_radius), Color(0.05, 1.0, 0.82), 1.0)
			_pulse_haptic(28, 0.45)
			_flash_paddle()
			_chain_combo = 0
			_combo_timeout = 0.0
			if _tutorial_enabled and not _tutorial_catch_seen:
				_tutorial_catch_seen = true
				_show_tutorial_pause(
					"Catch the Pulse",
					"The pulse stays alive only when it rebounds off the stabilizer. Miss below the paddle and the signal drops.",
					"pulse",
					"continue"
				)
		else:
			_lose_run()
			return

	if _ball_z < _z_fail:
		_lose_run()
		return

	_check_brick_hits()

func _check_brick_hits() -> void:
	for i in range(_bricks.size() - 1, -1, -1):
		var brick: Node = _bricks[i]
		if brick == null or not is_instance_valid(brick):
			_bricks.remove_at(i)
			continue

		var hit_info: Dictionary = Collision.ball_vs_brick(
			_ball_theta,
			_ball_z,
			brick.get_collision_data(BALL_THETA_RADIUS, BALL_Z_RADIUS)
		)
		if not bool(hit_info.get("hit", false)):
			continue

		_apply_brick_reflection(hit_info)
		var destroyed: bool = brick.apply_hit()
		_spawn_ball_impact_burst(TunnelMath.surface_to_world(_ball_theta, _ball_z, _play_radius), Color(1.0, 0.18, 0.92), 1.15 if destroyed else 0.85)
		_pulse_haptic(34 if destroyed else 22, 0.64 if destroyed else 0.42)
		if destroyed:
			_start_camera_shake(0.055, 0.16)
		_register_combo_hit()
		if _tutorial_enabled and not _tutorial_fragment_seen:
			_tutorial_fragment_seen = true
			_show_tutorial_pause(
				"Break Signal Fragments",
				"Every fragment you break raises signal charge. Clear the cluster to dive deeper into the tunnel.",
				"fragments",
				"continue"
			)

		if destroyed:
			_maybe_spawn_powerup(brick)
			brick.queue_free()
			_bricks.remove_at(i)
		break

	if _bricks.is_empty():
		_complete_level()

func _apply_brick_reflection(hit_info: Dictionary) -> void:
	var axis: String = String(hit_info.get("axis", "z"))
	if axis == "theta":
		_ball_v_theta *= -1.0
		_ball_theta += 0.01 * float(hit_info.get("theta_sign", 1.0))
	else:
		_ball_v_z *= -1.0
		_ball_z += 0.03 * float(hit_info.get("z_sign", 1.0))

func _register_combo_hit() -> void:
	_chain_combo += 1
	_combo_timeout = COMBO_RESET_TIME
	var style_mult := 1.0
	if _run_style == STYLE_OVERDRIVE:
		style_mult = 1.25
	elif _run_style == STYLE_STABILITY:
		style_mult = 0.95
	var points := int(round((100 + (_chain_combo - 1) * 30) * style_mult))
	RunManager.add_score(points)
	if combo_sfx != null and combo_sfx.has_method("play_combo"):
		combo_sfx.play_combo(_chain_combo)
	if _chain_combo >= 2:
		_start_camera_shake(0.04 + 0.01 * min(_chain_combo, 8), 0.15)

func _pulse_haptic(duration_ms: int, amplitude: float) -> void:
	if _haptic_cooldown > 0.0:
		return
	_haptic_cooldown = HAPTIC_MIN_INTERVAL
	Input.vibrate_handheld(maxi(duration_ms, 1), clampf(amplitude, 0.0, 1.0))

func _load_level(level_index: int) -> void:
	if not LevelLoader.has_level(level_index):
		RunManager.go_to_results(true, max(1, level_index - 1), RunManager.run_score)
		return

	_level_index = level_index
	_level_data = LevelLoader.load_level(level_index)
	if _level_data.is_empty():
		RunManager.go_to_results(false, level_index, RunManager.run_score)
		return

	_play_radius = max(1.0, float(_level_data.get("tunnel_radius", 6.0)) - PADDLE_SURFACE_INSET)
	_paddle_width = max(0.2, float(_level_data.get("paddle_width", 0.9)))
	_paddle_z = float(_level_data.get("paddle_z", 3.0))
	_z_fail = _paddle_z - 1.0
	_ball_theta = 0.0
	_ball_z = _paddle_z + 1.6
	_ball_v_theta = float(_level_data.get("start_speed_theta", 0.3))
	_ball_v_z = absf(float(_level_data.get("start_speed_z", 8.0)))
	_paddle_theta = 0.0
	_chain_combo = 0
	_combo_timeout = 0.0
	_wide_timer = 0.0
	_slow_timer = 0.0
	_pending_transition = false
	_transition_mode = ""
	_transition_time = 0.0
	_paddle_flash_timer = 0.0
	_signal_gate_hit_timer = 0.0
	_signal_gate_break_progress = 0.0
	_tutorial_enabled = _level_index == 1 and RunManager.tutorial_requested and not SaveStore.tutorial_prompts_disabled
	_tutorial_rotate_seen = false
	_tutorial_catch_seen = false
	_tutorial_fragment_seen = false
	_tutorial_powerups_seen.clear()

	if _run_style == STYLE_OVERDRIVE:
		_ball_v_theta *= 1.20
		_ball_v_z *= 1.14
		_paddle_width *= 0.92
	else:
		_ball_v_theta *= 0.94
		_ball_v_z *= 0.95
		_paddle_width *= 1.04

	# Adaptive guardrail: after repeated failures, widen paddle and reduce speed spikes.
	if SaveStore.fail_streak >= 2:
		var fail_help: int = min(SaveStore.fail_streak, 4)
		_paddle_width += 0.05 * float(fail_help)
		_ball_v_z *= 0.96
		_ball_v_theta *= 0.97

	if rot_input != null and rot_input.has_method("reset"):
		rot_input.reset()
	_level_end_z = _compute_level_end_z()
	_begin_tunnel_layout_for_level(level_index, _tunnel_material == null)
	_begin_portal_light_for_level(level_index)

	_refresh_tunnel_visual()
	_spawn_bricks()
	_clear_powerups()
	_update_ball_visual()
	_reset_ball_tracers()
	_update_paddle_visual()
	_update_camera(0.0, true)
	if _tutorial_enabled:
		_show_tutorial_pause(
			"Rotate the Stabilizer",
			"Drag or tilt to rotate the glowing stabilizer around the tunnel. Move it now to let the pulse launch.",
			"stabilizer",
			"input"
		)
	else:
		_show_message("DEPTH %d - %s" % [_level_index, "OVERDRIVE" if _run_style == STYLE_OVERDRIVE else "STABILITY"], 1.0)

func _compute_level_end_z() -> float:
	var farthest_brick_z: float = 12.0
	var bricks: Array = _level_data.get("bricks", [])
	var brick_z_size: float = float(_level_data.get("brick_z_size", 1.0))
	for item in bricks:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var brick: Dictionary = item
		farthest_brick_z = max(farthest_brick_z, float(brick.get("z_center", 12.0)) + brick_z_size * 0.6)
	return max(24.0, farthest_brick_z + 6.0)

func _refresh_tunnel_visual() -> void:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = _play_radius + PADDLE_SURFACE_INSET + 0.2
	cylinder.bottom_radius = cylinder.top_radius
	cylinder.height = _level_end_z + 16.0
	cylinder.radial_segments = 48
	cylinder.rings = 12
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	tunnel.mesh = cylinder
	tunnel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	tunnel.position = Vector3(0.0, 0.0, (_level_end_z * 0.5) + 3.0)

	var tunnel_material := ShaderMaterial.new()
	tunnel_material.shader = TUNNEL_FRACTAL_SHADER
	tunnel_material.set_shader_parameter("tunnel_phase", _tunnel_texture_phase)
	tunnel_material.set_shader_parameter("intensity", 0.86)
	tunnel_material.set_shader_parameter("hue_shift", 0.0)
	tunnel_material.set_shader_parameter("device_audio_pulse", _device_audio_pulse)
	tunnel_material.set_shader_parameter("audio_bass", _device_audio_bass)
	tunnel_material.set_shader_parameter("audio_mid", _device_audio_mid)
	tunnel_material.set_shader_parameter("audio_treble", _device_audio_treble)
	tunnel.material_override = tunnel_material
	_tunnel_material = tunnel_material
	_apply_tunnel_layout_material(0.86, 0.0)
	_position_tunnel_end_portal()

func _build_tunnel_end_portal() -> void:
	_portal_fractal_cap = MeshInstance3D.new()
	_portal_fractal_cap.name = "TunnelLightEnd"
	_portal_fractal_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portal_fractal_material = ShaderMaterial.new()
	_portal_fractal_material.shader = TUNNEL_LIGHT_PORTAL_SHADER
	_portal_fractal_material.set_shader_parameter("alpha", 0.66)
	_portal_fractal_material.set_shader_parameter("zoom", 2.5)
	_portal_fractal_material.set_shader_parameter("drift", 0.5)
	_portal_fractal_material.set_shader_parameter("portal_phase", _portal_phase)
	_portal_fractal_cap.material_override = _portal_fractal_material
	_apply_portal_light_material()
	$World.add_child(_portal_fractal_cap)

	_portal_cap = MeshInstance3D.new()
	_portal_cap.name = "SignalGate"
	_portal_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portal_material = ShaderMaterial.new()
	_portal_material.shader = SIGNAL_GATE_SHADER
	_portal_material.set_shader_parameter("alpha", 0.36)
	_portal_material.set_shader_parameter("gate_time", _portal_phase)
	_portal_material.set_shader_parameter("hit_strength", 0.0)
	_portal_material.set_shader_parameter("break_progress", 0.0)
	_portal_animation_speed = portal_animation_speed_for_ball_velocity(_ball_v_z, _ball_v_theta)
	_portal_cap.material_override = _portal_material
	$World.add_child(_portal_cap)
	_build_signal_gate_shards()
	_position_tunnel_end_portal()

func _position_tunnel_end_portal() -> void:
	if _portal_cap == null or _portal_fractal_cap == null:
		return
	var portal_radius: float = _play_radius + PADDLE_SURFACE_INSET + 0.12
	var portal_mesh := _build_disc_mesh(portal_radius, 128)
	_portal_fractal_cap.mesh = portal_mesh
	_portal_fractal_cap.position = Vector3(0.0, 0.0, _level_end_z + 0.06)
	_portal_fractal_cap.rotation = Vector3.ZERO
	_portal_cap.mesh = portal_mesh
	_portal_cap.position = Vector3(0.0, 0.0, _level_end_z)
	_portal_cap.rotation = Vector3.ZERO
	_reset_signal_gate_shards()

func _build_signal_gate_shards() -> void:
	for shard in _signal_gate_shards:
		var node: MeshInstance3D = shard.get("node")
		if node != null and is_instance_valid(node):
			node.queue_free()
	_signal_gate_shards.clear()

	for i in range(SIGNAL_GATE_SHARD_COUNT):
		var shard := MeshInstance3D.new()
		shard.name = "SignalGateShard%d" % i
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.mesh = _build_signal_gate_shard_mesh(i, SIGNAL_GATE_SHARD_COUNT, _play_radius + PADDLE_SURFACE_INSET + 0.12)

		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.no_depth_test = true
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.2, 1.0, 0.94, 0.0)
		material.emission_enabled = true
		material.emission = Color(0.2, 1.0, 0.94)
		material.emission_energy_multiplier = 1.7
		shard.material_override = material
		shard.visible = false
		$World.add_child(shard)

		var angle := (TAU * (float(i) + 0.5)) / float(SIGNAL_GATE_SHARD_COUNT)
		_signal_gate_shards.append({
			"node": shard,
			"material": material,
			"direction": Vector2(cos(angle), sin(angle)),
			"spin": (-1.0 if i % 2 == 0 else 1.0) * (1.6 + float(i % 5) * 0.35),
			"travel": 1.4 + float(i % 4) * 0.38
		})

func _build_signal_gate_shard_mesh(index: int, count: int, radius: float) -> ArrayMesh:
	var start_angle := TAU * float(index) / float(count)
	var end_angle := TAU * float(index + 1) / float(count)
	var middle_angle := (start_angle + end_angle) * 0.5
	var inner_radius := radius * (0.18 + 0.10 * float(index % 3))
	var mid_radius := radius * (0.62 + 0.08 * float(index % 2))

	var vertices := PackedVector3Array([
		Vector3(cos(start_angle) * inner_radius, sin(start_angle) * inner_radius, 0.0),
		Vector3(cos(middle_angle) * radius, sin(middle_angle) * radius, 0.0),
		Vector3(cos(end_angle) * mid_radius, sin(end_angle) * mid_radius, 0.0)
	])
	var uvs := PackedVector2Array()
	for vertex in vertices:
		uvs.append(Vector2(vertex.x / (radius * 2.0) + 0.5, vertex.y / (radius * 2.0) + 0.5))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _reset_signal_gate_shards() -> void:
	for shard in _signal_gate_shards:
		var node: MeshInstance3D = shard.get("node")
		var material: StandardMaterial3D = shard.get("material")
		if node == null or not is_instance_valid(node):
			continue
		node.visible = false
		node.position = Vector3(0.0, 0.0, _level_end_z + 0.03)
		node.rotation = Vector3.ZERO
		node.scale = Vector3.ONE
		if material != null:
			material.albedo_color = Color(0.2, 1.0, 0.94, 0.0)

func _step_signal_gate_shards(progress: float) -> void:
	for shard in _signal_gate_shards:
		var node: MeshInstance3D = shard.get("node")
		var material: StandardMaterial3D = shard.get("material")
		if node == null or not is_instance_valid(node):
			continue
		var direction: Vector2 = shard.get("direction", Vector2.RIGHT)
		var travel: float = float(shard.get("travel", 1.5)) * progress * progress
		node.visible = progress > 0.02 and progress < 0.98
		node.position = Vector3(direction.x * travel, direction.y * travel, _level_end_z + 0.04 + progress * 2.8)
		node.rotation = Vector3(progress * 0.9, progress * 0.55, progress * float(shard.get("spin", 1.5)))
		node.scale = Vector3.ONE * (1.0 + progress * 0.28)
		if material != null:
			var alpha := clampf((1.0 - progress) * 0.72, 0.0, 0.72)
			material.albedo_color = Color(0.28 + progress * 0.72, 1.0 - progress * 0.35, 0.96, alpha)

func _build_disc_mesh(radius: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	uvs.append(Vector2(0.5, 0.5))
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		var radial := Vector2(cos(angle), sin(angle))
		vertices.append(Vector3(radial.x * radius, radial.y * radius, 0.0))
		uvs.append(radial * 0.5 + Vector2(0.5, 0.5))
	for i in range(segments):
		var next_i: int = 1 + ((i + 1) % segments)
		indices.append_array(PackedInt32Array([0, 1 + i, next_i]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _setup_ball_visual() -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = BALL_WORLD_RADIUS
	sphere.height = BALL_WORLD_RADIUS * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	ball_mesh.mesh = sphere

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SHADERTOY_ENERGY_BALL_SHADER
	mat.set_shader_parameter("core_color", Color(1.0, 0.38, 0.02, 1.0))
	mat.set_shader_parameter("hot_color", Color(1.0, 0.93, 0.12, 1.0))
	mat.set_shader_parameter("edge_color", Color(1.0, 0.58, 0.0, 1.0))
	mat.set_shader_parameter("ball_time", _visual_time)
	mat.set_shader_parameter("device_audio_pulse", _device_audio_pulse)
	mat.set_shader_parameter("audio_bass", _device_audio_bass)
	mat.set_shader_parameter("audio_mid", _device_audio_mid)
	mat.set_shader_parameter("audio_treble", _device_audio_treble)
	ball_mesh.material_override = mat
	_ball_material = mat

func _build_ball_tracers() -> void:
	_ball_trail_root = Node3D.new()
	_ball_trail_root.name = "BallTracers"
	$World.add_child(_ball_trail_root)
	_ball_trail_segments.clear()
	_ball_guide_segments.clear()
	_ball_trail_materials.clear()
	_ball_guide_materials.clear()

	for i in range(BALL_TRAIL_SEGMENT_COUNT):
		var segment := _build_tracer_orb(0.16, true)
		_ball_trail_root.add_child(segment)
		_ball_trail_segments.append(segment)
		_ball_trail_materials.append(segment.material_override as StandardMaterial3D)

	for i in range(BALL_GUIDE_SEGMENT_COUNT):
		var guide := _build_tracer_orb(0.12, false)
		_ball_trail_root.add_child(guide)
		_ball_guide_segments.append(guide)
		_ball_guide_materials.append(guide.material_override as StandardMaterial3D)

func _build_tracer_orb(radius: float, tail: bool) -> MeshInstance3D:
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	orb.mesh = sphere
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.no_depth_test = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.12, 1.0, 0.9, 0.45 if tail else 0.34)
	material.emission_enabled = true
	material.emission = Color(0.18, 1.0, 0.92)
	material.emission_energy_multiplier = 1.15 if tail else 0.85
	orb.material_override = material
	orb.visible = false
	return orb

func _build_impact_particles() -> void:
	_impact_particle_root = Node3D.new()
	_impact_particle_root.name = "ImpactParticles"
	$World.add_child(_impact_particle_root)
	_impact_particles.clear()

	var pool_size := IMPACT_PARTICLE_COUNT * 4
	for i in range(pool_size):
		var particle := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.055
		sphere.height = 0.11
		sphere.radial_segments = 10
		sphere.rings = 6
		particle.mesh = sphere

		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.no_depth_test = true
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.2, 1.0, 0.95, 0.0)
		material.emission_enabled = true
		material.emission = Color(0.2, 1.0, 0.95)
		material.emission_energy_multiplier = 1.6
		particle.material_override = material
		particle.visible = false
		_impact_particle_root.add_child(particle)
		_impact_particles.append({
			"node": particle,
			"material": material,
			"velocity": Vector3.ZERO,
			"age": IMPACT_PARTICLE_LIFETIME,
			"lifetime": IMPACT_PARTICLE_LIFETIME
		})

func _build_powerup_root() -> void:
	_powerup_root = Node3D.new()
	_powerup_root.name = "Powerups"
	$World.add_child(_powerup_root)
	_powerups.clear()

func _make_powerup_node(power_type: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Powerup%s" % power_type
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	sphere.radial_segments = 18
	sphere.rings = 9
	node.mesh = sphere
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.no_depth_test = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = _powerup_color(power_type)
	material.emission_enabled = true
	material.emission = _powerup_color(power_type)
	material.emission_energy_multiplier = 2.2
	node.material_override = material
	return node

func _maybe_spawn_powerup(brick: Node) -> void:
	if _powerup_root == null or randf() > POWERUP_PICKUP_CHANCE:
		return
	var power_type := _pick_powerup_type()
	var node := _make_powerup_node(power_type)
	_powerup_root.add_child(node)
	var theta := float(brick.get("theta_center"))
	var z := float(brick.get("z_center"))
	node.position = TunnelMath.surface_to_world(theta, z, _play_radius)
	_powerups.append({
		"type": power_type,
		"theta": theta,
		"z": z,
		"node": node,
		"age": 0.0
	})
	_show_message("%s MODULE" % power_type, 0.55)

func _pick_powerup_type() -> String:
	var roll := randf()
	if roll < 0.42:
		return POWERUP_WIDE
	if roll < 0.76:
		return POWERUP_SLOW
	return POWERUP_BLAST

func _powerup_color(power_type: String) -> Color:
	match power_type:
		POWERUP_WIDE:
			return Color(0.05, 1.0, 0.82, 0.82)
		POWERUP_SLOW:
			return Color(0.22, 0.52, 1.0, 0.82)
		POWERUP_BLAST:
			return Color(1.0, 0.22, 0.82, 0.86)
		_:
			return Color(1.0, 0.9, 0.2, 0.82)

func _step_powerups(delta: float) -> void:
	if _powerups.is_empty():
		return
	for i in range(_powerups.size() - 1, -1, -1):
		var powerup := _powerups[i]
		var node: MeshInstance3D = powerup["node"]
		if node == null or not is_instance_valid(node):
			_powerups.remove_at(i)
			continue
		var theta := float(powerup["theta"])
		var z := float(powerup["z"]) - POWERUP_Z_SPEED * delta
		var age := float(powerup["age"]) + delta
		powerup["z"] = z
		powerup["age"] = age
		node.position = TunnelMath.surface_to_world(theta, z, _play_radius)
		node.scale = Vector3.ONE * (0.88 + 0.24 * sin(_visual_time * 7.0 + age * 2.0))
		node.rotate_z(delta * 2.8)

		if z <= _paddle_z + POWERUP_COLLECT_Z_WINDOW:
			var theta_delta := absf(TunnelMath.theta_distance(theta, _paddle_theta))
			if theta_delta <= _paddle_collision_width() * 0.55:
				_collect_powerup(String(powerup["type"]), node.position)
				node.queue_free()
				_powerups.remove_at(i)
			elif z < _z_fail:
				node.queue_free()
				_powerups.remove_at(i)

func _collect_powerup(power_type: String, origin: Vector3) -> void:
	match power_type:
		POWERUP_WIDE:
			_wide_timer = POWERUP_WIDE_DURATION
			_show_message("WIDE SIGNAL MODULE", 0.8)
		POWERUP_SLOW:
			_slow_timer = POWERUP_SLOW_DURATION
			_ball_v_z = signf(_ball_v_z) * maxf(absf(_ball_v_z) * 0.72, POWERUP_SLOW_MIN_Z_SPEED)
			_ball_v_theta *= 0.76
			_show_message("SLOW SIGNAL MODULE", 0.8)
		POWERUP_BLAST:
			_blast_nearby_bricks(3)
			_show_message("PRISM BLAST MODULE", 0.8)
	RunManager.add_score(180)
	_spawn_ball_impact_burst(origin, _powerup_color(power_type), 1.25)
	_flash_paddle()
	_start_camera_shake(0.075, 0.18)
	_pulse_haptic(46, 0.85)
	if _tutorial_enabled and not _tutorial_powerups_seen.has(power_type):
		_tutorial_powerups_seen[power_type] = true
		_show_tutorial_pause(
			"%s Signal Module" % powerup_display_name(power_type),
			powerup_tutorial_text(power_type),
			"powerup",
			"continue"
		)

func _step_powerup_timers(delta: float) -> void:
	_wide_timer = maxf(_wide_timer - delta, 0.0)
	_slow_timer = maxf(_slow_timer - delta, 0.0)

func _blast_nearby_bricks(limit: int) -> void:
	var removed := 0
	for i in range(_bricks.size() - 1, -1, -1):
		if removed >= limit:
			return
		var brick: Node3D = _bricks[i]
		if brick == null or not is_instance_valid(brick):
			_bricks.remove_at(i)
			continue
		var dz := absf(float(brick.get("z_center")) - _ball_z)
		if dz > 8.5:
			continue
		_spawn_ball_impact_burst(brick.global_position, Color(1.0, 0.22, 0.82), 1.0)
		brick.queue_free()
		_bricks.remove_at(i)
		removed += 1
	if _bricks.is_empty():
		_complete_level()

func _clear_powerups() -> void:
	for powerup in _powerups:
		var node: MeshInstance3D = powerup.get("node")
		if node != null and is_instance_valid(node):
			node.queue_free()
	_powerups.clear()

func _build_paddle_segments() -> void:
	for child in paddle_root.get_children():
		child.queue_free()
	_paddle_segments.clear()
	_paddle_materials.clear()

	for i in range(PADDLE_SEGMENT_COUNT):
		var segment: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.3, 0.4, 0.2)
		segment.mesh = mesh

		var material: StandardMaterial3D = StandardMaterial3D.new()
		var hue := fmod(0.44 + float(i) * 0.045, 1.0)
		material.albedo_color = Color.from_hsv(hue, 0.78, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(hue, 0.9, 1.0)
		material.emission_energy_multiplier = 0.85
		material.roughness = 0.28
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		segment.material_override = material

		paddle_root.add_child(segment)
		_paddle_segments.append(segment)
		_paddle_materials.append(material)

func _update_paddle_visual() -> void:
	if _paddle_segments.is_empty():
		return

	for i in range(_paddle_segments.size()):
		var segment: MeshInstance3D = _paddle_segments[i]
		var t: float = 0.0
		if _paddle_segments.size() > 1:
			t = float(i) / float(_paddle_segments.size() - 1) - 0.5
		var current_width: float = _effective_paddle_width()
		var segment_theta: float = TunnelMath.wrap_angle(_paddle_theta + t * current_width)
		var tangent: Vector3 = Vector3(-sin(segment_theta), cos(segment_theta), 0.0).normalized()
		var forward: Vector3 = TUNNEL_FORWARD
		var inward: Vector3 = -Vector3(cos(segment_theta), sin(segment_theta), 0.0).normalized()
		segment.position = TunnelMath.surface_to_world(segment_theta, _paddle_z, _play_radius)
		segment.basis = Basis(tangent, forward, inward).orthonormalized()

		if segment.mesh is BoxMesh:
			var mesh: BoxMesh = segment.mesh as BoxMesh
			var arc_len: float = max((current_width / float(PADDLE_SEGMENT_COUNT)) * _play_radius * PADDLE_VISUAL_ARC_SCALE, 0.18)
			mesh.size = Vector3(arc_len, 0.55, 0.22)
		if i < _paddle_materials.size():
			var material := _paddle_materials[i]
			var base_energy := 0.85
			if _paddle_flash_timer > 0.0:
				base_energy = 2.2
			if _tutorial_focus == "stabilizer":
				base_energy = 3.5 + 0.9 * sin(_visual_time * 9.0)
			material.emission_energy_multiplier = base_energy

func _paddle_collision_width() -> float:
	var current_width := _effective_paddle_width()
	var segment_overhang := (current_width / float(PADDLE_SEGMENT_COUNT)) * PADDLE_VISUAL_ARC_SCALE
	return current_width + segment_overhang

func _effective_paddle_width() -> float:
	return _paddle_width * (1.42 if _wide_timer > 0.0 else 1.0)

func _update_ball_visual() -> void:
	ball_mesh.position = TunnelMath.surface_to_world(_ball_theta, _ball_z, _play_radius)
	var pulse := 1.0 + 0.18 * sin(_visual_time * 7.5)
	ball_mesh.scale = Vector3.ONE * pulse
	_update_ball_tracers(ball_mesh.position)

func _reset_ball_tracers() -> void:
	_ball_trail_points.clear()
	var current_position := TunnelMath.surface_to_world(_ball_theta, _ball_z, _play_radius)
	for i in range(BALL_TRAIL_SEGMENT_COUNT):
		_ball_trail_points.append(current_position)
	_update_ball_tracers(current_position, true)

func _update_ball_tracers(current_position: Vector3, force: bool = false) -> void:
	if _ball_trail_root == null:
		return
	if force or _ball_trail_points.is_empty() or current_position.distance_to(_ball_trail_points[0]) > 0.18:
		_ball_trail_points.push_front(current_position)
		while _ball_trail_points.size() > BALL_TRAIL_SEGMENT_COUNT:
			_ball_trail_points.pop_back()

	for i in range(_ball_trail_segments.size()):
		var segment := _ball_trail_segments[i]
		if i >= _ball_trail_points.size():
			segment.visible = false
			continue
		var t := 1.0 - (float(i) / maxf(1.0, float(BALL_TRAIL_SEGMENT_COUNT - 1)))
		var hue := fmod(0.47 + _visual_time * 0.08 + float(i) * 0.035, 1.0)
		segment.visible = true
		segment.position = _ball_trail_points[i]
		segment.scale = Vector3.ONE * (0.28 + t * 0.82)
		var material := _ball_trail_materials[i]
		material.albedo_color = Color.from_hsv(hue, 0.9, 1.0, 0.08 + t * 0.38)
		material.emission = Color.from_hsv(hue, 1.0, 1.0)
		material.emission_energy_multiplier = 0.45 + t * 1.15

	for i in range(_ball_guide_segments.size()):
		var guide := _ball_guide_segments[i]
		var lookahead := 0.13 + float(i) * 0.11
		var predicted_theta := TunnelMath.wrap_angle(_ball_theta + _ball_v_theta * lookahead)
		var predicted_z := clampf(_ball_z + _ball_v_z * lookahead, _z_fail, _level_end_z)
		var fade := 1.0 - float(i) / float(maxi(1, BALL_GUIDE_SEGMENT_COUNT))
		var hue := fmod(0.14 + _visual_time * 0.1 + float(i) * 0.05, 1.0)
		guide.visible = true
		guide.position = TunnelMath.surface_to_world(predicted_theta, predicted_z, _play_radius)
		guide.scale = Vector3.ONE * (0.75 - float(i) * 0.09)
		var guide_material := _ball_guide_materials[i]
		guide_material.albedo_color = Color.from_hsv(hue, 0.75, 1.0, 0.12 + fade * 0.18)
		guide_material.emission = Color.from_hsv(hue, 0.95, 1.0)
		guide_material.emission_energy_multiplier = 0.55 + fade * 0.5

func _spawn_ball_impact_burst(origin: Vector3, base_color: Color, intensity: float = 1.0) -> void:
	if _impact_particles.is_empty():
		return
	var outward := Vector3(cos(_ball_theta), sin(_ball_theta), 0.0).normalized()
	var tangent := Vector3(-sin(_ball_theta), cos(_ball_theta), 0.0).normalized()
	var forward := TUNNEL_FORWARD
	for i in range(IMPACT_PARTICLE_COUNT):
		var particle := _next_free_impact_particle()
		if particle.is_empty():
			return
		var node: MeshInstance3D = particle["node"]
		var material: StandardMaterial3D = particle["material"]
		var theta_spread := randf_range(-1.0, 1.0)
		var forward_spread := randf_range(-1.0, 1.0)
		var lift := randf_range(0.2, 1.0)
		var speed := randf_range(4.2, 9.0) * intensity
		var velocity := (tangent * theta_spread + forward * forward_spread + outward * lift).normalized() * speed
		var hue := fmod(0.82 + randf_range(-0.16, 0.16) + _visual_time * 0.03, 1.0)
		var color := Color.from_hsv(hue, 0.85, 1.0).lerp(base_color, 0.55)

		node.visible = true
		node.position = origin + outward * 0.08
		node.scale = Vector3.ONE * randf_range(0.72, 1.25)
		material.albedo_color = Color(color.r, color.g, color.b, 0.88)
		material.emission = color
		material.emission_energy_multiplier = 1.4 + intensity * 0.9
		particle["velocity"] = velocity
		particle["age"] = 0.0
		particle["lifetime"] = IMPACT_PARTICLE_LIFETIME * randf_range(0.82, 1.22)

func _next_free_impact_particle() -> Dictionary:
	for particle in _impact_particles:
		var node: MeshInstance3D = particle["node"]
		if not node.visible:
			return particle
	return {}

func _update_impact_particles(delta: float) -> void:
	if _impact_particles.is_empty():
		return
	for particle in _impact_particles:
		var node: MeshInstance3D = particle["node"]
		if not node.visible:
			continue
		var age := float(particle["age"]) + delta
		var lifetime := float(particle["lifetime"])
		if age >= lifetime:
			node.visible = false
			particle["age"] = lifetime
			continue
		var velocity: Vector3 = particle["velocity"]
		velocity *= pow(0.12, delta)
		node.position += velocity * delta
		node.scale *= 1.0 + delta * 1.8
		var t := clampf(age / lifetime, 0.0, 1.0)
		var material: StandardMaterial3D = particle["material"]
		material.albedo_color.a = (1.0 - t) * 0.86
		material.emission_energy_multiplier = (1.0 - t) * 2.2
		particle["velocity"] = velocity
		particle["age"] = age

func _spawn_bricks() -> void:
	for brick in _bricks:
		if brick != null and is_instance_valid(brick):
			brick.queue_free()
	_bricks.clear()

	var default_theta_size: float = float(_level_data.get("brick_theta_size", 0.42))
	var default_z_size: float = float(_level_data.get("brick_z_size", 1.0))
	var source_bricks: Array = _level_data.get("bricks", [])
	for item in source_bricks:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var brick_data: Dictionary = item
		var brick: Node3D = BRICK_SCENE.instantiate() as Node3D
		brick_root.add_child(brick)
		brick.call("setup", brick_data, _play_radius, default_theta_size, default_z_size)
		_bricks.append(brick)
	_initial_brick_count = _bricks.size()

func _update_camera(delta: float, snap: bool = false) -> void:
	# Adapted from wormhole_raiders AngleSystem camera strategy:
	# scripts/systems/AngleSystem.gd::_update_camera
	var paddle_pos: Vector3 = TunnelMath.surface_to_world(_paddle_theta, _paddle_z, _play_radius)
	var outward: Vector3 = Vector3(cos(_paddle_theta), sin(_paddle_theta), 0.0).normalized()
	var inward: Vector3 = -outward
	var forward: Vector3 = TUNNEL_FORWARD
	var zoom_out: float = _camera_zoom_out_scale()
	var target_fov: float = lerpf(CAMERA_BASE_FOV, CAMERA_MOBILE_FOV, clampf(zoom_out - 1.0, 0.0, 1.0))
	camera.fov = lerpf(camera.fov, target_fov, 1.0 if snap else clampf(delta * 5.0, 0.0, 1.0))

	var cam_target: Vector3 = paddle_pos + inward * (CAMERA_BASE_INWARD_DISTANCE * zoom_out) - forward * (CAMERA_BASE_BACK_DISTANCE * zoom_out)
	if snap:
		camera.global_position = cam_target
	else:
		camera.global_position = camera.global_position.lerp(cam_target, clampf(delta * 8.0, 0.0, 1.0))

	var look_target: Vector3 = paddle_pos + forward * (CAMERA_BASE_LOOK_AHEAD * zoom_out) + inward * (0.9 * zoom_out)
	camera.look_at(look_target, inward)
	_apply_camera_shake(delta)

func _camera_zoom_out_scale() -> float:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / maxf(viewport_size.y, 1.0)
	var scale: float = 1.0
	if OS.has_feature("mobile"):
		scale = 1.22
	if aspect < 0.8:
		scale = maxf(scale, 1.42)
	elif aspect < 1.15:
		scale = maxf(scale, 1.25)
	return scale

func _update_psychedelic_materials() -> void:
	if _tunnel_material != null:
		var pulse := 0.5 + 0.5 * sin(_visual_time * 0.9)
		var audio_intensity := _device_audio_pulse * 0.58 + _device_audio_bass * 0.42
		_apply_tunnel_layout_material(0.78 + pulse * 0.26 + audio_intensity, _visual_time)
	if _ball_material != null:
		var ball_hue := fmod(0.13 + _visual_time * 0.07, 1.0)
		_ball_material.set_shader_parameter("ball_time", _visual_time)
		_ball_material.set_shader_parameter("hue_shift", ball_hue)
		_ball_material.set_shader_parameter("device_audio_pulse", _device_audio_pulse)
		_ball_material.set_shader_parameter("audio_bass", _device_audio_bass)
		_ball_material.set_shader_parameter("audio_mid", _device_audio_mid)
		_ball_material.set_shader_parameter("audio_treble", _device_audio_treble)
	for i in range(_paddle_materials.size()):
		var material := _paddle_materials[i]
		var hue := fmod(0.42 + _visual_time * 0.045 + float(i) * 0.035, 1.0)
		if _paddle_flash_timer > 0.0:
			hue = fmod(0.13 + _visual_time * 0.18, 1.0)
		material.albedo_color = Color.from_hsv(hue, 0.72, 1.0)
		material.emission = Color.from_hsv(hue, 0.96, 1.0)
		var flash_boost := 1.45 * (_paddle_flash_timer / PADDLE_FLASH_DURATION) if _paddle_flash_timer > 0.0 else 0.0
		material.emission_energy_multiplier = 0.65 + 0.28 * absf(sin(_visual_time * 2.4 + float(i))) + flash_boost
	if _portal_fractal_material != null and not _pending_transition:
		var portal_pulse := 0.5 + 0.5 * sin(_visual_time * 1.1)
		_portal_fractal_material.set_shader_parameter("alpha", 0.58 + portal_pulse * 0.12 + _device_audio_mid * 0.14)
		_portal_fractal_material.set_shader_parameter("zoom", 2.45 + portal_pulse * 0.24 + _device_audio_mid * 0.32)
	if _portal_material != null and not _pending_transition:
		var gate_pulse := 0.5 + 0.5 * sin(_visual_time * 2.0)
		_portal_material.set_shader_parameter("alpha", 0.28 + gate_pulse * 0.08 + _device_audio_treble * 0.12)
		_portal_material.set_shader_parameter("audio_treble", _device_audio_treble)
	if key_light != null:
		key_light.light_color = Color.from_hsv(fmod(0.81 + _visual_time * 0.035, 1.0), 0.6, 1.0)
	if fill_light != null:
		fill_light.light_color = Color.from_hsv(fmod(0.48 + _visual_time * 0.055, 1.0), 0.72, 1.0)

func _apply_psychedelic_lighting() -> void:
	if key_light != null:
		key_light.light_energy = 1.9
		key_light.light_color = Color(0.95, 0.35, 1.0)
	if fill_light != null:
		fill_light.light_energy = 2.2
		fill_light.omni_range = 52.0
		fill_light.light_color = Color(0.15, 1.0, 0.9)

func _apply_hud_style() -> void:
	if hud_panel != null:
		var hud_vbox := hud_panel.get_node_or_null("VBox") as VBoxContainer
		if hud_vbox != null:
			hud_vbox.add_theme_constant_override("separation", 1)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.008, 0.0, 0.04, 0.82)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(0.0, 1.0, 0.9, 0.66)
		panel_style.corner_radius_top_left = 16
		panel_style.corner_radius_top_right = 16
		panel_style.corner_radius_bottom_right = 16
		panel_style.corner_radius_bottom_left = 16
		panel_style.shadow_size = 16
		panel_style.shadow_color = Color(0.75, 0.0, 1.0, 0.18)
		panel_style.content_margin_left = 14.0
		panel_style.content_margin_top = 9.0
		panel_style.content_margin_right = 14.0
		panel_style.content_margin_bottom = 9.0
		hud_panel.add_theme_stylebox_override("panel", panel_style)
	for label in [score_label, level_label, objective_label, style_label, phase_label, combo_label]:
		if label == null:
			continue
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.84, 1.0, 0.96, 0.94))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.28))
	objective_label.add_theme_color_override("font_color", Color(0.58, 1.0, 0.96, 0.96))
	phase_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.25, 0.96))
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.95))
	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _build_tutorial_overlay() -> void:
	_tutorial_overlay = PanelContainer.new()
	_tutorial_overlay.name = "TutorialPauseOverlay"
	_tutorial_overlay.visible = false
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_control_rect(_tutorial_overlay, Rect2(Vector2(0, 0), Vector2(360, 220)))
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.0, 0.052, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1.0, 0.84, 0.18, 0.82)
	panel_style.corner_radius_top_left = 22
	panel_style.corner_radius_top_right = 22
	panel_style.corner_radius_bottom_right = 22
	panel_style.corner_radius_bottom_left = 22
	panel_style.shadow_size = 22
	panel_style.shadow_color = Color(1.0, 0.1, 0.9, 0.28)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_top = 16.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_bottom = 16.0
	_tutorial_overlay.add_theme_stylebox_override("panel", panel_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_tutorial_overlay.add_child(box)

	_tutorial_title_label = Label.new()
	_tutorial_title_label.add_theme_font_size_override("font_size", 24)
	_tutorial_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.26))
	_tutorial_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_tutorial_title_label)

	_tutorial_body_label = Label.new()
	_tutorial_body_label.add_theme_font_size_override("font_size", 15)
	_tutorial_body_label.add_theme_color_override("font_color", Color(0.82, 1.0, 0.98))
	_tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_tutorial_body_label)

	_tutorial_disable_check = CheckBox.new()
	_tutorial_disable_check.text = "Do not show again"
	_tutorial_disable_check.add_theme_font_size_override("font_size", 14)
	_tutorial_disable_check.add_theme_color_override("font_color", Color(0.9, 0.94, 1.0, 0.88))
	box.add_child(_tutorial_disable_check)

	_tutorial_continue_button = Button.new()
	_tutorial_continue_button.text = "CONTINUE"
	_tutorial_continue_button.custom_minimum_size = Vector2(220, 46)
	_tutorial_continue_button.add_theme_font_size_override("font_size", 18)
	_apply_tutorial_button_style(_tutorial_continue_button)
	_tutorial_continue_button.pressed.connect(_on_tutorial_continue_pressed)
	box.add_child(_tutorial_continue_button)
	$HUD.add_child(_tutorial_overlay)
	_layout_tutorial_overlay()

func _layout_hud() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if hud_panel != null:
		var dock_rect := hud_dock_rect_for_viewport(viewport_size)
		_apply_control_rect(hud_panel, dock_rect)
		hud_panel.custom_minimum_size = dock_rect.size
	if message_label != null:
		_apply_control_rect(message_label, hud_message_rect_for_viewport(viewport_size))
	_layout_tutorial_overlay()
	_layout_device_audio_debug_label()
	_layout_web_audio_connect_button()

func _layout_device_audio_debug_label() -> void:
	if _device_audio_debug_label == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var height := 30.0
	var width: float = clampf(viewport_size.x - HUD_DOCK_SAFE_MARGIN * 2.0, 320.0, 560.0)
	var x := HUD_DOCK_SAFE_MARGIN
	var y := maxf(HUD_DOCK_SAFE_MARGIN, viewport_size.y - HUD_DOCK_SAFE_MARGIN - height)
	_apply_control_rect(_device_audio_debug_label, Rect2(Vector2(x, y), Vector2(width, height)))

func _layout_web_audio_connect_button() -> void:
	if _web_audio_connect_button == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var width := 196.0
	var height := 42.0
	var x := HUD_DOCK_SAFE_MARGIN
	var y := maxf(HUD_DOCK_SAFE_MARGIN, viewport_size.y - HUD_DOCK_SAFE_MARGIN - 30.0 - 12.0 - height)
	_apply_control_rect(_web_audio_connect_button, Rect2(Vector2(x, y), Vector2(width, height)))

func _layout_tutorial_overlay() -> void:
	if _tutorial_overlay == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var dock_rect := hud_dock_rect_for_viewport(viewport_size)
	var width: float = clampf(viewport_size.x - HUD_DOCK_SAFE_MARGIN * 2.0, 320.0, 520.0)
	var height: float = 224.0
	var x: float = (viewport_size.x - width) * 0.5
	var y: float = maxf(HUD_DOCK_SAFE_MARGIN, dock_rect.position.y - height - 28.0)
	_apply_control_rect(_tutorial_overlay, Rect2(Vector2(x, y), Vector2(width, height)))

static func hud_dock_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	var width: float = clampf(viewport_size.x - HUD_DOCK_SAFE_MARGIN * 2.0, HUD_DOCK_MIN_WIDTH, HUD_DOCK_MAX_WIDTH)
	var height: float = minf(HUD_DOCK_HEIGHT, maxf(126.0, viewport_size.y * 0.20))
	var x: float = (viewport_size.x - width) * 0.5
	var y: float = maxf(HUD_DOCK_SAFE_MARGIN, viewport_size.y - HUD_DOCK_SAFE_MARGIN - height)
	return Rect2(Vector2(x, y), Vector2(width, height))

static func hud_message_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	var dock_rect := hud_dock_rect_for_viewport(viewport_size)
	var width: float = clampf(viewport_size.x - HUD_DOCK_SAFE_MARGIN * 2.0, 320.0, 820.0)
	var x: float = (viewport_size.x - width) * 0.5
	var y: float = maxf(HUD_DOCK_SAFE_MARGIN, dock_rect.position.y - HUD_MESSAGE_HEIGHT - 14.0)
	return Rect2(Vector2(x, y), Vector2(width, HUD_MESSAGE_HEIGHT))

static func portal_animation_speed_for_ball_velocity(ball_v_z: float, ball_v_theta: float) -> float:
	var forward_speed: float = absf(ball_v_z)
	var angular_speed: float = absf(ball_v_theta) * 2.5
	var speed_ratio: float = clampf(((forward_speed + angular_speed) - 7.0) / 9.0, 0.0, 1.0)
	return clampf(lerpf(PORTAL_BASE_ANIMATION_SPEED, PORTAL_MAX_ANIMATION_SPEED, speed_ratio), PORTAL_BASE_ANIMATION_SPEED, PORTAL_MAX_ANIMATION_SPEED)

static func smoothed_portal_animation_speed(current_speed: float, target_speed: float, delta: float) -> float:
	var weight: float = 1.0 - exp(-PORTAL_SPEED_ACCELERATION * maxf(delta, 0.0))
	return lerpf(current_speed, target_speed, clampf(weight, 0.0, 1.0))

static func tunnel_texture_speed_for_ball_velocity(ball_v_z: float, ball_v_theta: float) -> float:
	var forward_speed: float = absf(ball_v_z)
	var angular_speed: float = absf(ball_v_theta) * 2.0
	var speed_ratio: float = clampf(((forward_speed + angular_speed) - 7.0) / 11.0, 0.0, 1.0)
	return clampf(lerpf(TUNNEL_TEXTURE_BASE_SPEED, TUNNEL_TEXTURE_MAX_SPEED, speed_ratio), TUNNEL_TEXTURE_BASE_SPEED, TUNNEL_TEXTURE_MAX_SPEED)

static func smoothed_tunnel_texture_speed(current_speed: float, target_speed: float, delta: float) -> float:
	var weight: float = 1.0 - exp(-TUNNEL_TEXTURE_SPEED_ACCELERATION * maxf(delta, 0.0))
	return lerpf(current_speed, target_speed, clampf(weight, 0.0, 1.0))

static func audio_beat_onset(current_pulse: float, previous_pulse: float, current_energy: float = 0.0, previous_energy: float = 0.0) -> bool:
	var safe_current := clampf(current_pulse, 0.0, DEVICE_AUDIO_PULSE_MAX)
	var safe_previous := clampf(previous_pulse, 0.0, DEVICE_AUDIO_PULSE_MAX)
	var safe_energy := maxf(current_energy, 0.0)
	var safe_previous_energy := maxf(previous_energy, 0.0)
	var pulse_onset := safe_current >= AUDIO_BPM_ONSET_PULSE_MIN and (safe_current - safe_previous) >= AUDIO_BPM_ONSET_PULSE_RISE
	var energy_onset := safe_energy >= AUDIO_BPM_ONSET_ENERGY_MIN and (safe_energy - safe_previous_energy) >= AUDIO_BPM_ONSET_ENERGY_RISE
	return pulse_onset or energy_onset

static func audio_bpm_from_beat_interval(interval_seconds: float) -> float:
	var safe_interval := maxf(interval_seconds, 0.0)
	if safe_interval < AUDIO_BPM_MIN_INTERVAL:
		return 0.0
	if safe_interval > AUDIO_BPM_MAX_INTERVAL:
		var half_interval := safe_interval * 0.5
		if half_interval < AUDIO_BPM_MIN_INTERVAL or half_interval > AUDIO_BPM_MAX_INTERVAL:
			return 0.0
		safe_interval = half_interval
	return clampf(60.0 / safe_interval, AUDIO_BPM_MIN, AUDIO_BPM_MAX)

static func smoothed_audio_bpm(current_bpm: float, interval_bpm: float) -> float:
	if interval_bpm <= 0.0:
		return clampf(current_bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX)
	var safe_current := clampf(current_bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX)
	var safe_interval := clampf(interval_bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX)
	var blend := AUDIO_BPM_SHIFT_BLEND if absf(safe_interval - safe_current) >= AUDIO_BPM_SHIFT_THRESHOLD else AUDIO_BPM_BLEND
	return lerpf(safe_current, safe_interval, blend)

static func audio_bpm_samples_after_interval(samples: Array[float], interval_bpm: float, current_bpm: float) -> Array[float]:
	var safe_interval := clampf(interval_bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX)
	var next_samples: Array[float] = []
	if absf(safe_interval - clampf(current_bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX)) < AUDIO_BPM_SHIFT_THRESHOLD:
		var start_index: int = maxi(samples.size() - AUDIO_BPM_HISTORY_SIZE + 1, 0)
		for i in range(start_index, samples.size()):
			next_samples.append(clampf(samples[i], AUDIO_BPM_MIN, AUDIO_BPM_MAX))
	next_samples.append(safe_interval)
	return next_samples

static func audio_bpm_from_recent_samples(samples: Array[float]) -> float:
	if samples.is_empty():
		return 0.0
	var total := 0.0
	var total_weight := 0.0
	var start_index: int = maxi(samples.size() - AUDIO_BPM_HISTORY_SIZE, 0)
	var weight := 1.0
	for i in range(start_index, samples.size()):
		var bpm := clampf(samples[i], AUDIO_BPM_MIN, AUDIO_BPM_MAX)
		total += bpm * weight
		total_weight += weight
		weight += 1.0
	if total_weight <= 0.0:
		return 0.0
	return clampf(total / total_weight, AUDIO_BPM_MIN, AUDIO_BPM_MAX)

static func audio_bpm_confidence_after_step(current_confidence: float, valid_onset: bool, timed_out: bool, delta: float, detected_onset: bool = false) -> float:
	var confidence := clampf(current_confidence, 0.0, 1.0)
	if valid_onset:
		return clampf(confidence + AUDIO_BPM_CONFIDENCE_ATTACK, 0.0, 1.0)
	if detected_onset:
		return maxf(confidence, AUDIO_BPM_CONFIDENCE_PROBE)
	if timed_out:
		return clampf(confidence - AUDIO_BPM_CONFIDENCE_DECAY * maxf(delta, 0.0), 0.0, 1.0)
	return confidence

static func audio_beat_speed_kick_after_step(current_kick: float, valid_onset: bool, delta: float) -> float:
	if valid_onset:
		return 1.0
	var weight: float = 1.0 - exp(-AUDIO_BPM_BEAT_KICK_DECAY * maxf(delta, 0.0))
	return lerpf(clampf(current_kick, 0.0, 1.0), 0.0, clampf(weight, 0.0, 1.0))

static func tunnel_texture_speed_for_audio_bpm(base_speed: float, bpm: float, confidence: float, pulse: float, beat_kick: float = 0.0) -> float:
	var safe_base := clampf(base_speed, TUNNEL_TEXTURE_BASE_SPEED, TUNNEL_TEXTURE_MAX_SPEED)
	var safe_confidence := clampf(confidence, 0.0, 1.0)
	var safe_beat_kick := clampf(beat_kick, 0.0, 1.0)
	if safe_confidence <= 0.0 and safe_beat_kick <= 0.0:
		return safe_base
	var kick_confidence := 0.35 if safe_beat_kick > 0.0 else 0.0
	var effective_confidence := maxf(safe_confidence, kick_confidence)
	var bpm_ratio := clampf((clampf(bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX) - AUDIO_BPM_MIN) / (AUDIO_BPM_MAX - AUDIO_BPM_MIN), 0.0, 1.0)
	var bpm_speed := lerpf(TUNNEL_TEXTURE_BASE_SPEED, TUNNEL_TEXTURE_MAX_SPEED, bpm_ratio)
	var blended_speed := lerpf(safe_base, maxf(safe_base, bpm_speed), safe_confidence * AUDIO_BPM_TUNNEL_BLEND)
	var pulse_boost := clampf(pulse, 0.0, DEVICE_AUDIO_PULSE_MAX) * effective_confidence * AUDIO_BPM_PULSE_SPEED_BOOST
	var kick_boost := safe_beat_kick * effective_confidence * AUDIO_BPM_BEAT_SPEED_KICK
	return clampf(blended_speed + pulse_boost + kick_boost, TUNNEL_TEXTURE_BASE_SPEED, TUNNEL_TEXTURE_MAX_SPEED)

static func is_tunnel_layout_id(layout_id: String) -> bool:
	return TUNNEL_LAYOUT_PRESETS.has(layout_id.strip_edges().to_lower())

static func normalized_tunnel_layout_lineup(raw_lineup: String) -> PackedStringArray:
	var lineup := PackedStringArray()
	for raw_item in raw_lineup.replace(";", ",").replace("|", ",").split(",", false):
		var layout_id := String(raw_item).strip_edges().to_lower()
		if is_tunnel_layout_id(layout_id) and not lineup.has(layout_id):
			lineup.append(layout_id)
	return lineup

static func default_tunnel_layout_lineup() -> PackedStringArray:
	var lineup := PackedStringArray()
	for layout_id in TUNNEL_LAYOUT_DEFAULT_LINEUP:
		lineup.append(layout_id)
	return lineup

static func tunnel_layout_for_level(level_index: int, level_data: Dictionary = {}, lineup: PackedStringArray = PackedStringArray()) -> String:
	var level_layout := String(level_data.get("tunnel_layout", "")).strip_edges().to_lower()
	if is_tunnel_layout_id(level_layout):
		return level_layout
	var active_lineup := lineup
	if active_lineup.is_empty():
		active_lineup = default_tunnel_layout_lineup()
	if active_lineup.is_empty():
		return TUNNEL_LAYOUT_DEFAULT
	var index := posmod(maxi(level_index, 1) - 1, active_lineup.size())
	return active_lineup[index]

static func tunnel_layout_transition_blend(elapsed: float, duration: float = TUNNEL_LAYOUT_TRANSITION_DURATION) -> float:
	var t := 1.0 if duration <= 0.0 else clampf(elapsed / duration, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func is_portal_light_id(light_id: String) -> bool:
	return PORTAL_LIGHT_PRESETS.has(light_id.strip_edges().to_lower())

static func normalized_portal_light_lineup(raw_lineup: String) -> PackedStringArray:
	var lineup := PackedStringArray()
	for raw_item in raw_lineup.replace(";", ",").replace("|", ",").split(",", false):
		var light_id := String(raw_item).strip_edges().to_lower()
		if is_portal_light_id(light_id) and not lineup.has(light_id):
			lineup.append(light_id)
	return lineup

static func default_portal_light_lineup() -> PackedStringArray:
	var lineup := PackedStringArray()
	for light_id in PORTAL_LIGHT_DEFAULT_LINEUP:
		lineup.append(light_id)
	return lineup

static func portal_light_for_level(level_index: int, level_data: Dictionary = {}, lineup: PackedStringArray = PackedStringArray()) -> String:
	var level_light := String(level_data.get("portal_light", "")).strip_edges().to_lower()
	if is_portal_light_id(level_light):
		return level_light
	var active_lineup := lineup
	if active_lineup.is_empty():
		active_lineup = default_portal_light_lineup()
	if active_lineup.is_empty():
		return PORTAL_LIGHT_DEFAULT
	var index := posmod(maxi(level_index, 1) - 1, active_lineup.size())
	return active_lineup[index]

static func device_audio_pulse_target(energy: float, previous_energy: float) -> float:
	var safe_energy := maxf(energy, 0.0)
	var safe_previous := maxf(previous_energy, 0.0)
	var level_pulse := minf(maxf(safe_energy - DEVICE_AUDIO_PULSE_THRESHOLD, 0.0) * DEVICE_AUDIO_PULSE_LEVEL_GAIN, DEVICE_AUDIO_PULSE_LEVEL_MAX)
	var onset_pulse := maxf((safe_energy - safe_previous) - DEVICE_AUDIO_PULSE_ONSET_THRESHOLD, 0.0) * DEVICE_AUDIO_PULSE_ONSET_GAIN
	return clampf(maxf(level_pulse, onset_pulse), 0.0, DEVICE_AUDIO_PULSE_MAX)

static func smoothed_device_audio_pulse(current_pulse: float, target_pulse: float, delta: float) -> float:
	var rate := DEVICE_AUDIO_PULSE_ATTACK if target_pulse > current_pulse else DEVICE_AUDIO_PULSE_DECAY
	var weight: float = 1.0 - exp(-rate * maxf(delta, 0.0))
	return lerpf(clampf(current_pulse, 0.0, DEVICE_AUDIO_PULSE_MAX), clampf(target_pulse, 0.0, DEVICE_AUDIO_PULSE_MAX), clampf(weight, 0.0, 1.0))

static func device_audio_pulse_for_analyzer(analyzer: Object, current_pulse: float, previous_energy: float, delta: float) -> Dictionary:
	if analyzer == null or not _analyzer_has_method(analyzer, "is_available") or not bool(analyzer.call("is_available")) or not _analyzer_has_method(analyzer, "get_energy"):
		return {
			"available": false,
			"energy": 0.0,
			"pulse": smoothed_device_audio_pulse(current_pulse, 0.0, delta),
			"bass": 0.0,
			"mid": 0.0,
			"treble": 0.0
		}
	var energy := maxf(float(analyzer.call("get_energy")), 0.0)
	var native_pulse := 0.0
	if _analyzer_has_method(analyzer, "get_pulse"):
		native_pulse = clampf(float(analyzer.call("get_pulse")), 0.0, DEVICE_AUDIO_PULSE_MAX)
	var target_pulse := maxf(device_audio_pulse_target(energy, previous_energy), native_pulse)
	return {
		"available": true,
		"energy": energy,
		"pulse": smoothed_device_audio_pulse(current_pulse, target_pulse, delta),
		"bass": _analyzer_band(analyzer, "get_bass", energy),
		"mid": _analyzer_band(analyzer, "get_mid", energy),
		"treble": _analyzer_band(analyzer, "get_treble", energy)
	}

static func device_audio_band_state(bass: float, mid: float, treble: float) -> Dictionary:
	return {
		"bass": clampf(bass, 0.0, 1.0),
		"mid": clampf(mid, 0.0, 1.0),
		"treble": clampf(treble, 0.0, 1.0)
	}

static func _analyzer_band(analyzer: Object, method_name: StringName, fallback_energy: float) -> float:
	if analyzer != null and _analyzer_has_method(analyzer, method_name):
		return clampf(float(analyzer.call(method_name)), 0.0, 1.0)
	return clampf(fallback_energy, 0.0, 1.0)

static func _analyzer_has_method(analyzer: Object, method_name: StringName) -> bool:
	if analyzer == null:
		return false
	if analyzer.has_method(method_name):
		return true
	if OS.get_name() == "Android" and method_name in [
		&"request_capture",
		&"is_available",
		&"is_permission_pending",
		&"get_energy",
		&"get_pulse",
		&"get_bass",
		&"get_mid",
		&"get_treble",
		&"stop"
	]:
		return true
	if analyzer.has_method("has_java_method"):
		return bool(analyzer.call("has_java_method", method_name))
	return false

static func device_audio_debug_text(available: bool, energy: float, pulse: float, source_label: String = DEVICE_AUDIO_SOURCE_SYSTEM, bpm: float = -1.0, bpm_confidence: float = 0.0, tunnel_speed: float = -1.0, bass: float = -1.0, mid: float = -1.0, treble: float = -1.0) -> String:
	var text := "%s %s  E %.4f  P %.2f" % [
		source_label,
		"ON" if available else "OFF",
		maxf(energy, 0.0),
		clampf(pulse, 0.0, DEVICE_AUDIO_PULSE_MAX)
	]
	if bpm >= 0.0:
		var confidence := clampf(bpm_confidence, 0.0, 1.0)
		var bpm_text := "--"
		if confidence > 0.05:
			bpm_text = "%03d" % int(round(clampf(bpm, AUDIO_BPM_MIN, AUDIO_BPM_MAX)))
		text += "  BPM %s  C %.2f" % [bpm_text, confidence]
	if tunnel_speed >= 0.0:
		text += "  S %.2f" % clampf(tunnel_speed, TUNNEL_TEXTURE_BASE_SPEED, TUNNEL_TEXTURE_MAX_SPEED)
	if bass >= 0.0 or mid >= 0.0 or treble >= 0.0:
		text += "  B %.2f  M %.2f  T %.2f" % [
			clampf(maxf(bass, 0.0), 0.0, 1.0),
			clampf(maxf(mid, 0.0), 0.0, 1.0),
			clampf(maxf(treble, 0.0), 0.0, 1.0)
		]
	return text


static func game_audio_energy_from_magnitude(magnitude: Vector2) -> float:
	return clampf(magnitude.length() * GAME_AUDIO_ENERGY_GAIN, 0.0, 1.0)

static func mic_audio_energy_from_frames(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var sum := 0.0
	var peak := 0.0
	for frame in frames:
		var mono := maxf(absf(frame.x), absf(frame.y))
		sum += mono * mono
		peak = maxf(peak, mono)
	var rms := sqrt(sum / float(frames.size()))
	return clampf(maxf(rms * MIC_AUDIO_RMS_GAIN, peak * MIC_AUDIO_PEAK_GAIN), 0.0, 1.0)

static func signal_gate_hit_strength(hit_timer: float) -> float:
	return clampf(hit_timer / SIGNAL_GATE_HIT_DURATION, 0.0, 1.0)

func _hit_signal_gate() -> void:
	_signal_gate_hit_timer = SIGNAL_GATE_HIT_DURATION
	_spawn_ball_impact_burst(TunnelMath.surface_to_world(_ball_theta, _level_end_z, _play_radius), Color(0.14, 1.0, 0.96), 1.25)
	_start_camera_shake(0.035, 0.12)

func _break_signal_gate() -> void:
	_signal_gate_hit_timer = SIGNAL_GATE_HIT_DURATION
	_signal_gate_break_progress = 0.01
	_step_signal_gate_shards(_signal_gate_break_progress)
	_spawn_ball_impact_burst(TunnelMath.surface_to_world(_ball_theta, _level_end_z, _play_radius), Color(1.0, 0.28, 0.92), 1.7)

func _step_portal_motion(delta: float) -> void:
	if _portal_material == null and _portal_fractal_material == null:
		return
	var target_speed := portal_animation_speed_for_ball_velocity(_ball_v_z, _ball_v_theta)
	if _pending_transition and _transition_mode == "portal_breach":
		target_speed = PORTAL_MAX_ANIMATION_SPEED
	_portal_animation_speed = smoothed_portal_animation_speed(_portal_animation_speed, target_speed, delta)
	_portal_phase = fmod(_portal_phase + delta * _portal_animation_speed, 10000.0)
	if _portal_material != null:
		_portal_material.set_shader_parameter("gate_time", _portal_phase)
		_portal_material.set_shader_parameter("hit_strength", signal_gate_hit_strength(_signal_gate_hit_timer))
		_portal_material.set_shader_parameter("break_progress", _signal_gate_break_progress)
	if _portal_fractal_material != null:
		_portal_fractal_material.set_shader_parameter("portal_phase", _portal_phase)

func _step_tunnel_texture_motion(delta: float) -> void:
	if _tunnel_material == null:
		return
	var base_speed := tunnel_texture_speed_for_ball_velocity(_ball_v_z, _ball_v_theta)
	var target_speed := tunnel_texture_speed_for_audio_bpm(base_speed, _audio_bpm, _audio_bpm_confidence, _device_audio_pulse, _audio_beat_speed_kick)
	if _pending_transition and _transition_mode == "portal_breach":
		target_speed = TUNNEL_TEXTURE_MAX_SPEED
	_tunnel_texture_speed = smoothed_tunnel_texture_speed(_tunnel_texture_speed, target_speed, delta)
	_tunnel_texture_phase = fmod(_tunnel_texture_phase + delta * _tunnel_texture_speed, 10000.0)
	_tunnel_material.set_shader_parameter("tunnel_phase", _tunnel_texture_phase)

func _step_tunnel_layout_transition(delta: float) -> void:
	if _tunnel_layout_transition_time >= TUNNEL_LAYOUT_TRANSITION_DURATION:
		return
	_tunnel_layout_transition_time = minf(_tunnel_layout_transition_time + maxf(delta, 0.0), TUNNEL_LAYOUT_TRANSITION_DURATION)
	if _tunnel_layout_transition_time >= TUNNEL_LAYOUT_TRANSITION_DURATION:
		_current_tunnel_layout_id = _target_tunnel_layout_id
		_previous_tunnel_layout_id = _target_tunnel_layout_id

func _begin_tunnel_layout_for_level(level_index: int, immediate: bool = false) -> void:
	var next_layout := tunnel_layout_for_level(level_index, _level_data, _tunnel_layout_lineup)
	if immediate or _target_tunnel_layout_id == next_layout:
		_current_tunnel_layout_id = next_layout
		_previous_tunnel_layout_id = next_layout
		_target_tunnel_layout_id = next_layout
		_tunnel_layout_transition_time = TUNNEL_LAYOUT_TRANSITION_DURATION
		return
	_previous_tunnel_layout_id = _current_tunnel_layout_id
	_target_tunnel_layout_id = next_layout
	_tunnel_layout_transition_time = 0.0

func _resolve_tunnel_layout_lineup() -> PackedStringArray:
	var forced_layout := _query_or_environment_tunnel_value("tunnel_layout")
	if not forced_layout.is_empty() and is_tunnel_layout_id(forced_layout):
		return PackedStringArray([forced_layout.strip_edges().to_lower()])
	var lineup_text := _query_or_environment_tunnel_value("tunnel_lineup")
	var lineup := normalized_tunnel_layout_lineup(lineup_text)
	if lineup.is_empty():
		lineup = normalized_tunnel_layout_lineup(OS.get_environment(TUNNEL_LAYOUT_LINEUP_ENV))
	if lineup.is_empty():
		lineup = default_tunnel_layout_lineup()
	return lineup

func _resolve_portal_light_lineup() -> PackedStringArray:
	var forced_light := _query_or_environment_tunnel_value("portal_light")
	if not forced_light.is_empty() and is_portal_light_id(forced_light):
		return PackedStringArray([forced_light.strip_edges().to_lower()])
	var lineup_text := _query_or_environment_tunnel_value("portal_light_lineup")
	var lineup := normalized_portal_light_lineup(lineup_text)
	if lineup.is_empty():
		lineup = normalized_portal_light_lineup(OS.get_environment("WORM_BREAKER_PORTAL_LIGHT_LINEUP"))
	if lineup.is_empty():
		lineup = default_portal_light_lineup()
	return lineup

func _query_or_environment_tunnel_value(param_name: String) -> String:
	var env_name := "WORM_BREAKER_" + param_name.to_upper()
	var value := OS.get_environment(env_name).strip_edges()
	if not value.is_empty():
		return value
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return ""
	var js := "(new URLSearchParams(window.location.search).get('%s') || '')" % param_name
	return str(JavaScriptBridge.eval(js, true)).strip_edges()

func _begin_portal_light_for_level(level_index: int) -> void:
	_current_portal_light_id = portal_light_for_level(level_index, _level_data, _portal_light_lineup)
	_apply_portal_light_material()

func _apply_portal_light_material() -> void:
	if _portal_fractal_material == null:
		return
	var preset := _portal_light_preset(_current_portal_light_id)
	_portal_fractal_material.set_shader_parameter("portal_variant", int(preset.get("variant", 0)))
	_portal_fractal_material.set_shader_parameter("primary_color", preset.get("primary_color", Color(0.08, 1.0, 0.9, 1.0)))
	_portal_fractal_material.set_shader_parameter("secondary_color", preset.get("secondary_color", Color(1.0, 0.12, 0.82, 1.0)))
	_portal_fractal_material.set_shader_parameter("accent_color", preset.get("accent_color", Color(1.0, 0.92, 0.24, 1.0)))
	_portal_fractal_material.set_shader_parameter("ray_density", float(preset.get("ray_density", 14.0)))
	_portal_fractal_material.set_shader_parameter("ring_density", float(preset.get("ring_density", 9.0)))
	_portal_fractal_material.set_shader_parameter("wire_strength", float(preset.get("wire_strength", 0.45)))
	_portal_fractal_material.set_shader_parameter("grid_strength", float(preset.get("grid_strength", 0.32)))

func _portal_light_preset(light_id: String) -> Dictionary:
	var key := light_id.strip_edges().to_lower()
	if PORTAL_LIGHT_PRESETS.has(key):
		return PORTAL_LIGHT_PRESETS[key]
	return PORTAL_LIGHT_PRESETS[PORTAL_LIGHT_DEFAULT]

func _apply_tunnel_layout_material(intensity: float, time_seconds: float) -> void:
	if _tunnel_material == null:
		return
	var blend := tunnel_layout_transition_blend(_tunnel_layout_transition_time)
	var previous := _tunnel_layout_preset(_previous_tunnel_layout_id)
	var target := _tunnel_layout_preset(_target_tunnel_layout_id)
	var hue_origin := _layout_lerp_float(previous, target, "hue_origin", blend)
	var hue_motion := _layout_lerp_float(previous, target, "hue_motion", blend)
	var hue := fmod(hue_origin + sin(time_seconds * 0.17) * hue_motion, 1.0)
	var near_offset := _layout_lerp_float(previous, target, "near_offset", blend)
	var far_offset := _layout_lerp_float(previous, target, "far_offset", blend)
	_tunnel_material.set_shader_parameter("hue_shift", hue)
	_tunnel_material.set_shader_parameter("intensity", intensity)
	_tunnel_material.set_shader_parameter("base_color", _layout_lerp_color(previous, target, "base_color", blend))
	_tunnel_material.set_shader_parameter("near_color", Color.from_hsv(fmod(hue + near_offset, 1.0), _layout_lerp_float(previous, target, "near_saturation", blend), 1.0))
	_tunnel_material.set_shader_parameter("far_color", Color.from_hsv(fmod(hue + far_offset, 1.0), _layout_lerp_float(previous, target, "far_saturation", blend), 1.0))
	_tunnel_material.set_shader_parameter("projectm_overlay_strength", _layout_lerp_float(previous, target, "projectm_overlay_strength", blend))
	_tunnel_material.set_shader_parameter("layout_depth_scale", _layout_lerp_float(previous, target, "depth_scale", blend))
	_tunnel_material.set_shader_parameter("layout_angle_repeats", _layout_lerp_float(previous, target, "angle_repeats", blend))
	_tunnel_material.set_shader_parameter("layout_spoke_repeats", _layout_lerp_float(previous, target, "spoke_repeats", blend))
	_tunnel_material.set_shader_parameter("layout_kaleido_segments", _layout_lerp_float(previous, target, "kaleido_segments", blend))
	_tunnel_material.set_shader_parameter("layout_circuit_density", _layout_lerp_float(previous, target, "circuit_density", blend))
	_tunnel_material.set_shader_parameter("layout_ring_frequency", _layout_lerp_float(previous, target, "ring_frequency", blend))

func _tunnel_layout_preset(layout_id: String) -> Dictionary:
	var key := layout_id.strip_edges().to_lower()
	if TUNNEL_LAYOUT_PRESETS.has(key):
		return TUNNEL_LAYOUT_PRESETS[key]
	return TUNNEL_LAYOUT_PRESETS[TUNNEL_LAYOUT_DEFAULT]

func _layout_lerp_float(previous: Dictionary, target: Dictionary, key: String, blend: float) -> float:
	return lerpf(float(previous.get(key, target.get(key, 0.0))), float(target.get(key, previous.get(key, 0.0))), blend)

func _layout_lerp_color(previous: Dictionary, target: Dictionary, key: String, blend: float) -> Color:
	var from_color := previous.get(key, target.get(key, Color.WHITE)) as Color
	var to_color := target.get(key, previous.get(key, Color.WHITE)) as Color
	return from_color.lerp(to_color, blend)

func _step_audio_bpm(delta: float, previous_pulse: float, previous_energy: float) -> void:
	_audio_beat_time += maxf(delta, 0.0)
	var has_onset := _device_audio_available and audio_beat_onset(_device_audio_pulse, previous_pulse, _device_audio_energy, previous_energy)
	var valid_interval := false
	if has_onset:
		if _audio_last_beat_time >= 0.0:
			var interval := _audio_beat_time - _audio_last_beat_time
			var interval_bpm := audio_bpm_from_beat_interval(interval)
			if interval_bpm > 0.0:
				_audio_bpm_samples = audio_bpm_samples_after_interval(_audio_bpm_samples, interval_bpm, _audio_bpm)
				var recent_bpm := audio_bpm_from_recent_samples(_audio_bpm_samples)
				_audio_bpm = smoothed_audio_bpm(_audio_bpm, recent_bpm)
				valid_interval = true
		_audio_last_beat_time = _audio_beat_time
	var timed_out := _audio_last_beat_time < 0.0 or (_audio_beat_time - _audio_last_beat_time) > AUDIO_BPM_TIMEOUT
	_audio_bpm_confidence = audio_bpm_confidence_after_step(_audio_bpm_confidence, valid_interval, timed_out, delta, has_onset)
	_audio_beat_speed_kick = audio_beat_speed_kick_after_step(_audio_beat_speed_kick, has_onset, delta)

func _setup_device_audio_analyzer() -> void:
	if OS.get_environment(DEVICE_AUDIO_DISABLE_ENV) == "1":
		return
	if OS.get_name() == "Android":
		_setup_android_system_audio_capture()
		return
	if OS.has_feature("web"):
		_setup_web_system_audio_capture()
		return
	if OS.get_name() != "Windows":
		_setup_game_audio_spectrum_fallback()
		return
	if not ClassDB.class_exists(DEVICE_AUDIO_ANALYZER_CLASS):
		return
	var analyzer := ClassDB.instantiate(DEVICE_AUDIO_ANALYZER_CLASS) as RefCounted
	if analyzer == null:
		return
	_device_audio_analyzer = analyzer
	if _device_audio_analyzer.has_method("start"):
		_device_audio_analyzer.call("start")
	_device_audio_source_label = DEVICE_AUDIO_SOURCE_SYSTEM

func _setup_web_system_audio_capture() -> void:
	_device_audio_source_label = DEVICE_AUDIO_SOURCE_WEB
	var analyzer := get_node_or_null("/root/WebAudioCapture")
	if analyzer == null or not analyzer.has_method("is_supported") or not bool(analyzer.call("is_supported")):
		_setup_game_audio_spectrum_fallback()
		return
	_device_audio_analyzer = analyzer
	if _web_audio_connect_button != null:
		_web_audio_connect_button.visible = true

func _start_web_system_audio_capture() -> void:
	if not OS.has_feature("web"):
		return
	if _device_audio_analyzer == null:
		_setup_web_system_audio_capture()
	if _device_audio_analyzer != null and _analyzer_has_method(_device_audio_analyzer, "start"):
		_device_audio_source_label = DEVICE_AUDIO_SOURCE_WEB
		_device_audio_analyzer.call("start")

func _setup_android_system_audio_capture() -> void:
	_device_audio_source_label = DEVICE_AUDIO_SOURCE_SYSTEM
	_android_system_audio_wait_time = 0.0
	if not Engine.has_singleton(ANDROID_SYSTEM_AUDIO_SINGLETON):
		print("Android system audio singleton unavailable; using microphone fallback")
		_setup_mic_audio_fallback()
		return
	var analyzer := Engine.get_singleton(ANDROID_SYSTEM_AUDIO_SINGLETON)
	if analyzer == null:
		print("Android system audio singleton returned null; using microphone fallback")
		_setup_mic_audio_fallback()
		return
	_device_audio_analyzer = analyzer
	if _analyzer_has_method(_device_audio_analyzer, "request_capture"):
		print("Requesting Android system audio capture")
		_device_audio_analyzer.call("request_capture")

func _setup_mic_audio_fallback() -> void:
	if _mic_audio_capture_instance != null:
		return
	_device_audio_source_label = DEVICE_AUDIO_SOURCE_MIC
	if OS.has_method("request_permissions"):
		OS.request_permissions()
	var bus_index := AudioServer.get_bus_index(MIC_AUDIO_CAPTURE_BUS)
	if bus_index < 0:
		bus_index = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, MIC_AUDIO_CAPTURE_BUS)
	AudioServer.set_bus_volume_db(bus_index, 0.0)
	var effect := AudioEffectCapture.new()
	effect.resource_name = "WormBreakerMicAudioPulse"
	effect.buffer_length = 0.25
	_mic_audio_capture_effect_index = AudioServer.get_bus_effect_count(bus_index)
	AudioServer.add_bus_effect(bus_index, effect, _mic_audio_capture_effect_index)
	_mic_audio_capture_instance = AudioServer.get_bus_effect(bus_index, _mic_audio_capture_effect_index) as AudioEffectCapture
	var mute_effect := AudioEffectAmplify.new()
	mute_effect.resource_name = "WormBreakerMicAudioMute"
	mute_effect.volume_db = -80.0
	_mic_audio_mute_effect_index = AudioServer.get_bus_effect_count(bus_index)
	AudioServer.add_bus_effect(bus_index, mute_effect, _mic_audio_mute_effect_index)
	_mic_audio_player = AudioStreamPlayer.new()
	_mic_audio_player.name = "MicAudioPulseInput"
	_mic_audio_player.stream = AudioStreamMicrophone.new()
	_mic_audio_player.bus = MIC_AUDIO_CAPTURE_BUS
	_mic_audio_player.volume_db = 0.0
	add_child(_mic_audio_player)
	_mic_audio_player.play()

func _teardown_mic_audio_fallback() -> void:
	if _mic_audio_player != null and is_instance_valid(_mic_audio_player):
		_mic_audio_player.stop()
		_mic_audio_player.queue_free()
	_mic_audio_player = null
	if _mic_audio_capture_effect_index < 0 and _mic_audio_mute_effect_index < 0:
		_mic_audio_capture_instance = null
		return
	var bus_index := AudioServer.get_bus_index(MIC_AUDIO_CAPTURE_BUS)
	if bus_index >= 0:
		for effect_index in [_mic_audio_mute_effect_index, _mic_audio_capture_effect_index]:
			if effect_index >= 0 and effect_index < AudioServer.get_bus_effect_count(bus_index):
				AudioServer.remove_bus_effect(bus_index, effect_index)
	_mic_audio_capture_effect_index = -1
	_mic_audio_mute_effect_index = -1
	_mic_audio_capture_instance = null

func _setup_game_audio_spectrum_fallback() -> void:
	if _game_audio_spectrum_instance != null:
		return
	_device_audio_source_label = DEVICE_AUDIO_SOURCE_GAME
	var bus_index := AudioServer.get_bus_index(GAME_AUDIO_SPECTRUM_BUS)
	if bus_index < 0:
		return
	var effect := AudioEffectSpectrumAnalyzer.new()
	effect.resource_name = "WormBreakerGameAudioPulse"
	effect.buffer_length = 0.25
	_game_audio_spectrum_effect_index = AudioServer.get_bus_effect_count(bus_index)
	AudioServer.add_bus_effect(bus_index, effect, _game_audio_spectrum_effect_index)
	_game_audio_spectrum_instance = AudioServer.get_bus_effect_instance(bus_index, _game_audio_spectrum_effect_index) as AudioEffectSpectrumAnalyzerInstance

func _teardown_game_audio_spectrum_fallback() -> void:
	if _game_audio_spectrum_effect_index < 0:
		return
	var bus_index := AudioServer.get_bus_index(GAME_AUDIO_SPECTRUM_BUS)
	if bus_index >= 0 and _game_audio_spectrum_effect_index < AudioServer.get_bus_effect_count(bus_index):
		AudioServer.remove_bus_effect(bus_index, _game_audio_spectrum_effect_index)
	_game_audio_spectrum_effect_index = -1
	_game_audio_spectrum_instance = null

func _step_device_audio_pulse(delta: float) -> void:
	var previous_pulse := _device_audio_pulse
	var previous_energy := _device_audio_energy
	var next_state := {}
	var analyzer_state_available := false
	if _device_audio_analyzer != null:
		next_state = device_audio_pulse_for_analyzer(_device_audio_analyzer, _device_audio_pulse, _device_audio_energy, delta)
		analyzer_state_available = bool(next_state.get("available", false))
		if not analyzer_state_available and OS.get_name() == "Android":
			var permission_pending := false
			if _analyzer_has_method(_device_audio_analyzer, "is_permission_pending"):
				permission_pending = bool(_device_audio_analyzer.call("is_permission_pending"))
			if not permission_pending:
				_android_system_audio_wait_time += delta
			if _android_system_audio_wait_time >= ANDROID_SYSTEM_AUDIO_FALLBACK_DELAY:
				if _analyzer_has_method(_device_audio_analyzer, "stop"):
					_device_audio_analyzer.call("stop")
				_device_audio_analyzer = null
				_setup_mic_audio_fallback()
				next_state = _mic_audio_pulse_state(delta)
		elif not analyzer_state_available and OS.has_feature("web"):
			_setup_game_audio_spectrum_fallback()
			if _game_audio_spectrum_instance != null:
				var magnitude := _game_audio_spectrum_instance.get_magnitude_for_frequency_range(
					GAME_AUDIO_SPECTRUM_MIN_HZ,
					GAME_AUDIO_SPECTRUM_MAX_HZ,
					AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
				)
				var energy := game_audio_energy_from_magnitude(magnitude)
				var target_pulse := device_audio_pulse_target(energy, _device_audio_energy)
				next_state = {
					"available": true,
					"energy": energy,
					"pulse": smoothed_device_audio_pulse(_device_audio_pulse, target_pulse, delta)
				}
				next_state.merge(_game_audio_band_state(), true)
	elif _mic_audio_capture_instance != null:
		next_state = _mic_audio_pulse_state(delta)
	elif _game_audio_spectrum_instance != null:
		var magnitude := _game_audio_spectrum_instance.get_magnitude_for_frequency_range(
			GAME_AUDIO_SPECTRUM_MIN_HZ,
			GAME_AUDIO_SPECTRUM_MAX_HZ,
			AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
		)
		var energy := game_audio_energy_from_magnitude(magnitude)
		var target_pulse := device_audio_pulse_target(energy, _device_audio_energy)
		next_state = {
			"available": true,
			"energy": energy,
			"pulse": smoothed_device_audio_pulse(_device_audio_pulse, target_pulse, delta)
		}
		next_state.merge(_game_audio_band_state(), true)
	else:
		next_state = device_audio_pulse_for_analyzer(null, _device_audio_pulse, _device_audio_energy, delta)
	_device_audio_available = bool(next_state.get("available", false))
	_device_audio_energy = float(next_state.get("energy", 0.0))
	_device_audio_pulse = float(next_state.get("pulse", 0.0))
	_device_audio_bass = float(next_state.get("bass", 0.0))
	_device_audio_mid = float(next_state.get("mid", 0.0))
	_device_audio_treble = float(next_state.get("treble", 0.0))
	if OS.has_feature("web") and _device_audio_analyzer != null and analyzer_state_available:
		_device_audio_source_label = DEVICE_AUDIO_SOURCE_WEB
	_step_audio_bpm(delta, previous_pulse, previous_energy)
	if _tunnel_material != null:
		_tunnel_material.set_shader_parameter("device_audio_pulse", _device_audio_pulse)
		_tunnel_material.set_shader_parameter("audio_bass", _device_audio_bass)
		_tunnel_material.set_shader_parameter("audio_mid", _device_audio_mid)
		_tunnel_material.set_shader_parameter("audio_treble", _device_audio_treble)

func _game_audio_band_state() -> Dictionary:
	if _game_audio_spectrum_instance == null:
		return device_audio_band_state(0.0, 0.0, 0.0)
	var bass_magnitude := _game_audio_spectrum_instance.get_magnitude_for_frequency_range(40.0, 180.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
	var mid_magnitude := _game_audio_spectrum_instance.get_magnitude_for_frequency_range(180.0, 2200.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
	var treble_magnitude := _game_audio_spectrum_instance.get_magnitude_for_frequency_range(2200.0, 9000.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
	return device_audio_band_state(
		game_audio_energy_from_magnitude(bass_magnitude) * 1.4,
		game_audio_energy_from_magnitude(mid_magnitude) * 1.15,
		game_audio_energy_from_magnitude(treble_magnitude) * 1.35
	)

func _mic_audio_pulse_state(delta: float) -> Dictionary:
	if _mic_audio_capture_instance == null:
		return device_audio_pulse_for_analyzer(null, _device_audio_pulse, _device_audio_energy, delta)
	var available_frames := _mic_audio_capture_instance.get_frames_available()
	if available_frames <= 0:
		return {
			"available": true,
			"energy": 0.0,
			"pulse": smoothed_device_audio_pulse(_device_audio_pulse, 0.0, delta),
			"bass": 0.0,
			"mid": 0.0,
			"treble": 0.0
		}
	var frames := _mic_audio_capture_instance.get_buffer(mini(available_frames, 2048))
	var energy := mic_audio_energy_from_frames(frames)
	var target_pulse := clampf(device_audio_pulse_target(energy, _device_audio_energy) * MIC_AUDIO_PULSE_BOOST, 0.0, DEVICE_AUDIO_PULSE_MAX)
	return {
		"available": true,
		"energy": energy,
		"pulse": smoothed_device_audio_pulse(_device_audio_pulse, target_pulse, delta),
		"bass": clampf(energy * 1.2, 0.0, 1.0),
		"mid": clampf(energy * 0.85, 0.0, 1.0),
		"treble": clampf(energy * 0.55, 0.0, 1.0)
	}

func _build_device_audio_debug_label() -> void:
	_device_audio_debug_label = Label.new()
	_device_audio_debug_label.name = "DeviceAudioDebugLabel"
	_device_audio_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_device_audio_debug_label.text = device_audio_debug_text(false, 0.0, 0.0, _device_audio_source_label)
	_device_audio_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_device_audio_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_device_audio_debug_label.add_theme_font_size_override("font_size", 20)
	_device_audio_debug_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.82, 0.94))
	_device_audio_debug_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	_device_audio_debug_label.add_theme_constant_override("shadow_offset_x", 2)
	_device_audio_debug_label.add_theme_constant_override("shadow_offset_y", 2)
	$HUD.add_child(_device_audio_debug_label)
	_layout_device_audio_debug_label()

func _build_web_audio_connect_button() -> void:
	if not OS.has_feature("web"):
		return
	_web_audio_connect_button = Button.new()
	_web_audio_connect_button.name = "WebAudioConnectButton"
	_web_audio_connect_button.text = "CONNECT AUDIO"
	_web_audio_connect_button.visible = false
	_web_audio_connect_button.focus_mode = Control.FOCUS_NONE
	_web_audio_connect_button.add_theme_font_size_override("font_size", 16)
	_apply_tutorial_button_style(_web_audio_connect_button)
	_web_audio_connect_button.pressed.connect(_start_web_system_audio_capture)
	$HUD.add_child(_web_audio_connect_button)
	_layout_web_audio_connect_button()

func _apply_control_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y

func _apply_tutorial_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.96, 0.82, 0.96)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 1.0, 1.0, 0.42)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.86, 0.16, 0.96)
	button.add_theme_color_override("font_color", Color(0.02, 0.08, 0.12, 1.0))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)

func _show_tutorial_pause(title: String, body: String, focus: String, pause_kind: String) -> void:
	if not _tutorial_enabled:
		return
	_tutorial_pause_active = true
	_tutorial_pause_kind = pause_kind
	_tutorial_focus = focus
	_message_serial += 1
	if message_label != null:
		message_label.visible = false
	if _tutorial_overlay != null:
		_tutorial_title_label.text = title.to_upper()
		_tutorial_body_label.text = body
		_tutorial_disable_check.button_pressed = false
		_tutorial_continue_button.text = "MOVE STABILIZER" if pause_kind == "input" else "CONTINUE"
		_tutorial_overlay.visible = true
		_layout_tutorial_overlay()

func _step_tutorial_pause(_delta: float) -> void:
	if _tutorial_pause_kind != "input":
		return
	var angular_velocity: float = 0.0
	if rot_input != null and rot_input.has_method("get_angular_velocity"):
		angular_velocity = float(rot_input.get_angular_velocity())
	if absf(angular_velocity) > 0.08:
		_tutorial_rotate_seen = true
		_paddle_theta = TunnelMath.wrap_angle(_paddle_theta + angular_velocity * 0.016)
		_dismiss_tutorial_pause()

func _on_tutorial_continue_pressed() -> void:
	if _tutorial_pause_kind == "input":
		_tutorial_rotate_seen = true
	_dismiss_tutorial_pause()

func _dismiss_tutorial_pause() -> void:
	if _tutorial_disable_check != null and _tutorial_disable_check.button_pressed:
		SaveStore.set_tutorial_prompts_disabled(true)
		RunManager.tutorial_requested = false
		_tutorial_enabled = false
	_tutorial_pause_active = false
	_tutorial_pause_kind = ""
	_tutorial_focus = ""
	if _tutorial_overlay != null:
		_tutorial_overlay.visible = false

func _build_fractal_overlay() -> void:
	if FRACTAL_SHADERS.is_empty():
		return
	_fractal_overlay = ColorRect.new()
	_fractal_overlay.name = "FractalPlayfieldOverlay"
	_fractal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fractal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fractal_overlay.color = Color(0.018, 0.0, 0.055, 0.18)
	_fractal_overlay_material = ShaderMaterial.new()
	_fractal_overlay_material.shader = FRACTAL_SHADERS[0]
	_fractal_overlay_material.set_shader_parameter("alpha", 0.045)
	_fractal_overlay_material.set_shader_parameter("speed", 0.32)
	_fractal_overlay.material = _fractal_overlay_material
	_fractal_layer = CanvasLayer.new()
	_fractal_layer.name = "FractalBackgroundLayer"
	_fractal_layer.layer = -10
	add_child(_fractal_layer)
	_fractal_layer.add_child(_fractal_overlay)

func _update_fractal_overlay() -> void:
	if _fractal_overlay_material == null or FRACTAL_SHADERS.is_empty():
		return
	var next_index := int(floor(_visual_time / 8.0)) % FRACTAL_SHADERS.size()
	if next_index != _fractal_shader_index:
		_fractal_shader_index = next_index
		_fractal_overlay_material.shader = FRACTAL_SHADERS[_fractal_shader_index]
		_fractal_overlay_material.set_shader_parameter("alpha", 0.045)
		_fractal_overlay_material.set_shader_parameter("speed", 0.32)
		if _fractal_shader_index == 3:
			_fractal_overlay_material.set_shader_parameter("zoom", 2.8)
			_fractal_overlay_material.set_shader_parameter("recursion_limit", 72)
		elif _fractal_shader_index == 4:
			_fractal_overlay_material.set_shader_parameter("zoom", 1.2)
			_fractal_overlay_material.set_shader_parameter("recursion_limit", 72)
		else:
			_fractal_overlay_material.set_shader_parameter("zoom", 1.0)

func _start_camera_shake(amount: float, duration: float) -> void:
	_shake_amount = max(_shake_amount, amount)
	_shake_duration = max(duration, 0.01)
	_shake_time = max(_shake_time, duration)

func _flash_paddle() -> void:
	_paddle_flash_timer = PADDLE_FLASH_DURATION

func _apply_camera_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return

	_shake_time = max(_shake_time - delta, 0.0)
	var fade: float = _shake_time / _shake_duration
	var current_amount: float = _shake_amount * fade
	camera.h_offset = randf_range(-current_amount, current_amount)
	camera.v_offset = randf_range(-current_amount, current_amount)

func _complete_level() -> void:
	if _pending_transition:
		return
	_pending_transition = true
	_transition_mode = "portal_breach"
	_transition_time = 0.0
	_break_signal_gate()
	_clear_powerups()
	_show_message("SIGNAL GATE BREACH", 0.0)
	_start_camera_shake(0.12, PORTAL_BREACH_DURATION)
	_pulse_haptic(68, 0.9)
	SaveStore.record_level(_level_index + 1)
	await get_tree().create_timer(PORTAL_BREACH_DURATION).timeout

	if LevelLoader.has_level(_level_index + 1):
		RunManager.current_level_index = _level_index + 1
		_load_level(_level_index + 1)
	else:
		RunManager.go_to_results(true, _level_index, RunManager.run_score)

func _lose_run() -> void:
	if _pending_transition:
		return
	_pending_transition = true
	_transition_mode = "lost"
	_transition_time = 0.0
	_show_message("SIGNAL LOST", 0.9)
	_start_camera_shake(0.09, 0.38)
	await get_tree().create_timer(0.9).timeout
	RunManager.go_to_results(false, _level_index, RunManager.run_score)

func _step_transition(delta: float) -> void:
	_transition_time += delta
	if _transition_mode == "portal_breach":
		var t := clampf(_transition_time / PORTAL_BREACH_DURATION, 0.0, 1.0)
		_ball_z = lerpf(_ball_z, _level_end_z + 5.0, clampf(delta * (5.5 + t * 8.0), 0.0, 1.0))
		_ball_theta = TunnelMath.wrap_angle(_ball_theta + delta * (1.6 + t * 5.0))
		if _portal_material != null:
			_signal_gate_break_progress = t
			_portal_material.set_shader_parameter("alpha", lerpf(0.36, 0.06, t))
			_portal_material.set_shader_parameter("break_progress", _signal_gate_break_progress)
			_step_signal_gate_shards(_signal_gate_break_progress)
		if _portal_fractal_material != null:
			_portal_fractal_material.set_shader_parameter("alpha", lerpf(0.70, 1.0, t))
			_portal_fractal_material.set_shader_parameter("zoom", lerpf(2.45, 1.3, t))
			_portal_fractal_material.set_shader_parameter("drift", lerpf(0.5, 1.15, t))
		if _fractal_overlay_material != null:
			_fractal_overlay_material.set_shader_parameter("alpha", lerpf(0.045, 0.16, t))
	elif _transition_mode == "lost":
		_ball_v_z = 0.0

func _show_message(text: String, hide_after: float) -> void:
	_message_serial += 1
	var serial := _message_serial
	message_label.text = text
	message_label.visible = true
	if hide_after > 0.0:
		var local_hide_after: float = hide_after
		_hide_message_deferred(local_hide_after, serial)

func _hide_message_deferred(delay: float, serial: int) -> void:
	await get_tree().create_timer(delay).timeout
	if not _pending_transition and serial == _message_serial:
		message_label.visible = false

func _update_hud() -> void:
	score_label.text = hud_signal_text(RunManager.run_score)
	level_label.text = hud_depth_text(_level_index, LevelLoader.level_count())
	objective_label.text = hud_pressure_text(RunManager.run_score, _rival_target)
	var power_status := _powerup_status_text()
	style_label.text = "%s%s%s" % [
		"MODE OVERDRIVE" if _run_style == STYLE_OVERDRIVE else "MODE STABILITY",
		"  (assist active)" if SaveStore.fail_streak >= 2 else "",
		"  /  " + power_status if not power_status.is_empty() else ""
	]
	var remaining: int = _bricks.size()
	var destroyed: int = max(_initial_brick_count - remaining, 0)
	var progress_ratio: float = 0.0 if _initial_brick_count <= 0 else float(destroyed) / float(_initial_brick_count)
	var phase: String = "TUNNEL WARMUP"
	if progress_ratio >= 0.75:
		phase = "FINAL SPIRAL"
	elif progress_ratio >= 0.35:
		phase = "PRESSURE PEAK"
	phase_label.text = "%s  %d/%d" % [phase, destroyed, _initial_brick_count]
	combo_label.text = hud_pulse_text(_chain_combo)
	if _device_audio_debug_label != null:
		_device_audio_debug_label.text = device_audio_debug_text(_device_audio_available, _device_audio_energy, _device_audio_pulse, _device_audio_source_label, _audio_bpm, _audio_bpm_confidence, _tunnel_texture_speed, _device_audio_bass, _device_audio_mid, _device_audio_treble)
	if _web_audio_connect_button != null:
		var web_status := ""
		if _device_audio_analyzer != null and _analyzer_has_method(_device_audio_analyzer, "get_status"):
			web_status = str(_device_audio_analyzer.call("get_status"))
		_web_audio_connect_button.visible = OS.has_feature("web") and not (_device_audio_source_label == DEVICE_AUDIO_SOURCE_WEB and _device_audio_available)
		_web_audio_connect_button.disabled = web_status == "starting"
		_web_audio_connect_button.text = "CONNECTING..." if web_status == "starting" else "CONNECT AUDIO"

func _powerup_status_text() -> String:
	var parts: Array[String] = []
	if _wide_timer > 0.0:
		parts.append("WIDE MODULE %.0fs" % ceilf(_wide_timer))
	if _slow_timer > 0.0:
		parts.append("SLOW MODULE %.0fs" % ceilf(_slow_timer))
	return "  ".join(parts)

static func hud_signal_text(score: int) -> String:
	return "SIGNAL CHARGE %d" % max(score, 0)

static func hud_depth_text(level_index: int, level_count: int) -> String:
	return "TUNNEL DEPTH %d/%d" % [max(level_index, 1), max(level_count, 1)]

static func hud_pressure_text(score: int, rival_target: int) -> String:
	var safe_target: int = maxi(rival_target, 1)
	var percent: int = int(round(clampf(float(max(score, 0)) / float(safe_target), 0.0, 1.0) * 100.0))
	return "RIVAL PRESSURE %d%%  /  %d" % [percent, safe_target]

static func hud_pulse_text(chain_combo: int) -> String:
	return "PULSE x%d" % max(chain_combo, 0)

static func powerup_tutorial_text(power_type: String) -> String:
	match power_type:
		POWERUP_WIDE:
			return "Wide modules stretch the stabilizer, giving you more room to catch the pulse for a few seconds."
		POWERUP_SLOW:
			return "Slow modules calm the pulse, reducing tunnel speed so you can recover under pressure."
		POWERUP_BLAST:
			return "Prism blast modules shatter nearby signal fragments and push your charge upward."
		_:
			return "Signal modules change the run temporarily. Catch them with the stabilizer before they drift away."

static func powerup_display_name(power_type: String) -> String:
	match power_type:
		POWERUP_WIDE:
			return "Wide"
		POWERUP_SLOW:
			return "Slow"
		POWERUP_BLAST:
			return "Prism Blast"
		_:
			return power_type.capitalize()
