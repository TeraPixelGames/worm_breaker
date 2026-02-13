extends Control

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var summary_label: Label = $Center/VBox/SummaryLabel

func _ready() -> void:
	var is_win: bool = RunManager.last_result_win
	title_label.text = "Run Clear" if is_win else "Game Over"
	summary_label.text = "Level: %d   Score: %d   High: %d" % [
		RunManager.last_completed_level,
		RunManager.run_score,
		SaveStore.high_score
	]

func _on_restart_button_pressed() -> void:
	RunManager.start_new_run()

func _on_menu_button_pressed() -> void:
	RunManager.go_to_main_menu()
