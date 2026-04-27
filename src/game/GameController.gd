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
const MANDELBROT_PORTAL_SHADER: Shader = preload("res://src/shaders/fractals/mandelbrot_portal.gdshader")
const TUNNEL_FRACTAL_SHADER: Shader = preload("res://src/shaders/fractals/tunnel_fractal_wrap.gdshader")
const TUNNEL_FORWARD: Vector3 = Vector3(0.0, 0.0, 1.0)
const BALL_THETA_RADIUS: float = 0.12
const BALL_Z_RADIUS: float = 0.34
const BALL_WORLD_RADIUS: float = 0.18
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
const PADDLE_FLASH_DURATION: float = 0.18
const HUD_DOCK_SAFE_MARGIN: float = 24.0
const HUD_DOCK_MIN_WIDTH: float = 292.0
const HUD_DOCK_MAX_WIDTH: float = 380.0
const HUD_DOCK_HEIGHT: float = 166.0
const HUD_MESSAGE_HEIGHT: float = 62.0
const PORTAL_BASE_ANIMATION_SPEED: float = 0.46
const PORTAL_MAX_ANIMATION_SPEED: float = 1.85
const PORTAL_SPEED_ACCELERATION: float = 0.85
const TUNNEL_TEXTURE_BASE_SPEED: float = 0.62
const TUNNEL_TEXTURE_MAX_SPEED: float = 2.6
const TUNNEL_TEXTURE_SPEED_ACCELERATION: float = 1.1
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
var _ball_material: StandardMaterial3D
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
var _portal_phase: float = 0.0
var _portal_animation_speed: float = PORTAL_BASE_ANIMATION_SPEED
var _fractal_layer: CanvasLayer
var _fractal_overlay: ColorRect
var _fractal_overlay_material: ShaderMaterial
var _fractal_shader_index := 0
var _tutorial_enabled: bool = false
var _tutorial_rotate_seen: bool = false
var _tutorial_catch_seen: bool = false
var _tutorial_fragment_seen: bool = false
var _tutorial_powerup_seen: bool = false
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
	_build_tunnel_end_portal()
	_build_paddle_segments()
	_load_level(max(1, RunManager.current_level_index))
	_update_hud()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout_hud()

func _physics_process(delta: float) -> void:
	_visual_time += delta
	_haptic_cooldown = maxf(_haptic_cooldown - delta, 0.0)
	_step_portal_motion(delta)
	_step_tunnel_texture_motion(delta)
	_update_psychedelic_materials()
	_update_fractal_overlay()
	_update_impact_particles(delta)
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
	if _tutorial_enabled and not _tutorial_rotate_seen and absf(angular_velocity) > 0.08:
		_tutorial_rotate_seen = true
		_show_message("ROTATE THE STABILIZER", 1.15)
	_paddle_theta = TunnelMath.wrap_angle(_paddle_theta + angular_velocity * delta)

func _step_ball(delta: float) -> void:
	var prev_z: float = _ball_z

	_ball_theta = TunnelMath.wrap_angle(_ball_theta + _ball_v_theta * delta)
	_ball_z += _ball_v_z * delta

	if _ball_z > _level_end_z:
		_ball_z = _level_end_z
		_ball_v_z = -absf(_ball_v_z)
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
				_show_message("CATCH THE PULSE", 1.15)
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
			_show_message("BREAK SIGNAL FRAGMENTS", 1.2)

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
	_tutorial_enabled = _level_index == 1
	_tutorial_rotate_seen = false
	_tutorial_catch_seen = false
	_tutorial_fragment_seen = false
	_tutorial_powerup_seen = false

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

	_refresh_tunnel_visual()
	_spawn_bricks()
	_clear_powerups()
	_update_ball_visual()
	_reset_ball_tracers()
	_update_paddle_visual()
	_update_camera(0.0, true)
	if _tutorial_enabled:
		_show_message("ROTATE THE STABILIZER", 1.4)
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
	tunnel_material.set_shader_parameter("base_color", Color(0.018, 0.0, 0.055, 1.0))
	tunnel_material.set_shader_parameter("near_color", Color(0.0, 0.9, 0.95, 1.0))
	tunnel_material.set_shader_parameter("far_color", Color(1.0, 0.1, 0.95, 1.0))
	tunnel.material_override = tunnel_material
	_tunnel_material = tunnel_material
	_position_tunnel_end_portal()

