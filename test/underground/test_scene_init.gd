extends GdUnitTestSuite
# Feature: underground — Main scene initialization and HUD tests

const UNDERGROUND_SCENE = preload("res://scenes/minigames/Underground/Underground.tscn")


func test_scene_initialization_and_nodes() -> void:
	var game = UNDERGROUND_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game is MinigameBase).is_true()
	assert_object(game.get_node("TileMap")).is_not_null()
	assert_object(game.get_node("Platforms")).is_not_null()
	assert_object(game.get_node("Platforms/Floor")).is_not_null()
	assert_object(game.get_node("Ladders")).is_not_null()
	assert_object(game.get_node("Gem")).is_not_null()
	assert_object(game.get_node("Player")).is_not_null()
	assert_object(game.get_node("Enemies")).is_not_null()

	var ladders_node = game.get_node("Ladders")
	assert_int(ladders_node.get_child_count()).is_greater_equal(4)

	var enemies_node = game.get_node("Enemies")
	assert_int(enemies_node.get_child_count()).is_greater_equal(4)
	assert_int(game.remaining_enemies).is_equal(enemies_node.get_child_count())

	var label_score: Label = game.get_node("HUD/LabelScore")
	var label_lives: Label = game.get_node("HUD/LabelLives")
	var label_enemies: Label = game.get_node("HUD/LabelEnemies")

	assert_str(label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(label_enemies.text).is_equal("Criaturas: %d" % game.remaining_enemies)

	game.queue_free()
