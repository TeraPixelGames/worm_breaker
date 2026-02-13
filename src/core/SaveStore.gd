extends Node

const SAVE_PATH: String = "user://wormbreak_save.json"

var high_score: int = 0
var best_level_reached: int = 1

func _ready() -> void:
	load_data()

func load_data() -> void:
	high_score = 0
	best_level_reached = 1
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed
	high_score = int(data.get("high_score", 0))
	best_level_reached = max(1, int(data.get("best_level_reached", 1)))

func save_data() -> void:
	var data: Dictionary = {
		"high_score": high_score,
		"best_level_reached": best_level_reached
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to write save file at %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))

func record_score(score: int) -> void:
	if score > high_score:
		high_score = score
		save_data()

func record_level(level_reached: int) -> void:
	var normalized_level: int = max(1, level_reached)
	if normalized_level > best_level_reached:
		best_level_reached = normalized_level
		save_data()