func _build_tunnel_end_portal() -> void:
	_portal_cap = MeshInstance3D.new()
	_portal_cap.name = "MandelbrotTunnelEnd"
	_portal_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portal_material = ShaderMaterial.new()
	_portal_material.shader = MANDELBROT_PORTAL_SHADER
	_portal_material.set_shader_parameter("alpha", 0.58)
	_portal_material.set_shader_parameter("zoom", 2.55)
	_portal_material.set_shader_parameter("drift", 0.45)
	_portal_animation_speed = portal_animation_speed_for_ball_velocity(_ball_v_z, _ball_v_theta)
	_portal_material.set_shader_parameter("portal_phase", _portal_phase)
	_portal_material.set_shader_parameter("recursion_limit", 108)
	_portal_cap.material_override = _portal_material
	$World.add_child(_portal_cap)
	_position_tunnel_end_portal()

func _position_tunnel_end_portal() -> void:
	if _portal_cap == null:
		return
	var portal_radius: float = _play_radius + PADDLE_SURFACE_INSET + 0.12
	_portal_cap.mesh = _build_disc_mesh(portal_radius, 96)
	_portal_cap.position = Vector3(0.0, 0.0, _level_end_z + 5.2)
	_portal_cap.rotation = Vector3.ZERO

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

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.94, 1.0, 0.32)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.86)
	mat.emission_energy_multiplier = 1.8
	mat.roughness = 0.16
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
	if _tutorial_enabled and not _tutorial_powerup_seen:
		_tutorial_powerup_seen = true
		_show_message("POWER MODULES DRIFT TO THE STABILIZER", 1.25)
	else:
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
		var hue := fmod(0.76 + sin(_visual_time * 0.17) * 0.08, 1.0)
		var pulse := 0.5 + 0.5 * sin(_visual_time * 0.9)
		_tunnel_material.set_shader_parameter("hue_shift", hue)
		_tunnel_material.set_shader_parameter("intensity", 0.78 + pulse * 0.26)
		_tunnel_material.set_shader_parameter("near_color", Color.from_hsv(fmod(hue + 0.48, 1.0), 0.74, 1.0))
		_tunnel_material.set_shader_parameter("far_color", Color.from_hsv(fmod(hue + 0.12, 1.0), 0.92, 1.0))
	if _ball_material != null:
		var ball_hue := fmod(0.13 + _visual_time * 0.07, 1.0)
		_ball_material.albedo_color = Color.from_hsv(ball_hue, 0.68, 1.0)
		_ball_material.emission = Color.from_hsv(fmod(ball_hue + 0.38, 1.0), 0.95, 1.0)
		_ball_material.emission_energy_multiplier = 1.6 + 0.55 * absf(sin(_visual_time * 4.2))
	for i in range(_paddle_materials.size()):
		var material := _paddle_materials[i]
		var hue := fmod(0.42 + _visual_time * 0.045 + float(i) * 0.035, 1.0)
		if _paddle_flash_timer > 0.0:
			hue = fmod(0.13 + _visual_time * 0.18, 1.0)
		material.albedo_color = Color.from_hsv(hue, 0.72, 1.0)
		material.emission = Color.from_hsv(hue, 0.96, 1.0)
		var flash_boost := 1.45 * (_paddle_flash_timer / PADDLE_FLASH_DURATION) if _paddle_flash_timer > 0.0 else 0.0
		material.emission_energy_multiplier = 0.65 + 0.28 * absf(sin(_visual_time * 2.4 + float(i))) + flash_boost
	if _portal_material != null and not _pending_transition:
		var portal_pulse := 0.5 + 0.5 * sin(_visual_time * 1.1)
		_portal_material.set_shader_parameter("alpha", 0.50 + portal_pulse * 0.12)
		_portal_material.set_shader_parameter("zoom", 2.55 + portal_pulse * 0.2)
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
			hud_vbox.add_theme_constant_override("separation", 2)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.012, 0.0, 0.045, 0.80)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(0.0, 1.0, 0.9, 0.58)
		panel_style.corner_radius_top_left = 18
		panel_style.corner_radius_top_right = 18
		panel_style.corner_radius_bottom_right = 18
		panel_style.corner_radius_bottom_left = 18
		panel_style.shadow_size = 18
		panel_style.shadow_color = Color(0.75, 0.0, 1.0, 0.22)
		panel_style.content_margin_left = 12.0
		panel_style.content_margin_top = 8.0
		panel_style.content_margin_right = 12.0
		panel_style.content_margin_bottom = 8.0
		hud_panel.add_theme_stylebox_override("panel", panel_style)
	for label in [score_label, level_label, objective_label, style_label, phase_label, combo_label]:
		if label == null:
			continue
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.84, 1.0, 0.96, 0.94))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	score_label.add_theme_font_size_override("font_size", 19)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.28))
	objective_label.add_theme_color_override("font_color", Color(0.58, 1.0, 0.96, 0.96))
	phase_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.25, 0.96))
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.95))
	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _layout_hud() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if hud_panel != null:
		var dock_rect := hud_dock_rect_for_viewport(viewport_size)
		_apply_control_rect(hud_panel, dock_rect)
		hud_panel.custom_minimum_size = dock_rect.size
	if message_label != null:
		_apply_control_rect(message_label, hud_message_rect_for_viewport(viewport_size))

