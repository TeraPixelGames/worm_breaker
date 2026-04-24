extends Node

const SAVE_PATH: String = "user://wormbreak_save.json"

var high_score: int = 0
var best_level_reached: int = 1
var run_win_streak: int = 0
var fail_streak: int = 0
var rival_target: int = 1200
var rival_anchor_date: String = ""
var rival_beat_streak: int = 0

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
	run_win_streak = max(0, int(data.get("run_win_streak", 0)))
	fail_streak = max(0, int(data.get("fail_streak", 0)))
	rival_target = max(1200, int(data.get("rival_target", 1200)))
	rival_anchor_date = str(data.get("rival_anchor_date", ""))
	rival_beat_streak = max(0, int(data.get("rival_beat_streak", 0)))

func save_data() -> void:
	var data: Dictionary = {
		"high_score": high_score,
		"best_level_reached": best_level_reached,
		"run_win_streak": run_win_streak,
		"fail_streak": fail_streak,
		"rival_target": rival_target,
		"rival_anchor_date": rival_anchor_date,
		"rival_beat_streak": rival_beat_streak
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

func record_run_result(won: bool) -> void:
	if won:
		run_win_streak += 1
		fail_streak = 0
	else:
		run_win_streak = 0
		fail_streak += 1
	save_data()

func refresh_rival_target() -> int:
	var today := _today_key()
	if rival_anchor_date == today and rival_target >= 1200:
		return rival_target
	var seed: int = abs(hash("wormbreak-rival-" + today))
	rival_target = maxi(high_score + 300 + (seed % 420), 1200)
	rival_anchor_date = today
	save_data()
	return rival_target

func record_rival_result(score: int) -> bool:
	var target := refresh_rival_target()
	var beat := score >= target
	if beat:
		rival_beat_streak += 1
	else:
		rival_beat_streak = 0
	save_data()
	return beat

func _today_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(date.get("year", 1970)), int(date.get("month", 1)), int(date.get("day", 1))]
