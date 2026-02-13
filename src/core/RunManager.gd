extends Node

const BOOT_SCENE: String = "res://src/scenes/Boot.tscn"
const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"
const GAME_SCENE: String = "res://src/scenes/Game.tscn"
const RESULTS_SCENE: String = "res://src/scenes/Results.tscn"

var current_level_index: int = 1
var run_score: int = 0
var last_result_win: bool = false
var last_completed_level: int = 1

func go_to_main_menu() -> void:
	current_level_index = 1
	run_score = 0
	_change_scene(MAIN_MENU_SCENE)

func start_new_run() -> void:
	current_level_index = 1
	run_score = 0
	_change_scene(GAME_SCENE)

func start_level(level_index: int) -> void:
	current_level_index = max(1, level_index)
	_change_scene(GAME_SCENE)

func add_score(points: int) -> void:
	run_score += max(0, points)

func complete_level() -> void:
	current_level_index += 1
	SaveStore.record_level(current_level_index)

func go_to_results(win: bool, completed_level: int, score: int) -> void:
	last_result_win = win
	last_completed_level = max(1, completed_level)
	run_score = max(0, score)
	SaveStore.record_score(run_score)
	_change_scene(RESULTS_SCENE)

func _change_scene(scene_path: String) -> void:
	if get_tree() == null:
		return
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)" % [scene_path, err])
