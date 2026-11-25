extends GdUnitTestSuite
# Feature: the_evil_empire — Main scene initialization, palace TileMap, HUD, victory and defeat tests

const EVIL_EMPIRE_SCENE = preload("res://scenes/minigames/The Evil Empire/TheEvilEmpire.tscn")


func test_scene_initialization_nodes_and_palace_tilemap() -> void:
	GameManager.reset_stats()
	var game = EVIL_EMPIRE_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game is MinigameBase).is_true()
	assert_bool(game is TheEvilEmpire).is_true()

	var tile_map: TileMap = game.get_node_or_null("TileMap")
	assert_object(tile_map).is_not_null()
	assert_object(game.get_node_or_null("Platforms")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/Floor")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/LeftWall")).is_not_null()
	assert_object(game.get_node_or_null("Platforms/RightWall")).is_not_null()
	assert_object(game.get_node_or_null("Player")).is_not_null()
	assert_object(game.get_node_or_null("Enemies")).is_not_null()

	# Verificar suelo de arenisca (1,0), muros laterales (2,0) y 3 niveles de cornisas (0,0)
	assert_int(tile_map.get_cell_source_id(0, Vector2i(5, 17))).is_equal(0)
	assert_vector(tile_map.get_cell_atlas_coords(0, Vector2i(5, 17))).is_equal(Vector2i(1, 0))
	assert_vector(tile_map.get_cell_atlas_coords(0, Vector2i(0, 10))).is_equal(Vector2i(2, 0))
	assert_vector(tile_map.get_cell_atlas_coords(0, Vector2i(24, 10))).is_equal(Vector2i(2, 0))
	assert_vector(tile_map.get_cell_atlas_coords(0, Vector2i(3, 14))).is_equal(Vector2i(0, 0))
	assert_vector(tile_map.get_cell_atlas_coords(0, Vector2i(10, 10))).is_equal(Vector2i(0, 0))
	assert_vector(tile_map.get_cell_atlas_coords(0, Vector2i(11, 6))).is_equal(Vector2i(0, 0))

	var enemies_node: Node2D = game.get_node("Enemies")
	assert_int(enemies_node.get_child_count()).is_equal(7)
	assert_int(game.remaining_enemies).is_equal(7)

	var label_score: Label = game.get_node("HUD/LabelScore")
	var label_lives: Label = game.get_node("HUD/LabelLives")
	var label_enemies: Label = game.get_node("HUD/LabelEnemies")
	var label_message: Label = game.get_node("HUD/LabelMessage")

	assert_str(label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(label_enemies.text).is_equal("Guardias: %d" % game.remaining_enemies)
	assert_str(label_message.text).is_equal("")

	game.queue_free()


func test_victory_when_all_guards_defeated() -> void:
	GameManager.reset_stats()
	var game = EVIL_EMPIRE_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	var total_enemies: int = game.enemies_container.get_child_count()
	for enemy in game.enemies_container.get_children():
		enemy.hit()

	assert_int(game.remaining_enemies).is_equal(0)
	assert_bool(game._game_over).is_true()
	assert_int(GameManager.score).is_equal(total_enemies * 100)
	assert_str(game.label_enemies.text).is_equal("Guardias: 0")
	assert_str(game.label_message.text).is_equal("¡VICTORIA! ¡EL IMPERIO HA CAÍDO!")

	game.queue_free()


func test_defeat_on_zero_lives() -> void:
	GameManager.reset_stats()
	var game = EVIL_EMPIRE_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	game._on_lives_changed(0)

	assert_bool(game._game_over).is_true()
	assert_str(game.label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(game.label_message.text).is_equal("¡SIN VIDAS! JUEGO TERMINADO")

	game.queue_free()


func test_gameplay_scimitar_defeats_guard_and_updates_hud() -> void:
	GameManager.reset_stats()
	var game = EVIL_EMPIRE_SCENE.instantiate()
	add_child(game)

	for _i in 10:
		await get_tree().physics_frame

	assert_bool(game.player.is_on_floor()).is_true()
	var initial_count: int = game.remaining_enemies
	for enemy in game.enemies_container.get_children():
		assert_bool(enemy.is_on_floor()).is_true()

	var floor_guard: CharacterBody2D = game.get_node("Enemies/Guard1")
	floor_guard.speed = 0.0
	game.player.global_position = Vector2(floor_guard.global_position.x + 34.0, floor_guard.global_position.y)
	game.player._apply_direction(-1.0)
	game.player._start_melee()

	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_bool(floor_guard._is_dead).is_true()
	assert_int(game.remaining_enemies).is_equal(initial_count - 1)
	assert_int(GameManager.score).is_equal(100)
	assert_str(game.label_score.text).is_equal("Puntos: 100")
	assert_str(game.label_enemies.text).is_equal("Guardias: %d" % (initial_count - 1))

	game.queue_free()


func test_player_jump_reaches_palace_platform_heights() -> void:
	GameManager.reset_stats()
	var game = EVIL_EMPIRE_SCENE.instantiate()
	add_child(game)

	for _i in 6:
		await get_tree().physics_frame

	assert_bool(game.player.is_on_floor()).is_true()
	var start_y: float = game.player.global_position.y
	game.player.velocity.y = game.player.jump_velocity
	var min_y: float = start_y

	for _i in 45:
		game.player._apply_gravity(1.0 / 60.0)
		game.player.move_and_slide()
		min_y = minf(min_y, game.player.global_position.y)

	# Salto debe elevar al jugador al menos 145px (suficiente para subir 96px al Nivel 1 y 128px entre niveles)
	var jump_height: float = start_y - min_y
	assert_float(jump_height).is_greater(145.0)

	game.queue_free()


func test_main_menu_includes_the_evil_empire_button() -> void:
	var menu_scene: PackedScene = preload("res://scenes/main_menu/main_menu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var found := false
	for child in menu.grid.get_children():
		if child.get("minigame_id") == "the_evil_empire" and child.text == "The Evil Empire":
			found = true
			break

	assert_bool(found).is_true()
	menu.queue_free()
