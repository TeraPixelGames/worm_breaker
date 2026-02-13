extends Node3D

const BRICK_SCENE: PackedScene = preload("res://src/scenes/Brick.tscn")
const TunnelMath = preload("res://src/game/TunnelMath.gd")
const Collision = preload("res://src/game/Collision.gd")
const LevelLoader = preload("res://src/game/LevelLoader.gd")

const BALL_THETA_RADIUS: float = 0.12
const BALL_Z_RADIUS: float = 0.34
const BALL_WORLD_RADIUS: float = 0.18
const PADDLE_SEGMENT_COUNT: int = 11
const PADDLE_SURFACE_INSET: float = 0.24
const COMBO_RESET_TIME: float = 1.2

@onready var tunnel: MeshInstance3D = $World/Tunnel
@onready var paddle_root: Node3D = $World/PaddleRoot
@onready var ball_mesh: MeshInstance3D = $World/Ball
@onready var brick_root: Node3D = $World/BrickRoot
@onready var camera: Camera3D = $World/CameraRig/Camera3D
@onready var rot_input: Node = $RotInput
@onready var combo_sfx: AudioStreamPlayer = $ComboSfx
@onready var score_label: Label = $HUD/Panel/VBox/ScoreLabel
@onready var level_label: Label = $HUD/Panel/VBox/LevelLabel
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

var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_amount: float = 0.0

var _paddle_segments: Array[MeshInstance3D] = []
var _bricks: Array = []

func _ready() -> void:
	MusicManager.play_game()
	_setup_ball_visual()
	_build_paddle_segments()
	_load_level(max(1, RunManager.current_level_index))
	_update_hud()

func _physics_process(delta: float) -> void:
	if _pending_transition:
		_update_camera(delta)
		_update_hud()
		return

	_step_combo(delta)
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

	if _ball_v_z < 0.0 and prev_z >= _paddle_z and _ball_z <= _paddle_z:
		var paddle_hit: bool = Collision.ball_vs_paddle(_ball_theta, _paddle_z, _paddle_theta, _paddle_width, _paddle_z)
		if paddle_hit:
			var bounce: Dictionary = Collision.reflect_from_paddle(
				_ball_v_theta,
				_ball_v_z,
				_ball_theta,
				_paddle_theta,
				_paddle_width,
				1.9
			)
			_ball_v_theta = float(bounce.get("v_theta", _ball_v_theta))
			_ball_v_z = float(bounce.get("v_z", absf(_ball_v_z)))
			_ball_z = _paddle_z + 0.02
			_chain_combo = 0
			_combo_timeout = 0.0
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
		_register_combo_hit()

		if destroyed:
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
	RunManager.add_score(100 + (_chain_combo - 1) * 30)
	if combo_sfx != null and combo_sfx.has_method("play_combo"):
		combo_sfx.play_combo(_chain_combo)
	if _chain_combo >= 2:
		_start_camera_shake(0.04 + 0.01 * min(_chain_combo, 8), 0.15)

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
	_pending_transition = false
	if rot_input != null and rot_input.has_method("reset"):
		rot_input.reset()
	_level_end_z = _compute_level_end_z()

	_refresh_tunnel_visual()
	_spawn_bricks()
	_update_ball_visual()
	_update_paddle_visual()
	_update_camera(0.0, true)
	_show_message("Level %d" % _level_index, 1.0)

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

	var tunnel_material: StandardMaterial3D = StandardMaterial3D.new()
	tunnel_material.albedo_color = Color(0.06, 0.08, 0.12)
	tunnel_material.roughness = 0.95
	tunnel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tunnel.material_override = tunnel_material

func _setup_ball_visual() -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = BALL_WORLD_RADIUS
	sphere.height = BALL_WORLD_RADIUS * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	ball_mesh.mesh = sphere

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.98, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.32, 0.42, 0.6)
	mat.roughness = 0.2
	ball_mesh.material_override = mat

