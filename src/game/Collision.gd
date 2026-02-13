extends RefCounted

const TunnelMath = preload("res://src/game/TunnelMath.gd")

static func ball_vs_brick(ball_theta: float, ball_z: float, brick: Dictionary) -> Dictionary:
	var theta_center: float = float(brick.get("theta_center", 0.0))
	var z_center: float = float(brick.get("z_center", 0.0))
	var theta_size: float = float(brick.get("theta_size", 0.0))
	var z_size: float = float(brick.get("z_size", 0.0))
	var ball_theta_radius: float = float(brick.get("ball_theta_radius", 0.0))
	var ball_z_radius: float = float(brick.get("ball_z_radius", 0.0))

	var theta_half: float = theta_size * 0.5 + ball_theta_radius
	var z_half: float = z_size * 0.5 + ball_z_radius
	if theta_half <= 0.0 or z_half <= 0.0:
		return {"hit": false}

	if not TunnelMath.theta_overlap(ball_theta, ball_theta_radius, theta_center, theta_size * 0.5):
		return {"hit": false}

	var delta_theta: float = TunnelMath.theta_distance(ball_theta, theta_center)
	var delta_z: float = ball_z - z_center
	if absf(delta_z) > z_half:
		return {"hit": false}

	var theta_penetration: float = theta_half - absf(delta_theta)
	var z_penetration: float = z_half - absf(delta_z)
	var axis: String = "theta" if theta_penetration < z_penetration else "z"

	return {
		"hit": true,
		"axis": axis,
		"theta_sign": -1.0 if delta_theta < 0.0 else 1.0,
		"z_sign": -1.0 if delta_z < 0.0 else 1.0,
		"delta_theta": delta_theta,
		"delta_z": delta_z
	}

static func ball_vs_paddle(ball_theta: float, ball_z: float, paddle_theta: float, paddle_width: float, paddle_z: float) -> bool:
	if absf(ball_z - paddle_z) > 0.45:
		return false
	return TunnelMath.theta_overlap(ball_theta, 0.0, paddle_theta, paddle_width * 0.5)

static func reflect_from_paddle(
	v_theta: float,
	v_z: float,
	ball_theta: float,
	paddle_theta: float,
	paddle_width: float,
	spin_strength: float = 1.8
) -> Dictionary:
	var half_width: float = max(paddle_width * 0.5, 0.0001)
	var offset_norm: float = clampf(TunnelMath.theta_distance(ball_theta, paddle_theta) / half_width, -1.0, 1.0)
	return {
		"v_theta": v_theta + offset_norm * spin_strength,
		"v_z": absf(v_z),
		"offset_norm": offset_norm
	}
