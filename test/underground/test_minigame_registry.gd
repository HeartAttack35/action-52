extends GdUnitTestSuite
# Feature: underground — MinigameRegistry integration test

func test_minigame_registry_contains_underground() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("underground")

	assert_str(entry.get("id")).is_equal("underground")
	assert_str(entry.get("name")).is_equal("Underground")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Underground/Underground.tscn")
	assert_int(entry.get("tier")).is_equal(2)
