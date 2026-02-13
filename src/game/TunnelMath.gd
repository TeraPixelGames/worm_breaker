extends RefCounted

# Adapted from angle normalization patterns in wormhole_raiders:
# scripts/core/GameConstants.gd
static func wrap_angle(angle: float) -> float:
	return wrapf(angle + PI, 0.0, TAU) - PI

static func theta_distance(theta_a: float, theta_b: float) -> float:
	return wrap_angle(theta_a - theta_b)

static func theta_overlap(a_center: float, a_half: float, b_center: float, b_half: float) -> bool:
	return absf(theta_distance(a_center, b_center)) <= (a_half + b_half)

static func surface_to_world(theta: float, z: float, radius: float) -> Vector3:
	return Vector3(cos(theta) * radius, sin(theta) * radius, z)

static func world_to_surface(pos: Vector3, _radius: float) -> Dictionary:
	return {
		"theta": wrap_angle(atan2(pos.y, pos.x)),
		"z": pos.z
	}
