extends GdUnitTestSuite
# Feature: french-baker — MinigameRegistry integration test

func test_minigame_registry_contains_french_baker() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("french_baker")

	assert_str(entry.get("id")).is_equal("french_baker")
	assert_str(entry.get("name")).is_equal("French Baker")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/French Baker/FrenchBaker.tscn")
	assert_int(entry.get("tier")).is_equal(2)
