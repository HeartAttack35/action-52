extends GdUnitTestSuite
# Feature: chill-out — MinigameRegistry integration test

func test_minigame_registry_contains_chill_out() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("chill_out")

	assert_str(entry.get("id")).is_equal("chill_out")
	assert_str(entry.get("name")).is_equal("Chill-Out")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Chill-Out/ChillOut.tscn")
	assert_int(entry.get("tier")).is_equal(2)
