extends RefCounted

const LEVEL_PATHS: PackedStringArray = [
	"res://src/game/levels/level_001.json",
	"res://src/game/levels/level_002.json",
	"res://src/game/levels/level_003.json"
]

static func level_count() -> int:
	return LEVEL_PATHS.size()

static func has_level(level_index: int) -> bool:
	return level_index >= 1 and level_index <= LEVEL_PATHS.size()

static func load_level(level_index: int) -> Dictionary:
	if not has_level(level_index):
		push_error("Requested level %d out of range." % level_index)
		return {}

	var path: String = LEVEL_PATHS[level_index - 1]
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open level file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Level file does not contain a dictionary: %s" % path)
		return {}

	return _normalize_level(parsed as Dictionary, level_index)

static func _normalize_level(level_data: Dictionary, level_index: int) -> Dictionary:
	var normalized: Dictionary = {}
	normalized["id"] = int(level_data.get("id", level_index))
	normalized["tunnel_radius"] = float(level_data.get("tunnel_radius", 6.0))
	normalized["paddle_width"] = float(level_data.get("paddle_width", 0.9))
	normalized["paddle_z"] = float(level_data.get("paddle_z", 3.0))
	normalized["brick_theta_size"] = float(level_data.get("brick_theta_size", 0.42))
	normalized["brick_z_size"] = float(level_data.get("brick_z_size", 1.0))
	normalized["start_speed_theta"] = float(level_data.get("start_speed_theta", 0.3))
	normalized["start_speed_z"] = float(level_data.get("start_speed_z", 8.0))

	var bricks: Array[Dictionary] = []
	var source_bricks: Array = level_data.get("bricks", [])
	for item in source_bricks:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var brick_data: Dictionary = item
		bricks.append({
			"theta_center": float(brick_data.get("theta_center", 0.0)),
			"z_center": float(brick_data.get("z_center", 12.0)),
			"hp": max(1, int(brick_data.get("hp", 1))),
			"type": String(brick_data.get("type", "normal"))
		})
	normalized["bricks"] = bricks
	return normalized