func _build_paddle_segments() -> void:
	for child in paddle_root.get_children():
		child.queue_free()
	_paddle_segments.clear()

	for i in range(PADDLE_SEGMENT_COUNT):
		var segment: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.3, 0.4, 0.2)
		segment.mesh = mesh

		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.32, 0.95, 0.5)
		material.roughness = 0.35
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		segment.material_override = material

		paddle_root.add_child(segment)
		_paddle_segments.append(segment)

func _update_paddle_visual() -> void:
	if _paddle_segments.is_empty():
		return

	for i in range(_paddle_segments.size()):
		var segment: MeshInstance3D = _paddle_segments[i]
		var t: float = 0.0
		if _paddle_segments.size() > 1:
			t = float(i) / float(_paddle_segments.size() - 1) - 0.5
		var segment_theta: float = TunnelMath.wrap_angle(_paddle_theta + t * _paddle_width)
		var tangent: Vector3 = Vector3(-sin(segment_theta), cos(segment_theta), 0.0).normalized()
		var forward: Vector3 = Vector3.FORWARD
		var inward: Vector3 = -Vector3(cos(segment_theta), sin(segment_theta), 0.0).normalized()
		segment.position = TunnelMath.surface_to_world(segment_theta, _paddle_z, _play_radius)
		segment.basis = Basis(tangent, forward, inward).orthonormalized()

		if segment.mesh is BoxMesh:
			var mesh: BoxMesh = segment.mesh as BoxMesh
			var arc_len: float = max((_paddle_width / float(PADDLE_SEGMENT_COUNT)) * _play_radius * 1.15, 0.18)
			mesh.size = Vector3(arc_len, 0.55, 0.22)

func _update_ball_visual() -> void:
	ball_mesh.position = TunnelMath.surface_to_world(_ball_theta, _ball_z, _play_radius)

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

func _update_camera(delta: float, snap: bool = false) -> void:
	# Adapted from wormhole_raiders AngleSystem camera strategy:
	# scripts/systems/AngleSystem.gd::_update_camera
	var paddle_pos: Vector3 = TunnelMath.surface_to_world(_paddle_theta, _paddle_z, _play_radius)
	var outward: Vector3 = Vector3(cos(_paddle_theta), sin(_paddle_theta), 0.0).normalized()
	var inward: Vector3 = -outward
	var forward: Vector3 = Vector3.FORWARD

	var cam_target: Vector3 = paddle_pos + inward * 2.4 - forward * 7.2
	if snap:
		camera.global_position = cam_target
	else:
		camera.global_position = camera.global_position.lerp(cam_target, clampf(delta * 8.0, 0.0, 1.0))

	var look_target: Vector3 = paddle_pos + forward * 10.0 + inward * 0.9
	camera.look_at(look_target, inward)
	_apply_camera_shake(delta)

func _start_camera_shake(amount: float, duration: float) -> void:
	_shake_amount = max(_shake_amount, amount)
	_shake_duration = max(duration, 0.01)
	_shake_time = max(_shake_time, duration)

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
	_show_message("Level Complete", 1.1)
	SaveStore.record_level(_level_index + 1)
	await get_tree().create_timer(1.1).timeout

	if LevelLoader.has_level(_level_index + 1):
		RunManager.start_level(_level_index + 1)
	else:
		RunManager.go_to_results(true, _level_index, RunManager.run_score)

func _lose_run() -> void:
	if _pending_transition:
		return
	_pending_transition = true
	_show_message("Ball Lost", 0.9)
	await get_tree().create_timer(0.9).timeout
	RunManager.go_to_results(false, _level_index, RunManager.run_score)

func _show_message(text: String, hide_after: float) -> void:
	message_label.text = text
	message_label.visible = true
	if hide_after > 0.0:
		var local_hide_after: float = hide_after
		_hide_message_deferred(local_hide_after)

func _hide_message_deferred(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not _pending_transition:
		message_label.visible = false

func _update_hud() -> void:
	score_label.text = "Score: %d" % RunManager.run_score
	level_label.text = "Level: %d/%d" % [_level_index, LevelLoader.level_count()]
	combo_label.text = "Combo: %d" % _chain_combo
