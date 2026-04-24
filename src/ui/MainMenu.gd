extends Control

@onready var summary_label: Label = $Center/Panel/VBox/SummaryLabel

func _ready() -> void:
	MusicManager.play_menu()
	var rival_target := SaveStore.refresh_rival_target()
	summary_label.text = "Best Level: %d   High Score: %d   Win Streak: %d\nDaily Rival Target: %d (Beat Streak %d)" % [
		SaveStore.best_level_reached,
		SaveStore.high_score,
		SaveStore.run_win_streak,
		rival_target,
		SaveStore.rival_beat_streak
	]

func _on_start_button_pressed() -> void:
	RunManager.set_run_style("stability")
	RunManager.start_new_run("stability")

func _on_overdrive_button_pressed() -> void:
	RunManager.set_run_style("overdrive")
	RunManager.start_new_run("overdrive")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
