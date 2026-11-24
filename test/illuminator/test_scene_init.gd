extends GdUnitTestSuite
# Feature: illuminator — Main scene initialization, darkness/light cycle, victory and defeat tests

const ILLUMINATOR_SCENE = preload("res://scenes/minigames/Illuminator/Illuminator.tscn")


func test_scene_initialization_and_nodes() -> void:
	GameManager.reset_stats()
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	assert_bool(game is MinigameBase).is_true()
	assert_bool(game is Illuminator).is_true()

	assert_object(game.get_node_or_null("TileMap")).is_not_null()
	assert_object(game.get_node_or_null("Platforms")).is_not_null()
	assert_object(game.get_node_or_null("Ladders")).is_not_null()
	assert_object(game.get_node_or_null("Player")).is_not_null()
	assert_object(game.get_node_or_null("Enemies")).is_not_null()
	assert_object(game.get_node_or_null("DarknessModulate")).is_not_null()
	assert_object(game.get_node_or_null("DarknessOverlay")).is_not_null()
	assert_object(game.get_node_or_null("DarknessTimer")).is_not_null()
	assert_object(game.get_node_or_null("BlackoutTimer")).is_not_null()

	var ladders_node = game.get_node("Ladders")
	assert_int(ladders_node.get_child_count()).is_greater_equal(6)

	var enemies_node = game.get_node("Enemies")
	assert_int(enemies_node.get_child_count()).is_equal(6)
	assert_int(game.remaining_enemies).is_equal(6)

	assert_float(game.light_level).is_equal(1.0)
	assert_bool(game.is_total_darkness).is_false()
	assert_str(game.label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(game.label_lives.text).is_equal("Vidas: %d" % GameManager.lives)
	assert_str(game.label_enemies.text).is_equal("Sombras: 6")
	assert_str(game.label_light.text).is_equal("Luz: 100%")

	game.queue_free()


func test_darkness_timer_reduces_visibility_and_enemy_defeat_restores_light() -> void:
	GameManager.reset_stats()
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	# Simular varios ticks del temporizador de oscuridad
	game._on_darkness_timer_timeout()
	assert_float(game.light_level).is_less(1.0)
	var dimmed_level: float = game.light_level

	game._on_darkness_timer_timeout()
	assert_float(game.light_level).is_less(dimmed_level)

	# Derrotar una sombra restaura la claridad y reinicia el ciclo
	var first_enemy = game.enemies_container.get_child(0)
	first_enemy.hit()

	assert_float(game.light_level).is_equal(1.0)
	assert_bool(game.is_total_darkness).is_false()
	assert_int(game.remaining_enemies).is_equal(5)
	assert_str(game.label_light.text).is_equal("Luz: 100%")

	game.queue_free()


func test_prolonged_total_darkness_triggers_game_over() -> void:
	GameManager.reset_stats()
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	var state := {"blackout": false}
	game.blackout_triggered.connect(func(): state["blackout"] = true)

	# Llevar la luz hasta oscuridad total
	game.light_level = game.darkness_step * 0.5
	game._on_darkness_timer_timeout()

	assert_float(game.light_level).is_equal(0.0)
	assert_bool(game.is_total_darkness).is_true()
	assert_bool(game.blackout_timer.is_stopped()).is_false()

	# Si expira el temporizador de apagón prolongado -> Game Over
	game._on_blackout_timer_timeout()

	assert_bool(state["blackout"]).is_true()
	assert_bool(game._game_over).is_true()
	assert_str(game.label_message.text).is_equal("¡OSCURIDAD TOTAL! EL EDIFICIO SE APAGÓ")

	game.queue_free()


func test_victory_when_all_shadows_vaporized() -> void:
	GameManager.reset_stats()
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	for enemy in game.enemies_container.get_children():
		enemy.hit()

	assert_int(game.remaining_enemies).is_equal(0)
	assert_bool(game._game_over).is_true()
	assert_bool(game.darkness_timer.is_stopped()).is_true()
	assert_str(game.label_message.text).is_equal("¡VICTORIA! ¡EDIFICIO ILUMINADO!")

	game.queue_free()


func test_defeat_on_zero_lives() -> void:
	GameManager.reset_stats()
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	game._on_lives_changed(0)

	assert_bool(game._game_over).is_true()
	assert_bool(game.darkness_timer.is_stopped()).is_true()
	assert_str(game.label_message.text).is_equal("¡SIN VIDAS! JUEGO TERMINADO")

	game.queue_free()


func test_player_shoot_spawns_light_beam_and_cancels_blackout_on_kill() -> void:
	GameManager.reset_stats()
	var game = ILLUMINATOR_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame

	# Simular disparo del haz luminoso hacia la izquierda
	game.player._apply_direction(-1.0)
	var before_beams: int = get_tree().get_nodes_in_group("light_beam").size()
	game.player.shoot_requested.emit(game.player._origin.global_position)
	await get_tree().process_frame

	var beams := get_tree().get_nodes_in_group("light_beam")
	assert_int(beams.size()).is_equal(before_beams + 1)
	var spawned_beam = beams[beams.size() - 1]
	assert_vector(spawned_beam.direction).is_equal(Vector2.LEFT)

	# Entrar en oscuridad total y luego derrotar una sombra para cancelar el apagón
	game.light_level = 0.01
	game._on_darkness_timer_timeout()
	assert_bool(game.is_total_darkness).is_true()
	assert_bool(game.blackout_timer.is_stopped()).is_false()

	game.enemies_container.get_child(0).hit()
	assert_bool(game.is_total_darkness).is_false()
	assert_bool(game.blackout_timer.is_stopped()).is_true()
	assert_float(game.light_level).is_equal(1.0)

	game.queue_free()
