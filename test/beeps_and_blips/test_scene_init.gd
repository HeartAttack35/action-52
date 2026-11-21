extends GdUnitTestSuite
# Feature: beeps-and-blips — Scene initialization and configuration tests

const BNB_SCENE = preload("res://scenes/minigames/Beeps and Blips/BeepsAndBlips.tscn")


func test_enemy_spawner_config() -> void:
	var bnb = BNB_SCENE.instantiate()
	add_child(bnb)
	await get_tree().process_frame

	var spawner: Timer = bnb.get_node("EnemySpawner")
	assert_float(spawner.wait_time).is_equal(2.5)
	assert_bool(spawner.autostart).is_true()

	bnb.queue_free()


func test_player_initial_position() -> void:
	var bnb = BNB_SCENE.instantiate()
	add_child(bnb)
	await get_tree().process_frame

	var vp: Vector2 = bnb.get_viewport_rect().size
	var player = bnb.get_node("Player")
	var expected := Vector2(vp.x / 2.0, vp.y - 50.0)
	assert_vector2(player.position).is_equal(expected)

	bnb.queue_free()


func test_hud_initial_values() -> void:
	var bnb = BNB_SCENE.instantiate()
	add_child(bnb)
	await get_tree().process_frame

	var label_score: Label = bnb.get_node("HUD/LabelScore")
	var label_lives: Label = bnb.get_node("HUD/LabelLives")

	assert_str(label_score.text).is_equal("Puntos: %d" % GameManager.score)
	assert_str(label_lives.text).is_equal("Vidas: %d" % GameManager.lives)

	bnb.queue_free()


func test_background_static_exists() -> void:
	var bnb = BNB_SCENE.instantiate()
	add_child(bnb)
	await get_tree().process_frame

	var bg: ColorRect = bnb.get_node("Background")
	assert_object(bg).is_not_null()

	bnb.queue_free()
