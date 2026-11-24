extends GdUnitTestSuite
# Feature: illuminator — MinigameRegistry integration test

func test_minigame_registry_contains_illuminator() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("illuminator")

	assert_str(entry.get("id")).is_equal("illuminator")
	assert_str(entry.get("name")).is_equal("Illuminator")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Illuminator/Illuminator.tscn")
	assert_int(entry.get("tier")).is_equal(2)
