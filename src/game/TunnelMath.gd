extends RefCounted

# Adapted from angle normalization patterns in wormhole_raiders:
# scripts/core/GameConstants.gd
static func wrap_angle(angle: float) -> float:
	return wrapf(angle + PI, 0.0, TAU) - PI

static func theta_distance(theta_a: float, theta_b: float) -> float:
	return wrap_angle(theta_a - theta_b)

static func theta_overlap(a_center: float, a_half: float, b_center: float, b_half: float) -> bool:
	return absf(theta_distance(a_center, b_center)) <= (a_half + b_half)

static func bend_enabled(bend_profile: Dictionary = {}) -> bool:
	return bool(bend_profile.get("enabled", false))

static func bend_phase(bend_profile: Dictionary = {}) -> float:
	return float(bend_profile.get("phase", 0.0)) + float(bend_profile.get("time", 0.0)) * float(bend_profile.get("speed", 0.18))

static func bend_offset_x(z: float, bend_profile: Dictionary = {}) -> float:
	if not bend_enabled(bend_profile):
		return 0.0
	var amplitude := float(bend_profile.get("amplitude", 1.0))
	var frequency := float(bend_profile.get("frequency", 1.0))
	var phase := bend_phase(bend_profile)
	return sin(z * 0.018 * frequency + phase) * 3.2 * amplitude + sin(z * 0.041 * frequency + phase * 0.73 + 1.7) * 1.35 * amplitude

static func bend_slope_x(z: float, bend_profile: Dictionary = {}) -> float:
	if not bend_enabled(bend_profile):
		return 0.0
	var amplitude := float(bend_profile.get("amplitude", 1.0))
	var frequency := float(bend_profile.get("frequency", 1.0))
	var phase := bend_phase(bend_profile)
	return cos(z * 0.018 * frequency + phase) * 3.2 * amplitude * 0.018 * frequency + cos(z * 0.041 * frequency + phase * 0.73 + 1.7) * 1.35 * amplitude * 0.041 * frequency

static func tube_center(z: float, bend_profile: Dictionary = {}) -> Vector3:
	return Vector3(bend_offset_x(z, bend_profile), 0.0, z)

static func tube_tangent(z: float, bend_profile: Dictionary = {}) -> Vector3:
	return Vector3(bend_slope_x(z, bend_profile), 0.0, 1.0).normalized()

static func tube_up_axis(_z: float, _bend_profile: Dictionary = {}) -> Vector3:
	return Vector3.UP

static func tube_side_axis(z: float, bend_profile: Dictionary = {}) -> Vector3:
	var tangent := tube_tangent(z, bend_profile)
	var side := Vector3.UP.cross(tangent)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	return side.normalized()

static func radial_from_angle(theta: float, z: float, bend_profile: Dictionary = {}) -> Vector3:
	var side := tube_side_axis(z, bend_profile)
	var up_axis := tube_up_axis(z, bend_profile)
	return (cos(theta) * side + sin(theta) * up_axis).normalized()

static func tangent_from_angle(theta: float, z: float, bend_profile: Dictionary = {}) -> Vector3:
	var side := tube_side_axis(z, bend_profile)
	var up_axis := tube_up_axis(z, bend_profile)
	return (-sin(theta) * side + cos(theta) * up_axis).normalized()

static func surface_to_world(theta: float, z: float, radius: float, bend_profile: Dictionary = {}) -> Vector3:
	if not bend_enabled(bend_profile):
		return Vector3(cos(theta) * radius, sin(theta) * radius, z)
	return tube_center(z, bend_profile) + radial_from_angle(theta, z, bend_profile) * radius

static func surface_basis(theta: float, z: float, bend_profile: Dictionary = {}) -> Basis:
	var tangent := tangent_from_angle(theta, z, bend_profile)
	var forward := tube_tangent(z, bend_profile)
	var inward := -radial_from_angle(theta, z, bend_profile)
	return Basis(tangent, forward, inward).orthonormalized()

static func portal_basis(z: float, bend_profile: Dictionary = {}) -> Basis:
	var side := tube_side_axis(z, bend_profile)
	var up_axis := tube_up_axis(z, bend_profile)
	var forward := tube_tangent(z, bend_profile)
	return Basis(side, up_axis, forward).orthonormalized()

static func surface_to_world_legacy(theta: float, z: float, radius: float) -> Vector3:
	return Vector3(cos(theta) * radius, sin(theta) * radius, z)

static func world_to_surface(pos: Vector3, _radius: float) -> Dictionary:
	return {
		"theta": wrap_angle(atan2(pos.y, pos.x)),
		"z": pos.z
	}