static func hud_dock_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	var width: float = clampf(viewport_size.x - HUD_DOCK_SAFE_MARGIN * 2.0, HUD_DOCK_MIN_WIDTH, HUD_DOCK_MAX_WIDTH)
	var height: float = minf(HUD_DOCK_HEIGHT, maxf(118.0, viewport_size.y * 0.22))
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

func _step_portal_motion(delta: float) -> void:
	if _portal_material == null:
		return
	var target_speed := portal_animation_speed_for_ball_velocity(_ball_v_z, _ball_v_theta)
	if _pending_transition and _transition_mode == "portal_breach":
		target_speed = PORTAL_MAX_ANIMATION_SPEED
	_portal_animation_speed = smoothed_portal_animation_speed(_portal_animation_speed, target_speed, delta)
	_portal_phase = fmod(_portal_phase + delta * _portal_animation_speed, 10000.0)
	_portal_material.set_shader_parameter("portal_phase", _portal_phase)

func _step_tunnel_texture_motion(delta: float) -> void:
	if _tunnel_material == null:
		return
	var target_speed := tunnel_texture_speed_for_ball_velocity(_ball_v_z, _ball_v_theta)
	if _pending_transition and _transition_mode == "portal_breach":
		target_speed = TUNNEL_TEXTURE_MAX_SPEED
	_tunnel_texture_speed = smoothed_tunnel_texture_speed(_tunnel_texture_speed, target_speed, delta)
	_tunnel_texture_phase = fmod(_tunnel_texture_phase + delta * _tunnel_texture_speed, 10000.0)
	_tunnel_material.set_shader_parameter("tunnel_phase", _tunnel_texture_phase)

func _apply_control_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y

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
	_clear_powerups()
	_show_message("PORTAL BREACH", 0.0)
	_start_camera_shake(0.12, PORTAL_BREACH_DURATION)
	_pulse_haptic(68, 0.9)
	SaveStore.record_level(_level_index + 1)
	await get_tree().create_timer(PORTAL_BREACH_DURATION).timeout

	if LevelLoader.has_level(_level_index + 1):
		RunManager.start_level(_level_index + 1)
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
			_portal_material.set_shader_parameter("alpha", lerpf(0.62, 0.96, t))
			_portal_material.set_shader_parameter("zoom", lerpf(2.55, 1.25, t))
			_portal_material.set_shader_parameter("drift", lerpf(0.45, 1.15, t))
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
