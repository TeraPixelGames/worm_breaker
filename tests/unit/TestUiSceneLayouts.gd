extends "res://tests/framework/TestCase.gd"

const MAIN_MENU_SCENE: PackedScene = preload("res://src/scenes/MainMenu.tscn")
const RESULTS_SCENE: PackedScene = preload("res://src/scenes/Results.tscn")

func test_main_menu_launch_deck_stays_inside_viewports() -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1920, 1080)]:
		var menu := MAIN_MENU_SCENE.instantiate() as Control
		menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
		get_tree().root.add_child(menu)
		menu.size = viewport_size
		await get_tree().process_frame
		var panel := menu.get_node("Center/Panel") as Panel
		assert_true(panel.position.x >= 0.0, "Main menu panel should stay inside left edge for %s" % viewport_size)
		assert_true(panel.position.y >= 0.0, "Main menu panel should stay inside top edge for %s" % viewport_size)
		assert_true(panel.position.x + panel.size.x <= viewport_size.x, "Main menu panel should stay inside right edge for %s" % viewport_size)
		assert_true(panel.position.y + panel.size.y <= viewport_size.y, "Main menu panel should stay inside bottom edge for %s" % viewport_size)
		assert_equal((menu.get_node("Center/Panel/VBox/StartButton") as Button).text, "PRESS TO LAUNCH", "Primary launch copy should be cinematic prompt text")
		menu.queue_free()
		await get_tree().process_frame

func test_results_chamber_stays_inside_viewports() -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1920, 1080)]:
		var results := RESULTS_SCENE.instantiate() as Control
		results.set_anchors_preset(Control.PRESET_TOP_LEFT)
		get_tree().root.add_child(results)
		results.size = viewport_size
		await get_tree().process_frame
		var chamber := results.get_node("Center/ResultChamber") as Panel
		assert_true(chamber.position.x >= 0.0, "Results chamber should stay inside left edge for %s" % viewport_size)
		assert_true(chamber.position.y >= 0.0, "Results chamber should stay inside top edge for %s" % viewport_size)
		assert_true(chamber.position.x + chamber.size.x <= viewport_size.x, "Results chamber should stay inside right edge for %s" % viewport_size)
		assert_true(chamber.position.y + chamber.size.y <= viewport_size.y, "Results chamber should stay inside bottom edge for %s" % viewport_size)
		assert_equal((results.get_node("Center/VBox/RestartButton") as Button).text, "NEXT RUN", "Win result should make the primary action obvious")
		results.queue_free()
		await get_tree().process_frame
