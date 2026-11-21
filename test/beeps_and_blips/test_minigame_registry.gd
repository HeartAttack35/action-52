extends GdUnitTestSuite
# Feature: beeps-and-blips — MinigameRegistry integration test

func test_minigame_registry_contains_beeps_and_blips() -> void:
	var entry: Dictionary = MinigameRegistry.get_minigame("beeps_and_blips")

	assert_str(entry.get("id")).is_equal("beeps_and_blips")
	assert_str(entry.get("name")).is_equal("Beeps and Blips")
	assert_str(entry.get("scene")).is_equal("res://scenes/minigames/Beeps and Blips/BeepsAndBlips.tscn")
	assert_int(entry.get("tier")).is_equal(1)
