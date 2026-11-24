extends GdUnitTestSuite
# Feature: hambos_adventures — MinigameRegistry integration test

func test_minigame_registry_contains_hambos_adventures() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("hambos_adventures")

	assert_str(entry.get("id")).is_equal("hambos_adventures")
	assert_str(entry.get("name")).is_equal("Hambo's Adventures")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Hambos Adventures/HambosAdventures.tscn")
	assert_int(entry.get("tier")).is_equal(2)
