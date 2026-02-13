extends Node3D

const TunnelMath = preload("res://src/game/TunnelMath.gd")

@onready var body: MeshInstance3D = $Body

var hp: int = 1
var max_hp: int = 1
var theta_center: float = 0.0
var z_center: float = 0.0
var theta_size: float = 0.42
var z_size: float = 1.0

var _material: StandardMaterial3D
var _flash_timer: float = 0.0

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.roughness = 0.45
	_material.metallic = 0.05
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	body.material_override = _material
	_refresh_color()

func setup(data: Dictionary, surface_radius: float, default_theta_size: float, default_z_size: float) -> void:
	theta_center = float(data.get("theta_center", 0.0))
	z_center = float(data.get("z_center", 12.0))
	theta_size = float(data.get("theta_size", default_theta_size))
	z_size = float(data.get("z_size", default_z_size))
	hp = max(1, int(data.get("hp", 1)))
	max_hp = hp

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
	if _flash_timer <= 0.0:
		return
	_flash_timer = max(_flash_timer - delta, 0.0)
	var flash_alpha: float = _flash_timer / 0.12
	_material.emission_enabled = flash_alpha > 0.0
	_material.emission = Color(1.0, 1.0, 1.0) * (0.9 * flash_alpha)

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
	if hp >= 2:
		_material.albedo_color = Color(0.25, 0.75, 1.0)
	else:
		_material.albedo_color = Color(1.0, 0.6, 0.2)
