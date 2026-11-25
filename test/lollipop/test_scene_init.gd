extends GdUnitTestSuite
# Feature: lollipop — Main scene initialization, TileMap platforms, HUD, victory and defeat tests

const LOLLIPOP_SCENE = preload("res://scenes/minigames/Lollipop/Lollipop.tscn")


func test_scene_initialization_nodes_and_tilemap() -> void:
	GameManager.reset_stats()
	var game = LOLLIPOP_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game is MinigameBase).is_true()
	assert_bool(game is Lollipop).is_true()

	var tile_map: TileMap = game.get_node_or_null("TileMap")
	assert_object(tile_map).is_not_null()
	assert_object(game.get_node_or_null("Platforms")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/Floor")).is_not_null()
	assert_object(game.get_node_or_null("Player")).is_not_null()
	assert_object(game.get_node_or_null("Enemies")).is_not_null()

	# Verificar que el TileMap tiene celdas sólidas en suelo inferior y los 3 niveles flotantes
	assert_int(tile_map.get_cell_source_id(0, Vector2i(0, 17))).is_equal(0)
	assert_int(tile_map.get_cell_source_id(0, Vector2i(3, 14))).is_equal(0)
	assert_int(tile_map.get_cell_source_id(0, Vector2i(7, 10))).is_equal(0)
	assert_int(tile_map.get_cell_source_id(0, Vector2i(10, 6))).is_equal(0)

	var enemies_node: Node2D = game.get_node("Enemies")
	assert_int(enemies_node.get_child_count()).is_greater_equal(5)
	assert_int(game.remaining_enemies).is_equal(enemies_node.get_child_count())

	var label_score: Label = game.get_node("HUD/LabelScore")
	var label_lives: Label = game.get_node("HUD/LabelLives")
	var label_enemies: Label = game.get_node("HUD/LabelEnemies")
	var label_message: Label = game.get_node("HUD/LabelMessage")

	assert_str(label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(label_enemies.text).is_equal("Dulces: %d" % game.remaining_enemies)
	assert_str(label_message.text).is_equal("")

	game.queue_free()


func test_victory_when_all_enemies_defeated() -> void:
	GameManager.reset_stats()
	var game = LOLLIPOP_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	var total_enemies: int = game.enemies_container.get_child_count()
	for enemy in game.enemies_container.get_children():
		enemy.hit()

	assert_int(game.remaining_enemies).is_equal(0)
	assert_bool(game._game_over).is_true()
	assert_int(GameManager.score).is_equal(total_enemies * 100)
	assert_str(game.label_enemies.text).is_equal("Dulces: 0")
	assert_str(game.label_message.text).is_equal("¡VICTORIA! ¡MUNDO DULCE DESPEJADO!")

	game.queue_free()


func test_defeat_on_zero_lives() -> void:
	GameManager.reset_stats()
	var game = LOLLIPOP_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	game._on_lives_changed(0)

	assert_bool(game._game_over).is_true()
	assert_str(game.label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(game.label_message.text).is_equal("¡SIN VIDAS! JUEGO TERMINADO")

	game.queue_free()


func test_gameplay_melee_defeats_enemy_and_updates_hud() -> void:
	GameManager.reset_stats()
	var game = LOLLIPOP_SCENE.instantiate()
	add_child(game)

	# Esperar varios frames de física para que jugador y enemigos apoyen en sus plataformas
	for _i in 10:
		await get_tree().physics_frame

	assert_bool(game.player.is_on_floor()).is_true()
	var initial_count: int = game.remaining_enemies
	for enemy in game.enemies_container.get_children():
		assert_bool(enemy.is_on_floor()).is_true()

	# Colocar al jugador frente al enemigo del suelo mirando hacia la izquierda y atacar
	var floor_enemy: CharacterBody2D = game.get_node("Enemies/Enemy6")
	floor_enemy.speed = 0.0
	game.player.global_position = Vector2(floor_enemy.global_position.x + 34.0, floor_enemy.global_position.y)
	game.player._apply_direction(-1.0)
	game.player._start_melee()

	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_bool(floor_enemy._is_dead).is_true()
	assert_int(game.remaining_enemies).is_equal(initial_count - 1)
	assert_int(GameManager.score).is_equal(100)
	assert_str(game.label_score.text).is_equal("Puntos: 100")
	assert_str(game.label_enemies.text).is_equal("Dulces: %d" % (initial_count - 1))

	game.queue_free()
