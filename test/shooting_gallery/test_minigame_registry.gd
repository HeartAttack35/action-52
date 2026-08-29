extends GdUnitTestSuite
# Feature: shooting-gallery — MinigameRegistry integration test
# Validates: Requisito 7.2


func test_minigame_registry_contains_shooting_gallery() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("shooting_gallery")

	assert_str(entry.get("id")).is_equal("shooting_gallery")
	assert_str(entry.get("name")).is_equal("Shooting Gallery")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Shooting Gallery/shooting_gallery.tscn")
	assert_int(entry.get("tier")).is_equal(1)
