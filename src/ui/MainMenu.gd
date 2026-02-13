extends Control

@onready var summary_label: Label = $Center/VBox/SummaryLabel

func _ready() -> void:
	MusicManager.play_menu()
	summary_label.text = "Best Level: %d   High Score: %d" % [SaveStore.best_level_reached, SaveStore.high_score]

func _on_start_button_pressed() -> void:
	RunManager.start_new_run()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
