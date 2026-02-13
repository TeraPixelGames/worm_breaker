extends Node

func _ready() -> void:
	call_deferred("_route_to_menu")

func _route_to_menu() -> void:
	RunManager.go_to_main_menu()
