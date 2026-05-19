extends Node3D

const TunnelMath = preload("res://src/game/TunnelMath.gd")
const CRYSTAL_BLOCK_SHADER: Shader = preload("res://src/shaders/crystal_block.gdshader")

@onready var body: MeshInstance3D = $Body

var hp: int = 1
var max_hp: int = 1
var theta_center: float = 0.0
var z_center: float = 0.0
var theta_size: float = 0.42
var z_size: float = 1.0

var _material: ShaderMaterial
var _flash_timer: float = 0.0
var _phase: float = 0.0

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = CRYSTAL_BLOCK_SHADER
	body.material_override = _material
	_refresh_color()

func setup(data: Dictionary, surface_radius: float, default_theta_size: float, default_z_size: float) -> void:
	theta_center = float(data.get("theta_center", 0.0))
	z_center = float(data.get("z_center", 12.0))
	theta_size = float(data.get("theta_size", default_theta_size))
	z_size = float(data.get("z_size", default_z_size))
	hp = max(1, int(data.get("hp", 1)))
	max_hp = hp
	_phase = fmod(absf(theta_center) * 0.73 + z_center * 0.11, 1.0)

	_place_on_surface(surface_radius)
	_refresh_color()

func apply_hit() -> bool:
	hp = max(0, hp - 1)
	_flash_timer = 0.12
	_refresh_color()
	return hp == 0

func get_collision_data(ball_theta_radius: float, ball_z_radius: float) -> Dictionary:
	return {
		"theta_center": theta_center,
		"z_center": z_center,
		"theta_size": theta_size,
		"z_size": z_size,
		"ball_theta_radius": ball_theta_radius,
		"ball_z_radius": ball_z_radius
	}

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 0.08, 1.0)
	_flash_timer = max(_flash_timer - delta, 0.0)
	_refresh_color()

func _place_on_surface(surface_radius: float) -> void:
	position = TunnelMath.surface_to_world(theta_center, z_center, surface_radius)
	var tangent: Vector3 = Vector3(-sin(theta_center), cos(theta_center), 0.0).normalized()
	var forward: Vector3 = Vector3.FORWARD
	var inward: Vector3 = -Vector3(cos(theta_center), sin(theta_center), 0.0).normalized()
	basis = Basis(tangent, forward, inward).orthonormalized()

	if body.mesh is BoxMesh:
		var box: BoxMesh = body.mesh as BoxMesh
		box.size = Vector3(
			max(theta_size * surface_radius * 0.95, 0.2),
			max(z_size * 0.95, 0.2),
			0.28
		)

func _refresh_color() -> void:
	var hue := fmod(_phase + (0.56 if hp >= 2 else 0.88), 1.0)
	var flash_alpha: float = clampf(_flash_timer / 0.12, 0.0, 1.0)
	if hp >= 2:
		_material.set_shader_parameter("crystal_color", Color.from_hsv(hue, 0.58, 0.96))
		_material.set_shader_parameter("core_color", Color.from_hsv(fmod(hue + 0.16, 1.0), 0.82, 1.0))
	else:
		_material.set_shader_parameter("crystal_color", Color.from_hsv(hue, 0.64, 1.0))
		_material.set_shader_parameter("core_color", Color.from_hsv(fmod(hue + 0.12, 1.0), 0.92, 1.0))
	_material.set_shader_parameter("flash_color", Color(1.0, 1.0, 1.0, 1.0))
	_material.set_shader_parameter("flash_strength", flash_alpha)
	_material.set_shader_parameter("time_phase", _phase * 100.0)
	_material.set_shader_parameter("hp_ratio", float(hp) / maxf(float(max_hp), 1.0))
