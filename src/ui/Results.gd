extends Control

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var summary_label: Label = $Center/VBox/SummaryLabel
@onready var target_label: Label = $Center/VBox/TargetLabel

func _ready() -> void:
	var is_win: bool = RunManager.last_result_win
	title_label.text = "Run Clear" if is_win else "Game Over"
	var style_text := "Overdrive" if str(RunManager.run_style).to_lower() == "overdrive" else "Stability"
	summary_label.text = "Level: %d   Score: %d   High: %d   Style: %s" % [
		RunManager.last_completed_level,
		RunManager.run_score,
		SaveStore.high_score,
		style_text
	]
	target_label.text = "Win streak: %d   Best level: %d\nRival target: %d (%s)   Rival Beat Streak: %d" % [
		SaveStore.run_win_streak,
		SaveStore.best_level_reached,
		RunManager.last_rival_target,
		"beat" if RunManager.last_rival_beaten else "missed",
		SaveStore.rival_beat_streak
	]

func _on_restart_button_pressed() -> void:
	RunManager.start_new_run()

func _on_menu_button_pressed() -> void:
	RunManager.go_to_main_menu()
