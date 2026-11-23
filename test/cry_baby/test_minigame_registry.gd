extends GdUnitTestSuite
# Feature: cry-baby — MinigameRegistry integration test

func test_minigame_registry_contains_cry_baby() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("cry_baby")

	assert_str(entry.get("id")).is_equal("cry_baby")
	assert_str(entry.get("name")).is_equal("Cry Baby")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Cry Baby/CryBaby.tscn")
	assert_int(entry.get("tier")).is_equal(2)
