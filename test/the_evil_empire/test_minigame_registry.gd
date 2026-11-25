extends GdUnitTestSuite
# Feature: the_evil_empire — MinigameRegistry integration test


func test_minigame_registry_contains_the_evil_empire() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("the_evil_empire")

	assert_str(entry.get("id")).is_equal("the_evil_empire")
	assert_str(entry.get("name")).is_equal("The Evil Empire")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/The Evil Empire/TheEvilEmpire.tscn")
	assert_int(entry.get("tier")).is_equal(2)
