extends GdUnitTestSuite
# Feature: lollipop — MinigameRegistry integration test


func test_minigame_registry_contains_lollipop() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("lollipop")

	assert_str(entry.get("id")).is_equal("lollipop")
	assert_str(entry.get("name")).is_equal("Lollipop")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Lollipop/Lollipop.tscn")
	assert_int(entry.get("tier")).is_equal(2)
