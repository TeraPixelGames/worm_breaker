extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")

func test_hud_dock_stays_below_mobile_camera_cutout_area() -> void:
	for viewport_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1920, 1080)]:
		var dock_rect: Rect2 = GameController.hud_dock_rect_for_viewport(viewport_size)
		assert_true(dock_rect.position.y > viewport_size.y * 0.70, "HUD dock should live in the lower play area for %s" % viewport_size)
		assert_true(dock_rect.position.x >= 24.0, "HUD dock should respect left safe margin for %s" % viewport_size)
		assert_true(dock_rect.end.x <= viewport_size.x - 24.0, "HUD dock should respect right safe margin for %s" % viewport_size)
		assert_true(dock_rect.end.y <= viewport_size.y - 24.0, "HUD dock should respect bottom safe margin for %s" % viewport_size)

func test_hud_message_sits_above_bottom_dock_not_top_edge() -> void:
	var viewport_size := Vector2(720, 1280)
	var dock_rect: Rect2 = GameController.hud_dock_rect_for_viewport(viewport_size)
	var message_rect: Rect2 = GameController.hud_message_rect_for_viewport(viewport_size)
	assert_true(message_rect.position.y > 96.0, "Message label should avoid the mobile camera cutout area")
	assert_true(message_rect.end.y < dock_rect.position.y, "Message label should sit above the bottom HUD dock")
	assert_true(message_rect.position.x >= 24.0, "Message label should respect left safe margin")
	assert_true(message_rect.end.x <= viewport_size.x - 24.0, "Message label should respect right safe margin")
