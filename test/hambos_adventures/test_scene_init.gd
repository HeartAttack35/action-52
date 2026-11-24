extends GdUnitTestSuite
# Feature: hambos_adventures — Main scene initialization, platforms, HUD, victory and defeat tests

const HAMBOS_SCENE = preload("res://scenes/minigames/Hambos Adventures/HambosAdventures.tscn")


func test_scene_initialization_and_nodes() -> void:
	var game = HAMBOS_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game is MinigameBase).is_true()
	assert_bool(game is HambosAdventures).is_true()

	assert_object(game.get_node_or_null("TileMap")).is_not_null()
	assert_object(game.get_node_or_null("Platforms")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/Floor")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/PlatformL1")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/PlatformL2")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/PlatformL3")).is_not_null()

	var ladders_node = game.get_node_or_null("Ladders")
	assert_object(ladders_node).is_not_null()
	assert_int(ladders_node.get_child_count()).is_greater_equal(3)

	assert_object(game.get_node_or_null("Goal")).is_not_null()
	assert_object(game.get_node_or_null("BallSpawner")).is_not_null()
	assert_object(game.get_node_or_null("Player")).is_not_null()

	var label_score: Label = game.get_node_or_null("HUD/LabelScore")
	var label_lives: Label = game.get_node_or_null("HUD/LabelLives")
	var label_goal: Label = game.get_node_or_null("HUD/LabelGoal")
	var label_message: Label = game.get_node_or_null("HUD/LabelMessage")

	assert_object(label_score).is_not_null()
	assert_object(label_lives).is_not_null()
	assert_object(label_goal).is_not_null()
	assert_object(label_message).is_not_null()

	assert_str(label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(label_goal.text).is_equal("Objetivo: ¡Alcanza la cima!")

	game.queue_free()


func test_victory_condition_on_goal_reached() -> void:
	var game = HAMBOS_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game._game_over).is_false()

	# Simular que el jugador alcanza la meta en la cima
	game.goal.reached.emit(game.player)

	assert_bool(game._game_over).is_true()
	assert_bool(game.spawner.is_active).is_false()
	assert_str(game.label_message.text).is_equal("¡VICTORIA! ¡HAMBO LLEGÓ A LA CIMA!")

	game.queue_free()


func test_defeat_condition_on_zero_lives() -> void:
	var game = HAMBOS_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game._game_over).is_false()

	# Simular pérdida total de vidas
	game._on_lives_changed(0)

	assert_bool(game._game_over).is_true()
	assert_bool(game.spawner.is_active).is_false()
	assert_str(game.label_message.text).is_equal("¡SIN VIDAS! JUEGO TERMINADO")

	game.queue_free()
